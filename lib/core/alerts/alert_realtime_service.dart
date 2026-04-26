import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitaguard_app/core/alerts/alert_model.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';

class AlertRealtimeService {
  final SupabaseService _supabase = SupabaseService.instance;
  final List<RealtimeChannel> _channels = [];

  SupabaseClient get _client => _supabase.client;

  Future<void> subscribeForCompanion({
    required String patientId,
    String? fallbackPatientName,
    required void Function(AppAlert alert) onAlert,
    void Function(RealtimeSubscribeStatus status, Object? error)? onStatus,
  }) async {
    await clear();
    await _setRealtimeAuth();
    await _subscribeToTopic(
      topic: 'patient:$patientId:companion-alerts',
      fallbackPatientName: fallbackPatientName,
      onAlert: onAlert,
      onStatus: onStatus,
    );
  }

  Future<void> subscribeForDoctor({
    required List<String> patientIds,
    Map<String, String> patientNamesById = const {},
    required void Function(AppAlert alert) onAlert,
    void Function(RealtimeSubscribeStatus status, Object? error)? onStatus,
  }) async {
    await clear();
    await _setRealtimeAuth();

    for (final patientId in patientIds) {
      await _subscribeToTopic(
        topic: 'patient:$patientId:doctor-critical-alerts',
        fallbackPatientName: patientNamesById[patientId],
        onAlert: onAlert,
        onStatus: onStatus,
      );
    }
  }

  Future<void> clear() async {
    for (final channel in _channels) {
      await channel.unsubscribe();
    }
    _channels.clear();
  }

  Future<void> _setRealtimeAuth() async {
    final token = _client.auth.currentSession?.accessToken;
    await _client.realtime.setAuth(token);
  }

  Future<void> _subscribeToTopic({
    required String topic,
    required void Function(AppAlert alert) onAlert,
    String? fallbackPatientName,
    void Function(RealtimeSubscribeStatus status, Object? error)? onStatus,
  }) async {
    final channel = _client.channel(
      topic,
      opts: const RealtimeChannelConfig(private: true),
    );

    channel
        .onBroadcast(
          event: 'alert.changed',
          callback: (payload) {
            onAlert(
              AppAlert.fromRealtimePayload(
                payload,
                fallbackPatientName: fallbackPatientName,
              ),
            );
          },
        )
        .subscribe(onStatus);

    _channels.add(channel);
  }
}
