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
$(error please set CRD_DIR (directories where CRD manifests will be saved) prior to including kubebuilder.mk)
endif

ifeq ($(API_DIR),)
$(error please set API_DIR ()(directories where KUBEBUILDER API types are defined) prior to including kubebuilder.mk)
endif

# ====================================================================================
# Kubebuilder Targets

# Generate manifests e.g. CRD, RBAC etc.
kubebuilder.manifests: $(CONTROLLERGEN)
	@$(INFO) Generating CRD manifests
	@# first delete the CRD_DIR, to remove the CRDs of types that no longer exist
	@rm -rf $(CRD_DIR)
	@$(CONTROLLERGEN) crd:trivialVersions=true paths=$(API_DIR) output:dir=$(CRD_DIR)
	@$(OK) Generating CRD manifests

# ====================================================================================
# Common Targets

test.init: $(KUBEBUILDER)

# ====================================================================================
# Special Targets

define KUBEBULDER_HELPTEXT
Kubebuilder Targets:
    bin                     Run kubebuilder binary, pass args by setting ARGS=""
    manifests               Generates Kubernetes custom resources manifests (e.g. CRDs RBACs, ...)

endef
export KUBEBULDER_HELPTEXT

kubebuilder.help:
	@echo "$$KUBEBULDER_HELPTEXT"

help-special: kubebuilder.help
manifests: kubebuilder.manifests

kubebuilder.bin: $(KUBEBUILDER)
	@$(KUBEBUILDER)/kubebuilder $(ARGS)

.PHONY: kubebuilder.help kubebuilder.bin kubebuilder.manifests

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


