<!-- SPDX-License-Identifier: LGPL-3.0-or-later -->

# LanguageTool server image

[LanguageTool] is an open source grammar, style and spelling checker for
English, French, German, Polish, Spanish and some thirty other languages.
This repository builds the `collabora/languagetool` image on Docker Hub:
the LanguageTool HTTP server, from the languagetool-standalone release
on Maven Central, on the Eclipse Temurin Java runtime. Collabora Office
uses it as a remote sentence checker; see `docker/languagetool` in
https://github.com/CollaboraOnline/online for running it beside Collabora
Office. It is based on the original image by Silvio Fricke,
`silviof/docker-languagetool`.

The image is free to use, but unsupported. LanguageTool is released under
the LGPL 2.1 or later; its licence text and the licences of the third
party libraries are in the image, in `/LanguageTool-<version>`.

[LanguageTool]: https://languagetool.org/

# Usage

The server listens on port 8010, speaks plain HTTP, and has no
authentication: keep it on localhost or on an internal network, or behind
a reverse proxy that serves HTTPS.

    docker run --rm -p 127.0.0.1:8010:8010 collabora/languagetool
    curl -d 'text=The%20catt%20sat%20down.&language=en-US' http://127.0.0.1:8010/v2/check

The API is described at https://languagetool.org/http-api/swagger-ui/;
`/v2/languages` is an easy request to see that the server runs.

The environment variables of the container:

- `JAVAOPTIONS` goes to the Java runtime, as in `JAVAOPTIONS=-Xmx768m`.
- `EXTRAOPTIONS` goes to the server; its options are listed at
  https://dev.languagetool.org/http-server.
- A server configuration property is set with a variable of its name
  prefixed with `LT_`, as in `LT_maxTextLength=50000`. They are written to
  `/tmp/config.properties` at start.

With the fewest rights and a memory limit; `/tmp` must stay writable for
the `LT_` variables:

    docker run --name languagetool \
        --cap-drop=ALL \
        --user=65534:65534 \
        --read-only --tmpfs /tmp \
        -p 127.0.0.1:8010:8010 \
        --memory 412m --memory-swap 500m \
        -e JAVAOPTIONS=-Xmx382m \
        collabora/languagetool

## n-gram data

LanguageTool finds more confused words with [n-gram data], which is large
(several gigabytes per language) and is not in the image. Unpack it on the
host and mount the directory at `/ngrams`:

    mkdir ngrams
    wget https://languagetool.org/download/ngram-data/ngrams-en-20150817.zip
    (cd ngrams && unzip ../ngrams-en-20150817.zip)
    rm -f ngrams-en-20150817.zip
    docker run -d --name languagetool -p 127.0.0.1:8010:8010 \
        -v "$PWD"/ngrams:/ngrams:ro --restart=unless-stopped \
        collabora/languagetool

The LanguageTool browser add-on can use this server with its "Local server
(localhost)" setting, which expects it at port 8081: publish it with
`-p 127.0.0.1:8081:8010` for that.

[n-gram data]: https://dev.languagetool.org/finding-errors-using-n-gram-data

# Building

    make build    # all platforms, then the host platform into the local image store
    make test     # start the local image and check that it serves $(VERSION)
    make tag      # build and push :latest and :$(VERSION) to $(IMAGENAME)

`Makefile.version` holds the LanguageTool version and the SHA-256 of its
languagetool-standalone zip on Maven Central, the image name and the
runtime base image; `base-image.digest` holds the digest of the base image
that the image is built on, and `make update-base` sets it to the current
one.

The release workflow builds, tests and pushes the image for a release tag
and when started by hand. Once a day it also compares the current digest of
the base image with `base-image.digest`; when they differ, it rebuilds on
the new base, pushes the image, and commits the new digest. It logs in to
Docker Hub with the `DOCKERHUB_USERNAME` and `DOCKERHUB_PASSWORD` secrets
of the repository.
