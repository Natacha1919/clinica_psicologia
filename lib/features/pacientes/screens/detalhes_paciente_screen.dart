// lib/features/pacientes/screens/detalhes_paciente_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/paciente_detalhado_model.dart';
import 'editar_paciente_screen.dart';

class DetalhesPacienteScreen extends StatefulWidget {
  final String pacienteId;
  const DetalhesPacienteScreen({Key? key, required this.pacienteId}) : super(key: key);

  @override
  State<DetalhesPacienteScreen> createState() => _DetalhesPacienteScreenState();
}

class _DetalhesPacienteScreenState extends State<DetalhesPacienteScreen> with SingleTickerProviderStateMixin {
  late Future<PacienteDetalhado?> _futurePaciente;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _futurePaciente = _getPacienteDetalhado();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<PacienteDetalhado?> _getPacienteDetalhado() async {
    if (widget.pacienteId.isEmpty) {
      return null;
    }
    final supabase = Supabase.instance.client;
    try {
      const selectColumns = 
        'id, inscrito_id, nome_completo, cpf, status_detalhado, data_desligamento, '
        'contato, endereco, data_nascimento, idade, sexo, genero, raca, '
        'religiao, estado_civil, escolaridade, profissao, demanda_inicial, n_de_inscrição';

      final data = await supabase
          .from('pacientes_historico_temp')
          .select(selectColumns)
          .eq('id', widget.pacienteId)
          .single();
      
      return PacienteDetalhado.fromJson(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar detalhes do paciente: $e')),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Perfil do Paciente', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Informações completas e histórico', style: TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
        actions: [
          FutureBuilder<PacienteDetalhado?>(
              future: _futurePaciente,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final paciente = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditarPacienteScreen(paciente: paciente),
                          ),
                        );
                        if (result == true) {
                          setState(() {
                            _futurePaciente = _getPacienteDetalhado();
                          });
                        }
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Editar Informações'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A28D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
        ],
      ),
      body: FutureBuilder<PacienteDetalhado?>(
        future: _futurePaciente,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Não foi possível carregar os dados do paciente.'));
          }

          final paciente = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(paciente),
                const SizedBox(height: 24),
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Visão Geral'),
                    Tab(text: 'Consultas'),
                    Tab(text: 'Financeiro'),
                    Tab(text: 'Notas Clínicas'),
                  ],
                ),
                const SizedBox(height: 24),
                [
                  _buildVisaoGeralTab(paciente),
                  _buildPlaceholderTab('Consultas'),
                  _buildPlaceholderTab('Financeiro'),
                  _buildPlaceholderTab('Evolução Psicológica'),
                ][_tabController.index],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVisaoGeralTab(PacienteDetalhado paciente) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.person_outline,
                title: 'Informações Pessoais',
                data: {
                  'Data de Nascimento': paciente.dataNascimento != null ? DateFormat('dd/MM/yyyy').format(paciente.dataNascimento!) : null,
                  'Idade': paciente.idade != null ? '${paciente.idade} anos' : null,
                  'Estado Civil': paciente.estadoCivil,
                  'Escolaridade': paciente.escolaridade,
                  'Profissão': paciente.profissao,
                  'Gênero': paciente.genero,
                  'Raça/Cor': paciente.raca,
                  'Religião': paciente.religiao,
                },
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.favorite_border,
                title: 'Informações de Saúde',
                data: {
                  'Demanda Inicial': paciente.demandaInicial,
                  'Alergias': null,
                  'Medicamentos em Uso': null,
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildMetricCard(icon: Icons.calendar_today, value: '?', label: 'Total de Consultas', color: Colors.blue)),
            const SizedBox(width: 24),
            Expanded(child: _buildMetricCard(icon: Icons.attach_money, value: '?', label: 'Total Pago', color: Colors.green)),
            const SizedBox(width: 24),
            Expanded(child: _buildMetricCard(icon: Icons.book_online, value: '?', label: 'Consultas Agendadas', color: Colors.orange)),
          ],
        )
      ],
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(
      heightFactor: 5,
      child: Text(
        'Seção "$title" em construção...',
        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required Map<String, String?> data}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            ...data.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text(entry.value ?? 'Não consta', style: const TextStyle(fontSize: 14)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({required IconData icon, required String value, required String label, required Color color}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(PacienteDetalhado paciente) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                paciente.iniciais,
                style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          paciente.nomeCompleto,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Chip(
                        label: Text(
                          paciente.statusDetalhado?.toUpperCase() ?? 'N/A',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor: paciente.isAtivo ? Colors.teal : Colors.grey[600],
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${paciente.idade ?? '?'} anos • CPF: ${paciente.cpf ?? 'Não informado'}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildContactInfo(Icons.email_outlined, paciente.email),
            _buildContactInfo(Icons.phone_outlined, paciente.telefone),
            _buildContactInfo(Icons.location_on_outlined, paciente.endereco),
          ],
        ),
      ],
    );
  }

  Widget _buildContactInfo(IconData icon, String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}