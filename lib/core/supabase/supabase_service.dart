import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;

  String? get currentUidOrNull => currentUser?.id;

  String get currentUid {
    final user = currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }
    return user.id;
  }
}
