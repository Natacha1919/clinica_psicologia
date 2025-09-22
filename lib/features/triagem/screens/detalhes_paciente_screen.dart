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
  State<DetalhesPacienteScreen> createState() => _DetalhesPacienteScreenState();
}

class _DetalhesPacienteScreenState extends State<DetalhesPacienteScreen> {
  late StatusPaciente _statusAtual;
  bool _isSaving = false;

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
          const SnackBar(
              content: Text('Status atualizado com sucesso!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao atualizar status: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Paciente'), elevation: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações Pessoais
            _buildSectionCard('Informações Pessoais', [
              _buildDetailRow('Nome Completo', widget.paciente.nomeCompleto),
              if (widget.paciente.nomeSocial != null &&
                  widget.paciente.nomeSocial!.isNotEmpty)
                _buildDetailRow('Nome Social', widget.paciente.nomeSocial!),
              _buildDetailRow('CPF', widget.paciente.cpf ?? 'Não informado'),
              _buildDetailRow('Telefone', widget.paciente.telefone ?? 'Não informado'),
              _buildDetailRow('Email', widget.paciente.email ?? 'Não informado'),
              if (widget.paciente.emailSecundario != null &&
                  widget.paciente.emailSecundario!.isNotEmpty)
                _buildDetailRow('Email Secundário', widget.paciente.emailSecundario!),
              _buildDetailRow(
                'Data de Nascimento',
                widget.paciente.dataNascimento != null
                    ? _formatDate(widget.paciente.dataNascimento!)
                    : 'Não informado',
              ),
              _buildDetailRow('Idade', widget.paciente.idadeTexto ?? 'Não informado'),
              _buildDetailRow('Estado Civil', widget.paciente.estadoCivil ?? 'Não informado'),
              _buildDetailRow('Religião', widget.paciente.religiao ?? 'Não informado'),
            ]),
            const SizedBox(height: 16),

            // Informações Familiares
            _buildSectionCard('Informações Familiares', [
              _buildDetailRow('Nome do Pai', widget.paciente.nomePai ?? 'Não informado'),
              _buildDetailRow('Nome da Mãe', widget.paciente.nomeMae ?? 'Não informado'),
              _buildDetailRow('Renda Mensal', widget.paciente.rendaMensal ?? 'Não informado'),
            ]),
            const SizedBox(height: 16),

            // Localização
            _buildSectionCard('Localização', [
              _buildDetailRow('Endereço', widget.paciente.endereco ?? 'Não informado'),
            ]),
            const SizedBox(height: 16),

            // Preferências de Atendimento
            _buildSectionCard('Preferências de Atendimento', [
              _buildDetailRow('Modalidade', widget.paciente.modalidadePreferencial ?? 'Não informado'),
              _buildDetailRow('Dias', widget.paciente.diasPreferenciais ?? 'Não informado'),
              _buildDetailRow('Horários', widget.paciente.horariosPreferenciais ?? 'Não informado'),
              if (widget.paciente.poloEad != null && widget.paciente.poloEad!.isNotEmpty)
                _buildDetailRow('Polo EAD', widget.paciente.poloEad!),
            ]),
            const SizedBox(height: 16),

            // Informações Acadêmicas/Profissionais
            _buildSectionCard('Informações Acadêmicas/Profissionais', [
              _buildDetailRow('Vínculo UNIFECAF', widget.paciente.vinculoUnifecafStatus ?? 'Não informado'),
              if (widget.paciente.vinculoUnifecafDetalhe != null && widget.paciente.vinculoUnifecafDetalhe!.isNotEmpty)
                _buildDetailRow('Detalhe do Vínculo', widget.paciente.vinculoUnifecafDetalhe!),
              _buildDetailRow('Encaminhamento', widget.paciente.encaminhamento ?? 'Não informado'),
            ]),
            const SizedBox(height: 16),

            // Informações do Sistema
            _buildSectionCard('Informações do Sistema', [
              _buildStatusEditorRow(),
              _buildDetailRow(
                'Data de Envio',
                widget.paciente.dataHoraEnvio != null
                    ? _formatDate(widget.paciente.dataHoraEnvio!)
                    : 'Não informado',
              ),
              _buildDetailRow('Termo de Consentimento', widget.paciente.termoConsentimento ?? 'Não informado'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusEditorRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 140,
            child: Text('Categoria:', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
          ),
          if (_isSaving)
            const Expanded(child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            Expanded(
              child: DropdownButton<StatusPaciente>(
                value: _statusAtual,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                icon: const SizedBox.shrink(),
                onChanged: (novoStatus) {
                  if (novoStatus != null && novoStatus != _statusAtual) _updateStatus(novoStatus);
                },
                selectedItemBuilder: (context) {
                  return StatusPaciente.values.map((status) {
                    return Chip(
                      label: Text(_statusAtual.valor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: _statusAtual.cor,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList();
                },
                items: StatusPaciente.values.map((status) {
                  return DropdownMenuItem<StatusPaciente>(
                    value: status,
                    child: Row(children: [
                      Icon(Icons.circle, color: status.cor, size: 16),
                      const SizedBox(width: 12),
                      Text(status.valor),
                    ]),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 12),
          ...children,
        ]),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
