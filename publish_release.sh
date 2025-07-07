#!/bin/bash

VERSION="$1"

# Script to create a release on GitHub
echo "🚀 Publishing release v${VERSION} on GitHub..."

# Configuration
REPO="magikcypress/crypto-htop"
TAG="v${VERSION}"
RELEASE_NAME="Crypto htop v${VERSION}"
RELEASE_FILE="crypto-htop-v${VERSION}-Darwin-arm64.tar.gz"

# Check if the file exists
if [ ! -f "$RELEASE_FILE" ]; then
    echo "❌ Error: File $RELEASE_FILE not found"
    echo "💡 Creating binary..."
    ./build_release.sh $VERSION
fi

if [ ! -f "$RELEASE_FILE" ]; then
    echo "❌ Error: Unable to create file $RELEASE_FILE"
    exit 1
fi

echo "📁 File found: $RELEASE_FILE"
echo "📦 Size: $(du -h "$RELEASE_FILE" | cut -f1)"

# Ask for GitHub token
echo ""
echo "🔑 To publish the release, you need a GitHub token:"
echo "1. Go to https://github.com/settings/tokens"
echo "2. Click on 'Generate new token (classic)'"
echo "3. Give 'repo' permissions"
echo "4. Copy the token"
echo ""
read -p "Enter your GitHub token: " GITHUB_TOKEN

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Token required to publish the release"
    exit 1
fi

echo ""
echo "🔄 Checking if release exists..."

# Try to get the release by tag
RELEASE_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$REPO/releases/tags/$TAG")

echo "🔍 Debug: API Response for release check:"
echo "$RELEASE_RESPONSE"
echo ""

RELEASE_ID=$(echo "$RELEASE_RESPONSE" | grep -o '"id": [0-9]*' | head -1 | cut -d' ' -f2)

echo "🔍 Debug: Extracted RELEASE_ID: '$RELEASE_ID'"

if echo "$RELEASE_RESPONSE" | grep -q '"id":'; then
    echo "✅ Release exists with ID: $RELEASE_ID"
else
    echo "🔄 Creating release..."
    # Create the release
    CREATE_RESPONSE=$(curl -s -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "{\"tag_name\": \"$TAG\", \"name\": \"$RELEASE_NAME\", \"body\": \"## Crypto Top v$VERSION\\n\\n### What's New\\n- 🚀 Ultra-fast startup (onedir mode)\\n- 📦 23% smaller binary size\\n- 🌍 English interface and documentation\\n- 🎨 Improved README with screenshot\\n\\n### Features\\n- Real-time cryptocurrency data display\\n- Top 50 cryptocurrencies by market cap\\n- 24h and 1h price evolution charts\\n- Auto-refresh every 30 seconds\\n- Colored terminal interface\\n\\n### Installation\\n1. Download the tar.gz file\\n2. Extract the archive: \`tar -xzf crypto-top-v$VERSION-Darwin-arm64.tar.gz\`\\n3. Run: \`./crypto-top/crypto-top\`\\n\\n### Usage\\n\`\`\`bash\\n./crypto-top/crypto-top\\n\`\`\`\\n\\n### System Requirements\\n- macOS ARM64 (Apple Silicon)\\n- No additional dependencies required\\n\\n### Previous Release\\n- [v1.0.5](https://github.com/magikcypress/crypto-top/releases/tag/v1.0.5)\", \"draft\": false, \"prerelease\": false}" \
        "https://api.github.com/repos/$REPO/releases")
    RELEASE_ID=$(echo "$CREATE_RESPONSE" | grep -o '"id": [0-9]*' | head -1 | cut -d' ' -f2)
    echo "🔍 Debug: Extracted RELEASE_ID after creation: '$RELEASE_ID'"
    if [ -z "$RELEASE_ID" ]; then
        echo "❌ Error: Unable to create or find release"
        echo "Response: $CREATE_RESPONSE"
        exit 1
    fi
    echo "✅ Release created with ID: $RELEASE_ID"
fi

# Upload the file
# Check if asset already exists
ASSETS_URL="https://api.github.com/repos/$REPO/releases/$RELEASE_ID/assets"
ASSETS_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" "$ASSETS_URL")
if echo "$ASSETS_RESPONSE" | grep -q "$RELEASE_FILE"; then
    echo "⚠️ Asset $RELEASE_FILE already exists. Deleting old asset..."
    ASSET_ID=$(echo "$ASSETS_RESPONSE" | grep -B 2 "$RELEASE_FILE" | grep '"id":' | head -1 | grep -o '[0-9]\+')
    if [ -n "$ASSET_ID" ]; then
        curl -s -X DELETE -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$REPO/releases/assets/$ASSET_ID"
        echo "🗑️ Old asset deleted."
    fi
fi

echo "📤 Uploading file..."
UPLOAD_RESPONSE=$(curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/octet-stream" \
    --data-binary "@$RELEASE_FILE" \
    "https://uploads.github.com/repos/$REPO/releases/$RELEASE_ID/assets?name=$RELEASE_FILE")

if echo "$UPLOAD_RESPONSE" | grep -q '"state":"uploaded"'; then
    echo "✅ File uploaded successfully!"
    echo ""
    echo "🎉 Release published: https://github.com/$REPO/releases/tag/$TAG"
else
    echo "❌ Error during upload:"
    echo "$UPLOAD_RESPONSE"
    exit 1
fi 