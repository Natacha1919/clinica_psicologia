// lib/features/agendamento/screens/agendamento_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/config/supabase_config.dart';
import '../models/agendamento_model.dart';
import '../models/sala_model.dart';
import '../../pacientes/models/paciente_dropdown_model.dart';
import '../../alunos/models/aluno_model.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AgendamentoScreen extends StatefulWidget {
  const AgendamentoScreen({Key? key}) : super(key: key);

  @override
  State<AgendamentoScreen> createState() => _AgendamentoScreenState();
}

class _AgendamentoScreenState extends State<AgendamentoScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = true;
  String? _errorMessage;

  List<Sala> _salas = [];
  List<Agendamento> _agendamentosDoDia = [];

  final double _horaHeight = 60.0;
  final double _roomWidth = 150.0;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR');
    _fetchDataParaDia(_selectedDay);
  }

  // (Função _fetchDataParaDia - USA SELECT, está correta)
  Future<void> _fetchDataParaDia(DateTime dia) async {
    if (mounted) setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final salasResponse = await SupabaseConfig.client
          .from('salas')
          .select()
          .order('nome', ascending: true);

      final agendamentosResponse = await SupabaseConfig.client
          .from('agendamentos')
          .select('*') 
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

  // (Função _fetchPacientesParaDropdown - USA FILTRO .in_(), está correta)
  Future<List<PacienteDropdownModel>> _fetchPacientesParaDropdown({String? filtroNome}) async {
    try {
      final List<String> statusAtivos = [
        'PG - ATIVO',
        'BR - ATIVO',
        'ISENTO COLABORADOR',
        'ISENTO - ORIENTAÇÃO P.'
      ];
      
      var query = Supabase.instance.client
          .from('pacientes_historico_temp')
          .select('id, nome_completo')
          .filter('status_detalhado', 'in', statusAtivos);

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

  // (Função _fetchAlunosParaDropdown - está correta)
  Future<List<AlunoModel>> _fetchAlunosParaDropdown() async {
     try {
      final data = await Supabase.instance.client
          .from('alunos') 
          .select('id, nome_completo, ra')
          .order('nome_completo', ascending: true);
      final alunos = (data as List)
          .map((json) => AlunoModel.fromJson(json))
          .toList();
      return alunos;
    } catch (e) {
      _showSnackBar('Erro ao buscar alunos: $e', isError: true);
      return []; 
    }
  }

  // (Função _criarAgendamento - está correta)
  Future<void> _criarAgendamento({
    required Sala sala,
    required TimeOfDay horario,
    required String titulo,
    required bool isRecorrente,
    DateTime? dataFimRecorrencia,
    required String pacienteId,
    required String alunoId,
  }) async {
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

  // (Função _excluirAgendamento - está correta)
  Future<void> _excluirAgendamento(String agendamentoId) async {
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

  // (Função _showSnackBar - está correta)
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  // (Função build - está correta)
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
          _buildCalendar(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : RefreshIndicator(
                        onRefresh: () => _fetchDataParaDia(_selectedDay),
                        child: _buildTimetable(),
                      ),
          ),
        ],
      ),
    );
  }

  // (Função _buildCalendar - está correta)
  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: TableCalendar(
        locale: 'pt_BR',
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false),
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _fetchDataParaDia(selectedDay);
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
          todayDecoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.5), shape: BoxShape.circle),
        ),
      ),
    );
  }

  // (Função _buildTimetable - está correta)
  Widget _buildTimetable() {
    final horas = List.generate(15, (i) => 8 + i);
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeAxis(horas),
            Row(
              children: _salas.map((sala) => _buildRoomColumn(sala, horas)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // (Função _buildTimeAxis - está correta)
  Widget _buildTimeAxis(List<int> horas) {
    return Container(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: horas.map((hora) {
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

  // ===== ALTERAÇÃO 1: Na chamada 'onTap' =====
  Widget _buildRoomColumn(Sala sala, List<int> horas) {
    final agendamentosDaSala = _agendamentosDoDia.where((a) => a.salaId == sala.id).toList();

    return Container(
      width: _roomWidth,
      decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.shade200))),
      child: Column(
        children: [
          Container(
            height: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(sala.nome, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          ),
          Stack(
            children: [
              Column(
                children: horas.map((hora) {
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
                    
                    // ===== AQUI ESTÁ A MUDANÇA 1 =====
                    // Não passamos mais o objeto 'agendamento' inteiro.
                    // Passamos apenas os valores primitivos (Strings).
                    onTap: () => _showEditDeleteDialog(agendamento.id, agendamento.titulo),
                    // ===================================
                    
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


  // (Função _showCreateDialog - está correta, com pesquisa)
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
                      Text('Sala: ${sala.nome}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Dia: ${DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDay)}'),
                      Text('Horário: ${horario.format(context)}'),
                      const Divider(height: 24),
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
                          searchFieldProps: const TextFieldProps(
                            decoration: InputDecoration(labelText: "Pesquisar Paciente", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                          ),
                          itemBuilder: (context, paciente, isSelected) => ListTile(title: Text(paciente.nomeCompleto)),
                          emptyBuilder: (context, searchEntry) => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Nenhum paciente encontrado."))),
                          loadingBuilder: (context, searchEntry) => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
                          errorBuilder: (context, searchEntry, exception) => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Erro ao buscar pacientes.", style: TextStyle(color: Colors.red)))),
                        ),
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(labelText: "Paciente", hintText: "Selecione ou pesquise o paciente", border: OutlineInputBorder()),
                        ),
                        selectedItem: _selectedPacienteModel,
                        validator: (value) => value == null ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
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
                      if (isRecorrente)
                        ListTile(
                          title: Text(dataFimRecorrencia == null ? 'Selecionar data de término' : 'Término em: ${DateFormat('dd/MM/yyyy').format(dataFimRecorrencia!)}'),
                          trailing: const Icon(Icons.calendar_today),
                          contentPadding: EdgeInsets.zero,
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 90)),
                              firstDate: _selectedDay,
                              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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

  // ===== ALTERAÇÃO 2: Na assinatura da função =====
  void _showEditDeleteDialog(String agendamentoId, String? titulo) {
    showDialog(
      context: context,
      builder: (context) {
         return AlertDialog(
          title: const Text('Opções de Agendamento'),
          
          // ===== ALTERAÇÃO 3: Usando a variável 'titulo' =====
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text("Título: ${titulo ?? 'Não informado'}", 
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              // TODO: Mostrar paciente/aluno aqui
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                Navigator.of(context).pop(); 
                // Usando a variável 'agendamentoId'
                _excluirAgendamento(agendamentoId); 
              },
              tooltip: 'Excluir Agendamento',
            ),
            const Spacer(), 
            TextButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: const Text('Fechar')
            ),
          ],
        );
      },
    );
  }
}