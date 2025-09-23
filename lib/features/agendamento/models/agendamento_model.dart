// lib/features/agendamento/models/agendamento_model.dart

import 'package:flutter/material.dart';

class Agendamento {
  final String id;
  final String salaId;
  final DateTime dataAgendamento;
  final TimeOfDay horaInicio;
  final TimeOfDay horaFim;
  final String? titulo;

  Agendamento({
    required this.id,
    required this.salaId,
    required this.dataAgendamento,
    required this.horaInicio,
    required this.horaFim,
    this.titulo,
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
      // ALTERADO: Usamos .toString() para os IDs
      id: json['id'].toString(),
      salaId: json['sala_id'].toString(),
      dataAgendamento: DateTime.parse(json['data_agendamento'] as String),
      horaInicio: _parseTime(json['hora_inicio'] as String),
      horaFim: _parseTime(json['hora_fim'] as String),
      titulo: json['titulo'] as String?,
    );
  }
}