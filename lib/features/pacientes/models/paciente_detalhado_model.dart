// lib/features/pacientes/models/paciente_detalhado_model.dart
import 'package:flutter/foundation.dart';

DateTime? parseDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return null;
  DateTime? parsedDate = DateTime.tryParse(dateString);
  if (parsedDate != null) return parsedDate;
  try {
    final parts = dateString.split('/');
    if (parts.length == 3) {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    }
  } catch (e) {
    if (kDebugMode) print('Erro ao converter data no formato brasileiro: $dateString');
  }
  return null;
}

class PacienteDetalhado {
  final String id;
  final String? inscritoId;
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
  final String? tipoAtendimento; // Escolha do Paciente
  final String? classificacaoPreceptor; // ESCOLHA DO PRECEPTOR
  final String? nDeInscricao;
  final String? historicoSaudeMental;
  final String? usoMedicacao;
  final String? queixaTriagem;
  final String? tratamentoSaude;
  final String? rotinaPaciente;
  final String? triagemRealizadaPor;
  final String? diaAtendimentoDefinido;
  final String? escolaridadePai;
  final String? profissaoPai;
  final String? escolaridadeMae;
  final String? profissaoMae;
  final String? prioridadeAtendimento;

  bool get isAtivo => dataDesligamento == null;

  PacienteDetalhado({
    required this.id,
    this.inscritoId,
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
    this.tipoAtendimento,
    this.classificacaoPreceptor, // CORRIGIDO
    this.nDeInscricao,
    this.historicoSaudeMental,
    this.usoMedicacao,
    this.queixaTriagem,
    this.tratamentoSaude,
    this.rotinaPaciente,
    this.triagemRealizadaPor,
    this.diaAtendimentoDefinido,
    this.escolaridadePai,
    this.profissaoPai,
    this.escolaridadeMae,
    this.profissaoMae,
    this.prioridadeAtendimento,
  });

  factory PacienteDetalhado.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) {
      throw ArgumentError("O ID do paciente não pode ser nulo.");
    }
    return PacienteDetalhado(
      id: json['id'] as String,
      inscritoId: json['inscrito_id'] as String?,
      nomeCompleto: json['nome_completo'] as String? ?? 'Nome não informado',
      cpf: json['cpf'] as String?,
      statusDetalhado: json['status_detalhado'] as String?,
      dataDesligamento: parseDate(json['data_desligamento'] as String?),
      email: json['email'] as String?,
      telefone: json['contato'] as String?,
      endereco: json['endereco'] as String?,
      dataNascimento: parseDate(json['data_nascimento'] as String?),
      idade: json['idade'] as String?,
      sexo: json['sexo'] as String?,
      genero: json['genero'] as String?,
      raca: json['raca'] as String?,
      religiao: json['religiao'] as String?,
      estadoCivil: json['estado_civil'] as String?,
      escolaridade: json['escolaridade'] as String?,
      profissao: json['profissao'] as String?,
      tipoAtendimento: json['tipo_atendimento'] as String?,
      classificacaoPreceptor: json['classificacao_preceptor'] as String?, // CORRIGIDO
      nDeInscricao: json['n_de_inscrição'] as String?,
      historicoSaudeMental: json['historico_saude_mental'] as String?,
      usoMedicacao: json['uso_medicacao'] as String?,
      queixaTriagem: json['queixa_triagem'] as String?,
      tratamentoSaude: json['tratamento_saude'] as String?,
      rotinaPaciente: json['rotina_paciente'] as String?,
      triagemRealizadaPor: json['triagem_realizada_por'] as String?,
      diaAtendimentoDefinido: json['dia_atendimento_definido'] as String?,
      escolaridadePai: json['escolaridade_pai'] as String?,
      profissaoPai: json['profissao_pai'] as String?,
      escolaridadeMae: json['escolaridade_mae'] as String?,
      profissaoMae: json['profissao_mae'] as String?,
      prioridadeAtendimento: json['prioridade_atendimento'] as String?,
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

class PacienteHistorico {
  final String id;
  final String nomeCompleto;
  final String? cpf;
  final String? statusDetalhado;
  final DateTime? dataDesligamento;
  final DateTime? dataInscricao;
  final String? nDeInscricao;

  bool get isAtivo => dataDesligamento == null;

  PacienteHistorico({
    required this.id,
    required this.nomeCompleto,
    this.cpf,
    this.statusDetalhado,
    this.dataDesligamento,
    this.dataInscricao,
    this.nDeInscricao,
  });

  factory PacienteHistorico.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) {
      throw ArgumentError("O ID do paciente não pode ser nulo.");
    }
    return PacienteHistorico(
      id: json['id'] as String,
      nomeCompleto: json['nome_completo'] as String? ?? 'Nome não informado',
      cpf: json['cpf'] as String?,
      statusDetalhado: json['status_detalhado'] as String?,
      dataDesligamento: parseDate(json['data_desligamento'] as String?),
      dataInscricao: parseDate(json['data_inscricao'] as String?),
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