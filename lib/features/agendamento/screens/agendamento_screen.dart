// lib/features/agendamento/screens/agendamento_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart'; // Import necessário
import '../../../core/config/supabase_config.dart';
import '../models/agendamento_model.dart'; // Importa o modelo atualizado (com nomes)
import '../models/sala_model.dart';
import '../../pacientes/models/paciente_dropdown_model.dart';
import '../../alunos/models/aluno_model.dart';
import 'package:dropdown_search/dropdown_search.dart'; // Import do dropdown com pesquisa

class AgendamentoScreen extends StatefulWidget {
  const AgendamentoScreen({Key? key}) : super(key: key);

  @override
  State<AgendamentoScreen> createState() => _AgendamentoScreenState();
}

class _AgendamentoScreenState extends State<AgendamentoScreen> {
  // Campos agora usados novamente pelo TableCalendar e _buildTimetable
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = true;
  String? _errorMessage;

  List<Sala> _salas = []; // Usado por _buildTimetable
  List<Agendamento> _agendamentosDoDia = [];

  final double _horaHeight = 60.0;
  final double _roomWidth = 150.0;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR');
    _fetchDataParaDia(_selectedDay);
  }

  // Função _fetchDataParaDia (Usa SELECT com nomes)
  Future<void> _fetchDataParaDia(DateTime dia) async {
    if (mounted) setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final salasResponse = await SupabaseConfig.client
          .from('salas')
          .select()
          .order('nome', ascending: true);

      final agendamentosResponse = await SupabaseConfig.client
          .from('agendamentos')
          .select('''
            *, 
            pacientes:paciente_id ( nome_completo ), 
            alunos:aluno_id ( nome_completo )
          ''') 
          .eq('data_agendamento', DateFormat('yyyy-MM-dd').format(dia));

      final List<Map<String, dynamic>> salasData = List<Map<String, dynamic>>.from(salasResponse as List);
      final List<Map<String, dynamic>> agendamentosData = List<Map<String, dynamic>>.from(agendamentosResponse as List);

      if (mounted) {
        setState(() {
          _salas = salasData.map((json) => Sala.fromJson(json)).toList();
          _agendamentosDoDia = agendamentosData.map((json) => Agendamento.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Falha ao carregar dados: ${e.toString()}', isError: true);
      if (mounted) setState(() { _isLoading = false; _errorMessage = e.toString(); });
    }
  }

  // ===== FUNÇÃO CORRIGIDA PARA USAR .filter() =====
  /// Busca a lista de pacientes (apenas ID e Nome) para o dropdown.
Future<List<PacienteDropdownModel>> _fetchPacientesParaDropdown({String? filtroNome}) async {
    print("Buscando pacientes com filtro: '$filtroNome'"); 
    try {
      final List<String> statusAtivos = [
        'PG - ATIVO',
        'BR - ATIVO',
        'ISENTO COLABORADOR',
        'ISENTO - ORIENTAÇÃO P.'
      ];
      
      // ===== CORREÇÃO DA SINTAXE DO FILTRO .in() =====
      // Passamos a LISTA 'statusAtivos' diretamente.
      // A biblioteca supabase-flutter vai formatar para: status_detalhado=in.("PG - ATIVO","BR - ATIVO",...)
      
      var query = Supabase.instance.client
          .from('pacientes_historico_temp') 
          .select('id, nome_completo')
          // Passa a lista diretamente como terceiro argumento
          .filter('status_detalhado', 'in', statusAtivos); // <-- CORREÇÃO APLICADA

      if (filtroNome != null && filtroNome.isNotEmpty) {
        query = query.ilike('nome_completo', '%$filtroNome%'); 
      }
      final data = await query.order('nome_completo', ascending: true);
      final pacientes = (data as List)
          .map((json) => PacienteDropdownModel.fromJson(json))
          .toList();
      print("Pacientes encontrados (com filtro de status): ${pacientes.length}"); 
      
      if (pacientes.isEmpty && (filtroNome == null || filtroNome.isEmpty) && mounted) {
        _showSnackBar('Nenhum paciente com status válido para agendamento foi encontrado.', isError: true);
      }
      return pacientes; 
      
    } catch (e) {
      print("Erro ao buscar pacientes (com filtro de status): $e"); 
      _showSnackBar('Erro ao buscar pacientes: $e', isError: true);
      return []; 
    }
  }
  // ===============================================

  // Função _fetchAlunosParaDropdown (sem alterações)
  Future<List<AlunoModel>> _fetchAlunosParaDropdown() async {
     try {
      final data = await Supabase.instance.client
          .from('alunos') 
          .select('id, nome_completo, ra')
          .order('nome_completo', ascending: true);
      final alunos = (data as List).map((json) => AlunoModel.fromJson(json)).toList();
      return alunos;
    } catch (e) {
      _showSnackBar('Erro ao buscar alunos: $e', isError: true);
      return []; 
    }
  }

  // Função _criarAgendamento (sem alterações)
  Future<void> _criarAgendamento({
    required Sala sala,
    required TimeOfDay horario,
    required String titulo,
    required bool isRecorrente,
    DateTime? dataFimRecorrencia,
    required String pacienteId,
    required String alunoId,
  }) async {
    // ... (código igual)
     final horaInicio = '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}:00';
    final horaFim = '${(horario.hour + 1).toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}:00';
    final data = DateFormat('yyyy-MM-dd').format(_selectedDay);
    try {
      await SupabaseConfig.client.from('agendamentos').insert({
        'sala_id': sala.id,
        'paciente_id': pacienteId, 
        'aluno_id': alunoId,       
        'data_agendamento': data,
        'hora_inicio': horaInicio,
        'hora_fim': horaFim,
        'titulo': titulo.isNotEmpty ? titulo : 'Agendado',
        'is_recorrente': isRecorrente,
        'data_fim_recorrencia': isRecorrente ? DateFormat('yyyy-MM-dd').format(dataFimRecorrencia!) : null,
      });
      _showSnackBar('Agendamento confirmado com sucesso!');
      await _fetchDataParaDia(_selectedDay);
    } catch (e) {
      _showSnackBar('Erro ao criar agendamento: $e', isError: true);
    }
  }

  // Função _excluirAgendamento (sem alterações)
  Future<void> _excluirAgendamento(String agendamentoId) async {
    // ... (código igual)
      final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Você tem certeza que deseja excluir este agendamento? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Excluir'), style: FilledButton.styleFrom(backgroundColor: Colors.red)),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await SupabaseConfig.client.from('agendamentos').delete().eq('id', agendamentoId);
        _showSnackBar('Agendamento excluído com sucesso!');
        await _fetchDataParaDia(_selectedDay);
      } catch (e) {
        _showSnackBar('Erro ao excluir agendamento: $e', isError: true);
      }
    }
  }

  // Função _showSnackBar (sem alterações)
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  // Função build (sem alterações na estrutura principal)
  @override
  Widget build(BuildContext context) {
     return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Agendamento de Salas'),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Certifica que o calendário está sendo construído
          _buildCalendar(), 
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : RefreshIndicator(
                        onRefresh: () => _fetchDataParaDia(_selectedDay),
                        // Certifica que a grelha de horários está sendo construída
                        child: _buildTimetable(), 
                      ),
          ),
        ],
      ),
    );
  }

  // ===== FUNÇÃO RESTAURADA: _buildCalendar =====
  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: TableCalendar(
        locale: 'pt_BR',
        firstDay: DateTime.utc(2024, 1, 1), // Use _focusedDay ou uma data fixa
        lastDay: DateTime.utc(2030, 12, 31), // Use _focusedDay ou uma data fixa
        focusedDay: _focusedDay, // Usa o _focusedDay
        calendarFormat: CalendarFormat.month,
        headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false),
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay; // Atualiza _focusedDay aqui também
            });
            _fetchDataParaDia(selectedDay);
          }
        },
        onPageChanged: (focusedDay) {
          // Atualiza _focusedDay quando a página muda
          setState(() { 
             _focusedDay = focusedDay;
          });
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
          todayDecoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.5), shape: BoxShape.circle),
        ),
      ),
    );
  }
  // ============================================

  // ===== FUNÇÃO RESTAURADA: _buildTimetable =====
  Widget _buildTimetable() {
    final horas = List.generate(15, (i) => 8 + i); // Variável 'horas' agora usada
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chama a função _buildTimeAxis
            _buildTimeAxis(horas), 
            Row(
              // Chama a função _buildRoomColumn usando a lista _salas
              children: _salas.map((sala) => _buildRoomColumn(sala, horas)).toList(), 
            ),
          ],
        ),
      ),
    );
  }
  // ===========================================

  // ===== FUNÇÃO RESTAURADA: _buildTimeAxis =====
  Widget _buildTimeAxis(List<int> horas) {
    return Container(
      padding: const EdgeInsets.only(top: 40), // Espaço para header da sala
      child: Column(
        children: horas.map((hora) { // Usa a variável 'horas'
          return Container(
            height: _horaHeight,
            width: 60,
            padding: const EdgeInsets.only(right: 8),
            alignment: Alignment.topRight,
            child: Text('${hora.toString().padLeft(2, '0')}:00', style: TextStyle(color: Colors.grey[700])),
          );
        }).toList(),
      ),
    );
  }
  // ==========================================

  // ===== FUNÇÃO RESTAURADA: _buildRoomColumn =====
  // (Com Aparência do Card Original e onTap correto para BottomSheet)
  Widget _buildRoomColumn(Sala sala, List<int> horas) {
    final agendamentosDaSala = _agendamentosDoDia.where((a) => a.salaId == sala.id).toList();
    return Container(
      width: _roomWidth,
      decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.shade200))),
      child: Column(
        children: [
          Container( // Header da Sala
            height: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(sala.nome, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          ),
          Stack(
            children: [
              Column( // Coluna dos slots vazios com '+'
                children: horas.map((hora) { // Usa a variável 'horas'
                  final slotTime = TimeOfDay(hour: hora, minute: 0);
                  final agendamentoNesteSlot = agendamentosDaSala.any((ag) {
                     if (ag.horaInicio == null || ag.horaFim == null) return false;
                     return (hora >= ag.horaInicio!.hour && hora < ag.horaFim!.hour);
                  });
                  return Container(
                    height: _horaHeight,
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
                    child: Center(
                      child: agendamentoNesteSlot ? null : IconButton(
                        icon: Icon(Icons.add_circle_outline, color: Colors.grey.shade400, size: 20),
                        onPressed: () => _showCreateDialog(sala: sala, horario: slotTime),
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Mapeia os agendamentos para criar os cards
              ...agendamentosDaSala.map((agendamento) {
                if (agendamento.horaInicio == null || agendamento.horaFim == null) {
                  return const SizedBox.shrink(); 
                }
                final double top = (agendamento.horaInicio!.hour - 8) * _horaHeight + (agendamento.horaInicio!.minute / 60.0) * _horaHeight;
                final double height = ((agendamento.horaFim!.hour * 60 + agendamento.horaFim!.minute) - (agendamento.horaInicio!.hour * 60 + agendamento.horaInicio!.minute)) / 60.0 * _horaHeight;
                final bool isRecorrente = agendamento.isRecorrente ?? false;

                return Positioned(
                  top: top,
                  left: 4,
                  right: 4,
                  height: height > 2 ? height - 2 : height,
                  child: InkWell(
                    onTap: () => _showEditDeleteOptions(
                      agendamento.id, 
                      agendamento.titulo,
                      agendamento.pacienteNome, 
                      agendamento.alunoNome,    
                    ),
                    child: Card(
                      color: isRecorrente ? Colors.blue[400] : Colors.red[400],
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          children: [
                            if (isRecorrente) const Icon(Icons.sync, color: Colors.white, size: 12),
                            if (isRecorrente) const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                agendamento.titulo ?? 'Ocupado', 
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), 
                                overflow: TextOverflow.fade, 
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          )
        ],
      ),
    );
  }
  // =============================================


  // ===== FUNÇÃO CORRIGIDA: _showCreateDialog =====
  // (Com showDatePicker correto)
  void _showCreateDialog({required Sala sala, required TimeOfDay horario}) {
    final titleController = TextEditingController();
    bool isRecorrente = false;
    DateTime? dataFimRecorrencia;
    String? _selectedPacienteId;
    PacienteDropdownModel? _selectedPacienteModel; 
    String? _selectedAlunoId;
    final Future<List<AlunoModel>> _alunosFuture = _fetchAlunosParaDropdown();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Novo Agendamento'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ... (Info Sala, Dia, Hora)
                       Text('Sala: ${sala.nome}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Dia: ${DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDay)}'),
                      Text('Horário: ${horario.format(context)}'),
                      const Divider(height: 24),
                      // Dropdown de Pacientes com Pesquisa (Correto)
                      DropdownSearch<PacienteDropdownModel>(
                        asyncItems: (String filter) => _fetchPacientesParaDropdown(filtroNome: filter), 
                        itemAsString: (PacienteDropdownModel p) => p.nomeCompleto,
                        onChanged: (PacienteDropdownModel? data) {
                          setDialogState(() {
                            _selectedPacienteModel = data; 
                            _selectedPacienteId = data?.id; 
                          });
                        },
                        popupProps: PopupProps.menu(
                          showSearchBox: true, 
                          searchFieldProps: const TextFieldProps(decoration: InputDecoration(labelText: "Pesquisar Paciente", prefixIcon: Icon(Icons.search), border: OutlineInputBorder())),
                          itemBuilder: (context, paciente, isSelected) => ListTile(title: Text(paciente.nomeCompleto), selected: isSelected),
                          emptyBuilder: (context, searchEntry) => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Nenhum paciente encontrado."))),
                          loadingBuilder: (context, searchEntry) => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
                           errorBuilder: (context, searchEntry, exception) => Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Erro ao buscar pacientes: $exception", style: const TextStyle(color: Colors.red)))),
                           searchDelay: const Duration(milliseconds: 300), 
                        ),
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(labelText: "Paciente", hintText: "Selecione ou pesquise o paciente", border: OutlineInputBorder()),
                        ),
                        selectedItem: _selectedPacienteModel,
                        validator: (value) => value == null ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      // Dropdown de Alunos (Correto)
                      FutureBuilder<List<AlunoModel>>(
                        future: _alunosFuture,
                        builder: (context, snapshot) {
                           if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: LinearProgressIndicator());
                          }
                          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text('Erro: Nenhum aluno encontrado.', style: TextStyle(color: Colors.red));
                          }
                          final alunos = snapshot.data!;
                          return DropdownButtonFormField<String>(
                            value: _selectedAlunoId,
                            hint: const Text('Selecione o Aluno (Estagiário)'),
                            isExpanded: true,
                            items: alunos.map((aluno) {
                              return DropdownMenuItem(value: aluno.id, child: Text(aluno.nomeCompleto));
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() { _selectedAlunoId = value; });
                            },
                            validator: (value) => value == null ? 'Campo obrigatório' : null,
                            decoration: const InputDecoration(border: OutlineInputBorder()), 
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Resto do formulário (Título, Recorrente)
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Título/Notas (Opcional)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('Agendamento fixo (semanal)'),
                        value: isRecorrente,
                        onChanged: (value) {
                          setDialogState(() {
                            isRecorrente = value ?? false;
                            if (!isRecorrente) { dataFimRecorrencia = null; }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      // Seletor de Data Fim (com showDatePicker corrigido)
                      if (isRecorrente)
                        ListTile(
                          title: Text(dataFimRecorrencia == null ? 'Selecionar data de término' : 'Término em: ${DateFormat('dd/MM/yyyy').format(dataFimRecorrencia!)}'),
                          trailing: const Icon(Icons.calendar_today),
                          contentPadding: EdgeInsets.zero,
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context, // <-- Parâmetro obrigatório adicionado
                              initialDate: dataFimRecorrencia ?? DateTime.now().add(const Duration(days: 90)),
                              firstDate: _selectedDay, // <-- Parâmetro obrigatório adicionado
                              lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // <-- Parâmetro obrigatório adicionado
                            );
                            if (pickedDate != null) {
                              setDialogState(() => dataFimRecorrencia = pickedDate);
                            }
                          },
                        )
                    ],
                  ),
                ),
              ),
              // Botões de Ação (sem alterações)
              actions: [
                 TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: () {
                    if (_selectedPacienteId == null || _selectedAlunoId == null) {
                       _showSnackBar('Selecione um paciente e um aluno.', isError: true);
                       return;
                    }
                    if (isRecorrente && dataFimRecorrencia == null) {
                      _showSnackBar('Selecione uma data de término para o agendamento fixo.', isError: true);
                      return;
                    }
                    _criarAgendamento(
                      sala: sala,
                      horario: horario,
                      titulo: titleController.text,
                      isRecorrente: isRecorrente,
                      dataFimRecorrencia: dataFimRecorrencia,
                      pacienteId: _selectedPacienteId!,
                      alunoId: _selectedAlunoId!,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // ========================================================


  // Função _showEditDeleteOptions (usando BottomSheet e mostrando nomes - CORRETA)
  void _showEditDeleteOptions(String agendamentoId, String? titulo, String? pacienteNome, String? alunoNome) {
    // ... (código do BottomSheet completo e correto)
     final scaffoldContext = context; 
    showModalBottomSheet(
      context: scaffoldContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center( // Handle
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text('Opções de Agendamento', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Título: ${titulo ?? 'Não informado'}', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
              const SizedBox(height: 16), 
              ListTile( 
                leading: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                title: Text('Paciente: ${pacienteNome ?? 'Não informado'}'),
                dense: true, 
              ),
              ListTile(
                 leading: Icon(Icons.school_outlined, color: Theme.of(context).colorScheme.primary),
                 title: Text('Aluno: ${alunoNome ?? 'Não informado'}'),
                 dense: true,
              ),
              const Divider(height: 24),
              ListTile( // Excluir
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Excluir Agendamento', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop(); 
                  _excluirAgendamento(agendamentoId); 
                },
              ),
              ListTile( // Fechar
                leading: const Icon(Icons.close),
                title: const Text('Fechar'),
                onTap: () { Navigator.of(context).pop(); },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
} // Fim da classe _AgendamentoScreenState