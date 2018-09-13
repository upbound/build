# ====================================================================================
# Options

DOCS_VERSION := $(shell echo $(BRANCH_NAME) | sed -E "s/^release\-([0-9]+)\.([0-9]+)$$/v\1.\2/g")
DOCS_DIR ?= $(ROOT_DIR)/Documentation
DOCS_WORK_DIR := $(WORK_DIR)/upbound.github.io
DOCS_VERSION_DIR := $(DOCS_WORK_DIR)/docs/upbound/$(DOCS_VERSION)

ifdef GIT_API_TOKEN
DOCS_GIT_REPO := https://$(GIT_API_TOKEN)@github.com/upbound/upbound.github.io.git
else
DOCS_GIT_REPO := git@github.com:upbound/upbound.github.io.git
endif

# ====================================================================================
# Targets

docs.build:
	rm -rf $(DOCS_WORK_DIR)
	mkdir -p $(DOCS_WORK_DIR)
	git clone --depth=1 -b master $(DOCS_GIT_REPO) $(DOCS_WORK_DIR)
	rm -rf $(DOCS_VERSION_DIR)
	cp -r $(DOCS_DIR)/ $(DOCS_VERSION_DIR)
	cd $(DOCS_WORK_DIR) && npm install && node build/scripts/preprocess.js

docs.publish:
	$(DOCS_WORK_DIR)/build/publish.sh
