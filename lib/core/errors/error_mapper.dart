import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ClinicalErrorArea {
  auth,
  upload,
  xrayAi,
  chatbot,
  reports,
  alerts,
  hardware,
  network,
  database,
  storage,
  unknown,
}

class ClinicalErrorContext {
  const ClinicalErrorContext({
    required this.area,
    this.operation,
    this.operationId,
    this.resourceName,
    this.allowRetry = true,
  });

  final ClinicalErrorArea area;
  final String? operation;
  final String? operationId;
  final String? resourceName;
  final bool allowRetry;
}

class ClinicalErrorMessage {
  const ClinicalErrorMessage({
    required this.message,
    this.developerDiagnostics,
  });

  final String message;
  final String? developerDiagnostics;
}

class ErrorMapper {
  static String map(Object error) {
    return mapForUser(
      error,
      const ClinicalErrorContext(area: ClinicalErrorArea.unknown),
    ).message;
  }

  static ClinicalErrorMessage mapForUser(
    Object error,
    ClinicalErrorContext context,
  ) {
    final developerDiagnostics = kDebugMode ? _diagnostic(error) : null;

    if (error is AuthException) {
      switch (error.statusCode) {
        case '400':
          return ClinicalErrorMessage(
            message:
                'We could not verify those credentials. Please check them and try again.',
            developerDiagnostics: developerDiagnostics,
          );
        case '429':
          return ClinicalErrorMessage(
            message:
                'Too many attempts. Please wait a few minutes before trying again.',
            developerDiagnostics: developerDiagnostics,
          );
        default:
          return ClinicalErrorMessage(
            message:
                'Authentication is unavailable right now. Please try again.',
            developerDiagnostics: developerDiagnostics,
          );
      }
    }

    if (error is PostgrestException) {
      if (error.code == '23503') {
        return ClinicalErrorMessage(
          message:
              'Your profile is still being prepared. Please try again shortly or contact support.',
          developerDiagnostics: developerDiagnostics,
        );
      }
      return ClinicalErrorMessage(
        message: _messageForArea(context.area),
        developerDiagnostics: developerDiagnostics,
      );
    }

    if (error is StorageException) {
      return ClinicalErrorMessage(
        message:
            'Unable to store this file right now. Please check the file and try again.',
        developerDiagnostics: developerDiagnostics,
      );
    }

    final maybeFunctionStatus = _functionStatus(error);
    if (maybeFunctionStatus != null) {
      if (maybeFunctionStatus == 401) {
        return ClinicalErrorMessage(
          message:
              'Your session has expired. Please sign in again to continue.',
          developerDiagnostics: developerDiagnostics,
        );
      }
      return ClinicalErrorMessage(
        message: _messageForArea(context.area),
        developerDiagnostics: developerDiagnostics,
      );
    }

    if (error is StateError) {
      return ClinicalErrorMessage(
        message: _sanitizeKnownUserMessage(error.message, context),
        developerDiagnostics: developerDiagnostics,
      );
    }

    final errorStr = _diagnostic(error).toLowerCase();

    if (errorStr.contains('unauthorized') ||
        errorStr.contains('invalid auth token') ||
        errorStr.contains('missing authorization')) {
      return ClinicalErrorMessage(
        message: 'Your session has expired. Please sign in again to continue.',
        developerDiagnostics: developerDiagnostics,
      );
    }

    if (errorStr.contains('gemini') ||
        errorStr.contains('v1beta') ||
        errorStr.contains('v1/') ||
        errorStr.contains('{') ||
        errorStr.contains('status:') ||
        errorStr.contains('functionexception') ||
        errorStr.contains('[object object]') ||
        errorStr.contains('bad request')) {
      return ClinicalErrorMessage(
        message: _messageForArea(context.area),
        developerDiagnostics: developerDiagnostics,
      );
    }

    return ClinicalErrorMessage(
      message: _sanitizeKnownUserMessage(_diagnostic(error), context),
      developerDiagnostics: developerDiagnostics,
    );
  }

  static String _diagnostic(Object error) => '$error';

  static int? _functionStatus(Object error) {
    if (!error.runtimeType.toString().toLowerCase().contains('function')) {
      return null;
    }
    try {
      final status = (error as dynamic).status;
      return status is int ? status : int.tryParse('$status');
    } catch (_) {
      return null;
    }
  }

  static String _messageForArea(ClinicalErrorArea area) {
    switch (area) {
      case ClinicalErrorArea.auth:
        return 'Unable to complete authentication right now. Please try again.';
      case ClinicalErrorArea.upload:
      case ClinicalErrorArea.storage:
        return 'Unable to upload this file right now. Please try again.';
      case ClinicalErrorArea.xrayAi:
        return 'Unable to complete the AI analysis right now. Please try again.';
      case ClinicalErrorArea.chatbot:
        return 'VitaGuard AI is having trouble responding right now. Please try again.';
      case ClinicalErrorArea.reports:
        return 'Unable to save this clinical report right now. Please try again.';
      case ClinicalErrorArea.alerts:
        return 'Unable to update clinical alerts right now. Please try again.';
      case ClinicalErrorArea.hardware:
        return 'Unable to load hardware readings right now. Please check the connection.';
      case ClinicalErrorArea.network:
        return 'The network connection appears unstable. Please try again.';
      case ClinicalErrorArea.database:
      case ClinicalErrorArea.unknown:
        return 'Unable to complete this request right now. Please try again.';
    }
  }

  static String _sanitizeKnownUserMessage(
    String message,
    ClinicalErrorContext context,
  ) {
    final trimmed = message.trim();
    final lower = trimmed.toLowerCase();
    if (trimmed.isEmpty ||
        lower.contains('exception') ||
        lower.contains('stack') ||
        lower.contains('supabase') ||
        lower.contains('postgrest') ||
        lower.contains('function') ||
        lower.contains('[object object]') ||
        lower.contains('{') ||
        lower.contains('status:')) {
      return _messageForArea(context.area);
    }
    return trimmed;
  }
}
