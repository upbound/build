# ====================================================================================
# Options

ifeq ($(CHANNEL),)
$(error the CHANNEL variable must be set before including output.mk)
endif

ifeq ($(VERSION),)
$(error the VERSION variable must be set before including output.mk)
endif

ifeq ($(BRANCH_NAME),)
$(error the BRANCH_NAME variable must be set before including output.mk)
endif

ifeq ($(OUTPUT_DIR),)
$(error the CHANNEL variable must be set before including output.mk)
endif

ifeq ($(S3_BUCKET),)
$(error the S3_BUCKET variable must be set before including output.mk)
endif

S3_CP := aws s3 cp --only-show-errors
S3_SYNC := aws s3 sync --only-show-errors
S3_SYNC_DEL := aws s3 sync --only-show-errors --delete

# ====================================================================================
# Targets

output.init:
	@mkdir -p $(OUTPUT_DIR)
	@echo "$(VERSION)" > $(OUTPUT_DIR)/version

output.clean:
	@rm -fr $(OUTPUT_DIR)

output.publish:
	@$(INFO) publishing outputs to s3://$(S3_BUCKET)/build/$(BRANCH_NAME)/$(VERSION)
	@$(S3_SYNC_DEL) $(OUTPUT_DIR) s3://$(S3_BUCKET)/build/$(BRANCH_NAME)/$(VERSION) || $(FAIL)
	@$(OK) publishing outputs to s3://$(S3_BUCKET)/build/$(BRANCH_NAME)/$(VERSION)

output.promote:
	@$(INFO) promoting s3://$(S3_BUCKET)/$(CHANNEL)/$(VERSION)
	@$(S3_SYNC_DEL) s3://$(S3_BUCKET)/build/$(BRANCH_NAME)/$(VERSION) s3://$(S3_BUCKET)/$(CHANNEL)/$(VERSION) || $(FAIL)
	@$(S3_SYNC_DEL) s3://$(S3_BUCKET)/build/$(BRANCH_NAME)/$(VERSION) s3://$(S3_BUCKET)/$(CHANNEL)/current || $(FAIL)
	@$(OK) promoting s3://$(S3_BUCKET)/$(CHANNEL)/$(VERSION)

# ====================================================================================
# Common Targets

build.init: output.init
build.clean: output.clean
publish.artifacts: output.publish
promote.artifacts: output.promote
