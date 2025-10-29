// lib/features/agendamento/models/agendamento_model.dart

import 'package:flutter/material.dart';

class Agendamento {
  final String id;
  final String salaId;
  final DateTime? dataAgendamento;
  final TimeOfDay? horaInicio;
  final TimeOfDay? horaFim;
  final String? titulo;
  final bool? isRecorrente; // <-- Tornado nulável
  final DateTime? dataFimRecorrencia;
  final String? psicologoId;
  final String? pacienteId;
  final String? alunoId; 

  Agendamento({
    required this.id,
    required this.salaId,
    // ===== CORREÇÃO AQUI: Removido 'required' =====
    this.dataAgendamento,
    this.horaInicio,
    this.horaFim,
    this.titulo,
    this.isRecorrente, // <-- Removido 'required'
    // ===============================================
    this.dataFimRecorrencia,
    this.psicologoId,
    this.pacienteId,
    this.alunoId,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    
    TimeOfDay? _tryParseTime(String? timeStr) {
      if (timeStr == null || !timeStr.contains(':')) {
        return null;
      }
      try {
        final parts = timeStr.split(':');
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      } catch (e) {
        print("Erro ao parsear hora '$timeStr': $e");
      }
      return null;
    }

    DateTime? _tryParseDate(String? dateStr) {
       if (dateStr == null) return null;
       return DateTime.tryParse(dateStr);
    }

    return Agendamento(
      id: json['id']?.toString() ?? '', 
      salaId: json['sala_id']?.toString() ?? '', 
      
      dataAgendamento: _tryParseDate(json['data_agendamento'] as String?),
      horaInicio: _tryParseTime(json['hora_inicio'] as String?),
      horaFim: _tryParseTime(json['hora_fim'] as String?),
      
      titulo: json['titulo'] as String?,
      
      // ===== CORREÇÃO AQUI: Cast para bool? (nulável) =====
      isRecorrente: json['is_recorrente'] as bool?, 
      // ====================================================
      
      dataFimRecorrencia: _tryParseDate(json['data_fim_recorrencia'] as String?),
      psicologoId: json['psicologo_id'] as String?,
      pacienteId: json['paciente_id'] as String?,
      alunoId: json['aluno_id'] as String?,
    );
  }
}