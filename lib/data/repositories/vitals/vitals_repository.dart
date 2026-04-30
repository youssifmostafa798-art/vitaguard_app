import 'dart:async';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';
import 'package:vitaguard_app/data/models/vitals/vitals_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vitals_repository.g.dart';

abstract class VitalsRepository {
  Future<PatientLiveVitals?> getLatestVitals(String patientId);
  Stream<PatientLiveVitals> subscribeToVitals(String patientId);
}

class SupabaseVitalsRepository implements VitalsRepository {
  final SupabaseService _supabase;

  SupabaseVitalsRepository(this._supabase);

  @override
  Future<PatientLiveVitals?> getLatestVitals(String patientId) async {
    final data = await _supabase.latestPatientLiveVitals(patientId);
    if (data == null) return null;
    return PatientLiveVitals.fromJson(data);
  }

  @override
  Stream<PatientLiveVitals> subscribeToVitals(String patientId) {
    final controller = StreamController<PatientLiveVitals>.broadcast();

    final subscription = _supabase.subscribeToPatientLiveVitals(
      patientId: patientId,
      onInsert: (record) {
        if (!controller.isClosed) {
          controller.add(PatientLiveVitals.fromJson(record));
        }
      },
    );

    controller.onCancel = () {
      subscription.unsubscribe();
      if (!controller.isClosed) {
        controller.close();
      }
    };

    return controller.stream;
  }
}

@riverpod
VitalsRepository vitalsRepository(Ref ref) {
  return SupabaseVitalsRepository(ref.watch(supabaseServiceProvider));
}
