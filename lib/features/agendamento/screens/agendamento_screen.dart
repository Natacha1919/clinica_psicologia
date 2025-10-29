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

  // ===== ⭐ MUDANÇA 1: SUBSTITUIR RPC POR SELECT ⭐ =====
  Future<void> _fetchDataParaDia(DateTime dia) async {
    if (mounted) setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final salasResponse = await SupabaseConfig.client
          .from('salas')
          .select()
          .order('nome', ascending: true);

      // --- ABANDONAMOS O RPC 'get_agendamentos_para_dia' ---
      // Esta consulta 'select' é mais simples e busca *todos* os campos
      // da tabela 'agendamentos', incluindo os novos.
      final agendamentosResponse = await SupabaseConfig.client
          .from('agendamentos')
          .select('*') // Busca todas as colunas
          .eq('data_agendamento', DateFormat('yyyy-MM-dd').format(dia)); // Para o dia selecionado

      // O resto da lógica continua igual
      final List<Map<String, dynamic>> salasData = List<Map<String, dynamic>>.from(salasResponse as List);
      final List<Map<String, dynamic>> agendamentosData = List<Map<String, dynamic>>.from(agendamentosResponse as List);

      if (mounted) {
        setState(() {
          _salas = salasData.map((json) => Sala.fromJson(json)).toList();
          // O Agendamento.fromJson (que corrigimos) agora receberá TODOS os campos
          _agendamentosDoDia = agendamentosData.map((json) => Agendamento.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Falha ao carregar dados: ${e.toString()}', isError: true);
      if (mounted) setState(() { _isLoading = false; _errorMessage = e.toString(); });
    }
  }
  // =======================================================

  Future<List<PacienteDropdownModel>> _fetchPacientesParaDropdown({String? filtroNome}) async {
    // ... (sem alterações)
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
          .filter('status_detalhado', 'in', '(${statusAtivos.map((s) => '"$s"').join(',')})');

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

  Future<List<AlunoModel>> _fetchAlunosParaDropdown() async {
    // ... (sem alterações)
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

  Future<void> _criarAgendamento({
    required Sala sala,
    required TimeOfDay horario,
    required String titulo,
    required bool isRecorrente,
    DateTime? dataFimRecorrencia,
    required String pacienteId,
    required String alunoId,
  }) async {
    // ... (sem alterações)
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

  Future<void> _excluirAgendamento(String agendamentoId) async {
    // ... (sem alterações)
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

  void _showSnackBar(String message, {bool isError = false}) {
    // ... (sem alterações)
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (sem alterações)
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

  Widget _buildCalendar() {
    // ... (sem alterações)
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

  Widget _buildTimetable() {
    // ... (sem alterações)
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

  Widget _buildTimeAxis(List<int> horas) {
    // ... (sem alterações)
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

  // ===== ⭐ MUDANÇA 2: Tornar o _buildRoomColumn Nulo-Seguro ⭐ =====
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
                  
                  // Adicionamos verificação de nulidade aqui
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
                // Se hora for null (devido ao parsing robusto), não desenha o card
                if (agendamento.horaInicio == null || agendamento.horaFim == null) {
                  return const SizedBox.shrink(); // Retorna um widget vazio
                }

                final double top = (agendamento.horaInicio!.hour - 8) * _horaHeight + (agendamento.horaInicio!.minute / 60.0) * _horaHeight;
                final double height = ((agendamento.horaFim!.hour * 60 + agendamento.horaFim!.minute) - (agendamento.horaInicio!.hour * 60 + agendamento.horaInicio!.minute)) / 60.0 * _horaHeight;

                // Adicionamos '?? false' para segurança
                final bool isRecorrente = agendamento.isRecorrente ?? false;

                return Positioned(
                  top: top,
                  left: 4,
                  right: 4,
                  height: height > 2 ? height - 2 : height,
                  child: InkWell(
                    // O objeto 'agendamento' agora está completo e seguro para ser passado
                    onTap: () => _showEditDeleteDialog(agendamento), 
                    child: Card(
                      color: isRecorrente ? Colors.blue[400] : Colors.red[400],
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          children: [
                            if (isRecorrente)
                              const Icon(Icons.sync, color: Colors.white, size: 12),
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
  // =======================================================


  /// DIÁLOGO DE CRIAR AGENDAMENTO (COM DROPDOWN DE PESQUISA)
  void _showCreateDialog({required Sala sala, required TimeOfDay horario}) {
    // ... (sem alterações)
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

  /// DIÁLOGO DE OPÇÕES DE AGENDAMENTO (Corrigido para o deploy)
  void _showEditDeleteDialog(Agendamento agendamento) {
    // ... (sem alterações, agora deve funcionar)
    showDialog(
      context: context,
      builder: (context) {
         return AlertDialog(
          title: const Text('Opções de Agendamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text("Título: ${agendamento.titulo ?? 'Não informado'}", 
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
                _excluirAgendamento(agendamento.id); 
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