#!/bin/bash

# Script to update release v1.0.3 on GitHub
echo "🔄 Updating release v1.0.3 on GitHub..."

# Configuration
REPO="magikcypress/crypto-top"
TAG="v1.0.3"
RELEASE_NAME="Crypto Top v1.0.3"
RELEASE_FILE="crypto-top-v1.0.3-Darwin-arm64.tar.gz"

# Check if the file exists
if [ ! -f "$RELEASE_FILE" ]; then
    echo "❌ Error: File $RELEASE_FILE not found"
    exit 1
fi

echo "📁 File found: $RELEASE_FILE"
echo "📦 Size: $(du -h "$RELEASE_FILE" | cut -f1)"

# Ask for GitHub token
echo ""
read -p "Enter your GitHub token: " GITHUB_TOKEN

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Token required to publish the release"
    exit 1
fi

echo ""
echo "🔄 Updating release..."

# Get the existing release ID
RELEASE_INFO=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$REPO/releases/tags/$TAG")

echo "Debug: $RELEASE_INFO"

RELEASE_ID=$(echo "$RELEASE_INFO" | grep -m1 '"id":' | grep -o '[0-9]\+')

if [ -z "$RELEASE_ID" ]; then
    echo "❌ Error: Unable to find release $TAG"
    exit 1
fi

echo "✅ Release found with ID: $RELEASE_ID"

# Delete existing assets
echo "🗑️ Deleting old assets..."
ASSETS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$REPO/releases/$RELEASE_ID/assets")

ASSET_IDS=$(echo "$ASSETS" | grep -o '"id":[0-9]*' | cut -d: -f2)

for asset_id in $ASSET_IDS; do
    curl -s -X DELETE \
        -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$REPO/releases/assets/$asset_id"
done

# Update the release
echo "📝 Updating description..."
UPDATE_RESPONSE=$(curl -s -X PATCH \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "{
        \"name\": \"$RELEASE_NAME\",
        \"body\": \"## Crypto Top v1.0.3\\n\\n### What's New\\n- 🐍 All dependencies are now bundled (no more ModuleNotFoundError)\\n- 🌍 English interface and documentation\\n- 🎨 Improved README with screenshot\\n- 🔧 Code cleanup and better error handling\\n\\n### Features\\n- Real-time cryptocurrency data display\\n- Top 50 cryptocurrencies by market cap\\n- 24h and 1h price evolution charts\\n- Auto-refresh every 30 seconds\\n- Colored terminal interface\\n\\n### Installation\\n1. Download the tar.gz file\\n2. Extract the archive: \`tar -xzf crypto-top-v1.0.3-Darwin-arm64.tar.gz\`\\n3. Run: \`./crypto-top\`\\n\\n### Usage\\n\`\`\`bash\\n./crypto-top\\n\`\`\`\\n\\n### System Requirements\\n- macOS ARM64 (Apple Silicon)\\n- No additional dependencies required\\n\\n### Previous Release\\n- [v1.0.2](https://github.com/magikcypress/crypto-top/releases/tag/v1.0.2)\"
    }" \
    "https://api.github.com/repos/$REPO/releases/$RELEASE_ID")

# Upload the new file
echo "📤 Uploading new file..."

UPLOAD_RESPONSE=$(curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/octet-stream" \
    --data-binary "@$RELEASE_FILE" \
    "https://uploads.github.com/repos/$REPO/releases/$RELEASE_ID/assets?name=$RELEASE_FILE")

if echo "$UPLOAD_RESPONSE" | grep -q "uploaded"; then
    echo "✅ File uploaded successfully!"
    echo ""
    echo "🎉 Release updated: https://github.com/$REPO/releases/tag/$TAG"
else
    echo "❌ Error during upload:"
    echo "$UPLOAD_RESPONSE"
    exit 1
fi 