#!/bin/bash

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

echo "Vérification de la signature de l'APK..."
echo "----------------------------------------"

# Vérifier si l'APK existe
if [ ! -f "$APK_PATH" ]; then
    echo "❌ APK non trouvé à $APK_PATH"
    exit 1
fi

# Vérifier la signature avec keytool
echo "🔍 Informations du certificat :"
unzip -p "$APK_PATH" "META-INF/*.RSA" | keytool -printcert

# Vérifier avec apksigner
echo -e "\n🔐 Vérification de la signature :"
apksigner verify --verbose "$APK_PATH"

# Vérifier si l'APK est debuggable
echo -e "\n📱 Vérification du mode debug :"
if unzip -p "$APK_PATH" AndroidManifest.xml | grep -q "android:debuggable=\"true\""; then
    echo "⚠️ L'APK est en mode debug"
else
    echo "✅ L'APK est en mode release"
fi

# Afficher la taille de l'APK
echo -e "\n📦 Taille de l'APK :"
ls -lh "$APK_PATH" | awk '{print $5}'