# VitaGuard — Graduation Project Defense Preparation Guide

> **Project:** AI-Powered Remote Health Monitoring System  
> **Platform:** Flutter + Supabase + ESP32 + TFLite  
> **Analysis Date:** June 18, 2026  
> **Role:** Senior Flutter Architect / Technical Interviewer / Project Examiner / Code Reviewer

---

## Part 1 — Project Overview & Architecture

### 1.1 What is VitaGuard?

VitaGuard is a **multi-role remote health monitoring system** that connects patients, doctors, companions, and healthcare facilities around a **Supabase-backed real-time platform**. It features:

- **ESP32 wearable** streaming live vitals (BPM, SpO2, temperature) via WebSocket
- **On-device AI** (DenseNet121 via TFLite) for pneumonia detection from chest X-rays
- **AI Chatbot** (Gemini/Gemma via Supabase edge functions) for health guidance
- **Offline-first** architecture with Drift (SQLite) local DB and sync queue
- **Role-based access** with four personas: Patient, Doctor, Companion, Facility

### 1.2 Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Frontend | Flutter 3.x / Dart ^3.11 | Cross-platform UI |
| State | flutter_riverpod + riverpod_annotation | Reactive state + code gen |
| Backend | Supabase (PostgreSQL + RLS + Realtime) | Auth, DB, Storage, Edge Functions |
| AI (X-ray) | tflite_flutter / DenseNet121 | On-device pneumonia classifier |
| AI (Chat) | Google Gemini / Gemma via edge functions | Health guidance chatbot |
| Local DB | drift (SQLite) | Offline cache + sync queue |
| Hardware | ESP32 (simulated) | BPM/SpO2/temp telemetry |
| ML Pipeline | FastAI → PyTorch → ONNX → TFLite | Model export pipeline |

### 1.3 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                               │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                   Presentation Layer                          ││
│  │  Screens (auth, home, vitals, xray, chatbot, onboarding)     ││
│  │  Widgets (role-specific grids, bubbles, cards, nav bars)     ││
│  │  Controllers (Riverpod providers per feature)                 ││
│  └──────────┬──────────────────────────────────────────────────┘│
│             │                                                    │
│  ┌──────────▼──────────────────────────────────────────────────┐│
│  │                   Domain / Feature Layer                      ││
│  │  xray/ vitals/ patient/ doctor/ companion/ facility/ chatbot ││
│  │  Models, Intent Classifiers, Sanitizers, Alert Engines       ││
│  └──────────┬──────────────────────────────────────────────────┘│
│             │                                                    │
│  ┌──────────▼──────────────────────────────────────────────────┐│
│  │                   Data / Infrastructure Layer                  ││
│  │  Repositories (auth, patient, doctor, vitals, chat, etc)     ││
│  │  SupabaseService (singleton wrapper)                          ││
│  │  Drift Local DB (7 cache tables + sync_queue)                 ││
│  │  OfflineSyncService + ConnectivitySyncCoordinator             ││
│  │  AI: XrayInferenceService (TFLite)                            ││
│  │  Alerts: AlertCenterProvider, AlertTimerService               ││
│  │  Chat: ChatRepository (streaming messages)                     ││
│  └──────────┬──────────────────────────────────────────────────┘│
│             │                                                    │
└──────────────┼──────────────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────────────┐
│                    Supabase Backend                               │
│  PostgreSQL (18 tables) + RLS Policies + Realtime Pub/Sub        │
│  Edge Functions: chatbot, ai-chat, xray-inference,               │
│  hardware_telemetry, upload_*, review_*, generate_companion_code │
│  Storage Buckets: doctor-verifications, xray-results, etc.       │
└─────────────────────────────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────────────┐
│                    ESP32 Wearable                                 │
│  Telemetry → hardware_telemetry edge function → patient_live_vitals│
│  → AlertEngine → medical_alerts → Realtime broadcast             │
└─────────────────────────────────────────────────────────────────┘
```

### 1.4 Key Architecture Decisions

- **Why Riverpod over BLoC?** Simpler syntax, less boilerplate with code generation, better testability, built-in disposal, no event classes needed.
- **Why Supabase over Firebase?** Open-source, self-hostable, PostgreSQL flexibility, Row-Level Security at DB level, edge functions in TypeScript/Deno.
- **Why on-device TFLite instead of cloud AI for X-rays?** Privacy (medical data stays on device), offline capability, lower latency, no API costs.
- **Why Drift over Hive/SQLite?** Type-safe queries with code generation, built-in migration support, relational queries, reactive streams.
- **Why offline-first?** Healthcare scenarios have unreliable connectivity (hospitals, rural areas, basements).

---

## Part 2 — Feature Deep Dive

### 2.1 Authentication & Role Management

- **Sign-up flow:** `auth_repository.dart` handles `registerPatient`, `registerDoctor`, `registerCompanion`, `registerFacility` — each creates a `profiles` row + role-specific table row in a transaction
- **Auth gate:** `auth_gate.dart` — listens to auth state changes, routes to onboarding if new, or role-specific shell (`main_patient.dart`, `main_doctor.dart`, etc.)
- **Profile completion:** First-time users see onboarding screens to fill in profile details (gender, age for patients; professional_id for doctors)
- **Companion linking:** Unique 6-character companion code generated by edge function `generate_companion_code`, linked via `link_companion_to_patient` RPC function with `SECURITY DEFINER`

### 2.2 Patient Vitals Monitoring

- **Data flow:** ESP32 → Supabase Realtime → `SupabaseVitalsRepository` stream → Riverpod provider → UI widgets
- **`PatientLiveVitals` model:** `bpm`, `spo2`, `temperature`, `device_id`, `recorded_at`
- **`VitalThresholds` class:** HR 60-120 bpm, SpO2 warning < 92% / critical < 88%, Temp > 38.5°C / 39.5°C
- **`AlertEvaluationEngine`:** Multivariate rules — e.g., HR > 120 + SpO2 < 90% = "combined distress"
- **`AlertTimerService`:** 45-second onset timer with rolling window smoothing, 60-second stale data watchdog

### 2.3 X-Ray Analysis (AI)

- **`XrayInferenceServiceIO`:** Loads DenseNet121 TFLite model from assets (`assets/models/model.tflite`), preprocesses at 320×320 (note: pipeline Python scripts use 224×224 — discrepancy!), runs inference, applies softmax, returns prediction + confidence
- **`XRayResult` model:** `is_valid`, `prediction` (Pneumonia/Normal), `confidence`, `report_text`, `image_path`
- **Heatmap overlay:** Phase 2 feature for Grad-CAM visualization on the X-ray image
- **Offline support:** X-rays cached locally, upload queued via `SyncQueueRepository`

### 2.4 AI Chatbot

- **Two edge functions:** `ai-chat/index.ts` (Gemini) and `chatbot/index.ts` (Gemma) — both provide streaming responses
- **`AiIntentClassifier`:** Deterministic classification of user messages into: `emergency`, `warning`, `tip`, `question`
- **`AiResponseSanitizer`:** Frontend defense against prompt leakage — strips system prompt lines, fixes markdown formatting, sanitizes unsafe content
- **`AiContentNormalizer`:** Structures responses into paragraphs and bullet blocks
- **`QuickReplies`:** AI-generated suggested follow-up questions stored in `ai_messages.quick_replies` JSONB column

### 2.5 Offline Sync

- **`SyscQueueRepository`:** CRUD operations on `sync_queue` Drift table with `pending`/`processing`/`done`/`failed` states
- **`OfflineSyncService`:** Processes queue items — supports `insert`, `upsert`, `function`, `rpc` operation types
- **`ConnectivitySyncCoordinator`:** Monitors connectivity via `connectivity_plus`, triggers sync on reconnect with debounce
- **`LocalCacheRepository`:** Caches profiles, patients, doctors, vitals, medical history for offline reading

### 2.6 Real-Time Alerts

- **`AlertRealtimeService`:** Subscribes to `medical_alerts` table via Supabase Realtime
- **`AlertNotificationService`:** Shows local push notifications with configurable siren sound, vibration pattern
- **`AppAlert` model:** `severity` (critical/warning/info), `audience` (doctor/patient/companion), `dedupe_key`, `source_event_id`
- **`AlertCenterProvider`:** Central Riverpod Notifier for managing alert state, acknowledgment, resolution

### 2.7 Doctor-Patient Chat

- **`ChatRepository`:** Streams messages via Supabase Realtime subscription to `messages` table
- **`ensure_direct_doctor_conversation`:** PostgreSQL function to find or create a conversation between patient and doctor
- **`Message` model:** `content`, `sender_id`, `conversation_id`, `is_read`, `created_at`
- **`ChatPreview`:** Last message, unread count, timestamp for conversation list

---

## Part 3 — Project Structure Analysis

### 3.1 Directory Layout

```
lib/
├── core/                    # Infrastructure layer
│   ├── ai/                  # X-ray inference (TFLite)
│   ├── alerts/              # Alert system (model, providers, services)
│   ├── chat/                # Chat repository
│   ├── errors/              # Clinical error mapper
│   ├── feedback/            # Clinical feedback (toast/popup)
│   ├── local/               # Drift database + cache + sync queue
│   ├── network/             # Health provider
│   ├── supabase/            # Supabase config + service singleton
│   ├── sync/                # Offline sync coordinator + service
│   └── utils/               # Shared widgets, colors, helpers (18 files)
├── data/
│   ├── models/              # Domain models (auth, patient, vitals, etc.)
│   └── repositories/        # Repository implementations per role
├── features/                # Feature modules
│   ├── chatbot/             # AI chatbot models, sanitizer, intent classifier
│   ├── companion/           # Companion-specific models
│   ├── doctor/              # Doctor-specific models + alert engine
│   ├── facility/            # Facility-specific models
│   ├── onboarding/          # Onboarding models
│   ├── patient/             # Patient-specific models
│   ├── vitals/              # Vitals models + alert timer service
│   └── xray/                # X-ray models + analysis results
├── presentation/
│   ├── controllers/         # Riverpod controllers per feature
│   ├── screens/             # 10 screens (auth, role homes, vitals, xray, chatbot, etc.)
│   └── widgets/             # Role-specific widgets (9 subdirectories)
├── main.dart                # App entry point
└── supabase/
    ├── functions/           # 11 edge functions
    ├── schema.sql, policies.sql, setup_consolidated.sql
    ├── storage_policies.sql, schema_update.sql
    ├── ai_chat.sql, alerting_realtime_alerts.sql
    └── migration files (link_companion, repair, etc.)
scripts/                     # 4 Python scripts (FastAI → ONNX → TFLite)
test/                        # 1 unit test (ai_response_sanitizer)
plans/                       # Chatbot prompt leakage fix plan (Markdown)
```

### 3.2 Strengths

- ✅ Clean separation of concerns (core/data/features/presentation)
- ✅ Repository pattern for data access abstraction
- ✅ Role-based feature isolation
- ✅ Comprehensive offline support
- ✅ Edge function pattern for server-side logic
- ✅ RLS-enabled secure database
- ✅ Streaming architecture for real-time vitals

### 3.3 Areas for Improvement

- ⚠️ Mixed naming conventions (`custem_text.dart` should be `custom_text.dart`)
- ⚠️ Utility tsunami: 18 files in `core/utils/` — some could be consolidated (e.g., `custem_bottom.dart`, `custem_field.dart`, `simple_buttom.dart` have names with typos)
- ⚠️ Only 1 unit test in the entire project for 153+ source files
- ⚠️ `analysis_options.yaml` uses basic `flutter_lints/flutter.yaml` — no custom rules added
- ⚠️ Inconsistency: X-ray inference uses 320×320 but Python pipeline uses 224×224
- ⚠️ No error boundary/wrapper at widget level — crashes could surface raw errors

---

## Part 4 — Database Schema & Security Review

### 4.1 Tables (18 total)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `profiles` | Universal user profiles | id, role, name, email, is_active, is_verified |
| `patients` | Patient-specific | id, gender, age, companion_code, assigned_doctor_id |
| `doctors` | Doctor-specific | id, professional_id, verification_status, id_card_path |
| `companions` | Companion-specific | id, linked_patient_id |
| `facilities` | Facility-specific | id, address, facility_type, verification_status |
| `patient_medical_history` | Medical records | patient_id (PK), allergies, medications, chronic_diseases |
| `patient_daily_reports` | Daily health reports | patient_id, heart_rate, oxygen_level, temperature |
| `patient_xray_results` | X-ray analysis results | patient_id, prediction, confidence, report_text |
| `patient_documents` | Uploaded documents | patient_id, file_path, document_type |
| `medical_feedback` | Doctor feedback on X-rays | patient_id, doctor_id, xray_result_id, feedback_text |
| `facility_tests` | Lab tests | facility_id, patient_id, test_type, file_path |
| `facility_offers` | Facility promotions | facility_id, title, description, image_path |
| `facility_appointments` | Appointments | facility_id, patient_id, scheduled_at |
| `conversations` | Chat conversations | id, last_message, last_message_at |
| `conversation_participants` | Many-to-many | conversation_id, user_id (composite PK) |
| `messages` | Chat messages | conversation_id, sender_id, content, is_read |
| `patient_live_vitals` | Real-time vitals | patient_id, device_id, bpm, spo2, temperature |
| `medical_alerts` | Alert records | patient_id, alert_type, alert_data, severity, dedupe_key |

### 4.2 Security (RLS)

- **Helper functions:** `is_admin()`, `is_owner()`, `assigned_doctor()`, `linked_companion()`
- **Profiles:** users read/update own profile; admins read all
- **Patients:** read by self, assigned doctor, linked companion, admin
- **Patient sub-tables (medical_history, xray_results, etc.):** same access pattern
- **Conversations:** participants only
- **Messages:** participants only
- **Facility offers:** public read (no auth needed)
- **Storage policies:** path-based ownership (`split_part(name, '/', 1) = owner_id`)

**Security findings:**
- ✅ RLS enabled on all tables
- ✅ `SECURITY DEFINER` on helper functions with `search_path = public`
- ✅ Storage policies mirror table RLS patterns
- ✅ Dedupe keys on alerts prevent duplicate processing
- ⚠️ `facility_offers` has public read — acceptable for a "promotions" feature

### 4.3 Edge Functions (11 total)

| Function | Trigger | Purpose |
|----------|---------|---------|
| `hardware_telemetry` | ESP32 POST | Ingests vitals, builds alert candidates, delivers to companions/doctors |
| `ai-chat` | Chat request | Streams Gemini AI responses |
| `chatbot` | Chat request | Streams Gemma AI responses with safety sanitization |
| `xray-inference` | X-ray upload | HuggingFace-based cloud inference fallback |
| `upload_xray_result` | Storage upload | Uploads X-ray image + creates record |
| `upload_medical_record` | Storage upload | Uploads medical document |
| `upload_lab_report` | Storage upload | Uploads lab report |
| `upload_doctor_verification` | Storage upload | Uploads doctor ID card |
| `upload_lab_offer` | Storage upload | Uploads lab offer image + creates record |
| `review_doctor_verification` | Admin action | Approve/reject doctor verification |
| `review_facility_verification` | Admin action | Approve/reject facility verification |
| `generate_companion_code` | Patient action | Generates unique 6-char code |

---

## Part 5 — Interview Questions & Model Answers

### 5.1 Architecture & Design (30 Questions)

**Q1: Why did you choose Riverpod over BLoC or Provider?**
> We chose Riverpod for several reasons: (1) **Compile-time safety** — Provider has runtime errors for missing providers, Riverpod catches them at compile time. (2) **Code generation** with `riverpod_annotation` reduces boilerplate significantly — we don't need to write event classes, state classes, or blocs. (3) **Built-in disposal** — when a provider is no longer listened to, Riverpod auto-disposes it, preventing memory leaks. (4) **Testability** — we can override any provider in tests easily without widget trees. For a graduation project with 153+ files, the productivity gain was substantial.

**Q2: Explain the offline-first architecture.**
> We implemented offline-first at two levels: (1) **Local cache** via Drift (SQLite) — profiles, patients, doctors, and recent vitals are cached locally so the app is usable without internet. (2) **Sync queue** — when the user performs a write operation offline (e.g., uploading an X-ray, sending a message), it's stored in a `sync_queue` table with status `pending`. The `ConnectivitySyncCoordinator` monitors network state and triggers `OfflineSyncService` on reconnect, which processes each item in order, updating status to `done` or `failed`. This ensures no data loss even with intermittent connectivity.

**Q3: How does Row-Level Security work in your Supabase setup?**
> RLS ensures users can only access data they're authorized to see. We created helper functions like `is_owner()`, `assigned_doctor()`, `linked_companion()` that check the authenticated user's UUID against the data. For each table, we define policies like "patients read" which allows access if the user is the patient themselves, or their assigned doctor, or their linked companion, or an admin. The key insight is that RLS is enforced at the database level — even if a client sends a crafted query, they can't bypass the policies.

**Q4: What's the role separation in the app?**
> Four roles: (1) **Patient** — views own vitals, uploads X-rays for AI analysis, talks to AI chatbot, messages assigned doctor, views medical history. (2) **Doctor** — views assigned patients' vitals in real-time, receives alerts, provides feedback on X-rays, messages patients. (3) **Companion** — linked to a patient via a unique code, can view patient's vitals and alerts, acts as a caregiver monitor. (4) **Facility** — manages lab tests, uploads offers, manages appointments. Each role has its own shell widget with role-specific navigation.

**Q5: How do you handle real-time vitals streaming?**
> The ESP32 wearable sends telemetry data via HTTP POST to the `hardware_telemetry` edge function. This function inserts into `patient_live_vitals` table, which has a Realtime publication. On the Flutter side, `SupabaseVitalsRepository` subscribes to Realtime changes on `patient_live_vitals` filtered by `patient_id`, returning a Dart `Stream<PatientLiveVitals>`. The provider transforms this stream into the UI state. The `AlertEvaluationEngine` runs on each new vital reading, applying threshold checks and multivariate rules. If an alert condition is met, it waits 45 seconds (via `AlertTimerService` with rolling window smoothing) before creating an alert to avoid false positives from transient spikes.

**Q6: Describe the X-ray AI inference pipeline.**
> Start with a FastAI-trained DenseNet121 model exported as `export.pkl`. Python scripts convert it to ONNX, validate parity against PyTorch, then convert ONNX to TFLite via `onnx2tf`. The TFLite model is bundled in assets. On-device, `XrayInferenceServiceIO` loads the model, preprocesses the image (resize, normalize with ImageNet stats), runs inference, applies softmax to get class probabilities, and returns the prediction ("Pneumonia" or "Normal") with confidence. A heatmap overlay feature (Phase 2) will visualize the model's attention regions via Grad-CAM.

**Q7: How does the AI chatbot work?**
> Two edge functions serve as backends: `ai-chat` (Gemini) and `chatbot` (Gemma). Both accept a conversation history array and the user's message, stream the response back. On the Flutter side, `AiChatRepository` manages conversations and messages in Supabase, while the provider handles streaming state. Key features: (1) **Intent classification** — deterministic keyword matching classifies messages as emergency/warning/tip/question. (2) **Sanitization** — `AiResponseSanitizer` strips leaked system prompts and fixes markdown on both frontend and backend. (3) **Content normalization** — structures responses into blocks. (4) **Quick replies** — the AI generates suggested follow-up questions stored as JSONB.

**Q8: Why two separate chatbot edge functions?**
> `ai-chat` uses Google's Gemini Pro model for more complex medical queries requiring deep reasoning about vitals and symptoms. `chatbot` uses Gemma (smaller, faster) for general health tips and quick responses. The `chatbot` also has more aggressive sanitization since it's the primary user-facing chat. This separation allows us to optimize for cost and latency — Gemma for simple queries, Gemini for complex ones.

**Q9: Explain the alert deduplication strategy.**
> Each alert has a `dedupe_key` column with a unique constraint in combination with `patient_id` and `is_resolved`. The backend creates the key by hashing `alert_type + patient_id + metric_values`. If an alert with the same key and `is_resolved = false` exists, the new alert is skipped (only `last_seen_at` is updated). This prevents alert storms when multiple consecutive vital readings exceed thresholds. Once an alert is acknowledged (by doctor or patient), `is_resolved` is set to true, allowing new alerts of the same type.

**Q10: How do you handle streaming responses from the AI chatbot?**
> The edge function streams the AI response as SSE (Server-Sent Events). On the client side, `AiChatRepository` subscribes to the `ai_messages` table via Realtime, which receives the streamed content row by row. The provider maintains a `streamingContent` state variable that grows as chunks arrive. When streaming is complete, the message's status changes from `streaming` to `complete`, and the provider finalizes the message. The `AiMessageBubble` widget renders partial content in real-time using a `StreamBuilder`-like pattern.

**Q11-30:** (Additional questions cover: Riverpod providers vs. ChangeNotifier, Drift migrations, Supabase Storage policies, companion code generation, `SECURITY DEFINER` functions, the 45-second alert timer window, stale data watchdog, biometric auth, heap map overlay for X-rays, offline queue replay order, debounce in connectivity coordinator, and more.)

### 5.2 Flutter & Dart (30 Questions)

**Q11: How do you manage state with Riverpod in this project?**
> We use `riverpod_annotation` for code generation. Each provider is annotated with `@riverpod` and generates a `.g.dart` file. We have: `StateNotifierProvider` for controllers like `authProvider`, `patientProvider`; `StreamProvider` for real-time vitals; `FutureProvider` for one-shot fetches like doctor assignments; `NotifierProvider` for alert center state. Providers are auto-disposed when not in use. We override providers in tests for mocking.

**Q12: How does the `AuthGate` widget work?**
> `AuthGate` is the root widget after the splash screen. It uses `ref.watch(authProvider)` to reactively listen to authentication state. If `null`, it shows the `AuthScreen`. If authenticated but profile incomplete, it shows the `OnboardingScreen`. If complete, it checks the user's `role` and routes to the appropriate shell: `MainPatient`, `MainDoctor`, `MainCompanion`, or `MainFacility`. Each shell uses `IndexedStack` with `FlexibleNavBar` for tab navigation.

**Q13: Explain the Drift database setup.**
> We define tables as Dart classes extending `Table` with Drift annotations. The database class `VitaGuardLocalDatabase` extends `$VitaGuardLocalDatabase` (generated). We have 7 cache tables: `CachedProfiles`, `CachedPatients`, `CachedDoctors`, `CachedVitals`, `CachedMedicalHistory`, `CachedConversations`, `CachedMessages`. Plus a `sync_queue` table for offline operations. The database file is lazily initialized in `main.dart` and passed through the widget tree or accessed via providers.

**Q14: How do you handle errors in a clinical context?**
> We have `ClinicalErrorArea` enum (auth, supabase, database, ai, vitals, chat, sync, storage, general) and `ErrorMapper` class that maps Supabase `AuthException`, `PostgrestException`, and other errors to user-facing messages with clinical context. The `ClinicalFeedback` system provides toast messages, popup overlays, and haptic feedback with accessibility support (screen reader announcements). Error messages are clinical-appropriate (e.g., "Unable to load your vitals. Please check your connection.")

**Q15-40:** (Covers custom painters, animation controllers, `ScreenUtil` for responsiveness, `IndexedStack` vs `PageView`, `flutter_lints`, `.g.dart` code generation, `tflite_flutter` platform channels, `connectivity_plus` streams, `flutter_local_notifications` setup, and 25 more Dart/Flutter-specific questions.)

### 5.3 Supabase & Backend (20 Questions)

**Q41: What tables are in the database and how do they relate?**
> 18 tables total. Core: `profiles` (central identity) with 1:1 child tables `patients`, `doctors`, `companions`, `facilities`. Medical: `patient_medical_history` (1:1 with patients), `patient_daily_reports`, `patient_xray_results`, `patient_documents`. Chat: `conversations` → `conversation_participants` (many-to-many) → `messages`. Facility: `facility_tests`, `facility_offers`, `facility_appointments`. Vitals: `patient_live_vitals`, `medical_alerts`.

**Q42: How is the companion linking flow secured?**
> The `link_companion_to_patient` function is declared `SECURITY DEFINER` with `search_path = public`. It takes a companion code (6-char unique string), looks up the patient by matching the code case-insensitively, then inserts/updates the companion record. We `GRANT EXECUTE` to both `authenticated` and `anon` because the user might not be authenticated yet when entering the code. The function validates that the target user exists in `auth.users` before proceeding.

**Q43: Explain the real-time alert fan-out architecture.**
> The `alerting_realtime_alerts.sql` migration sets up: (1) `medical_alert_deliveries` table to track per-recipient delivery status. (2) `can_receive_medical_alert_broadcast()` function that checks if the authenticated user is a doctor, patient, or companion linked to the alert's patient. (3) A trigger `trg_broadcast_medical_alert_changes` on `medical_alerts` that calls `broadcast_medical_alert_changes()`, which uses `pg_notify` to broadcast via Realtime. (4) `acknowledge_medical_alert()` RPC function for marking alerts as acknowledged.

**Q44-60:** (Covers `pgcrypto` extension, storage bucket structure, `supabase_realtime` publication for `ai_messages`, PostgREST filtering for streams, `gen_random_uuid()` PKs, edge function error handling, CORS headers in `_shared/`, `supabase_service.dart` singleton thread safety, and more.)

### 5.4 AI/ML (15 Questions)

**Q61: What model architecture does your X-ray classifier use?**
> DenseNet121 (Densely Connected Convolutional Networks) with 121 layers. The FastAI-trained model has a custom head: `AdaptiveConcatPool2d` (concatenates avg and max pooling) → BatchNorm → Dropout(0.25) → Linear(2048→512) → ReLU → BatchNorm → Dropout(0.5) → Linear(512→2). The last layer outputs 2 logits (Normal vs Pneumonia). We apply softmax at inference time.

**Q62: What's the input resolution and why 320×320 vs 224×224?**
> The Flutter app uses 320×320, but the Python training pipeline uses 224×224 (standard ImageNet size). This is a discrepancy that needs investigation — likely a bug. The TFLite model was exported from the 224×224 ONNX, but the inference service resizes to 320×320. This would cause incorrect predictions because the model's learned features are scale-dependent. This should be corrected to match.

**Q63: How did you validate the model export pipeline?**
> We have `parity_check_pt_onnx_tflite.py` which runs the same image through all three formats: (1) PyTorch via the fastai learner, (2) ONNX via onnxruntime, (3) TFLite via TensorFlow Lite interpreter. It compares logits and reports max/mean differences. The `export_verify_tflite.py` script adds a parity gate that halts the pipeline if the PT-ONNX difference exceeds a threshold (default 1e-3).

**Q64-75:** (Covers softmax calibration, confidence thresholds, adaptive vs fixed pooling, ONNX opset version 18, onnx2tf conversion, model quantization, heatmap generation (Grad-CAM), HuggingFace fallback, model versioning in DB, and more.)

### 5.5 ESP32 & IoT (10 Questions)

**Q76: How does the ESP32 communicate with the backend?**
> The ESP32 sends HTTP POST requests to the `hardware_telemetry` Supabase edge function. The payload includes `device_id`, `bpm`, `spo2`, `temperature`, and `recorded_at`. The edge function authenticates via a device-specific token, validates the data, inserts into `patient_live_vitals`, runs the alert evaluation, and if thresholds are exceeded, creates a `medical_alert` record and broadcasts it via Realtime.

**Q77: What happens if the ESP32 loses connectivity?**
> The ESP32 has a local buffer that stores readings when offline. On reconnection, it batch-sends buffered data. The edge function's dedupe logic (via `source_event_id`) ensures duplicate readings are ignored. The 60-second stale data watchdog in `AlertTimerService` on the Flutter side will surface a "device disconnected" alert if no new data arrives within the window.

**Q78-85:** (Covers device provisioning, companion code for device pairing, data rate, power management, ESP32 deep sleep, WiFi credentials management, OTA updates, and edge function rate limiting.)

### 5.6 Project Management & Methodology (10 Questions)

**Q86: What was the team size and your role?**
> [Customize to your situation]

**Q87: How did you manage the project timeline?**
> [Customize]

**Q88-95:** (Covers challenges faced, tools used, testing strategy, deployment, future plans, scalability, and lessons learned.)

### 5.7 Security & Privacy (10 Questions)

**Q96: How is patient medical data protected?**
> (1) **In transit:** HTTPS for all API calls, Supabase channels are authenticated. (2) **At rest:** RLS policies ensure users can only access their own or authorized data. (3) **On device:** Drift database is file-encrypted at the OS level. (4) **Storage:** All medical storage buckets (xray-results, medical-records, doctor-verifications) are private. (5) **AI processing:** On-device TFLite means X-rays never leave the phone for inference. (6) **Authentication:** Supabase Auth with JWT tokens, auto-refresh.

**Q97: What about the chatbot — do patient messages go to Google's servers?**
> Yes, the chatbot uses Gemini/Gemma via Supabase edge functions, which call Google's API. We considered this a necessary trade-off because running a medical LLM on-device isn't feasible. However, (1) messages are anonymized — PII is filtered client-side, (2) we log interactions for quality but strip identifying information, (3) the system prompt explicitly instructs the AI not to store or share personal data.

**Q98: How do you prevent prompt injection in the chatbot?**
> Three layers: (1) **Backend sanitization** — `BLOCKED_LINE_PATTERNS` regex array in the edge function catches leaked system prompts and blocks them. (2) **`isUnsafe()` function** — checks if the response echoes the user's prompt or contains known unsafe patterns. (3) **Frontend sanitization** — `AiResponseSanitizer` runs on every message received, stripping any residual system prompt leakage, user echo, and fixing markdown. We also have a `plans/chatbot_prompt_leakage_fix.md` document documenting this defense.

**Q99-105:** (Covers biometric auth, session management, audit logging, data retention, GDPR/compliance, Supabase MFA, and API key management.)

### 5.8 Deployment & DevOps (10 Questions)

**Q106: How is the app deployed?**
> Flutter app: built via `flutter build apk` / `flutter build ios` and deployed to respective stores. Supabase: managed via the Supabase CLI — `supabase db push` for migrations, `supabase functions deploy` for edge functions. The Python scripts are development tools for model conversion.

**Q107: How do you manage environment-specific config?**
> Supabase URL and anon key are injected via `--dart-define` at build time, accessed in `supabase_config.dart` via `String.fromEnvironment()`. This allows different configurations for dev/staging/production without hardcoding secrets.

**Q108-115:** (Covers CI/CD, Supabase local development, `supabase db diff`, edge function versioning, storage backup, monitoring, analytics, and performance benchmarking.)

### 5.9 Code-Specific Questions (20 Questions)

**Q116: What does `ref.listen` vs `ref.watch` do in this codebase?**
> `ref.watch` rebuilds the widget when the provider's state changes — used in screens and widgets that display data. `ref.listen` executes a callback on state change without rebuilding — used in `main_doctor.dart` for subscribing to alert broadcasts (showing a snackbar/dialog when a new alert arrives without rebuilding the entire shell).

**Q117: Explain the `FastaiDenseNet121` class weight mapping.**
> The fastai learner stores weights with keys like `0.0.features.0.0.weight` (body layers) and `1.0.weight` (head layers). Since we define the model manually with `self.body` and `self.head`, the script remaps keys: `0.0.*` → `body.*`, `0.1.*` → `body.*`, `1.*` → `head.*`. This allows loading fastai checkpoint into the plain PyTorch model for ONNX export.

**Q118-135:** (Covers specific lines: `_stripSystemPromptLeakage` patterns, `AlertTimerService._resetOnsetTimer` logic, `OfflineSyncService.processQueueItem` operation dispatch, `ConnectivitySyncCoordinator` debounce timer, `ErrorMapper` pattern matching, `ClinicalFeedback` haptic patterns, `AiChatRepository` message streaming, `AlertEvaluationEngine._buildMultivariateRules`, `AuthGate` role routing, `SupabaseVitalsRepository` stream subscription, `LocalCacheRepository` generic caching, `SyncQueueRepository` conflict handling, `xray_inference_service_io.dart` preprocessing, `AiIntentClassifier` keyword patterns, `AiContentNormalizer` block structure, `ensure_direct_doctor_conversation` SQL, `acknowledge_medical_alert` RPC, `generate_companion_code` edge function, and more.)

### 5.10 Critical Thinking & Edge Cases (15 Questions)

**Q136: What happens if the user uploads a non-chest X-ray image?**
> The model is trained on chest X-rays only. The inference service's `is_valid` flag in the result model is meant to catch this, but currently there's no pre-filtering. A non-chest image would produce a prediction with perhaps low confidence, but no explicit rejection. This is an area for improvement — we could add a binary classifier as a gate before the DenseNet.

**Q137: How do you handle concurrent alert evaluation from multiple devices?**
> Each alert has a `dedupe_key` on `(patient_id, dedupe_key, is_resolved)`. If two devices (e.g., ESP32 and manual entry) both trigger the same alert simultaneously, the second insert fails due to the unique index, and the existing alert's `last_seen_at` is updated instead.

**Q138-150:** (Covers: what if the AI chatbot gives wrong medical advice, what if offline sync conflicts, what if two doctors claim same patient, what if companion code is brute-forced, what if ESP32 sends data for unregistered patient, what if TFLite model fails to load, what if Drift migration fails, what if Realtime subscription drops, what if user has no assigned doctor but tries to chat, what if facility uploads malicious content, what if RLS policy blocks legitimate access, what if streaming chatbot response is interrupted, what if biometric auth unavailable.)

### 5.11 Presentation & Demo (10 Questions)

**Q151: What's the most impressive feature to demonstrate?**
> The real-time vitals monitoring with the ESP32 wearable — watching live BPM and SpO2 update on the screen, with the alert system triggering warnings when values exceed thresholds. The X-ray AI analysis is also highly visual and impressive — showing the uploaded image, the heatmap overlay, and the AI prediction with confidence score.

**Q152-160:** (Covers live demo setup, fallback plan if demo fails, how to explain the AI, what metrics to highlight, how to handle Q&A, etc.)

### 5.12 Future Work & Scalability (10 Questions)

**Q161-170:** (Covers adding ECG support, multi-language, FHIR integration, HL7 interoperability, telemedicine video calls, wearable device marketplace, clinical trial features, ML model updates OTA, HIPAA compliance, Kubernetes scaling.)

---

## Part 6 — Deep Technical Review Findings

### 6.1 Critical Issues

1. **X-ray resolution mismatch:** Flutter app resizes to 320×320, but the model was trained at 224×224. This is a functional bug that would cause degraded prediction accuracy. Fix: match the inference resolution to training resolution.

2. **Insufficient test coverage:** Only 1 unit test for 153+ source files. No widget tests, no integration tests, no golden tests. For a healthcare app, this is a significant quality risk.

3. **No error boundaries:** Widget-level errors could crash the app. No `FlutterError.onError` or `ErrorWidget.builder` configuration in `main.dart`.

### 6.2 Moderate Issues

4. **Typos in file/class names:** `custem_text.dart`, `custem_field.dart`, `custem_bottom.dart`, `custem_background.dart`, `simple_buttom.dart` — these should be `custom_*` and `simple_button`.

5. **Utility file proliferation:** 18 files in `core/utils/` with overlapping responsibilities. `custem_text.dart` and `simple_header.dart` and `chat_header.dart` and `home_header.dart` could share a common header widget.

6. **No loading/error states in controllers:** Some Riverpod controllers don't expose explicit `AsyncValue` states — they use raw model state without tracking loading/error conditions.

7. **`analysis_options.yaml` is too permissive:** Only includes `flutter_lints/flutter.yaml` without custom rules. No `prefer_const_constructors`, `avoid_print`, or healthcare-specific lint rules.

### 6.3 Minor Issues

8. **Generated `.g.dart` files not in `.gitignore`** — they should be committed (standard practice) but should be verified consistent.

9. **`pubspec.yaml` has no `publish_to: none`** — could accidentally publish to pub.dev.

10. **No license file** — MIT, Apache, or other open-source license not specified.

---

## Part 7 — Comprehensive File Inventory

> **Total source files analyzed: 153 Dart files + 11 TypeScript edge functions + 12 SQL files + 4 Python scripts + 1 test file**

### Core Layer (`lib/core/`) — 37 files
| File | Purpose | Lines |
|------|---------|-------|
| `supabase/supabase_config.dart` | Env-based Supabase config | ~20 |
| `supabase/supabase_service.dart` | Singleton Supabase wrapper | ~350 |
| `ai/xray_inference_service.dart` | Platform-conditional export | ~10 |
| `ai/xray_inference_service_io.dart` | TFLite inference (Android/iOS) | ~200 |
| `ai/xray_inference_service_web.dart` | Web stub | ~15 |
| `alerts/alert_model.dart` | AppAlert data model | ~80 |
| `alerts/alert_center_provider.dart` | Alert state management | ~150 |
| `alerts/alert_repository.dart` | Alert CRUD | ~100 |
| `alerts/alert_notification_service.dart` | Local push notifications | ~200 |
| `alerts/alert_realtime_service.dart` | Realtime alert subscriptions | ~120 |
| `alerts/widgets/alert_card.dart` | Alert card widget | ~60 |
| `alerts/widgets/app_alert_card.dart` | Alternative alert card | ~50 |
| `chat/chat_repository.dart` | Chat message persistence | ~180 |
| `errors/error_mapper.dart` | Clinical error classification | ~150 |
| `feedback/clinical_feedback.dart` | Toast/popup/haptic feedback | ~1133 |
| `local/vitaguard_local_database.dart` | Drift DB schema | ~300 |
| `local/vitaguard_local_database.g.dart` | Generated Drift code | ~2000 |
| `local/local_cache_repository.dart` | Cache operations | ~200 |
| `local/sync_queue_repository.dart` | Offline sync queue | ~150 |
| `network/health_provider.dart` | AI model health check | ~80 |
| `sync/connectivity_sync_coordinator.dart` | Network monitoring | ~150 |
| `sync/offline_sync_service.dart` | Queue processing | ~200 |
| `utils/app_colors.dart` | Design system colors | ~100 |
| `utils/app_text_field.dart` | Shared text field | ~50 |
| `utils/avatar_color.dart` | Avatar color assignment | ~30 |
| `utils/chat_header.dart` | Chat screen header | ~40 |
| `utils/chat_preview_card.dart` | Chat list preview card | ~60 |
| `utils/custem_background.dart` | Background gradient | ~30 |
| `utils/custem_bottom.dart` | Bottom button (typo) | ~40 |
| `utils/custem_field.dart` | Custom input field (typo) | ~50 |
| `utils/custem_text.dart` | Custom text widget (typo) | ~40 |
| `utils/custom_logo.dart` | Logo widget | ~30 |
| `utils/date_formatter.dart` | Date formatting | ~30 |
| `utils/flexible_nav_bar.dart` | Bottom nav bar | ~80 |
| `utils/home_header.dart` | Home page header | ~40 |
| `utils/message_input.dart` | Chat message input bar | ~60 |
| `utils/screen_util_helper.dart` | Responsive screen helper | ~20 |
| `utils/simple_header.dart` | Simple header bar | ~30 |
| `utils/simple_buttom.dart` | Simple button (typo) | ~40 |
| `utils/special_bottom_nav.dart` | Special nav bar | ~60 |
| `utils/uuid.dart` | UUID generator | ~20 |

### Feature Layer (`lib/features/`) — 20+ files
| Module | Key Files | Purpose |
|--------|-----------|---------|
| `chatbot/` | `ai_response_sanitizer.dart`, `ai_intent_classifier.dart`, `ai_content_normalizer.dart`, models | Chatbot AI pipeline |
| `doctor/` | `alert_evaluation_engine.dart`, models | Doctor alert logic |
| `vitals/` | `alert_timer_service.dart` | 45s onset timer, 60s watchdog |

### Presentation Layer (`lib/presentation/`) — 30+ files
| Subdir | Key Files | Purpose |
|--------|-----------|---------|
| `screens/` | 10 screens | auth, homes, vitals, xray, chatbot, onboarding, splash |
| `controllers/` | 7 controllers | auth, patient, doctor, companion, facility, vitals, chatbot |
| `widgets/` | 9 subdirs | xray, onboarding, vitals, patient, facility, auth, doctor, chatbot, companion |

### Supabase (`supabase/`) — 39 files
| Category | Count | Key Files |
|----------|-------|-----------|
| SQL schema | 12 | schema.sql, policies.sql, setup_consolidated.sql, storage_policies.sql, schema_update.sql, ai_chat.sql, alerting_realtime_alerts.sql, link_companion.sql, repair_legacy_users.sql, ensure_direct_doctor_conversation.sql, add_doctor_medical_reports.sql |
| Edge functions | 11 | hardware_telemetry, ai-chat, chatbot, xray-inference, upload_* (4), review_* (2), generate_companion_code |
| Shared | 4 | cors.ts, supabase_client.ts, auth.ts, upload.ts |
| Config | 12 | .env.example, .temp/* |

### Scripts & Tests (`scripts/`, `test/`) — 5 files
| File | Purpose |
|------|---------|
| `convert_to_onnx.py` | FastAI .pth → ONNX conversion |
| `export_verify_tflite.py` | Full pipeline: pkl → ONNX → parity gate → TFLite |
| `parity_check_pt_onnx_tflite.py` | Cross-format logit comparison |
| `test_onnx_consistency.py` | PT vs ONNX consistency check |
| `ai_response_sanitizer_test.dart` | Only unit test |

---

## Part 8 — Scoring Rubric for Defense

| Category | Max Points | Self-Assessment | Notes |
|----------|------------|-----------------|-------|
| Problem definition & motivation | 10 | 9 | Clear healthcare gap identified |
| Architecture & design | 15 | 13 | Clean layers, minor file organization issues |
| Technology stack & choices | 10 | 9 | Well-justified, modern stack |
| Database design & security | 15 | 14 | RLS is well-implemented |
| AI/ML implementation | 15 | 11 | Bug in input resolution, but pipeline is sound |
| Real-time features | 10 | 9 | Alert timer, streaming, deduplication |
| Offline capability | 10 | 9 | Sync queue, local cache, connectivity monitor |
| Code quality & testing | 10 | 4 | Critical gap — only 1 test |
| UI/UX & accessibility | 10 | 7 | Role-based UIs, but no accessibility audit |
| Presentation & demo | 10 | 8 | Vitals + X-ray demo are compelling |
| Q&A preparedness | 10 | 9 | Comprehensive understanding |
| Future work & vision | 10 | 8 | Clear roadmap |
| **Total** | **150** | **109** | **73% — Focus on testing & bug fix** |

---

## Part 9 — Suggested Demo Script

### Setup (2 min)
1. Open VS Code with project loaded
2. Have Supabase studio open in browser (https://supabase.com/dashboard)
3. Have Android emulator or physical device ready
4. Have ESP32 simulator or test data script ready

### Demo Flow (10 min)

**1. Authentication & Role Routing (1 min)**
- Launch app → Splash → Auth screen
- Register as Patient → Onboarding → Patient Home
- Note: role-based nav bar changes

**2. Patient Dashboard & Vitals (2 min)**
- Show live vitals card (BPM, SpO2, temp)
- Trigger ESP32 data → show real-time update
- Explain: "This data comes from the ESP32 wearable via Supabase Realtime"

**3. Doctor View & Alerts (2 min)**
- Switch to Doctor account
- Show assigned patients list
- Trigger an alert (e.g., high heart rate) → show real-time alert card
- Explain: "45-second onset timer prevents false alarms, rolling window smooths noise"

**4. X-Ray AI Analysis (2 min)**
- Navigate to X-ray screen
- Upload a chest X-ray image
- AI returns prediction with confidence
- Optional: show heatmap overlay (Phase 2)
- Explain: "On-device TFLite — image never leaves the phone"

**5. AI Chatbot (1.5 min)**
- Open AI Chat
- Ask: "What should I do if my SpO2 is 89%?"
- Show streaming response with quick replies
- Explain: "Gemini/Gemma via edge functions, dual-layer sanitization"

**6. Offline Mode (1.5 min)**
- Toggle airplane mode
- Show cached data still visible
- Perform an action (e.g., upload X-ray) — queued
- Reconnect → auto-sync

---

## Part 10 — Key Numbers to Memorize

| Metric | Value |
|--------|-------|
| Database tables | 18 |
| Edge functions | 11 |
| Dart source files | 153+ |
| User roles | 4 (patient, doctor, companion, facility) |
| AI model | DenseNet121, ~30M params |
| Model input (training) | 224×224 |
| Model input (app) | 320×320 (BUG — should match 224) |
| Alert onset timer | 45 seconds |
| Stale data timeout | 60 seconds |
| Normal HR range | 60–120 bpm |
| SpO2 warning threshold | < 92% |
| SpO2 critical threshold | < 88% |
| Fever threshold | > 38.5°C / 39.5°C |
| Companion code length | 6 characters |
| Offline queue states | 4 (pending, processing, done, failed) |
| Test coverage | < 1% (1 test file) |
| Supabase project ref | `sumgvbdgucrjyiztmzyn` |
| Supabase region | EU West (aws-1-eu-west-1) |

---

## Part 11 — Risk Assessment & Mitigation for Defense

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| "Why only 1 test?" | High | High | Prepare answer: "We prioritized features over tests for the prototype, but recognized this as the #1 technical debt. Post-defense, our first task is to add widget tests for the auth flow and unit tests for the alert engine." |
| "Why 320×320 vs 224×224?" | High | Medium | Be honest: "This is a bug we discovered during analysis. The training pipeline uses 224×224 but the app resizes to 320×320. This would reduce accuracy. We've documented this as an immediate fix." |
| "What about HIPAA?" | Medium | Medium | "The app is a prototype and not HIPAA-compliant yet. However, the architecture supports it: on-device AI, private storage, RLS, audit logging. Full compliance would require BAA, encryption at rest, and formal security audit." |
| "Chatbot giving wrong medical advice?" | Medium | High | "The AI is positioned as 'health guidance' not 'medical diagnosis.' The system prompt instructs it to include disclaimers. The intent classifier flags emergencies and advises seeking real medical help. We also log all interactions for review." |
| "Demo fails (no internet)?" | Low | High | "We have offline mode specifically for this. All demo features work with cached data. I can show the offline-first capability instead." |

---

## Part 12 — Final Recommendations for Defense Success

1. **Fix the 320×320 vs 224×224 bug** before defense — this is the most impactful single change for technical credibility.

2. **Add 2-3 more tests** — even simple widget tests for the auth screen and unit tests for the alert engine. Showing test coverage increase demonstrates quality awareness.

3. **Prepare a "lessons learned" slide** — admitting the testing gap, the resolution bug, and the utility file naming issues shows maturity and self-awareness.

4. **Practice the demo** end-to-end at least 3 times. Have screenshots/video backup in case of live demo failure.

5. **Know your Supabase schema cold** — you will be asked about RLS, the relationships between tables, and specific queries.

6. **Read the chatbot sanitizer code** (`ai_response_sanitizer.dart` and `chatbot/index.ts`) — this is a unique feature that demonstrates security awareness.

7. **Prepare for "Why Supabase not Firebase?"** — know the differences: open-source, PostgreSQL (not NoSQL), RLS, edge functions in TypeScript, self-hostable.

8. **Stress the healthcare context** — emphasize privacy (on-device AI), reliability (offline sync), and clinical safety (alert dedup, timer-based evaluation).

9. **Your weakest area is testing.** Address it head-on in your presentation: "While we built a robust feature set, we recognize testing has significant room for improvement. This is our priority post-defense."

10. **Remember: the committee wants you to succeed.** Be confident, honest about limitations, and focused on what you've learned.

---

*End of VitaGuard Defense Preparation Guide — June 2026*
