enum AlertSeverity { warning, critical }

enum AlertAudience { companion, doctor }

class AppAlert {
  const AppAlert({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.alertType,
    required this.severity,
    required this.metrics,
    required this.message,
    required this.source,
    required this.occurredAt,
    required this.lastSeenAt,
    required this.payload,
    required this.recipientRole,
    required this.isAcknowledged,
    required this.isResolved,
    this.acknowledgedAt,
    this.resolvedAt,
    this.dedupeKey,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String alertType;
  final AlertSeverity severity;
  final List<String> metrics;
  final String message;
  final String source;
  final DateTime occurredAt;
  final DateTime lastSeenAt;
  final Map<String, dynamic> payload;
  final String recipientRole;
  final bool isAcknowledged;
  final bool isResolved;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String? dedupeKey;

  bool get isActive => !isResolved;
  bool get isCritical => severity == AlertSeverity.critical;

  String get metricLabel {
    if (metrics.isEmpty) return alertType;
    return metrics.join(' | ');
  }

  AppAlert copyWith({
    String? patientName,
    DateTime? lastSeenAt,
    Map<String, dynamic>? payload,
    bool? isAcknowledged,
    bool? isResolved,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    String? message,
  }) {
    return AppAlert(
      id: id,
      patientId: patientId,
      patientName: patientName ?? this.patientName,
      alertType: alertType,
      severity: severity,
      metrics: metrics,
      message: message ?? this.message,
      source: source,
      occurredAt: occurredAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      payload: payload ?? this.payload,
      recipientRole: recipientRole,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      isResolved: isResolved ?? this.isResolved,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      dedupeKey: dedupeKey,
    );
  }

  factory AppAlert.fromDatabaseRow(
    Map<String, dynamic> row, {
    required String recipientRole,
    String? fallbackPatientName,
  }) {
    return AppAlert(
      id: row['id'] as String,
      patientId: row['patient_id'] as String,
      patientName: _coercePatientName(row, fallbackPatientName),
      alertType: (row['alert_type'] as String?)?.trim().isNotEmpty == true
          ? row['alert_type'] as String
          : 'ALERT',
      severity: _parseSeverity(row['severity']),
      metrics: _coerceMetrics(row['metrics']),
      message: (row['message'] as String?)?.trim().isNotEmpty == true
          ? row['message'] as String
          : 'Medical alert',
      source: (row['source'] as String?)?.trim().isNotEmpty == true
          ? row['source'] as String
          : 'hardware',
      occurredAt: _parseDate(row['occurred_at']) ?? DateTime.now(),
      lastSeenAt:
          _parseDate(row['last_seen_at']) ??
          _parseDate(row['occurred_at']) ??
          DateTime.now(),
      payload: _coercePayload(row['payload'] ?? row['alert_data']),
      recipientRole: recipientRole,
      isAcknowledged:
          row['acknowledged_at'] != null || row['is_acknowledged'] == true,
      isResolved: row['is_resolved'] == true || row['resolved_at'] != null,
      acknowledgedAt: _parseDate(row['acknowledged_at']),
      resolvedAt: _parseDate(row['resolved_at']),
      dedupeKey: row['dedupe_key'] as String?,
    );
  }

  factory AppAlert.fromRealtimePayload(
    Map<String, dynamic> raw, {
    String? fallbackPatientName,
  }) {
    final payload = raw['payload'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(raw['payload'] as Map<String, dynamic>)
        : Map<String, dynamic>.from(raw);

    return AppAlert(
      id: payload['id'] as String,
      patientId: payload['patientId'] as String,
      patientName:
          (payload['patientName'] as String?)?.trim().isNotEmpty == true
          ? payload['patientName'] as String
          : (fallbackPatientName ?? 'Unknown'),
      alertType: (payload['alertType'] as String?)?.trim().isNotEmpty == true
          ? payload['alertType'] as String
          : 'ALERT',
      severity: _parseSeverity(payload['severity']),
      metrics: _coerceMetrics(payload['metrics']),
      message: (payload['message'] as String?)?.trim().isNotEmpty == true
          ? payload['message'] as String
          : 'Medical alert',
      source: (payload['source'] as String?)?.trim().isNotEmpty == true
          ? payload['source'] as String
          : 'hardware',
      occurredAt: _parseDate(payload['occurredAt']) ?? DateTime.now(),
      lastSeenAt:
          _parseDate(payload['lastSeenAt']) ??
          _parseDate(payload['occurredAt']) ??
          DateTime.now(),
      payload: _coercePayload(payload['payload']),
      recipientRole:
          (payload['recipientRole'] as String?)?.trim().isNotEmpty == true
          ? payload['recipientRole'] as String
          : 'companion',
      isAcknowledged: payload['isAcknowledged'] == true,
      isResolved: payload['isResolved'] == true,
      acknowledgedAt: _parseDate(payload['acknowledgedAt']),
      resolvedAt: _parseDate(payload['resolvedAt']),
      dedupeKey: payload['dedupeKey'] as String?,
    );
  }

  static AlertSeverity _parseSeverity(Object? raw) {
    if (raw is String && raw.toLowerCase() == 'critical') {
      return AlertSeverity.critical;
    }
    return AlertSeverity.warning;
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is! String || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  static List<String> _coerceMetrics(Object? raw) {
    if (raw is List) {
      return raw
          .map((item) => item?.toString() ?? '')
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false);
    }

    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    return const [];
  }

  static Map<String, dynamic> _coercePayload(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  static String _coercePatientName(
    Map<String, dynamic> row,
    String? fallbackPatientName,
  ) {
    final directName = row['patient_name'] as String?;
    if (directName?.trim().isNotEmpty == true) {
      return directName!;
    }

    final nestedPatient = row['patients'];
    if (nestedPatient is Map) {
      final profile = nestedPatient['profiles'];
      if (profile is Map) {
        final nestedName = profile['name'] as String?;
        if (nestedName?.trim().isNotEmpty == true) {
          return nestedName!;
        }
      }
    }

    return fallbackPatientName ?? 'Unknown';
  }
}
