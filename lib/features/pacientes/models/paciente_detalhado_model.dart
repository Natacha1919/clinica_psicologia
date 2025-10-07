// lib/features/pacientes/models/paciente_detalhado_model.dart

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


class PacienteDetalhado {
  final String id;
  final String inscritoId;
  final String nomeCompleto;
  final String? cpf;
  final String status;
  final String? email;
  final String? telefone;
  final String? endereco;
  final DateTime? dataNascimento;
  final String? idade;
  // --- CAMPOS ADICIONADOS ---
  final String? sexo;
  final String? genero;
  final String? raca;
  final String? religiao;
  final String? estadoCivil;
  final String? escolaridade;
  final String? profissao;
  final String? demandaInicial;


  PacienteDetalhado({
    required this.id,
    required this.inscritoId,
    required this.nomeCompleto,
    this.cpf,
    required this.status,
    this.email,
    this.telefone,
    this.endereco,
    this.dataNascimento,
    this.idade,
    // --- CAMPOS ADICIONADOS ---
    this.sexo,
    this.genero,
    this.raca,
    this.religiao,
    this.estadoCivil,
    this.escolaridade,
    this.profissao,
    this.demandaInicial,
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
      status: json['status'] as String? ?? 'Status desconhecido',
      email: json['email_secundario'] as String?,
      telefone: json['contato'] as String?,
      endereco: json['endereco'] as String?,
      dataNascimento: parseBrDate(json['data_nascimento']?.toString()),
      idade: json['idade'] as String?,
      // --- MAPEAMENTO DOS NOVOS CAMPOS ---
      sexo: json['sexo'] as String?,
      genero: json['genero'] as String?,
      raca: json['raca'] as String?,
      religiao: json['religiao'] as String?,
      estadoCivil: json['estado_civil'] as String?,
      escolaridade: json['escolaridade'] as String?,
      profissao: json['profissao'] as String?,
      demandaInicial: json['demanda_inicial'] as String?,
    );
  }

  String get iniciais {
    if (nomeCompleto.isEmpty) return '?';
    final parts = nomeCompleto.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length > 1) {
      return (parts.first[0] + parts.last[0]).toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts.first.substring(0, 2).toUpperCase();
    }
    return '?';
  }
}