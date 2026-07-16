#!/usr/bin/env bash
# =====================================================================
# apply_v10.sh — ORA AHORA v10: identificador propio.
# com.proqube.oraahora  →  com.oraahora.app  (applicationId, namespace,
# paquete Kotlin, MethodChannel y carpetas). Idempotente.
# Uso: bash apply_v10.sh   (desde la raíz del repo)
# =====================================================================
set -euo pipefail
test -f pubspec.yaml || { echo "Corre desde la raíz del repo"; exit 1; }

OLD="com.proqube.oraahora"
NEW="com.oraahora.app"
OLDDIR="android/app/src/main/kotlin/com/proqube/oraahora"
NEWDIR="android/app/src/main/kotlin/com/oraahora/app"

# 1) Mover los .kt a la carpeta nueva
if [ -d "$OLDDIR" ]; then
  mkdir -p "$NEWDIR"
  mv "$OLDDIR"/*.kt "$NEWDIR"/
  rm -rf android/app/src/main/kotlin/com/proqube
  echo "Carpetas Kotlin movidas."
fi

# 2) Reemplazar el identificador SOLO en código vivo y docs (no en los
#    apply_v*.sh históricos)
for f in \
  android/app/build.gradle \
  "$NEWDIR"/*.kt \
  lib/services/gate_service.dart \
  README.md \
  PROYECTO_ORA_AHORA.md \
  PLAY_STORE_LISTING.md
do
  [ -f "$f" ] && sed -i "s/${OLD}/${NEW}/g" "$f"
done

# 3) Verificación: nada vivo debe mencionar proqube
if grep -rn "proqube" android lib 2>/dev/null; then
  echo "ERROR: quedan referencias a proqube en código vivo"; exit 1
fi
echo "OK: identificador ahora es ${NEW}."
echo "Siguiente: flutter build appbundle --release (y nuevo APK de prueba si se quiere)."
