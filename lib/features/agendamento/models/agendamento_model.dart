// lib/features/agendamento/models/agendamento_model.dart

import 'package:flutter/material.dart';

class Agendamento {
  final String id;
  final String salaId;
  final DateTime dataAgendamento;
  final TimeOfDay horaInicio;
  final TimeOfDay horaFim;
  final String? titulo;
  // NOVOS CAMPOS
  final bool isRecorrente;
  final DateTime? dataFimRecorrencia;
  final String? psicologoId;
  final String? pacienteId;

  Agendamento({
    required this.id,
    required this.salaId,
    required this.dataAgendamento,
    required this.horaInicio,
    required this.horaFim,
    this.titulo,
    // NOVOS CAMPOS
    required this.isRecorrente,
    this.dataFimRecorrencia,
    this.psicologoId,
    this.pacienteId,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    TimeOfDay _parseTime(String timeStr) {
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    return Agendamento(
      id: json['id'].toString(),
      salaId: json['sala_id'].toString(),
      dataAgendamento: DateTime.parse(json['data_agendamento'] as String),
      horaInicio: _parseTime(json['hora_inicio'] as String),
      horaFim: _parseTime(json['hora_fim'] as String),
      titulo: json['titulo'] as String?,
      // NOVOS CAMPOS
      isRecorrente: json['is_recorrente'] as bool,
      // O campo de data de fim pode ser nulo, então precisamos verificar
      dataFimRecorrencia: json['data_fim_recorrencia'] == null
          ? null
          : DateTime.parse(json['data_fim_recorrencia'] as String),
      psicologoId: json['psicologo_id'] as String?,
      pacienteId: json['paciente_id'] as String?,
    );
  }
}