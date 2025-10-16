
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

DateTime? parseBrDate(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  // Try ISO 8601 first
  try {
    return DateTime.parse(value);
  } catch (_) {}

  // Try Brazilian format dd/MM/yyyy or dd/MM/yyyy HH:mm:ss
  final parts = value.split(' ');
  final datePart = parts.first;
  final dateSegments = datePart.split('/');
  if (dateSegments.length == 3) {
    final day = int.tryParse(dateSegments[0]);
    final month = int.tryParse(dateSegments[1]);
    final year = int.tryParse(dateSegments[2]);
    if (day != null && month != null && year != null) {
      int hour = 0, minute = 0, second = 0;
      if (parts.length > 1) {
        final timeSegments = parts[1].split(':');
        hour = int.tryParse(timeSegments.elementAt(0)) ?? 0;
        minute = int.tryParse(timeSegments.elementAt(1)) ?? 0;
        second = int.tryParse(timeSegments.elementAt(2)) ?? 0;
      }
      return DateTime(year, month, day, hour, minute, second);
    }
  }

  return null;
}