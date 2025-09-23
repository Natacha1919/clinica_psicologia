// lib/features/agendamento/screens/agendamento_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/config/supabase_config.dart';
import '../models/agendamento_model.dart';
import '../models/sala_model.dart';

class AgendamentoScreen extends StatefulWidget {
  const AgendamentoScreen({Key? key}) : super(key: key);

  @override
  State<AgendamentoScreen> createState() => _AgendamentoScreenState();
}

class _AgendamentoScreenState extends State<AgendamentoScreen> {
  // Cores e Variáveis de Estado
  final Color _primaryDark = const Color(0xFF122640);
  final Color _accentGreen = const Color(0xFF36D97D);

  bool _isLoadingSalas = true;
  List<Sala> _salas = [];
  Sala? _salaSelecionada;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  final ValueNotifier<List<Agendamento>> _agendamentosDoMes = ValueNotifier([]);
  bool _isModoAgendamento = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchSalas();
  }

  @override
  void dispose() {
    _agendamentosDoMes.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : _accentGreen,
      ),
    );
  }

  // --- LÓGICA DE DADOS (CRUD) ---

  Future<void> _fetchSalas() async {
    try {
      final response = await SupabaseConfig.client.from('salas').select().order('nome', ascending: true);
      final dataList = List<Map<String, dynamic>>.from(response);
      if (mounted) {
        setState(() {
          _salas = dataList.map((json) => Sala.fromJson(json)).toList();
          if (_salas.isNotEmpty) {
            _salaSelecionada = _salas.first;
            _fetchAgendamentosDoMes(_focusedDay);
          }
          _isLoadingSalas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro ao buscar salas: $e', isError: true);
        setState(() => _isLoadingSalas = false);
      }
    }
  }

  Future<void> _fetchAgendamentosDoMes(DateTime month) async {
    if (_salaSelecionada == null) {
      _agendamentosDoMes.value = [];
      return;
    }
    final primeiroDia = DateTime(month.year, month.month, 1);
    final ultimoDia = DateTime(month.year, month.month + 1, 0);
    try {
      final response = await SupabaseConfig.client.from('agendamentos').select()
          .eq('sala_id', _salaSelecionada!.id)
          .gte('data_agendamento', DateFormat('yyyy-MM-dd').format(primeiroDia))
          .lte('data_agendamento', DateFormat('yyyy-MM-dd').format(ultimoDia));
      final dataList = List<Map<String, dynamic>>.from(response);
      _agendamentosDoMes.value = dataList.map((json) => Agendamento.fromJson(json)).toList();
    } catch (e) {
      _showSnackBar('Erro ao buscar agendamentos do mês: $e', isError: true);
    }
  }

  List<Agendamento> _getAgendamentosParaDia(DateTime day) {
    return _agendamentosDoMes.value.where((agendamento) => isSameDay(agendamento.dataAgendamento, day)).toList()
      ..sort((a,b) => (a.horaInicio.hour * 60 + a.horaInicio.minute).compareTo(b.horaInicio.hour * 60 + b.horaInicio.minute));
  }
  
  Future<void> _criarAgendamento(TimeOfDay horario, String titulo) async {
    if (_salaSelecionada == null || _selectedDay == null) return;
    final horaInicio = '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}:00';
    final horaFim = '${(horario.hour + 1).toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}:00';
    final data = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    try {
      await SupabaseConfig.client.from('agendamentos').insert({
        'sala_id': _salaSelecionada!.id, 'data_agendamento': data,
        'hora_inicio': horaInicio, 'hora_fim': horaFim,
        'titulo': titulo.isNotEmpty ? titulo : null,
      });
      _showSnackBar('Agendamento confirmado com sucesso!');
      await _fetchAgendamentosDoMes(_focusedDay);
      setState(() => _isModoAgendamento = false);
    } catch (e) {
      _showSnackBar('Erro ao criar agendamento: $e', isError: true);
    }
  }

  Future<void> _excluirAgendamento(String agendamentoId) async {
     final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Você tem certeza que deseja excluir este agendamento?'),
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
        await _fetchAgendamentosDoMes(_focusedDay);
      } catch (e) {
        _showSnackBar('Erro ao excluir agendamento: $e', isError: true);
      }
    }
  }

  Future<void> _editarAgendamento(Agendamento agendamento, String novoTitulo) async {
    try {
      await SupabaseConfig.client.from('agendamentos').update({'titulo': novoTitulo}).eq('id', agendamento.id);
      _showSnackBar('Agendamento atualizado com sucesso!');
      await _fetchAgendamentosDoMes(_focusedDay);
    } catch (e) {
      _showSnackBar('Erro ao editar agendamento: $e', isError: true);
    }
  }
  
  Future<void> _showConfirmationDialog({Agendamento? agendamentoExistente, TimeOfDay? novoHorario}) async {
    final isEditing = agendamentoExistente != null;
    final titleController = TextEditingController(text: isEditing ? agendamentoExistente.titulo : '');
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Agendamento' : 'Confirmar Agendamento', style: TextStyle(color: _primaryDark)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Sala: ${_salaSelecionada!.nome}'),
                Text('Dia: ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}'),
                Text('Horário: ${isEditing ? agendamentoExistente.horaInicio.format(context) : novoHorario!.format(context)}'),
                const SizedBox(height: 16),
                TextField(controller: titleController, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Título do Agendamento')),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _accentGreen),
              child: Text(isEditing ? 'Salvar' : 'Confirmar'),
              onPressed: () {
                if (isEditing) {
                  _editarAgendamento(agendamentoExistente, titleController.text);
                } else {
                  _criarAgendamento(novoHorario!, titleController.text);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- WIDGETS DE CONSTRUÇÃO DA UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Row(children: [Icon(Icons.calendar_month_outlined), SizedBox(width: 10), Text('Agendamento de Salas')]), backgroundColor: _primaryDark, foregroundColor: Colors.white, elevation: 2),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildRoomSelector(),
          const SizedBox(height: 24),
          _buildCalendar(),
          const Divider(height: 32),
          _buildDayDetails(),
        ],
      ),
    );
  }

  Widget _buildRoomSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Selecione a Sala', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryDark)),
            const SizedBox(height: 16),
            if (_isLoadingSalas) const Center(child: CircularProgressIndicator())
            else DropdownButtonFormField<Sala>(
              value: _salaSelecionada,
              isExpanded: true,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.grey.shade100, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              hint: const Text('Escolha uma sala'),
              items: _salas.map((sala) => DropdownMenuItem<Sala>(value: sala, child: Text(sala.nome))).toList(),
              onChanged: (salaSelecionada) {
                setState(() {
                  _salaSelecionada = salaSelecionada;
                  _isModoAgendamento = false;
                });
                _fetchAgendamentosDoMes(_focusedDay);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ValueListenableBuilder<List<Agendamento>>(
          valueListenable: _agendamentosDoMes,
          builder: (context, value, _) {
            return TableCalendar(
              locale: 'pt_BR',
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _isModoAgendamento = false;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                // A busca agora acontece apenas ao mudar de página
                _fetchAgendamentosDoMes(focusedDay);
              },
              eventLoader: _getAgendamentosParaDia,
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      left: 0,
                      right: 0,
                      bottom: 4,
                      child: Container(
                        height: 7,
                        width: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accentGreen,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(color: _primaryDark, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: _primaryDark.withOpacity(0.5), shape: BoxShape.circle),
                weekendTextStyle: const TextStyle(color: Colors.redAccent),
                cellMargin: const EdgeInsets.all(6.0),
              ),
              headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayDetails() {
    if (_salaSelecionada == null || _selectedDay == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const SizedBox(
          height: 100,
          child: Center(child: Text('Selecione uma sala e um dia para ver os detalhes.')),
        ),
      );
    }
    return _isModoAgendamento ? _buildTimeSlotsGrid() : _buildAppointmentList();
  }

  Widget _buildAppointmentList() {
    final agendamentosDoDia = _getAgendamentosParaDia(_selectedDay!);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Agendamentos do Dia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryDark)),
                FilledButton.icon(onPressed: () => setState(() => _isModoAgendamento = true), icon: const Icon(Icons.add, size: 18), label: const Text('Adicionar'), style: FilledButton.styleFrom(backgroundColor: _accentGreen))
              ],
            ),
            const Divider(height: 24),
            if (agendamentosDoDia.isEmpty)
              const Center(heightFactor: 3, child: Text('Nenhum agendamento para este dia.'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: agendamentosDoDia.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final agendamento = agendamentosDoDia[index];
                  return ListTile(
                    leading: Icon(Icons.access_time_filled_rounded, color: _primaryDark),
                    title: Text(agendamento.titulo ?? 'Sem título', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${agendamento.horaInicio.format(context)} - ${agendamento.horaFim.format(context)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey), onPressed: () => _showConfirmationDialog(agendamentoExistente: agendamento)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _excluirAgendamento(agendamento.id)),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  List<TimeOfDay> _gerarHorariosParaDia(DateTime dia) {
    List<TimeOfDay> horarios = [];
    if (dia.weekday == DateTime.sunday) {
    } else if (dia.weekday >= DateTime.monday && dia.weekday <= DateTime.friday) {
      for (int i = 8; i < 14; i++) { horarios.add(TimeOfDay(hour: i, minute: 0)); }
      for (int i = 16; i < 22; i++) { horarios.add(TimeOfDay(hour: i, minute: 0)); }
    } else if (dia.weekday == DateTime.saturday) {
      for (int i = 8; i < 16; i++) { horarios.add(TimeOfDay(hour: i, minute: 0)); }
    }
    return horarios;
  }
  
  bool _isHorarioOcupado(TimeOfDay horario) {
    double toDouble(TimeOfDay t) => t.hour + t.minute / 60.0;
    final horarioDouble = toDouble(horario);
    return _agendamentosDoMes.value.any((agendamento) {
      if (!isSameDay(agendamento.dataAgendamento, _selectedDay)) return false;
      final inicioDouble = toDouble(agendamento.horaInicio);
      final fimDouble = toDouble(agendamento.horaFim);
      return horarioDouble >= inicioDouble && horarioDouble < fimDouble;
    });
  }
  
  Widget _buildTimeSlotsGrid() {
    final horariosDoDia = _gerarHorariosParaDia(_selectedDay!);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Selecione um Horário Livre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryDark)),
                IconButton(onPressed: () => setState(() => _isModoAgendamento = false), icon: const Icon(Icons.close))
              ],
            ),
            const SizedBox(height: 16),
            if (horariosDoDia.isEmpty)
              const Center(child: Text('Não há horários disponíveis para este dia.'))
            else
              Wrap(
                spacing: 8.0, runSpacing: 8.0,
                children: horariosDoDia.map((horario) {
                  final isBooked = _isHorarioOcupado(horario);
                  return ActionChip(
                    label: Text(horario.format(context)),
                    backgroundColor: isBooked ? Colors.red.shade100 : Colors.green.shade100,
                    labelStyle: TextStyle(color: isBooked ? Colors.red.shade900 : Colors.green.shade900, fontWeight: FontWeight.bold),
                    side: BorderSide(color: isBooked ? Colors.red.shade200 : Colors.green.shade200),
                    onPressed: isBooked ? null : () => _showConfirmationDialog(novoHorario: horario),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}