#!/bin/bash

set -e

UPLOADS_SERVICE_URL="$1"
BP_API_KEY="$2"
ME="$3"
USER_FOLDER="$3"
UPLOAD_FOLDER="$4"
UPLOAD_DIR="$5"

# Input validation
if [[ -z "$BP_API_KEY" ]]; then
  echo "❌ Missing required input: bp_api_key"
  exit 1
fi

if [[ -z "$USER" ]]; then
  echo "❌ Missing required input: user"
  exit 1
fi

if [[ -z "$FOLDER" ]]; then
  echo "❌ Missing required input: folder"
  exit 1
fi

# Set default upload dir if not provided
if [[ -z "$UPLOAD_DIR" ]]; then
  UPLOAD_DIR="${GITHUB_WORKSPACE}"
fi

if [ ! -d "$UPLOAD_DIR" ]; then
  echo "Directory not found: $UPLOAD_DIR"
  exit 1
fi

echo "🔍 Scanning files from: $UPLOAD_DIR"

find "$UPLOAD_DIR" -type f \
  -not -path "$UPLOAD_DIR/.git/*" \
  -not -path "$UPLOAD_DIR/.github/*" | while read -r FILE_PATH; do

  RELATIVE_PATH="${FILE_PATH#$UPLOAD_DIR/}"
  FILE_SIZE=$(stat -c%s "$FILE_PATH")
  UPLOAD_KEY="$UPLOAD_FOLDER/$RELATIVE_PATH"
  CONTENT_TYPE=$(file --mime-type -b "$FILE_PATH")

  echo
  echo "➡️ Uploading $UPLOAD_KEY ($FILE_SIZE bytes, $CONTENT_TYPE)"

  SIGNED_URL_REQUEST="$UPLOADS_SERVICE_URL?v=6&fileName=$UPLOAD_KEY&fileSize=$FILE_SIZE&userFolder=$USER_FOLDER&bp_api_key=$BP_API_KEY&me=$ME&format=text"
  SIGNED_URL=$(curl -s -X GET "$SIGNED_URL_REQUEST")

  if [[ "$SIGNED_URL" == "null" || -z "$SIGNED_URL" ]]; then
    echo "❌ Failed to get signed URL for $UPLOAD_KEY"
    continue
  fi

  echo "Signed URL: $SIGNED_URL"

  curl -s -X PUT \
    -H "Content-Type: $CONTENT_TYPE" \
    --upload-file "$FILE_PATH" \
    "$SIGNED_URL"

  if [ $? -eq 0 ]; then
    echo "✅ Uploaded $UPLOAD_KEY"
  else
    echo "❌ Upload failed for $UPLOAD_KEY"
    exit 1
  fi
done

echo
echo "🏁 All done."

