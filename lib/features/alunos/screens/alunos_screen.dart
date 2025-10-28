// lib/features/alunos/screens/alunos_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/aluno_model.dart'; 

class AlunosScreen extends StatefulWidget {
  const AlunosScreen({Key? key}) : super(key: key);

  @override
  State<AlunosScreen> createState() => _AlunosScreenState();
}

class _AlunosScreenState extends State<AlunosScreen> {
  late Future<List<AlunoModel>> _alunosFuture;

  @override
  void initState() {
    super.initState();
    _alunosFuture = _fetchAlunos();
  }

  Future<List<AlunoModel>> _fetchAlunos() async {
    // ... (sem alterações)
     try {
      final data = await Supabase.instance.client
          .from('alunos')
          .select('id, nome_completo, ra, email') 
          .order('nome_completo', ascending: true); 

      final alunos = (data as List)
          .map((json) => AlunoModel.fromJson(json))
          .toList();
      return alunos;
    } catch (e) {
      _showSnackBar('Erro ao buscar alunos: $e', isError: true);
      throw Exception('Falha ao carregar alunos: $e'); 
    }
  }

  void _refreshAlunosList() {
    // ... (sem alterações)
     setState(() {
      _alunosFuture = _fetchAlunos();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    // ... (sem alterações)
     if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  /// =============================================================
  /// DIÁLOGO DE CADASTRO DE ALUNO (Lógica movida para cá)
  /// =============================================================
  Future<void> _showCreateAlunoDialog() async {
    final formKeyDialog = GlobalKey<FormState>();
    final nomeControllerDialog = TextEditingController();
    final raControllerDialog = TextEditingController();
    final emailControllerDialog = TextEditingController();
    bool isLoadingDialog = false; 

    disposeControllers() {
      nomeControllerDialog.dispose();
      raControllerDialog.dispose();
      emailControllerDialog.dispose();
    }

    Future<void> salvarAlunoDialog(StateSetter setDialogState) async {
      // ... (lógica de salvar - sem alterações)
       if (!formKeyDialog.currentState!.validate()) {
        return;
      }
      setDialogState(() => isLoadingDialog = true); 

      final nomeCompleto = nomeControllerDialog.text.trim();
      final ra = raControllerDialog.text.trim();
      final email = emailControllerDialog.text.trim();

      try {
        await Supabase.instance.client.from('alunos').insert({
          'nome_completo': nomeCompleto,
          'ra': ra.isNotEmpty ? ra : null,
          'email': email.isNotEmpty ? email : null,
        });

        if (mounted) Navigator.of(context).pop(); 
        _showSnackBar('Aluno cadastrado com sucesso!');
        _refreshAlunosList(); 

      } on PostgrestException catch (e) {
        if (mounted) Navigator.of(context).pop(); 
        _showSnackBar('Erro ao salvar: ${e.message}', isError: true);
      } catch (e) {
        if (mounted) Navigator.of(context).pop(); 
        _showSnackBar('Ocorreu um erro inesperado: $e', isError: true);
      } 
    }

    await showDialog(
      context: context,
      barrierDismissible: !isLoadingDialog, 
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cadastrar Novo Aluno'),
              
              // ===== ⭐ CORREÇÃO AQUI ⭐ =====
              // Removemos o SizedBox que estava a envolver o Form.
              // O AlertDialog e o SingleChildScrollView gerem o tamanho.
              content: SingleChildScrollView(
                child: Form( // <-- O Form é filho direto do SingleChildScrollView
                  key: formKeyDialog,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, 
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: nomeControllerDialog,
                        decoration: const InputDecoration(
                          labelText: 'Nome Completo', 
                          hintText: 'Nome completo do estagiário', // Hint text adicionado
                          border: OutlineInputBorder(), // Borda adicionada
                        ),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'O nome é obrigatório.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: raControllerDialog,
                        decoration: const InputDecoration(
                          labelText: 'RA (Opcional)',
                          hintText: 'Ex: 123456', // Hint text adicionado
                          border: OutlineInputBorder(), // Borda adicionada
                          ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailControllerDialog,
                        decoration: const InputDecoration(
                          labelText: 'E-mail (Opcional)',
                          hintText: 'email.aluno@fecaf.com.br', // Hint text adicionado
                          border: OutlineInputBorder(), // Borda adicionada
                          ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
              ), // ===== FIM DA CORREÇÃO =====
              actions: [
                TextButton(
                  onPressed: isLoadingDialog ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: isLoadingDialog ? null : () => salvarAlunoDialog(setDialogState),
                  icon: isLoadingDialog 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                      : const Icon(Icons.save),
                  label: Text(isLoadingDialog ? 'Salvando...' : 'Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
    disposeControllers();
  }

 /// =============================================================
  /// DIÁLOGO DE EDIÇÃO DE ALUNO 
  /// =============================================================
  Future<void> _showEditAlunoDialog(AlunoModel aluno) async {
    final formKeyDialog = GlobalKey<FormState>();
    final nomeControllerDialog = TextEditingController(text: aluno.nomeCompleto);
    final raControllerDialog = TextEditingController(text: aluno.ra);
    final emailControllerDialog = TextEditingController(text: aluno.email);
    bool isLoadingDialog = false;

    disposeControllers() {
      nomeControllerDialog.dispose();
      raControllerDialog.dispose();
      emailControllerDialog.dispose();
    }

    Future<void> atualizarAlunoDialog(StateSetter setDialogState) async {
      // ... (lógica de atualizar - sem alterações)
        if (!formKeyDialog.currentState!.validate()) {
        return;
      }
      setDialogState(() => isLoadingDialog = true);

      final nomeCompleto = nomeControllerDialog.text.trim();
      final ra = raControllerDialog.text.trim();
      final email = emailControllerDialog.text.trim();

      try {
        await Supabase.instance.client.from('alunos').update({
          'nome_completo': nomeCompleto,
          'ra': ra.isNotEmpty ? ra : null,
          'email': email.isNotEmpty ? email : null,
        }).eq('id', aluno.id); 

        if (mounted) Navigator.of(context).pop();
        _showSnackBar('Aluno atualizado com sucesso!');
        _refreshAlunosList();

      } on PostgrestException catch (e) {
        if (mounted) Navigator.of(context).pop();
        _showSnackBar('Erro ao atualizar: ${e.message}', isError: true);
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        _showSnackBar('Ocorreu um erro inesperado: $e', isError: true);
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: !isLoadingDialog,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Aluno'), 
              
              // ===== ⭐ CORREÇÃO AQUI (igual à do diálogo de Criar) ⭐ =====
              content: SingleChildScrollView(
                child: Form( // <-- Form direto no SingleChildScrollView
                  key: formKeyDialog,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, 
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: nomeControllerDialog, 
                        decoration: const InputDecoration(
                          labelText: 'Nome Completo', 
                          hintText: 'Nome completo do estagiário',
                          border: OutlineInputBorder(),
                          ),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'O nome é obrigatório.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: raControllerDialog, 
                        decoration: const InputDecoration(
                          labelText: 'RA (Opcional)',
                          hintText: 'Ex: 123456',
                          border: OutlineInputBorder(),
                          ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailControllerDialog, 
                        decoration: const InputDecoration(
                          labelText: 'E-mail (Opcional)',
                          hintText: 'email.aluno@fecaf.com.br',
                          border: OutlineInputBorder(),
                          ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
              ), // ===== FIM DA CORREÇÃO =====
              actions: [
                TextButton(
                  onPressed: isLoadingDialog ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: isLoadingDialog ? null : () => atualizarAlunoDialog(setDialogState), 
                  icon: isLoadingDialog 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                      : const Icon(Icons.save_as), 
                  label: Text(isLoadingDialog ? 'Salvando...' : 'Salvar Alterações'), 
                ),
              ],
            );
          },
        );
      },
    );
    disposeControllers();
  }
  
  /// =============================================================
  /// LÓGICA DE EXCLUSÃO DE ALUNO 
  /// =============================================================
  Future<void> _handleDeleteAluno(String alunoId, String alunoNome) async {
    // ... (lógica de excluir - sem alterações)
     final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o aluno "$alunoNome"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), 
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true), 
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client.from('alunos').delete().eq('id', alunoId);
        
        _showSnackBar('Aluno "$alunoNome" excluído com sucesso!');
        _refreshAlunosList(); 

      } on PostgrestException catch (e) {
        _showSnackBar('Erro ao excluir aluno: ${e.message}', isError: true);
        if (e.code == '23503') { 
           _showSnackBar('Erro: Não é possível excluir este aluno pois ele está associado a agendamentos.', isError: true);
        }
      } catch (e) {
        _showSnackBar('Ocorreu um erro inesperado ao excluir: $e', isError: true);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // ... (AppBar e RefreshIndicator - sem alterações)
     return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Alunos'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _showCreateAlunoDialog, 
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar Novo Aluno'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshAlunosList(), 
        child: FutureBuilder<List<AlunoModel>>(
          future: _alunosFuture,
          builder: (context, snapshot) {
            // ... (Estados de Loading, Erro, Vazio - sem alterações)
             if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Erro ao carregar alunos: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('Nenhum aluno cadastrado ainda.'),
              );
            }


            final alunos = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: alunos.length,
              itemBuilder: (context, index) {
                final aluno = alunos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(aluno.nomeCompleto.isNotEmpty ? aluno.nomeCompleto[0].toUpperCase() : '?'),
                    ),
                    title: Text(aluno.nomeCompleto),
                    subtitle: Text('RA: ${aluno.ra ?? 'N/A'} - Email: ${aluno.email ?? 'N/A'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                          tooltip: 'Editar Aluno',
                          onPressed: () {
                            _showEditAlunoDialog(aluno); 
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Excluir Aluno',
                          onPressed: () {
                            _handleDeleteAluno(aluno.id, aluno.nomeCompleto);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}