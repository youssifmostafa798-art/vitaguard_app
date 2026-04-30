

part of 'supabase_service.dart';

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supabaseService)
final supabaseServiceProvider = SupabaseServiceProvider._();

final class SupabaseServiceProvider
    extends
        $FunctionalProvider<SupabaseService, SupabaseService, SupabaseService>
    with $Provider<SupabaseService> {
  SupabaseServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseServiceHash();

  @$internal
  @override
  $ProviderElement<SupabaseService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseService create(Ref ref) {
    return supabaseService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseService>(value),
    );
  }
}

String _$supabaseServiceHash() => r'c2a81d858cb3ce6df869cef502282782be78462a';