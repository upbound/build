# Copyright 2016 The Upbound Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ====================================================================================
# Options

# the version of kubebuilder to use
KUBEBUILDER_VERSION ?= 1.0.8
CONTROLLER_GEN_VERSION ?= v0.2.1
KUBEBUILDER := $(TOOLS_HOST_DIR)/kubebuilder-$(KUBEBUILDER_VERSION)

# these are use by the kube builder test harness
TEST_ASSET_KUBE_APISERVER := $(KUBEBUILDER)/kube-apiserver
TEST_ASSET_ETCD := $(KUBEBUILDER)/etcd
TEST_ASSET_KUBECTL := $(KUBEBUILDER)/kubectl
export TEST_ASSET_KUBE_APISERVER TEST_ASSET_ETCD TEST_ASSET_KUBECTL

# ====================================================================================
# Setup environment

-include golang.mk

ifeq ($(CRD_DIR),)
$(error please set CRD_DIR prior to including kubebuilder.mk)
endif

ifeq ($(CONTROLLERGEN_PATHS),)
$(error please set CONTROLLERGEN_PATHS prior to including kubebuilder.mk)
endif

CONTROLLERGEN := $(TOOLS_HOST_DIR)/controller-gen

# ====================================================================================
# Kubebuilder Targets

# Generate manifests e.g. CRD, RBAC etc.
kubebuilder.manifests: $(CONTROLLERGEN)
	@$(INFO) Generating CRD manifests
	@# first delete the CRD_DIR, to remove the CRDs of types that no longer exist
	@rm -rf $(CRD_DIR)
	@$(CONTROLLERGEN) crd:trivialVersions=true paths=$(CONTROLLERGEN_PATHS) output:dir=$(CRD_DIR)
	@$(OK) Generating CRD manifests

# Generate controller 
kubebuilder.generate: $(GOIMPORTS) $(CONTROLLERGEN)
	@$(INFO) go generate $(PLATFORM)
	@CGO_ENABLED=0 CONTROLLERGEN=$(CONTROLLERGEN) $(GOHOST) generate $(GO_COMMON_FLAGS) $(GO_PACKAGES) $(GO_INTEGRATION_TEST_PACKAGES) || $(FAIL)
	@find $(GO_SUBDIRS) $(GO_INTEGRATION_TESTS_SUBDIRS) -type f -name 'zz_generated*' -exec $(GOIMPORTS) -l -w -local $(GO_PROJECT) {} \;
	@$(OK) go generate $(PLATFORM)

# ====================================================================================
# Common Targets

test.init: $(KUBEBUILDER)

# ====================================================================================
# Special Targets

define KUBEBULDER_HELPTEXT
Kubebuilder Targets:
    bin                     run kubebuilder binary, pass args by setting ARGS=""
    contgen                 Runs go code generation, to execute controller-gen tool
    manifests               Generates Kubernetes custom resources manifests (e.g. CRDs RBACs, ...)

endef
export KUBEBULDER_HELPTEXT

kubebuilder.help:
	@echo "$$KUBEBULDER_HELPTEXT"

help-special: kubebuilder.help

contgen: kubebuilder.generate
manifests: kubebuilder.manifests

kubebuilder.bin: $(KUBEBUILDER)
	@$(KUBEBUILDER)/kubebuilder $(ARGS)

.PHONY: kubebuilder.help kubebuilder.bin kubebuilder.generate kubebuilder.manifests

# ====================================================================================
# tools

# kubebuilder download and install
$(KUBEBUILDER):
	@$(INFO) installing kubebuilder $(KUBEBUILDER_VERSION)
	@mkdir -p $(TOOLS_HOST_DIR)/tmp || $(FAIL)
	@curl -fsSL https://github.com/kubernetes-sigs/kubebuilder/releases/download/v$(KUBEBUILDER_VERSION)/kubebuilder_$(KUBEBUILDER_VERSION)_$(GOHOSTOS)_$(GOHOSTARCH).tar.gz | tar -xz -C $(TOOLS_HOST_DIR)/tmp  || $(FAIL)
	@mv $(TOOLS_HOST_DIR)/tmp/kubebuilder_$(KUBEBUILDER_VERSION)_$(GOHOSTOS)_$(GOHOSTARCH)/bin $(KUBEBUILDER) || $(FAIL)
	@rm -fr $(TOOLS_HOST_DIR)/tmp
	@$(OK) installing kubebuilder $(KUBEBUILDER_VERSION)

$(CONTROLLERGEN):
	@$(INFO) installing controller-gen @$(CONTROLLER_GEN_VERSION)
	@mkdir -p $(TOOLS_HOST_DIR)/tmp-controllergen || $(FAIL)

	@# `go get` only supports versioned go packages when GO111MODULE=on 
	@#  since $(TOOLS_HOST_DIR) is under $(GO_PROJECT), make a temp folder which has a go.mod, 
	@#  so that $(GO_PROJECT)/go.mod doesn't get modified because of running `go get`
	@cd $(TOOLS_HOST_DIR)/tmp-controllergen; rm -f go.mod; GO111MODULE=on $(GOHOST) mod init tmp-controllergen
	@cd $(TOOLS_HOST_DIR)/tmp-controllergen; GOPATH=$(abspath $(GO_PKG_DIR)) GO111MODULE=on GOBIN=$(TOOLS_HOST_DIR) $(GOHOST) get sigs.k8s.io/controller-tools/cmd/controller-gen@$(CONTROLLER_GEN_VERSION) || $(FAIL)
	@rm -fr $(TOOLS_HOST_DIR)/tmp-controllergen

	@$(OK) installing controller-gen @$(CONTROLLER_GEN_VERSION)

