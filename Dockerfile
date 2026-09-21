# SPDX-License-Identifier: LGPL-3.0-or-later

# LanguageTool publishes no binary zip after 6.6, so the standalone
# distribution is built from the release tag. The build stage runs on the
# build host's own platform; its output is pure Java, so the runtime stage
# below is assembled for every target platform without emulation.
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

FROM docker.io/library/eclipse-temurin:17-jre

# see Makefile.version
ARG UNPACKED_VERSION

LABEL maintainer="Silvio Fricke <silvio.fricke@gmail.com>"

COPY --from=build /dist/LanguageTool /LanguageTool-"${UNPACKED_VERSION}"

WORKDIR /LanguageTool-"${UNPACKED_VERSION}"

COPY misc/start.sh .
CMD [ "bash", "start.sh" ]
USER nobody
EXPOSE 8010
