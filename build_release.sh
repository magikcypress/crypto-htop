#!/bin/bash

# Script de build pour les releases GitHub
# Usage: ./build_release.sh [version]

VERSION=${1:-"1.0.0"}
PLATFORM=$(uname -s)
ARCH=$(uname -m)

echo "🚀 Building crypto-top v$VERSION for $PLATFORM-$ARCH"

# Nettoyer les builds précédents
echo "🧹 Cleaning previous builds..."
rm -rf build/ dist/

# Créer le binaire
echo "📦 Creating binary..."
pyinstaller --onefile --name crypto-top crypto_top.py

# Créer le dossier de release
RELEASE_DIR="crypto-top-v$VERSION-$PLATFORM-$ARCH"
mkdir -p "$RELEASE_DIR"

# Copier les fichiers
echo "📋 Copying files..."
cp dist/crypto-top "$RELEASE_DIR/"
cp README.md "$RELEASE_DIR/"
cp LICENSE "$RELEASE_DIR/"

# Créer un script d'installation
cat > "$RELEASE_DIR/install.sh" << 'EOF'
#!/bin/bash
echo "Installing crypto-top..."
sudo cp crypto-top /usr/local/bin/
sudo chmod +x /usr/local/bin/crypto-top
echo "✅ crypto-top installed successfully!"
echo "Usage: crypto-top"
EOF

chmod +x "$RELEASE_DIR/install.sh"

# Créer l'archive
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