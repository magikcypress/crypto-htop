#!/bin/bash

# Build script for GitHub releases
# Usage: ./build_release.sh [version]

VERSION=${1:-"1.0.0"}
PLATFORM=$(uname -s)
ARCH=$(uname -m)

echo "🚀 Building crypto-top v$VERSION for $PLATFORM-$ARCH"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/ dist/

# Build the binary
echo "📦 Creating binary..."
pyinstaller --onefile --name crypto-top crypto_top.py

# Create the release directory
RELEASE_DIR="crypto-top-v$VERSION-$PLATFORM-$ARCH"
mkdir -p "$RELEASE_DIR"

# Copy files
echo "📋 Copying files..."
cp dist/crypto-top "$RELEASE_DIR/"
cp README.md "$RELEASE_DIR/"
cp LICENSE "$RELEASE_DIR/"

# Create a smart install script
cat > "$RELEASE_DIR/install.sh" << 'EOF'
#!/bin/bash
set -e

echo "Installing crypto-top..."

# Recommended install path for Apple Silicon
TARGET="/opt/homebrew/bin/crypto-top"

# If /opt/homebrew/bin/ does not exist, use ~/bin/
if [ ! -d "/opt/homebrew/bin" ]; then
    mkdir -p "$HOME/bin"
    TARGET="$HOME/bin/crypto-top"
    echo "💡 /opt/homebrew/bin/ does not exist, installing in $HOME/bin/"
fi

cp crypto-top "$TARGET"
chmod +x "$TARGET"

echo "✅ crypto-top installed successfully!"
echo "Usage: $(basename $TARGET)"
echo "If you want to use it everywhere, add $(dirname $TARGET) to your PATH."
EOF

chmod +x "$RELEASE_DIR/install.sh"

# Create the archive
echo "📦 Creating archive..."
tar -czf "$RELEASE_DIR.tar.gz" "$RELEASE_DIR"

echo "✅ Build complete!"
echo "📁 Release files:"
echo "   - $RELEASE_DIR.tar.gz"
echo "   - $RELEASE_DIR/"

echo ""
echo "🎯 For GitHub release:"
echo "1. Create a new release on GitHub"
echo "2. Upload $RELEASE_DIR.tar.gz"
echo "3. Add release notes" 