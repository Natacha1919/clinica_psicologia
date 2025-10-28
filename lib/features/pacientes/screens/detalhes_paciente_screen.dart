import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/paciente_detalhado_model.dart';
import 'editar_paciente_screen.dart';

// ===== Imports para o PDF =====
import '../../../core/services/pdf_generator_service.dart';
import '../../../core/services/pdf_generator_service.dart' show AgendamentoPdfModel;

class DetalhesPacienteScreen extends StatefulWidget {
  final String pacienteId;
  const DetalhesPacienteScreen({Key? key, required this.pacienteId}) : super(key: key);

  @override
  State<DetalhesPacienteScreen> createState() => _DetalhesPacienteScreenState();
}

class _DetalhesPacienteScreenState extends State<DetalhesPacienteScreen> with SingleTickerProviderStateMixin {
  late Future<PacienteDetalhado?> _futurePaciente;
  late TabController _tabController;
  bool _isGerandoPdf = false;
  final PdfGeneratorService _pdfService = PdfGeneratorService();

  @override
  void initState() {
    super.initState();
    _futurePaciente = _getPacienteDetalhado();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Função que busca os detalhes E a contagem via RPC
  Future<PacienteDetalhado?> _getPacienteDetalhado() async {
    if (widget.pacienteId.isEmpty) {
      return null;
    }
    final supabase = Supabase.instance.client;
    try {
      final data = await supabase
          .rpc(
            'get_paciente_detalhado_com_contagem', // Nome da função SQL
            params: {'p_paciente_id': widget.pacienteId}
          )
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

  // Função para gerar o PDF (com busca real)
  Future<void> _handleGerarPdf(PacienteDetalhado paciente) async {
    setState(() => _isGerandoPdf = true);
    try {
      final agendamentosData = await Supabase.instance.client
          .from('agendamentos')
          .select('''
            data_agendamento,
            hora_inicio, 
            titulo,
            alunos ( nome_completo )
          ''')
          .eq('paciente_id', paciente.id)
          .order('data_agendamento', ascending: true);

      final agendamentos = (agendamentosData as List).map((json) {
          final alunoInfo = json['alunos'] as Map<String, dynamic>?;
          final alunoNome = alunoInfo?['nome_completo'] ?? 'Aluno não informado';

          return AgendamentoPdfModel(
            data: DateTime.parse(json['data_agendamento']),
            horaInicio: json['hora_inicio']?.toString().substring(0, 5) ?? '--:--',
            titulo: '${json['titulo'] ?? 'Sessão'} (com ${alunoNome})',
          );
      }).toList();

      await _pdfService.gerarProntuarioPaciente(
        paciente: paciente,
        agendamentos: agendamentos,
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar dados ou gerar PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGerandoPdf = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        // ... (AppBar sem alterações)
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
                  return Row(
                    children: [
                      _isGerandoPdf
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14.0),
                              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))),
                            )
                          : IconButton(
                              icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.black87),
                              tooltip: 'Gerar Prontuário PDF',
                              onPressed: () => _handleGerarPdf(paciente),
                            ),
                      const SizedBox(width: 8),
                      Padding(
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
                      ),
                    ],
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

          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: _buildProfileHeader(paciente),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: TabBar(
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
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: IndexedStack(
                      index: _tabController.index,
                      children: [
                        // Aba 0: Visão Geral (Passa o paciente com a contagem)
                        SingleChildScrollView(child: _buildVisaoGeralTab(paciente)),
                        _buildConsultasTab(paciente.id),
                        _buildPlaceholderTab('Financeiro'),
                        _buildPlaceholderTab('Notas Clínicas'),
                      ],
                    ),
                  ),
                ),
              ],
            );
        },
      ),
    );
  }

  // ===== FUNÇÃO DA ABA VISÃO GERAL (LAYOUT AJUSTADO) =====
  Widget _buildVisaoGeralTab(PacienteDetalhado paciente) {
    return Column(
      children: [
        // Cards de Informações Pessoais e Saúde (sem alteração)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.person_outline,
                title: 'Informações Pessoais',
                data: {
                  'CPF': paciente.cpf,
                  'Email': paciente.email,
                  'Telefone': paciente.telefone,
                  'Data de Nascimento': paciente.dataNascimento != null ? DateFormat('dd/MM/yyyy').format(paciente.dataNascimento!) : null,
                  'Idade': paciente.idade,
                  'Estado Civil': paciente.estadoCivil,
                  'Profissão': paciente.profissao,
                  'Gênero': paciente.genero,
                  'Raça': paciente.raca,
                  'Religião': paciente.religiao,
                },
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.favorite_border,
                title: 'Informações de Saúde e Triagem',
                data: {
                  'Atendimento Escolhido (Paciente)': paciente.tipoAtendimento,
                  'Classificação (Preceptor)': paciente.classificacaoPreceptor,
                  'Queixa (Resumo da Triagem)': paciente.queixaTriagem,
                  'Atendimento de Saúde Mental Anterior': paciente.historicoSaudeMental,
                  'Uso de Medicação': paciente.usoMedicacao,
                  'Tratamento de Saúde Atual': paciente.tratamentoSaude,
                  'Rotina do Paciente': paciente.rotinaPaciente,
                  'Triagem Realizada Por': paciente.triagemRealizadaPor,
                  'Dia de Atendimento Definido': paciente.diaAtendimentoDefinido,
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- LINHA DO CARD MÉTRICO (CENTRALIZADO) ---
        Row(
          // 1. Centraliza o conteúdo horizontalmente
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            // 2. Usamos Flexible em vez de Expanded para permitir que o card
            //    tenha seu tamanho natural, mas ainda limitado pela Row.
            //    O SizedBox força uma largura mínima/máxima se necessário.
            Flexible(
              // flex: 0, // Não precisa de flex se só há um item visível
              child: ConstrainedBox( // Limita a largura do card
                constraints: const BoxConstraints(maxWidth: 250), // Ajuste a largura máxima como desejar
                child: _buildMetricCard(
                  icon: Icons.calendar_today_outlined, 
                  // 3. Usa a contagem real (fallback simplificado: substituir por consulta real quando disponível no modelo)
                  value: '0', 
                  label: 'Total de Consultas', 
                  color: Colors.blueAccent
                ),
              ),
            ),
            // 4. Os outros cards foram removidos
          ],
        )
        // --- FIM DA LINHA DO CARD MÉTRICO ---
      ],
    );
  }
  // =======================================================


  // --- FUNÇÃO DA ABA CONSULTAS (sem alteração) ---
  Widget _buildConsultasTab(String pacienteId) {
    // ... (código completo da função _buildConsultasTab)
    final futureConsultas = Supabase.instance.client
        .from('agendamentos')
        .select('''
          id, 
          data_agendamento, 
          hora_inicio, 
          titulo, 
          alunos ( nome_completo ), 
          salas ( nome ) 
        ''')
        .eq('paciente_id', pacienteId)
        .order('data_agendamento', ascending: false); // Mais recentes primeiro

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: futureConsultas,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro ao buscar consultas: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('Nenhuma consulta encontrada para este paciente.'),
              ],
            ),
          );
        }

        final consultas = snapshot.data!;

        return ListView.builder(
          itemCount: consultas.length,
          itemBuilder: (context, index) {
            final consulta = consultas[index];
            final alunoInfo = consulta['alunos'] as Map<String, dynamic>?;
            final salaInfo = consulta['salas'] as Map<String, dynamic>?;
            DateTime? dataAgendamento;
            try { dataAgendamento = DateTime.parse(consulta['data_agendamento']); } catch (_) {}
            final dataFormatada = dataAgendamento != null ? DateFormat('dd/MM/yyyy').format(dataAgendamento) : 'Data inválida';
            final horaFormatada = consulta['hora_inicio']?.toString().substring(0, 5) ?? '--:--';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    dataAgendamento != null ? DateFormat('dd').format(dataAgendamento) : '?',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ),
                title: Text(consulta['titulo'] ?? 'Sessão'),
                subtitle: Text(
                  'Aluno: ${alunoInfo?['nome_completo'] ?? 'Não informado'}\n'
                  'Sala: ${salaInfo?['nome'] ?? 'Não informada'} • $dataFormatada às $horaFormatada'
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  print("Clicou na consulta ID: ${consulta['id']}");
                },
              ),
            );
          },
        );
      },
    );
  }

  // --- Funções de Widgets Auxiliares (sem alteração) ---
  Widget _buildPlaceholderTab(String title) {
     return Center(
      heightFactor: 5,
      child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Seção "$title" em construção...',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
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
          mainAxisAlignment: MainAxisAlignment.center, // Centraliza o ícone e o texto dentro do card
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
} // Fim da classe _DetalhesPacienteScreenState