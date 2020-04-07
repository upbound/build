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

# the version of kind to use
KIND_VERSION ?= v0.7.0
KIND := $(TOOLS_HOST_DIR)/kind-$(KIND_VERSION)

# the version of kubectl to use
KUBECTL_VERSION ?= v1.15.0
KUBECTL := $(TOOLS_HOST_DIR)/kubectl-$(KUBECTL_VERSION)

# the version of kustomize to use
KUSTOMIZE_VERSION ?= v3.3.0
KUSTOMIZE := $(TOOLS_HOST_DIR)/kustomize-$(KUSTOMIZE_VERSION)

# ====================================================================================
# Common Targets

k8s_tools.buildvars:
	@echo KIND=$(KIND)
	@echo KUBECTL=$(KUBECTL)
	@echo KUSTOMIZE=$(KUSTOMIZE)

build.vars: k8s_tools.buildvars

# ====================================================================================
# tools

# kind download and install
$(KIND):
	@$(INFO) installing kind $(KIND_VERSION)
	@curl -fsSLo $(KIND) https://github.com/kubernetes-sigs/kind/releases/download/$(KIND_VERSION)/kind-$(GOHOSTOS)-$(GOHOSTARCH) || $(FAIL)
	@chmod +x $(KIND) 
	@$(OK) installing kind $(KIND_VERSION)

# kubectl download and install
$(KUBECTL):
	@$(INFO) installing kubectl $(KUBECTL_VERSION)
	@curl -fsSLo $(KUBECTL) https://storage.googleapis.com/kubernetes-release/release/$(KUBECTL_VERSION)/bin/$(GOHOSTOS)/$(GOHOSTARCH)/kubectl || $(FAIL)
	@chmod +x $(KUBECTL) 
	@$(OK) installing kubectl $(KUBECTL_VERSION)

# kustomize download and install
$(KUSTOMIZE):
	@$(INFO) installing kustomize $(KUSTOMIZE_VERSION)
	@mkdir -p $(TOOLS_HOST_DIR)/tmp-kustomize
	@curl -fsSL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/$(KUSTOMIZE_VERSION)/kustomize_$(KUSTOMIZE_VERSION)_$(HOST_PLATFORM).tar.gz | tar -xz -C $(TOOLS_HOST_DIR)/tmp-kustomize
	@mv $(TOOLS_HOST_DIR)/tmp-kustomize/kustomize $(KUSTOMIZE)
	@rm -fr $(TOOLS_HOST_DIR)/tmp-kustomize
	@$(OK) installing kustomize $(KUSTOMIZE_VERSION)