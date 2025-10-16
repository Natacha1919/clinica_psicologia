// lib/features/pacientes/screens/lista_pacientes_screen.dart

import 'package:clinica_psicologi/features/pacientes/models/prontuario_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/paciente_detalhado_model.dart' as detalhado;
import 'detalhes_paciente_screen.dart'; 

class ListaPacientesScreen extends StatefulWidget {
  const ListaPacientesScreen({Key? key}) : super(key: key);

  @override
  State<ListaPacientesScreen> createState() => _ListaPacientesScreenState();
}

class _ListaPacientesScreenState extends State<ListaPacientesScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  List<detalhado.PacienteHistorico> _pacientesOriginais = [];
  List<detalhado.PacienteHistorico> _pacientesFiltrados = [];

  final Map<String, String> _sortOptions = {
    'Nº Inscrição (Recentes)': 'numero_recente',
    'Ativos e Recentes': 'ativos_recentes',
    'Ordem Alfabética': 'ordem_alfabetica',
  };
  late String _selectedSortOption;

  @override
  void initState() {
    super.initState();
    _selectedSortOption = _sortOptions.keys.first;
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
      final response = await Supabase.instance.client.rpc(
        'get_pacientes_sorted',
        params: {'sort_by': _sortOptions[_selectedSortOption]},
      );

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);
      final List<detalhado.PacienteHistorico> pacientes = data.map((json) => detalhado.PacienteHistorico.fromJson(json)).toList();

      if (mounted) {
        setState(() {
          _pacientesOriginais = pacientes;
          _filtrarPacientes();
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

  Color _getStatusColor(bool isAtivo) {
    return isAtivo ? const Color(0xFF28A745) : const Color(0xFF6C757D);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSearchBar(),
            const SizedBox(height: 8),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Pacientes',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSortOption,
              items: _sortOptions.keys.map((String key) {
                return DropdownMenuItem<String>(
                  value: key,
                  child: Text(key, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedSortOption = newValue;
                  });
                  _carregarDados();
                }
              },
              icon: const Icon(Icons.sort),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSearchBar() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Pesquisar por nome...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF122640)),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage!)));
    }
    if (_pacientesFiltrados.isEmpty) {
      return const Center(child: Text('Nenhum paciente encontrado.'));
    }

    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: _pacientesFiltrados.length,
        itemBuilder: (context, index) {
          final paciente = _pacientesFiltrados[index];
          return _buildPacienteCard(paciente);
        },
      ),
    );
  }
  
  Widget _buildPacienteCard(detalhado.PacienteHistorico paciente) {
    final bool isAtivo = paciente.isAtivo;
    final statusColor = _getStatusColor(isAtivo);
    final statusTextGeral = isAtivo ? 'EM ATENDIMENTO' : 'ENCERRADO';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DetalhesPacienteScreen(pacienteId: paciente.id),
            ),
          ).then((_) => _carregarDados());
        },
        child: Row(
          children: [
            Container(
              width: 8,
              height: 100,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    paciente.nomeCompleto,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nº Inscrição: ${paciente.nDeInscricao ?? 'N/A'} • CPF: ${paciente.cpf ?? 'Não consta'}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusTextGeral,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (paciente.dataInscricao != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(paciente.dataInscricao!),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}