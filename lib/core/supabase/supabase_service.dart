import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'supabase_service.g.dart';

@Riverpod(keepAlive: true)
SupabaseService supabaseService(Ref ref) {
  return SupabaseService.instance;
}

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

  /// Checks if there is an active authenticated session.
  bool get isAuthenticated => currentSession != null && currentUser != null;

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
    return track(
      'auth.signOut',
      () => client.auth
          .signOut(scope: SignOutScope.global)
          .timeout(const Duration(seconds: 5)),
    );
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

  Future<T> rpc<T>(String functionName, {Map<String, dynamic>? params}) {
    return track(
      'rpc.$functionName',
      () async => await client.rpc(functionName, params: params) as T,
    );
  }

  Future<FunctionResponse> invokeFunction(String functionName, {Object? body}) {
    debugPrint('[FUNCTION] Invoking: $functionName with body: $body');
    return track('functions.$functionName', () {
      final future = client.functions.invoke(functionName, body: body);
      future.then(
        (response) {
          debugPrint(
            '[FUNCTION] Response from $functionName: '
            '${response.status} ${response.data}',
          );
        },
        onError: (error) {
          debugPrint('[ERROR] Function $functionName failed: $error');
        },
      );
      return future;
    });
  }

  Future<Map<String, dynamic>?> latestPatientLiveVitals(String patientId) {
    return track('patient_live_vitals.latest', () async {
      final row = await client
          .from('patient_live_vitals')
          .select()
          .eq('patient_id', patientId)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null ? null : Map<String, dynamic>.from(row);
    });
  }

  SupabaseRealtimeSubscription subscribeToPatientLiveVitals({
    required String patientId,
    required void Function(Map<String, dynamic> record) onInsert,
  }) {
    debugPrint('[REALTIME] Subscribing to patient_live_vitals for: $patientId');
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
          callback: (payload) {
            debugPrint('[REALTIME] New vital recorded for patient: $patientId');
            onInsert(payload.newRecord);
          },
        )
        .subscribe((status, [error]) {
          debugPrint('[REALTIME] Subscription status: $status, error: $error');
        });
    return SupabaseRealtimeSubscription(subscription);
  }

  Future<T> track<T>(String operation, Future<T> Function() action) async {
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
