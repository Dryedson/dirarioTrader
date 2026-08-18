import 'package:flutter/foundation.dart';

import '../models/trade.dart';
import '../repositories/trade_repository.dart';
import '../utils/period.dart';

// Provider que gerencia o estado dos trades exibidos na tela.
//
// Mantém em memória os trades do mês visível no calendário (para pintar os
// dias) e oferece métodos para salvar/remover e para calcular relatórios.
class TradeProvider extends ChangeNotifier {
  final TradeRepository _repository = TradeRepository();

  // Cache dos trades do intervalo atualmente carregado, indexado por data
  // (chave yyyy-MM-dd) para acesso O(1) ao pintar/consultar dias.
  final Map<String, Trade> _tradesByDate = {};

  // Flag de carregamento para exibir indicadores na UI.
  bool _loading = false;
  bool get loading => _loading;

  // Retorna o trade de um dia específico a partir do cache, ou null.
  Trade? tradeForDate(DateTime date) => _tradesByDate[_key(date)];

  // Carrega os trades de um intervalo (normalmente o mês visível) e atualiza
  // o cache local. Usado pelo calendário para destacar os dias com registro.
  Future<void> loadRange(DateTime start, DateTime end) async {
    _setLoading(true);
    try {
      final trades = await _repository.fetchTradesInRange(start, end);
      _tradesByDate.clear();
      for (final t in trades) {
        _tradesByDate[_key(t.date)] = t;
      }
    } finally {
      _setLoading(false);
    }
  }

  // Salva (insere ou atualiza) o resultado de um dia e atualiza o cache.
  Future<void> saveTrade({
    required DateTime date,
    required double amount,
    String? note,
  }) async {
    final trade = Trade(date: date, amount: amount, note: note);
    final saved = await _repository.upsertTrade(trade);
    // Atualiza o cache local para refletir imediatamente na UI.
    _tradesByDate[_key(date)] = saved;
    notifyListeners();
  }

  // Remove o registro de um dia e atualiza o cache.
  Future<void> deleteTrade(DateTime date) async {
    await _repository.deleteTradeByDate(date);
    _tradesByDate.remove(_key(date));
    notifyListeners();
  }

  // Calcula o total (soma dos valores) de um período a partir de uma data
  // de referência. Busca os dados no banco para garantir precisão mesmo
  // fora do intervalo em cache.
  Future<ReportResult> computeReport(
    ReportPeriod period,
    DateTime reference,
  ) async {
    final range = PeriodCalculator.rangeFor(period, reference);
    final trades = await _repository.fetchTradesInRange(range.start, range.end);

    // Soma total, separando ganhos e prejuízos para exibição detalhada.
    double total = 0;
    double gains = 0;
    double losses = 0;
    for (final t in trades) {
      total += t.amount;
      if (t.amount >= 0) {
        gains += t.amount;
      } else {
        losses += t.amount;
      }
    }

    return ReportResult(
      range: range,
      total: total,
      gains: gains,
      losses: losses,
      trades: trades,
    );
  }

  // Atualiza o estado de loading e notifica a UI.
  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  // Gera a chave de cache (yyyy-MM-dd) a partir de uma data.
  String _key(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }
}

// Estrutura de resultado de um relatório, com os totais e os registros.
class ReportResult {
  final DateRange range; // Intervalo considerado.
  final double total; // Soma de tudo (ganhos + prejuízos).
  final double gains; // Soma apenas dos ganhos (>= 0).
  final double losses; // Soma apenas dos prejuízos (< 0, valor negativo).
  final List<Trade> trades; // Registros do período.

  const ReportResult({
    required this.range,
    required this.total,
    required this.gains,
    required this.losses,
    required this.trades,
  });
}
