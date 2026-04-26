import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitaguard_app/Hardware/screen/hardware_screen.dart';
import 'package:vitaguard_app/companion/data/companion_models.dart';
import 'package:vitaguard_app/companion/home/screens/companion_home.dart';
import 'package:vitaguard_app/components/flexible_nav_bar.dart';
import 'package:vitaguard_app/core/providers.dart';
import 'package:vitaguard_app/patient/chat/screen/chat_list_patient.dart';

import '../x_ray_model/screen/upload_x_ray.dart';

class MainCompanion extends ConsumerStatefulWidget {
  final String name;

  const MainCompanion({super.key, required this.name});

  @override
  ConsumerState<MainCompanion> createState() => _MainCompanionState();
}

class _MainCompanionState extends ConsumerState<MainCompanion>
    with WidgetsBindingObserver {
  int currentIndex = 0;
  String? _bootstrappedPatientId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeCompanionContext());
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

  Future<void> _initializeCompanionContext() async {
    await ref.read(companionProvider).fetchPatientStatus();
    _bootstrapAlertCenter(ref.read(companionProvider).patientStatus);
  }

  void _bootstrapAlertCenter(LinkedPatientStatus? patientStatus) {
    if (patientStatus == null) {
      return;
    }

    if (_bootstrappedPatientId == patientStatus.patientId) {
      return;
    }

    _bootstrappedPatientId = patientStatus.patientId;
    unawaited(
      ref
          .read(alertCenterProvider)
          .bootstrapForCompanion(
            patientId: patientStatus.patientId,
            patientName: patientStatus.name,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientStatus = ref.watch(companionProvider).patientStatus;
    if (patientStatus != null &&
        patientStatus.patientId != _bootstrappedPatientId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bootstrapAlertCenter(patientStatus);
      });
    }

    final List<Widget> screens = [
      CompanionHome(name: widget.name),
      ChatListPatient(),
      UploadXRay(),
      HardwareScreen(
        patientId: patientStatus?.patientId,
        patientName: patientStatus?.name,
      ),
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
        hiddenIndexes: [],
      ),
    );
  }
}
