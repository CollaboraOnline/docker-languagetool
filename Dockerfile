# check=skip=InvalidDefaultArgInFrom
# SPDX-License-Identifier: LGPL-3.0-or-later

# LanguageTool publishes no binary zip after 6.6, so the standalone
# distribution is built from the release tag. The build stage runs on the
# build host's own platform; its output is pure Java, so the runtime stage
# below is assembled for every target platform without emulation.

# The runtime base image and the digest of it to build on, see
# Makefile.version and base-image.digest. They have no defaults: build with
# make, which passes them.
ARG BASE_IMAGE
ARG BASE_DIGEST

FROM --platform=$BUILDPLATFORM docker.io/library/maven:3-eclipse-temurin-17 AS build

# see Makefile.version
ARG VERSION

RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch v"${VERSION}" https://github.com/languagetool-org/languagetool.git /src

WORKDIR /src

COPY misc/maven-settings.xml /root/.m2/settings.xml

# The cache mount keeps the downloaded dependencies in the builder between
# builds; it is not part of the image.
RUN --mount=type=cache,target=/root/.m2/repository \
    mvn --batch-mode --quiet --projects languagetool-standalone --also-make package -DskipTests

RUN unzip -q languagetool-standalone/target/LanguageTool-*.zip -d /dist \
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

COPY --from=build /dist/LanguageTool /LanguageTool-"${UNPACKED_VERSION}"

WORKDIR /LanguageTool-"${UNPACKED_VERSION}"

COPY misc/start.sh .
CMD [ "bash", "start.sh" ]
USER nobody
EXPOSE 8010
