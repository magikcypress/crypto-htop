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
