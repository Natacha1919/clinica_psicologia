import 'package:clinica_psicologi/features/pacientes/models/paciente_detalhado_model.dart';

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
      dataDesligamento: parseBrDate(json['data_desligamento']?.toString()),
      dataInscricao: parseBrDate(json['data_inscricao']?.toString()),
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