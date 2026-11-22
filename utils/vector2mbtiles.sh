#!/bin/bash
# Build a vector MBTiles overlay (canali, rive, ...) from any GDAL-readable file (shp, geojson, gpkg),
# then rebuild dequa_all.mbtiles (join_tiles.sh) and restart Martin.
# Usage: utils/vector2mbtiles.sh <layer> <input file> [comma-separated fields to keep]
#   utils/vector2mbtiles.sh canali canali/CAN_LAG_4326VE_v2.shp \
#       CAN_LAG_TY,TC_CODDEN,TC_SPECIE,TC_DENOM,VEL_MAX,VEL_MAX_MP,LIM_DIM,DIVIETO_TR,ONEWAY,BARCHE_A_R,ALTRE_PRES,COMPETENZA,TIPO_CANAL,NORMATIVA,STAZZA_MAX,LARGH_MAX
#   utils/vector2mbtiles.sh rive Rive/rive.geojson
# Output: tileserver/mbtiles/dequa_<layer>.mbtiles, source-layer <layer>. Needs GDAL (`conda activate dequa`).
# MBTILES_DIR=/some/dir only builds the file there (no join, no restart): useful for tests.
set -euo pipefail

CUR_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$CUR_DIR/.." && pwd)"
SERVER_TILES_PATH="$PROJECT_DIR/tileserver/mbtiles"
OUT_DIR="${MBTILES_DIR:-$SERVER_TILES_PATH}"
MARTIN_CONTAINER="dq_tiles_martin"
MAXZOOM=14  # same as dequa_tiles, needed by the join

LAYER="${1:-}"
INPUT="${2:-}"
FIELDS="${3:-}"
if [[ -z "$LAYER" || -z "$INPUT" ]]; then
    sed -n '4,8p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
fi
[[ -f "$INPUT" ]] || { echo "❌ $INPUT not found"; exit 1; }
command -v ogr2ogr >/dev/null || { echo "❌ ogr2ogr not found: activate the GDAL environment"; exit 1; }

OUT="$OUT_DIR/dequa_$LAYER.mbtiles"
# Build outside the served folder (GDAL needs the .mbtiles extension), then move it over the live file
PART="$PROJECT_DIR/data_tmp/dequa_$LAYER.mbtiles"
mkdir -p "$OUT_DIR" "$(dirname "$PART")"
rm -f "$PART"

echo "Build $OUT from $INPUT"
SELECT=()
[[ -n "$FIELDS" ]] && SELECT=(-select "$FIELDS")
ogr2ogr -f MBTiles "$PART" "$INPUT" -t_srs EPSG:4326 -nln "$LAYER" "${SELECT[@]}" \
    -dsco MINZOOM=0 -dsco MAXZOOM=$MAXZOOM -dsco NAME="DeQua $LAYER" \
    -dsco DESCRIPTION="$(basename "$INPUT")"
mv -f "$PART" "$OUT"

if [[ "$OUT_DIR" != "$SERVER_TILES_PATH" ]]; then
    echo "✅ $OUT (test build: no join, no restart)"
    exit 0
fi
