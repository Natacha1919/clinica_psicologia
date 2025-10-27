// lib/features/triagem/screens/detalhes_paciente_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/config/supabase_config.dart';
import '../models/paciente_model.dart';
import '../models/status_paciente.dart';

const Color primary = Color.fromARGB(255, 10, 23, 36);
const Color accentGreen = Color(0xFF4CAF50);

class DetalhesPacienteScreen extends StatefulWidget {
  final String pacienteId;
  const DetalhesPacienteScreen({Key? key, required this.pacienteId}) : super(key: key);
  
  @override
  State<DetalhesPacienteScreen> createState() => _DetalhesPacienteScreenState();
}

class _DetalhesPacienteScreenState extends State<DetalhesPacienteScreen> {
  late Future<Paciente?> _futurePaciente;
  Paciente? _pacienteAtual;

  late StatusPaciente _statusAtual;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  // Controladores para todos os campos da triagem
  late TextEditingController _sexoController;
  late TextEditingController _racaController;
  late TextEditingController _escolaridadeController;
  late TextEditingController _profissaoController;
  late TextEditingController _escolaridadePaiController;
  late TextEditingController _profissaoPaiController;
  late TextEditingController _escolaridadeMaeController;
  late TextEditingController _profissaoMaeController;
  late TextEditingController _histSaudeMentalController;
  late TextEditingController _usoMedicacaoController;
  late TextEditingController _queixaTriagemController;
  late TextEditingController _tratamentoSaudeController;
  late TextEditingController _rotinaPacienteController;
  late TextEditingController _triagemRealizadaPorController;
  String? _diaAtendimentoSelecionado;
  final List<String> _diasSemana = ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado'];
  String? _prioridadeSelecionada;
  final List<String> _opcoesPrioridade = ['Urgente', 'Assim que possível', 'Posso esperar um pouco', 'Não tenho pressa'];

  @override
  void initState() {
    super.initState();
    _futurePaciente = _fetchPaciente();
  }

  @override
  void dispose() {
    if (_pacienteAtual != null) {
      _sexoController.dispose();
      _racaController.dispose();
      _escolaridadeController.dispose();
      _profissaoController.dispose();
      _escolaridadePaiController.dispose();
      _profissaoPaiController.dispose();
      _escolaridadeMaeController.dispose();
      _profissaoMaeController.dispose();
      _histSaudeMentalController.dispose();
      _usoMedicacaoController.dispose();
      _queixaTriagemController.dispose();
      _tratamentoSaudeController.dispose();
      _rotinaPacienteController.dispose();
      _triagemRealizadaPorController.dispose();
    }
    super.dispose();
  }

  Future<Paciente?> _fetchPaciente() async {
    try {
      const selectColumns =
          'id, created_at, categoria, data_hora_envio, telefone, data_nascimento, '
          'idade_texto, nome_completo, termo_consentimento, nome_social, cpf, '
          'nome_pai, nome_mae, estado_civil, religiao, endereco, encaminhamento, '
          'vinculo_unifecaf_status, vinculo_unifecaf_detalhe, email, renda_mensal, '
          'email_secundario, modalidade_preferencial, dias_preferenciais, '
          'horarios_preferenciais, polo_ead, tipo_atendimento, '
          'historico_saude_mental, uso_medicacao, queixa_triagem, tratamento_saude, '
          'rotina_paciente, triagem_realizada_por, dia_atendimento_definido, '
          'sexo, raca, escolaridade, profissao, escolaridade_pai, profissao_pai, '
          'escolaridade_mae, profissao_mae, prioridade_atendimento';
          
      final data = await SupabaseConfig.client
          .from('pacientes_inscritos')
          .select(selectColumns)
          .eq('id', widget.pacienteId)
          .single();

      final paciente = Paciente.fromJson(data);
      _initializeState(paciente);
      return paciente;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar paciente: $e'), backgroundColor: Colors.red));
      }
      return null;
    }
  }

  void _initializeState(Paciente paciente) {
    _pacienteAtual = paciente;
    _statusAtual = StatusPaciente.values.firstWhere(
      (e) => e.valor.toUpperCase() == paciente.categoria?.toUpperCase(),
      orElse: () => StatusPaciente.espera,
    );

    // Inicialização de todos os controladores
    _sexoController = TextEditingController(text: paciente.sexo);
    _racaController = TextEditingController(text: paciente.raca);
    _escolaridadeController = TextEditingController(text: paciente.escolaridade);
    _profissaoController = TextEditingController(text: paciente.profissao);
    _escolaridadePaiController = TextEditingController(text: paciente.escolaridadePai);
    _profissaoPaiController = TextEditingController(text: paciente.profissaoPai);
    _escolaridadeMaeController = TextEditingController(text: paciente.escolaridadeMae);
    _profissaoMaeController = TextEditingController(text: paciente.profissaoMae);
    _histSaudeMentalController = TextEditingController(text: paciente.historicoSaudeMental);
    _usoMedicacaoController = TextEditingController(text: paciente.usoMedicacao);
    _queixaTriagemController = TextEditingController(text: paciente.queixaTriagem);
    _tratamentoSaudeController = TextEditingController(text: paciente.tratamentoSaude);
    _rotinaPacienteController = TextEditingController(text: paciente.rotinaPaciente);
    _triagemRealizadaPorController = TextEditingController(text: paciente.triagemRealizadaPor);
    _diaAtendimentoSelecionado = paciente.diaAtendimentoDefinido;
    _prioridadeSelecionada = paciente.prioridadeAtendimento;
  }

  Future<void> _salvarAlteracoes() async {
    if (_statusAtual == StatusPaciente.triagemRealizada) {
      if (!_formKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, preencha os campos obrigatórios da triagem.'), backgroundColor: Colors.red));
        return;
      }
    }

    setState(() => _isSaving = true);
    
    try {
      final updates = {
        'categoria': _statusAtual.valor,
        'sexo': _sexoController.text,
        'raca': _racaController.text,
        'escolaridade': _escolaridadeController.text,
        'profissao': _profissaoController.text,
        'escolaridade_pai': _escolaridadePaiController.text,
        'profissao_pai': _profissaoPaiController.text,
        'escolaridade_mae': _escolaridadeMaeController.text,
        'profissao_mae': _profissaoMaeController.text,
        'historico_saude_mental': _histSaudeMentalController.text,
        'uso_medicacao': _usoMedicacaoController.text,
        'queixa_triagem': _queixaTriagemController.text,
        'tratamento_saude': _tratamentoSaudeController.text,
        'rotina_paciente': _rotinaPacienteController.text,
        'triagem_realizada_por': _triagemRealizadaPorController.text,
        'dia_atendimento_definido': _diaAtendimentoSelecionado,
        'prioridade_atendimento': _prioridadeSelecionada,
      };

      await SupabaseConfig.client
          .from('pacientes_inscritos')
          .update(updates)
          .eq('id', widget.pacienteId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informações salvas com sucesso!'), backgroundColor: accentGreen));
        setState(() {
          _futurePaciente = _fetchPaciente();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _generatePdf() async {
    // ... (Lógica para gerar PDF, se necessário)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Detalhes do Paciente'),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Gerar PDF',
            onPressed: _generatePdf,
          ),
        ],
      ),
      body: FutureBuilder<Paciente?>(
        future: _futurePaciente,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _pacienteAtual == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Não foi possível carregar os dados do paciente.'));
          }

          final paciente = _pacienteAtual!;
          final bool isModoTriagem = _statusAtual == StatusPaciente.triagemRealizada;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: 'Informações Pessoais',
                    icon: Icons.person_outline,
                    children: [
                      _buildDetailRow('Nome Completo', paciente.nomeCompleto),
                      if (paciente.nomeSocial != null && paciente.nomeSocial!.isNotEmpty)
                        _buildDetailRow('Nome Social', paciente.nomeSocial!),
                      _buildDetailRow('CPF', paciente.cpf ?? 'Não informado'),
                      _buildDetailRow('Telefone', paciente.telefone ?? 'Não informado'),
                      _buildDetailRow('Email Principal', paciente.email ?? 'Não informado'),
                      if (paciente.emailSecundario != null && paciente.emailSecundario!.isNotEmpty)
                        _buildDetailRow('Email Secundário', paciente.emailSecundario!),
                      _buildDetailRow('Data de Nascimento', paciente.dataNascimento != null ? DateFormat('dd/MM/yyyy').format(paciente.dataNascimento!) : 'Não informada'),
                      _buildDetailRow('Idade', paciente.idadeTexto ?? 'Não informada'),
                      _buildDetailRow('Estado Civil', paciente.estadoCivil ?? 'Não informado'),
                      _buildDetailRow('Religião', paciente.religiao ?? 'Não informado'),
                      _buildDetailRow('Endereço', paciente.endereco ?? 'Não informado'),
                      
                    ],
                  ),
                  _buildSectionCard(
                    title: 'Informações Familiares',
                    icon: Icons.family_restroom_outlined,
                    children: [
                      _buildDetailRow('Nome da Mãe', paciente.nomeMae ?? 'Não informado'),
                      _buildDetailRow('Nome do Pai', paciente.nomePai ?? 'Não informado'),
                      _buildDetailRow('Renda Mensal', paciente.rendaMensal ?? 'Não informado'),
                    ],
                  ),
                   _buildSectionCard(
                    title: 'Preferências de Atendimento',
                    icon: Icons.schedule_outlined,
                    children: [
                      _buildDetailRow('Modalidade', paciente.modalidadePreferencial ?? 'Não informado'),
                      _buildDetailRow('Dias Preferenciais', paciente.diasPreferenciais ?? 'Não informado'),
                      _buildDetailRow('Horários Preferenciais', paciente.horariosPreferenciais ?? 'Não informado'),
                    ],
                  ),
                  _buildSectionCard(
                    title: 'Vínculo Institucional e Atendimento',
                    icon: Icons.school_outlined,
                    children: [
                      _buildDetailRow('Vínculo UNIFECAF', paciente.vinculoUnifecafStatus ?? 'Não informado'),
                      if (paciente.vinculoUnifecafDetalhe != null && paciente.vinculoUnifecafDetalhe!.isNotEmpty)
                        _buildDetailRow('Detalhe do Vínculo', paciente.vinculoUnifecafDetalhe!),
                      _buildDetailRow('Encaminhamento', paciente.encaminhamento ?? 'Não informado'),
                      if (paciente.poloEad != null && paciente.poloEad!.isNotEmpty)
                        _buildDetailRow('Polo EAD', paciente.poloEad!),
                      _buildDetailRow('Atendimento Escolhido', paciente.tipoAtendimento ?? 'Não informada'),
                    ],
                  ),
                  _buildSectionCard(
                    title: 'Gerenciamento',
                    icon: Icons.rule_folder_outlined,
                    children: [
                      _buildStatusEditorRow(),
                      _buildDetailRow('Data de Inscrição', paciente.dataHoraEnvio != null ? DateFormat('dd/MM/yyyy').format(paciente.dataHoraEnvio!) : 'Não informada'),
                      _buildDetailRow('Termo de Consentimento', paciente.termoConsentimento ?? 'Não informado'),
                    ],
                  ),
                  if (isModoTriagem) _buildTriagemForm(),
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _salvarAlteracoes,
                        icon: const Icon(Icons.save_alt_outlined),
                        label: const Text('Salvar Alterações'),
                        style: FilledButton.styleFrom(backgroundColor: accentGreen, padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusEditorRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('Categoria:', style: TextStyle(fontWeight: FontWeight.w600, color: primary, fontSize: 15)),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              child: DropdownButton<StatusPaciente>(
                value: _statusAtual,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                icon: Icon(Icons.arrow_drop_down, color: primary),
                onChanged: (novoStatus) {
                  if (novoStatus != null) {
                    setState(() => _statusAtual = novoStatus);
                  }
                },
                items: StatusPaciente.values.map((status) {
                  return DropdownMenuItem<StatusPaciente>(
                    value: status,
                    child: Row(children: [Icon(Icons.circle, color: status.cor, size: 14), const SizedBox(width: 8), Text(status.valor)]),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTriagemForm() {
    return _buildSectionCard(
      title: 'Formulário de Triagem',
      icon: Icons.fact_check_outlined,
      children: [
        _buildTextFormField(_sexoController, 'Sexo'),
        _buildTextFormField(_racaController, 'Raça, cor ou etnia'),
        _buildTextFormField(_escolaridadeController, 'Escolaridade'),
        _buildTextFormField(_profissaoController, 'Profissão'),
        const SizedBox(height: 24),
        const Text('Dados dos Responsáveis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary)),
        const SizedBox(height: 8),
        _buildTextFormField(_escolaridadePaiController, 'Escolaridade do Pai'),
        _buildTextFormField(_profissaoPaiController, 'Profissão do Pai'),
        _buildTextFormField(_escolaridadeMaeController, 'Escolaridade da Mãe'),
        _buildTextFormField(_profissaoMaeController, 'Profissão da Mãe'),
        const SizedBox(height: 24),
        const Text('Histórico Clínico', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary)),
        const SizedBox(height: 8),
        _buildTextFormField(_histSaudeMentalController, 'Já fez tratamento de saúde mental?'),
        _buildTextFormField(_usoMedicacaoController, 'Uso de medicação? Se sim, qual?'),
        _buildTextFormField(_tratamentoSaudeController, 'Já fez ou faz tratamento de saúde?'),
        _buildTextFormField(_queixaTriagemController, 'Queixa do paciente (resumo do preceptor)'),
        _buildTextFormField(_rotinaPacienteController, 'Rotina do paciente', maxLines: 3),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _diaAtendimentoSelecionado,
          decoration: const InputDecoration(labelText: 'Dia Oficial do Atendimento', border: OutlineInputBorder()),
          hint: const Text('Selecione o dia'),
          items: _diasSemana.map((dia) => DropdownMenuItem(value: dia, child: Text(dia))).toList(),
          onChanged: (value) {
            setState(() => _diaAtendimentoSelecionado = value);
          },
          validator: (value) => value == null ? 'Selecione um dia' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _prioridadeSelecionada,
          decoration: const InputDecoration(labelText: 'Prioridade de Atendimento', border: OutlineInputBorder()),
          hint: const Text('Selecione a prioridade'),
          items: _opcoesPrioridade.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: (value) { setState(() => _prioridadeSelecionada = value); },
           validator: (value) => value == null ? 'Selecione uma prioridade' : null,
        ),
        const SizedBox(height: 16),
        _buildTextFormField(_triagemRealizadaPorController, 'Quem realizou a triagem?', isRequired: true),
      ],
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label, {bool isRequired = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        maxLines: maxLines,
        validator: isRequired ? (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null : null,
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary)),
            ]),
            const Divider(height: 24, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w600, color: primary)),
          ),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade700, fontSize: 15))),
        ],
      ),
    );
  }
}