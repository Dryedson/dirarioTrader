// Utilitários para cálculo de intervalos de datas dos relatórios.
//
// Centralizamos aqui a lógica de "qual é o início e fim de cada período"
// para garantir consistência entre tela de relatórios e consultas.

// Tipos de período suportados pelos relatórios.
enum ReportPeriod {
  weekly, // Semanal
  monthly, // Mensal
  quarterly, // Trimestral
  semiannual, // Semestral
  annual, // Anual
}

// Extensão com nome amigável (PT-BR) de cada período para exibição.
extension ReportPeriodLabel on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.weekly:
        return 'Semanal';
      case ReportPeriod.monthly:
        return 'Mensal';
      case ReportPeriod.quarterly:
        return 'Trimestral';
      case ReportPeriod.semiannual:
        return 'Semestral';
      case ReportPeriod.annual:
        return 'Anual';
    }
  }
}

// Representa um intervalo de datas [start, end], ambos inclusivos.
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange(this.start, this.end);
}

// Classe com funções estáticas para calcular o intervalo de um período
// a partir de uma data de referência.
class PeriodCalculator {
  // Normaliza um DateTime para meia-noite (remove a parte de hora),
  // evitando problemas de comparação por causa de horas/minutos.
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // Retorna o intervalo do período que contém [reference].
  static DateRange rangeFor(ReportPeriod period, DateTime reference) {
    final ref = dateOnly(reference);
    switch (period) {
      case ReportPeriod.weekly:
        return _weekRange(ref);
      case ReportPeriod.monthly:
        return _monthRange(ref);
      case ReportPeriod.quarterly:
        return _quarterRange(ref);
      case ReportPeriod.semiannual:
        return _semiannualRange(ref);
      case ReportPeriod.annual:
        return _yearRange(ref);
    }
  }

  // Semana: de segunda-feira a domingo que contêm a data de referência.
  static DateRange _weekRange(DateTime ref) {
    // weekday: 1 = segunda ... 7 = domingo.
    final start = ref.subtract(Duration(days: ref.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return DateRange(start, end);
  }

  // Mês: do dia 1 ao último dia do mês da referência.
  static DateRange _monthRange(DateTime ref) {
    final start = DateTime(ref.year, ref.month, 1);
    // Dia 0 do mês seguinte = último dia do mês atual.
    final end = DateTime(ref.year, ref.month + 1, 0);
    return DateRange(start, end);
  }

  // Trimestre: blocos de 3 meses (Jan-Mar, Abr-Jun, Jul-Set, Out-Dez).
  static DateRange _quarterRange(DateTime ref) {
    // Calcula o mês inicial do trimestre (1, 4, 7 ou 10).
    final startMonth = ((ref.month - 1) ~/ 3) * 3 + 1;
    final start = DateTime(ref.year, startMonth, 1);
    final end = DateTime(ref.year, startMonth + 3, 0);
    return DateRange(start, end);
  }

  // Semestre: primeiro (Jan-Jun) ou segundo (Jul-Dez) semestre.
  static DateRange _semiannualRange(DateTime ref) {
    final isFirstHalf = ref.month <= 6;
    final startMonth = isFirstHalf ? 1 : 7;
    final start = DateTime(ref.year, startMonth, 1);
    final end = DateTime(ref.year, startMonth + 6, 0);
    return DateRange(start, end);
  }

  // Ano: de 1º de janeiro a 31 de dezembro do ano da referência.
  static DateRange _yearRange(DateTime ref) {
    final start = DateTime(ref.year, 1, 1);
    final end = DateTime(ref.year, 12, 31);
    return DateRange(start, end);
  }
}
