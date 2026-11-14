# tile-join (tippecanoe) used by join_tiles.sh: upstream publishes no image, so build it from a release tag
FROM alpine:3.20 AS build
ARG TIPPECANOE_VERSION=2.79.0
RUN apk add --no-cache build-base sqlite-dev zlib-dev bash git \
    && git clone --depth 1 --branch ${TIPPECANOE_VERSION} https://github.com/felt/tippecanoe.git /src \
    && make -C /src -j"$(nproc)" tile-join \
    && install -m 755 /src/tile-join /usr/local/bin/tile-join

FROM alpine:3.20
RUN apk add --no-cache sqlite-libs zlib libstdc++ libgcc
COPY --from=build /usr/local/bin/tile-join /usr/local/bin/tile-join
ENTRYPOINT ["tile-join"]
