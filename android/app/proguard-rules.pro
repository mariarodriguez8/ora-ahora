# Reglas minimas de ProGuard/R8 para Ora Ahora.
# flutter_local_notifications usa reflexion para algunas clases de soporte;
# se conservan para evitar fallos en builds ofuscadas (release).
-keep class com.dexterous.** { *; }
-keep class io.flutter.plugins.** { *; }
