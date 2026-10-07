import 'package:flutter/material.dart';

import '../models/bill.dart';
import 'selectable.dart';

/// Colors of the three [BillStatus]es (container + text/icon on it, AA contrast) and their solid accents (charts,
/// dots). Read with `StatusColors.of(context)`.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  final Color unpaid;
  final Color onUnpaid;
  final Color verification;
  final Color onVerification;
  final Color paid;
  final Color onPaid;

  const StatusColors({
    required this.unpaid,
    required this.onUnpaid,
    required this.verification,
    required this.onVerification,
    required this.paid,
    required this.onPaid,
  });

  static const light = StatusColors(
    unpaid: Color(0xFFFEE2E2),
    onUnpaid: Color(0xFF991B1B),
    verification: Color(0xFFFEF3C7),
    onVerification: Color(0xFF92400E),
    paid: Color(0xFFDCFCE7),
    onPaid: Color(0xFF166534),
  );

  static const dark = StatusColors(
    unpaid: Color(0xFF3F1219),
    onUnpaid: Color(0xFFFCA5A5),
    verification: Color(0xFF3A2A0A),
    onVerification: Color(0xFFFCD34D),
    paid: Color(0xFF0E2E1C),
    onPaid: Color(0xFF86EFAC),
  );

  /// The theme's status colors; the light set when the theme has none (e.g. a bare test theme).
  static StatusColors of(BuildContext context) => Theme.of(context).extension<StatusColors>() ?? light;

  /// (container, on container) for [status].
  (Color, Color) forStatus(BillStatus status) => switch (status) {
    BillStatus.unpaid => (unpaid, onUnpaid),
    BillStatus.forVerification => (verification, onVerification),
    BillStatus.paid => (paid, onPaid),
  };

  @override
  StatusColors copyWith({Color? unpaid, Color? onUnpaid, Color? verification, Color? onVerification, Color? paid, Color? onPaid}) => StatusColors(
    unpaid: unpaid ?? this.unpaid,
    onUnpaid: onUnpaid ?? this.onUnpaid,
    verification: verification ?? this.verification,
    onVerification: onVerification ?? this.onVerification,
    paid: paid ?? this.paid,
    onPaid: onPaid ?? this.onPaid,
  );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      unpaid: Color.lerp(unpaid, other.unpaid, t)!,
      onUnpaid: Color.lerp(onUnpaid, other.onUnpaid, t)!,
      verification: Color.lerp(verification, other.verification, t)!,
      onVerification: Color.lerp(onVerification, other.onVerification, t)!,
      paid: Color.lerp(paid, other.paid, t)!,
      onPaid: Color.lerp(onPaid, other.onPaid, t)!,
    );
  }
}

/// The M18 Residences look: deep teal on neutral slate surfaces, flat bordered cards, Inter. Light and dark follow
/// the system (`MaterialApp(theme: AppTheme.light, darkTheme: AppTheme.dark, themeMode: ThemeMode.system)`).
class AppTheme {
  AppTheme._();

  /// The brand color (teal 700).
  static const Color brand = Color(0xFF0F766E);

  /// The bundled font (see this package's pubspec).
  static const String fontFamily = 'packages/m18_residences_shared/Inter';

  /// Figures of equal width, so amounts and readings line up in columns.
  static const List<FontFeature> tabularFigures = [FontFeature.tabularFigures()];

  static final ColorScheme lightScheme = ColorScheme.fromSeed(seedColor: brand).copyWith(
    primary: brand,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFCCFBF1),
    onPrimaryContainer: const Color(0xFF134E4A),
    secondary: const Color(0xFF475569),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFE2E8F0),
    onSecondaryContainer: const Color(0xFF0F172A),
    tertiary: const Color(0xFF92400E),
    error: const Color(0xFFB91C1C),
    onError: Colors.white,
    errorContainer: const Color(0xFFFEE2E2),
    onErrorContainer: const Color(0xFF7F1D1D),
    surface: const Color(0xFFF8FAFC),
    onSurface: const Color(0xFF0F172A),
    onSurfaceVariant: const Color(0xFF475569),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFF8FAFC),
    surfaceContainer: const Color(0xFFF1F5F9),
    surfaceContainerHigh: const Color(0xFFE9EEF4),
    surfaceContainerHighest: const Color(0xFFE2E8F0),
    outline: const Color(0xFF8291A6),
    outlineVariant: const Color(0xFFE2E8F0),
    inverseSurface: const Color(0xFF1E293B),
    onInverseSurface: const Color(0xFFF1F5F9),
    inversePrimary: const Color(0xFF5EEAD4),
    surfaceTint: Colors.transparent,
  );

  static final ColorScheme darkScheme = ColorScheme.fromSeed(seedColor: brand, brightness: Brightness.dark).copyWith(
    primary: const Color(0xFF2DD4BF),
    onPrimary: const Color(0xFF042F2E),
    primaryContainer: const Color(0xFF134E4A),
    onPrimaryContainer: const Color(0xFFCCFBF1),
    secondary: const Color(0xFF94A3B8),
    onSecondary: const Color(0xFF0F172A),
    secondaryContainer: const Color(0xFF1E293B),
    onSecondaryContainer: const Color(0xFFE2E8F0),
    tertiary: const Color(0xFFFCD34D),
    error: const Color(0xFFF87171),
    onError: const Color(0xFF450A0A),
    errorContainer: const Color(0xFF7F1D1D),
    onErrorContainer: const Color(0xFFFEE2E2),
    surface: const Color(0xFF0B1120),
    onSurface: const Color(0xFFE2E8F0),
    onSurfaceVariant: const Color(0xFF94A3B8),
    surfaceContainerLowest: const Color(0xFF070C17),
    surfaceContainerLow: const Color(0xFF0F172A),
    surfaceContainer: const Color(0xFF131C2E),
    surfaceContainerHigh: const Color(0xFF1A2436),
    surfaceContainerHighest: const Color(0xFF1E293B),
    outline: const Color(0xFF64748B),
    outlineVariant: const Color(0xFF1E293B),
    inverseSurface: const Color(0xFFE2E8F0),
    onInverseSurface: const Color(0xFF0F172A),
    inversePrimary: brand,
    surfaceTint: Colors.transparent,
  );

  static ThemeData get light => _build(lightScheme, StatusColors.light);

  static ThemeData get dark => _build(darkScheme, StatusColors.dark);

  /// The color of cards, sheets, the navigation bar/rail and inputs: white on light, a lifted slate on dark.
  static Color panelColor(ColorScheme scheme) => scheme.brightness == Brightness.light ? scheme.surfaceContainerLowest : scheme.surfaceContainerLow;

  /// A panel inside a panel (e.g. a modal's sections): a step off [panelColor].
  static Color softPanelColor(ColorScheme scheme) => scheme.brightness == Brightness.light ? scheme.surfaceContainerLow : scheme.surfaceContainer;

  /// A modal's footer strip: a little darker than [panelColor].
  static Color footerColor(ColorScheme scheme) => scheme.brightness == Brightness.light ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest;

  /// A modal's header band: [tint] (the primary color by default) washed over [panelColor].
  static Color modalBandColor(ColorScheme scheme, [Color? tint]) =>
      Color.alphaBlend((tint ?? scheme.primary).withValues(alpha: scheme.brightness == Brightness.light ? 0.07 : 0.12), panelColor(scheme));

  static ThemeData _build(ColorScheme scheme, StatusColors status) {
    final panel = panelColor(scheme);
    final base = ThemeData(colorScheme: scheme, fontFamily: fontFamily);
    final text = _textTheme(base.textTheme, scheme);
    const radius12 = BorderRadius.all(Radius.circular(12));
    const radius16 = BorderRadius.all(Radius.circular(16));
    final buttonShape = WidgetStateProperty.all(const RoundedRectangleBorder(borderRadius: radius12));
    final buttonText = WidgetStateProperty.all(text.labelLarge);
    final buttonSize = WidgetStateProperty.all(const Size(48, 48));
    final buttonPadding = WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 14));

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: radius12,
      borderSide: BorderSide(color: color, width: width),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      extensions: [status],
      // Every page's text can be selected and copied.
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {for (final platform in TargetPlatform.values) platform: const SelectablePageTransitionsBuilder()},
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        titleTextStyle: text.titleLarge,
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius16,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      // A disabled filled button (e.g. Save before anything changed) stays visibly a button in both themes; enabled
      // colors are left to Material (null), so FilledButton.styleFrom and tonal buttons keep theirs.
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          textStyle: buttonText,
          minimumSize: buttonSize,
          padding: buttonPadding,
          backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.disabled) ? scheme.surfaceContainerHighest : null),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled) ? scheme.onSurfaceVariant.withValues(alpha: 0.8) : null,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled) ? BorderSide(color: scheme.outline.withValues(alpha: 0.5)) : null,
          ),
        ),
      ),
      // ElevatedButton looks like FilledButton: flat, brand colored.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          textStyle: buttonText,
          minimumSize: buttonSize,
          padding: buttonPadding,
          elevation: WidgetStateProperty.all(0),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled) ? scheme.surfaceContainerHighest : scheme.primary,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled) ? scheme.onSurfaceVariant.withValues(alpha: 0.8) : scheme.onPrimary,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled) ? BorderSide(color: scheme.outline.withValues(alpha: 0.5)) : null,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          textStyle: buttonText,
          minimumSize: buttonSize,
          padding: buttonPadding,
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(color: states.contains(WidgetState.disabled) ? scheme.outlineVariant : scheme.outline),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          textStyle: buttonText,
          minimumSize: buttonSize,
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 4,
        highlightElevation: 2,
        extendedTextStyle: text.labelLarge,
        shape: const RoundedRectangleBorder(borderRadius: radius16),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: panel,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.error)
                ? scheme.error
                : states.contains(WidgetState.focused)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: inputBorder(scheme.outline),
        enabledBorder: inputBorder(scheme.outline),
        disabledBorder: inputBorder(scheme.outlineVariant),
        focusedBorder: inputBorder(scheme.primary, 2),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 2),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: panel,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
        titleTextStyle: text.titleLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: panel,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: panel,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
        headerBackgroundColor: scheme.primaryContainer,
        headerForegroundColor: scheme.onPrimaryContainer,
        todayBorder: BorderSide(color: scheme.primary),
        dividerColor: scheme.outlineVariant,
        cancelButtonStyle: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        confirmButtonStyle: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: panel,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium!.copyWith(
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: panel,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: text.labelLarge!.copyWith(color: scheme.onSurface),
        unselectedLabelTextStyle: text.labelLarge!.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: text.labelLarge!.copyWith(fontWeight: FontWeight.w500),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: panel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius12,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        shape: const RoundedRectangleBorder(borderRadius: radius12),
        titleTextStyle: text.bodyLarge!.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: text.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(scheme.surfaceContainer),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        shape: WidgetStateProperty.all(const RoundedRectangleBorder(borderRadius: radius12)),
        side: WidgetStateProperty.all(BorderSide(color: scheme.outlineVariant)),
        hintStyle: WidgetStateProperty.all(text.bodyLarge!.copyWith(color: scheme.onSurfaceVariant)),
        constraints: const BoxConstraints(minHeight: 48),
      ),
      searchViewTheme: SearchViewThemeData(backgroundColor: panel, surfaceTintColor: Colors.transparent),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(scheme.surfaceContainer),
        headingTextStyle: text.labelLarge!.copyWith(color: scheme.onSurfaceVariant),
        dataTextStyle: text.bodyMedium!.copyWith(fontFeatures: tabularFigures),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primaryContainer;
          if (states.contains(WidgetState.hovered)) return scheme.surfaceContainer;
          return null;
        }),
        dividerThickness: 1,
        headingRowHeight: 48,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: const BorderRadius.all(Radius.circular(8))),
        textStyle: text.bodySmall!.copyWith(color: scheme.onInverseSurface),
      ),
      badgeTheme: BadgeThemeData(backgroundColor: scheme.error, textColor: scheme.onError),
    );
  }

  /// Inter with tighter headings; colors from [scheme].
  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    TextStyle? heading(TextStyle? s, double size, FontWeight weight, double spacing) =>
        s?.copyWith(fontSize: size, fontWeight: weight, letterSpacing: spacing, height: 1.2, color: scheme.onSurface);
    return base.copyWith(
      displaySmall: heading(base.displaySmall, 34, FontWeight.w700, -0.8),
      headlineLarge: heading(base.headlineLarge, 30, FontWeight.w700, -0.6),
      headlineMedium: heading(base.headlineMedium, 26, FontWeight.w700, -0.5),
      headlineSmall: heading(base.headlineSmall, 22, FontWeight.w700, -0.3),
      titleLarge: heading(base.titleLarge, 19, FontWeight.w600, -0.2),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
      bodyLarge: base.bodyLarge?.copyWith(letterSpacing: 0),
      bodyMedium: base.bodyMedium?.copyWith(letterSpacing: 0),
      bodySmall: base.bodySmall?.copyWith(letterSpacing: 0, color: scheme.onSurfaceVariant),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.1),
      labelSmall: base.labelSmall?.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.2),
    );
  }
}
