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
  final List<String> _opcoesStatus = [
    'BR - AGUARDANDO ATENDIMENTO',
    'PG - AGUARDANDO ATENDIMENTO',
    'BR - ATIVO',
    'BR - ENCERRADO',
    'PG - ATIVO',
    'PG - ENCERRADO',
    'ISENTO COLABORADOR',
    'ISENTO COLABORADOR - ENCERRADO',
    'ISENTO - ORIENTAÇÃO P.',
  ];

  late final TextEditingController _nomeController;
  late final TextEditingController _cpfController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _enderecoController;
  late final TextEditingController _demandaInicialController;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.paciente.nomeCompleto);
    _cpfController = TextEditingController(text: widget.paciente.cpf);
    _telefoneController = TextEditingController(text: widget.paciente.telefone);
    _enderecoController = TextEditingController(text: widget.paciente.endereco);
    _demandaInicialController = TextEditingController(text: widget.paciente.demandaInicial);
    
    final String? initialStatus = widget.paciente.statusDetalhado;
    if (initialStatus != null && _opcoesStatus.contains(initialStatus)) {
      _selectedStatus = initialStatus;
    } else {
      _selectedStatus = _opcoesStatus.first;
    }
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
        'demanda_inicial': _demandaInicialController.text,
        'status_detalhado': _selectedStatus,
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
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _opcoesDemanda;
                  }
                  return _opcoesDemanda.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
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
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status Detalhado'),
                items: _opcoesStatus.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedStatus = newValue;
                    });
                  }
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