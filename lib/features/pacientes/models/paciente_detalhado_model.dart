// lib/features/pacientes/models/paciente_detalhado_model.dart

import 'package:flutter/foundation.dart';

DateTime? parseBrDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return null;
  try {
    // Tenta diferentes formatos, incluindo o padrão ISO que o Supabase pode retornar
    if (dateString.contains('-') && dateString.length > 10) {
      return DateTime.tryParse(dateString);
    }
    final parts = dateString.split('/');
    if (parts.length == 3) {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    }
  } catch (e) {
    if (kDebugMode) {
      print('Erro ao converter data: $dateString');
    }
  }
  return null;
}

// --- Modelo Detalhado para a tela de detalhes e edição ---
class PacienteDetalhado {
  final String id;
  final String inscritoId;
  final String nomeCompleto;
  final String? cpf;
  final String? statusDetalhado;
  final DateTime? dataDesligamento;
  final String? email;
  final String? telefone;
  final String? endereco;
  final DateTime? dataNascimento;
  final String? idade;
  final String? sexo;
  final String? genero;
  final String? raca;
  final String? religiao;
  final String? estadoCivil;
  final String? escolaridade;
  final String? profissao;
  final String? demandaInicial;
  final String? nDeInscricao;

  bool get isAtivo => dataDesligamento == null;

  PacienteDetalhado({
    required this.id,
    required this.inscritoId,
    required this.nomeCompleto,
    this.cpf,
    this.statusDetalhado,
    this.dataDesligamento,
    this.email,
    this.telefone,
    this.endereco,
    this.dataNascimento,
    this.idade,
    this.sexo,
    this.genero,
    this.raca,
    this.religiao,
    this.estadoCivil,
    this.escolaridade,
    this.profissao,
    this.demandaInicial,
    this.nDeInscricao,
  });

  factory PacienteDetalhado.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) {
      throw ArgumentError("O ID do paciente não pode ser nulo.");
    }
    return PacienteDetalhado(
      id: json['id'] as String,
      inscritoId: json['inscrito_id'] as String? ?? '',
      nomeCompleto: json['nome_completo'] as String? ?? 'Nome não informado',
      cpf: json['cpf'] as String?,
      statusDetalhado: json['status_detalhado'] as String?,
      dataDesligamento: parseBrDate(json['data_desligamento']?.toString()),
      email: json['email'] as String?, // Assumindo que pode existir uma coluna email
      telefone: json['contato'] as String?,
      endereco: json['endereco'] as String?,
      dataNascimento: parseBrDate(json['data_nascimento']?.toString()),
      idade: json['idade'] as String?,
      sexo: json['sexo'] as String?,
      genero: json['genero'] as String?,
      raca: json['raca'] as String?,
      religiao: json['religiao'] as String?,
      estadoCivil: json['estado_civil'] as String?,
      escolaridade: json['escolaridade'] as String?,
      profissao: json['profissao'] as String?,
      demandaInicial: json['demanda_inicial'] as String?,
      nDeInscricao: json['n_de_inscrição'] as String?,
    );
  }

  String get iniciais {
    if (nomeCompleto.isEmpty) return '?';
    final parts = nomeCompleto.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length > 1) {
      return (parts.first[0] + parts.last[0]).toUpperCase();
    } else if (parts.isNotEmpty && parts.first.length >= 2) {
      return parts.first.substring(0, 2).toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return '?';
  }
}