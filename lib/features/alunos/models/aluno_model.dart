// lib/features/alunos/models/aluno_model.dart

class AlunoModel {
  final String id;
  final String nomeCompleto;
  final String? ra; // RA (Registro Acadêmico) é opcional
  final String? email; // E-mail também é opcional

  AlunoModel({
    required this.id,
    required this.nomeCompleto,
    this.ra,
    this.email,
  });

  // Factory para criar o modelo a partir do JSON do Supabase
  factory AlunoModel.fromJson(Map<String, dynamic> json) {
    return AlunoModel(
      id: json['id'] as String,
      nomeCompleto: json['nome_completo'] as String,
      ra: json['ra'] as String?,
      email: json['email'] as String?,
    );
  }

  // Método para converter o modelo para JSON (para enviar ao Supabase)
  Map<String, dynamic> toJson() {
    return {
      'nome_completo': nomeCompleto,
      'ra': ra,
      'email': email,
    };
  }
}