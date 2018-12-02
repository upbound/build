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
