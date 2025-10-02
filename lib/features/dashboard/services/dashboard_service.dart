// lib/features/dashboard/services/dashboard_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dashboard_metrics_model.dart';

class DashboardService {
  final _supabase = Supabase.instance.client;
  final _metricsController = StreamController<DashboardMetrics>.broadcast();
  
  Stream<DashboardMetrics> get metricsStream => _metricsController.stream;
  RealtimeChannel? _pacientesChannel;

  DashboardService() {
    _fetchData();
    _listenToChanges();
  }

  Future<void> refreshData() async {
    await _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final response = await _supabase.rpc('get_dashboard_metrics');

      final data = response as Map<String, dynamic>;
      final totalPacientes = data['totalPacientes'] as int? ?? 0;
      
      final statusCountRaw = data['statusCount'] as Map<String, dynamic>? ?? {};
      final statusCount = statusCountRaw.map((key, value) => MapEntry(key.toUpperCase(), value as int));
      
      // NOVO: Processa os dados de Vínculo
      final vinculoCountRaw = data['vinculoCount'] as Map<String, dynamic>? ?? {};
      final vinculoCount = vinculoCountRaw.map((key, value) => MapEntry(key.toUpperCase(), value as int));

      final ageResponse = await _supabase.from('pacientes_inscritos').select('data_nascimento');
      final ageDistribution = _calculateAgeDistribution(ageResponse);
      
      final metrics = DashboardMetrics(
        totalPacientes: totalPacientes,
        statusCount: statusCount,
        ageDistribution: ageDistribution,
        vinculoCount: vinculoCount, // NOVO
      );

      if (!_metricsController.isClosed) {
        _metricsController.add(metrics);
      }

    } catch (e) {
      debugPrint('Erro ao buscar métricas: $e');
      if (!_metricsController.isClosed) {
        _metricsController.addError('Falha ao carregar dados do dashboard.');
      }
    }
  }

  void _listenToChanges() {
    _pacientesChannel = _supabase
        .channel('public:pacientes_inscritos')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pacientes_inscritos',
          callback: (payload) {
            debugPrint('Mudança detectada! Recarregando métricas...');
            _fetchData();
          },
        )
        .subscribe();
  }

  void dispose() {
    if (_pacientesChannel != null) {
      _supabase.removeChannel(_pacientesChannel!);
    }
    _metricsController.close();
  }

  AgeDistribution _calculateAgeDistribution(List<Map<String, dynamic>> data) {
    final ageDistribution = <String, int>{};
    for (final paciente in data) {
      if (paciente['data_nascimento'] != null) {
        final idade = _calculateAge(paciente['data_nascimento']);
        final ageGroup = _getAgeGroup(idade);
        ageDistribution[ageGroup] = (ageDistribution[ageGroup] ?? 0) + 1;
      }
    }
    return ageDistribution;
  }

  int _calculateAge(String dataNascimento) {
    final birthDate = DateTime.tryParse(dataNascimento);
    if (birthDate == null) return 0;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _getAgeGroup(int age) {
    if (age == 0) return 'Idade inválida';
    if (age < 18) return '0-17 anos';
    if (age < 30) return '18-29 anos';
    if (age < 50) return '30-49 anos';
    if (age < 65) return '50-64 anos';
    return '65+ anos';
  }
}