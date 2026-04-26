import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitaguard_app/core/providers.dart';
import 'package:vitaguard_app/doctor/chat/screen/chat_list_dr.dart';
import 'package:vitaguard_app/doctor/home/screen/doctor_home.dart';
import 'package:vitaguard_app/components/flexible_nav_bar.dart';

import '../x_ray_model/screen/doctor_x_ray_review_entry_screen.dart';

class MainDoctor extends ConsumerStatefulWidget {
  final String name;

  const MainDoctor({super.key, required this.name});

  @override
  ConsumerState<MainDoctor> createState() => _MainDoctorState();
}

class _MainDoctorState extends ConsumerState<MainDoctor>
    with WidgetsBindingObserver {
  int currentIndex = 0;
  List<String> _bootstrappedPatientIds = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeDoctorContext());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(alertCenterProvider).onAppResumed());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeDoctorContext() async {
    await ref.read(doctorProvider).fetchAssignedPatients();
    await ref.read(doctorProvider).fetchVerificationStatus();
    _bootstrapAlertCenter(ref.read(doctorProvider).assignedPatients);
  }

  void _bootstrapAlertCenter(List<dynamic> assignedPatients) {
    final patientIds = assignedPatients
        .map((patient) => patient['patient_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false)
      ..sort();

    if (patientIds.isEmpty || listEquals(patientIds, _bootstrappedPatientIds)) {
      return;
    }

    final patientNamesById = <String, String>{};
    for (final patient in assignedPatients) {
      final patientId = patient['patient_id']?.toString() ?? '';
      if (patientId.isEmpty) {
        continue;
      }

      final patientName = patient['name']?.toString().trim();
      if (patientName != null && patientName.isNotEmpty) {
        patientNamesById[patientId] = patientName;
      }
    }

    _bootstrappedPatientIds = patientIds;
    unawaited(
      ref.read(alertCenterProvider).bootstrapForDoctor(
        patientIds: patientIds,
        patientNamesById: patientNamesById,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignedPatients = ref.watch(doctorProvider).assignedPatients;
    final patientIds = assignedPatients
        .map((patient) => patient['patient_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false)
      ..sort();

    if (patientIds.isNotEmpty &&
        !listEquals(patientIds, _bootstrappedPatientIds)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bootstrapAlertCenter(assignedPatients);
      });
    }

    final screens = [
      DoctorHomes(name: widget.name),
      ChatListDr(),
      DoctorXRayReviewEntryScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: FlexibleNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        hiddenIndexes: [3, 4, 5],
      ),
    );
  }
}
