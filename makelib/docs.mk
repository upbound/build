# ====================================================================================
# Options

ifndef SOURCE_DOCS_DIR
$(error SOURCE_DOCS_DIR must be defined)
endif

ifndef DEST_DOCS_DIR
$(error DEST_DOCS_DIR must be defined)
endif

ifndef DOCS_GIT_REPO
$(error DOCS_GIT_REPO must be defined)
endif

DOCS_VERSION := $(shell echo $(BRANCH_NAME) | sed -E "s/^release\-([0-9]+)\.([0-9]+)$$/v\1.\2/g")
DOCS_WORK_DIR := $(WORK_DIR)/docs-repo
DOCS_VERSION_DIR := $(DOCS_WORK_DIR)/$(DEST_DOCS_DIR)/$(DOCS_VERSION)

# ====================================================================================
# Targets

docs.publish:
	rm -rf $(DOCS_WORK_DIR)
	mkdir -p $(DOCS_WORK_DIR)
	git clone --depth=1 -b master $(DOCS_GIT_REPO) $(DOCS_WORK_DIR)
	rm -rf $(DOCS_VERSION_DIR)
	cp -r $(SOURCE_DOCS_DIR)/ $(DOCS_VERSION_DIR)
	cd $(DOCS_WORK_DIR) && DOCS_VERSION=$(DOCS_VERSION) $(MAKE) publish

# ====================================================================================
# Common Targets

# only publish docs for master and release branches
ifneq ($(filter master release-%,$(BRANCH_NAME)),)
publish.artifacts: docs.publish
endif
