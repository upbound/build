# ====================================================================================
# Options

# the version of kubebuilder to use
KUBEBUILDER_VERSION ?= 1.0.4
KUBEBUILDER := $(TOOLS_HOST_DIR)/kubebuilder-$(KUBEBUILDER_VERSION)

# these are use by the kube builder test harness
TEST_ASSET_KUBE_APISERVER := $(KUBEBUILDER)/kube-apiserver
TEST_ASSET_ETCD := $(KUBEBUILDER)/etcd
TEST_ASSET_KUBECTL := $(KUBEBUILDER)/kubectl
export TEST_ASSET_KUBE_APISERVER TEST_ASSET_ETCD TEST_ASSET_KUBECTL

kubebuilder.codegen: $(KUBEBUILDER)
	@$(INFO) running kubebuilder generate
	@$(KUBEBUILDER)/kubebuilder generate || $(FAIL)
	@$(OK) kubebuilder generate

.PHONY: kubebuilder.codegen

# ====================================================================================
# Common Targets

test.init: $(KUBEBUILDER)

# ====================================================================================
# Special Targets

codegen: kubebuilder.codegen

define KUBEBULDER_HELPTEXT
Kubebuilder Targets:
    codegen      run code generation

endef
export KUBEBULDER_HELPTEXT

kubebuilder.help:
	@echo "$$KUBEBULDER_HELPTEXT"

help-special: kubebuilder.help

.PHONY: codegen kubebuilder.help

# ====================================================================================
# tools

# kubebuilder download and install
$(KUBEBUILDER):
	@$(INFO) installing kubebuilder
	@mkdir -p $(TOOLS_HOST_DIR)/tmp || $(FAIL)
	@curl -fsSL https://github.com/kubernetes-sigs/kubebuilder/releases/download/v$(KUBEBUILDER_VERSION)/kubebuilder_$(KUBEBUILDER_VERSION)_$(GOHOSTOS)_$(GOHOSTARCH).tar.gz | tar -xz -C $(TOOLS_HOST_DIR)/tmp  || $(FAIL)
	@mv $(TOOLS_HOST_DIR)/tmp/kubebuilder_$(KUBEBUILDER_VERSION)_$(GOHOSTOS)_$(GOHOSTARCH)/bin $(KUBEBUILDER) || $(FAIL)
	@rm -fr $(TOOLS_HOST_DIR)/tmp
	@$(OK) installing kubebuilder


