// lib/features/triagem/screens/detalhes_paciente_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/config/supabase_config.dart';
import '../models/paciente_model.dart';
import '../models/status_paciente.dart';

// Defina as cores usadas no app
const Color primary = Color.fromARGB(255, 10, 23, 36);
const Color accentGreen = Color(0xFF4CAF50); // Verde de destaque

class DetalhesPacienteScreen extends StatefulWidget {
  final Paciente paciente;
  const DetalhesPacienteScreen({Key? key, required this.paciente}) : super(key: key);
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
          SnackBar(
            content: const Text('Status atualizado com sucesso!'),
            backgroundColor: accentGreen,
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

  // FUNÇÃO DE GERAR PDF ATUALIZADA COM O NOVO RODAPÉ
  Future<void> _generatePdf() async {
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final pdf = pw.Document();

    // CORREÇÃO: Carrega as imagens dos assets com o caminho correto
    final unifecafLogo = pw.MemoryImage((await rootBundle.load('assets/images/unifecaf_logo.png')).buffer.asUint8List());
    final psicologiaLogo = pw.MemoryImage((await rootBundle.load('assets/images/psicologia_logo.png')).buffer.asUint8List());

    const headerColor = PdfColor.fromInt(0xFF2A3F54); // Azul escuro
    const lightGrey = PdfColor.fromInt(0xFFF0F0F0);

    pw.Widget buildDetailRow(String label, String? value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 150,
              child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Expanded(child: pw.Text(value ?? 'Não informado')),
          ],
        ),
      );
    }
    
    pw.Widget buildSectionHeader(String title) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(8),
        margin: const pw.EdgeInsets.only(top: 16, bottom: 8),
        decoration: const pw.BoxDecoration(
          color: lightGrey,
          border: pw.Border(left: pw.BorderSide(color: headerColor, width: 4)),
        ),
        child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: headerColor)),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 20.0),
          child: pw.Text('Ficha de Inscrição - UniFECAF', style: pw.TextStyle(color: headerColor, fontWeight: pw.FontWeight.bold, fontSize: 24)),
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Image(unifecafLogo, height: 40),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text("UniFECAF – Taboão da Serra - Avenida Vida Nova, 166 2º Andar - CEP 06764-045 - Jardim Maria Rosa - Taboão da Serra/SP", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                      pw.Text("Clínica escola de Psicologia - Rua Cesário Dau, 528 - CEP 06763-080 - Jardim Maria Rosa - Taboão da Serra/SP", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                      pw.Text("CNPJ 238.945/0001-49", style: const pw.TextStyle(fontSize: 8)),
                      pw.Text("Telefone (11) 4701-5070", style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Image(psicologiaLogo, height: 40),
              ],
            ),
          ]
        ),
        build: (context) => [
          buildSectionHeader('DADOS DO PACIENTE'),
          buildDetailRow('Nome Completo', widget.paciente.nomeCompleto),
          if (widget.paciente.nomeSocial != null && widget.paciente.nomeSocial!.isNotEmpty) buildDetailRow('Nome Social', widget.paciente.nomeSocial),
          buildDetailRow('CPF', widget.paciente.cpf),
          buildDetailRow('Data de Nascimento', widget.paciente.dataNascimento != null ? DateFormat('dd/MM/yyyy').format(widget.paciente.dataNascimento!) : null),
          buildDetailRow('Idade', widget.paciente.idadeTexto),
          buildDetailRow('Estado Civil', widget.paciente.estadoCivil),
          buildDetailRow('Religião', widget.paciente.religiao),

          buildSectionHeader('CONTATO'),
          buildDetailRow('Telefone', widget.paciente.telefone),
          buildDetailRow('Email Principal', widget.paciente.email),
          if (widget.paciente.emailSecundario != null && widget.paciente.emailSecundario!.isNotEmpty) buildDetailRow('Email Secundário', widget.paciente.emailSecundario),

          buildSectionHeader('ENDEREÇO'),
          buildDetailRow('Endereço Completo', widget.paciente.endereco),
          
          buildSectionHeader('DADOS DOS RESPONSÁVEIS'),
          buildDetailRow('Nome da Mãe', widget.paciente.nomeMae),
          buildDetailRow('Nome do Pai', widget.paciente.nomePai),

          buildSectionHeader('INFORMAÇÕES ADICIONAIS'),
          buildDetailRow('Renda Mensal', widget.paciente.rendaMensal),
          buildDetailRow('Vínculo UNIFECAF', widget.paciente.vinculoUnifecafStatus),
          if (widget.paciente.vinculoUnifecafDetalhe != null && widget.paciente.vinculoUnifecafDetalhe!.isNotEmpty) buildDetailRow('Detalhe do Vínculo', widget.paciente.vinculoUnifecafDetalhe),
          buildDetailRow('Encaminhamento', widget.paciente.encaminhamento),

          buildSectionHeader('PREFERÊNCIAS DE ATENDIMENTO'),
          buildDetailRow('Modalidade', widget.paciente.modalidadePreferencial),
          buildDetailRow('Dias Preferenciais', widget.paciente.diasPreferenciais),
          buildDetailRow('Horários Preferenciais', widget.paciente.horariosPreferenciais),
          if (widget.paciente.poloEad != null && widget.paciente.poloEad!.isNotEmpty) buildDetailRow('Polo EAD', widget.paciente.poloEad),

          buildSectionHeader('DADOS DO SISTEMA'),
          buildDetailRow('Categoria Atual', _statusAtual.valor),
          buildDetailRow('Data de Inscrição', widget.paciente.dataHoraEnvio != null ? DateFormat('dd/MM/yyyy HH:mm').format(widget.paciente.dataHoraEnvio!) : 'Não informada'),
          buildDetailRow('Termo de Consentimento', widget.paciente.termoConsentimento),
        ],
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
        foregroundColor: Colors.white,
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
                _buildDetailRow('Data de Nascimento', widget.paciente.dataNascimento != null ? DateFormat('dd/MM/yyyy').format(widget.paciente.dataNascimento!) : 'Não informada'),
                _buildDetailRow('Idade', widget.paciente.idadeTexto ?? 'Não informado'),
                _buildDetailRow('Estado Civil', widget.paciente.estadoCivil ?? 'Não informado'),
                _buildDetailRow('Religião', widget.paciente.religiao ?? 'Não informado'),
                _buildDetailRow('Endereço', widget.paciente.endereco ?? 'Não informado'),
              ],
            ),
            _buildSectionCard(
              title: 'Informações Familiares',
              icon: Icons.family_restroom_outlined,
              children: [
                _buildDetailRow('Nome da Mãe', widget.paciente.nomeMae ?? 'Não informado'),
                _buildDetailRow('Nome do Pai', widget.paciente.nomePai ?? 'Não informado'),
                _buildDetailRow('Renda Mensal', widget.paciente.rendaMensal ?? 'Não informado'),
              ],
            ),
             _buildSectionCard(
              title: 'Preferências de Atendimento',
              icon: Icons.schedule_outlined,
              children: [
                _buildDetailRow('Modalidade', widget.paciente.modalidadePreferencial ?? 'Não informado'),
                _buildDetailRow('Dias Preferenciais', widget.paciente.diasPreferenciais ?? 'Não informado'),
                _buildDetailRow('Horários Preferenciais', widget.paciente.horariosPreferenciais ?? 'Não informado'),
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
                    // MUDANÇA AQUI: Removido o 'HH:mm' do DateFormat
                    _buildDetailRow('Data de Inscrição', widget.paciente.dataHoraEnvio != null ? DateFormat('dd/MM/yyyy').format(widget.paciente.dataHoraEnvio!) : 'Não informada'),
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
          Text('Categoria:', style: TextStyle(fontWeight: FontWeight.w600, color: primary, fontSize: 15)),
          const SizedBox(width: 16),
          _isSaving
              ? const Expanded(child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))))
              : Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                    child: DropdownButton<StatusPaciente>(
                      value: _statusAtual,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      icon: Icon(Icons.arrow_drop_down, color: primary),
                      onChanged: (novoStatus) {
                        if (novoStatus != null && novoStatus != _statusAtual) {
                          _updateStatus(novoStatus);
                        }
                      },
                      items: StatusPaciente.values.map((status) {
                        return DropdownMenuItem<StatusPaciente>(
                          value: status,
                          child: Row(children: [Icon(Icons.circle, color: status.cor, size: 14), const SizedBox(width: 8), Text(status.valor)]),
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
            Row(children: [
              Icon(icon, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary)),
            ]),
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
            child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w600, color: primary)),
          ),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade700, fontSize: 15))),
        ],
      ),
    );
  }
}