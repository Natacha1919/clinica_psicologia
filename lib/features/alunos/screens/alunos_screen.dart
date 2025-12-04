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

  // ===== DEFINIÇÃO DAS PERMISSÕES DISPONÍVEIS =====
  // Chave (salva no banco) : Valor (Texto na tela)
  final Map<String, String> _permissoesDisponiveis = {
    'dashboard': 'Ver Dashboard',
    'inscritos': 'Acessar Inscritos/Triagem',
    'pacientes': 'Gestão de Pacientes',
    'agendamentos': 'Agenda e Calendário',
  };

  @override
  void initState() {
    super.initState();
    _alunosFuture = _fetchAlunos();
  }

  Future<List<AlunoModel>> _fetchAlunos() async {
    try {
      final data = await Supabase.instance.client
          .from('alunos')
          .select('id, nome_completo, ra, email, permissoes') // <-- Incluir permissoes
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
    setState(() {
      _alunosFuture = _fetchAlunos();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  /// =============================================================
  /// DIÁLOGO DE CADASTRO DE ALUNO
  /// =============================================================
  Future<void> _showCreateAlunoDialog() async {
    final formKeyDialog = GlobalKey<FormState>();
    final nomeControllerDialog = TextEditingController();
    final raControllerDialog = TextEditingController();
    final emailControllerDialog = TextEditingController();
    
    // Lista local para controlar as permissões selecionadas neste diálogo
    List<String> permissoesSelecionadas = []; 
    
    bool isLoadingDialog = false; 

    disposeControllers() {
      nomeControllerDialog.dispose();
      raControllerDialog.dispose();
      emailControllerDialog.dispose();
    }

    Future<void> salvarAlunoDialog(StateSetter setDialogState) async {
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
          'permissoes': permissoesSelecionadas, // <-- Salva a lista
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
              content: SingleChildScrollView(
                child: Form( 
                  key: formKeyDialog,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, 
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: nomeControllerDialog,
                        decoration: const InputDecoration(labelText: 'Nome Completo', hintText: 'Nome completo', border: OutlineInputBorder()),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'O nome é obrigatório.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: raControllerDialog,
                        decoration: const InputDecoration(labelText: 'RA (Opcional)', hintText: 'Ex: 123456', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailControllerDialog,
                        decoration: const InputDecoration(labelText: 'E-mail (Opcional)', hintText: 'email@fecaf.com.br', border: OutlineInputBorder()),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      
                      // ===== SEÇÃO DE PERMISSÕES =====
                      const SizedBox(height: 24),
                      const Text('Permissões de Acesso:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Divider(),
                      // Gera um Checkbox para cada permissão disponível
                      ..._permissoesDisponiveis.entries.map((entry) {
                        return CheckboxListTile(
                          title: Text(entry.value),
                          value: permissoesSelecionadas.contains(entry.key),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                permissoesSelecionadas.add(entry.key);
                              } else {
                                permissoesSelecionadas.remove(entry.key);
                              }
                            });
                          },
                        );
                      }).toList(),
                      // ===============================
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoadingDialog ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: isLoadingDialog ? null : () => salvarAlunoDialog(setDialogState),
                  icon: isLoadingDialog ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
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
  /// DIÁLOGO DE EDIÇÃO DE ALUNO (ATUALIZADO)
  /// =============================================================
  Future<void> _showEditAlunoDialog(AlunoModel aluno) async {
    final formKeyDialog = GlobalKey<FormState>();
    final nomeControllerDialog = TextEditingController(text: aluno.nomeCompleto);
    final raControllerDialog = TextEditingController(text: aluno.ra);
    final emailControllerDialog = TextEditingController(text: aluno.email);
    
    // Carrega as permissões atuais do aluno para editar
    List<String> permissoesSelecionadas = List.from(aluno.permissoes);
    
    bool isLoadingDialog = false;

    disposeControllers() {
      nomeControllerDialog.dispose();
      raControllerDialog.dispose();
      emailControllerDialog.dispose();
    }

    Future<void> atualizarAlunoDialog(StateSetter setDialogState) async {
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
          'permissoes': permissoesSelecionadas, // <-- Atualiza a lista
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
              content: SingleChildScrollView(
                child: Form( 
                  key: formKeyDialog,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, 
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: nomeControllerDialog, 
                        decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'O nome é obrigatório.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: raControllerDialog, 
                        decoration: const InputDecoration(labelText: 'RA (Opcional)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailControllerDialog, 
                        decoration: const InputDecoration(labelText: 'E-mail (Opcional)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.emailAddress,
                      ),

                      // ===== SEÇÃO DE PERMISSÕES (EDIÇÃO) =====
                      const SizedBox(height: 24),
                      const Text('Permissões de Acesso:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Divider(),
                      ..._permissoesDisponiveis.entries.map((entry) {
                        return CheckboxListTile(
                          title: Text(entry.value),
                          value: permissoesSelecionadas.contains(entry.key),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                permissoesSelecionadas.add(entry.key);
                              } else {
                                permissoesSelecionadas.remove(entry.key);
                              }
                            });
                          },
                        );
                      }).toList(),
                      // ========================================
                    ],
                  ),
                ),
              ), 
              actions: [
                TextButton(
                  onPressed: isLoadingDialog ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: isLoadingDialog ? null : () => atualizarAlunoDialog(setDialogState), 
                  icon: isLoadingDialog ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_as), 
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
  
  // (Lógica de exclusão permanece igual, mas incluo aqui para completude)
  Future<void> _handleDeleteAluno(String alunoId, String alunoNome) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o aluno "$alunoNome"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
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
        _showSnackBar('Aluno excluído com sucesso!');
        _refreshAlunosList(); 
      } on PostgrestException catch (e) {
        _showSnackBar('Erro ao excluir aluno: ${e.message}', isError: true);
      } catch (e) {
        _showSnackBar('Erro inesperado: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Nenhum aluno cadastrado ainda.'));
            }

            final alunos = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: alunos.length,
              itemBuilder: (context, index) {
                final aluno = alunos[index];
                
                // Gera uma string com as permissões para mostrar no card
                final permsString = aluno.permissoes.isEmpty 
                    ? 'Sem acesso definido'
                    : 'Acesso: ${aluno.permissoes.map((p) => _permissoesDisponiveis[p] ?? p).join(', ')}';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(aluno.nomeCompleto.isNotEmpty ? aluno.nomeCompleto[0].toUpperCase() : '?'),
                    ),
                    title: Text(aluno.nomeCompleto),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RA: ${aluno.ra ?? 'N/A'}'),
                        Text(permsString, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    isThreeLine: true, // Para caber a lista de permissões
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                          onPressed: () => _showEditAlunoDialog(aluno),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _handleDeleteAluno(aluno.id, aluno.nomeCompleto),
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