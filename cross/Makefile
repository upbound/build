# ====================================================================================
# Setup Project

PLATFORMS := linux_amd64
include ../makelib/common.mk

IMAGE = $(BUILD_REGISTRY)/cross-$(ARCH)
CACHE_IMAGES = $(IMAGE)
include ../makelib/image.mk

# ====================================================================================
# Targets

img.build:
	@$(INFO) docker build $(IMAGE)
	@cp -a . $(IMAGE_TEMP_DIR)
	@docker build $(BUILD_ARGS) \
		--build-arg ARCH=$(ARCH) \
		--build-arg TINI_VERSION=$(TINI_VERSION) \
		-t $(IMAGE) \
		$(IMAGE_TEMP_DIR)
	@$(OK) docker build $(IMAGE)
