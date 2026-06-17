<p align="center">
  <img src="assets/Logo/Vita%20Guard%202.png" alt="VitaGuard Logo" width="200"/>
</p>

<h1 align="center">VitaGuard</h1>

<p align="center">
  <strong>AI-Powered Remote Health Monitoring System</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.11+-02569B?logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/State%20Management-Riverpod-764ABC?logo=riverpod" alt="Riverpod"/>
  <img src="https://img.shields.io/badge/Supabase-3FCF8E?logo=supabase&logoColor=white" alt="Supabase"/>
  <img src="https://img.shields.io/badge/ESP32-323232?logo=espressif&logoColor=white" alt="ESP32"/>
  <img src="https://img.shields.io/badge/TFLite-FF6F00?logo=tensorflow&logoColor=white" alt="TFLite"/>
  <img src="https://img.shields.io/badge/Drift-blue" alt="Drift"/>
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License"/>
</p>

---

## Overview

VitaGuard is a graduation project that combines a **Flutter mobile application** with **ESP32-based wearable hardware** to create a real-time patient health monitoring ecosystem. The system continuously tracks vital signs — heart rate (BPM), blood oxygen saturation (SpO2), and body temperature — through biomedical sensors (MAX30102, MPU6050, DS18B20) connected to an ESP32 microcontroller. Data is streamed wirelessly to a **Supabase** backend and visualized in the Flutter app with real-time updates, intelligent alerting, and AI-powered chest X-ray analysis.

**Problem being solved:** Traditional health monitoring requires frequent hospital visits and lacks continuous oversight. Patients with chronic conditions, post-surgery recovery needs, or elderly individuals living alone lack a cost-effective, real-time monitoring solution that connects them with doctors, companions, and healthcare facilities. VitaGuard bridges this gap.

**Target users:**
- **Patients** — individuals requiring continuous vital sign monitoring
- **Companions** — family members or caregivers who receive alerts
- **Doctors** — healthcare professionals who review vitals, X-rays, and medical history
- **Facilities** — clinics, labs, and healthcare service providers

---

## Features

### Health Monitoring
- **Real-time vital signs tracking** — live BPM, SpO2, and temperature display via Supabase Realtime subscriptions
- **ESP32 hardware integration** — telemetry ingestion from MAX30102 (heart rate/SpO2), MPU6050 (fall detection), and DS18B20 (temperature) sensors
- **Fall detection** — automatic detection via accelerometer (Z-axis threshold analysis)
- **Device status monitoring** — online/offline status, signal strength, battery level indicators
- **Heart rate ring** — animated circular BPM display with color-coded alert status

### Intelligent Alert System
- **Multi-tier alert severity** — warning vs. critical classification
- **Threshold-based evaluation** — configurable thresholds for heart rate (high/low), SpO2, and temperature
- **Combined risk detection** — respiratory-cardiac distress detection (low SpO2 + high heart rate)
- **45-second cooldown** — rolling window smoothing (last 5 readings) to prevent alert fatigue
- **Realtime delivery** — alerts broadcast to linked companions and assigned doctors via Supabase Realtime
- **Alert acknowledgment workflow** — companions and doctors can acknowledge and resolve alerts
- **Local push notifications** — FlutterLocalNotifications for on-device alerting
- **Alert banner UI** — animated three-state banner (active, pre-alert, normal) with haptic feedback

### AI Chest X-Ray Analysis
- **On-device TFLite inference** — DenseNet121-based binary classifier (Normal vs. Pneumonia)
- **Three-way classification** — Normal, Pneumonia, or Inconclusive (uncertainty band)
- **Calibrated thresholds** — 0.60 pneumonia threshold, 0.45 inconclusive boundary (FDA SaMD-inspired)
- **GPU delegate support** — GPU acceleration with CPU fallback
- **Background isolate preprocessing** — non-blocking UI thread through Flutter compute()
- **Supabase Edge Function fallback** — HuggingFace-based cloud inference alternative
- **Two-phase doctor review** — manual diagnosis checklist (Phase 1) + AI review with confirm/override (Phase 2)
- **Model export pipeline** — Python scripts for fastai-to-ONNX-to-TFLite conversion with parity checking

### Role-Based Multi-User System
- **Patient** — view vitals, medical history, companion code, guidance videos, upload X-rays, chat with doctors
- **Doctor** — view assigned patients' vitals, manage alerts, upload medical reports, perform X-ray review, chat
- **Companion** — linked to a patient, receives alerts, views vitals, manages medical history
- **Facility** — upload lab test reports, manage offers, chat with patients

### Messaging & Communication
- **Multi-role chat** — direct conversations between patients, doctors, companions, and facilities
- **AI Health Chatbot** — Google Gemini/Gemma-powered conversational AI for health queries
- **Message streaming** — real-time message delivery via Supabase Realtime
- **Smart sanitization** — prompt leakage protection and content filtering on both client and server

### Data Management
- **Medical history** — allergies, medications, chronic diseases, surgeries, notes
- **Daily vitals reports** — historical vital sign tracking with dates
- **Medical reports** — doctor-uploaded reports with image attachments
- **Guidance videos** — curated health education video library
- **Offline support** — Drift local database caching and sync queue for offline resilience
- **Connectivity-aware sync** — automatic pending write replay on reconnection

---

## Architecture

VitaGuard follows a **layered architecture** with a strong separation of concerns, leveraging **Riverpod** for dependency injection and state management.

```
Presentation (Widgets/Screens/Controllers)
        |
    Application (Controllers/Providers)
        |
    Domain (Features/Models)
        |
    Data (Repositories/Services)
        |
    Core (Supabase, Drift, AI, Sync, Network)
        |
    Supabase (Database, Realtime, Edge Functions, Storage)
```

### Folder Organization

| Layer | Directory | Responsibility |
|---|---|---|
| **Core** | `lib/core/` | Infrastructure: Supabase client, Drift database, AI inference, alert system, sync, network health, error handling, shared UI utilities |
| **Data** | `lib/data/` | Models (DTOs, enums, serialization) and Repositories (CRUD operations, API abstraction) |
| **Features** | `lib/features/` | Feature-specific logic: chatbot sanitization, companion management, doctor alert evaluation, facility operations, onboarding data, vitals timer services, X-ray view models |
| **Presentation** | `lib/presentation/` | Riverpod controllers, full screens, reusable widgets |
| **App Entry** | `lib/main.dart` | Supabase init, Theme config, AuthGate root widget |

### Design Patterns

- **Repository Pattern** — all data access abstracted behind repository interfaces
- **Singleton Pattern** — SupabaseService and XrayInferenceService
- **Observer Pattern** — Supabase Realtime subscriptions for vitals, alerts, and messages
- **Provider Pattern** — Riverpod for DI and state management with generated providers
- **Notifier Pattern** — Riverpod Notifiers for complex state (auth, chat, alerts)
- **Strategy Pattern** — TFLite on-device vs. Edge Function cloud inference
- **Two-Phase Review Pattern** — mandatory manual + AI review for medical X-rays

### Data Flow

```
ESP32 (MAX30102, MPU6050, DS18B20)
    |
    | HTTP POST (JSON telemetry)
    v
Supabase Edge Function: hardware_telemetry
    |
    |--- Insert into patient_live_vitals
    |--- Evaluate alert conditions (thresholds, combined risks, fall detection)
    |--- Persist alerts in medical_alerts
    |--- Resolve recipients (companions + doctors)
    |--- Upsert medical_alert_deliveries
    |--- Broadcast via Realtime
    v
Flutter App (Realtime subscriptions)
    |
    |--- HardwareScreen: live vitals display
    |--- AlertCenterProvider: alert list management
    |--- AlertNotificationService: local push notifications
    |--- AlertEvaluationEngine: client-side threshold evaluation
```

---

## Technologies Used

### Flutter & Dart Ecosystem
- **Flutter 3.11+** — cross-platform UI framework
- **Dart 3.11+** — programming language
- **flutter_riverpod + riverpod_annotation** — state management with code generation
- **drift + drift_flutter** — local SQLite database with type-safe DAOs
- **flutter_screenutil** — responsive UI scaling
- **flutter_svg** — SVG asset rendering
- **flutter_animate** — declarative animations
- **cached_network_image** — image caching
- **intl** — internationalization and formatting
- **gap** — layout spacing widgets

### Backend & Database
- **Supabase** — backend-as-a-service (PostgreSQL, Auth, Realtime, Storage, Edge Functions)
- **Supabase Realtime** — WebSocket-based realtime data sync
- **Supabase Edge Functions (Deno)** — serverless TypeScript functions
- **PostgreSQL** — relational database with Row-Level Security (RLS)

### AI & Machine Learning
- **tflite_flutter** — on-device TensorFlow Lite inference
- **DenseNet121** — deep learning architecture for X-ray classification
- **ONNX Runtime** — model export and verification pipeline
- **HuggingFace Inference API** — cloud-based X-ray inference fallback
- **Google Gemini/Gemma** — AI chatbot models
- **Fastai** — PyTorch-based training framework

### Hardware Integration
- **ESP32** — microcontroller for sensor data collection and WiFi transmission
- **MAX30102** — pulse oximeter and heart rate sensor
- **MPU6050** — accelerometer and gyroscope for fall detection
- **DS18B20** — digital temperature sensor

### Additional Services
- **FlutterLocalNotifications** — local push notifications
- **shared_preferences** — key-value local storage
- **connectivity_plus** — network connectivity monitoring
- **image_picker** — camera and gallery image selection
- **image** — Dart image processing and decoding
- **url_launcher** — external URL launching
- **logger** — structured logging
- **flutter_md** — Markdown rendering in chat bubbles

---

## Project Structure

```
vitaguard_app/
├── android/                          # Android platform files
├── assets/                           # Static assets
│   ├── Logo/                         # App logos
│   ├── PNG/                          # PNG images
│   ├── SVG/                          # SVG icons
│   ├── cover/                        # Background covers
│   ├── fonts/                        # Custom fonts (WixMadeforDisplay)
│   ├── models/                       # TFLite model (model.tflite)
│   └── sounds/                       # Notification sounds
├── ios/                              # iOS platform files
├── lib/                              # Main application source
│   ├── main.dart                     # App entry point
│   ├── core/                         # Core infrastructure
│   │   ├── ai/                       # X-ray inference service (TFLite)
│   │   ├── alerts/                   # Alert model, service, repository, realtime, UI widgets
│   │   ├── chat/                     # Chat repository and streaming
│   │   ├── errors/                   # Error mapping and clinical error areas
│   │   ├── feedback/                 # Clinical feedback overlay system
│   │   ├── local/                    # Drift database, cache repository, sync queue
│   │   ├── network/                  # Network health monitoring provider
│   │   ├── supabase/                 # Supabase client singleton service
│   │   ├── sync/                     # Offline sync service and connectivity coordinator
│   │   └── utils/                    # Shared widgets (AppColors, buttons, headers, nav bars, etc.)
│   ├── data/                         # Data layer
│   │   ├── models/                   # Data transfer objects and enums
│   │   │   ├── auth/                 # Auth models (UserRole)
│   │   │   ├── chatbot/              # AI chat models (AiConversation, AiMessage)
│   │   │   ├── companion/            # Companion models (LinkedPatientStatus)
│   │   │   ├── doctor/               # Doctor models (VitalAlert, thresholds)
│   │   │   ├── patient/              # Patient models (XRayResult, MedicalHistory)
│   │   │   ├── vitals/               # Vitals models (PatientLiveVitals)
│   │   │   └── xray/                 # X-ray models (TwoPhaseReview)
│   │   └── repositories/             # Data access repositories (auth, ai_chat, companion, doctor, facility, patient, vitals)
│   ├── features/                     # Feature-specific business logic
│   │   ├── chatbot/                  # AI response sanitizer, intent classifier, content normalizer
│   │   ├── companion/                # Companion shell and category data
│   │   ├── doctor/                   # Doctor shell and alert evaluation engine
│   │   ├── facility/                 # Facility shell, reports, offers
│   │   ├── onboarding/               # Onboarding data models
│   │   ├── patient/                  # Patient shell, categories, guidance videos
│   │   ├── vitals/                   # Alert timer service
│   │   └── xray/                     # Two-phase AI review view data
│   └── presentation/                 # UI layer
│       ├── controllers/              # Riverpod state controllers
│       │   ├── auth/                 # AuthController (login, register, logout)
│       │   ├── chatbot/              # AiChatController (conversation management)
│       │   ├── companion/            # CompanionController
│       │   ├── doctor/               # DoctorController
│       │   ├── facility/             # FacilityController
│       │   ├── patient/              # PatientController
│       │   └── vitals/               # VitalsController
│       ├── screens/                  # Full page screens
│       │   ├── splash_screen.dart
│       │   ├── onboarding/           # Onboarding with PageView
│       │   ├── auth/                 # Sign in, role selection, registration forms
│       │   ├── vitals/               # HardwareScreen, MetricCard
│       │   ├── xray/                 # Upload, AI result, doctor review screens
│       │   ├── chatbot/              # AI chat screen
│       │   ├── patient/              # Patient home, chat, medical history, daily report, companion code, videos
│       │   ├── doctor/               # Doctor home, chat, alerts, reports, X-ray review
│       │   ├── companion/            # Companion home, alerts
│       │   └── facility/             # Facility chat, reports, offers
│       └── widgets/                  # Reusable widgets
│           ├── auth/                 # AuthGate, text fields, buttons, dialogs, professional ID picker
│           ├── onboarding/           # Onboarding page, actions
│           ├── chatbot/              # AI message bubble
│           ├── doctor/               # Category grid, alert banner, message bubble
│           ├── facility/             # Message bubble
│           ├── patient/              # Category cards, grid, search, info slider, video cards
│           ├── companion/            # Category grid
│           ├── shared/               # ClinicalCard
│           ├── vitals/               # VitalAlertBanner
│           └── xray/                 # AI diagnosis widgets, heatmaps, review panels, raw viewer
├── scripts/                          # Python model export/verification scripts
├── supabase/                         # Database migrations and edge functions
│   ├── migrations/                   # SQL schema, policies, triggers
│   ├── functions/                    # Deno Edge Functions
│   │   ├── _shared/                  # Shared utilities (CORS, auth, Supabase client, upload)
│   │   ├── ai-chat/                  # Gemini-powered AI chat streaming
│   │   ├── chatbot/                  # Enhanced chatbot with model fallback and quick replies
│   │   ├── generate_companion_code/  # Companion code generation
│   │   ├── hardware_telemetry/       # ESP32 telemetry ingestion and alert evaluation
│   │   ├── review_doctor_verification/ # Admin doctor verification
│   │   ├── review_facility_verification/ # Admin facility verification
│   │   ├── upload_doctor_verification/ # Doctor ID card upload
│   │   ├── upload_lab_offer/         # Facility offer creation
│   │   ├── upload_lab_report/        # Lab test report upload
│   │   ├── upload_medical_record/    # Medical document upload
│   │   ├── upload_xray_result/       # X-ray image and result upload
│   │   └── xray-inference/           # HuggingFace-based X-ray inference
├── test/                             # Unit and widget tests
└── web/                              # Web platform files
```

---

## Screenshots

<p align="center">
  <em>Screenshots coming soon</em>
</p>

<!--
<p align="center">
  <img src="screenshots/splash.png" alt="Splash Screen" width="200"/>
  <img src="screenshots/onboarding.png" alt="Onboarding" width="200"/>
  <img src="screenshots/hardware_screen.png" alt="Vitals Monitoring" width="200"/>
  <img src="screenshots/patient_home.png" alt="Patient Home" width="200"/>
</p>
<p align="center">
  <img src="screenshots/xray_result.png" alt="X-Ray Result" width="200"/>
  <img src="screenshots/doctor_alerts.png" alt="Doctor Alerts" width="200"/>
  <img src="screenshots/ai_chat.png" alt="AI Chat" width="200"/>
  <img src="screenshots/chat.png" alt="Messaging" width="200"/>
</p>
-->

---

## API Integration

### Backend Communication

All backend communication flows through **Supabase** services:

- **Supabase Client SDK** (`supabase_flutter`) — direct database CRUD, authentication, realtime subscriptions, and storage operations
- **Supabase Edge Functions** (Deno/TypeScript) — serverless endpoints for hardware telemetry, X-ray inference, AI chat, file uploads, and administrative operations
- **Supabase Realtime** — WebSocket subscriptions for live vitals, messages, and alert broadcasts
- **Row-Level Security (RLS)** — all database access is protected by PostgreSQL policies enforcing ownership, role-based access, and relationship checks

### Key Endpoints

| Endpoint | Method | Purpose |
|---|---|---|
| `hardware_telemetry` | POST | Ingest ESP32 sensor data, evaluate alerts, persist vitals |
| `xray-inference` | POST | Cloud-based X-ray inference via HuggingFace (fallback) |
| `ai-chat` | POST | Streaming AI chat via Google Gemini |
| `chatbot` | POST | Enhanced chatbot with model fallback and quick replies |
| `generate_companion_code` | GET | Generate unique 6-char companion linking code |
| `upload_*` | POST | File uploads (X-rays, medical records, lab reports, offers) |
| `review_*_verification` | POST | Admin verification of doctors and facilities |

### Data Models

Key database tables (PostgreSQL with RLS):

- `profiles` — user profiles with role (patient/doctor/companion/facility)
- `patients` — patient details, companion code, assigned doctor
- `doctors` — doctor details, verification status, professional ID
- `companions` — companion-to-patient linking
- `facilities` — facility details and verification status
- `patient_live_vitals` — real-time vital sign records from ESP32
- `medical_alerts` — generated alerts with severity, metrics, deduplication
- `medical_alert_deliveries` — per-recipient alert delivery tracking
- `patient_xray_results` — X-ray analysis results with AI predictions
- `patient_medical_history` — patient medical history
- `patient_daily_reports` — daily vital sign summaries
- `ai_conversations` / `ai_messages` — AI chatbot conversation history
- `conversations` / `messages` — human chat messaging system
- `doctor_medical_reports` — doctor-uploaded medical report images
- `facility_tests` / `facility_offers` — facility service data

### Error Handling Strategy

- **Client-side** — `ClinicalErrorContext` categorizes errors by area (auth, upload, xrayAi, chatbot, hardware, etc.), `ErrorMapper` maps Supabase and generic exceptions to user-friendly messages
- **ClinicalFeedbackPanel** — in-app error banners and loading indicators
- **AlertNotificationService** — local push notifications for critical system issues
- **Server-side** — Edge Functions use try-catch with structured JSON error responses
- **Offline resilience** — sync queue captures failed writes for later replay when connectivity returns

---

## State Management

VitaGuard uses **Riverpod** with code generation (`riverpod_annotation` + `riverpod_generator`) for state management.

### Architecture

```
┌────────────────────────────────────────────┐
│              UI Layer (Widgets)             │
│  ref.watch(provider) / ref.read(provider)  │
└────────────────┬───────────────────────────┘
                 │
┌────────────────▼───────────────────────────┐
│          Riverpod Providers                │
│                                            │
│  AsyncNotifierProvider  (complex state)     │
│  FutureProvider        (async data)         │
│  StreamProvider        (realtime data)      │
│  NotifierProvider      (simple state)       │
│  Provider              (DI / singletons)    │
└────────────────┬───────────────────────────┘
                 │
┌────────────────▼───────────────────────────┐
│          Repository Layer                  │
│  Abstracted data access (Supabase + Local) │
└────────────────┬───────────────────────────┘
                 │
┌────────────────▼───────────────────────────┐
│          Data Sources                      │
│  Supabase API  │  Drift Local DB           │
└────────────────────────────────────────────┘
```

### Key Providers

| Provider | Type | Role |
|---|---|---|
| `authControllerProvider` | AsyncNotifier | Auth state, login, registration, logout, session management |
| `aiChatControllerProvider` | Notifier | AI chat conversation, message streaming, intent classification |
| `alertControllerProvider` | Notifier | Alert list, realtime subscriptions, acknowledge/resolve |
| `vitalsControllerProvider` | Notifier | Live vitals state management |
| `patientControllerProvider` | Notifier | Patient data, X-ray results, companion code |
| `doctorControllerProvider` | Notifier | Doctor's assigned patients, daily reports |
| `companionControllerProvider` | Notifier | Companion linking and patient status |
| `facilityControllerProvider` | Notifier | Facility appointments and offers |
| `healthControllerProvider` | Notifier | Network health and AI service status |
| `supabaseServiceProvider` | Provider (keepAlive) | Singleton Supabase client wrapper |
| `vitalsRepositoryProvider` | Provider | Dependency injection for vitals data access |

### Key Design Decisions

- `ref.keepAlive()` on `AuthController` to survive across the entire app session
- Provider invalidation on logout clears all user-scoped state
- `StreamProvider` for realtime subscriptions (vitals, messages, alerts)
- Generated `.g.dart` files for type-safe, boilerplate-free provider definitions

---

## Hardware Integration

### ESP32 Wearable Device

The ESP32 microcontroller serves as the central hub for sensor data collection and wireless transmission.

```
┌─────────────────────────────────────┐
│         ESP32 Microcontroller       │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │ MAX30102 │  │ MPU6050  │        │
│  │ (SpO2 +  │  │ (Fall    │        │
│  │  Heart   │  │  Detect) │        │
│  │  Rate)   │  │          │        │
│  └──────────┘  └──────────┘        │
│                                     │
│  ┌──────────┐                       │
│  │ DS18B20  │   WiFi ───► Internet  │
│  │ (Temp)   │         │            │
│  └──────────┘         │            │
│                       ▼            │
│              Supabase Edge Function │
│              (hardware_telemetry)   │
└─────────────────────────────────────┘
```

### Telemetry Protocol

The ESP32 sends JSON payloads via HTTP POST to the `hardware_telemetry` Edge Function:

```json
{
  "device_id": "vitaguard-001",
  "patient_id": "uuid-here",
  "source_event_id": "unique-event-id",
  "vitals": {
    "bpm": 75,
    "temperature": 36.6,
    "spo2": 98
  },
  "motion": {
    "fall_detected": false,
    "acc_z": 9.8
  },
  "device_status": "Online",
  "timestamp": "2026-06-17T10:30:00Z"
}
```

### Alert Conditions (Server-Side)

| Condition | Threshold | Severity |
|---|---|---|
| SpO2 | < 89% | Critical |
| SpO2 | < 92% | Warning |
| Heart Rate | > 120 bpm or < 60 bpm | Warning |
| Temperature | > 39.5°C | Critical |
| Temperature | > 38.5°C | Warning |
| SpO2 < 92% + HR > 120 | Combined risk | Critical |
| Fall detected (acc_z > 15 or < 2) | — | Critical |
| Device status (FALL_DETECTED, EMERGENCY_BUTTON, EMERGENCY_NO_PULSE) | — | Critical |

---

## Installation

### Prerequisites

- Flutter SDK 3.11+ ([install guide](https://docs.flutter.dev/get-started/install))
- Dart 3.11+
- A Supabase account ([supabase.com](https://supabase.com))
- Android Studio / Xcode for device builds

### Setup Steps

1. **Clone the repository**

   ```bash
   git clone https://github.com/youssifmostafa798-art/vitaguard_app.git
   cd vitaguard_app
   ```

2. **Install Flutter dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Supabase**

   Create a Supabase project and configure the database schema:

   ```bash
   # Apply the consolidated schema
   psql -h your-supabase-host -d postgres -U postgres -f supabase/setup_consolidated.sql
   
   # Apply schema updates
   psql -h your-supabase-host -d postgres -U postgres -f supabase/schema_update.sql
   
   # Apply AI chat schema
   psql -h your-supabase-host -d postgres -U postgres -f supabase/ai_chat.sql
   
   # Apply alerting schema
   psql -h your-supabase-host -d postgres -U postgres -f supabase/alerting_realtime_alerts.sql
   
   # Apply medical reports schema
   psql -h your-supabase-host -d postgres -U postgres -f supabase/add_doctor_medical_reports.sql
   
   # Apply RLS policies
   psql -h your-supabase-host -d postgres -U postgres -f supabase/policies.sql
   
   # Apply storage policies
   psql -h your-supabase-host -d postgres -U postgres -f supabase/storage_policies.sql
   
   # Apply companion linking function
   psql -h your-supabase-host -d postgres -U postgres -f supabase/link_companion.sql
   
   # Apply direct conversation function
   psql -h your-supabase-host -d postgres -U postgres -f supabase/ensure_direct_doctor_conversation.sql
   ```

4. **Update Supabase credentials**

   Open `lib/main.dart` and update the Supabase URL and anon key:

   ```dart
    await Supabase.initialize(
    url: 'https://sumgvbdgucrjyiztmzyn.supabase.co',
    anonKey: 'sb_publishable_mn_LuYvFSEJBx4Kqt07Xpg_6mHktGkV',
  );
   ```

5. **Deploy Edge Functions** (requires Supabase CLI)

   ```bash
   supabase login
   supabase functions deploy hardware_telemetry
   supabase functions deploy ai-chat
   supabase functions deploy chatbot
   supabase functions deploy generate_companion_code
   supabase functions deploy xray-inference
   supabase functions deploy upload_xray_result
   supabase functions deploy upload_medical_record
   supabase functions deploy upload_doctor_verification
   supabase functions deploy upload_lab_report
   supabase functions deploy upload_lab_offer
   supabase functions deploy review_doctor_verification
   supabase functions deploy review_facility_verification
   ```

6. **Set environment secrets**

   ```bash
   supabase secrets set SUPABASE_URL=your-url
   supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
   supabase secrets set HARDWARE_API_KEY=your-hardware-key
   supabase secrets set HF_TOKEN=your-huggingface-token
   supabase secrets set GEMINI_API_KEY=your-gemini-api-key
   ```

7. **Run the app**

   ```bash
   flutter run
   ```

### ESP32 Setup

1. Flash the ESP32 firmware (available in the hardware repository)
2. Configure WiFi credentials
3. Set the Supabase Edge Function URL and hardware API key
4. Connect sensors: MAX30102 (I2C), MPU6050 (I2C), DS18B20 (OneWire)
5. Power on the device

---

## Dependencies

### Core Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | 3.3.1 | State management and dependency injection |
| `riverpod_annotation` | 4.0.2 | Riverpod code generation annotations |
| `supabase_flutter` | 2.5.6 | Supabase backend client (Auth, Database, Realtime, Storage) |
| `drift` | 2.18.0 | Local SQLite database with type-safe queries |
| `drift_flutter` | 0.2.0 | Flutter-specific Drift configuration |
| `tflite_flutter` | 0.12.1 | On-device TensorFlow Lite inference |

### UI & Utilities

| Package | Version | Purpose |
|---|---|---|
| `flutter_screenutil` | 5.9.3 | Responsive screen adaptation |
| `flutter_svg` | 2.2.3 | SVG asset rendering |
| `flutter_animate` | 4.5.2 | Declarative widget animations |
| `lucide_icons` | 0.257.0 | Open-source icon set |
| `cached_network_image` | 3.4.1 | Remote image caching |
| `gap` | 3.0.1 | Gap/sizedbox shorthand |
| `intl` | 0.20.2 | Date formatting and localization |
| `url_launcher` | 6.1.10 | External URL and deep link launching |
| `flutter_md` | 0.0.8 | Markdown rendering in chat |

### Data & Networking

| Package | Version | Purpose |
|---|---|---|
| `connectivity_plus` | 7.0.0 | Network connectivity monitoring |
| `shared_preferences` | 2.5.5 | Key-value local persistence |
| `image_picker` | 1.1.2 | Camera and gallery image selection |
| `image` | 4.5.0 | Image decoding and processing |
| `cross_file` | 0.3.5 | Cross-platform file abstraction |

### Notifications & Feedback

| Package | Version | Purpose |
|---|---|---|
| `flutter_local_notifications` | 21.0.0 | Local push notification display |
| `logger` | 2.5.0 | Structured debug logging |

### Serialization & Code Generation

| Package | Version | Purpose |
|---|---|---|
| `freezed` | 3.2.5 | Immutable data class generation |
| `freezed_annotation` | 3.1.0 | Freezed annotations |
| `json_annotation` | 4.11.0 | JSON serialization annotations |
| `json_serializable` | 6.13.0 | JSON code generation |
| `build_runner` | any | Code generation orchestrator |
| `drift_dev` | any | Drift database code generation |
| `riverpod_generator` | any | Riverpod provider code generation |

---

## Future Improvements

Based on the current implementation, planned enhancements include:

1. **Wearable device ecosystem expansion** — support for additional sensors (blood pressure, ECG, glucose monitoring)
2. **Advanced analytics dashboard** — historical trends, predictive health scoring, and anomaly detection using ML
3. **Offline-first architecture** — fully operational offline mode with intelligent conflict resolution
4. **Multi-language support** — localization for Arabic, French, and other languages (RTL support)
5. **Appointment scheduling** — calendar integration for doctor appointments and facility visits
6. **Emergency services integration** — direct SOS alerts to nearby hospitals and ambulance services
7. **Medication reminders** — smart pill reminders with adherence tracking
8. **Telemedicine video calls** — in-app video consultation with doctors
9. **Health reports PDF export** — shareable medical reports with QR code verification
10. **Voice commands** — hands-free operation for elderly and disabled users
11. **Smartwatch companion app** — lightweight wearable OS app for Apple Watch and Wear OS
12. **Advanced AI models** — multi-disease classification (tuberculosis, lung cancer, COVID-19)
13. **Blockchain medical records** — tamper-proof health data storage and sharing
14. **Multi-patient support for companions** — caregivers managing multiple dependents
15. **Progressive Web App (PWA)** — web-based version for non-mobile users

---

## Contributors

- **Ahmed Mekawi** — AI/ML engineer, Python model export pipeline, Edge Functions development, and database schema design
- *Your Name Here* — Flutter application architecture, UI/UX design, state management, and hardware integration

---

## License

```
MIT License

Copyright (c) 2026 VitaGuard

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
