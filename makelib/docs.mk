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

ifndef DOCS_GIT_REPO
$(error DOCS_GIT_REPO must be defined)
endif

DOCS_WORK_DIR := $(WORK_DIR)/docs-repo

# ====================================================================================
# Targets

docs.init:
	rm -rf $(DOCS_WORK_DIR)
	mkdir -p $(DOCS_WORK_DIR)
	git clone --depth=1 -b master $(DOCS_GIT_REPO) $(DOCS_WORK_DIR)

docs.run: docs.init
	cd $(DOCS_WORK_DIR) $(MAKE) run

docs.validate: docs.generate
	cd $(DOCS_WORK_DIR) $(MAKE) validate


# ====================================================================================
# Common Targets
