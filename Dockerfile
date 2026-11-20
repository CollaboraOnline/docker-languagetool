# check=skip=InvalidDefaultArgInFrom
# SPDX-License-Identifier: LGPL-3.0-or-later

# The LanguageTool distribution is the languagetool-standalone release on
# Maven Central, checked against its SHA-256 (see Makefile.version). It is
# unpacked on the build host's own platform; its content is pure Java, so the
# runtime stage below is assembled for every target platform without
# emulation.

# The runtime base image and the digest of it to build on, see
# Makefile.version and base-image.digest. They have no defaults: build with
# make, which passes them.
ARG BASE_IMAGE
ARG BASE_DIGEST

FROM --platform=$BUILDPLATFORM docker.io/library/busybox:stable AS unpack

# see Makefile.version
ARG VERSION
ARG SHA256

ADD --checksum=sha256:${SHA256} \
    https://repo1.maven.org/maven2/org/languagetool/languagetool-standalone/${VERSION}/languagetool-standalone-${VERSION}.zip \
    /languagetool.zip

RUN unzip -q /languagetool.zip -d /dist \
    && mv /dist/LanguageTool-* /dist/LanguageTool

FROM ${BASE_IMAGE}@${BASE_DIGEST}

# see Makefile.version
ARG UNPACKED_VERSION
ARG BASE_IMAGE
ARG BASE_DIGEST

LABEL org.opencontainers.image.title="LanguageTool" \
      org.opencontainers.image.description="LanguageTool HTTP server" \
      org.opencontainers.image.version="${UNPACKED_VERSION}" \
      org.opencontainers.image.source="https://github.com/CollaboraOnline/docker-languagetool" \
      org.opencontainers.image.licenses="LGPL-2.1-or-later" \
      org.opencontainers.image.base.name="${BASE_IMAGE}" \
      org.opencontainers.image.base.digest="${BASE_DIGEST}"

COPY --from=unpack /dist/LanguageTool /LanguageTool-"${UNPACKED_VERSION}"

WORKDIR /LanguageTool-"${UNPACKED_VERSION}"

COPY misc/start.sh .
CMD [ "bash", "start.sh" ]
USER nobody
EXPOSE 8010
