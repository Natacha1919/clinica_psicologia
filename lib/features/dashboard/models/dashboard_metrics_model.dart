typedef StatusCount = Map<String, int>;
typedef AgeDistribution = Map<String, int>;

class DashboardMetrics {
  final int totalPacientes;
  final StatusCount statusCount;
  final AgeDistribution ageDistribution;

  DashboardMetrics({
    required this.totalPacientes,
    required this.statusCount,
    required this.ageDistribution,
  });
}