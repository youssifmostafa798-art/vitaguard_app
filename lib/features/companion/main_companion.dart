import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitaguard_app/presentation/screens/vitals/hardware_screen.dart';
import 'package:vitaguard_app/data/models/companion/companion_models.dart';
import 'package:vitaguard_app/presentation/screens/companion/companion_home.dart';
import 'package:vitaguard_app/presentation/widgets/flexible_nav_bar.dart';
import 'package:vitaguard_app/presentation/screens/patient/chat_list_patient.dart';
import 'package:vitaguard_app/presentation/screens/xray/upload_x_ray.dart';
import 'package:vitaguard_app/core/alerts/alert_center_provider.dart';
import 'package:vitaguard_app/presentation/controllers/companion/companion_provider.dart';

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
      unawaited(ref.read(alertControllerProvider.notifier).onAppResumed());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeCompanionContext() async {
    await ref.read(companionControllerProvider.notifier).fetchPatientStatus();
    _bootstrapAlertCenter(ref.read(companionControllerProvider).patientStatus);
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
          .read(alertControllerProvider.notifier)
          .bootstrapForCompanion(
            patientId: patientStatus.patientId,
            patientName: patientStatus.name,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientStatus = ref.watch(companionControllerProvider).patientStatus;
    if (patientStatus != null &&
        patientStatus.patientId != _bootstrappedPatientId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bootstrapAlertCenter(patientStatus);
      });
    }

    final List<Widget> screens = [
      CompanionHome(name: widget.name),
      ChatListPatient(),
      UploadXRay(
        patientId: patientStatus?.patientId,
        patientName: patientStatus?.name,
        requiresPatientContext: true,
      ),
      HardwareScreen(
        patientId: patientStatus?.patientId,
        patientName: patientStatus?.name,
        requiresPatientContext: true,
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