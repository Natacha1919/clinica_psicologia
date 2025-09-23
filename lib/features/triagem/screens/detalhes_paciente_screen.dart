// lib/features/triagem/screens/detalhes_paciente_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/config/supabase_config.dart';
import '../models/paciente_model.dart';
import '../models/status_paciente.dart';

class DetalhesPacienteScreen extends StatefulWidget {
  final Paciente paciente;

  const DetalhesPacienteScreen({Key? key, required this.paciente})
      : super(key: key);

  @override
  State<DetalhesPacienteScreen> createState() =>
      _DetalhesPacienteScreenState();
}

class _DetalhesPacienteScreenState extends State<DetalhesPacienteScreen> {
  late StatusPaciente _statusAtual;
  bool _isSaving = false;

  // Cores Padrão UniFECAF
  final Color _primaryDark = const Color(0xFF122640);
  final Color _accentGreen = const Color(0xFF36D97D);

  @override
  void initState() {
    super.initState();
    _statusAtual = StatusPaciente.values.firstWhere(
      (e) => e.valor == widget.paciente.categoria?.toUpperCase(),
      orElse: () => StatusPaciente.espera,
    );
  }

  Future<void> _updateStatus(StatusPaciente novoStatus) async {
    setState(() => _isSaving = true);
    try {
      await SupabaseConfig.client
          .from('pacientes_inscritos')
          .update({'categoria': novoStatus.valor})
          .eq('id', widget.paciente.id);
          
      setState(() => _statusAtual = novoStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Status atualizado com sucesso!'),
            backgroundColor: _accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Detalhes do Paciente'),
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: 'Informações Pessoais',
              icon: Icons.person_outline,
              children: [
                _buildDetailRow('Nome Completo', widget.paciente.nomeCompleto),
                if (widget.paciente.nomeSocial != null && widget.paciente.nomeSocial!.isNotEmpty)
                  _buildDetailRow('Nome Social', widget.paciente.nomeSocial!),
                _buildDetailRow('CPF', widget.paciente.cpf ?? 'Não informado'),
                _buildDetailRow('Telefone', widget.paciente.telefone ?? 'Não informado'),
                _buildDetailRow('Email Principal', widget.paciente.email ?? 'Não informado'),
                if (widget.paciente.emailSecundario != null && widget.paciente.emailSecundario!.isNotEmpty)
                  _buildDetailRow('Email Secundário', widget.paciente.emailSecundario!),
                _buildDetailRow(
                  'Data de Nascimento',
                  widget.paciente.dataNascimento != null
                      ? DateFormat('dd/MM/yyyy').format(widget.paciente.dataNascimento!)
                      : 'Não informada',
                ),
                _buildDetailRow('Idade', widget.paciente.idadeTexto ?? 'Não informada'),
                _buildDetailRow('Estado Civil', widget.paciente.estadoCivil ?? 'Não informado'),
                _buildDetailRow('Religião', widget.paciente.religiao ?? 'Não informada'),
                _buildDetailRow('Endereço', widget.paciente.endereco ?? 'Não informado'),
              ],
            ),
            _buildSectionCard(
              title: 'Informações Familiares',
              icon: Icons.family_restroom_outlined,
              children: [
                _buildDetailRow('Nome da Mãe', widget.paciente.nomeMae ?? 'Não informado'),
                _buildDetailRow('Nome do Pai', widget.paciente.nomePai ?? 'Não informado'),
                _buildDetailRow('Renda Mensal', widget.paciente.rendaMensal ?? 'Não informada'),
              ],
            ),
             _buildSectionCard(
              title: 'Preferências de Atendimento',
              icon: Icons.schedule_outlined,
              children: [
                _buildDetailRow('Modalidade', widget.paciente.modalidadePreferencial ?? 'Não informada'),
                _buildDetailRow('Dias Preferenciais', widget.paciente.diasPreferenciais ?? 'Não informada'),
                _buildDetailRow('Horários Preferenciais', widget.paciente.horariosPreferenciais ?? 'Não informada'),
              ],
            ),
            _buildSectionCard(
              title: 'Vínculo Institucional',
              icon: Icons.school_outlined,
              children: [
                _buildDetailRow('Vínculo UNIFECAF', widget.paciente.vinculoUnifecafStatus ?? 'Não informado'),
                 if (widget.paciente.vinculoUnifecafDetalhe != null && widget.paciente.vinculoUnifecafDetalhe!.isNotEmpty)
                  _buildDetailRow('Detalhe do Vínculo', widget.paciente.vinculoUnifecafDetalhe!),
                _buildDetailRow('Encaminhamento', widget.paciente.encaminhamento ?? 'Não informado'),
                if (widget.paciente.poloEad != null && widget.paciente.poloEad!.isNotEmpty)
                  _buildDetailRow('Polo EAD', widget.paciente.poloEad!),
              ],
            ),
            _buildSectionCard(
              title: 'Gerenciamento',
              icon: Icons.rule_folder_outlined,
              children: [
                _buildStatusEditorRow(),
                _buildDetailRow(
                  'Data de Inscrição',
                  widget.paciente.dataHoraEnvio != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(widget.paciente.dataHoraEnvio!)
                      : 'Não informada',
                ),
                _buildDetailRow('Termo de Consentimento', widget.paciente.termoConsentimento ?? 'Não informado'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusEditorRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            'Categoria:',
            style: TextStyle(fontWeight: FontWeight.w600, color: _primaryDark, fontSize: 15),
          ),
          const SizedBox(width: 16),
          _isSaving
              ? const Expanded(
                  child: Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<StatusPaciente>(
                      value: _statusAtual,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      icon: Icon(Icons.arrow_drop_down, color: _primaryDark),
                      onChanged: (novoStatus) {
                        if (novoStatus != null && novoStatus != _statusAtual) {
                          _updateStatus(novoStatus);
                        }
                      },
                      items: StatusPaciente.values.map((status) {
                        return DropdownMenuItem<StatusPaciente>(
                          value: status,
                          child: Row(
                            children: [
                              Icon(Icons.circle, color: status.cor, size: 14),
                              const SizedBox(width: 8),
                              Text(status.valor),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ],
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
            Row(
              children: [
                Icon(icon, color: _primaryDark, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryDark,
                  ),
                ),
              ],
            ),
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
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _primaryDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}