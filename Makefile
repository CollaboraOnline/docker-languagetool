# SPDX-License-Identifier: LGPL-3.0-or-later

include Makefile.version

envout:
	@echo "VERSION=$(VERSION)"
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
	sudo apt-get -qq -y install curl

build:
	docker buildx build --pull $(BUILDARG_VERSION) $(BUILDARG_PLATFORM) -t $(IMAGENAME):latest .
	docker buildx build --pull $(BUILDARG_VERSION) --load -t $(IMAGENAME):latest .

test: test-cleanup.1
test: test-start
test: test-java-version
test: test-run-test-lang
test: test-run-test-en
test: test-run-test-fr
test: test-cleanup.2

test-start:
	@echo ""
	docker run -d --name languagetool -p 127.0.0.1:8010:8010 $(IMAGENAME):latest

test-java-version:
	@echo ""
	docker exec languagetool java -version

test-run-test-lang:
	@echo ""
	curl -fsS --retry 30 --retry-connrefused --retry-all-errors --retry-delay 1 \
		-X GET \
		--header 'Accept: application/json' \
		'http://127.0.0.1:8010/v2/languages'

test-run-test-en:
	@echo ""
	curl -fsS \
		-X POST \
		--header 'Content-Type: application/x-www-form-urlencoded' \
		--header 'Accept: application/json' \
		-d 'text=hello%20woorld&language=en-US&motherTongue=de-DE&enabledOnly=false' \
		'http://127.0.0.1:8010/v2/check'

test-run-test-fr:
	@echo ""
	curl -fsS -X POST \
		--header 'Content-Type: application/x-www-form-urlencoded' \
		--header 'Accept: application/json' \
		-d 'text=hello%20woorld&language=fr&motherTongue=de-DE&enabledOnly=false' \
		'http://127.0.0.1:8010/v2/check'

.PHONY: test-cleanup
test-cleanup.%:
	@echo ""
	-docker container stop languagetool
	-docker container rm languagetool

.PHONY: tag
tag: tag-push

.PHONY: tag-push
tag-push:
	docker buildx build --pull $(BUILDARG_VERSION) $(BUILDARG_PLATFORM) -t $(IMAGENAME):latest -t $(IMAGENAME):$(VERSION) . --push
