#!/bin/bash

# Script pour uploader le fichier à la release existante
echo "📤 Upload du fichier à la release v1.0.0..."

# Configuration
REPO="magikcypress/crypto-top"
RELEASE_ID="230397757"
RELEASE_FILE="crypto-top-v1.0.0-Darwin-arm64.tar.gz"

# Vérifier que le fichier existe
if [ ! -f "$RELEASE_FILE" ]; then
    echo "❌ Erreur: Fichier $RELEASE_FILE non trouvé"
    exit 1
fi

echo "📁 Fichier trouvé: $RELEASE_FILE"
echo "📦 Taille: $(du -h "$RELEASE_FILE" | cut -f1)"

# Demander le token GitHub
echo ""
read -p "Entrez votre token GitHub: " GITHUB_TOKEN

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Token requis pour uploader le fichier"
    exit 1
fi

echo ""
echo "🔄 Upload du fichier..."

# Uploader le fichier
UPLOAD_RESPONSE=$(curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/octet-stream" \
    --data-binary "@$RELEASE_FILE" \
    "https://uploads.github.com/repos/$REPO/releases/$RELEASE_ID/assets?name=$RELEASE_FILE")

if echo "$UPLOAD_RESPONSE" | grep -q "uploaded"; then
    echo "✅ Fichier uploadé avec succès!"
    echo ""
    echo "🎉 Release complète: https://github.com/$REPO/releases/tag/v1.0.0"
else
    echo "❌ Erreur lors de l'upload:"
    echo "$UPLOAD_RESPONSE"
    exit 1
fi 