#!/bin/bash
# Convert a folder of GeoTIFF orthophotos into a raster JPEG MBTiles served by Martin.
# Usage: utils/geotiff2mbtiles.sh [tiff_dir] [output.mbtiles]   (asks for missing values)
# Needs GDAL (e.g. `conda activate dequa`). Restart Martin afterwards.
set -euo pipefail

CUR_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$CUR_DIR/.." && pwd)"
DEFAULT_OUT="$PROJECT_DIR/tileserver/mbtiles/agea_2024.mbtiles"
QUALITY=80

for cmd in gdalbuildvrt gdal_translate gdaladdo; do
    command -v "$cmd" >/dev/null || { echo "❌ $cmd not found: activate the GDAL environment"; exit 1; }
done

IN_DIR="${1:-}"
[[ -z "$IN_DIR" ]] && read -rp "Folder with the .tif files: " IN_DIR
OUT="${2:-}"
[[ -z "$OUT" ]] && read -rp "Output MBTiles [$DEFAULT_OUT]: " OUT
OUT="${OUT:-$DEFAULT_OUT}"

shopt -s nullglob
TIFFS=("$IN_DIR"/*.tif "$IN_DIR"/*.tiff)
(( ${#TIFFS[@]} )) || { echo "❌ No .tif files in $IN_DIR"; exit 1; }
mkdir -p "$(dirname "$OUT")"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
# Build under a name Martin ignores (not *.mbtiles), then rename atomically over the live file
PART="$OUT.part"
rm -f "$PART"

echo "1/3 Mosaic of ${#TIFFS[@]} files"
gdalbuildvrt "$TMP_DIR/mosaic.vrt" "${TIFFS[@]}"

echo "2/3 Reproject and tile (JPEG q$QUALITY, native zoom)"
gdal_translate -of MBTILES -co TILE_FORMAT=JPEG -co QUALITY=$QUALITY \
    -co NAME="$(basename "$OUT" .mbtiles)" "$TMP_DIR/mosaic.vrt" "$PART"

echo "3/3 Lower zoom levels (overviews down to ~z11)"
gdaladdo -r average "$PART" 2 4 8 16 32 64 128 256

mv -f "$PART" "$OUT"
echo "✅ $OUT ($(du -h "$OUT" | cut -f1)). Restart Martin: docker restart dq_tiles_martin"
