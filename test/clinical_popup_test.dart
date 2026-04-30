import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitaguard_app/core/utils/screen_util_helper.dart';
import 'package:vitaguard_app/data/models/patient/patient_models.dart';
import 'package:vitaguard_app/presentation/screens/xray/ai_xray_result_screen.dart';
import 'package:vitaguard_app/presentation/widgets/xray/clinical_popup.dart';

void main() {
  testWidgets('ClinicalPopupHost shows and auto-dismisses a popup', (
    tester,
  ) async {
    final controller = ClinicalPopupController();
    addTearDown(controller.dispose);

    await _pumpHarness(
      tester,
      ClinicalPopupHost(
        controller: controller,
        child: const SizedBox.expand(),
      ),
    );

    controller.showClinicalPopup(
      message: 'Analysis marked as reviewed.',
      color: ClinicalPopupPalette.reviewed,
      icon: Icons.verified_outlined,
    );
    await tester.pump();

    expect(find.text('Analysis marked as reviewed.'), findsOneWidget);
    expect(find.byType(FractionallySizedBox), findsOneWidget);

    await tester.pump(ClinicalPopupController.displayDuration);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Analysis marked as reviewed.'), findsNothing);
  });

  testWidgets('ClinicalPopupHost caps rapid mixed actions at two popups', (
    tester,
  ) async {
    final controller = ClinicalPopupController();
    addTearDown(controller.dispose);

    await _pumpHarness(
      tester,
      ClinicalPopupHost(
        controller: controller,
        child: const SizedBox.expand(),
      ),
    );

    controller.showClinicalPopup(
      message: 'Added.',
      color: ClinicalPopupPalette.addToReport,
      icon: Icons.note_add_outlined,
      type: PopupType.addToReport,
    );
    controller.showClinicalPopup(
      message: 'Flagged.',
      color: ClinicalPopupPalette.flag,
      icon: Icons.flag_outlined,
      type: PopupType.flag,
    );
    controller.showClinicalPopup(
      message: 'Reviewed.',
      color: ClinicalPopupPalette.reviewed,
      icon: Icons.verified_outlined,
      type: PopupType.reviewed,
    );
    await tester.pump();

    expect(find.text('Reviewed.'), findsOneWidget);
    expect(find.text('Flagged.'), findsOneWidget);
    expect(find.text('Added.'), findsNothing);
  });

  testWidgets('ClinicalPopupHost cross-fades same-type rapid actions', (
    tester,
  ) async {
    final controller = ClinicalPopupController();
    addTearDown(controller.dispose);

    await _pumpHarness(
      tester,
      ClinicalPopupHost(
        controller: controller,
        child: const SizedBox.expand(),
      ),
    );

    controller.showClinicalPopup(
      message: 'Flagged once.',
      color: ClinicalPopupPalette.flag,
      icon: Icons.flag_outlined,
      type: PopupType.flag,
    );
    controller.showClinicalPopup(
      message: 'Flag updated.',
      color: ClinicalPopupPalette.flag,
      icon: Icons.flag_outlined,
      type: PopupType.flag,
    );
    await tester.pump();

    expect(find.text('Flag updated.'), findsOneWidget);
    expect(find.text('Flagged once.'), findsNothing);
  });

  testWidgets('AiXRayResultScreen uses clinical popup for action feedback', (
    tester,
  ) async {
    final image = await _createTestPng();
    addTearDown(() {
      if (image.existsSync()) image.deleteSync();
    });

    await _pumpHarness(
      tester,
      ProviderScope(
        child: AiXRayResultScreen(
          imageFile: image,
          result: XRayResult(
            isValid: true,
            prediction: 'NORMAL',
            confidence: 0.91,
            reportText: 'No significant pneumonia pattern detected.',
            probNormal: 0.91,
            probPneumonia: 0.09,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.ensureVisible(find.text('Add to report'));
    await tester.pump();
    await tester.tap(find.text('Add to report'));
    await tester.pump();

    expect(
      find.text('AI report summary copied and marked for report inclusion.'),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
  });
}

Future<void> _pumpHarness(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: ScreenUtilHelper.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, childWidget) => MaterialApp(home: child),
    ),
  );
}

Future<File> _createTestPng() async {
  final file = File(
    '${Directory.systemTemp.path}/vitaguard_test_xray_${DateTime.now().microsecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(_transparentPng);
  return file;
}

final Uint8List _transparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
);