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

  static const List<String> _opcoesDemanda = [
    'PSICODIAGNÓSTICO',
    'PSICOTERAPIA',
    'AVALIAÇÃO NEUROPSICOLÓGICA',
  ];

  late final TextEditingController _nomeController;
  late final TextEditingController _cpfController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _enderecoController;
  late final TextEditingController _demandaInicialController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.paciente.nomeCompleto);
    _cpfController = TextEditingController(text: widget.paciente.cpf);
    _telefoneController = TextEditingController(text: widget.paciente.telefone);
    _enderecoController = TextEditingController(text: widget.paciente.endereco);
    _demandaInicialController = TextEditingController(text: widget.paciente.demandaInicial);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _demandaInicialController.dispose();
    super.dispose();
  }
  Future<void> _salvarAlteracoes() async {
    // Valida o formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final supabase = Supabase.instance.client;
      
      // Monta o mapa de dados a serem atualizados
      final updates = {
        'nome_completo': _nomeController.text,
        'cpf': _cpfController.text,
        'contato': _telefoneController.text,
        'endereco': _enderecoController.text,
        'demanda_inicial': _demandaInicialController.text,
        // Adicione outros campos aqui conforme necessário
      };

      // Envia o comando UPDATE para o Supabase
      await supabase
          .from('pacientes_historico_temp')
          .update(updates)
          .eq('id', widget.paciente.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informações salvas com sucesso!'), backgroundColor: Colors.green),
        );
        // Retorna para a tela anterior, enviando um sinal de 'true' para indicar que houve sucesso
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
      appBar: AppBar(
        title: const Text('Editar Informações do Paciente'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome Completo'),
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cpfController,
                decoration: const InputDecoration(labelText: 'CPF'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone (Contato)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _enderecoController,
                decoration: const InputDecoration(labelText: 'Endereço'),
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                // --- MUDANÇA PRINCIPAL AQUI ---
                optionsBuilder: (TextEditingValue textEditingValue) {
                  // Se o campo estiver vazio, retorna a lista COMPLETA.
                  if (textEditingValue.text.isEmpty) {
                    return _opcoesDemanda;
                  }
                  // Se o usuário digitou algo, filtra a lista.
                  return _opcoesDemanda.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                // --- FIM DA MUDANÇA ---
                fieldViewBuilder: (BuildContext context, TextEditingController fieldController,
                    FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    fieldController.text = _demandaInicialController.text;
                  });
                  return TextFormField(
                    controller: fieldController,
                    focusNode: fieldFocusNode,
                    decoration: const InputDecoration(labelText: 'Demanda Inicial'),
                    onChanged: (text) => _demandaInicialController.text = text,
                  );
                },
                onSelected: (String selection) {
                  _demandaInicialController.text = selection;
                   FocusScope.of(context).unfocus();
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 32,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          shrinkWrap: true,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(option),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _salvarAlteracoes,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Salvar Alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}