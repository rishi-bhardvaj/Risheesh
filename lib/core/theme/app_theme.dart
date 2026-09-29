import 'package:flutter/material.dart';

/// Groww-style design system: near-black surfaces, one green accent, big
/// bold numbers, soft rounded cards and pill filters. Dark is the default;
/// the light theme mirrors it for users who switch.
class AppTheme {
  // Accent & status
  static const Color accent = Color(0xFF00D09C); // Groww green
  static const Color accentDeep = Color(0xFF00B386);
  static const Color success = accent;
  static const Color warning = Color(0xFFFFB84D);
  static const Color error = Color(0xFFEB5B3C);
  static const Color info = Color(0xFF5B8DEF);
  static const Color violet = Color(0xFF8C7CF0);

  // Dark surfaces
  static const Color bg = Color(0xFF121212);
  static const Color card = Color(0xFF1C1C1E);
  static const Color cardHigh = Color(0xFF26262A);
  static const Color stroke = Color(0xFF2C2C30);
  static const Color textHigh = Color(0xFFF5F5F5);
  static const Color textMid = Color(0xFFA3A3A8);
  static const Color textLow = Color(0xFF6E6E73);

  static const _dark = ColorScheme(
    brightness: Brightness.dark,
    primary: accent,
    onPrimary: Color(0xFF00241B),
    primaryContainer: Color(0xFF003D2F),
    onPrimaryContainer: Color(0xFFB8F5E3),
    secondary: violet,
    onSecondary: Colors.white,
    tertiary: warning,
    onTertiary: Colors.black,
    error: error,
    onError: Colors.white,
    surface: bg,
    onSurface: textHigh,
    onSurfaceVariant: textMid,
    surfaceContainerLowest: Color(0xFF0C0C0D),
    surfaceContainerLow: Color(0xFF171719),
    surfaceContainer: card,
    surfaceContainerHigh: cardHigh,
    surfaceContainerHighest: Color(0xFF303034),
    outline: Color(0xFF3A3A3F),
    outlineVariant: stroke,
    inverseSurface: textHigh,
    onInverseSurface: bg,
    inversePrimary: accentDeep,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );

  static const _light = ColorScheme(
    brightness: Brightness.light,
    primary: accentDeep,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFD7F7EE),
    onPrimaryContainer: Color(0xFF00382B),
    secondary: Color(0xFF5B4FD6),
    onSecondary: Colors.white,
    tertiary: Color(0xFFE09B2D),
    onTertiary: Colors.black,
    error: Color(0xFFD9472B),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Color(0xFF16161A),
    onSurfaceVariant: Color(0xFF6B6B73),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFF7F7F8),
    surfaceContainer: Color(0xFFF4F4F6),
    surfaceContainerHigh: Color(0xFFECECEF),
    surfaceContainerHighest: Color(0xFFE2E2E6),
    outline: Color(0xFFD0D0D6),
    outlineVariant: Color(0xFFE8E8EC),
    inverseSurface: Color(0xFF1C1C1E),
    onInverseSurface: Colors.white,
    inversePrimary: accent,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );

  static ThemeData get darkTheme => _build(_dark);
  static ThemeData get lightTheme => _build(_light);

  static ThemeData _build(ColorScheme cs) {
    final base = ThemeData(brightness: cs.brightness, useMaterial3: true).textTheme;
    final text = base
        .copyWith(
          displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
          headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8),
          headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.1),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          bodyMedium: base.bodyMedium?.copyWith(height: 1.4),
          bodySmall: base.bodySmall?.copyWith(height: 1.35),
          labelSmall: base.labelSmall?.copyWith(letterSpacing: 0.2),
        )
        .apply(bodyColor: cs.onSurface, displayColor: cs.onSurface);
    final r16 = BorderRadius.circular(16);
    final r12 = BorderRadius.circular(12);

    return ThemeData(
      useMaterial3: true,
      brightness: cs.brightness,
      colorScheme: cs,
      textTheme: text,
      scaffoldBackgroundColor: cs.surface,
      splashFactory: InkSparkle.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      }),
      cardTheme: CardThemeData(
        color: cs.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: r16),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: cs.onSurface,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: cs.primary, width: 2.5),
          borderRadius: BorderRadius.circular(2),
        ),
        dividerColor: cs.outlineVariant,
        labelStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontSize: 11.5,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? cs.primary : cs.onSurfaceVariant,
            )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              size: 24,
              color: s.contains(WidgetState.selected) ? cs.primary : cs.onSurfaceVariant,
            )),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: r12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outline),
          shape: RoundedRectangleBorder(borderRadius: r12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          foregroundColor: cs.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(minimumSize: const Size(44, 44))),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: r16),
        extendedTextStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: cs.primary.withValues(alpha: 0.14),
        side: WidgetStateBorderSide.resolveWith(
          (s) => BorderSide(color: s.contains(WidgetState.selected) ? cs.primary : cs.outline),
        ),
        shape: const StadiumBorder(),
        labelStyle: WidgetStateTextStyle.resolveWith((s) => TextStyle(
              fontSize: 13,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? cs.primary : cs.onSurfaceVariant,
            )),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      listTileTheme: ListTileThemeData(iconColor: cs.onSurfaceVariant, shape: RoundedRectangleBorder(borderRadius: r12)),
      dividerTheme: DividerThemeData(color: cs.outlineVariant, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: cs.primary, linearTrackColor: cs.surfaceContainerHighest),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? cs.primary : Colors.transparent),
        checkColor: WidgetStatePropertyAll(cs.onPrimary),
        side: BorderSide(color: cs.outline, width: 1.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? cs.onPrimary : cs.onSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? cs.primary : cs.surfaceContainerHighest),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: TextStyle(color: cs.onInverseSurface, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: r12),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: cs.outline,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: r12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: r12, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: r12, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: r12, borderSide: BorderSide(color: cs.primary, width: 1.5)),
        labelStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 14),
        prefixIconColor: cs.onSurfaceVariant,
      ),
    );
  }
}
