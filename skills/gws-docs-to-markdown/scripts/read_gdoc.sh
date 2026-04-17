#!/bin/bash
set -euo pipefail

# Export a Google Docs document as Markdown and extract embedded base64 images.

if [ $# -lt 2 ]; then
  echo "Usage: bash $0 GOOGLE_DOCS_URL_OR_ID OUTPUT_DIR" >&2
  exit 1
fi

INPUT="$1"
OUTPUT_DIR="$2"

# Extract DOC_ID from the URL. If the input is not a URL, treat it as a raw DOC_ID.
if echo "$INPUT" | grep -q '/document/d/'; then
  DOC_ID=$(echo "$INPUT" | grep -o '/document/d/[a-zA-Z0-9_-]*' | sed 's|/document/d/||')
else
  DOC_ID="$INPUT"
fi

# Validate DOC_ID to prevent JSON injection into the next gws call.
if [[ ! "$DOC_ID" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "Error: DOC_ID contains invalid characters: $DOC_ID" >&2
  exit 1
fi

DOC_ID_SHORT="${DOC_ID:0:8}"
IMAGES_DIR="${OUTPUT_DIR}/images_${DOC_ID_SHORT}"
RAW_FILE="${OUTPUT_DIR}/gdoc_export_raw.md"
CLEAN_FILE="${OUTPUT_DIR}/gdoc_${DOC_ID_SHORT}.md"

# Create output directories.
mkdir -p "$IMAGES_DIR"

# Export as Markdown.
echo "Exporting document ${DOC_ID}..." >&2
PARAMS=$(jq -n --arg id "$DOC_ID" '{"fileId": $id, "mimeType": "text/markdown"}')
gws drive files export --params "$PARAMS" -o "$RAW_FILE" >&2

# Extract images. '|| true' keeps the script successful when the document has no images.
grep '^\[image[0-9]*\]: <data:image/' "$RAW_FILE" | while IFS= read -r line; do
  NAME=$(echo "$line" | grep -o 'image[0-9]*' | head -1)
  # Map MIME type to file extension. Google normally returns PNG, but cover other types too.
  MIME=$(echo "$line" | sed 's/.*data:image\///' | sed 's/;.*//')
  case "$MIME" in
    png)  EXT="png" ;;
    jpeg) EXT="jpg" ;;
    gif)  EXT="gif" ;;
    *)    EXT="$MIME" ;;
  esac
  # Decode base64 and save.
  echo "$line" | sed 's/.*base64,//' | sed 's/>$//' | base64 -d > "${IMAGES_DIR}/${NAME}.${EXT}"
  echo "  Extracted: ${IMAGES_DIR}/${NAME}.${EXT}" >&2
done || true

# Build the cleaned Markdown: copy non-image lines first, then append local path references
# (handles docs where every line is an image too).
grep -v '^\[image[0-9]*\]: <data:image/' "$RAW_FILE" > "$CLEAN_FILE" || true

# Append local path references for the extracted images.
IMAGE_COUNT=0
for img_file in "$IMAGES_DIR"/image*.*; do
  [ -f "$img_file" ] || continue
  BASENAME=$(basename "$img_file")
  NAME="${BASENAME%.*}"
  echo "[${NAME}]: images_${DOC_ID_SHORT}/${BASENAME}" >> "$CLEAN_FILE"
  IMAGE_COUNT=$((IMAGE_COUNT + 1))
done

# Clean up intermediate file.
rm -f "$RAW_FILE"

# Result summary.
echo "---" >&2
echo "Markdown: ${CLEAN_FILE}" >&2
echo "Images: ${IMAGE_COUNT} files in ${IMAGES_DIR}/" >&2

# Print only the Markdown file path to stdout (easy for Claude to capture).
echo "$CLEAN_FILE"
