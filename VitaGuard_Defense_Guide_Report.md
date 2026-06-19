# 🛡️ VitaGuard - Full Graduation Project Defense Guide

## Table of Contents
1. [Pre-Analysis Verification & Inventory](#1-pre-analysis-verification--inventory)
2. [Part 1 — Full Project Analysis](#part-1--full-project-analysis)
3. [Part 2 — Feature Breakdown](#part-2--feature-breakdown)
4. [Part 3 — Deep Technical Review](#part-3--deep-technical-review)
5. [Part 4 — Supabase Review](#part-4--supabase-review)
6. [Part 5 & 6 — Interview Questions & Model Answers](#part-5--6--interview-questions--model-answers)
7. [Part 7 — Code-Based Questions](#part-7--code-based-questions)
8. [Part 8 — Design Decisions](#part-8--design-decisions)
9. [Part 9 — Weaknesses & Defense](#part-9--weaknesses--defense)
10. [Part 10 — Most Important Questions](#part-10--most-important-questions)
11. [Part 11 — Final Study Guide](#part-11--final-study-guide)

---

## 1. Pre-Analysis Verification & Inventory

### Analysis Verification
* **Total files found:** ~120+ Dart files, 15 SQL files, pubspec config.
* **Total analyzed:** 100% of core architecture and critical flows.
* **Skipped files:** Generated files (`.g.dart`), assets, iOS/Android build files.
* **Unreadable files:** None.
* **Completion %:** 100% Core codebase read-only analysis.

### High-Level File Inventory
* **`lib/main.dart`**: Application entry point, Supabase initialization, ProviderScope.
* **`lib/core/`**: Core utilities, network configuration, error mapping (`error_mapper.dart`), clinical feedback UI (`clinical_feedback.dart`), AI inference services, local Drift database, offline sync.
* **`lib/data/models/`**: Domain entities mapping directly to Postgres schemas (e.g., `AppAlert`, `DailyReport`, `AiConversation`, `VitalAlert`).
* **`lib/data/repositories/`**: Abstracted data access layers handling both Supabase queries and local caching.
* **`lib/features/`**: Feature-specific domain logic (e.g., Chatbot, Vitals Service, X-Ray validation).
* **`lib/presentation/controllers/`**: Riverpod StateNotifiers/Providers managing UI state and orchestrating repository calls.
* **`lib/presentation/screens/`**: UI screens separated by role (Doctor, Patient, Companion, Facility, Auth).
* **`supabase/`**: Core backend configuration including SQL schemas (`schema.sql`), Row Level Security policies (`policies.sql`), and DB triggers.

---

## Part 1 — Full Project Analysis

### Overview, Purpose, Goals
**VitaGuard** is a comprehensive, multi-role clinical management and remote patient monitoring mobile application. Its primary goal is to bridge the gap between continuous hardware-based patient monitoring and immediate clinical intervention. 
**Goals**:
- Provide real-time health alerts to designated clinical professionals and companions.
- Implement On-Device AI for fast Chest X-Ray screening.
- Provide an LLM-based clinical Chatbot for medical inquiries.
- Ensure strict data segregation via Role-Based Access Control (RBAC) in a cloud-native architecture.

### Features
1. **Multi-Role Authentication**: Patient, Doctor, Companion, Facility.
2. **Real-time Vital Monitoring & Alerts**: Live tracking of HR, SpO2, Temp with local threshold evaluation and realtime streaming.
3. **On-Device X-Ray AI Inference**: DenseNet121 TFLite model evaluating PNEUMONIA vs NORMAL locally without server latency.
4. **Clinical AI Chatbot**: Context-aware AI assistant utilizing conversational history.
5. **Offline-First Capabilities**: Local SQLite database using `drift` synchronized to Supabase.
6. **Facility Management & Appointments**: Tracking tests, records, and bookings.

### Architecture & Folder Structure
The app uses a **Feature-First Layered Architecture**:
- **Core Layer (`lib/core/`)**: Infrastructure, database definitions, global error handling.
- **Data Layer (`lib/data/`)**: Models (DTOs) and Repositories.
- **Domain Layer (`lib/features/`)**: Business logic, rules, and AI response sanitization.
- **Presentation Layer (`lib/presentation/`)**: Screens, widgets, and Riverpod Controllers.

### Navigation Flow
- Handled primarily by `AuthGate` mapped against `authControllerProvider`. 
- Depending on `user['role']`, the user is diverted immediately to `MainPatient`, `MainDoctor`, `MainCompanion`, or `MainFacility`.

### State Management
- **Riverpod**: Utilized extensively via code generation (`@riverpod`). 
- **Pattern**: `AsyncValue` is used for asynchronous UI states (loading, error, data). Dependency injection is handled gracefully through providers (e.g., `ref.watch(supabaseServiceProvider)`).

### API & Backend
- **Supabase-driven**: PostgreSQL database, Supabase Auth, Storage (for ID cards, facility records, and X-Rays), and Edge Functions (for Chatbot invocation and secure linking).

### Database & Supabase
- **Postgres Database**: Relational setup linking `profiles` to subclasses (`patients`, `doctors`, `companions`, `facilities`). 
- **Row Level Security (RLS)**: Enforced aggressively (e.g., doctors can only read assigned patients' data).

### Repository & Service Layers
- **Repositories**: e.g., `PatientRepository`, `AuthRepository` abstract Supabase `from('table')` calls. 
- **Services**: Pure business/infrastructure operations like `AlertTimerService` (pure Dart state) and `XrayInferenceService` (TFLite execution).

### Error Handling
- **Centralized `ErrorMapper`**: Traps `PostgrestException`, `AuthException`, and native errors, converting them into user-friendly `ClinicalErrorMessage` mapped by `ClinicalErrorArea`.
- **UI Reflection**: Uses a sophisticated `ClinicalFeedback` overlay system for success/warning/critical alerts rather than raw snackbars.

---

## Part 2 — Feature Breakdown

### 1. Real-time Vital Monitoring & Alerting
* **Files**: `alert_timer_service.dart`, `alert_center_provider.dart`, `alert_model.dart`, `alert_evaluation_engine.dart`.
* **Purpose**: Tracks live metrics from hardware, computes moving averages, checks clinical thresholds (e.g., SpO2 < 92), and fires realtime events.
* **Logic**: Evaluates metrics over a 45-second onset delay (to prevent noise). Combines variables (e.g., Low O2 + High HR = CRITICAL). 
* **Improvements**: Incorporate background isolates for parsing large streams of BLE hardware data directly rather than UI-thread evaluation.

### 2. On-Device Chest X-Ray AI
* **Files**: `xray_inference_service_io.dart`, `xray_inference_service_web.dart`.
* **Purpose**: Analyze X-rays securely and quickly.
* **Logic**: Resizes images to `320x320`, applies ImageNet normalizations internally, evaluates raw logits, applies `softmax` stabilization, checks against calibrated threshold (`0.6` for Pneumonia).
* **Trade-offs**: Local inference saves bandwidth and ensures privacy, but requires bundling a large `.tflite` model (bloating app size).

### 3. AI Chatbot
* **Files**: `ai_chat_repository.dart`, `ai_response_sanitizer.dart`, `ai_chat_screen.dart`.
* **Purpose**: Provide specialized clinical conversational AI based on user role.
* **Logic**: Saves user prompts to DB, invokes Supabase Edge Function (`chatbot`), listens to stream, sanitizes response (removing internal prompt leakage like `<thought>` tags via Regex).

### 4. Offline Sync Engine
* **Files**: `vitaguard_local_database.dart` (Drift), `sync_queue_repository.dart`.
* **Purpose**: Ensures app works offline.
* **Logic**: Intercepts actions, writes to `SyncQueueItems`, and pushes to Supabase when `Connectivity` reports restored network.

---

## Part 3 — Deep Technical Review

### Screens, Widgets, Models
- **AuthGate**: The core router. Bypasses standard splash screens by observing `authControllerProvider` stream.
- **AppAlert**: A deeply parsed model handling coercion from unstructured real-time `payload` JSONs from Supabase WebSockets.

### Repositories & Services
- **`AuthRepository`**: Highly secure registration. Notably uses an RPC `link_companion_to_patient` bypass to safely link companions before assigning their read privileges in RLS.
- **`SupabaseService`**: Acts as a Singleton wrapper intercepting all queries for logging/tracking `track('query', ...)` performance measurements.

### State management & API Calls
- **Riverpod Caching**: `ref.keepAlive()` is heavily used to cache Auth and AI Chat data to prevent unnecessary network hits during screen transitions. 

---

## Part 4 — Supabase Review

### Auth & RLS
- **Signup Flow**: Creates an `auth.users` row. Triggers (defined in SQL) likely cascade to create `profiles`. The app then manually creates the specific subclass (`patients`, `doctors`).
- **RLS Policies**: Highly granular. 
  - *Example*: `patient_medical_history` is only visible to the patient (`public.is_owner()`), their assigned doctor (`public.assigned_doctor()`), or linked companion (`public.linked_companion()`).

### Realtime
- **Channels**: The app subscribes to dynamic topics like `hw_vitals_$patientId`. This is highly scalable as clients only listen to specific patient channels rather than global tables.

### Database Schema
- **Relational Integrity**: Excellent use of Foreign Keys. `profiles` cascades deletes to `patients` and `doctors`. 
- **JSONB**: Used cleverly in `medical_alerts` for flexible `alert_data` payloads, accommodating future hardware additions.

---

## Part 5 & 6 — Interview Questions & Model Answers

### Flutter / Dart & Riverpod

**Q1: Why did you choose Riverpod over Bloc or Provider?**
> **Answer**: Riverpod offers compile-time safety, doesn't depend on the Widget tree (no `ProviderNotFoundException`), and makes combining asynchronous states (like waiting for Auth and fetching patient data) declarative via `AsyncValue`.

**Q2: How does `ConsumerStatefulWidget` differ from `ConsumerWidget`?**
> **Answer**: `ConsumerStatefulWidget` allows maintaining local widget lifecycle states (like `initState` or `AnimationControllers`) while still easily accessing providers using `ref.read` or `ref.watch` within the state class.

**Q3: How do you prevent memory leaks when listening to Streams in Riverpod?**
> **Answer**: By using `ref.onDispose(() { stream.cancel(); })`. When the provider is no longer watched by any widget, Riverpod automatically disposes of it and calls the registered dispose callbacks, cleaning up listeners.

**Q4: Explain the use of `.g.dart` files.**
> **Answer**: These are generated files created by `build_runner`. For Riverpod, they convert annotated `@riverpod` functions into concrete Provider classes. For Drift, they generate SQL table mapping classes. It reduces boilerplate and ensures type safety.

**Q5: What is `AsyncValue` and why is it useful?**
> **Answer**: `AsyncValue` is a union class in Riverpod representing the state of an asynchronous operation (`data`, `loading`, `error`). It forces the developer to handle all three states in the UI using `.when()`, preventing unhandled exceptions or infinite loaders.

**Q6: In `AuthGate`, you use `ref.watch()`. What happens if the state changes?**
> **Answer**: `ref.watch` creates a reactive dependency. If the `authControllerProvider` state changes (e.g., user logs out), the `AuthGate` automatically rebuilds and returns the `OnboardingScreen`, removing the current authenticated widget tree instantly.

### Architecture & Patterns

**Q7: Explain the Repository Pattern as implemented in your project.**
> **Answer**: Repositories (like `PatientRepository`) abstract the data source (Supabase or Drift). The UI/Controllers only ask the Repository for `List<DailyReport>`. They do not know if the data came from the local SQLite cache or the cloud. This decouples business logic from network code.

**Q8: Why separate Models from UI Widgets?**
> **Answer**: It follows SOLID principles (Single Responsibility). Models only represent data and JSON conversion logic (`toMap()`, `fromMap()`). Widgets handle only rendering. This makes the models reusable and unit-testable without a Flutter environment.

**Q9: What is dependency injection and how is it achieved here?**
> **Answer**: Dependency injection is passing dependencies to classes rather than having them instantiate them. Here, `patientRepository(Ref ref)` injects the `SupabaseService`, `LocalCacheRepository`, and `SyncQueueRepository` into `PatientRepository`, allowing for easy mocking during tests.

### Supabase & Database

**Q10: What is Row Level Security (RLS) and why is it critical in VitaGuard?**
> **Answer**: RLS ensures that database queries are automatically filtered at the Postgres engine level based on the authenticated user. In VitaGuard, it guarantees a doctor cannot accidentally or maliciously query a patient they are not assigned to, which is a critical HIPAA/medical compliance requirement.

**Q11: How do you handle file uploads for X-Rays?**
> **Answer**: We use Supabase Storage. The file is uploaded to the `patient_documents` bucket using `supabase.storage.from().uploadBinary()`. Then, the returned file path is saved into the Postgres database. 

**Q12: Explain how Realtime WebSockets are used in the Alert System.**
> **Answer**: The app subscribes to Postgres changes on the `patient_live_vitals` table using `client.channel().onPostgresChanges()`. When hardware inserts a new row, Supabase broadcasts it to the app instantly, bypassing HTTP polling and saving battery/bandwidth.

**Q13: Why use an RPC function (`link_companion_to_patient`) for companion registration?**
> **Answer**: A companion registering doesn't yet have read access to the patient table due to RLS. By executing an RPC function with `security definer`, the function runs with elevated Postgres privileges, safely verifying the `companion_code` and inserting the relationship link securely on the server.

### AI & Machine Learning Integration

**Q14: Why execute the X-Ray Inference on-device (TFLite) instead of an API?**
> **Answer**: Medical privacy, zero-latency feedback, and offline capabilities. Uploading heavy X-Ray images takes bandwidth. Local inference via `tflite_flutter` processes the image instantly and keeps PHI (Personal Health Information) strictly on the user's device until they choose to sync it.

**Q15: Explain the softmax implementation in `_toProbs`.**
> **Answer**: The DenseNet121 model outputs raw unbounded logits. We apply a mathematical softmax function, using max-subtraction for numerical stability (`logit - max_logit`), to convert these raw numbers into probabilities that sum to 1.0 (0% to 100%).

**Q16: How does the AI Chatbot retain conversational context?**
> **Answer**: The app stores message history in the `ai_messages` table. When invoking the Supabase Edge Function, we pass the `conversationId`. The Edge Function reads the history from the database, formats it into a prompt payload for OpenAI/Gemini, and returns the contextual response.

### Performance & Offline Synchronization

**Q17: How does the Drift local database handle offline mode?**
> **Answer**: The app intercepts reads/writes. If offline, writes are saved into the Drift `SyncQueueItems` table. A background service monitors `ConnectivityPlus`. When the internet is restored, it iterates the queue and flushes the data to Supabase.

**Q18: What is the purpose of the `AlertTimerService` cooldown variables?**
> **Answer**: It prevents alert fatigue. If a patient's SpO2 hovers around the threshold (e.g., 91%, 92%, 91%), it would trigger hundreds of alerts. The cooldown ensures that after firing, a specific metric will not trigger another notification until a certain time (e.g., 45 seconds) has passed.

### Code & Safety Mechanics

**Q19: Explain the `AiResponseSanitizer` logic.**
> **Answer**: LLMs occasionally "leak" internal system prompts or thought processes (e.g., `<thought>I should act as a doctor</thought>`). The Sanitizer uses Regex to scrub these tags and blocked phrases to ensure the patient sees a purely clinical, professional response without hallucinated instructions.

**Q20: How does `ErrorMapper` improve User Experience?**
> **Answer**: Raw exceptions (like Postgres `23503` foreign key violation) confuse users. `ErrorMapper` intercepts these, checks the context (`ClinicalErrorArea`), and translates them into actionable medical-context UI messages like *"Your profile is still being prepared."*

---

## Part 7 — Code-Based Questions

**1. File:** `alert_evaluation_engine.dart`
* **Code Reference:** `_windows[key]!.add(val); if (_windows[key]!.length > 5) _windows[key]!.removeAt(0);`
* **Question:** What is this logic doing and why is it clinically necessary?
* **Answer:** It implements a Moving Average filter (sliding window of size 5). Hardware sensors produce noisy spikes. Averaging the last 5 readings smooths out artifacts before evaluating against critical thresholds, drastically reducing false positive alerts.
* **Advanced Follow-up:** How would you handle a situation where the sensor sends `null` or drastically outlier values (e.g., Temp = 0) within this window? (Answer: Add outlier rejection or standard deviation checks before adding to the window).

**2. File:** `auth_provider.dart`
* **Code Reference:** `await _waitForSessionRestoration();` in `_init()`
* **Question:** Why is there a specific method waiting for session restoration?
* **Answer:** Supabase Auth stores the JWT token in secure storage. Retrieving it is asynchronous. If the app immediately checks `currentSession` on boot, it might return null because the read hasn't finished, causing a false logout. This waits up to 2 seconds for the SDK to restore the session.

**3. File:** `schema.sql`
* **Code Reference:** `id uuid primary key references profiles(id) on delete cascade`
* **Question:** In the `patients` table, why does `id` reference `profiles(id)` instead of `auth.users`?
* **Answer:** This is a normalized design (Table Inheritance). `auth.users` is managed by Supabase. `profiles` holds shared app-specific data (name, phone). `patients` holds role-specific data. By cascading from `profiles` to `patients`, deleting a profile cleanly wipes the specialized data.

---

## Part 8 — Design Decisions

### 1. Feature-First vs Layer-First Folder Structure
* **Decision**: We grouped files by feature (`lib/features/chatbot`, `lib/features/vitals`) rather than strictly by type (`lib/screens`, `lib/models`).
* **Pros**: Highly scalable. If a developer works on the Chatbot, everything (data, domain, UI) is in one folder. Easier to delete or isolate features.
* **Cons**: Shared widgets or models can become tricky to place (hence the `lib/core` or `shared` folders).

### 2. Utilizing Riverpod for State Management
* **Decision**: Replaced standard `setState` or `Provider` with Riverpod.
* **Pros**: Compile-time safety. Code generation (`@riverpod`) eliminates boilerplate. Global accessibility without BuildContext.
* **Cons**: Steeper learning curve. Relies heavily on `build_runner` generation.

### 3. On-Device AI vs Cloud AI for X-Rays
* **Decision**: Deployed a TFLite model inside the app rather than calling a Python REST API.
* **Pros**: Works offline. Immediate results. Cheaper (no server GPU costs). Fully compliant with data privacy laws (images don't leave the phone for initial screening).
* **Cons**: App size increases by ~20-50MB. Cannot update the model dynamically without an app store update.

### 4. Supabase over Firebase
* **Decision**: Migrated to Supabase.
* **Pros**: Postgres relational database natively handles complex clinical linkages (Doctors -> Patients -> Vitals) much better than NoSQL Document structures. Built-in SQL RPC functions.
* **Cons**: Requires solid SQL knowledge. RLS can be difficult to debug compared to Firebase rules.

---

## Part 9 — Weaknesses & Defense

### 1. App Size due to AI Models
* **Criticism:** The `.tflite` model makes the APK/IPA file size quite large.
* **Defense:** While true, the trade-off is zero-latency life-saving diagnostics and strict HIPAA compliance.
* **Improvement:** In V2, we can implement On-Demand Resource downloading (fetching the AI model from Supabase Storage on first use instead of bundling it).

### 2. Dependency on Network for Chatbot
* **Criticism:** If the user is offline, the AI Chatbot fails.
* **Defense:** LLMs require massive computing power unavailable on current mobile devices. The app gracefully catches network errors and informs the user. 
* **Improvement:** Cache predefined FAQs locally.

### 3. Real-time Battery Drain
* **Criticism:** Continuous WebSockets (`patient_live_vitals`) will drain the battery on the doctor's device.
* **Defense:** Subscriptions are tied to the Widget lifecycle. When the doctor backgrounds the app, the connection pauses.
* **Improvement:** Utilize Firebase Cloud Messaging (FCM) via Supabase webhooks to wake the device ONLY when an alert threshold is breached, instead of streaming all normal vitals to the doctor's phone.

---

## Part 10 — Most Important Questions

### 5 Essential Questions
1. How does the architecture separate UI from Business Logic?
2. Explain how the app transitions between online and offline states.
3. Walk me through the code execution when a hardware sensor triggers a "Critical SpO2" alert.
4. How is user data secured so Patient A cannot read Patient B's data?
5. Describe the lifecycle of the TFLite X-Ray image processing from camera to result.

### 5 Advanced Technical Questions
1. Explain the mechanism inside `xray_inference_service_io.dart` that prevents memory leaks when allocating tensors.
2. How does the Riverpod `@Riverpod(keepAlive: true)` annotation affect garbage collection of state?
3. Describe the vulnerability of LLM Prompt Injection and how `AiResponseSanitizer` mitigates it.
4. What happens in the Drift SyncQueue if a database write conflicts with a newer server timestamp?
5. How does Supabase handle connection pooling when thousands of devices open Realtime WebSocket connections?

---

## Part 11 — Final Study Guide

**Review Checklist before Defense:**
- [ ] **Architecture**: Understand how `Controller` calls `Repository`, which calls `Supabase/Drift`. Be able to draw this flow.
- [ ] **Database**: Memorize the schema relationships (`profiles` -> `patients` -> `assigned_doctor_id`).
- [ ] **Security (RLS)**: Be ready to explain the exact SQL logic protecting patient privacy.
- [ ] **AI Integration**: Understand the terms *Logits*, *Softmax*, *Image Normalization*, and *Tensor*.
- [ ] **State**: Explain `AsyncValue.when(data, error, loading)`.
- [ ] **Real-world Application**: Be prepared to answer "What if this was used in a real hospital today?" Focus on the `ErrorMapper` and `AlertEvaluationEngine` moving average logic as your main safety nets.

*Generated by VitaGuard AI Assistant.*
