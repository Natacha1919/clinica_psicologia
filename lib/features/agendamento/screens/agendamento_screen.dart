// lib/features/agendamento/screens/agendamento_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importante para 'pt_BR'
import 'package:table_calendar/table_calendar.dart';
import '../../../core/config/supabase_config.dart'; // Verifique se este caminho está correto
import '../models/agendamento_model.dart'; // Verifique se este caminho está correto
import '../models/sala_model.dart'; // Verifique se este caminho está correto

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
    // Inicializa a formatação de data para Português (Brasil)
    initializeDateFormatting('pt_BR');
    _fetchDataParaDia(_selectedDay);
  }

  Future<void> _fetchDataParaDia(DateTime dia) async {
    if (mounted) setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final salasResponse = await SupabaseConfig.client
          .from('salas')
          .select()
          .order('nome', ascending: true);

      // Formata a data para o padrão 'yyyy-MM-dd' que o Supabase/PostgreSQL espera
      final dataFormatada = DateFormat('yyyy-MM-dd').format(dia);

      final agendamentosResponse = await SupabaseConfig.client.rpc(
        'get_agendamentos_para_dia',
        params: {'p_target_date': dataFormatada},
      );

      // Conversão segura dos dados
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

  Future<void> _criarAgendamento({
    required Sala sala,
    required TimeOfDay horario,
    required String titulo,
    required bool isRecorrente,
    DateTime? dataFimRecorrencia,
  }) async {
    final horaInicio = '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}:00';
    // Assume que o agendamento dura 1 hora.
    final horaFim = '${(horario.hour + 1).toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}:00';
    final data = DateFormat('yyyy-MM-dd').format(_selectedDay);

    try {
      await SupabaseConfig.client.from('agendamentos').insert({
        'sala_id': sala.id,
        'data_agendamento': data,
        'hora_inicio': horaInicio,
        'hora_fim': horaFim,
        'titulo': titulo.isNotEmpty ? titulo : 'Ocupado',
        'is_recorrente': isRecorrente,
        'data_fim_recorrencia': isRecorrente ? DateFormat('yyyy-MM-dd').format(dataFimRecorrencia!) : null,
      });
      _showSnackBar('Agendamento confirmado com sucesso!');
      await _fetchDataParaDia(_selectedDay);
    } catch (e) {
      _showSnackBar('Erro ao criar agendamento: $e', isError: true);
    }
  }

  // A função _editarAgendamento foi removida pois não será mais usada.

  Future<void> _excluirAgendamento(String agendamentoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Você tem certeza que deseja excluir este agendamento? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
          ),
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    // MODERNO: Pegamos o tema aqui para usar nas personalizações
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Um fundo cinza claro, bom para web
      appBar: AppBar(
        title: const Text('Agendamento de Salas'),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          _buildCalendar(theme), // Passa o tema para o calendário
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : RefreshIndicator(
                        onRefresh: () => _fetchDataParaDia(_selectedDay),
                        child: _buildTimetable(theme), // Passa o tema para a agenda
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(12.0),
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
          // MODERNO: Usa as cores do tema da aplicação
          selectedDecoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
          selectedTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
          todayDecoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.5), shape: BoxShape.circle),
          todayTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
        ),
      ),
    );
  }

  Widget _buildTimetable(ThemeData theme) {
    final horas = List.generate(15, (i) => 8 + i); // Das 8:00 às 22:00

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeAxis(horas),
            Row(
              children: _salas.map((sala) => _buildRoomColumn(sala, horas, theme)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeAxis(List<int> horas) {
    return Container(
      padding: const EdgeInsets.only(top: 40), // Espaço para o cabeçalho da sala
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

  Widget _buildRoomColumn(Sala sala, List<int> horas, ThemeData theme) {
    final agendamentosDaSala = _agendamentosDoDia.where((a) => a.salaId == sala.id).toList();

    return Container(
      width: _roomWidth,
      decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.shade200))),
      child: Column(
        children: [
          // Cabeçalho com o nome da sala
          Container(
            height: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(sala.nome, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          ),
          // Slots de horário
          Stack(
            children: [
              // Slots vazios com botões de adicionar
              Column(
                children: horas.map((hora) {
                  final slotTime = TimeOfDay(hour: hora, minute: 0);
                  final agendamentoNesteSlot = agendamentosDaSala.any((ag) => (hora >= ag.horaInicio.hour && hora < ag.horaFim.hour));
                  
                  return Container(
                    height: _horaHeight,
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
                    child: Center(
                      child: agendamentoNesteSlot ? null : IconButton( // Só mostra o '+' se o slot estiver livre
                        icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary.withOpacity(0.5), size: 20),
                        onPressed: () => _showCreateDialog(sala: sala, horario: slotTime, theme: theme),
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Cartões de agendamento (sobrepostos)
              ...agendamentosDaSala.map((agendamento) {
                final double top = (agendamento.horaInicio.hour - 8) * _horaHeight + (agendamento.horaInicio.minute / 60.0) * _horaHeight;
                final double height = ((agendamento.horaFim.hour * 60 + agendamento.horaFim.minute) - (agendamento.horaInicio.hour * 60 + agendamento.horaInicio.minute)) / 60.0 * _horaHeight;

                // MODERNO: Define cores com base no tema
                final cardColor = agendamento.isRecorrente ? theme.colorScheme.primary : theme.colorScheme.secondaryContainer;
                final textColor = agendamento.isRecorrente ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondaryContainer;

                return Positioned(
                  top: top,
                  left: 4,
                  right: 4,
                  height: height > 2 ? height - 2 : height, // Pequeno respiro visual
                  child: InkWell(
                    onTap: () => _showEditDeleteDialog(agendamento),
                    child: Card(
                      color: cardColor, // Cor baseada no tema
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), // Cantos arredondados
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Row(
                          children: [
                            if (agendamento.isRecorrente)
                              Icon(Icons.sync, color: textColor, size: 12),
                            if (agendamento.isRecorrente) const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                agendamento.titulo ?? 'Ocupado',
                                style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis, // Melhor que 'fade'
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

  void _showCreateDialog({required Sala sala, required TimeOfDay horario, required ThemeData theme}) {
    final titleController = TextEditingController();
    bool isRecorrente = false;
    DateTime? dataFimRecorrencia;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Novo Agendamento'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sala: ${sala.nome}'),
                    Text('Dia: ${DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDay)}'),
                    Text('Horário: ${horario.format(context)}'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Título (Ex: Nome do Aluno)'),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Agendamento fixo (semanal)'),
                      value: isRecorrente,
                      onChanged: (value) {
                        setDialogState(() {
                          isRecorrente = value ?? false;
                          if (!isRecorrente) {
                            dataFimRecorrencia = null;
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: theme.colorScheme.primary, // MODERNO: Cor do tema
                    ),
                    if (isRecorrente)
                      ListTile(
                        title: Text(dataFimRecorrencia == null
                            ? 'Selecionar data de término'
                            : 'Término em: ${DateFormat('dd/MM/yyyy').format(dataFimRecorrencia!)}'),
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
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: () {
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

  // ✅ CORREÇÃO + PERSONALIZAÇÃO
  // Esta é a função que corrigimos e modernizamos.
  void _showEditDeleteDialog(Agendamento agendamento) {
    // Pegamos o tema para usar nos ícones
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Opções de Agendamento'),
          
          // MODERNO: Usamos uma Coluna com ListTiles para um visual limpo.
          // Isso resolve o bug de layout que você tinha (a caixa cinza).
          content: Column(
            mainAxisSize: MainAxisSize.min, // Garante que o diálogo seja "pequeno"
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(Icons.label_outline, color: theme.colorScheme.primary),
                title: Text(agendamento.titulo ?? 'Ocupado'),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: Icon(Icons.schedule_outlined, color: theme.colorScheme.primary),
                title: Text('Horário: ${agendamento.horaInicio.format(context)} - ${agendamento.horaFim.format(context)}'),
                contentPadding: EdgeInsets.zero,
              ),
              if (agendamento.isRecorrente)
                ListTile(
                  leading: Icon(Icons.sync, color: theme.colorScheme.primary),
                  title: const Text('Agendamento fixo (semanal)'),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),

          // Ações alinhadas com o objetivo de "excluir ou fechar"
          actions: [
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () {
          Navigator.of(context).pop();
          _excluirAgendamento(agendamento.id);
        },
        tooltip: 'Excluir Agendamento',
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Fechar'),
      ),
    ],
  )
],        );
      },
    );
  }
}