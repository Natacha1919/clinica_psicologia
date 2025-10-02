// lib/features/triagem/screens/detalhes_paciente_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  Future<void> _generatePdf() async {
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final boldTtf = pw.Font.ttf(boldFontData);

    final pdf = pw.Document();

    final dataMap = {
      'Informações Pessoais': {
        'Nome Completo': widget.paciente.nomeCompleto,
        'Nome Social': widget.paciente.nomeSocial,
        'CPF': widget.paciente.cpf,
        'Telefone': widget.paciente.telefone,
        'Email Principal': widget.paciente.email,
        'Email Secundário': widget.paciente.emailSecundario,
        'Data de Nascimento': widget.paciente.dataNascimento != null ? DateFormat('dd/MM/yyyy').format(widget.paciente.dataNascimento!) : null,
        'Idade': widget.paciente.idadeTexto,
        'Estado Civil': widget.paciente.estadoCivil,
        'Religião': widget.paciente.religiao,
        'Endereço': widget.paciente.endereco,
      },
      'Informações Familiares': {
        'Nome da Mãe': widget.paciente.nomeMae,
        'Nome do Pai': widget.paciente.nomePai,
        'Renda Mensal': widget.paciente.rendaMensal,
      },
      'Preferências de Atendimento': {
        'Modalidade': widget.paciente.modalidadePreferencial,
        'Dias Preferenciais': widget.paciente.diasPreferenciais,
        'Horários Preferenciais': widget.paciente.horariosPreferenciais,
      },
      'Vínculo Institucional': {
        'Vínculo UNIFECAF': widget.paciente.vinculoUnifecafStatus,
        'Detalhe do Vínculo': widget.paciente.vinculoUnifecafDetalhe,
        'Encaminhamento': widget.paciente.encaminhamento,
        'Polo EAD': widget.paciente.poloEad,
      },
      'Gerenciamento': {
        'Categoria Atual': _statusAtual.valor,
        'Data de Inscrição': widget.paciente.dataHoraEnvio != null ? DateFormat('dd/MM/yyyy HH:mm').format(widget.paciente.dataHoraEnvio!) : null,
        'Termo de Consentimento': widget.paciente.termoConsentimento,
      }
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text('Ficha de Dados do Paciente - Clínica', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
        ),
        build: (context) {
          final List<pw.Widget> widgets = [];
          
          dataMap.forEach((sectionTitle, sectionData) {
            widgets.add(pw.Header(level: 1, text: sectionTitle));
            
            sectionData.forEach((label, value) {
              if (value != null && value.isNotEmpty) {
                widgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4.0),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(
                          width: 150,
                          child: pw.Text('$label:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Expanded(child: pw.Text(value)),
                      ],
                    ),
                  ),
                );
              }
            });
            widgets.add(pw.SizedBox(height: 20));
          });

          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Detalhes do Paciente'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Gerar PDF',
            onPressed: _generatePdf,
          ),
        ],
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