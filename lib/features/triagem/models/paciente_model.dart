// lib/features/triagem/models/paciente_model.dart

class Paciente {
  final String id;
  final DateTime createdAt;
  final String? categoria;
  final DateTime? dataHoraEnvio;
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
  final String? tipoAtendimento; // NOME CORRETO
  
  // Campos da triagem
  final String? historicoSaudeMental;
  final String? usoMedicacao;
  final String? queixaTriagem;
  final String? tratamentoSaude;
  final String? rotinaPaciente;
  final String? triagemRealizadaPor;
  final String? diaAtendimentoDefinido;
  final String? sexo;
  final String? raca;
  final String? escolaridade;
  final String? profissao;
  final String? escolaridadePai;
  final String? profissaoPai;
  final String? escolaridadeMae;
  final String? profissaoMae;
  final String? prioridadeAtendimento;

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
    this.tipoAtendimento, // NOME CORRETO
    this.historicoSaudeMental,
    this.usoMedicacao,
    this.queixaTriagem,
    this.tratamentoSaude,
    this.rotinaPaciente,
    this.triagemRealizadaPor,
    this.diaAtendimentoDefinido,
    this.sexo,
    this.raca,
    this.escolaridade,
    this.profissao,
    this.escolaridadePai,
    this.profissaoPai,
    this.escolaridadeMae,
    this.profissaoMae,
    this.prioridadeAtendimento,
  });

  factory Paciente.fromJson(Map<String, dynamic> json) {
    String? _safeGetString(dynamic value) => value?.toString();
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
      tipoAtendimento: _safeGetString(json['tipo_atendimento']), // CORRIGIDO
      historicoSaudeMental: _safeGetString(json['historico_saude_mental']),
      usoMedicacao: _safeGetString(json['uso_medicacao']),
      queixaTriagem: _safeGetString(json['queixa_triagem']),
      tratamentoSaude: _safeGetString(json['tratamento_saude']),
      rotinaPaciente: _safeGetString(json['rotina_paciente']),
      triagemRealizadaPor: _safeGetString(json['triagem_realizada_por']),
      diaAtendimentoDefinido: _safeGetString(json['dia_atendimento_definido']),
      sexo: _safeGetString(json['sexo']),
      raca: _safeGetString(json['raca']),
      escolaridade: _safeGetString(json['escolaridade']),
      profissao: _safeGetString(json['profissao']),
      escolaridadePai: _safeGetString(json['escolaridade_pai']),
      profissaoPai: _safeGetString(json['profissao_pai']),
      escolaridadeMae: _safeGetString(json['escolaridade_mae']),
      profissaoMae: _safeGetString(json['profissao_mae']),
      prioridadeAtendimento: _safeGetString(json['prioridade_atendimento']),
      
    );
  }
}