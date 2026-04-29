import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRealtimeSubscription {
  SupabaseRealtimeSubscription(this._channel);

  final RealtimeChannel _channel;

  Future<void> unsubscribe() => _channel.unsubscribe();
}

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  Session? get currentSession => client.auth.currentSession;

  User? get currentUser => client.auth.currentUser;

  String? get currentUidOrNull => currentUser?.id;

  String get currentUid {
    final user = currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }
    return user.id;
  }

  SupabaseQueryBuilder table(String tableName) => client.from(tableName);

  SupabaseStorageClient get storage => client.storage;

  StorageFileApi storageBucket(String bucketId) {
    return client.storage.from(bucketId);
  }

  Future<String> uploadBinary({
    required String bucketId,
    required String path,
    required Uint8List bytes,
    required String contentType,
    bool upsert = false,
  }) {
    return track(
      'storage.$bucketId.uploadBinary',
      () => storageBucket(bucketId).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: upsert),
      ),
    );
  }

  RealtimeChannel channel(
    String topic, {
    RealtimeChannelConfig opts = const RealtimeChannelConfig(),
  }) {
    return client.channel(topic, opts: opts);
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return track(
      'auth.signInWithPassword',
      () => client.auth.signInWithPassword(email: email, password: password),
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) {
    return track(
      'auth.signUp',
      () => client.auth.signUp(email: email, password: password, data: data),
    );
  }

  Future<void> signOut() {
    return track('auth.signOut', client.auth.signOut);
  }

  Future<AuthResponse> refreshSession() {
    return track('auth.refreshSession', client.auth.refreshSession);
  }

  Future<void> setRealtimeAuth([String? token]) {
    return track(
      'realtime.setAuth',
      () => client.realtime.setAuth(token ?? currentSession?.accessToken),
    );
  }

  Future<T> rpc<T>(
    String functionName, {
    Map<String, dynamic>? params,
  }) {
    return track(
      'rpc.$functionName',
      () async => await client.rpc(functionName, params: params) as T,
    );
  }

  Future<FunctionResponse> invokeFunction(
    String functionName, {
    Object? body,
  }) {
    return track(
      'functions.$functionName',
      () => client.functions.invoke(functionName, body: body),
    );
  }

  Future<Map<String, dynamic>?> latestPatientLiveVitals(String patientId) {
    return track(
      'patient_live_vitals.latest',
      () async {
        final row = await client
            .from('patient_live_vitals')
            .select()
            .eq('patient_id', patientId)
            .order('recorded_at', ascending: false)
            .limit(1)
            .maybeSingle();
        return row == null ? null : Map<String, dynamic>.from(row);
      },
    );
  }

  SupabaseRealtimeSubscription subscribeToPatientLiveVitals({
    required String patientId,
    required void Function(Map<String, dynamic> record) onInsert,
  }) {
    final subscription = channel('hw_vitals_$patientId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'patient_live_vitals',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: patientId,
          ),
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
    return SupabaseRealtimeSubscription(subscription);
  }

  Future<T> track<T>(
    String operation,
    Future<T> Function() action,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await action();
      stopwatch.stop();
      _logOperation(operation, stopwatch.elapsed, succeeded: true);
      return result;
    } catch (error) {
      stopwatch.stop();
      _logOperation(
        operation,
        stopwatch.elapsed,
        succeeded: false,
        error: error,
      );
      rethrow;
    }
  }

  void _logOperation(
    String operation,
    Duration duration, {
    required bool succeeded,
    Object? error,
  }) {
    assert(() {
      final status = succeeded ? 'ok' : 'failed';
      // ignore: avoid_print
      print(
        '[SupabaseService] $operation $status in '
        '${duration.inMilliseconds}ms'
        '${error == null ? '' : ' error=$error'}',
      );
      return true;
    }());
  }
}
