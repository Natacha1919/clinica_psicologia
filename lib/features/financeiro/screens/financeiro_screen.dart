// lib/features/financeiro/screens/financeiro_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dropdown_search/dropdown_search.dart'; 

// Importa os modelos de dados necessários
import '../models/pagamento_model.dart';
import '../../pacientes/models/paciente_dropdown_model.dart';

// Modelos de dados para receber os resultados das funções SQL
class ResumoMensal {
  final String formaDePagto;
  final int qde;
  final double total;
  ResumoMensal.fromJson(Map<String, dynamic> json)
      : formaDePagto = json['forma_de_pagto'],
        qde = (json['qde'] as num).toInt(),
        total = (json['total'] as num).toDouble();
}

class ResumoDiario {
  final DateTime dia;
  final String formaDePagto;
  final int qde;
  final double total;
  ResumoDiario.fromJson(Map<String, dynamic> json)
      : dia = DateTime.parse(json['dia']),
        formaDePagto = json['forma_de_pagto'],
        qde = (json['qde'] as num).toInt(),
        total = (json['total'] as num).toDouble();
}

// Estrutura para guardar os resultados
class RelatorioFinanceiro {
  final List<ResumoMensal> resumoMensal;
  final List<ResumoDiario> resumoDiario;
  RelatorioFinanceiro({required this.resumoMensal, required this.resumoDiario});
}


class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({Key? key}) : super(key: key);

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<RelatorioFinanceiro> _relatorioFuture;
  
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  int _refreshKey = 0; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _relatorioFuture = _fetchRelatorioFinanceiro(_selectedMonth);
    
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

  /// Busca os dados das DUAS funções SQL
  Future<RelatorioFinanceiro> _fetchRelatorioFinanceiro(DateTime mes) async {
    final inicioMes = DateFormat('yyyy-MM-dd').format(mes);
    final fimMes = DateFormat('yyyy-MM-dd').format(DateTime(mes.year, mes.month + 1, 0)); 

    try {
      final rpcMensal = Supabase.instance.client.rpc(
        'get_resumo_financeiro_mensal',
        params: {'start_date': inicioMes, 'end_date': fimMes}
      );
      final rpcDiario = Supabase.instance.client.rpc(
        'get_resumo_financeiro_diario',
        params: {'start_date': inicioMes, 'end_date': fimMes}
      );

      final results = await Future.wait([rpcMensal, rpcDiario]);

      final List<ResumoMensal> resumoMensal = (results[0] as List)
          .map((json) => ResumoMensal.fromJson(json))
          .toList();
          
      final List<ResumoDiario> resumoDiario = (results[1] as List)
          .map((json) => ResumoDiario.fromJson(json))
          .toList();

      return RelatorioFinanceiro(resumoMensal: resumoMensal, resumoDiario: resumoDiario);

    } catch (e) {
      _showSnackBar('Erro ao buscar relatório: $e', isError: true);
      throw Exception('Falha ao carregar relatório: $e');
    }
  }

  /// Atualiza o relatório quando um novo mês é selecionado
  void _onMonthSelected(DateTime novoMes) {
    setState(() {
      _selectedMonth = novoMes;
      _relatorioFuture = _fetchRelatorioFinanceiro(novoMes);
      _refreshKey++; 
    });
  }

  /// Exibe o seletor de Mês/Ano
  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null && (picked.month != _selectedMonth.month || picked.year != _selectedMonth.year)) {
      _onMonthSelected(DateTime(picked.year, picked.month, 1));
    }
  }

  // ===== FUNÇÃO CORRIGIDA (IGUAL À DA TELA DE AGENDAMENTO) =====
  /// Busca pacientes para o dropdown
  Future<List<PacienteDropdownModel>> _fetchPacientesParaDropdown({String? filtroNome}) async {
    print("Buscando pacientes com filtro: '$filtroNome'"); 
    try {
      // Usa a MESMA lista de status da tela de agendamento
      final List<String> statusAtivos = [ 
        'PG - ATIVO', 
        'BR - ATIVO', 
        'ISENTO COLABORADOR', 
        'ISENTO - ORIENTAÇÃO P.'
      ];
      
      var query = Supabase.instance.client
          .from('pacientes_historico_temp')
          .select('id, nome_completo')
          .filter('status_detalhado', 'in', statusAtivos); // Filtro IN

      if (filtroNome != null && filtroNome.isNotEmpty) { 
        query = query.ilike('nome_completo', '%$filtroNome%'); 
      }
      final data = await query.order('nome_completo', ascending: true);
      final pacientes = (data as List)
          .map((json) => PacienteDropdownModel.fromJson(json))
          .toList();

      if (pacientes.isEmpty && (filtroNome == null || filtroNome.isEmpty) && mounted) {
        _showSnackBar('Nenhum paciente com status válido encontrado.', isError: true);
      }
      
      return pacientes;

    } catch (e) { 
      _showSnackBar('Erro ao buscar pacientes: $e', isError: true); 
      return []; 
    }
  }
  // ==============================================================

  /// Exibe feedback
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }
  
  /// DIÁLOGO DE ADICIONAR PAGAMENTO (Completo e Corrigido)
  Future<void> _showAddPagamentoDialog() async {
    final formKey = GlobalKey<FormState>();
    final valorController = TextEditingController();
    String? selectedFormaPagto; 
    DateTime selectedDate = DateTime.now();
    PacienteDropdownModel? selectedPaciente;

    final formasDePagamento = ['Pago - Crédito', 'Pago - Débito', 'Pago - Pix Manual', 'Pix - Qrcode', 'Isento'];
    bool isLoading = false;

    // Função interna para salvar o pagamento
    Future<void> _salvarPagamento(StateSetter setDialogState) async {
      if (!formKey.currentState!.validate()) return;
      if (selectedPaciente == null) {
        _showSnackBar('É obrigatório selecionar um paciente.', isError: true);
        return;
      }
      
      setDialogState(() => isLoading = true);
      try {
        await Supabase.instance.client.from('pagamentos_pacientes').insert({
          'paciente_id': selectedPaciente!.id,
          'valor': double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0.0,
          'forma_de_pagto': selectedFormaPagto,
          'data_pagamento': DateFormat('yyyy-MM-dd').format(selectedDate),
        });

        if (mounted) Navigator.of(context).pop(); 
        _showSnackBar('Pagamento salvo com sucesso!');
        _onMonthSelected(_selectedMonth); // Atualiza o relatório

      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        _showSnackBar('Erro ao salvar pagamento: $e', isError: true);
      }
    }

    // Chama o 'showDialog'
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Registrar Novo Pagamento'),
              content: SizedBox(
                width: 500, 
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView( 
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- SELEÇÃO DE PACIENTE ---
                        DropdownSearch<PacienteDropdownModel>(
                          asyncItems: (String filter) => _fetchPacientesParaDropdown(filtroNome: filter), 
                          itemAsString: (PacienteDropdownModel p) => p.nomeCompleto,
                          onChanged: (PacienteDropdownModel? data) {
                            setDialogState(() => selectedPaciente = data);
                          },
                          popupProps: PopupProps.menu(
                            showSearchBox: true, 
                            searchFieldProps: const TextFieldProps(
                              decoration: InputDecoration(labelText: "Pesquisar Paciente", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                              autofocus: true,
                            ),
                            emptyBuilder: (context, searchEntry) => const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text("Nenhum paciente encontrado."))),
                          ),
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(labelText: "Paciente*", border: OutlineInputBorder()),
                          ),
                          selectedItem: selectedPaciente,
                          validator: (value) => value == null ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        // --- Campo Valor ---
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
                            final parsedValue = double.tryParse(value?.replaceAll(',', '.') ?? '');
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
                        // --- Campo Forma de Pagamento ---
                        DropdownButtonFormField<String>(
                          value: selectedFormaPagto,
                          hint: const Text('Forma de Pagamento'),
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          items: formasDePagamento.map((forma) => DropdownMenuItem(value: forma, child: Text(forma))).toList(),
                          onChanged: (value) {
                            setDialogState(() { 
                              selectedFormaPagto = value; 
                              if (value == 'Isento') {
                                valorController.text = '0.00';
                              }
                            });
                          },
                          validator: (value) => value == null ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        // --- Campo Data ---
                        ListTile(
                          contentPadding: EdgeInsets.zero,
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
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: isLoading ? null : () => _salvarPagamento(setDialogState),
                  icon: isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                  label: Text(isLoading ? 'Salvando...' : 'Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Lançamento'),
              onPressed: _showAddPagamentoDialog, 
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Relatório Mensal'), 
            Tab(text: 'Lançamentos Recentes'), 
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRelatorioTab(),
          _buildLancamentosTab(),
        ],
      ),
    );
  }

  /// Constrói a Aba 1: Relatório Mensal
  Widget _buildRelatorioTab() {
    return Column(
      children: [
        _buildMonthSelector(context),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _onMonthSelected(_selectedMonth),
            child: FutureBuilder<RelatorioFinanceiro>(
              key: ValueKey('relatorio_$_refreshKey'), 
              future: _relatorioFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar relatório: ${snapshot.error}'));
                }
                if (!snapshot.hasData || (snapshot.data!.resumoMensal.isEmpty && snapshot.data!.resumoDiario.isEmpty)) {
                  return const Center(child: Text('Nenhum dado encontrado para este mês.'));
                }

                final relatorio = snapshot.data!;
                return _buildRelatorioContent(relatorio);
              },
            ),
          ),
        ),
      ],
    );
  }
  
  /// Constrói a Aba 2: Lista de Lançamentos
  Widget _buildLancamentosTab() {
    final futureLancamentos = Supabase.instance.client
        .from('pagamentos_pacientes')
        .select('''
          *, 
          pacientes_historico_temp:paciente_id ( id, nome_completo )
        ''') 
        .order('data_pagamento', ascending: false) 
        .limit(100); 

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _refreshKey++);
      },
      child: FutureBuilder<List<Map<String, dynamic>>>(
        key: ValueKey('lancamentos_$_refreshKey'), 
        future: futureLancamentos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao buscar lançamentos: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Nenhum lançamento financeiro encontrado.'),
            );
          }

          final pagamentos = snapshot.data!
              .map((json) => PagamentoModel.fromJson(json))
              .toList();
              
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
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
                    pag.paciente?.nomeCompleto ?? 'Paciente não encontrado',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Forma: ${pag.formaDePagto} • Data: ${DateFormat('dd/MM/yyyy').format(pag.dataPagamento)}'
                  ),
                  trailing: Text(
                    NumberFormat.simpleCurrency(locale: 'pt_BR').format(pag.valor),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                  ),
                  onTap: () {
                    // TODO: Ação de clique (ex: editar lançamento)
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  
  /// Widget Seletor de Mês
  Widget _buildMonthSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _onMonthSelected(DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1)),
          ),
          InkWell(
            onTap: () => _selectMonth(context),
            child: Text(
              DateFormat('MMMM de yyyy', 'pt_BR').format(_selectedMonth),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _onMonthSelected(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1)),
          ),
        ],
      ),
    );
  }

  /// Constrói o conteúdo principal do relatório
  Widget _buildRelatorioContent(RelatorioFinanceiro relatorio) {
    final double totalGeralValor = relatorio.resumoMensal.fold(0.0, (sum, item) => sum + item.total);
    final int totalGeralQde = relatorio.resumoMensal.fold(0, (sum, item) => sum + item.qde);
    final Map<DateTime, List<ResumoDiario>> dadosAgrupadosPorDia = {};
    for (var res in relatorio.resumoDiario) {
      if (!dadosAgrupadosPorDia.containsKey(res.dia)) {
        dadosAgrupadosPorDia[res.dia] = [];
      }
      dadosAgrupadosPorDia[res.dia]!.add(res);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildResumoMensalCard(relatorio.resumoMensal, totalGeralQde, totalGeralValor),
          const SizedBox(height: 24),
          _buildDetalhadoPorDiaCard(dadosAgrupadosPorDia),
        ],
      ),
    );
  }
  
  /// Card do Resumo Mensal
  Widget _buildResumoMensalCard(List<ResumoMensal> resumoMensal, int totalGeralQde, double totalGeralValor) {
    final formatadorReais = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Resumo do Mês', style: Theme.of(context).textTheme.headlineSmall),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(flex: 3, child: Text('Forma de Pagamento', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Qde.', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('\$ Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 8),
            ...resumoMensal.map((resumo) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(flex: 3, child: Text(resumo.formaDePagto)),
                    Expanded(flex: 1, child: Text(resumo.qde.toString(), textAlign: TextAlign.right)),
                    Expanded(flex: 2, child: Text(formatadorReais.format(resumo.total), textAlign: TextAlign.right)),
                  ],
                ),
              );
            }).toList(),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(flex: 3, child: Text('TOTAL MÊS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Expanded(flex: 1, child: Text(totalGeralQde.toString(), textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Expanded(flex: 2, child: Text(formatadorReais.format(totalGeralValor), textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Card do Detalhado por Dia
  Widget _buildDetalhadoPorDiaCard(Map<DateTime, List<ResumoDiario>> dadosAgrupados) {
    final formatadorReais = NumberFormat.simpleCurrency(locale: 'pt_BR');
    if (dadosAgrupados.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Nenhum lançamento neste mês.')),
        ),
      );
    }
    final diasOrdenados = dadosAgrupados.keys.toList()..sort();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Detalhado por Dia', style: Theme.of(context).textTheme.headlineSmall),
            const Divider(height: 24),
            ...diasOrdenados.map((dia) {
              final lancamentosDoDia = dadosAgrupados[dia]!;
              final totalDoDia = lancamentosDoDia.fold<double>(0.0, (sum, item) => sum + item.total);
              
              return ExpansionTile(
                title: Text(
                  DateFormat('dd/MM/yyyy (EEE)', 'pt_BR').format(dia), 
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
                trailing: Text(
                  formatadorReais.format(totalDoDia),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)
                ),
                children: lancamentosDoDia.map((resumo) {
                  return ListTile(
                    title: Text(resumo.formaDePagto),
                    leading: Text('${resumo.qde}x', style: const TextStyle(color: Colors.grey)), 
                    trailing: Text(formatadorReais.format(resumo.total)), 
                    dense: true,
                  );
                }).toList(),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}