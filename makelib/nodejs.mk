# ====================================================================================
# Options

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

NPM := npm
NPM_MODULE_DIR := $(SELF_DIR)/../../node_modules
NPM_PACKAGE_FILE := $(SELF_DIR)/../../package.json
NPM_PACKAGE_LOCK_FILE := $(SELF_DIR)/../../package-lock.json

NG := $(NPM) run ng --

# TODO: link this to overall TTY support
ifneq ($(origin NG_NO_PROGRESS), undefined)
NG_PROGRESS_ARG ?= --progress=false
npm_config_progress = false
export npm_config_progress
endif

NG_KARMA_CONFIG ?= karma.ci.conf.js

NG_OUTDIR ?= $(OUTPUT_DIR)/angular
export NG_OUTDIR

# ====================================================================================
# NPM Targets

# some node packages like node-sass require platform/arch specific install. we need
# to run npm install for each platform. As a result we track a stamp file per host
NPM_INSTALL_STAMP := $(NPM_MODULE_DIR)/npm.install.$(HOST_PLATFORM).stamp

# only run "npm install" if the package.json has changed
$(NPM_INSTALL_STAMP): $(NPM_PACKAGE_FILE) $(NPM_PACKAGE_LOCK_FILE)
	@echo === npm install $(HOST_PLATFORM)
	@$(NPM) install --no-save
#	rebuild node-sass since it has platform dependent bits
	@[ ! -d "$(NPM_MODULE_DIR)/node-sass" ] || $(NPM) rebuild node-sass
	@touch $(NPM_INSTALL_STAMP)

npm.install: $(NPM_INSTALL_STAMP)

.PHONY: npm.install

# ====================================================================================
# Angular Project Targets

ng.build: npm.install
	@echo === ng build $(PLATFORM)
	@$(NG) build --prod $(NG_PROGRESS_ARG)

ng.lint: npm.install
	@echo === ng lint
	@$(NG) lint

ng.test: npm.install
	@echo === ng test
	@$(NG) test $(NG_PROGRESS_ARG) --code-coverage --karma-config $(NG_KARMA_CONFIG)

ng.test-integration: npm.install
	@echo === ng e2e
	@$(NG) e2e

ng.clean:
	@:

ng.distclean:
	@rm -fr $(NPM_MODULE_DIR)

.PHONY: ng.build ng.lint ng.test ng.test-integration ng.clean ng.distclean

# ====================================================================================
# Common Targets

build.init: npm.install
build.check: ng.lint
clean: ng.clean
distclean: ng.distclean
lint.init: npm.install
lint: ng.lint
test.init: npm.install
test.run: ng.test
e2e.init: npm.install
e2e.run: ng.test

