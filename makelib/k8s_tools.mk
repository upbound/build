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

# the version of istio to use
ISTIO_VERSION ?= 1.12.9
ISTIO := $(TOOLS_HOST_DIR)/istioctl-$(ISTIO_VERSION)
ISTIOOS := $(HOSTOS)
ISTIO_DOWNLOAD_TUPLE := $(SAFEHOSTPLATFORM)
ifeq ($(HOSTOS),darwin)
ISTIO_DOWNLOAD_TUPLE := osx-$(SAFEHOSTARCH)
endif

# the version of kind to use
KIND_VERSION ?= v0.16.0
KIND := $(TOOLS_HOST_DIR)/kind-$(KIND_VERSION)

# the version of kubectl to use
KUBECTL_VERSION ?= v1.24.3
KUBECTL := $(TOOLS_HOST_DIR)/kubectl-$(KUBECTL_VERSION)

# the version of kustomize to use
KUSTOMIZE_VERSION ?= v4.5.5
KUSTOMIZE := $(TOOLS_HOST_DIR)/kustomize-$(KUSTOMIZE_VERSION)

# the version of olm-bundle to use
OLMBUNDLE_VERSION ?= v0.5.2
OLMBUNDLE := $(TOOLS_HOST_DIR)/olm-bundle-$(OLMBUNDLE_VERSION)

# the version of up to use
UP_VERSION ?= v0.28.0
UP_CHANNEL ?= stable
UP := $(TOOLS_HOST_DIR)/up-$(UP_VERSION)

# the version of crossplane cli to use
CROSSPLANE_CLI_VERSION ?= v1.14.5
CROSSPLANE_CLI_CHANNEL ?= stable
CROSSPLANE_CLI := $(TOOLS_HOST_DIR)/crossplane-cli-$(CROSSPLANE_CLI_VERSION)

# the version of helm 3 to use
USE_HELM3 ?= false
HELM3_VERSION ?= v3.9.1
HELM3 := $(TOOLS_HOST_DIR)/helm-$(HELM3_VERSION)

# If we enable HELM3 we alias HELM to be HELM3
ifeq ($(USE_HELM3),true)
HELM_VERSION ?= $(HELM3_VERSION)
HELM := $(HELM3)
else
HELM_VERSION ?= v2.17.0
HELM := $(TOOLS_HOST_DIR)/helm-$(HELM_VERSION)
endif

# the version of kuttl to use
KUTTL_VERSION ?= 0.12.1
KUTTL := $(TOOLS_HOST_DIR)/kuttl-$(KUTTL_VERSION)

# the version of chainsaw to use
CHAINSAW_VERSION ?= 0.2.0
CHAINSAW := $(TOOLS_HOST_DIR)/chainsaw-$(CHAINSAW_VERSION)

# the version of uptest to use
UPTEST_VERSION ?= v0.1.0
UPTEST := $(TOOLS_HOST_DIR)/uptest-$(UPTEST_VERSION)

# the version of yq to use
YQ_VERSION ?= v4.40.5
YQ := $(TOOLS_HOST_DIR)/yq-$(YQ_VERSION)

# ====================================================================================
# Common Targets

k8s_tools.buildvars:
	@echo KIND=$(KIND)
	@echo KUBECTL=$(KUBECTL)
	@echo KUSTOMIZE=$(KUSTOMIZE)
	@echo OLM_BUNDLE=$(OLM_BUNDLE)
	@echo UP=$(UP)
	@echo HELM=$(HELM)
	@echo HELM3=$(HELM3)
	@echo KUTTL=$(KUTTL)
	@echo CHAINSAW=$(CHAINSAW)
	@echo YQ=$(YQ)

build.vars: k8s_tools.buildvars

# ====================================================================================
# tools

# istio download and install
$(ISTIO):
	@$(INFO) installing istio $(ISTIO_VERSION)
	@mkdir -p $(TOOLS_HOST_DIR)/tmp-istio || $(FAIL)
	@curl --progress-bar -fsSL https://github.com/istio/istio/releases/download/$(ISTIO_VERSION)/istio-$(ISTIO_VERSION)-$(ISTIO_DOWNLOAD_TUPLE).tar.gz | tar -xz -C $(TOOLS_HOST_DIR)/tmp-istio || $(FAIL)
	@mv $(TOOLS_HOST_DIR)/tmp-istio/istio-$(ISTIO_VERSION)/bin/istioctl $(ISTIO) || $(FAIL)
	@rm -fr $(TOOLS_HOST_DIR)/tmp-istio || $(FAIL)
	@$(OK) $(ISTIO) installing istio $(ISTIO_VERSION)

# kind download and install
$(KIND):
	@$(INFO) installing kind $(KIND_VERSION)
	@mkdir -p $(TOOLS_HOST_DIR) || $(FAIL)
	@curl -fsSLo $(KIND) https://github.com/kubernetes-sigs/kind/releases/download/$(KIND_VERSION)/kind-$(SAFEHOSTPLATFORM) || $(FAIL)
	@chmod +x $(KIND)
	@$(OK) installing kind $(KIND_VERSION)

# kubectl download and install
$(KUBECTL):
	@$(INFO) installing kubectl $(KUBECTL_VERSION)
	@curl -fsSLo $(KUBECTL) --create-dirs https://storage.googleapis.com/kubernetes-release/release/$(KUBECTL_VERSION)/bin/$(HOSTOS)/$(SAFEHOSTARCH)/kubectl || $(FAIL)
	@chmod +x $(KUBECTL)
	@$(OK) installing kubectl $(KUBECTL_VERSION)

# kustomize download and install
$(KUSTOMIZE):
	@$(INFO) installing kustomize $(KUSTOMIZE_VERSION)
	@mkdir -p $(TOOLS_HOST_DIR)/tmp-kustomize
	@curl -fsSL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/$(KUSTOMIZE_VERSION)/kustomize_$(KUSTOMIZE_VERSION)_$(SAFEHOST_PLATFORM).tar.gz | tar -xz -C $(TOOLS_HOST_DIR)/tmp-kustomize
	@mv $(TOOLS_HOST_DIR)/tmp-kustomize/kustomize $(KUSTOMIZE)
	@rm -fr $(TOOLS_HOST_DIR)/tmp-kustomize
	@$(OK) installing kustomize $(KUSTOMIZE_VERSION)

# olm-bundle download and install
$(OLMBUNDLE):
	@$(INFO) installing olm-bundle $(OLMBUNDLE_VERSION)
	@curl -fsSLo $(OLMBUNDLE) https://github.com/upbound/olm-bundle/releases/download/$(OLMBUNDLE_VERSION)/olm-bundle_$(SAFEHOSTPLATFORM) || $(FAIL)
	@chmod +x $(OLMBUNDLE)
	@$(OK) installing olm-bundle $(OLMBUNDLE_VERSION)

# up download and install
$(UP):
	@$(INFO) installing up $(UP_VERSION)
	@curl -fsSLo $(UP) --create-dirs https://cli.upbound.io/$(UP_CHANNEL)/$(UP_VERSION)/bin/$(SAFEHOST_PLATFORM)/up?source=build || $(FAIL)
	@chmod +x $(UP)
	@$(OK) installing up $(UP_VERSION)

# Crossplane CLI download and install
$(CROSSPLANE_CLI):
	@$(INFO) installing Crossplane CLI $(CROSSPLANE_CLI_VERSION)
	@curl -fsSLo $(CROSSPLANE_CLI) --create-dirs https://releases.crossplane.io/$(CROSSPLANE_CLI_CHANNEL)/$(CROSSPLANE_CLI_VERSION)/bin/$(SAFEHOST_PLATFORM)/crank?source=build || $(FAIL)
	@chmod +x $(CROSSPLANE_CLI)
	@$(OK) installing Crossplane CLI $(CROSSPLANE_CLI_VERSION)

# helm download and install only if helm3 not enabled
ifeq ($(USE_HELM3),false)
$(HELM):
	@$(INFO) installing helm $(HELM_VERSION)
	@mkdir -p $(TOOLS_HOST_DIR)/tmp-helm
	@curl -fsSL https://get.helm.sh/helm-$(HELM_VERSION)-$(SAFEHOSTPLATFORM).tar.gz | tar -xz -C $(TOOLS_HOST_DIR)/tmp-helm
	@mv $(TOOLS_HOST_DIR)/tmp-helm/$(SAFEHOSTPLATFORM)/helm $(HELM)
	@rm -fr $(TOOLS_HOST_DIR)/tmp-helm
	@$(OK) installing helm $(HELM_VERSION)
endif

# helm3 download and install
$(HELM3):
	@$(INFO) installing helm3 $(HELM_VERSION)
	@mkdir -p $(TOOLS_HOST_DIR)/tmp-helm3
	@curl -fsSL https://get.helm.sh/helm-$(HELM3_VERSION)-$(SAFEHOSTPLATFORM).tar.gz | tar -xz -C $(TOOLS_HOST_DIR)/tmp-helm3
	@mv $(TOOLS_HOST_DIR)/tmp-helm3/$(SAFEHOSTPLATFORM)/helm $(HELM3)
	@rm -fr $(TOOLS_HOST_DIR)/tmp-helm3
	@$(OK) installing helm3 $(HELM_VERSION)

# kuttl download and install
$(KUTTL):
	@$(INFO) installing kuttl $(KUTTL_VERSION)
	@mkdir -p $(TOOLS_HOST_DIR)
	@curl -fsSLo $(KUTTL) --create-dirs https://github.com/kudobuilder/kuttl/releases/download/v$(KUTTL_VERSION)/kubectl-kuttl_$(KUTTL_VERSION)_$(HOST_PLATFORM) || $(FAIL)
	@chmod +x $(KUTTL)
	@$(OK) installing kuttl $(KUTTL_VERSION)

# chainsaw download and install
$(CHAINSAW):
	@$(INFO) installing chainsaw $(CHAINSAW_VERSION)
	@mkdir -p $(TOOLS_HOST_DIR)
	@curl -fsSLo $(CHAINSAW).tar.gz --create-dirs https://github.com/kyverno/chainsaw/releases/download/v$(CHAINSAW_VERSION)/chainsaw_$(HOST_PLATFORM).tar.gz || $(FAIL)
	@tar -xvf $(CHAINSAW).tar.gz chainsaw
	@mv chainsaw $(CHAINSAW)
	@chmod +x $(CHAINSAW)
	@rm $(CHAINSAW).tar.gz
	@$(OK) installing chainsaw $(CHAINSAW_VERSION)

# uptest download and install
$(UPTEST):
	@$(INFO) installing uptest $(UPTEST)
	@mkdir -p $(TOOLS_HOST_DIR)
	@curl -fsSLo $(UPTEST) https://github.com/upbound/uptest/releases/download/$(UPTEST_VERSION)/uptest_$(SAFEHOSTPLATFORM) || $(FAIL)
	@chmod +x $(UPTEST)
	@$(OK) installing uptest $(UPTEST)

# yq download and install
$(YQ):
	@$(INFO) installing yq $(YQ_VERSION)
	@mkdir -p $(TOOLS_HOST_DIR) && \
	curl -fsSLo $(YQ) https://github.com/mikefarah/yq/releases/download/$(YQ_VERSION)/yq_$(SAFEHOST_PLATFORM) && \
	chmod +x $(YQ) || $(FAIL)
	@$(OK) installing yq $(YQ_VERSION)
