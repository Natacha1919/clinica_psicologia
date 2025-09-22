class Paciente {
  final String id;
  final DateTime createdAt;
  final String? categoria;
  final DateTime? dataHoraEnvio; // Aqui só a data
  final String? telefone;
  final DateTime? dataNascimento;
  final String? idadeTexto;
  final String nomeCompleto;
  final String? termoConsentimento;
  final String? nomeSocial;
  final String? cpf;
  final String? nomePai;
  final String? nomeMae;
  final String? estadoCivil;
  final String? religiao;
  final String? endereco;
  final String? encaminhamento;
  final String? vinculoUnifecafStatus;
  final String? vinculoUnifecafDetalhe;
  final String? email;
  final String? rendaMensal;
  final String? emailSecundario;
  final String? modalidadePreferencial;
  final String? diasPreferenciais;
  final String? horariosPreferenciais;
  final String? poloEad;

  Paciente({
    required this.id,
    required this.createdAt,
    this.categoria,
    this.dataHoraEnvio,
    this.telefone,
    this.dataNascimento,
    this.idadeTexto,
    required this.nomeCompleto,
    this.termoConsentimento,
    this.nomeSocial,
    this.cpf,
    this.nomePai,
    this.nomeMae,
    this.estadoCivil,
    this.religiao,
    this.endereco,
    this.encaminhamento,
    this.vinculoUnifecafStatus,
    this.vinculoUnifecafDetalhe,
    this.email,
    this.rendaMensal,
    this.emailSecundario,
    this.modalidadePreferencial,
    this.diasPreferenciais,
    this.horariosPreferenciais,
    this.poloEad,
  });

  factory Paciente.fromJson(Map<String, dynamic> json) {
    String? _safeGetString(dynamic value) => value?.toString();

    // Converte string para DateTime (somente data)
    DateTime? _parseDate(String? dateString) {
      if (dateString == null) return null;
      try {
        return DateTime.parse(dateString);
      } catch (_) {
        return null;
      }
    }

    String? categoriaFinal;
    final dynamic categoriaData = json['categoria'];
    if (categoriaData != null && categoriaData is Map) {
      categoriaFinal = categoriaData['nome'] as String?;
    } else if (categoriaData != null) {
      categoriaFinal = categoriaData.toString();
    }

    return Paciente(
      id: _safeGetString(json['id']) ?? 'id_invalido',
      createdAt: _parseDate(_safeGetString(json['created_at'])) ?? DateTime.now(),
      categoria: categoriaFinal ?? 'ESPERA',
      dataHoraEnvio: _parseDate(_safeGetString(json['data_hora_envio'])),
      telefone: _safeGetString(json['telefone']),
      dataNascimento: _parseDate(_safeGetString(json['data_nascimento'])),
      idadeTexto: _safeGetString(json['idade_texto']),
      nomeCompleto: _safeGetString(json['nome_completo']) ?? 'Nome não informado',
      termoConsentimento: _safeGetString(json['termo_consentimento']),
      nomeSocial: _safeGetString(json['nome_social']),
      cpf: _safeGetString(json['cpf']),
      nomePai: _safeGetString(json['nome_pai']),
      nomeMae: _safeGetString(json['nome_mae']),
      estadoCivil: _safeGetString(json['estado_civil']),
      religiao: _safeGetString(json['religiao']),
      endereco: _safeGetString(json['endereco']),
      encaminhamento: _safeGetString(json['encaminhamento']),
      vinculoUnifecafStatus: _safeGetString(json['vinculo_unifecaf_status']),
      vinculoUnifecafDetalhe: _safeGetString(json['vinculo_unifecaf_detalhe']),
      email: _safeGetString(json['email']),
      rendaMensal: _safeGetString(json['renda_mensal']),
      emailSecundario: _safeGetString(json['email_secundario']),
      modalidadePreferencial: _safeGetString(json['modalidade_preferencial']),
      diasPreferenciais: _safeGetString(json['dias_preferenciais']),
      horariosPreferenciais: _safeGetString(json['horarios_preferenciais']),
      poloEad: _safeGetString(json['polo_ead']),
    );
  }
}
