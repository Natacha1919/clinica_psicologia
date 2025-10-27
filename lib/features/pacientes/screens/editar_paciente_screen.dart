// lib/features/pacientes/screens/editar_paciente_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/paciente_detalhado_model.dart';

class EditarPacienteScreen extends StatefulWidget {
  final PacienteDetalhado paciente;

  const EditarPacienteScreen({Key? key, required this.paciente}) : super(key: key);

  @override
  State<EditarPacienteScreen> createState() => _EditarPacienteScreenState();
}

class _EditarPacienteScreenState extends State<EditarPacienteScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Listas de Opções para Dropdowns
  final List<String> _opcoesStatus = [
    'BR - AGUARDANDO ATENDIMENTO', 'PG - AGUARDANDO ATENDIMENTO',
    'BR - ATIVO', 'BR - ENCERRADO', 'PG - ATIVO', 'PG - ENCERRADO',
    'ISENTO COLABORADOR', 'ISENTO COLABORADOR - ENCERRADO', 'ISENTO - ORIENTAÇÃO P.',
  ];
  final List<String> _opcoesClassificacao = ['Orientação', 'Neuropsicologia', 'Psicanálise', 'Psicoterapia', 'Psicodiagnóstico'];
  final List<String> _opcoesSexo = ['Feminino', 'Masculino', 'Intersexo', 'Outro'];
  final List<String> _opcoesEstadoCivil = ['Solteiro (a)', 'Casado (a)', 'Divorciado (a)', 'Viúvo (a)', 'União Estável'];
  final List<String> _diasSemana = ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado'];
  final List<String> _opcoesPrioridade = ['Urgente', 'Assim que possível', 'Posso esperar um pouco', 'Não tenho pressa'];

  // Controladores para campos de texto
  late final TextEditingController _nomeController;
  late final TextEditingController _cpfController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _enderecoController;
  late final TextEditingController _generoController;
  late final TextEditingController _racaController;
  late final TextEditingController _religiaoController;
  late final TextEditingController _escolaridadeController;
  late final TextEditingController _profissaoController;
  late final TextEditingController _histSaudeMentalController;
  late final TextEditingController _usoMedicacaoController;
  late final TextEditingController _queixaTriagemController;
  late final TextEditingController _tratamentoSaudeController;
  late final TextEditingController _rotinaPacienteController;
  late final TextEditingController _triagemRealizadaPorController;
  late final TextEditingController _escolaridadePaiController;
  late final TextEditingController _profissaoPaiController;
  late final TextEditingController _escolaridadeMaeController;
  late final TextEditingController _profissaoMaeController;

  // Variáveis para Dropdowns
  late String _selectedStatus;
  String? _selectedClassificacao; // CORRIGIDO
  String? _selectedSexo;
  String? _selectedEstadoCivil;
  String? _selectedDiaAtendimento;
  String? _selectedPrioridade;

  String? _safeFindValue(List<String> options, String? value) {
    if (value == null) return null;
    for (final item in options) {
      if (item.toUpperCase() == value.toUpperCase()) {
        return item;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final p = widget.paciente;

    _nomeController = TextEditingController(text: p.nomeCompleto);
    _cpfController = TextEditingController(text: p.cpf);
    _telefoneController = TextEditingController(text: p.telefone);
    _enderecoController = TextEditingController(text: p.endereco);
    _generoController = TextEditingController(text: p.genero);
    _racaController = TextEditingController(text: p.raca);
    _religiaoController = TextEditingController(text: p.religiao);
    _escolaridadeController = TextEditingController(text: p.escolaridade);
    _profissaoController = TextEditingController(text: p.profissao);
    _histSaudeMentalController = TextEditingController(text: p.historicoSaudeMental);
    _usoMedicacaoController = TextEditingController(text: p.usoMedicacao);
    _queixaTriagemController = TextEditingController(text: p.queixaTriagem);
    _tratamentoSaudeController = TextEditingController(text: p.tratamentoSaude);
    _rotinaPacienteController = TextEditingController(text: p.rotinaPaciente);
    _triagemRealizadaPorController = TextEditingController(text: p.triagemRealizadaPor);
    _escolaridadePaiController = TextEditingController(text: p.escolaridadePai);
    _profissaoPaiController = TextEditingController(text: p.profissaoPai);
    _escolaridadeMaeController = TextEditingController(text: p.escolaridadeMae);
    _profissaoMaeController = TextEditingController(text: p.profissaoMae);

    final String? initialStatus = p.statusDetalhado;
    if (initialStatus != null && _opcoesStatus.contains(initialStatus)) {
      _selectedStatus = initialStatus;
    } else {
      _selectedStatus = _opcoesStatus.first;
    }

    // CORRIGIDO: Lendo do campo correto 'classificacaoPreceptor'
    _selectedClassificacao = _safeFindValue(_opcoesClassificacao, p.classificacaoPreceptor);
    _selectedSexo = _safeFindValue(_opcoesSexo, p.sexo);
    _selectedEstadoCivil = _safeFindValue(_opcoesEstadoCivil, p.estadoCivil);
    _selectedDiaAtendimento = _safeFindValue(_diasSemana, p.diaAtendimentoDefinido);
    _selectedPrioridade = _safeFindValue(_opcoesPrioridade, p.prioridadeAtendimento);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _generoController.dispose();
    _racaController.dispose();
    _religiaoController.dispose();
    _escolaridadeController.dispose();
    _profissaoController.dispose();
    _histSaudeMentalController.dispose();
    _usoMedicacaoController.dispose();
    _queixaTriagemController.dispose();
    _tratamentoSaudeController.dispose();
    _rotinaPacienteController.dispose();
    _triagemRealizadaPorController.dispose();
    _escolaridadePaiController.dispose();
    _profissaoPaiController.dispose();
    _escolaridadeMaeController.dispose();
    _profissaoMaeController.dispose();
    super.dispose();
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final supabase = Supabase.instance.client;
      final bool isEncerrado = _selectedStatus.toUpperCase().contains('ENCERRADO');

      final updates = {
        'nome_completo': _nomeController.text,
        'cpf': _cpfController.text,
        'contato': _telefoneController.text,
        'endereco': _enderecoController.text,
        'genero': _generoController.text,
        'raca': _racaController.text,
        'religiao': _religiaoController.text,
        'escolaridade': _escolaridadeController.text,
        'profissao': _profissaoController.text,
        'historico_saude_mental': _histSaudeMentalController.text,
        'uso_medicacao': _usoMedicacaoController.text,
        'queixa_triagem': _queixaTriagemController.text,
        'tratamento_saude': _tratamentoSaudeController.text,
        'rotina_paciente': _rotinaPacienteController.text,
        'triagem_realizada_por': _triagemRealizadaPorController.text,
        'escolaridade_pai': _escolaridadePaiController.text,
        'profissao_pai': _profissaoPaiController.text,
        'escolaridade_mae': _escolaridadeMaeController.text,
        'profissao_mae': _profissaoMaeController.text,
        'status_detalhado': _selectedStatus,
        'classificacao_preceptor': _selectedClassificacao, // CORRIGIDO
        'sexo': _selectedSexo,
        'estado_civil': _selectedEstadoCivil,
        'dia_atendimento_definido': _selectedDiaAtendimento,
        'prioridade_atendimento': _selectedPrioridade,
        'data_desligamento': isEncerrado ? DateTime.now().toIso8601String() : null,
      };

      await supabase
          .from('pacientes_historico_temp')
          .update(updates)
          .eq('id', widget.paciente.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informações salvas com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar informações: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Editar Informações do Paciente'),
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionCard(
                title: 'Informações Pessoais',
                icon: Icons.person_outline,
                children: [
                  _buildTextFormField(_nomeController, 'Nome Completo', isRequired: true),
                  _buildTextFormField(_cpfController, 'CPF'),
                  _buildTextFormField(_telefoneController, 'Telefone (Contato)'),
                  _buildTextFormField(_enderecoController, 'Endereço'),
                  _buildDropdown(_opcoesSexo, _selectedSexo, 'Sexo', (val) => setState(() => _selectedSexo = val)),
                  _buildTextFormField(_generoController, 'Gênero'),
                  _buildTextFormField(_racaController, 'Raça/Cor'),
                  _buildTextFormField(_religiaoController, 'Religião'),
                  _buildDropdown(_opcoesEstadoCivil, _selectedEstadoCivil, 'Estado Civil', (val) => setState(() => _selectedEstadoCivil = val)),
                  _buildTextFormField(_escolaridadeController, 'Escolaridade'),
                  _buildTextFormField(_profissaoController, 'Profissão'),
                ],
              ),
              _buildSectionCard(
                title: 'Informações de Saúde e Triagem',
                icon: Icons.favorite_border,
                children: [
                  _buildDropdown(_opcoesClassificacao, _selectedClassificacao, 'Classificação (Preceptor)', (val) => setState(() => _selectedClassificacao = val)),
                  _buildDropdown(_opcoesPrioridade, _selectedPrioridade, 'Prioridade de Atendimento', (val) => setState(() => _selectedPrioridade = val)),
                  _buildDropdown(_diasSemana, _selectedDiaAtendimento, 'Dia de Atendimento Definido', (val) => setState(() => _selectedDiaAtendimento = val)),
                  _buildTextFormField(_queixaTriagemController, 'Queixa (Resumo da Triagem)', maxLines: 3),
                  _buildTextFormField(_histSaudeMentalController, 'Atendimento de Saúde Mental Anterior'),
                  _buildTextFormField(_usoMedicacaoController, 'Uso de Medicação'),
                  _buildTextFormField(_tratamentoSaudeController, 'Tratamento de Saúde Atual'),
                  _buildTextFormField(_rotinaPacienteController, 'Rotina do Paciente', maxLines: 3),
                  _buildTextFormField(_triagemRealizadaPorController, 'Triagem Realizada Por'),
                ],
              ),
              _buildSectionCard(
                title: 'Dados dos Responsáveis',
                icon: Icons.family_restroom_outlined,
                children: [
                  _buildTextFormField(_escolaridadePaiController, 'Escolaridade do Pai'),
                  _buildTextFormField(_profissaoPaiController, 'Profissão do Pai'),
                  _buildTextFormField(_escolaridadeMaeController, 'Escolaridade da Mãe'),
                  _buildTextFormField(_profissaoMaeController, 'Profissão da Mãe'),
                ],
              ),
              _buildSectionCard(
                title: 'Gerenciamento',
                icon: Icons.rule_folder_outlined,
                children: [
                  _buildDropdown(_opcoesStatus, _selectedStatus, 'Status Detalhado', (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  }, isRequired: true),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _salvarAlteracoes,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Salvar Alterações', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label, {bool isRequired = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1,
        ),
        maxLines: maxLines,
        validator: isRequired ? (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null : null,
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String? value, String label, Function(String?) onChanged, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        hint: const Text('Selecione...'),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: isRequired ? (value) => value == null ? 'Campo obrigatório' : null : null,
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}