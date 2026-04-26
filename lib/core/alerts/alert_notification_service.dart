import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vitaguard_app/core/alerts/alert_model.dart';

class AlertNotificationService {
  AlertNotificationService._();

  static final AlertNotificationService instance = AlertNotificationService._();

  static const MethodChannel _platformChannel = MethodChannel(
    'vitaguard/alerts',
  );

  static const _warningChannelId = 'vitaguard_warning_alerts';
  static const _criticalChannelId = 'vitaguard_critical_alerts';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _activeCriticalAlertId;

  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      _initialized = true;
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );

    await _notifications.initialize(
      settings: InitializationSettings(android: androidSettings, iOS: darwinSettings),
    );

    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  Future<void> presentAlert(AppAlert alert) async {
    await initialize();
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    if (alert.isResolved) {
      await clearAlert(alert);
      return;
    }

    final details = NotificationDetails(
      android: _androidDetailsFor(alert),
      iOS: _darwinDetailsFor(alert),
    );

    await _notifications.show(
      id: _notificationIdFor(alert),
      title: _titleFor(alert),
      body: _bodyFor(alert),
      notificationDetails: details,
      payload: alert.id,
    );

    if (alert.isCritical && _activeCriticalAlertId != alert.id) {
      _activeCriticalAlertId = alert.id;
      await _invokePlatformMethod('startCriticalAlert');
    }
  }

  Future<void> clearAlert(AppAlert alert) async {
    await initialize();
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    await _notifications.cancel(id: _notificationIdFor(alert));
    if (_activeCriticalAlertId == alert.id) {
      _activeCriticalAlertId = null;
      await _invokePlatformMethod('stopCriticalAlert');
    }
  }

  Future<void> clearAll() async {
    await initialize();
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    _activeCriticalAlertId = null;
    await _notifications.cancelAll();
    await _invokePlatformMethod('stopCriticalAlert');
  }

  AndroidNotificationDetails _androidDetailsFor(AppAlert alert) {
    if (alert.isCritical) {
      return const AndroidNotificationDetails(
        _criticalChannelId,
        'Critical Alerts',
        channelDescription: 'Urgent VitaGuard patient alerts',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        ongoing: true,
        autoCancel: false,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('critical_siren'),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );
    }

    return const AndroidNotificationDetails(
      _warningChannelId,
      'Warning Alerts',
      channelDescription: 'Non-critical VitaGuard patient alerts',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.status,
      playSound: true,
      enableVibration: false,
      audioAttributesUsage: AudioAttributesUsage.notification,
    );
  }

  DarwinNotificationDetails _darwinDetailsFor(AppAlert alert) {
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: alert.isCritical
          ? InterruptionLevel.timeSensitive
          : null,
    );
  }

  String _titleFor(AppAlert alert) {
    final prefix = alert.isCritical ? 'Critical Alert' : 'Warning Alert';
    return '$prefix - ${alert.patientName}';
  }

  String _bodyFor(AppAlert alert) {
    final metric = alert.metricLabel.trim();
    if (metric.isEmpty) return alert.message;
    return '$metric: ${alert.message}';
  }

  int _notificationIdFor(AppAlert alert) {
    return alert.id.hashCode & 0x7fffffff;
  }

  Future<void> _invokePlatformMethod(String method) async {
    try {
      await _platformChannel.invokeMethod<void>(method);
    } catch (_) {
      // Native siren and vibration are best effort.
    }
  }
}
