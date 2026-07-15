import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palettes.dart';
import 'app_typography.dart';

/// Tema Material 3 "Santuario" de Ora Ahora.
///
/// Este archivo es la palanca principal del rediseno: al estilizar aqui
/// AppBar, tarjetas, listas, dialogos, selector de hora, navegacion y
/// campos de texto, TODAS las pantallas (incluidas las de Ajustes que no
/// se tocaron una por una) heredan el mismo lenguaje visual.
class AppTheme {
  AppTheme._();

  static ThemeData fromPalette(AppPalette palette, {bool simpleMode = false}) {
    final scheme = palette.colorScheme;
    final buttonHeight = simpleMode ? 65.0 : 56.0;
    final serifOnSurface = AppTypography.headline.copyWith(
      fontSize: 20,
      color: scheme.onSurface,
    );

    final textTheme = TextTheme(
      displayLarge: AppTypography.display.copyWith(color: scheme.onSurface),
      displayMedium: AppTypography.display
          .copyWith(fontSize: 28, color: scheme.onSurface),
      headlineLarge: AppTypography.headline
          .copyWith(fontSize: 26, color: scheme.onSurface),
      headlineMedium: AppTypography.headline.copyWith(color: scheme.onSurface),
      headlineSmall: serifOnSurface,
      titleLarge: serifOnSurface,
      titleMedium: AppTypography.title.copyWith(color: scheme.onSurface),
      titleSmall: AppTypography.title
          .copyWith(fontSize: 15, color: scheme.onSurface),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: scheme.onSurface),
      bodyMedium: AppTypography.body.copyWith(color: scheme.onSurface),
      bodySmall: AppTypography.body
          .copyWith(fontSize: 13, color: scheme.onSurfaceVariant),
      labelLarge: AppTypography.title
          .copyWith(fontSize: 15, color: scheme.onSurface),
      labelMedium: AppTypography.caption.copyWith(color: scheme.onSurface),
      labelSmall: AppTypography.caption
          .copyWith(fontSize: 10.5, color: scheme.onSurfaceVariant),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.sansFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headline.copyWith(
          fontSize: 21,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
      ),
      cardTheme: CardThemeData(
        color: palette.isDark
            ? scheme.surfaceContainerHighest
            : Colors.white.withValues(alpha: 0.72),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.35),
          disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.8),
          minimumSize: Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: TextStyle(
            fontFamily: AppTypography.sansFamily,
            fontWeight: FontWeight.w700,
            fontSize: simpleMode ? 18 : 16,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.55)),
          minimumSize: Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: TextStyle(
            fontFamily: AppTypography.sansFamily,
            fontWeight: FontWeight.w700,
            fontSize: simpleMode ? 18 : 16,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(
            fontFamily: AppTypography.sansFamily,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        titleTextStyle: AppTypography.title
            .copyWith(fontSize: 16, color: scheme.onSurface),
        subtitleTextStyle: AppTypography.body
            .copyWith(fontSize: 13.5, color: scheme.onSurfaceVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primary,
        labelStyle: TextStyle(
          fontFamily: AppTypography.sansFamily,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: AppTypography.sansFamily,
          fontWeight: FontWeight.w600,
          color: scheme.onPrimary,
        ),
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontFamily: AppTypography.sansFamily,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: scheme.onSurface,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.isDark
            ? scheme.surfaceContainerHighest
            : Colors.white.withValues(alpha: 0.8),
        hintStyle: AppTypography.body.copyWith(color: scheme.onSurfaceVariant),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        titleTextStyle: AppTypography.headline.copyWith(
          fontSize: 21,
          color: scheme.onSurface,
        ),
        contentTextStyle: AppTypography.body.copyWith(color: scheme.onSurface),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: scheme.surface,
        dialBackgroundColor: scheme.surfaceContainerHighest,
        dialHandColor: scheme.primary,
        hourMinuteColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
        ),
        hourMinuteTextColor: scheme.onSurface,
        dayPeriodColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primaryContainer
              : scheme.surface,
        ),
        dayPeriodTextColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.brightness == Brightness.light
            ? AppColors.ink
            : scheme.surfaceContainerHighest,
        contentTextStyle: AppTypography.body.copyWith(
          color: Colors.white,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : scheme.outline,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }

  /// Temas heredados: se conservan como alias del tema por defecto para
  /// no romper referencias antiguas a `AppTheme.light()` / `dark()`.
  static ThemeData light() => fromPalette(AppPalette.zafiroCalmo);

  static ThemeData dark() => fromPalette(AppPalette.maresProfundos);
}
