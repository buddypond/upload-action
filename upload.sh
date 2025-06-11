#!/bin/bash

set -e

UPLOADS_SERVICE_URL="$1"
BP_API_KEY="$2"
PAD_NAME="$3"
ME="$4"
USER_FOLDER="$4"
# UPLOAD_FOLDER should be "pads/PAD_NAME"
UPLOAD_FOLDER="pads/$PAD_NAME"
UPLOAD_DIR="$5"
PAD_SERVICE_URL="$6"

# Input validation
if [[ -z "$BP_API_KEY" ]]; then
  echo "❌ Missing required input: bp_api_key"
  exit 1
fi

if [[ -z "$ME" ]]; then
  echo "❌ Missing required input: user"
  exit 1
fi

if [[ -z "$PAD_NAME" ]]; then
  echo "❌ Missing required input: name"
  exit 1
fi

if [[ "$PAD_NAME" =~ [^a-zA-Z0-9_-] ]]; then
  echo "❌ PAD_NAME contains invalid characters. Use only letters, numbers, dashes, or underscores."
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

if [[ -z "$PAD_SERVICE_URL" ]]; then
  echo "❌ Missing required input: PAD_SERVICE_URL"
  exit 1
fi

# first create the pad
echo "🔧 Creating pad for user: $ME"
echo "Pad Name: $PAD_NAME"
PAD_TITLE="$PAD_NAME"  # Use the folder name as the pad title
PAD_KEY="$PAD_NAME"  # Use the folder name as the pad key

echo "Pad Key: $PAD_KEY"

HTTP_STATUS=$(curl -s -o response.txt -w "%{http_code}" -X POST "$PAD_SERVICE_URL" \
  -H "Content-Type: application/json" \
  -H "bp-api-key: $BP_API_KEY" \
  -H "x-me: $ME" \
  -d '{
    "title": "'"$PAD_TITLE"'",
    "pad_key": "'"$PAD_KEY"'"
  }')

if [[ "$HTTP_STATUS" -ne 200 && "$HTTP_STATUS" -ne 201 ]]; then
  echo "❌ Failed to create pad (HTTP $HTTP_STATUS)"
  cat response.txt
  exit 1
fi

echo "✅ Pad created:"
cat response.txt

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

