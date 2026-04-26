import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitaguard_app/core/alerts/alert_model.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';

class AlertRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  SupabaseClient get _client => _supabase.client;

  Future<List<AppAlert>> fetchAlertsForCompanion({
    required String patientId,
    String? patientName,
    DateTime? since,
  }) {
    return _fetchRecentAndActiveAlerts(
      patientIds: [patientId],
      audience: AlertAudience.companion,
      fallbackNames: {patientId: patientName ?? 'Unknown'},
      since: since,
    );
  }

  Future<List<AppAlert>> fetchAlertsForDoctor({
    required List<String> patientIds,
    Map<String, String> patientNamesById = const {},
    DateTime? since,
  }) {
    return _fetchRecentAndActiveAlerts(
      patientIds: patientIds,
      audience: AlertAudience.doctor,
      fallbackNames: patientNamesById,
      since: since,
    );
  }

  Future<void> acknowledgeAlert(String alertId) async {
    final result = await _client.rpc(
      'acknowledge_medical_alert',
      params: {'p_alert_id': alertId},
    );

    if (result == null) {
      return;
    }
  }

  Future<List<AppAlert>> _fetchRecentAndActiveAlerts({
    required List<String> patientIds,
    required AlertAudience audience,
    required Map<String, String> fallbackNames,
    DateTime? since,
  }) async {
    if (patientIds.isEmpty) {
      return const [];
    }

    final unresolvedRows = await _queryAlerts(
      patientIds: patientIds,
      audience: audience,
      unresolvedOnly: true,
      since: since,
    );

    final recentRows = await _queryAlerts(
      patientIds: patientIds,
      audience: audience,
      since: since ?? DateTime.now().subtract(const Duration(hours: 24)),
    );

    final merged = <String, AppAlert>{};
    for (final row in [...unresolvedRows, ...recentRows]) {
      final patientId = row['patient_id'] as String? ?? '';
      final recipientRole = audience == AlertAudience.doctor
          ? 'doctor'
          : 'companion';
      final alert = AppAlert.fromDatabaseRow(
        row,
        recipientRole: recipientRole,
        fallbackPatientName: fallbackNames[patientId],
      );
      merged[alert.id] = alert;
    }

    final alerts = merged.values.toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return alerts;
  }

  Future<List<Map<String, dynamic>>> _queryAlerts({
    required List<String> patientIds,
    required AlertAudience audience,
    bool unresolvedOnly = false,
    DateTime? since,
  }) async {
    var query = _client
        .from('medical_alerts')
        .select(
          'id, patient_id, alert_type, alert_data, is_resolved, created_at, '
          'severity, source, metrics, message, payload, dedupe_key, '
          'occurred_at, last_seen_at, acknowledged_at, resolved_at',
        );

    if (patientIds.length == 1) {
      query = query.eq('patient_id', patientIds.first);
    } else {
      query = query.inFilter('patient_id', patientIds);
    }

    if (audience == AlertAudience.doctor) {
      query = query.eq('severity', 'critical');
    }

    if (unresolvedOnly) {
      query = query.eq('is_resolved', false);
    }

    if (since != null) {
      query = query.gte('occurred_at', since.toUtc().toIso8601String());
    }

    final response = await query
        .order('occurred_at', ascending: false)
        .limit(50);

    return response
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }
}
