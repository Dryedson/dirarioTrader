import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/trade.dart';
import '../providers/trade_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/period.dart';

// Tela de relatórios de desempenho.
//
// Permite alternar entre os períodos (semanal, mensal, trimestral,
// semestral e anual) e mostra o total de ganhos/prejuízos, além de um
// gráfico de barras com os resultados diários do período.
class ReportsScreen extends StatefulWidget {
  // Data de referência usada para determinar o período (dia selecionado).
  final DateTime reference;

  const ReportsScreen({super.key, required this.reference});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Período atualmente selecionado (inicia no mensal).
  ReportPeriod _period = ReportPeriod.monthly;

  // Future com o resultado do relatório atual (para o FutureBuilder).
  late Future<ReportResult> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  // Recalcula o relatório para o período selecionado.
  void _reload() {
    _future = context.read<TradeProvider>().computeReport(
      _period,
      widget.reference,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: Column(
        children: [
          // Seletor de período (chips roláveis horizontalmente).
          _buildPeriodSelector(),

          // Conteúdo do relatório carregado de forma assíncrona.
          Expanded(
            child: FutureBuilder<ReportResult>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar o relatório.'),
                  );
                }
                final result = snapshot.data!;
                return _buildReportContent(result);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Constrói a linha de chips para escolher o período.
  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: ReportPeriod.values.map((p) {
          final selected = p == _period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p.label),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _period = p;
                  _reload();
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // Constrói o conteúdo principal do relatório (totais + gráfico + lista).
  Widget _buildReportContent(ReportResult result) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Intervalo do período analisado.
        Text(
          '${AppFormatters.fullDate(result.range.start)} — '
          '${AppFormatters.fullDate(result.range.end)}',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),

        // Cartão com o resultado total do período.
        _buildTotalCard(result),
        const SizedBox(height: 12),

        // Linha com ganhos e prejuízos separados.
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Ganhos',
                result.gains,
                AppTheme.primary,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Prejuízos',
                result.losses,
                AppTheme.danger,
                Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Gráfico de barras dos resultados diários.
        const Text(
          'Resultados no período',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(height: 240, child: _buildChart(result)),
        const SizedBox(height: 24),

        // Lista dos registros do período.
        if (result.trades.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Nenhum registro neste período.',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          )
        else
          ...result.trades.map(_buildTradeTile),
      ],
    );
  }

  // Cartão de destaque com o total (saldo) do período.
  Widget _buildTotalCard(ReportResult result) {
    final color = AppTheme.amountColor(result.total);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saldo do período',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              AppFormatters.currency(result.total),
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cartão menor com uma estatística (ganhos ou prejuízos).
  Widget _buildStatCard(
    String title,
    double value,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(title, style: const TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppFormatters.currency(value),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Constrói o gráfico de barras com os resultados diários do período.
  Widget _buildChart(ReportResult result) {
    if (result.trades.isEmpty) {
      return const Center(
        child: Text(
          'Sem dados para exibir.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    // Cria uma barra por registro, colorida conforme ganho/prejuízo.
    final bars = <BarChartGroupData>[];
    for (var i = 0; i < result.trades.length; i++) {
      final trade = result.trades[i];
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: trade.amount,
              color: AppTheme.amountColor(trade.amount),
              width: 14,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: bars,
        // Linha de base no zero para separar ganhos de prejuízos.
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 44),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= result.trades.length) {
                  return const SizedBox.shrink();
                }
                // Mostra o dia/mês na base de cada barra.
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    AppFormatters.dayMonth(result.trades[index].date),
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white54,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Item da lista de registros do período.
  Widget _buildTradeTile(Trade trade) {
    final color = AppTheme.amountColor(trade.amount);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          trade.amount >= 0 ? Icons.trending_up : Icons.trending_down,
          color: color,
        ),
        title: Text(AppFormatters.fullDate(trade.date)),
        subtitle: (trade.note != null && trade.note!.isNotEmpty)
            ? Text(trade.note!)
            : null,
        trailing: Text(
          AppFormatters.currency(trade.amount),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
