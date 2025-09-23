// lib/features/agendamento/models/sala_model.dart

class Sala {
  final String id;
  final String nome;
  final String? descricao;
  final int capacidade;

  Sala({
    required this.id,
    required this.nome,
    this.descricao,
    required this.capacidade,
  });

  factory Sala.fromJson(Map<String, dynamic> json) {
    return Sala(
      // ALTERADO: Usamos .toString() para converter com segurança
      id: json['id'].toString(), 
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      capacidade: json['capacidade'] as int,
    );
  }
}