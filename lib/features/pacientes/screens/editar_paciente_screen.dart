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

  final List<String> _opcoesTipoAtendimento = ['Orientação', 'Neuropsicologia', 'Psicanálise'];
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
  late final TextEditingController _queixaPacienteController;
  late String _selectedStatus;
  late String? _selectedTipoAtendimento;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.paciente.nomeCompleto);
    _cpfController = TextEditingController(text: widget.paciente.cpf);
    _telefoneController = TextEditingController(text: widget.paciente.telefone);
    _enderecoController = TextEditingController(text: widget.paciente.endereco);
    _queixaPacienteController = TextEditingController(text: widget.paciente.queixaPaciente);
    _selectedTipoAtendimento = widget.paciente.tipoAtendimento;
    
    final String? initialStatus = widget.paciente.statusDetalhado;
    if (initialStatus != null && _opcoesStatus.contains(initialStatus)) {
      _selectedStatus = initialStatus;
    } else {
      // Tenta encontrar um status de 'aguardando' como um padrão mais inteligente
      _selectedStatus = _opcoesStatus.firstWhere(
        (s) => s.contains('AGUARDANDO'), 
        orElse: () => _opcoesStatus.first
      );
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _queixaPacienteController.dispose();
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
        'queixa_paciente': _queixaPacienteController.text,
        'tipo_atendimento': _selectedTipoAtendimento,
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
              TextFormField(
                controller: _queixaPacienteController,
                decoration: const InputDecoration(labelText: 'Queixa do Paciente'),
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTipoAtendimento,
                decoration: const InputDecoration(labelText: 'Tipo de Atendimento (Preceptor)'),
                hint: const Text('Selecione uma classificação'),
                items: _opcoesTipoAtendimento.map((String tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTipoAtendimento = newValue;
                  });
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