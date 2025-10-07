// lib/features/pacientes/models/prontuario_model.dart

// Helper para converter datas no formato DD/MM/YYYY de forma segura
DateTime? parseBrDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return null;
  try {
    final parts = dateString.split('/');
    if (parts.length == 3) {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    }
  } catch (e) {
    print('Erro ao converter data: $dateString');
  }
  return null;
}

class PacienteHistorico {
  final String id;
  final String inscritoId;
  final String nomeCompleto;
  final String? cpf;
  final String status;
  final DateTime? dataInscricao;
  final String? nDeInscricao; // ADICIONADO

  PacienteHistorico({
    required this.id,
    required this.inscritoId,
    required this.nomeCompleto,
    this.cpf,
    required this.status,
    this.dataInscricao,
    this.nDeInscricao, // ADICIONADO
  });

  factory PacienteHistorico.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) {
      throw ArgumentError("O ID do paciente não pode ser nulo. Verifique os dados no Supabase.");
    }

    return PacienteHistorico(
      id: json['id'] as String,
      inscritoId: json['inscrito_id']?.toString() ?? '',
      nomeCompleto: json['nome_completo']?.toString() ?? 'Nome não informado',
      cpf: json['cpf']?.toString(),
      status: json['status']?.toString() ?? 'Status desconhecido',
      dataInscricao: parseBrDate(json['data_inscricao']?.toString()),
      nDeInscricao: json['n_de_inscrição'] as String?, // ADICIONADO
    );
  }

  // ADICIONADO: Helper para pegar as iniciais do nome, necessário para o novo design
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