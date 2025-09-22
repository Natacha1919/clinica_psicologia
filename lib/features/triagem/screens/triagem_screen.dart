import 'package:flutter/material.dart';
import '../../../core/config/supabase_config.dart';
import '../models/paciente_model.dart';
import 'detalhes_paciente_screen.dart';

class TriagemScreen extends StatefulWidget {
  const TriagemScreen({Key? key}) : super(key: key);

  @override
  State<TriagemScreen> createState() => _TriagemScreenState();
}

class _TriagemScreenState extends State<TriagemScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  List<Paciente> _pacientesOriginais = [];
  List<Paciente> _pacientesFiltrados = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarPacientes);
    _carregarDados();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filtrarPacientes);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    if (mounted) setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final response = await SupabaseConfig.client
          .from('pacientes_inscritos')
          .select()
          .order('data_hora_envio', ascending: false);

      final dataList = List<Map<String, dynamic>>.from(response);

      final pacientes = dataList.map((json) {
        if (json['categoria'] == null || (json['categoria'] as String).trim().isEmpty) {
          json['categoria'] = 'ESPERA';
        }
        return Paciente.fromJson(json);
      }).toList();

      if (mounted) {
        setState(() {
          _pacientesOriginais = pacientes;
          _pacientesFiltrados = pacientes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Falha ao carregar dados: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _filtrarPacientes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _pacientesFiltrados = _pacientesOriginais.where((paciente) {
        return paciente.nomeCompleto.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacientes em Triagem'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).primaryColorDark,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Pesquisar por nome do paciente',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_errorMessage!, textAlign: TextAlign.center),
      ));
    }
    if (_pacientesFiltrados.isEmpty) {
      return const Center(child: Text('Nenhum paciente encontrado.'));
    }

    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: ListView.separated(
        itemCount: _pacientesFiltrados.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 72, endIndent: 16),
        itemBuilder: (context, index) {
          final paciente = _pacientesFiltrados[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(paciente.nomeCompleto),
            subtitle: Text('CPF: ${paciente.cpf ?? 'Não informado'} | Categoria: ${paciente.categoria}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DetalhesPacienteScreen(paciente: paciente),
                ),
              ).then((_) => _carregarDados());
            },
          );
        },
      ),
    );
  }
}
