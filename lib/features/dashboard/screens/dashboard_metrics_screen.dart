// lib/features/dashboard/screens/dashboard_metrics_screen.dart

import 'package:flutter/material.dart';
import '../../../core/config/supabase_config.dart';
import '../../triagem/models/paciente_model.dart'; // Importe o modelo de Paciente
import '../../triagem/models/status_paciente.dart'; // Importe o enum de Status

class DashboardMetricsScreen extends StatefulWidget {
  const DashboardMetricsScreen({super.key});

  @override
  State<DashboardMetricsScreen> createState() => _DashboardMetricsScreenState();
}

class _DashboardMetricsScreenState extends State<DashboardMetricsScreen> {
  // Variáveis de estado para cada métrica
  int? _totalInscritos;
  int? _pacientesEmTriagem;
  int? _pacientesEmAtendimento;
  double? _mediaIdade;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarMetricas();
  }

  Future<void> _carregarMetricas() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      // Usamos Future.wait para rodar todas as buscas em paralelo, é mais rápido!
      final responses = await Future.wait([
        // 0: Total de inscritos
        SupabaseConfig.client.from('pacientes_inscritos').count(),
        // 1: Total em triagem
        SupabaseConfig.client.from('pacientes_inscritos').count().eq('categoria', StatusPaciente.triagem.valor),
        // 2: Total em atendimento
        SupabaseConfig.client.from('pacientes_inscritos').count().eq('categoria', StatusPaciente.emAtendimento.valor),
        // 3: Datas de nascimento para calcular a média de idade
        SupabaseConfig.client.from('pacientes_inscritos')
          .select('data_nascimento')
          .inFilter('categoria', [StatusPaciente.triagem.valor, StatusPaciente.emAtendimento.valor])
      ]);

      // Processa as respostas
      final totalCount = responses[0] as int;
      final triagemCount = responses[1] as int;
      final atendimentoCount = responses[2] as int;
      final pacientesParaMediaIdade = List<Map<String, dynamic>>.from(responses[3] as List);

      final mediaIdade = _calcularMediaIdade(pacientesParaMediaIdade);

      if (mounted) {
        setState(() {
          _totalInscritos = totalCount;
          _pacientesEmTriagem = triagemCount;
          _pacientesEmAtendimento = atendimentoCount;
          _mediaIdade = mediaIdade;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar métricas: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double? _calcularMediaIdade(List<Map<String, dynamic>> pacientes) {
    if (pacientes.isEmpty) return 0;

    double somaIdades = 0;
    int pacientesValidos = 0;
    
    for (var p in pacientes) {
      final dataNascStr = p['data_nascimento'];
      if (dataNascStr != null) {
        final dataNasc = DateTime.tryParse(dataNascStr);
        if (dataNasc != null) {
          final idade = DateTime.now().year - dataNasc.year;
          somaIdades += idade;
          pacientesValidos++;
        }
      }
    }
    return pacientesValidos > 0 ? somaIdades / pacientesValidos : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( /* ... */ ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.count(
          crossAxisCount: 4,
          childAspectRatio: 1.3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMetricCard(context, title: 'Total de Inscritos', value: _isLoading ? '...' : _totalInscritos?.toString() ?? '0', icon: Icons.group, color: Colors.blue),
            _buildMetricCard(context, title: 'Pacientes em Triagem', value: _isLoading ? '...' : _pacientesEmTriagem?.toString() ?? '0', icon: Icons.hourglass_empty, color: Colors.orange),
            _buildMetricCard(context, title: 'Em Atendimento', value: _isLoading ? '...' : _pacientesEmAtendimento?.toString() ?? '0', icon: Icons.medical_services, color: Colors.teal),
            _buildMetricCard(context, title: 'Média de Idade (Ativos)', value: _isLoading ? '...' : '${_mediaIdade?.toStringAsFixed(1) ?? '0'} anos', icon: Icons.cake, color: Colors.purple),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para construir os cards
  Widget _buildMetricCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Icon(icon, size: 28, color: color.withOpacity(0.7)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}