import 'package:flutter/material.dart';

final class AppTheme {
  AppTheme._();

  static const Color sacredRed = Color(0xFF9D2028);
  static const Color inkBlack = Color(0xFF2A2118);
  static const Color parchment = Color(0xFFF3E7CF);
  static const Color parchmentSurface = Color(0xFFFBF4E5);
  static const Color parchmentMuted = Color(0xFFE7D6B5);
  static const Color controlGreen = Color(0xFF315B43);
  static const Color liturgicalGold = Color(0xFFA7782C);
  static const Color warmOutline = Color(0xFFBEA77D);

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: controlGreen,
          brightness: Brightness.light,
        ).copyWith(
          primary: controlGreen,
          secondary: sacredRed,
          tertiary: liturgicalGold,
          surface: parchmentSurface,
          onSurface: inkBlack,
          outline: warmOutline,
          outlineVariant: parchmentMuted,
        );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: parchment,
      cardColor: parchmentSurface,
      dividerColor: warmOutline.withValues(alpha: 0.45),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: parchment,
        foregroundColor: inkBlack,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: parchmentSurface.withValues(alpha: 0.9),
        indicatorColor: controlGreen.withValues(alpha: 0.14),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? controlGreen
                : inkBlack.withValues(alpha: 0.72),
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: warmOutline.withValues(alpha: 0.45),
        space: 1,
        thickness: 0.7,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: parchmentMuted.withValues(alpha: 0.7),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: parchmentSurface.withValues(alpha: 0.94),
        surfaceTintColor: Colors.transparent,
      ),
    );

    return theme.copyWith(
      textTheme: theme.textTheme
          .apply(bodyColor: inkBlack, displayColor: inkBlack)
          .copyWith(
            headlineSmall: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
            titleLarge: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
            bodyLarge: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
    );
  }
}
