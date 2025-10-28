// lib/features/pacientes/models/paciente_dropdown_model.dart

class PacienteDropdownModel {
  final String id;
  final String nomeCompleto;

  PacienteDropdownModel({
    required this.id,
    required this.nomeCompleto,
  });

  // Factory para criar o modelo a partir do JSON do Supabase
  // Vamos buscar da mesma view 'pacientes_historico_temp'
  factory PacienteDropdownModel.fromJson(Map<String, dynamic> json) {
    return PacienteDropdownModel(
      id: json['id'] as String,
      nomeCompleto: json['nome_completo'] as String,
    );
  }
}