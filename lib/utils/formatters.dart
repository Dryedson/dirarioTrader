import 'package:intl/intl.dart';

// Utilitários de formatação usados em todo o app.
//
// Centraliza a formatação de moeda e datas em PT-BR para manter
// consistência visual e facilitar mudanças futuras (ex.: trocar moeda).
class AppFormatters {
  // Formata um valor monetário em Real brasileiro (ex.: R$ 1.234,56).
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  // Formata data completa por extenso curto (ex.: 13 de jul. de 2026).
  static final DateFormat _fullDate = DateFormat("d 'de' MMM 'de' y", 'pt_BR');

  // Formata dia e mês (ex.: 13/07).
  static final DateFormat _dayMonth = DateFormat('dd/MM', 'pt_BR');

  // Retorna o valor formatado como moeda. Mantém o sinal negativo para
  // prejuízos (ex.: -R$ 200,00).
  static String currency(double value) => _currency.format(value);

  // Retorna a data completa formatada.
  static String fullDate(DateTime date) => _fullDate.format(date);

  // Retorna dia/mês formatado.
  static String dayMonth(DateTime date) => _dayMonth.format(date);
}
