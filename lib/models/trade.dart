// Modelo que representa um registro de trade (resultado de um dia).
//
// Cada trade guarda o dia, o valor (positivo = ganho, negativo = prejuízo)
// e uma anotação opcional. O campo [id] e [userId] são gerenciados pelo
// Supabase (o userId vem do usuário autenticado).
class Trade {
  // Identificador único do registro (uuid gerado pelo Supabase). Pode ser
  // nulo antes de o registro ser salvo pela primeira vez.
  final String? id;

  // Identificador do usuário dono do registro (auth.uid()).
  final String? userId;

  // Data do trade (apenas a parte de data importa; hora é ignorada).
  final DateTime date;

  // Valor do resultado do dia. Positivo = ganho, negativo = prejuízo.
  final double amount;

  // Observação/anotação opcional sobre o dia.
  final String? note;

  const Trade({
    this.id,
    this.userId,
    required this.date,
    required this.amount,
    this.note,
  });

  // Cria um Trade a partir de um mapa (linha) vindo do Supabase.
  factory Trade.fromMap(Map<String, dynamic> map) {
    return Trade(
      id: map['id'] as String?,
      userId: map['user_id'] as String?,
      // A data vem como texto ISO (yyyy-MM-dd); convertemos para DateTime.
      date: DateTime.parse(map['trade_date'] as String),
      // O valor pode vir como int, double ou string dependendo do driver.
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
    );
  }

  // Converte o Trade em um mapa pronto para inserir/atualizar no Supabase.
  // Não incluímos o id aqui pois usamos upsert por (user_id, trade_date).
  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      // Salvamos apenas a data no formato yyyy-MM-dd.
      'trade_date': _dateOnly(date),
      'amount': amount,
      'note': note,
    };
  }

  // Cria uma cópia do Trade alterando campos específicos.
  Trade copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? amount,
    String? note,
  }) {
    return Trade(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }

  // Helper: formata um DateTime como string yyyy-MM-dd (sem hora).
  static String _dateOnly(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }
}
