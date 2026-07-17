#!/usr/bin/env bash
# =====================================================================
# apply_v12.sh — ORA AHORA v12: permiso extra de MIUI (Xiaomi/Redmi/POCO).
#
# Problema detectado en pruebas con Redmi: aun con "Acceso de uso" y
# "Mostrar sobre otras apps" concedidos, MIUI/HyperOS bloquea el overlay
# de "Pausa y Ora" hasta que el usuario activa a mano, en Ajustes >
# Aplicaciones > Ora Ahora > Otros permisos, el permiso propio de MIUI
# "Mostrar ventanas emergentes mientras se ejecuta en segundo plano".
#
# Este script añade:
#  1. MainActivity.kt: isMiuiDevice / isMiuiBackgroundStartAllowed
#     (AppOps 10021 por reflexión) / openMiuiOtherPermissions (deep link
#     a la pantalla "Otros permisos" de MIUI, con fallback a la ficha de
#     la app) + sus handlers en el MethodChannel.
#  2. gate_service.dart: los tres wrappers Dart.
#  3. gate_explainer_screen.dart: TERCERA tarjeta de permiso, visible
#     solo en Xiaomi/Redmi/POCO, con estado en vivo y botón directo.
#  4. pubspec.yaml: 1.0.2+3 → 1.0.3+4.
#
# Idempotente. Uso: bash apply_v12.sh   (desde la raíz del repo)
# =====================================================================
set -euo pipefail
test -f pubspec.yaml || { echo "Corre desde la raíz del repo"; exit 1; }

MAIN="android/app/src/main/kotlin/com/oraahora/app/MainActivity.kt"
GATE="lib/services/gate_service.dart"
EXPL="lib/screens/gate_explainer/gate_explainer_screen.dart"

python3 - "$MAIN" "$GATE" "$EXPL" <<'PYEOF'
import sys

main_kt, gate_dart, expl_dart = sys.argv[1], sys.argv[2], sys.argv[3]

def read(p):
    with open(p, encoding="utf-8") as f:
        return f.read()

def write(p, s):
    with open(p, "w", encoding="utf-8") as f:
        f.write(s)

def insert_before(text, anchor, block, marker, path):
    if marker in text:
        print(f"  · {path}: ya aplicado, se omite")
        return text, False
    if anchor not in text:
        sys.exit(f"ERROR: ancla no encontrada en {path}:\n{anchor}")
    return text.replace(anchor, block + anchor, 1), True

# ---------------------------------------------------------------
# 1) MainActivity.kt
# ---------------------------------------------------------------
kt = read(main_kt)

kt, _ = insert_before(
    kt,
    "import android.os.PowerManager",
    "import android.app.AppOpsManager\nimport android.os.Process\n",
    "import android.app.AppOpsManager",
    main_kt,
)

handlers = '''                    "isMiuiDevice" -> result.success(isMiuiDevice())
                    "isMiuiBackgroundStartAllowed" ->
                        result.success(isMiuiBackgroundStartAllowed())
                    "openMiuiOtherPermissions" -> {
                        try {
                            openMiuiOtherPermissions()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("OPEN_SETTINGS_FAILED", e.message, null)
                        }
                    }
'''
kt, _ = insert_before(
    kt,
    '                    "isIgnoringBatteryOptimizations" -> {',
    handlers,
    '"isMiuiDevice" ->',
    main_kt,
)

methods = '''    // ---- v12: permiso extra de MIUI (Xiaomi/Redmi/POCO) ----

    /** true si el telefono es Xiaomi/Redmi/POCO (MIUI/HyperOS). */
    private fun isMiuiDevice(): Boolean {
        val m = Build.MANUFACTURER.lowercase()
        val b = Build.BRAND.lowercase()
        return m.contains("xiaomi") || b.contains("xiaomi") ||
            b.contains("redmi") || b.contains("poco")
    }

    /**
     * MIUI/HyperOS: comprueba su permiso propio "Mostrar ventanas
     * emergentes mientras se ejecuta en segundo plano" (AppOps 10021,
     * por reflexion porque no es API publica). Sin el, el overlay de
     * "Pausa y Ora" no aparece aunque los 2 permisos estandar esten
     * concedidos. Devuelve null si no aplica o no se pudo comprobar.
     */
    private fun isMiuiBackgroundStartAllowed(): Boolean? {
        if (!isMiuiDevice()) return null
        return try {
            val ops = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val method = AppOpsManager::class.java.getMethod(
                "checkOpNoThrow",
                Int::class.javaPrimitiveType,
                Int::class.javaPrimitiveType,
                String::class.java,
            )
            val mode = method.invoke(ops, 10021, Process.myUid(), packageName) as Int
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Abre la pantalla "Otros permisos" de MIUI para Ora Ahora (donde
     * vive "Mostrar ventanas emergentes en segundo plano"). Si el
     * dispositivo no la soporta, abre la ficha de la app en Ajustes.
     */
    private fun openMiuiOtherPermissions() {
        val editor = Intent("miui.intent.action.APP_PERM_EDITOR")
        editor.setClassName(
            "com.miui.securitycenter",
            "com.miui.permcenter.permissions.PermissionsEditorActivity",
        )
        editor.putExtra("extra_pkgname", packageName)
        editor.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            startActivity(editor)
        } catch (e: Exception) {
            val fallback = Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:$packageName"),
            )
            fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(fallback)
        }
    }

'''
kt, _ = insert_before(
    kt,
    "    private fun isIgnoringBatteryOptimizations(): Boolean {",
    methods,
    "isMiuiBackgroundStartAllowed(): Boolean?",
    main_kt,
)
write(main_kt, kt)
print(f"OK {main_kt}")

# ---------------------------------------------------------------
# 2) gate_service.dart
# ---------------------------------------------------------------
gd = read(gate_dart)

dart_methods = '''  // ---- v12: permiso extra de MIUI (Xiaomi/Redmi/POCO) ----

  /// true si el telefono es Xiaomi/Redmi/POCO (MIUI/HyperOS).
  Future<bool> isMiuiDevice() async {
    try {
      final miui = await _channel.invokeMethod<bool>('isMiuiDevice');
      return miui ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// MIUI: estado de su permiso "Mostrar ventanas emergentes mientras se
  /// ejecuta en segundo plano". `null` = no aplica o no se pudo comprobar.
  Future<bool?> isMiuiBackgroundStartAllowed() async {
    try {
      return await _channel
          .invokeMethod<bool?>('isMiuiBackgroundStartAllowed');
    } on PlatformException {
      return null;
    }
  }

  /// Abre la pantalla "Otros permisos" de MIUI para Ora Ahora.
  Future<void> openMiuiOtherPermissions() async {
    try {
      await _channel.invokeMethod('openMiuiOtherPermissions');
    } on PlatformException {
      // Nunca bloquear el flujo; el usuario puede llegar manualmente.
    }
  }

'''
gd, _ = insert_before(
    gd,
    "  /// Comprueba si Android ya excluyo a Ora Ahora de la optimizacion de",
    dart_methods,
    "isMiuiBackgroundStartAllowed()",
    gate_dart,
)
write(gate_dart, gd)
print(f"OK {gate_dart}")

# ---------------------------------------------------------------
# 3) gate_explainer_screen.dart
# ---------------------------------------------------------------
ex = read(expl_dart)

if "_miuiGranted" in ex:
    print(f"  · {expl_dart}: ya aplicado, se omite")
else:
    # 3a. Estado nuevo
    old = """  bool? _usageGranted;
  bool? _overlayGranted;
  bool _celebrated = false;

  bool get _allGranted => (_usageGranted ?? false) && (_overlayGranted ?? false);"""
    new = """  bool? _usageGranted;
  bool? _overlayGranted;
  bool _isMiui = false;
  bool? _miuiGranted;
  bool _celebrated = false;

  // En MIUI el tercer permiso cuenta; si no se pudo comprobar (null),
  // no bloquea el "Continuar".
  bool get _allGranted =>
      (_usageGranted ?? false) &&
      (_overlayGranted ?? false) &&
      (!_isMiui || (_miuiGranted ?? true));"""
    if old not in ex:
        sys.exit(f"ERROR: ancla 3a no encontrada en {expl_dart}")
    ex = ex.replace(old, new, 1)

    # 3b. _refreshStatus
    old = """    final gate = context.read<GateService>();
    final usage = await gate.hasUsageAccess();
    final overlay = await gate.hasOverlayPermission();
    if (!mounted) return;
    setState(() {
      _usageGranted = usage;
      _overlayGranted = overlay;
      _checking = false;
    });"""
    new = """    final gate = context.read<GateService>();
    final usage = await gate.hasUsageAccess();
    final overlay = await gate.hasOverlayPermission();
    final isMiui = await gate.isMiuiDevice();
    final miui = isMiui ? await gate.isMiuiBackgroundStartAllowed() : null;
    if (!mounted) return;
    setState(() {
      _usageGranted = usage;
      _overlayGranted = overlay;
      _isMiui = isMiui;
      _miuiGranted = miui;
      _checking = false;
    });"""
    if old not in ex:
        sys.exit(f"ERROR: ancla 3b no encontrada en {expl_dart}")
    ex = ex.replace(old, new, 1)

    # 3c. Titular dinamico
    old = """                    Text('Dos permisos, una sola misión 🙏',
                        style: AppTypography.headline),"""
    new = """                    Text(
                        _isMiui
                            ? 'Tres permisos, una sola misión 🙏'
                            : 'Dos permisos, una sola misión 🙏',
                        style: AppTypography.headline),"""
    if old not in ex:
        sys.exit(f"ERROR: ancla 3c no encontrada en {expl_dart}")
    ex = ex.replace(old, new, 1)

    # 3d. Tercera tarjeta tras la tarjeta 2
    old = """                      onPressed: () => _markSeenAnd(gate.openOverlaySettings),
                    ),
                    const SizedBox(height: 16),"""
    new = """                      onPressed: () => _markSeenAnd(gate.openOverlaySettings),
                    ),
                    if (_isMiui) ...[
                      const SizedBox(height: 14),
                      _PermisoCard(
                        numero: '3',
                        titulo: 'Xiaomi: ventanas en segundo plano',
                        descripcion:
                            'Tu teléfono Xiaomi/Redmi pide un permiso extra '
                            'para que la pausa de oración pueda aparecer '
                            'cuando Ora Ahora trabaja en segundo plano.',
                        granted: _miuiGranted,
                        botonTexto: 'Abrir "Otros permisos"',
                        instruccion:
                            'En la pantalla que se abre, activa "Mostrar '
                            'ventanas emergentes mientras se ejecuta en '
                            'segundo plano".',
                        onPressed: () =>
                            _markSeenAnd(gate.openMiuiOtherPermissions),
                      ),
                    ],
                    const SizedBox(height: 16),"""
    if old not in ex:
        sys.exit(f"ERROR: ancla 3d no encontrada en {expl_dart}")
    ex = ex.replace(old, new, 1)

    # 3e. Mensaje de "falta X" con el tercer permiso
    old = """                                  final falta = (_usageGranted ?? false)
                                      ? 'el permiso 2: "Mostrar sobre otras apps"'
                                      : ((_overlayGranted ?? false)
                                          ? 'el permiso 1: "Acceso de uso"'
                                          : 'los dos permisos');"""
    new = """                                  final pendientes = <String>[
                                    if (!(_usageGranted ?? false))
                                      '1: "Acceso de uso"',
                                    if (!(_overlayGranted ?? false))
                                      '2: "Mostrar sobre otras apps"',
                                    if (_isMiui && _miuiGranted == false)
                                      '3: "Ventanas en segundo plano"',
                                  ];
                                  final falta = pendientes.length == 1
                                      ? 'el permiso ${pendientes.first}'
                                      : 'los permisos ${pendientes.join(' y ')}';"""
    if old not in ex:
        sys.exit(f"ERROR: ancla 3e no encontrada en {expl_dart}")
    ex = ex.replace(old, new, 1)

    write(expl_dart, ex)
    print(f"OK {expl_dart}")
PYEOF

# ---------------------------------------------------------------
# 4) Version 1.0.2+3 → 1.0.3+4
# ---------------------------------------------------------------
if grep -q "^version: 1.0.2+3" pubspec.yaml; then
  sed -i 's/^version: 1.0.2+3/version: 1.0.3+4/' pubspec.yaml
  echo "OK pubspec.yaml → 1.0.3+4"
else
  echo "  · pubspec.yaml: version ya distinta de 1.0.2+3, no se toca"
fi

echo ""
echo "v12 aplicado. Siguiente paso:"
echo "  flutter clean && flutter pub get && flutter build appbundle --release"
echo "(recuerda el namespace de device_apps en el pub-cache tras pub get limpio)"
