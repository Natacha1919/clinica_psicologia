// lib/features/agendamento/models/agendamento_model.dart

import 'package:flutter/material.dart';

class Agendamento {
  final String id;
  final String salaId;
  final DateTime? dataAgendamento;
  final TimeOfDay? horaInicio;
  final TimeOfDay? horaFim;
  final String? titulo;
  final bool? isRecorrente; 
  final DateTime? dataFimRecorrencia;
  final String? psicologoId; // Você ainda usa este? Se não, pode remover.
  final String? pacienteId;
  final String? alunoId; 
  // ===== CAMPOS PARA NOMES =====
  final String? pacienteNome;
  final String? alunoNome;
  // =============================

  Agendamento({
    required this.id,
    required this.salaId,
    this.dataAgendamento, // Tornados opcionais no construtor devido ao parsing
    this.horaInicio,
    this.horaFim,
    this.titulo,
    this.isRecorrente, 
    this.dataFimRecorrencia,
    this.psicologoId,
    this.pacienteId,
    this.alunoId,
    // ===== NOVOS PARÂMETROS =====
    this.pacienteNome,
    this.alunoNome,
    // ============================
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    
    // Funções de parsing robustas (retornam null em caso de erro)
    TimeOfDay? _tryParseTime(String? timeStr) {
      if (timeStr == null || !timeStr.contains(':')) { return null; }
      try {
        final parts = timeStr.split(':');
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      } catch (e) { print("Erro ao parsear hora '$timeStr': $e"); }
      return null;
    }

    DateTime? _tryParseDate(String? dateStr) {
       if (dateStr == null) return null;
       return DateTime.tryParse(dateStr);
    }

    // Lê os objetos aninhados que vêm da consulta SELECT com JOIN/embedding
    final pacienteJson = json['pacientes'] as Map<String, dynamic>?; // Pode vir como 'pacientes'
    final alunoJson = json['alunos'] as Map<String, dynamic>?;       // Pode vir como 'alunos'

    return Agendamento(
      id: json['id']?.toString() ?? '', 
      salaId: json['sala_id']?.toString() ?? '', 
      dataAgendamento: _tryParseDate(json['data_agendamento'] as String?),
      horaInicio: _tryParseTime(json['hora_inicio'] as String?),
      horaFim: _tryParseTime(json['hora_fim'] as String?),
      titulo: json['titulo'] as String?,
      isRecorrente: json['is_recorrente'] as bool?, // Trata null de forma segura
      dataFimRecorrencia: _tryParseDate(json['data_fim_recorrencia'] as String?),
      psicologoId: json['psicologo_id'] as String?, 
      pacienteId: json['paciente_id'] as String?,
      alunoId: json['aluno_id'] as String?,

      // Extrai o 'nome_completo' dos objetos aninhados
      pacienteNome: pacienteJson?['nome_completo'] as String?,
      alunoNome: alunoJson?['nome_completo'] as String?,
    );
  }
}