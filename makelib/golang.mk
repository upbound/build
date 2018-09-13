# ====================================================================================
# Options

# The go project including repo name, for example, github.com/rook/rook
ifeq ($(GO_PROJECT),)
$(error the variable GO_PROJECT must be set prior to including golang.mk)
endif

# the packages to be built statically, for example, $(GO_PROJECT)/cmd/mytool
ifeq ($(GO_STATIC_PACKAGES),)
$(error please set GO_STATIC_PACKAGES prior to including golang.mk)
endif

# Optional. These are subdirs that we look for all go files to test, vet, and fmt
GO_SUBDIRS ?= cmd pkg

# Optional. Additional subdirs used for integration or e2e testings
GO_INTEGRATION_TESTS_SUBDIRS ?=

# Optional directories (relative to CURDIR)
GO_VENDOR_DIR ?= vendor
GO_PKG_DIR ?= $(WORK_DIR)/pkg

# Optional build flags passed to go tools
GO_BUILDFLAGS ?=
GO_LDFLAGS ?=
GO_TAGS ?=
GO_TEST_FLAGS ?=

# ====================================================================================
# Setup go environment

# turn on more verbose build when V=1
ifeq ($(V),1)
GO_LDFLAGS += -v -n
GO_BUILDFLAGS += -x
endif

# whether to generate debug information in binaries. this includes DWARF and symbol tables.
ifeq ($(DEBUG),0)
GO_LDFLAGS += -s -w
endif

# supported go versions
GO_SUPPORTED_VERSIONS ?= 1.7|1.8|1.9|1.10|1.11

# set GOOS and GOARCH
GOOS := $(OS)
GOARCH := $(ARCH)
export GOOS GOARCH

# set GOOS and GOARCH
GOHOSTOS := $(HOSTOS)
GOHOSTARCH := $(HOSTARCH)

GO_PACKAGES := $(foreach t,$(GO_SUBDIRS),$(GO_PROJECT)/$(t)/...)
GO_INTEGRATION_TEST_PACKAGES := $(foreach t,$(GO_INTEGRATION_TESTS_SUBDIRS),$(GO_PROJECT)/$(t)/integration)

ifneq ($(GO_TEST_SUITE),)
GO_TEST_FLAGS += -run '$(GO_TEST_SUITE)'
endif

ifneq ($(GO_TEST_FILTER),)
TEST_FILTER_PARAM := -testify.m '$(GO_TEST_FILTER)'
endif

GOPATH := $(shell go env GOPATH)

# setup tools used during the build
DEP_VERSION=v0.4.1
DEP := $(TOOLS_HOST_DIR)/dep-$(DEP_VERSION)
GOLINT := $(TOOLS_HOST_DIR)/golint
GOJUNIT := $(TOOLS_HOST_DIR)/go-junit-report

GO := go
GOHOST := GOOS=$(GOHOSTOS) GOARCH=$(GOHOSTARCH) go
GO_VERSION := $(shell $(GO) version | sed -ne 's/[^0-9]*\(\([0-9]\.\)\{0,4\}[0-9][^.]\).*/\1/p')

# we use a consistent version of gofmt even while running different go compilers.
# see https://github.com/golang/go/issues/26397 for more details
GOFMT_VERSION := 1.11
ifneq ($(findstring $(GOFMT_VERSION),$(GO_VERSION)),)
GOFMT := $(shell which gofmt)
else
GOFMT := $(TOOLS_HOST_DIR)/gofmt$(GOFMT_VERSION)
endif

GO_BIN_DIR := $(abspath $(OUTPUT_DIR)/bin)
GO_OUT_DIR := $(GO_BIN_DIR)/$(PLATFORM)
GO_TEST_DIR := $(abspath $(OUTPUT_DIR)/tests)
GO_TEST_OUTPUT := $(GO_TEST_DIR)/$(PLATFORM)

ifeq ($(GOOS),windows)
GO_OUT_EXT := .exe
endif

# NOTE: the install suffixes are matched with the build container to speed up the
# the build. Please keep them in sync.

# we run go build with -i which on most system's would want to install packages
# into the system's root dir. using our own pkg dir avoid thats
ifneq ($(GO_PKG_DIR),)
GO_PKG_BASE_DIR := $(abspath $(GO_PKG_DIR)/$(PLATFORM))
GO_PKG_STATIC_FLAGS := -pkgdir $(GO_PKG_BASE_DIR)_static
endif

GO_COMMON_FLAGS = $(GO_BUILDFLAGS) -tags '$(GO_TAGS)'
GO_STATIC_FLAGS = $(GO_COMMON_FLAGS) $(GO_PKG_STATIC_FLAGS) -installsuffix static  -ldflags '$(GO_LDFLAGS)'

# ====================================================================================
# Go Targets

go.init: go.vendor.lite
	@if ! `$(GO) version | grep -q -E '\bgo($(GO_SUPPORTED_VERSIONS))\b'`; then \
		$(ERR) unsupported go version. Please make install one of the following supported version: '$(GO_SUPPORTED_VERSIONS)' ;\
		exit 1 ;\
	fi
	@if [ "$(realpath ../../../..)" !=  "$(realpath $(GOPATH))" ]; then \
		$(WARN) the source directory is not relative to the GOPATH at $(GOPATH) or you are you using symlinks. The build might run into issue. Please move the source directory to be at $(GOPATH)/src/$(GO_PROJECT) ;\
	fi

go.build:
	@$(INFO) go build $(PLATFORM)
	$(foreach p,$(GO_STATIC_PACKAGES),@CGO_ENABLED=0 $(GO) build -v -i -o $(GO_OUT_DIR)/$(lastword $(subst /, ,$(p)))$(GO_OUT_EXT) $(GO_STATIC_FLAGS) $(p) || $(FAIL) ${\n})
	$(foreach p,$(GO_TEST_PACKAGES) $(GO_LONGHAUL_TEST_PACKAGES),@CGO_ENABLED=0 $(GO) test -v -i -c -o $(GO_TEST_OUTPUT)/$(lastword $(subst /, ,$(p)))$(GO_OUT_EXT) $(GO_STATIC_FLAGS) $(p) || $(FAIL ${\n}))
	@$(OK) go build $(PLATFORM)

go.install:
	@$(INFO) go install $(PLATFORM)
	$(foreach p,$(GO_STATIC_PACKAGES),@CGO_ENABLED=0 $(GO) install -v $(GO_STATIC_FLAGS) $(p) || $(FAIL) ${\n})
	@$(OK) go install $(PLATFORM)

go.test.unit: $(GOJUNIT)
	@$(INFO) go test unit-tests
	@mkdir -p $(GO_TEST_OUTPUT)
	@CGO_ENABLED=0 $(GOHOST) test -v -i -cover $(GO_STATIC_FLAGS) $(GO_PACKAGES) || $(FAIL)
	@CGO_ENABLED=0 $(GOHOST) test -v -cover $(GO_TEST_FLAGS) $(GO_STATIC_FLAGS) $(GO_PACKAGES) 2>&1 | tee $(GO_TEST_OUTPUT)/unit-tests.log || $(FAIL)
	@cat $(GO_TEST_OUTPUT)/unit-tests.log | $(GOJUNIT) -set-exit-code > $(GO_TEST_OUTPUT)/unit-tests.xml || $(FAIL)
	@$(OK) go test unit-tests

go.test.integration: $(GOJUNIT)
	@$(INFO) go test integration-tests
	@mkdir -p $(GO_TEST_OUTPUT) || $(FAIL)
	@CGO_ENABLED=0 $(GOHOST) test -v -i $(GO_STATIC_FLAGS) $(GO_INTEGRATION_TEST_PACKAGES) || $(FAIL)
	@CGO_ENABLED=0 $(GOHOST) test -v $(GO_TEST_FLAGS) $(GO_STATIC_FLAGS) $(GO_INTEGRATION_TEST_PACKAGES) $(TEST_FILTER_PARAM) 2>&1 | tee $(GO_TEST_OUTPUT)/integration-tests.log || $(FAIL)
	@cat $(GO_TEST_OUTPUT)/integration-tests.log | $(GOJUNIT) -set-exit-code > $(GO_TEST_OUTPUT)/integration-tests.xml || $(FAIL)
	@$(OK) go test integration-tests

go.lint: $(GOLINT)
	@$(INFO) go lint
	@$(GOLINT) -set_exit_status=true $(GO_PACKAGES) $(GO_INTEGRATION_TEST_PACKAGES) || $(FAIL)
	@$(OK) go lint

go.vet:
	@$(INFO) go vet $(PLATFORM)
	@CGO_ENABLED=0 $(GOHOST) vet $(GO_COMMON_FLAGS) $(GO_PACKAGES) $(GO_INTEGRATION_TEST_PACKAGES) || $(FAIL)
	@$(OK) go vet $(PLATFORM)

go.fmt: $(GOFMT)
	@$(INFO) go fmt
	@gofmt_out=$$($(GOFMT) -s -d -e $(GO_SUBDIRS) $(GO_INTEGRATION_TESTS_SUBDIRS) 2>&1) && [ -z "$${gofmt_out}" ] || (echo "$${gofmt_out}" 1>&2; $(FAIL))
	@$(OK) go fmt

go.validate: go.vet go.fmt

go.vendor.lite: $(DEP)
#	dep ensure blindly updates the whole vendor tree causing everything to be rebuilt. This workaround
#	will only call dep ensure if the .lock file changes or if the vendor dir is non-existent.
	@if [ ! -d $(GO_VENDOR_DIR) ] || [ ! $(DEP) ensure -no-vendor -dry-run &> /dev/null ]; then \
		$(INFO) dep ensure ;\
		$(DEP) ensure || $(FAIL);\
		$(OK) dep ensure ;\
	fi

go.vendor: $(DEP)
	@$(INFO) dep ensure
	@$(DEP) ensure || $(FAIL)
	@$(OK) dep ensure

go.clean:
	@rm -fr $(GO_BIN_DIR) $(GO_TEST_DIR)

go.distclean:
	@rm -rf $(GO_VENDOR_DIR) $(GO_PKG_DIR)

.PHONY: go.init go.build go.install go.test.unit go.test.integration go.lint go.vet go.fmt
.PHONY: go.validate go.vendor.lite go.vendor go.clean go.distclean

# ====================================================================================
# Common Targets

build.init: go.init
build.check: go.fmt
build.check.platform: go.vet
build.code.platform: go.build
clean: go.clean
distclean: go.distclean
lint: go.lint
test: go.test.unit

# ====================================================================================
# Special Targets

fmt: go.fmt
vendor: go.vendor
ifneq ($(filter $(PLATFORMS),$(PLATFORM)),)
vet: go.vet
else
vet: ; @:
endif

define GO_HELPTEXT
Go Targets:
    fmt          Build and publish final releasable artifacts
    vendor       Promote a release to a release channel
    vet          Tag a release

endef
export GO_HELPTEXT

go.help:
	@echo "$$GO_HELPTEXT"

help-special: go.help

.PHONY: fmt vendor vet go.help

# ====================================================================================
# Tools install targets

$(DEP):
	@$(INFO) installing dep $(HOSTOS)-$(HOSTARCH)
	@mkdir -p $(TOOLS_HOST_DIR)/tmp-dep || $(FAIL)
	@if [ "$(GOHOSTARCH)" = "arm64" ]; then\
		GOPATH=$(TOOLS_HOST_DIR)/tmp-dep GOBIN=$(TOOLS_HOST_DIR) $(GOHOST) get -u github.com/golang/dep/cmd/dep || $(FAIL) ;\
		mv $(TOOLS_HOST_DIR)/dep $@ || $(FAIL);\
	else \
		curl -sL -o $(DEP) https://github.com/golang/dep/releases/download/$(DEP_VERSION)/dep-$(HOSTOS)-$(HOSTARCH) || $(FAIL);\
	fi
	@chmod +x $(DEP) || $(FAIL)
	@rm -fr $(TOOLS_HOST_DIR)/tmp-dep
	@$(OK) installing dep $(HOSTOS)-$(HOSTARCH)

$(GOLINT):
	@$(INFO) installing golint
	@mkdir -p $(TOOLS_HOST_DIR)/tmp-lint || $(FAIL)
	@GOPATH=$(TOOLS_HOST_DIR)/tmp-lint GOBIN=$(TOOLS_HOST_DIR) $(GOHOST) get github.com/golang/lint/golint || rm -fr $(TOOLS_HOST_DIR)/tmp-lint || $(FAIL)
	@rm -fr $(TOOLS_HOST_DIR)/tmp-lint
	@$(OK) installing golint

$(GOFMT):
	@$(INFO) installing gofmt$(GOFMT_VERSION)
	@mkdir -p $(TOOLS_HOST_DIR)/tmp-fmt || $(FAIL)
	@curl -sL https://dl.google.com/go/go$(GOFMT_VERSION).$(HOSTOS)-$(HOSTARCH).tar.gz | tar -xz -C $(TOOLS_HOST_DIR)/tmp-fmt || $(FAIL)
	@mv $(TOOLS_HOST_DIR)/tmp-fmt/go/bin/gofmt $(GOFMT) || $(FAIL)
	@rm -fr $(TOOLS_HOST_DIR)/tmp-fmt
	@$(OK) installing gofmt$(GOFMT_VERSION)

$(GOJUNIT):
	@$(INFO) installing go-junit-report
	@mkdir -p $(TOOLS_HOST_DIR)/tmp-junit || $(FAIL)
	@GOPATH=$(TOOLS_HOST_DIR)/tmp-junit GOBIN=$(TOOLS_HOST_DIR) $(GOHOST) get github.com/jstemmer/go-junit-report || rm -fr $(TOOLS_HOST_DIR)/tmp-junit || $(FAIL)
	@rm -fr $(TOOLS_HOST_DIR)/tmp-junit
	@$(OK) installing go-junit-report
