# VitaGuard Alert System - Deployment & Setup Guide

## Prerequisites

- Supabase project already set up with auth, profiles, patients, doctors, companions tables
- Deno functions already deployed (hardware_telemetry)
- Flutter app with Riverpod provider setup

## Step 1: Apply SQL Migration to Supabase

### Option A: Using Supabase Dashboard

1. Go to **SQL Editor** in Supabase Dashboard
2. Click **New Query**
3. Copy entire content of `supabase/alerting_realtime_alerts.sql`
4. Paste into query editor
5. Click **Run**
6. Verify success (no errors)

### Option B: Using Supabase CLI

```bash
cd supabase
supabase db push  # This will apply all migrations in order
```

### Verification Steps

After applying migration, run these queries in SQL Editor:

```sql
-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name IN ('medical_alerts', 'medical_alert_deliveries');

-- Check columns
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'medical_alerts' 
ORDER BY column_name;

-- Check trigger exists
SELECT trigger_name FROM information_schema.triggers 
WHERE trigger_name = 'trg_broadcast_medical_alert_changes';

-- Check RLS is enabled
SELECT * FROM pg_tables WHERE tablename = 'medical_alerts';

-- Check function exists
SELECT routine_name FROM information_schema.routines 
WHERE routine_name = 'acknowledge_medical_alert';
```

## Step 2: Configure Environment Variables

### Backend

**Supabase Function** (`supabase/functions/hardware_telemetry`):

1. Go to **Functions** in Supabase Dashboard
2. Select `hardware_telemetry`
3. Click **Settings**
4. Add secret:
   - **Key**: `HARDWARE_API_KEY`
   - **Value**: Generate a strong random string (at least 32 chars)
   ```bash
   openssl rand -base64 32
   ```
5. Save

### Frontend

No secrets needed (uses Supabase anon key from main.dart).

Verify in `lib/main.dart`:
```dart
await Supabase.initialize(
  url: 'https://sumgvbdgucrjyiztmzyn.supabase.co',
  anonKey: 'sb_publishable_mn_LuYvFSEJBx4Kqt07Xpg_6mHktGkV',
);
```

## Step 3: Initialize Flutter Alert System

### In main.dart (Already Done)

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: '...',
    anonKey: '...',
  );
  
  // Initialize Alert Notifications (handles Android/iOS setup)
  await AlertNotificationService.instance.initialize();
  
  runApp(const ProviderScope(child: MyApp()));
}
```

### In MainCompanion (Already Done)

```dart
Future<void> _initializeCompanionContext() async {
  await ref.read(companionProvider).fetchPatientStatus();
  _bootstrapAlertCenter(ref.read(companionProvider).patientStatus);
}

void _bootstrapAlertCenter(LinkedPatientStatus? patientStatus) {
  if (patientStatus == null) return;
  
  unawaited(
    ref.read(alertCenterProvider).bootstrapForCompanion(
      patientId: patientStatus.patientId,
      patientName: patientStatus.name,
    ),
  );
}
```

### In MainDoctor (Already Done)

```dart
Future<void> _initializeDoctorContext() async {
  await ref.read(doctorProvider).fetchAssignedPatients();
  _bootstrapAlertCenter(ref.read(doctorProvider).assignedPatients);
}

void _bootstrapAlertCenter(List<dynamic> assignedPatients) {
  final patientIds = assignedPatients
      .map((p) => p['patient_id']?.toString() ?? '')
      .where((id) => id.isNotEmpty)
      .toList()
      ..sort();
  
  if (patientIds.isEmpty) return;
  
  final patientNames = <String, String>{};
  for (final patient in assignedPatients) {
    final id = patient['patient_id']?.toString() ?? '';
    final name = patient['name']?.toString().trim();
    if (id.isNotEmpty && name != null && name.isNotEmpty) {
      patientNames[id] = name;
    }
  }
  
  unawaited(
    ref.read(alertCenterProvider).bootstrapForDoctor(
      patientIds: patientIds,
      patientNamesById: patientNames,
    ),
  );
}
```

## Step 4: Test Deployment

### 4.1 Database Connectivity

```dart
// In any screen, add this test:
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> testDatabaseConnection() async {
  try {
    final result = await Supabase.instance.client
        .from('medical_alerts')
        .select('count', const FetchOptions(head: true))
        .limit(1);
    
    print('✅ Database connection OK');
  } catch (e) {
    print('❌ Database error: $e');
  }
}
```

### 4.2 RLS Policies

```dart
// This will fail if RLS is too restrictive
Future<void> testRLSPermissions() async {
  try {
    final result = await Supabase.instance.client
        .from('medical_alerts')
        .select('id')
        .limit(1);
    
    print('✅ RLS allows SELECT');
  } catch (e) {
    print('❌ RLS blocks SELECT: $e');
  }
}
```

### 4.3 Realtime Connection

```dart
// This will fail if realtime is not configured
Future<void> testRealtimeConnection() async {
  final client = Supabase.instance.client;
  final channel = client.channel('test-topic');
  
  channel.on(
    RealtimeListenTypes.broadcast,
    event: 'test-event',
    callback: (payload) {
      print('✅ Realtime received: $payload');
    },
  );
  
  await channel.subscribe();
  
  // Give it 2 seconds to connect
  await Future.delayed(const Duration(seconds: 2));
  
  print('Realtime subscription status: ${channel.status}');
}
```

### 4.4 Platform Notifications

```dart
// Test Android/iOS notification permission
Future<void> testNotificationSetup() async {
  await AlertNotificationService.instance.initialize();
  print('✅ Notifications initialized');
  
  // Try to show a test notification
  final testAlert = AppAlert(
    id: 'test-alert',
    patientId: 'test-patient',
    patientName: 'Test Patient',
    alertType: 'TEST_ALERT',
    severity: AlertSeverity.critical,
    metrics: ['Test'],
    message: 'This is a test alert',
    source: 'test',
    occurredAt: DateTime.now(),
    lastSeenAt: DateTime.now(),
    payload: {},
    recipientRole: 'companion',
    isAcknowledged: false,
    isResolved: false,
  );
  
  await AlertNotificationService.instance.presentAlert(testAlert);
  print('✅ Test notification displayed');
}
```

## Step 5: Grant Permissions (Platform-Specific)

### Android (`android/app/build.gradle.kts`)

Should have:
```kotlin
android {
    compileSdk 34
    
    defaultConfig {
        targetSdk 34
        minSdk 21  // Required for health data APIs
    }
}
```

Manifest permissions (should be auto-generated by `flutter_local_notifications`):
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.BODY_SENSORS" />
```

### iOS (`ios/Podfile`)

In Podfile:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    # No special settings needed for notifications
  end
end
```

Ensure `ios/Runner/Info.plist` has:
```xml
<key>NSBonjourServices</key>
<array>
  <string>_flutter_devtools</string>
</array>
```

## Step 6: Build and Deploy

### Android APK

```bash
cd /path/to/vitaguard_app
flutter clean
flutter pub get
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk
```

### iOS IPA

```bash
flutter clean
flutter pub get
flutter build ios --release
# Then open in Xcode to sign and archive
```

### Web (Optional, won't show siren)

```bash
flutter build web --release
# Deploy build/web folder to hosting
```

## Step 7: Manual Testing Checklist

### Test Data Setup

1. Create test patient user
2. Create test companion user, link to patient
3. Create test doctor user, assign patient
4. Get their UUIDs

### Test Scenario 1: Critical Alert

```bash
curl -X POST https://sumgvbdgucrjyiztmzyn.supabase.co/functions/v1/hardware_telemetry \
  -H "Authorization: Bearer your_jwt_token" \
  -H "X-Hardware-Key: your_hardware_api_key" \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "test-device",
    "patient_id": "patient-uuid-here",
    "source_event_id": "test-evt-001",
    "vitals": {
      "spo2": 85,
      "bpm": 130,
      "temperature": 39.8
    },
    "device_status": null,
    "timestamp": "2024-04-26T12:00:00Z"
  }'
```

**Expected**:
- API returns 200 with alert IDs
- Database: `medical_alerts` row created with severity='critical'
- Database: `medical_alert_deliveries` rows created for companion + doctor
- Companion app: Sees alert + siren plays
- Doctor app: Sees alert + siren plays
- Database: `acknowledged_at` is NULL initially

### Test Scenario 2: Acknowledge Alert

In Supabase SQL Editor:
```sql
SELECT id FROM medical_alerts 
WHERE patient_id = 'patient-uuid-here' 
ORDER BY created_at DESC 
LIMIT 1;
```

Copy alert ID, then:

```dart
// In companion/doctor app, click acknowledge button
ref.read(alertCenterProvider).acknowledgeAlert('alert-uuid-here');
```

**Expected**:
- Siren stops immediately
- UI shows "ACKNOWLEDGED" badge
- Database: `medical_alerts.acknowledged_at` is now set
- Database: `medical_alerts.resolved_at` is now set
- Database: `medical_alert_deliveries.acknowledged_at` is now set
- Realtime broadcast sent to all subscribers

### Test Scenario 3: Resync on Reconnect

1. Open companion app
2. See active alerts (or create new ones)
3. Turn off WiFi + mobile data
4. Alert status shouldn't change locally
5. Turn on connectivity
6. App should resync and fetch any new alerts
7. New alerts should appear

### Test Scenario 4: Companion-Only vs Doctor-Only

**Warning Alert** (only companion):
```json
{
  "device_id": "test",
  "patient_id": "patient-uuid",
  "source_event_id": "test-002",
  "vitals": {
    "bpm": 70,
    "spo2": 94,
    "temperature": 38.6
  }
}
```

**Expected**:
- Companion app: Shows WARNING alert
- Doctor app: No alert shown (warnings are companion-only)

**Critical Alert** (companion + doctor):
```json
{
  "device_id": "test",
  "patient_id": "patient-uuid",
  "source_event_id": "test-003",
  "motion": {
    "fall_detected": true
  }
}
```

**Expected**:
- Companion app: Shows CRITICAL alert
- Doctor app: Shows CRITICAL alert
- Both play siren

## Troubleshooting Deployment

### Issue: Alerts not appearing in Companion/Doctor

**Check**:
1. `AlertCenterProvider.bootstrapForCompanion/Doctor()` was called ✓
2. Patient/Doctor relationship is correct in database ✓
3. Realtime subscription status is 'subscribed' (check logs)
4. RLS policies allow read access ✓

**Fix**:
- Restart app
- Check auth token is valid
- Verify patient_id/doctor_id format (should be UUID)

### Issue: Siren not playing

**Check**:
1. Notification permission granted on device
2. Device is not on silent mode
3. `alert.isCritical` is true
4. `critical_siren.wav` asset is bundled

**Fix**:
- Grant notification permission in app settings
- Test with `AlertNotificationService.instance.presentAlert(alert)`
- Check logcat/Xcode for platform errors

### Issue: Realtime not connecting

**Check**:
1. Network connectivity is active
2. Supabase JWT token is valid
3. RLS policy `can_receive_medical_alert_broadcast()` allows user
4. Topic name is correct (`patient:uuid:companion-alerts`)

**Fix**:
- Refresh auth token: `await Supabase.instance.client.auth.refreshSession()`
- Check `channel.status` in logs
- Try unsubscribing/resubscribing

### Issue: Duplicate alerts appearing

**Check**:
1. `source_event_id` is unique per hardware event
2. Dedupe query finds existing unresolved alert
3. UPDATE logic correctly updates `last_seen_at`

**Fix**:
- Verify hardware sends unique `source_event_id` for each event
- Manual fix: Mark duplicate as resolved in database

## Next Steps

1. **Load Testing**: Simulate 100+ alerts/minute to test throughput
2. **Geo-Location**: Add location-based doctor routing for nearest doctor
3. **Manual Alerts**: Allow companions to manually trigger SOS alerts
4. **Email Escalation**: If alert not acknowledged in 5 min, send email to doctor
5. **Alert History**: Archive alerts older than 30 days
6. **Batch Processing**: Combine multiple alerts into single broadcast

---

**Document Version**: 1.0  
**Last Updated**: 2024-04-26  
**Maintainer**: VitaGuard Team
