#!/bin/bash

CUR_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR=$(cd "$CUR_DIR/.." && pwd)

TILES_NAME="dequa_tiles.mbtiles"
TILES_TMP_NAME="dequa_tiles_$(date +%Y%m%d).mbtiles"
TMP_OUT_FOLDER="$PROJECT_DIR/data_tmp"
SERVER_PATH="$PROJECT_DIR/tileserver"
SERVER_TILES_PATH="$SERVER_PATH/mbtiles"


# if $TMP_OUT_FOLDER does not exist
if [ ! -d "$TMP_OUT_FOLDER" ]; then
    echo "Creating temporary folder: $TMP_OUT_FOLDER"
    mkdir -p "$TMP_OUT_FOLDER"
fi


if [ -f "$TMP_OUT_FOLDER/$TILES_TMP_NAME" ]; then
    # ask if overwrite (default no)
    read -p "⚠️ File $TILES_TMP_NAME already exists in TMP folder. Overwrite? [y/N] " confirm
    confirm=${confirm,,}  # lowercase
    if [[ "$confirm" != "y" && "$confirm" != "yes" ]]; then
        echo "Aborted."
        exit 0
    fi
fi


docker run --rm -e JAVA_TOOL_OPTIONS="-Xmx2g" \
    -v "$TMP_OUT_FOLDER":/data \
    ghcr.io/onthegomap/planetiler:latest \
    --download --area=italy --mbtiles=/data/$TILES_TMP_NAME


if [ -f "$SERVER_TILES_PATH/$TILES_TMP_NAME" ]; then
    # ask if overwrite (default no)
    read -p "⚠️ File $TILES_TMP_NAME already exists in SERVER folder. Overwrite? [y/N] " confirm
    confirm=${confirm,,}
    if [[ "$confirm" != "y" && "$confirm" != "yes" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo "Copy $TILES_TMP_NAME to server"

cp "$TMP_OUT_FOLDER/$TILES_TMP_NAME" "$SERVER_TILES_PATH/$TILES_TMP_NAME"

if [ -f "$SERVER_TILES_PATH/$TILES_NAME" ]; then
    # ask if overwrite (default no)
    read -p "⚠️ File $TILES_NAME already exists. Overwrite? [y/N] " confirm
    confirm=${confirm,,}
    if [[ "$confirm" != "y" && "$confirm" != "yes" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo "Update $TILES_NAME on server"
cp "$SERVER_TILES_PATH/$TILES_TMP_NAME" "$SERVER_TILES_PATH/$TILES_NAME"
rm "$SERVER_TILES_PATH/$TILES_TMP_NAME"

echo "✅ Done!"
