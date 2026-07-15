#!/usr/bin/env bash
# =====================================================================
# crear_llave_release.sh — Crea la llave de firma de Ora Ahora.
# LA CORRE MARIA (una sola vez). La contraseña la escribes TÚ y debes
# guardarla en un lugar seguro PARA SIEMPRE: sin ella no se puede
# actualizar la app en Play Store nunca más.
# Uso: bash crear_llave_release.sh   (desde la raíz del repo)
# =====================================================================
set -euo pipefail
test -f pubspec.yaml || { echo "Corre esto desde la raíz del repo"; exit 1; }
KS=android/keystore-ora-ahora.jks
if [ -f "$KS" ]; then
  echo "✅ La llave ya existe ($KS). No hay que hacer nada."
  exit 0
fi
echo "Vas a crear la llave de firma de Ora Ahora."
echo "⚠️  Elige una contraseña y GUÁRDALA (papel seguro o gestor de contraseñas)."
echo "    Si se pierde, NO podrás actualizar la app en Play Store."
echo ""
read -r -s -p "Contraseña (mínimo 6 caracteres): " P1; echo ""
read -r -s -p "Repítela: " P2; echo ""
if [ "$P1" != "$P2" ]; then echo "❌ No coinciden. Vuelve a correr el script."; exit 1; fi
if [ "${#P1}" -lt 6 ]; then echo "❌ Muy corta (mínimo 6). Vuelve a correr el script."; exit 1; fi
keytool -genkeypair -v -keystore "$KS" -alias oraahora \
  -keyalg RSA -keysize 2048 -validity 10950 \
  -storepass "$P1" -keypass "$P1" \
  -dname "CN=Ora Ahora, O=Ora Ahora, C=CO"
cat > android/key.properties <<KP
storePassword=$P1
keyPassword=$P1
keyAlias=oraahora
storeFile=../keystore-ora-ahora.jks
KP
echo ""
echo "✅ Llave creada y configurada. (keystore y key.properties están en"
echo "   .gitignore: NUNCA se suben a GitHub.)"
echo "Siguiente paso: avísale a Claude para compilar el .aab de release."
