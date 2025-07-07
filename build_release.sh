#!/bin/bash

# Build script for GitHub releases
# Usage: ./build_release.sh [version]

VERSION=${1:-"1.0.2"}
PLATFORM=$(uname -s)
ARCH=$(uname -m)

echo "🚀 Building crypto-htop v$VERSION for $PLATFORM-$ARCH"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/ dist/

# Build the binary
echo "📦 Creating binary..."
# Activate virtual environment and build
source venv/bin/activate && pyinstaller crypto-htop.spec

# Compress the binary with UPX
echo "🗜️ Compressing binary with UPX..."
if command -v upx &> /dev/null; then
    upx --best --lzma dist/crypto-htop
    echo "✅ Binary compressed with UPX"
else
    echo "⚠️ UPX not found, skipping compression"
fi

# Create the release directory
RELEASE_DIR="crypto-htop-v$VERSION-$PLATFORM-$ARCH"
mkdir -p "$RELEASE_DIR"

# Copy files
echo "📋 Copying files..."
cp dist/crypto-htop "$RELEASE_DIR/"
cp README.md "$RELEASE_DIR/"
cp LICENSE "$RELEASE_DIR/"

# Create a smart install script
cat > "$RELEASE_DIR/install.sh" << 'EOF'
#!/bin/bash
set -e

echo "Installing crypto-htop..."

# Recommended install path for Apple Silicon
TARGET_DIR="/opt/homebrew/bin"

# If /opt/homebrew/bin/ does not exist, use ~/bin/
if [ ! -d "$TARGET_DIR" ]; then
    TARGET_DIR="$HOME/bin"
    mkdir -p "$TARGET_DIR"
    echo "💡 /opt/homebrew/bin/ does not exist, installing in $HOME/bin/"
fi

# Copy the binary (onefile mode - no _internal needed)
cp crypto-htop "$TARGET_DIR/"

chmod +x "$TARGET_DIR/crypto-htop"

# Remove macOS quarantine attributes to avoid "Python.framework is damaged" error
echo "🔓 Removing macOS quarantine attributes..."
xattr -dr com.apple.quarantine "$TARGET_DIR/crypto-htop" 2>/dev/null || true

echo "✅ crypto-htop installed successfully!"
echo "Usage: $TARGET_DIR/crypto-htop"
echo "If you want to use it everywhere, add $TARGET_DIR to your PATH."
echo ""
echo "💡 Note: If you still see 'Python.framework is damaged', run:"
echo "   xattr -dr com.apple.quarantine $TARGET_DIR/crypto-htop"
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