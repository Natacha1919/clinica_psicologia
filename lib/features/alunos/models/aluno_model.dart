// lib/features/alunos/models/aluno_model.dart

class AlunoModel {
  final String id;
  final String nomeCompleto;
  final String? ra;
  final String? email;
  // ===== NOVA PROPRIEDADE =====
  final List<String> permissoes; 
  // ============================

  AlunoModel({
    required this.id,
    required this.nomeCompleto,
    this.ra,
    this.email,
    // ===== NOVA PROPRIEDADE =====
    required this.permissoes,
    // ============================
  });

  factory AlunoModel.fromJson(Map<String, dynamic> json) {
    return AlunoModel(
      id: json['id'] as String,
      nomeCompleto: json['nome_completo'] as String,
      ra: json['ra'] as String?,
      email: json['email'] as String?,
      // ===== LER A LISTA DO JSON =====
      // Se vier nulo, cria lista vazia. Se vier lista, converte para String.
      permissoes: json['permissoes'] != null 
          ? List<String>.from(json['permissoes']) 
          : [],
      // ===============================
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome_completo': nomeCompleto,
      'ra': ra,
      'email': email,
      'permissoes': permissoes, // Envia a lista para o banco
    };
  }
}