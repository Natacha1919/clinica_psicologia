// lib/features/dashboard/screens/dashboard_metrics_screen.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:fl_chart/fl_chart.dart' as fl;

import '../models/dashboard_metrics_model.dart';
import '../services/dashboard_service.dart';

// Classe auxiliar para o gráfico da Syncfusion (barras)
class _ChartData {
  _ChartData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}

class DashboardMetricsScreen extends StatefulWidget {
  const DashboardMetricsScreen({Key? key}) : super(key: key);

  @override
  State<DashboardMetricsScreen> createState() => _DashboardMetricsScreenState();
}

class _DashboardMetricsScreenState extends State<DashboardMetricsScreen> {
  final DashboardService _dashboardService = DashboardService();
  late Stream<DashboardMetrics> _metricsStream;
  int _statusTouchedIndex = -1; // Índice de toque para o gráfico de Status
  int _vinculoTouchedIndex = -1; // NOVO: Índice de toque para o gráfico de Vínculo

  final Color _primaryDark = const Color(0xFF122640);
  final Color _accentGreen = const Color(0xFF36D97D);

  final Map<String, Color> _statusColors = {
    'TRIAGEM': Colors.blue.shade800,
    'CAIXA POSTAL': Colors.purple.shade600,
    'DESISTÊNCIA': Colors.red.shade700,
    'ESTÁGIO 4': Colors.teal.shade400,
    'OUTROS': Colors.grey.shade500,
    'N/A': Colors.grey.shade400,
    // Adicione mais cores se necessário para status específicos
  };

  // NOVO: Mapeamento de cores para o gráfico de Vínculo
  final Map<String, Color> _vinculoColors = {
    'SIM': const Color(0xFF36D97D), // Verde
    'NÃO': Colors.orange.shade600, // Laranja
    'NÃO INFORMADO': Colors.grey.shade400, // Cinza
    'OUTROS': Colors.blue.shade400, // Azul claro para outros vínculos
  };

  @override
  void initState() {
    super.initState();
    _metricsStream = _dashboardService.metricsStream;
  }

  @override
  void dispose() {
    _dashboardService.dispose();
    super.dispose();
  }

  Future<void> _reloadData() async {
    await _dashboardService.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.bar_chart),
          SizedBox(width: 10),
          Text('Dashboard de Métricas'),
        ]),
        elevation: 2,
      ),
      body: StreamBuilder<DashboardMetrics>(
        stream: _metricsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: _accentGreen));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(snapshot.error.toString(), textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700, fontSize: 16)),
                    const SizedBox(height: 20),
                    ElevatedButton(onPressed: _reloadData, child: const Text('Tentar Novamente'))
                  ],
                ),
              ),
            );
          }
          if (snapshot.hasData) {
            final metrics = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _reloadData,
              color: _accentGreen,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSectionTitle('Inscritos', Icons.list_alt_rounded),
                  _buildMainMetrics(metrics),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildVinculoPieChart(metrics.vinculoCount), // NOVO: Chamada para o gráfico de Vínculo
                      _buildStatusPieChart(metrics.statusCount),
                      _buildAgeBarChart(metrics.ageDistribution),
                    ],
                  )
                ],
              ),
            );
          }
          return const Center(child: Text('Carregando métricas...'));
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _primaryDark, size: 24),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _primaryDark)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(thickness: 1.5),
        ],
      ),
    );
  }

  Widget _buildMainMetrics(DashboardMetrics metrics) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Resumo Geral", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryDark)),
            const SizedBox(height: 16),
            _buildMetricCard("Total de Pacientes", metrics.totalPacientes.toString(), Icons.people, _primaryDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(child: Text(title, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // NOVO: Widget para o gráfico de pizza de Vínculo Institucional (Agora Interativo e Agrupado)
  Widget _buildVinculoPieChart(Map<String, int> vinculoCount) {
    // 1. Agrupar os dados de Vínculo
    int simTotal = 0;
    int naoTotal = 0;
    int naoInformadoTotal = 0;
    Map<String, int> otherVinculos = {}; // Para agrupar o que não for SIM/NÃO/NÃO INFORMADO

    vinculoCount.forEach((key, value) {
      if (key.toUpperCase().contains('SIM')) {
        simTotal += value;
      } else if (key.toUpperCase().contains('NÃO')) {
        naoTotal += value;
      } else if (key.toUpperCase().contains('NÃO INFORMADO')) {
        naoInformadoTotal += value;
      } else {
        otherVinculos[key.toUpperCase()] = value;
      }
    });

    final List<MapEntry<String, int>> processedEntries = [];
    if (simTotal > 0) processedEntries.add(MapEntry('SIM', simTotal));
    if (naoTotal > 0) processedEntries.add(MapEntry('NÃO', naoTotal));
    if (naoInformadoTotal > 0) processedEntries.add(MapEntry('NÃO INFORMADO', naoInformadoTotal));

    // Se houver "outros" vínculos, adicione-os como uma única fatia "OUTROS"
    int othersTotal = otherVinculos.values.fold(0, (sum, item) => sum + item);
    if (othersTotal > 0) {
      processedEntries.add(MapEntry('OUTROS', othersTotal));
    }

    double total = processedEntries.fold(0, (sum, entry) => sum + entry.value.toDouble());
    if (processedEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 500, // Largura similar ao gráfico de Status
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Vínculo Institucional", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryDark)),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: fl.PieChart(
                    fl.PieChartData(
                      pieTouchData: fl.PieTouchData(touchCallback: (fl.FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                            _vinculoTouchedIndex = -1;
                            return;
                          }
                          _vinculoTouchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      }),
                      borderData: fl.FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: List.generate(processedEntries.length, (i) {
                        final isTouched = i == _vinculoTouchedIndex;
                        final fontSize = isTouched ? 18.0 : 12.0;
                        final radius = isTouched ? 70.0 : 60.0;
                        final shadows = [const Shadow(color: Colors.black, blurRadius: 2)];
                        final entry = processedEntries[i];
                        final percentage = total > 0 ? (entry.value / total * 100) : 0;
                        return fl.PieChartSectionData(
                          color: _vinculoColors[entry.key] ?? Colors.blue, // Usar as cores do vínculo
                          value: entry.value.toDouble(),
                          title: '${percentage.toStringAsFixed(0)}%',
                          radius: radius,
                          titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: shadows),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(processedEntries.length, (i) {
                      final entry = processedEntries[i];
                      final isTouched = i == _vinculoTouchedIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: _buildLegendItem(_vinculoColors[entry.key] ?? Colors.blue, "${entry.key} (${entry.value})", isTouched),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPieChart(StatusCount statusCount) {
    final filteredData = Map.fromEntries(statusCount.entries.where((entry) => entry.value > 0));
    final sortedEntries = filteredData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sortedEntries.take(5).toList();
    final otherEntries = sortedEntries.skip(5).toList();
    int othersTotal = otherEntries.fold(0, (sum, entry) => sum + entry.value);
    final List<MapEntry<String, int>> dataEntries = [...topEntries];
    if (othersTotal > 0) {
      dataEntries.add(MapEntry('OUTROS', othersTotal));
    }
    double total = dataEntries.fold(0, (sum, entry) => sum + entry.value.toDouble());
    if (dataEntries.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: 500,
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Distribuição por Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryDark)),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: fl.PieChart(
                    fl.PieChartData(
                      pieTouchData: fl.PieTouchData(touchCallback: (fl.FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                            _statusTouchedIndex = -1; // Usar o novo índice
                            return;
                          }
                          _statusTouchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex; // Usar o novo índice
                        });
                      }),
                      borderData: fl.FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: List.generate(dataEntries.length, (i) {
                        final isTouched = i == _statusTouchedIndex; // Usar o novo índice
                        final fontSize = isTouched ? 18.0 : 12.0;
                        final radius = isTouched ? 70.0 : 60.0;
                        final shadows = [const Shadow(color: Colors.black, blurRadius: 2)];
                        final entry = dataEntries[i];
                        final percentage = total > 0 ? (entry.value / total * 100) : 0;
                        return fl.PieChartSectionData(
                          color: _statusColors[entry.key] ?? Colors.orange.shade400,
                          value: entry.value.toDouble(),
                          title: '${percentage.toStringAsFixed(0)}%',
                          radius: radius,
                          titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: shadows),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(dataEntries.length, (i) {
                      final entry = dataEntries[i];
                      final isTouched = i == _statusTouchedIndex; // Usar o novo índice
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: _buildLegendItem(_statusColors[entry.key] ?? Colors.orange.shade400, "${entry.key} (${entry.value})", isTouched),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text, bool isTouched) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: isTouched ? color.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontWeight: isTouched ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }

  Widget _buildAgeBarChart(AgeDistribution ageDistribution) {
    final chartData = ageDistribution.entries.where((entry) => entry.value > 0).map((entry) => _ChartData(entry.key, entry.value.toDouble(), _accentGreen)).toList();
    if (chartData.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: 500,
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 10)]),
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(),
        primaryYAxis: const NumericAxis(majorGridLines: MajorGridLines(width: 0.5)),
        title: ChartTitle(text: 'Distribuição por Faixa Etária', textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryDark)),
        series: <CartesianSeries<_ChartData, String>>[
          StackedBarSeries<_ChartData, String>(
            dataSource: chartData,
            xValueMapper: (_ChartData data, _) => data.x,
            yValueMapper: (_ChartData data, _) => data.y,
            pointColorMapper: (_ChartData data, _) => data.color,
            width: 0.6,
            borderRadius: BorderRadius.circular(8),
          )
        ],
      ),
    );
  }
}