#!/bin/bash

# Script pour publier la release sur GitHub
echo "🚀 Publication de la release v1.0.0 sur GitHub..."

# Configuration
REPO="magikcypress/crypto-top"
TAG="v1.0.0"
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
echo "🔑 Pour publier la release, vous avez besoin d'un token GitHub:"
echo "1. Allez sur https://github.com/settings/tokens"
echo "2. Cliquez sur 'Generate new token (classic)'"
echo "3. Donnez les permissions 'repo'"
echo "4. Copiez le token"
echo ""
read -p "Entrez votre token GitHub: " GITHUB_TOKEN

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Token requis pour publier la release"
    exit 1
fi

echo ""
echo "🔄 Création de la release..."

# Créer la release
RELEASE_RESPONSE=$(curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "{
        \"tag_name\": \"$TAG\",
        \"name\": \"Crypto Top v1.0.0\",
        \"body\": \"## Crypto Top v1.0.0\\n\\nPremière release de Crypto Top pour macOS ARM64.\\n\\n### Fonctionnalités\\n- Interface en ligne de commande pour suivre les cryptomonnaies\\n- Données en temps réel\\n- Support macOS ARM64\\n\\n### Installation\\n1. Téléchargez le fichier tar.gz\\n2. Extrayez l'archive\\n3. Exécutez ./crypto-top\\n\\n### Utilisation\\n\`\`\`bash\\n./crypto-top\\n\`\`\`\",
        \"draft\": false,
        \"prerelease\": false
    }" \
    "https://api.github.com/repos/$REPO/releases")

# Vérifier les erreurs
if echo "$RELEASE_RESPONSE" | grep -q "Bad credentials"; then
    echo "❌ Erreur: Token GitHub invalide"
    exit 1
fi

if echo "$RELEASE_RESPONSE" | grep -q "Not Found"; then
    echo "❌ Erreur: Repository $REPO non trouvé"
    exit 1
fi

# Extraire l'ID de la release
RELEASE_ID=$(echo "$RELEASE_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)

if [ -z "$RELEASE_ID" ]; then
    echo "❌ Erreur: Impossible de créer la release"
    echo "Réponse: $RELEASE_RESPONSE"
    exit 1
fi

echo "✅ Release créée avec l'ID: $RELEASE_ID"

# Uploader le fichier
echo "📤 Upload du fichier..."

UPLOAD_RESPONSE=$(curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/octet-stream" \
    --data-binary "@$RELEASE_FILE" \
    "https://uploads.github.com/repos/$REPO/releases/$RELEASE_ID/assets?name=$RELEASE_FILE")

if echo "$UPLOAD_RESPONSE" | grep -q "uploaded"; then
    echo "✅ Fichier uploadé avec succès!"
    echo ""
    echo "🎉 Release publiée: https://github.com/$REPO/releases/tag/$TAG"
else
    echo "❌ Erreur lors de l'upload:"
    echo "$UPLOAD_RESPONSE"
    exit 1
fi 