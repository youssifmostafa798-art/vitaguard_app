import 'package:flutter/material.dart';
import 'package:vitaguard_app/core/feedback/clinical_feedback.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ClinicalFeedbackPanel(
      type: ClinicalPopupType.error,
      title: 'Authentication issue',
      message: message,
    );
  }
}
