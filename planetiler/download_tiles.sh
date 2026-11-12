#!/bin/bash
# Build Italy tiles with planetiler and swap them into Martin. Non-interactive (meant for cron).
#  - dequa_tiles.mbtiles:    OpenMapTiles base map
#  - dequa_hydrants.mbtiles: fire hydrants (custom schema in hydrants.yml, missing from OpenMapTiles)
set -euo pipefail

CUR_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$CUR_DIR/.." && pwd)"

DATE="$(date +%Y%m%d)"
TMP_OUT_FOLDER="$PROJECT_DIR/data_tmp"
SERVER_TILES_PATH="$PROJECT_DIR/tileserver/mbtiles"
PLANETILER_IMAGE="ghcr.io/onthegomap/planetiler:latest"  # shortcut: moving tag, pin a version for reproducible builds
MARTIN_CONTAINER="dq_tiles_martin"
KEEP_BUILDS=2  # dated builds kept in data_tmp as backup

planetiler() {
    # Fixed name: recognizable in Dozzle and prevents two builds running at once
    docker run --rm --name dq_planetiler_build \
        -e JAVA_TOOL_OPTIONS="-Xmx2g" \
        -v "$TMP_OUT_FOLDER":/data \
        -v "$CUR_DIR":/schema:ro \
        "$PLANETILER_IMAGE" "$@"
}

# Copy under a name Martin ignores (not *.mbtiles), then rename atomically over the live file
publish() {
    local name="$1"
    echo "Update $name.mbtiles on server"
    cp "$TMP_OUT_FOLDER/${name}_$DATE.mbtiles" "$SERVER_TILES_PATH/.$name.mbtiles.part"
    mv -f "$SERVER_TILES_PATH/.$name.mbtiles.part" "$SERVER_TILES_PATH/$name.mbtiles"
    ls -1t "$TMP_OUT_FOLDER/${name}"_*.mbtiles | tail -n +$((KEEP_BUILDS + 1)) | xargs -r rm -f
}

mkdir -p "$TMP_OUT_FOLDER"

echo "Build dequa_tiles_$DATE.mbtiles"
planetiler --download --refresh-sources --area=italy --force \
    --mbtiles="/data/dequa_tiles_$DATE.mbtiles"

# Reuses data/sources/italy.osm.pbf just refreshed by the build above
echo "Build dequa_hydrants_$DATE.mbtiles"
planetiler generate-custom --schema=/schema/hydrants.yml --area=italy --force \
    --output="/data/dequa_hydrants_$DATE.mbtiles"

publish dequa_tiles
publish dequa_hydrants

# Martin keeps the old files open and only scans the folder at startup: restart it
if docker ps -q -f "name=^${MARTIN_CONTAINER}$" | grep -q .; then
    echo "Restart $MARTIN_CONTAINER"
    docker restart "$MARTIN_CONTAINER"
fi

echo "✅ Done!"
