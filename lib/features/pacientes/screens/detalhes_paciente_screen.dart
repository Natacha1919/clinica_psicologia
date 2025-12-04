import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/paciente_detalhado_model.dart'; // Modelo atualizado com totalConsultas
import 'editar_paciente_screen.dart';

// ===== Imports para o PDF =====
import '../../../core/services/pdf_generator_service.dart';
// Modelo para passar dados ao PDF
import '../../../core/services/pdf_generator_service.dart' show AgendamentoPdfModel;

// ===== ADIÇÃO 1: Modelo de Dados para Pagamentos =====
// (Podemos mover para um ficheiro próprio depois, se preferir)
class PagamentoModel {
  final String id;
  final DateTime dataPagamento;
  final double valor;
  final String formaDePagto;

  PagamentoModel({
    required this.id,
    required this.dataPagamento,
    required this.valor,
    required this.formaDePagto,
  });

  factory PagamentoModel.fromJson(Map<String, dynamic> json) {
    return PagamentoModel(
      id: json['id'] as String,
      dataPagamento: DateTime.parse(json['data_pagamento'] as String),
      valor: (json['valor'] as num).toDouble(), // Converte 'num' para 'double'
      formaDePagto: json['forma_de_pagto'] as String? ?? 'Não informada',
    );
  }
}
// ===================================================


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

  // Chave para forçar a atualização da lista de pagamentos
  int _financeiroRefreshKey = 0; 

  @override
  void initState() {
    super.initState();
    _futurePaciente = _getPacienteDetalhado(); // Chama a função que busca paciente + contagem
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
    if (widget.pacienteId.isEmpty) { return null; }
    final supabase = Supabase.instance.client;
    try {
      final data = await supabase
          .rpc('get_paciente_detalhado_com_contagem', params: {'p_paciente_id': widget.pacienteId})
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

  // Função para gerar o PDF (com busca real de agendamentos)
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

  // Função de SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    // Pegamos a cor primária (azul) para usar nos elementos da AppBar
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        
        // ===== MUDANÇA 2: Ícone de Voltar AZUL =====
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor), // Azul
          onPressed: () => Navigator.of(context).pop(),
        ),
        
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== MUDANÇA 2: Título AZUL =====
            Text(
              'Perfil do Paciente', 
              style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const Text('Informações completas e histórico', style: TextStyle(color: Colors.black54, fontSize: 12)),
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
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14.0),
                              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2))),
                            )
                          : IconButton(
                              icon: Icon(Icons.picture_as_pdf_outlined, color: primaryColor),
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
                    // Cores das abas também em azul para combinar
                    labelColor: primaryColor,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: primaryColor,
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
                        SingleChildScrollView(child: _buildVisaoGeralTab(paciente)), 
                        _buildConsultasTab(paciente.id), 
                        _buildFinanceiroTab(paciente.id), 
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

  // (Função _buildVisaoGeralTab - sem alterações)
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child: _buildMetricCard(
                  icon: Icons.calendar_today_outlined, 
                  value: paciente.totalConsultas.toString(), 
                  label: 'Total de Consultas', 
                  color: Colors.blueAccent
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
  
  // (Função _buildConsultasTab - sem alterações)
  Widget _buildConsultasTab(String pacienteId) {
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
        .order('data_agendamento', ascending: false);

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
                Icon(Icons.calendar_month_outlined, size: 48, color: Colors.grey),
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

  // --- FUNÇÃO DA ABA FINANCEIRO (COM EXCLUSÃO) ---
  Widget _buildFinanceiroTab(String pacienteId) {
    final futurePagamentos = Supabase.instance.client
        .from('pagamentos_pacientes') // Nome correto da tabela
        .select()
        .eq('paciente_id', pacienteId)
        .order('data_pagamento', ascending: false);
    
    final key = ValueKey('financeiro_$_financeiroRefreshKey'); 

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Pagamento'),
              onPressed: () {
                _showAddPagamentoDialog(pacienteId); // Chama o diálogo
              },
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            key: key, 
            future: futurePagamentos,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erro ao buscar pagamentos: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('Nenhum pagamento registrado para este paciente.'),
                );
              }

              final pagamentos = snapshot.data!
                  .map((json) => PagamentoModel.fromJson(json))
                  .toList();
              
              final totalPago = pagamentos.fold<double>(0.0, (sum, item) => sum + item.valor);

              return Column(
                children: [
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(Icons.attach_money, color: Colors.green.shade700),
                      title: const Text('Total Pago (Já Registrado)'),
                      trailing: Text(
                        NumberFormat.simpleCurrency(locale: 'pt_BR').format(totalPago),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                      ),
                    ),
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: pagamentos.length,
                      itemBuilder: (context, index) {
                        final pag = pagamentos[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(DateFormat('dd').format(pag.dataPagamento)),
                            ),
                            title: Text(
                              NumberFormat.simpleCurrency(locale: 'pt_BR').format(pag.valor),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Data: ${DateFormat('dd/MM/yyyy').format(pag.dataPagamento)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(pag.formaDePagto),
                                  backgroundColor: Colors.grey.shade100,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: 'Excluir Pagamento',
                                  onPressed: () {
                                    _handleDeletePagamento(
                                      pag.id, 
                                      pag.valor, 
                                      pag.dataPagamento
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // --- DIÁLOGO DE ADICIONAR PAGAMENTO ---
  Future<void> _showAddPagamentoDialog(String pacienteId) async {
    final formKey = GlobalKey<FormState>();
    final valorController = TextEditingController();
    String? selectedFormaPagto; 
    DateTime selectedDate = DateTime.now(); 

    final formasDePagamento = [
      'Pago - Crédito',
      'Pago - Débito',
      'Pago - Pix Manual',
      'Pix - Qrcode',
      'Isento' 
    ];
    bool isLoading = false;

    Future<void> _salvarPagamento(StateSetter setDialogState) async {
      if (!formKey.currentState!.validate()) return;
      setDialogState(() => isLoading = true);
      try {
        await Supabase.instance.client.from('pagamentos_pacientes').insert({ 
          'paciente_id': pacienteId,
          'valor': double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0.0,
          'forma_de_pagto': selectedFormaPagto,
          'data_pagamento': DateFormat('yyyy-MM-dd').format(selectedDate),
        });

        if (mounted) Navigator.of(context).pop(); 
        _showSnackBar('Pagamento salvo com sucesso!');
        setState(() => _financeiroRefreshKey++); 
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        _showSnackBar('Erro ao salvar pagamento: $e', isError: true);
      }
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Registrar Novo Pagamento'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: valorController,
                      decoration: const InputDecoration(labelText: 'Valor (R\$)', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                         if (value == null || value.isEmpty) {
                          if (selectedFormaPagto != 'Isento') {
                            return 'Valor obrigatório';
                          }
                         }
                        final parsedValue = double.tryParse((value ?? '').replaceAll(',', '.'));
                        if (parsedValue == null) {
                           return 'Valor inválido';
                        }
                        if (selectedFormaPagto != 'Isento' && parsedValue <= 0) {
                          return 'Valor deve ser positivo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedFormaPagto,
                      hint: const Text('Forma de Pagamento'),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: formasDePagamento.map((forma) => DropdownMenuItem(value: forma, child: Text(forma))).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedFormaPagto = value;
                          if (value == 'Isento') { valorController.text = '0.00'; }
                        });
                      },
                      validator: (value) => value == null ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Data do Pagamento'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (pickedDate != null && pickedDate != selectedDate) {
                          setDialogState(() => selectedDate = pickedDate);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: isLoading ? null : () => _salvarPagamento(setDialogState),
                  icon: isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                  label: Text(isLoading ? 'Salvando...' : 'Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  // --- FUNÇÃO PARA EXCLUIR PAGAMENTO ---
  Future<void> _handleDeletePagamento(String pagamentoId, double valor, DateTime data) async {
    final valorFormatado = NumberFormat.simpleCurrency(locale: 'pt_BR').format(valor);
    final dataFormatada = DateFormat('dd/MM/yyyy').format(data);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o pagamento de $valorFormatado realizado em $dataFormatada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), 
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true), 
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client
            .from('pagamentos_pacientes')
            .delete()
            .eq('id', pagamentoId);
        
        _showSnackBar('Pagamento excluído com sucesso!');
        setState(() => _financeiroRefreshKey++); 

      } on PostgrestException catch (e) {
        _showSnackBar('Erro ao excluir pagamento: ${e.message}', isError: true);
      } catch (e) {
        _showSnackBar('Ocorreu um erro inesperado: $e', isError: true);
      }
    }
  }


  // --- Funções de Widgets Auxiliares ---
  Widget _buildPlaceholderTab(String title) {
     return Center(
      heightFactor: 5,
      child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Seção "$title" em construção...', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
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
          mainAxisAlignment: MainAxisAlignment.center, 
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