import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/trade.dart';

// Repositório responsável por toda a comunicação com a tabela `trades`
// no Supabase. Centraliza as consultas para manter o código organizado
// e facilitar manutenção/otimização futura.
class TradeRepository {
  // Cliente do Supabase (singleton já inicializado em main.dart).
  final SupabaseClient _client = Supabase.instance.client;

  // Nome da tabela no banco.
  static const String _table = 'trades';

  // Retorna o id do usuário autenticado atual, ou lança erro se não houver.
  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Nenhum usuário autenticado.');
    }
    return user.id;
  }

  // Busca todos os trades dentro de um intervalo de datas [start, end]
  // (ambos inclusivos). Usado tanto para o calendário quanto relatórios.
  //
  // Observação de performance: filtramos por data direto no Postgres e
  // dependemos do RLS + índice (user_id, trade_date) para consultas rápidas.
  Future<List<Trade>> fetchTradesInRange(DateTime start, DateTime end) async {
    final response = await _client
        .from(_table)
        .select()
        .gte('trade_date', _dateOnly(start))
        .lte('trade_date', _dateOnly(end))
        .order('trade_date', ascending: true);

    // Converte cada linha retornada em um objeto Trade.
    return (response as List)
        .map((row) => Trade.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  // Busca o trade de um dia específico, ou null se não existir.
  Future<Trade?> fetchTradeByDate(DateTime date) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('trade_date', _dateOnly(date))
        .maybeSingle();

    if (response == null) return null;
    return Trade.fromMap(response);
  }

  // Insere ou atualiza (upsert) o resultado de um dia.
  //
  // Usamos onConflict em (user_id, trade_date) para que registrar o mesmo
  // dia novamente sobrescreva o valor anterior, evitando duplicidade.
  Future<Trade> upsertTrade(Trade trade) async {
    final data = trade.toInsertMap(_userId);

    final response = await _client
        .from(_table)
        .upsert(data, onConflict: 'user_id,trade_date')
        .select()
        .single();

    return Trade.fromMap(response);
  }

  // Remove o registro de um dia específico.
  Future<void> deleteTradeByDate(DateTime date) async {
    await _client
        .from(_table)
        .delete()
        .eq('user_id', _userId)
        .eq('trade_date', _dateOnly(date));
  }

  // Helper: formata DateTime como yyyy-MM-dd (a tabela guarda só a data).
  static String _dateOnly(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }
}
