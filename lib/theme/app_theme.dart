import 'package:flutter/material.dart';

// Definição centralizada do tema visual do app.
//
// Usamos um tema escuro moderno com destaque em verde/vermelho para
// ganhos e prejuízos, algo familiar para quem opera no mercado financeiro.
class AppTheme {
  // Cores principais reutilizadas em toda a UI.
  static const Color primary = Color(0xFF00C853); // Verde (ganho / marca)
  static const Color danger = Color(0xFFFF5252); // Vermelho (prejuízo)
  static const Color background = Color(0xFF0E1116); // Fundo escuro
  static const Color surface = Color(0xFF1A1F27); // Cartões/superfícies

  // Retorna a cor apropriada para um valor: verde se >= 0, vermelho se < 0.
  static Color amountColor(double value) => value >= 0 ? primary : danger;

  // Constrói o ThemeData escuro do aplicativo.
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        surface: surface,
        error: danger,
      ),
      // Aparência padrão dos cartões.
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      // Aparência dos botões elevados (ações principais).
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      // Aparência dos campos de texto.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
