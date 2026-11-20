# SPDX-License-Identifier: LGPL-3.0-or-later

include Makefile.version

envout:
	@echo "VERSION=$(VERSION)"
	@echo "SHA256=$(SHA256)"
	@echo "UNPACKED_VERSION=$(UNPACKED_VERSION)"
	@echo "BUILDARG_VERSION=$(BUILDARG_VERSION)"
	@echo "IMAGENAME=$(IMAGENAME)"
	@echo "BUILDARG_PLATFORM=$(BUILDARG_PLATFORM)"

# Set base-image.digest to the current digest of the base image.
update-base:
	docker buildx imagetools inspect $(BASE_IMAGE) --format '{{json .Manifest}}' | jq -r .digest > base-image.digest.new
	grep -qx 'sha256:[0-9a-f]\{64\}' base-image.digest.new
	mv base-image.digest.new base-image.digest

prepare:
	sudo apt-get -qq -y install curl jq

build:
	docker buildx build --pull $(BUILDARG_VERSION) $(BUILDARG_PLATFORM) -t $(IMAGENAME):latest .
	docker buildx build --pull $(BUILDARG_VERSION) --load -t $(IMAGENAME):latest .

.PHONY: test
test:
	misc/test.sh $(IMAGENAME):latest $(VERSION)

.PHONY: tag
tag: tag-push

.PHONY: tag-push
tag-push:
	docker buildx build --pull $(BUILDARG_VERSION) $(BUILDARG_PLATFORM) -t $(IMAGENAME):latest -t $(IMAGENAME):$(VERSION) . --push
