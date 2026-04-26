# VitaGuard Alert System Implementation Guide

## Overview

The VitaGuard alert system has been refactored to use **Supabase Realtime Broadcast** as the messaging backbone, with Supabase tables as the durable source of truth. Flutter provides local notifications and platform-specific siren behavior. **No Firebase is used.**

---

## Architecture

### Backend Flow

```
Hardware Device
       ↓
[Telemetry Endpoint] → hardware_telemetry function
       ↓
[Validate & Normalize] → Check for duplicates via source_event_id
       ↓
[Insert into patient_live_vitals] → Store raw metrics
       ↓
[Evaluate Severity] → Build alert candidates (fall, HR, SpO2, temp, etc.)
       ↓
[Deduplicate Alerts] → Check existing unresolved alerts by dedupe_key
       ↓
[Persist to medical_alerts] → Insert or update existing alert
       ↓
[Create medical_alert_deliveries] → Route to companions (all severity) + doctors (critical only)
       ↓
[Broadcast Trigger] → broadcast_medical_alert_changes() fires
       ↓
[Publish to Realtime Topics]:
  - patient:{patientId}:companion-alerts (warning + critical)
  - patient:{patientId}:doctor-critical-alerts (critical only)
```

### Frontend Flow

```
App Launch (MainCompanion / MainDoctor)
       ↓
[Bootstrap AlertCenterProvider]
       ├─ For Companion: alertCenterProvider.bootstrapForCompanion(patientId)
       └─ For Doctor: alertCenterProvider.bootstrapForDoctor([patientIds])
       ↓
[Fetch Bootstrap Data] → Query recent/unresolved alerts from medical_alerts
       ↓
[Subscribe to Realtime] → alertRealtimeService.subscribeForCompanion/Doctor()
       ↓
[Listen to Broadcasts] → onBroadcast(event: 'alert.changed') → Merge into local state
       ↓
[Display Alerts] → AppAlertCard widgets in Companion & Doctor home screens
       ↓
[User Action: Acknowledge] → acknowledgeAlert(alertId) via RPC
       ↓
[Backend Update] → acknowledge_medical_alert() sets acknowledged_at, resolved_at
       ↓
[Broadcast Update] → Trigger fires again, notifies all subscribers
       ↓
[Stop Siren] → Clear notification, invoke stopCriticalAlert() platform method
       ↓
[Resume/Reconnect] → onAppResumed() → _resync() → Fetch new alerts since last sync
```

---

## Database Schema

### Tables Extended

#### `medical_alerts` (Extended)
- `severity` (text): 'warning' | 'critical'
- `source` (text): 'hardware' | 'manual' (source of alert)
- `metrics` (text[]): Array of affected metric names
- `message` (text): Human-readable alert message
- `payload` (jsonb): Full alert data (vitals, device status, etc.)
- `dedupe_key` (text): Unique key for deduplication per patient
- `occurred_at` (timestamptz): When the condition was first detected
- `last_seen_at` (timestamptz): Most recent occurrence timestamp
- `acknowledged_at` (timestamptz): When companion/doctor acknowledged
- `resolved_at` (timestamptz): When alert was fully resolved
- `source_event_id` (text): Hardware source event ID for dedupe

#### `medical_alert_deliveries` (New)
- `id` (uuid): Primary key
- `alert_id` (uuid): Foreign key to medical_alerts
- `recipient_user_id` (uuid): Companion or doctor receiving the alert
- `recipient_role` (text): 'companion' | 'doctor'
- `delivery_status` (text): 'pending' | 'delivered' | 'acknowledged'
- `delivered_at` (timestamptz): When first delivered
- `acknowledged_at` (timestamptz): When recipient acknowledged
- `created_at` (timestamptz): Record creation time
- `updated_at` (timestamptz): Last update time

#### `patient_live_vitals` (Extended)
- `source_event_id` (text): Hardware event ID for deduplication
- **Unique Index**: `(patient_id, source_event_id)` ensures no duplicate vitals from same event

---

## Key Functions & Triggers

### SQL Trigger: `broadcast_medical_alert_changes()`

**When**: Fires after INSERT or UPDATE of severity, metrics, message, payload, acknowledged_at, resolved_at, is_resolved on `medical_alerts`

**Actions**:
1. Builds base payload with alert details
2. Publishes to `patient:{patientId}:companion-alerts` (all subscribers)
3. If critical, also publishes to `patient:{patientId}:doctor-critical-alerts` (doctor only)
4. Event type: `'alert.changed'`

### RPC Function: `acknowledge_medical_alert(p_alert_id uuid)`

**Purpose**: Companion/Doctor acknowledges an alert

**Actions**:
1. Checks authorization (linked companion or assigned doctor)
2. Sets `acknowledged_at` and `resolved_at` to now()
3. Sets `is_resolved = true`
4. Updates `medical_alert_deliveries` for that user to 'acknowledged'
5. Trigger fires → broadcasts update to all subscribers

### RPC Function: `can_receive_medical_alert_broadcast()`

**Purpose**: RLS policy for realtime broadcasts

**Logic**:
- For `patient:{patientId}:companion-alerts`: User must be linked companion or admin
- For `patient:{patientId}:doctor-critical-alerts`: User must be assigned doctor or admin

---

## Alert Severity & Routing

### Alert Type → Severity Mapping

#### CRITICAL (Routed to Companion + Assigned Doctor)
- `FALL_DETECTED`
- `EMERGENCY_BUTTON`
- `EMERGENCY_NO_PULSE`
- `LOW_OXYGEN_CRITICAL` (SpO2 < 89%)
- `RESPIRATORY_CARDIAC_RISK` (SpO2 < 92% AND HR > 120)
- `HIGH_FEVER_CRITICAL` (Temp > 39.5°C)

#### WARNING (Routed to Companion Only)
- `LOW_OXYGEN_WARNING` (SpO2: 89-92%)
- `HEART_RATE_HIGH` (HR > 120)
- `HEART_RATE_LOW` (HR < 60)
- `FEVER_WARNING` (Temp: 38.5-39.5°C)

---

## Deduplication Strategy

### Patient-Level Deduplication

Each alert has a `dedupe_key` (e.g., `"spo2:critical"`, `"bpm:high"`, `"motion:fall-detected"`).

**Logic**:
1. For incoming alert with `dedupe_key`
2. Query for existing **unresolved** alert with same patient + dedupe_key
3. If found: **UPDATE** existing alert's `last_seen_at` and `metrics`
4. If not found: **INSERT** new alert
5. No duplicate notifications are sent for the same alert ID

---

## Flutter Alert System

### Core Files

| File | Purpose |
|------|---------|
| `lib/core/alerts/alert_model.dart` | AppAlert class with factory methods |
| `lib/core/alerts/alert_center_provider.dart` | State management (ChangeNotifier) |
| `lib/core/alerts/alert_realtime_service.dart` | Realtime subscription handling |
| `lib/core/alerts/alert_repository.dart` | Database queries & acknowledgment |
| `lib/core/alerts/alert_notification_service.dart` | Local notifications & siren control |
| `lib/core/alerts/widgets/alert_card.dart` | Alert display widget (compact) |
| `lib/core/alerts/widgets/app_alert_card.dart` | Alert display widget (full) |

### AlertCenterProvider API

```dart
// Bootstrap (call once on app start)
await alertCenterProvider.bootstrapForCompanion(
  patientId: '...uuid...',
  patientName: 'Patient Name',
);

// OR for Doctor
await alertCenterProvider.bootstrapForDoctor(
  patientIds: ['id1', 'id2'],
  patientNamesById: {'id1': 'Patient 1', 'id2': 'Patient 2'},
);

// Properties
List<AppAlert> alerts;  // All alerts (active + resolved)
List<AppAlert> activeAlerts;  // Unresolved only
List<AppAlert> criticalActiveAlerts;  // Critical unresolved only
bool isLoading;
String? error;

// Actions
Future<void> acknowledgeAlert(String alertId);
Future<void> onAppResumed();  // Called on lifecycle resume
```

### AppAlert Data Model

```dart
class AppAlert {
  final String id;  // UUID
  final String patientId;  // Patient UUID
  final String patientName;
  final String alertType;  // e.g., 'FALL_DETECTED'
  final AlertSeverity severity;  // warning | critical
  final List<String> metrics;  // ['SpO2', 'Heart Rate']
  final String message;  // 'Critical fall detected...'
  final String source;  // 'hardware'
  final DateTime occurredAt;
  final DateTime lastSeenAt;
  final Map<String, dynamic> payload;  // Raw telemetry
  final String recipientRole;  // 'companion' | 'doctor'
  final bool isAcknowledged;
  final bool isResolved;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String? dedupeKey;
  
  // Computed properties
  bool get isActive => !isResolved;
  bool get isCritical => severity == AlertSeverity.critical;
}
```

### Realtime Subscription Topics

**For Companion**:
- `patient:{patientId}:companion-alerts` → All severity levels

**For Doctor**:
- `patient:{patientId}:doctor-critical-alerts` → Critical only (one topic per assigned patient)

---

## Notification & Siren Behavior

### Android Implementation
- **Channel**: `vitaguard_warning_alerts` (warning) | `vitaguard_critical_alerts` (critical)
- **Critical Alert**:
  - Looping siren: `assets/sounds/critical_siren.wav`
  - Vibration pattern: 750ms on, 400ms off, repeating
  - Full-screen intent
  - Auto-cancel: false
  - Ongoing: true
- **Warning Alert**: Standard notification

### iOS Implementation
- **Audio Session**: `.playback` with `.duckOthers` option
- **Critical Alert**:
  - Looping siren: `assets/sounds/critical_siren.wav`
  - Haptic vibration: Every 1.8 seconds
  - Highest interruption level
- **Warning Alert**: Standard notification

### Siren Lifecycle
1. **Start**: When critical alert is first presented
2. **Loop**: Continues until stopped
3. **Stop**: When alert is acknowledged OR explicitly dismissed
4. **Platform Method**: `'vitaguard/alerts'` channel
   - `startCriticalAlert()` → Kotlin/Swift
   - `stopCriticalAlert()` → Kotlin/Swift

---

## UI Integration

### Companion Home Screen
- Displays critical alerts strip at top
- Shows up to 3 most recent critical alerts
- Each alert shows: metric name, severity badge, timestamp, message
- **Acknowledge Button**: Stops siren and marks as resolved

### Doctor Home Screen
- Displays top 3 critical alerts for assigned patients
- Shows patient name (to distinguish between patients)
- Severity badge and message
- **Acknowledge Button**: Same as companion

---

## Sync Behavior

### On App Start
1. `MainCompanion.initState()` / `MainDoctor.initState()`
2. Fetch linked patient / assigned patients
3. Call `bootstrapForCompanion()` or `bootstrapForDoctor()`
4. **Step 1**: Fetch recent/unresolved alerts (up to 24h or current unresolved)
5. **Step 2**: Subscribe to realtime broadcast
6. **Step 3**: On subscription success, resync to catch any missed alerts

### On App Resume
1. `didChangeAppLifecycleState(AppLifecycleState.resumed)`
2. Call `alertCenterProvider.onAppResumed()`
3. Resync with `DateTime - 1 minute` to catch missed events

### On Reconnect (Network)
1. `Connectivity` plugin detects connection restored
2. Triggers `_resync()` automatically
3. Fetches alerts newer than `_lastSyncedAt`
4. Merges into local state

---

## Testing

### 1. Manual Hardware Telemetry Test

**POST** to `https://sumgvbdgucrjyiztmzyn.supabase.co/functions/v1/hardware_telemetry`

**Headers**:
```
Authorization: Bearer {jwt_token}  # or leave empty for anon key
X-Hardware-Key: {HARDWARE_API_KEY}
Content-Type: application/json
```

**Payload**:
```json
{
  "device_id": "device-001",
  "patient_id": "550e8400-e29b-41d4-a716-446655440000",
  "source_event_id": "evt-2024-001",
  "timestamp": "2024-04-26T10:30:00Z",
  "vitals": {
    "bpm": 135,
    "spo2": 85,
    "temperature": 39.8
  },
  "motion": {
    "fall_detected": true,
    "acc_z": 20
  },
  "device_status": null
}
```

**Expected Response**:
```json
{
  "success": true,
  "deduplicated": false,
  "vitalsId": "...",
  "alertsProcessed": 3,
  "alertIds": ["...", "...", "..."]
}
```

### 2. Verify Realtime Broadcast

In Flutter:
1. Subscribe to `patient:{patientId}:companion-alerts`
2. Trigger hardware telemetry POST
3. Should receive `'alert.changed'` broadcast with alert data

### 3. Verify Acknowledgment

1. Get alert ID from database
2. Call `acknowledge_medical_alert(alertId)` RPC
3. Check `medical_alerts.acknowledged_at` is set
4. Check `medical_alert_deliveries.acknowledged_at` is set for current user
5. Verify siren stops in app

### 4. End-to-End Test Checklist

- [ ] Hardware sends telemetry with critical condition
- [ ] `medical_alerts` row created with severity='critical'
- [ ] `medical_alert_deliveries` rows created (companion + doctor)
- [ ] Broadcast trigger publishes to both topics
- [ ] Companion app receives alert and displays
- [ ] Doctor app receives alert and displays
- [ ] Siren plays on app for 5+ seconds
- [ ] User taps acknowledge button
- [ ] Siren stops immediately
- [ ] Alert status changes to "ACKNOWLEDGED"
- [ ] Database reflects acknowledged_at and resolved_at

---

## Deployment Checklist

### Backend
- [ ] Apply `supabase/alerting_realtime_alerts.sql` to production database
- [ ] Verify all tables created: `medical_alerts`, `medical_alert_deliveries`
- [ ] Verify all indexes created
- [ ] Verify all RLS policies are active
- [ ] Verify trigger `trg_broadcast_medical_alert_changes` is active
- [ ] Test RPC `acknowledge_medical_alert()` works
- [ ] Set `HARDWARE_API_KEY` environment variable on Supabase
- [ ] Verify hardware_telemetry function is deployed

### Frontend
- [ ] Run `flutter pub get`
- [ ] Verify no compilation errors
- [ ] Test on Android device with notifications enabled
- [ ] Test on iOS device with notifications enabled
- [ ] Verify critical_siren.wav asset is bundled
- [ ] Test realtime connection: Device → Broadcast → App

---

## Known Limitations & Future Improvements

1. **No Geo-routing**: All alerts route by assigned doctor only (not by proximity)
2. **No Email Escalation**: Only in-app alerts, no email backup
3. **No Manual Alert Creation**: Only hardware-generated alerts
4. **No Alert Expiration**: Old alerts remain in database unless manually cleared
5. **No Batching**: Each alert publishes individually (OK for < 100/min)

---

## Troubleshooting

### Alerts Not Appearing

**Companion side**:
1. Check `bootstrapForCompanion(patientId)` was called with correct patient ID
2. Check network connectivity
3. Check realtime subscription status in logs
4. Verify RLS policy allows read access to `medical_alerts`

**Doctor side**:
1. Check assigned patients were fetched correctly
2. Check `bootstrapForDoctor(patientIds)` passed all assigned patient IDs
3. Verify RLS filters to critical severity only

### Siren Not Playing

1. Check `assets/sounds/critical_siren.wav` exists
2. Verify `flutter_local_notifications` initialized correctly
3. Check Android notification channels created
4. Check iOS audio session is configured
5. Verify app has notification permission granted

### Realtime Not Connecting

1. Check Supabase JWT token is valid
2. Check network is connected
3. Check realtime status callback for errors
4. Verify RLS policies allow broadcast receive

---

## References

- **Supabase Realtime**: https://supabase.com/docs/reference/realtime/overview
- **Supabase RLS**: https://supabase.com/docs/guides/auth/row-level-security
- **Flutter Local Notifications**: https://pub.dev/packages/flutter_local_notifications
- **Connectivity Plus**: https://pub.dev/packages/connectivity_plus
