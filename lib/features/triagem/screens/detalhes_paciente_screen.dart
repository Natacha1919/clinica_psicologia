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
        foregroundColor: Colors.white, // 👈 MUDANÇA AQUI
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              'Informações Pessoais',
              [
                _buildDetailRow(
                    'Nome Completo', widget.paciente.nomeCompleto),
                if (widget.paciente.nomeSocial != null &&
                    widget.paciente.nomeSocial!.isNotEmpty)
                  _buildDetailRow(
                      'Nome Social', widget.paciente.nomeSocial!),
                _buildDetailRow(
                    'CPF', widget.paciente.cpf ?? 'Não informado'),
                _buildDetailRow('Telefone',
                    widget.paciente.telefone ?? 'Não informado'),
                _buildDetailRow(
                    'Email', widget.paciente.email ?? 'Não informado'),
                if (widget.paciente.emailSecundario != null &&
                    widget.paciente.emailSecundario!.isNotEmpty)
                  _buildDetailRow(
                      'Email Secundário', widget.paciente.emailSecundario!),
                _buildDetailRow(
                  'Data de Nascimento',
                  widget.paciente.dataNascimento != null
                      ? _formatDate(widget.paciente.dataNascimento!)
                      : 'Não informado',
                ),
                _buildDetailRow('Idade',
                    widget.paciente.idadeTexto ?? 'Não informado'),
                _buildDetailRow('Estado Civil',
                    widget.paciente.estadoCivil ?? 'Não informado'),
                _buildDetailRow('Religião',
                    widget.paciente.religiao ?? 'Não informado'),
              ],
              icon: Icons.person,
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              'Informações Familiares',
              [
                _buildDetailRow('Nome do Pai',
                    widget.paciente.nomePai ?? 'Não informado'),
                _buildDetailRow('Nome da Mãe',
                    widget.paciente.nomeMae ?? 'Não informado'),
                _buildDetailRow('Renda Mensal',
                    widget.paciente.rendaMensal ?? 'Não informado'),
              ],
              icon: Icons.family_restroom,
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              'Localização',
              [
                _buildDetailRow('Endereço',
                    widget.paciente.endereco ?? 'Não informado'),
              ],
              icon: Icons.location_on,
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              'Preferências de Atendimento',
              [
                _buildDetailRow('Modalidade',
                    widget.paciente.modalidadePreferencial ??
                        'Não informado'),
                _buildDetailRow('Dias',
                    widget.paciente.diasPreferenciais ?? 'Não informado'),
                _buildDetailRow('Horários',
                    widget.paciente.horariosPreferenciais ??
                        'Não informado'),
                if (widget.paciente.poloEad != null &&
                    widget.paciente.poloEad!.isNotEmpty)
                  _buildDetailRow('Polo EAD', widget.paciente.poloEad!),
              ],
              icon: Icons.schedule,
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              'Informações Acadêmicas/Profissionais',
              [
                _buildDetailRow(
                    'Vínculo UNIFECAF',
                    widget.paciente.vinculoUnifecafStatus ??
                        'Não informado'),
                if (widget.paciente.vinculoUnifecafDetalhe != null &&
                    widget.paciente.vinculoUnifecafDetalhe!.isNotEmpty)
                  _buildDetailRow('Detalhe do Vínculo',
                      widget.paciente.vinculoUnifecafDetalhe!),
                _buildDetailRow('Encaminhamento',
                    widget.paciente.encaminhamento ?? 'Não informado'),
              ],
              icon: Icons.school,
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              'Informações do Sistema',
              [
                _buildStatusEditorRow(),
                _buildDetailRow(
                  'Data de Envio',
                  widget.paciente.dataHoraEnvio != null
                      ? _formatDate(widget.paciente.dataHoraEnvio!)
                      : 'Não informado',
                ),
                _buildDetailRow(
                  'Termo de Consentimento',
                  widget.paciente.termoConsentimento ?? 'Não informado',
                ),
              ],
              icon: Icons.info,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusEditorRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              'Categoria:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _primaryDark,
              ),
            ),
          ),
          if (_isSaving)
            const Expanded(
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Expanded(
              child: DropdownButton<StatusPaciente>(
                value: _statusAtual,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                icon: Icon(Icons.arrow_drop_down, color: _accentGreen),
                onChanged: (novoStatus) {
                  if (novoStatus != null && novoStatus != _statusAtual) {
                    _updateStatus(novoStatus);
                  }
                },
                selectedItemBuilder: (context) {
                  return StatusPaciente.values.map<Widget>((status) {
                    final statusColor = status.cor;
                    final textColor =
                        _getTextColorForBackground(statusColor);
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        label: Text(
                          status.valor,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: statusColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        elevation: 2,
                      ),
                    );
                  }).toList();
                },
                items: StatusPaciente.values.map((status) {
                  return DropdownMenuItem<StatusPaciente>(
                    value: status,
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: status.cor, size: 16),
                        const SizedBox(width: 10),
                        Text(status.valor),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Color _getTextColorForBackground(Color backgroundColor) {
    if (ThemeData.estimateBrightnessForColor(backgroundColor) ==
        Brightness.light) {
      return Colors.black87;
    }
    return Colors.white;
  }

  Widget _buildSectionCard(String title, List<Widget> children,
      {IconData? icon}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) Icon(icon, size: 20, color: _accentGreen),
                if (icon != null) const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _primaryDark,
                  ),
                ),
              ],
            ),
            const Divider(thickness: 1, color: Color(0xFF36D97D)),
            const SizedBox(height: 12),
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
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}