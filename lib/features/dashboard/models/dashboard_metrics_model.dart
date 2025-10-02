// lib/features/dashboard/models/dashboard_metrics_model.dart

typedef StatusCount = Map<String, int>;
typedef AgeDistribution = Map<String, int>;

class DashboardMetrics {
  final int totalPacientes;
  final StatusCount statusCount;
  final AgeDistribution ageDistribution;
  final StatusCount vinculoCount; // NOVO: Métrica de Vínculo

  DashboardMetrics({
    required this.totalPacientes,
    required this.statusCount,
    required this.ageDistribution,
    required this.vinculoCount, // NOVO
  });
}