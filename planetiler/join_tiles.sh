#!/bin/bash
# Join base map, hydrants and rive into dequamap.mbtiles (one source for the client).
# Martin composite sources concatenate the gzipped tiles and browsers only read the first gzip
# stream, so the join must happen here. Called by download_tiles.sh; can also be run by hand.
# Does not restart Martin: the caller does it.
set -euo pipefail

CUR_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$CUR_DIR/.." && pwd)"

TMP_OUT_FOLDER="$PROJECT_DIR/data_tmp"
SERVER_TILES_PATH="$PROJECT_DIR/tileserver/mbtiles"
TIPPECANOE_IMAGE="dq-tippecanoe:2.79.0"  # keep in sync with TIPPECANOE_VERSION in tippecanoe.Dockerfile

if ! docker image inspect "$TIPPECANOE_IMAGE" >/dev/null 2>&1; then
    echo "Build $TIPPECANOE_IMAGE"
    docker build -t "$TIPPECANOE_IMAGE" -f "$CUR_DIR/tippecanoe.Dockerfile" "$CUR_DIR"
fi

mkdir -p "$TMP_OUT_FOLDER"

echo "Join dequa_all.mbtiles"
# --no-tile-size-limit: city tiles at z14 exceed the 500K default and would be dropped
docker run --rm --name dq_tile_join \
    -v "$SERVER_TILES_PATH":/in:ro \
    -v "$TMP_OUT_FOLDER":/data \
    "$TIPPECANOE_IMAGE" --force --no-tile-size-limit \
    -n "DeQua" -N "OpenMapTiles + hydrants + rive" \
    -o /data/dequa_all.mbtiles \
    /in/dequa_tiles.mbtiles /in/dequa_hydrants.mbtiles /in/dequa_rive.mbtiles /in/dequa_canali.mbtiles

# Copy under a name Martin ignores (not *.mbtiles), then rename atomically over the live file
cp "$TMP_OUT_FOLDER/dequa_all.mbtiles" "$SERVER_TILES_PATH/.dequa_all.mbtiles.part"
mv -f "$SERVER_TILES_PATH/.dequa_all.mbtiles.part" "$SERVER_TILES_PATH/dequa_all.mbtiles"
rm -f "$TMP_OUT_FOLDER/dequa_all.mbtiles"
