import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/trade.dart';
import '../providers/auth_provider.dart';
import '../providers/trade_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/period.dart';
import 'reports_screen.dart';

// Tela principal do app: exibe o calendário para o usuário selecionar um
// dia e registrar/visualizar o resultado (ganho ou prejuízo) daquele dia.
//
// O app sempre inicia no dia atual do aparelho, conforme solicitado.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dia atualmente focado pelo calendário (controla o mês exibido).
  late DateTime _focusedDay;

  // Dia selecionado pelo usuário (inicia no dia de hoje).
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    // Inicializa com a data atual do dispositivo.
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = PeriodCalculator.dateOnly(now);

    // Carrega os trades do mês atual após o primeiro frame, garantindo
    // que o Provider já esteja disponível no contexto.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMonth(_focusedDay);
    });
  }

  // Carrega os trades do mês que contém [day] para destacar no calendário.
  Future<void> _loadMonth(DateTime day) async {
    final range = PeriodCalculator.rangeFor(ReportPeriod.monthly, day);
    // Carregamos uma margem extra (mês inteiro) para cobrir dias visíveis
    // de meses vizinhos exibidos no calendário.
    await context.read<TradeProvider>().loadRange(
      DateTime(range.start.year, range.start.month - 1, 1),
      DateTime(range.end.year, range.end.month + 1, 0),
    );
  }

  // Abre o formulário (bottom sheet) para registrar/editar o valor do dia.
  Future<void> _openTradeEditor(DateTime day) async {
    final provider = context.read<TradeProvider>();
    final existing = provider.tradeForDate(day);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TradeEditorSheet(day: day, existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Observa o provider para atualizar o cartão do dia selecionado.
    final provider = context.watch<TradeProvider>();
    final selectedTrade = provider.tradeForDate(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diário de Trade'),
        actions: [
          // Acesso à tela de relatórios.
          IconButton(
            tooltip: 'Relatórios',
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportsScreen(reference: _selectedDay),
                ),
              );
            },
          ),
          // Botão de logout.
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cartão com o calendário.
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _buildCalendar(provider),
            ),
          ),

          // Cartão com o resumo do dia selecionado.
          Expanded(child: _buildDaySummary(selectedTrade)),
        ],
      ),
      // Botão para adicionar/editar o resultado do dia selecionado.
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        onPressed: () => _openTradeEditor(_selectedDay),
        icon: Icon(selectedTrade == null ? Icons.add : Icons.edit),
        label: Text(selectedTrade == null ? 'Registrar dia' : 'Editar'),
      ),
    );
  }

  // Constrói o widget do calendário (table_calendar).
  Widget _buildCalendar(TradeProvider provider) {
    return TableCalendar<Trade>(
      locale: 'pt_BR',
      // Período navegável do calendário.
      firstDay: DateTime.utc(2015, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: _focusedDay,
      // Formato fixo em mês.
      availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
      startingDayOfWeek: StartingDayOfWeek.monday,
      // Marca o dia selecionado.
      selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
      // Fornece os "eventos" (trades) de cada dia para os marcadores.
      eventLoader: (day) {
        final trade = provider.tradeForDate(day);
        return trade == null ? [] : [trade];
      },
      onDaySelected: (selected, focused) {
        setState(() {
          _selectedDay = PeriodCalculator.dateOnly(selected);
          _focusedDay = focused;
        });
      },
      // Ao mudar de mês, carrega os trades do novo período.
      onPageChanged: (focused) {
        _focusedDay = focused;
        _loadMonth(focused);
      },
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: Color(0x3300C853),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      // Marcador personalizado: ponto verde (ganho) ou vermelho (prejuízo).
      calendarBuilders: CalendarBuilders<Trade>(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return null;
          final trade = events.first;
          return Positioned(
            bottom: 4,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.amountColor(trade.amount),
              ),
            ),
          );
        },
      ),
    );
  }

  // Constrói o resumo do dia selecionado (valor, nota e ações).
  Widget _buildDaySummary(Trade? trade) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppFormatters.fullDate(_selectedDay),
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          if (trade == null)
            // Estado vazio: nenhum registro para o dia.
            _emptyState()
          else
            _tradeCard(trade),
        ],
      ),
    );
  }

  // Widget exibido quando o dia ainda não tem registro.
  Widget _emptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: const [
            Icon(Icons.event_note, color: Colors.white38, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Nenhum resultado registrado para este dia.\n'
                'Toque em "Registrar dia" para adicionar.',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cartão que mostra o resultado registrado do dia.
  Widget _tradeCard(Trade trade) {
    final color = AppTheme.amountColor(trade.amount);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  trade.amount >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  trade.amount >= 0 ? 'Ganho' : 'Prejuízo',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppFormatters.currency(trade.amount),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (trade.note != null && trade.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                trade.note!,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 8),
            // Ação para excluir o registro do dia.
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await context.read<TradeProvider>().deleteTrade(_selectedDay);
                },
                icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                label: const Text(
                  'Excluir',
                  style: TextStyle(color: AppTheme.danger),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bottom sheet com o formulário para registrar/editar o resultado de um dia.
class _TradeEditorSheet extends StatefulWidget {
  final DateTime day; // Dia sendo editado.
  final Trade? existing; // Registro existente (se houver).

  const _TradeEditorSheet({required this.day, this.existing});

  @override
  State<_TradeEditorSheet> createState() => _TradeEditorSheetState();
}

class _TradeEditorSheetState extends State<_TradeEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  // Define se o valor é um ganho (true) ou prejuízo (false).
  bool _isGain = true;

  // Flag de salvamento para desabilitar o botão durante a requisição.
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    // Pré-preenche os campos caso já exista um registro.
    _isGain = existing == null ? true : existing.amount >= 0;
    _amountController = TextEditingController(
      text: existing == null
          ? ''
          : existing.amount.abs().toStringAsFixed(2).replaceAll('.', ','),
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Converte o texto digitado (formato PT-BR) para double.
  double? _parseAmount(String text) {
    // Remove separador de milhar e troca a vírgula decimal por ponto.
    final normalized = text.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(normalized);
  }

  // Salva o registro no Supabase através do provider.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final value = _parseAmount(_amountController.text)!;
    // Aplica o sinal conforme ganho/prejuízo selecionado.
    final signed = _isGain ? value.abs() : -value.abs();

    setState(() => _saving = true);
    try {
      await context.read<TradeProvider>().saveTrade(
        date: widget.day,
        amount: signed,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ajusta o padding inferior para o teclado não cobrir os campos.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppFormatters.fullDate(widget.day),
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 16),

            // Seletor de tipo: ganho ou prejuízo.
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Ganho'),
                  icon: Icon(Icons.trending_up),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Prejuízo'),
                  icon: Icon(Icons.trending_down),
                ),
              ],
              selected: {_isGain},
              onSelectionChanged: (s) => setState(() => _isGain = s.first),
            ),
            const SizedBox(height: 16),

            // Campo de valor monetário.
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (value) {
                final parsed = _parseAmount(value ?? '');
                if (parsed == null || parsed <= 0) {
                  return 'Informe um valor válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Campo de anotação opcional.
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Anotação (opcional)',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
