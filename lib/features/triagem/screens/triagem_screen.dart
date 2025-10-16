// lib/features/triagem/screens/triagem_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/config/supabase_config.dart';
import '../models/paciente_model.dart';
import '../models/status_paciente.dart';
import 'detalhes_paciente_screen.dart';

class TriagemScreen extends StatefulWidget {
  const TriagemScreen({Key? key}) : super(key: key);

  @override
  State<TriagemScreen> createState() => _TriagemScreenState();
}

class _TriagemScreenState extends State<TriagemScreen> {
  final Color _primaryDark = const Color(0xFF122640);
  final Color _accentGreen = const Color(0xFF36D97D);
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;
  List<Paciente> _pacientesOriginais = [];
  List<Paciente> _pacientesFiltrados = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarPacientes);
    _carregarDados();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filtrarPacientes);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // CORRIGIDO: Lista de colunas 100% atualizada
      const selectColumns =
          'id, created_at, categoria, data_hora_envio, telefone, data_nascimento, '
          'idade_texto, nome_completo, termo_consentimento, nome_social, cpf, '
          'nome_pai, nome_mae, estado_civil, religiao, endereco, encaminhamento, '
          'vinculo_unifecaf_status, vinculo_unifecaf_detalhe, email, renda_mensal, '
          'email_secundario, modalidade_preferencial, dias_preferenciais, '
          'horarios_preferenciais, polo_ead, tipo_atendimento, '
          'historico_saude_mental, uso_medicacao, queixa_triagem, tratamento_saude, '
          'rotina_paciente, triagem_realizada_por, dia_atendimento_definido, '
          'sexo, raca, escolaridade, profissao, escolaridade_pai, profissao_pai, '
          'escolaridade_mae, profissao_mae, prioridade_atendimento';

      final response = await SupabaseConfig.client
          .from('pacientes_inscritos')
          .select(selectColumns)
          .order('data_hora_envio', ascending: false);
          
      final dataList = List<Map<String, dynamic>>.from(response);
      final pacientes = dataList.map((json) => Paciente.fromJson(json)).toList();

      if (mounted) {
        setState(() {
          _pacientesOriginais = pacientes;
          _pacientesFiltrados = pacientes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Falha ao carregar dados: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _filtrarPacientes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _pacientesFiltrados = _pacientesOriginais.where((paciente) {
        return paciente.nomeCompleto.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.person_search_outlined), SizedBox(width: 10), Text('Pacientes Inscritos')]),
        elevation: 2,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Pesquisar por nome...',
              prefixIcon: Icon(Icons.search, color: _primaryDark),
              border: InputBorder.none,
              suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear()) : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _accentGreen));
    }
    if (_errorMessage != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage!, textAlign: TextAlign.center)));
    }
    if (_pacientesFiltrados.isEmpty) {
      return const Center(child: Text('Nenhum paciente encontrado.'));
    }
    return RefreshIndicator(
      onRefresh: _carregarDados,
      color: _accentGreen,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _pacientesFiltrados.length,
        itemBuilder: (context, index) {
          final paciente = _pacientesFiltrados[index];
          return _buildPacienteCard(paciente);
        },
      ),
    );
  }
  
  Widget _buildPacienteCard(Paciente paciente) {
    final status = StatusPaciente.values.firstWhere(
      (e) => e.valor.toUpperCase() == (paciente.categoria?.toUpperCase() ?? 'ESPERA'),
      orElse: () => StatusPaciente.espera,
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => DetalhesPacienteScreen(pacienteId: paciente.id)))
              .then((_) => _carregarDados());
        },
        child: Row(
          children: [
            Container(
              width: 8,
              height: 100,
              decoration: BoxDecoration(color: status.cor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(paciente.nomeCompleto, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primaryDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('CPF: ${paciente.cpf ?? 'Não informado'}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: status.cor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text(status.valor, style: TextStyle(color: status.cor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const Spacer(),
                      if (paciente.dataHoraEnvio != null)
                        Text(DateFormat('dd/MM/yyyy').format(paciente.dataHoraEnvio!), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}