#!/bin/bash
# Replace all occurrences of {TILES_SERVER_URL} with the environment variable value
# inside all JSON files under ./styles/

set -e

CUR_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR=$(cd "$CUR_DIR/.." && pwd)

STYLES_DIR="$PROJECT_DIR/styles"
STYLES_SERVER_DIR="$PROJECT_DIR/tileserver/styles"

# Ensure the variable is set
if [[ -z "$TILES_SERVER_URL" ]]; then
    echo "❌ Error: environment variable TILES_SERVER_URL is not set."
    echo "Usage example:"
    echo "  TILES_SERVER_URL='https://myserver.com' ./replace_tiles_url.sh"
    exit 1
fi


# Check folder exists
if [[ ! -d "$STYLES_DIR" ]]; then
    echo "❌ Folder $STYLES_DIR does not exist."
    exit 1
fi

# Check folder exists
if [[ ! -d "$STYLES_SERVER_DIR" ]]; then
    mkdir -p $STYLES_SERVER_DIR
fi

cp $STYLES_DIR/*.json $STYLES_SERVER_DIR

echo "🔧 Replacing {TILES_SERVER_URL} with '$TILES_SERVER_URL' in all JSON files under $STYLES_SERVER_DIR"

# Loop over all .json files recursively
find "$STYLES_SERVER_DIR" -type f -name "*.json" | while read -r file; do
    echo "  ➜ Processing $file"
    # Escape slashes for sed
    safe_url=$(printf '%s\n' "$TILES_SERVER_URL" | sed 's/[\/&]/\\&/g')
    # Replace placeholder
    sed -i "s/{TILES_SERVER_URL}/$safe_url/g" "$file"
done

echo "✅ Done!"
