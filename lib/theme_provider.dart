import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkTheme = false;
  Color _primaryColor = Colors.deepPurpleAccent;
  double _textScaleFactor = 1.0; // Metin boyutunu kontrol eden ölçek faktörü (ör. 1.0 = Orta)
  String _fontFamily = 'Sans-serif'; // Yazı tipi

  bool get isDarkTheme => _isDarkTheme;
  Color get primaryColor => _primaryColor;
  double get textScaleFactor => _textScaleFactor;
  String get fontFamily => _fontFamily;

  ThemeMode get themeMode => _isDarkTheme ? ThemeMode.dark : ThemeMode.light;

  ThemeData getTheme() {
    final brightness = _isDarkTheme ? Brightness.dark : Brightness.light;
    final colorScheme = ColorScheme.fromSwatch(
      primarySwatch: _primaryColor == Colors.deepPurpleAccent
          ? Colors.deepPurple
          : MaterialColor(_primaryColor.value, {
              50: _primaryColor.withOpacity(.1),
              100: _primaryColor.withOpacity(.2),
              200: _primaryColor.withOpacity(.3),
              300: _primaryColor.withOpacity(.4),
              400: _primaryColor.withOpacity(.5),
              500: _primaryColor.withOpacity(.6),
              600: _primaryColor.withOpacity(.7),
              700: _primaryColor.withOpacity(.8),
              800: _primaryColor.withOpacity(.9),
              900: _primaryColor.withOpacity(1),
            }),
      brightness: brightness,
    );

    // Temaya uygulanacak temel textTheme'ü seçelim:
    TextTheme baseTextTheme = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    // Metin boyutu ve yazı tipini baseTextTheme'e uygula:
    TextTheme adjustedTextTheme = baseTextTheme.apply(
      fontSizeFactor: _textScaleFactor,
      fontFamily: _fontFamily,
    );

    return ThemeData(
      brightness: brightness,
      primaryColor: _primaryColor,
      scaffoldBackgroundColor: _isDarkTheme ? Colors.black87 : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: _isDarkTheme ? Colors.black : _primaryColor,
      ),
      colorScheme: colorScheme.copyWith(
        secondary: _primaryColor,
      ),
      textTheme: adjustedTextTheme,
    );
  }

  void toggleTheme(bool isDark) {
    _isDarkTheme = isDark;
    notifyListeners();
  }

  void setThemeColor(Color color) {
    _primaryColor = color;
    notifyListeners();
  }

  void setTextScaleFactor(double scale) {
    _textScaleFactor = scale;
    notifyListeners();
  }

  void setFontFamily(String fontFamily) {
    _fontFamily = fontFamily;
    notifyListeners();
  }
}
