// lib/core/services/pdf_generator_service.dart

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

// 1. IMPORTANDO O SEU MODELO DE DADOS REAL
import '../../features/pacientes/models/paciente_detalhado_model.dart';

// 2. PLACEHOLDER PARA AGENDAMENTOS (⭐ AJUSTE AQUI: Adicionado horaInicio)
class AgendamentoPdfModel {
  final DateTime data;
  final String horaInicio; // Ex: "08:00"
  final String titulo;
  AgendamentoPdfModel({required this.data, required this.horaInicio, required this.titulo});
}
// --------------------------------------------------------

class PdfGeneratorService {
  // --- Função Principal (sem alteração) ---
  Future<void> gerarProntuarioPaciente({
    required PacienteDetalhado paciente,
    required List<AgendamentoPdfModel> agendamentos,
  }) async {
    final pdf = pw.Document();

    // Carregar Ativos (Imagens e Fontes)
    final unifecafLogoBytes = await rootBundle.load('assets/images/unifecaf_logo.png');
    final psicoLogoBytes = await rootBundle.load('assets/images/psicologia_logo.png');
    final unifecafLogo = pw.MemoryImage(unifecafLogoBytes.buffer.asUint8List());
    final psicoLogo = pw.MemoryImage(psicoLogoBytes.buffer.asUint8List());
    final robotoRegular = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final robotoBold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));

    final footerWidget = _buildFooter(unifecafLogo, psicoLogo);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: robotoRegular,
          bold: robotoBold,
        ),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) => footerWidget,
        build: (pw.Context context) {
          const double availableWidth = 525.0; // A4 (595) - margens (32*2) = 531

          return [
            _buildHeaderProntuario(paciente),
            _buildSectionTitle('DADOS DO PACIENTE'),
            _buildDadosPessoaisGrid(paciente, availableWidth / 3),
            _buildSectionTitle('CONTATO E ENDEREÇO'),
            _buildContatoGrid(paciente, availableWidth / 2),
            _buildSectionTitle('INFORMAÇÕES DE TRIAGEM'),
            _buildDadosTriagemGrid(paciente, availableWidth / 3),
            _buildSectionTitle('HISTÓRICO CLÍNICO'),
            _buildHistoricoQueixaParagraphs(paciente),
            _buildSectionTitle('HISTÓRICO DE SESSÕES'),
            _buildHistoricoSessoesTable(agendamentos),
          ];
        },
      ),
    );

    // 5. Exibir a tela de pré-visualização de impressão
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // --- FUNÇÕES AUXILIARES DE LAYOUT ---

  pw.Widget _buildSectionTitle(String title) {
    // (Sem alteração)
     return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(
          title,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 15, color: PdfColors.black),
        ),
        pw.Divider(color: PdfColors.grey400, height: 8),
        pw.SizedBox(height: 10),
      ],
    );
  }

  pw.Widget _buildInfoItem(String label, String? value, double width) {
    // (Sem alteração)
     return pw.Container(
      width: width - 8, // Subtrai 8 para dar um 'padding'
      padding: const pw.EdgeInsets.only(bottom: 10, right: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value ?? 'Não consta',
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildParagraphInfo(String label, String? text) {
    // (Sem alteração)
     return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 5),
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 3),
        pw.Container(
          width: double.infinity, // Garante que o container ocupe a largura
          padding: const pw.EdgeInsets.all(8),
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Paragraph(
            text: text ?? 'Não consta',
            style: const pw.TextStyle(fontSize: 10), // lineHeight removido
          ),
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  // --- FUNÇÕES DE CONSTRUÇÃO DE SECÇÕES (ORGANIZADAS) ---

  pw.Widget _buildHeaderProntuario(PacienteDetalhado paciente) {
    // (Sem alteração - Chip simulado já corrigido)
     return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Prontuário do Paciente', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24)),
        pw.SizedBox(height: 8),
        pw.Text(paciente.nomeCompleto, style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
        pw.SizedBox(height: 5),
        pw.Container( // Simulação do Chip
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: pw.BoxDecoration(
            color: paciente.isAtivo ? PdfColors.teal100 : PdfColors.grey300,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Text(
            paciente.statusDetalhado?.toUpperCase() ?? 'N/A',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDadosPessoaisGrid(PacienteDetalhado paciente, double columnWidth) {
    // (Sem alteração)
    return pw.Wrap(
      children: [
        _buildInfoItem('Nome Completo', paciente.nomeCompleto, columnWidth),
        _buildInfoItem('CPF', paciente.cpf, columnWidth),
        _buildInfoItem('Data de Nascimento', paciente.dataNascimento != null ? DateFormat('dd/MM/yyyy').format(paciente.dataNascimento!) : null, columnWidth),
        _buildInfoItem('Idade', paciente.idade, columnWidth),
        _buildInfoItem('Gênero', paciente.genero, columnWidth),
        _buildInfoItem('Sexo (Biológico)', paciente.sexo, columnWidth),
        _buildInfoItem('Raça/Cor', paciente.raca, columnWidth),
        _buildInfoItem('Estado Civil', paciente.estadoCivil, columnWidth),
        _buildInfoItem('Religião', paciente.religiao, columnWidth),
        _buildInfoItem('Escolaridade', paciente.escolaridade, columnWidth),
        _buildInfoItem('Profissão', paciente.profissao, columnWidth),
      ],
    );
  }
  
  pw.Widget _buildContatoGrid(PacienteDetalhado paciente, double columnWidth) {
    // (Sem alteração)
    return pw.Wrap(
      children: [
        _buildInfoItem('E-mail', paciente.email, columnWidth),
        _buildInfoItem('Telefone', paciente.telefone, columnWidth),
        _buildInfoItem('Endereço', paciente.endereco, columnWidth * 2), 
      ],
    );
  }

  pw.Widget _buildDadosTriagemGrid(PacienteDetalhado paciente, double columnWidth) {
    // (Sem alteração)
     return pw.Wrap(
      children: [
         _buildInfoItem('Atendimento Escolhido', paciente.tipoAtendimento, columnWidth),
         _buildInfoItem('Classificação (Preceptor)', paciente.classificacaoPreceptor, columnWidth),
         _buildInfoItem('Triagem Realizada Por', paciente.triagemRealizadaPor, columnWidth),
         _buildInfoItem('Dia de Atendimento Definido', paciente.diaAtendimentoDefinido, columnWidth),
         _buildInfoItem('Prioridade (Paciente)', paciente.prioridadeAtendimento, columnWidth),
      ],
    );
  }

  pw.Widget _buildHistoricoQueixaParagraphs(PacienteDetalhado paciente) {
    // (Sem alteração)
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildParagraphInfo('Demanda Inicial', paciente.queixaTriagem),
        _buildParagraphInfo('Atendimento de Saúde Mental', paciente.historicoSaudeMental),
        _buildParagraphInfo('Uso de Medicação', paciente.usoMedicacao),
        _buildParagraphInfo('Tratamento de Saúde', paciente.tratamentoSaude),
        _buildParagraphInfo('Rotina do Paciente', paciente.rotinaPaciente),
      ],
    );
  }

  // ⭐ AJUSTE AQUI: Tabela de Histórico de Sessões agora inclui o Horário
  pw.Widget _buildHistoricoSessoesTable(List<AgendamentoPdfModel> agendamentos) {
    if (agendamentos.isEmpty) {
      return pw.Text('Nenhum agendamento registrado.');
    }
        
    return pw.Table.fromTextArray(
      // Adicionamos 'Horário' ao cabeçalho
      headers: ['Data', 'Horário', 'Descrição'], 
      data: agendamentos.map((ag) => [
        DateFormat('dd/MM/yyyy').format(ag.data),
        ag.horaInicio, // Adicionamos a hora aqui
        ag.titulo
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignments: { // Alinhamentos por coluna
        0: pw.Alignment.centerLeft, // Data
        1: pw.Alignment.center,     // Horário (centralizado)
        2: pw.Alignment.centerLeft, // Descrição
      },
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      // Ajuste opcional nas larguras das colunas
      columnWidths: {
        0: const pw.FixedColumnWidth(80), // Largura fixa para Data
        1: const pw.FixedColumnWidth(60), // Largura fixa para Horário
        2: const pw.FlexColumnWidth(),   // Descrição ocupa o resto
      }
    );
  }


  // --- FUNÇÃO DO RODAPÉ (Com Texto Centralizado) ---
  pw.Widget _buildFooter(pw.MemoryImage logoUnifecaf, pw.MemoryImage logoPsico) {
    const textStyle = pw.TextStyle(fontSize: 9, color: PdfColors.black);

    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey600, width: 1)),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 8.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center, // Mantém logos alinhados verticalmente
        children: [
          // Logo Esquerda (sem alteração)
          pw.Image(logoUnifecaf, width: 110),
          pw.SizedBox(width: 16),

          // Bloco Central de Texto (⭐ AJUSTE AQUI: Alinhamento centralizado)
          pw.Expanded(
            child: pw.Column(
              // Muda o alinhamento dos textos dentro da coluna para o CENTRO
              crossAxisAlignment: pw.CrossAxisAlignment.center, 
              children: [
                pw.RichText(
                  textAlign: pw.TextAlign.center, // Centraliza o RichText
                  text: pw.TextSpan(
                    style: textStyle,
                    children: [
                      pw.TextSpan(text: 'UniFECAF – Taboão da Serra', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      const pw.TextSpan(text: ' - Avenida Vida Nova, 166 2º Andar - CEP 06764-045 - Jardim Maria Rosa - Taboão da Serra/SP'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.RichText(
                  textAlign: pw.TextAlign.center, // Centraliza o RichText
                  text: pw.TextSpan(
                    style: textStyle,
                    children: [
                      pw.TextSpan(text: 'Clínica escola de Psicologia', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      const pw.TextSpan(text: ' - Rua Cesário Dau, 528 - CEP 06763-080 - Jardim Maria Rosa - Taboão da Serra/SP'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),
                // Textos normais já respeitam o CrossAxisAlignment.center da Coluna
                pw.Text('CNPJ 238.945/0001.49', style: textStyle),
                pw.SizedBox(height: 4),
                pw.Text('Telefone (11) 4701-5070', style: textStyle),
              ],
            ),
          ),
          
          pw.SizedBox(width: 16), // Espaçamento
          // Logo Direita (sem alteração)
          pw.Image(logoPsico, width: 80),
        ],
      ),
    );
  }
}