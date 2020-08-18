SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
SCRIPTS_DIR := $(SELF_DIR)/../scripts

KIND_CLUSTER_NAME ?= local-dev
LOCALDEV_CLONE_WITH ?= ssh # or https

DEPLOY_LOCAL_DIR ?= $(ROOT_DIR)/cluster/local
DEPLOY_LOCAL_WORKDIR := $(WORK_DIR)/local/localdev
DEPLOY_LOCAL_CONFIG_DIR := $(DEPLOY_LOCAL_WORKDIR)/config
DEPLOY_LOCAL_KUBECONFIG := $(DEPLOY_LOCAL_WORKDIR)/kubeconfig
KIND_CONFIG_FILE := $(DEPLOY_LOCAL_WORKDIR)/kind.yaml
KUBECONFIG ?= $(HOME)/.kube/config

LOCAL_BUILD ?= true

export KIND
export KUBECTL
export HELM
export HELM3
export GOMPLATE
export BUILD_REGISTRY
export ROOT_DIR
export SCRIPTS_DIR
export KIND_CLUSTER_NAME
export WORK_DIR
export LOCALDEV_INTEGRATION_CONFIG_REPO
export LOCAL_DEV_REPOS
export LOCALDEV_CLONE_WITH
export DEPLOY_LOCAL_DIR
export DEPLOY_LOCAL_WORKDIR
export DEPLOY_LOCAL_CONFIG_DIR
export DEPLOY_LOCAL_KUBECONFIG
export KIND_CONFIG_FILE
export KUBECONFIG
export LOCAL_BUILD
export HELM_OUTPUT_DIR
export BUILD_HELM_CHART_VERSION=$(HELM_CHART_VERSION)
export BUILD_HELM_CHARTS_LIST=$(HELM_CHARTS)
export BUILD_REGISTRIES=$(REGISTRIES)
export BUILD_IMAGES=$(IMAGES)
export BUILD_IMAGE_ARCHS=$(subst linux_,,$(filter linux_%,$(BUILD_PLATFORMS)))

# Install gomplate
GOMPLATE_VERSION := 3.7.0
GOMPLATE := $(TOOLS_HOST_DIR)/gomplate-$(GOMPLATE_VERSION)

gomplate.buildvars:
	@echo GOMPLATE=$(GOMPLATE)

build.vars: gomplate.buildvars

$(GOMPLATE):
	@$(INFO) installing gomplate $(HOSTOS)-$(HOSTARCH)
	@curl -fsSLo $(GOMPLATE) https://github.com/hairyhenderson/gomplate/releases/download/v$(GOMPLATE_VERSION)/gomplate_$(HOSTOS)-$(HOSTARCH) || $(FAIL)
	@chmod +x $(GOMPLATE)
	@$(OK) installing gomplate $(HOSTOS)-$(HOSTARCH)

kind.up: $(KIND)
	@$(INFO) kind up
	@$(KIND) get kubeconfig --name $(KIND_CLUSTER_NAME) >/dev/null 2>&1 || $(KIND) create cluster --name=$(KIND_CLUSTER_NAME) --config="$(KIND_CONFIG_FILE)" --kubeconfig="$(KUBECONFIG)"
	@$(KIND) get kubeconfig --name $(KIND_CLUSTER_NAME) > $(DEPLOY_LOCAL_KUBECONFIG)
	@$(OK) kind up

kind.down: $(KIND)
	@$(INFO) kind down
	@$(KIND) delete cluster --name=$(KIND_CLUSTER_NAME)
	@$(OK) kind down

kind.setcontext: $(KUBECTL) kind.up
	@$(KUBECTL) --kubeconfig $(KUBECONFIG) config use-context kind-$(KIND_CLUSTER_NAME)

kind.buildvars:
	@echo DEPLOY_LOCAL_KUBECONFIG=$(DEPLOY_LOCAL_KUBECONFIG)

build.vars: kind.buildvars
clean: local.down

.PHONY: kind.up kind.down kind.setcontext kind.buildvars

local.helminit: $(KUBECTL) $(HELM) kind.setcontext
	@$(INFO) helm init
	@docker pull gcr.io/kubernetes-helm/tiller:$(HELM_VERSION)
	@$(KIND) load docker-image gcr.io/kubernetes-helm/tiller:$(HELM_VERSION) --name=$(KIND_CLUSTER_NAME)
	@$(KUBECTL) --kubeconfig $(KUBECONFIG) --namespace kube-system get serviceaccount tiller > /dev/null 2>&1 || $(KUBECTL) --kubeconfig $(KUBECONFIG) --namespace kube-system create serviceaccount tiller
	@$(KUBECTL) --kubeconfig $(KUBECONFIG) get clusterrolebinding tiller-cluster-rule > /dev/null 2>&1 || $(KUBECTL) --kubeconfig $(KUBECONFIG) create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
	@$(HELM) ls > /dev/null 2>&1 || $(HELM) init --kubeconfig $(KUBECONFIG) --service-account tiller --upgrade --wait
	@$(HELM) repo update
	@$(OK) helm init

ifeq ($(LOCALDEV_INTEGRATION_CONFIG_REPO),)
$(DEPLOY_LOCAL_WORKDIR):
	@$(INFO) initializing local dev workdir
	@$(INFO) no integration config repo configured, using local config
	@mkdir -p $(DEPLOY_LOCAL_WORKDIR)
	@cp -rf $(DEPLOY_LOCAL_DIR)/. $(DEPLOY_LOCAL_WORKDIR)
	@$(OK) initializing local dev workdir
else
LOCALDEV_INTEGRATION_CONFIG_REPO_URL="git@github.com:$(LOCALDEV_INTEGRATION_CONFIG_REPO).git"
ifeq ($(LOCALDEV_CLONE_WITH),https)
	LOCALDEV_INTEGRATION_CONFIG_REPO_URL="https://github.com/$(LOCALDEV_INTEGRATION_CONFIG_REPO).git"
endif
$(DEPLOY_LOCAL_WORKDIR):
	@$(INFO) initializing local dev workdir
	@$(INFO) using integration config from repo $(LOCALDEV_INTEGRATION_CONFIG_REPO)
	@git clone --depth 1 $(LOCALDEV_INTEGRATION_CONFIG_REPO_URL) $(DEPLOY_LOCAL_WORKDIR)
	@$(OK) initializing local dev workdir
endif

-include $(DEPLOY_LOCAL_WORKDIR)/config.mk

local.prepare: $(DEPLOY_LOCAL_WORKDIR)
	@$(INFO) preparing local dev workdir
	@$(SCRIPTS_DIR)/localdev-prepare.sh || $(FAIL)
	@$(OK) preparing local dev workdir

local.clean:
	@$(INFO) cleaning local dev workdir
	@rm -rf $(WORK_DIR)/local || $(FAIL)
	@$(OK) cleaning local dev workdir

local.up: local.prepare kind.up local.helminit

local.down: kind.down

local.deploy.%: local.prepare $(KUBECTL) $(HELM) $(HELM3) $(HELM_HOME) $(GOMPLATE) kind.setcontext
	@$(INFO) localdev deploy component: $*
	@$(eval PLATFORMS=$(BUILD_PLATFORMS))
	@$(SCRIPTS_DIR)/localdev-deploy-component.sh $* || $(FAIL)
	@$(OK) localdev deploy component: $*

local.remove.%: local.prepare $(KUBECTL) $(HELM) $(HELM3) $(HELM_HOME) $(GOMPLATE) kind.setcontext
	@$(INFO) localdev remove component: $*
	@$(SCRIPTS_DIR)/localdev-remove-component.sh $* || $(FAIL)
	@$(OK) localdev remove component: $*

local.scaffold:
	@$(INFO) localdev scaffold config
	@$(SCRIPTS_DIR)/localdev-scaffold.sh || $(FAIL)
	@$(OK) localdev scaffold config

.PHONY: local.helminit local.up local.deploy.% local.remove.%  local.scaffold

# ====================================================================================
# Special Targets

fmt: go.imports
fmt.simplify: go.fmt.simplify
imports: go.imports
imports.fix: go.imports.fix
vendor: go.vendor
vendor.check: go.vendor.check
vendor.update: go.vendor.update
vet: go.vet
generate codegen: go.generate

define LOCAL_HELPTEXT
Local Targets:
    local.scaffold	scaffold a local development configuration
    local.up		stand up of a local development cluster with kind
    local.down		tear down local development cluster
    local.deploy.%	install/upgrade a local/external component, for example, local.deploy.crossplane
    local.remove.%	removes component, for example, local.remove.crossplane

endef
export LOCAL_HELPTEXT

local.help:
	@echo "$$LOCAL_HELPTEXT"

help-special: local.help

###