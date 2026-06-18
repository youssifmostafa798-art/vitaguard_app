# VitaGuard — دليل التحضير لمناقشة مشروع التخرج

> **المشروع:** نظام مراقبة صحية عن بُعد مدعوم بالذكاء الاصطناعي  
> **المنصة:** Flutter + Supabase + ESP32 + TFLite  
> **تاريخ التحليل:** 18 يونيو 2026  
> **الدور:** كبير مهندسي Flutter / مُحاور تقني / مُقيِّم مشروع / مُراجع كود

---

## الجزء 1 — نظرة عامة على المشروع والمعمارية

### 1.1 ما هو VitaGuard؟

VitaGuard هو **نظام مراقبة صحية عن بُعد متعدد الأدوار** يربط المرضى والأطباء والمرافقين والمنشآت الطبية عبر **منصة Supabase لحظية**. ويضم:

- **جهاز ESP32 القابل للارتداء** الذي يبث العلامات الحيوية مباشرةً (BPM، SpO2، درجة الحرارة) عبر WebSocket
- **ذكاء اصطناعي على الجهاز** (DenseNet121 عبر TFLite) لاكتشاف الالتهاب الرئوي من صور أشعة الصدر
- **روبوت محادثة بالذكاء الاصطناعي** (Gemini/Gemma عبر وظائف الحافة في Supabase) لتقديم إرشادات صحية
- **معمارية Offline-first** مع قاعدة بيانات محلية Drift (SQLite) وطابور مزامنة
- **تحكم في الوصول حسب الدور** مع أربعة أدوار: Patient، Doctor، Companion، Facility

### 1.2 حزمة التقنيات

| الطبقة | التقنية | الغرض |
|-------|---------|-------|
| الواجهة الأمامية | Flutter 3.x / Dart ^3.11 | واجهة متعددة المنصات |
| الحالة | flutter_riverpod + riverpod_annotation | حالة تفاعلية + توليد كود |
| الخلفية | Supabase (PostgreSQL + RLS + Realtime) | المصادقة، قاعدة البيانات، التخزين، وظائف الحافة |
| الذكاء الاصطناعي (الأشعة) | tflite_flutter / DenseNet121 | مصنِّف التهاب رئوي على الجهاز |
| الذكاء الاصطناعي (الدردشة) | Google Gemini / Gemma عبر وظائف الحافة | روبوت إرشادات صحية |
| قاعدة البيانات المحلية | drift (SQLite) | ذاكرة مؤقتة بلا اتصال + طابور المزامنة |
| العتاد | ESP32 (محاكى) | قياسات BPM / SpO2 / درجة الحرارة |
| خط أنابيب ML | FastAI → PyTorch → ONNX → TFLite | خط تصدير النموذج |

### 1.3 المعمارية عالية المستوى
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
### 1.4 قرارات المعمارية الرئيسية

- **لماذا Riverpod بدلًا من BLoC؟** لأن الصياغة أبسط، والـ boilerplate أقل بفضل توليد الكود، وإمكانية الاختبار أفضل، والإزالة التلقائية مدمجة، ولا حاجة إلى classes للأحداث.
- **لماذا Supabase بدلًا من Firebase؟** لأنه مفتوح المصدر، وقابل للاستضافة الذاتية، ومرن مع PostgreSQL، ويقدم أمان Row-Level Security على مستوى قاعدة البيانات، ووظائف حافة مكتوبة بـ TypeScript/Deno.
- **لماذا TFLite على الجهاز بدلًا من الذكاء الاصطناعي السحابي للأشعة؟** للخصوصية (البيانات الطبية تبقى على الجهاز)، والقدرة على العمل دون اتصال، وزمن استجابة أقل، ودون تكاليف API.
- **لماذا Drift بدلًا من Hive/SQLite؟** لأنه يوفّر استعلامات آمنة نوعيًا مع توليد كود، ودعمًا مدمجًا للهجرات، واستعلامات علائقية، وتدفّقات تفاعلية.
- **لماذا Offline-first؟** لأن سيناريوهات الرعاية الصحية تعاني غالبًا من اتصال غير مستقر (المستشفيات، المناطق الريفية، الأقبية).

---

## الجزء 2 — التعمق في الميزات

### 2.1 المصادقة وإدارة الأدوار

- **مسار التسجيل:** `auth_repository.dart` يتعامل مع `registerPatient` و`registerDoctor` و`registerCompanion` و`registerFacility` — وكل واحدة تنشئ صفًا في `profiles` + صفًا في الجدول الخاص بالدور داخل معاملة واحدة
- **بوابة المصادقة:** `auth_gate.dart` — تراقب تغيّرات حالة المصادقة، وتوجّه إلى onboarding إذا كان المستخدم جديدًا، أو إلى shell خاص بالدور (`main_patient.dart`، `main_doctor.dart`، إلخ)
- **إكمال الملف الشخصي:** المستخدمون لأول مرة يرون شاشات onboarding لإدخال تفاصيل الملف الشخصي (النوع، العمر للمرضى؛ professional_id للأطباء)
- **ربط المرافق:** كود مرافق فريد مكوّن من 6 أحرف يتم إنشاؤه بواسطة وظيفة الحافة `generate_companion_code`، ثم يربط عبر دالة RPC `link_companion_to_patient` مع `SECURITY DEFINER`

### 2.2 مراقبة العلامات الحيوية للمريض

- **تدفق البيانات:** ESP32 → Supabase Realtime → تيار `SupabaseVitalsRepository` → مزوّد Riverpod → عناصر واجهة المستخدم
- **النموذج `PatientLiveVitals`:** `bpm` و`spo2` و`temperature` و`device_id` و`recorded_at`
- **الفئة `VitalThresholds`:** معدل القلب 60-120 bpm، وتحذير SpO2 < 92% / حرج < 88%، ودرجة الحرارة > 38.5°C / 39.5°C
- **`AlertEvaluationEngine`:** قواعد متعددة المتغيرات — مثلًا: HR > 120 + SpO2 < 90% = "combined distress"
- **`AlertTimerService`:** مؤقت بداية لمدة 45 ثانية مع تنعيم بنافذة متحركة، وwatchdog للبيانات القديمة لمدة 60 ثانية

### 2.3 تحليل الأشعة السينية (الذكاء الاصطناعي)

- **`XrayInferenceServiceIO`:** يحمّل نموذج DenseNet121 TFLite من الأصول (`assets/models/model.tflite`)، ويعالج الصور مسبقًا عند 320×320 (ملاحظة: سكربتات Python في خط الأنابيب تستخدم 224×224 — يوجد عدم تطابق!)، ثم يجري الاستدلال، ويطبق softmax، ويعيد التنبؤ + الثقة
- **النموذج `XRayResult`:** `is_valid` و`prediction` (Pneumonia/Normal) و`confidence` و`report_text` و`image_path`
- **تراكب Heatmap:** ميزة من المرحلة الثانية لعرض Grad-CAM على صورة الأشعة
- **دعم العمل دون اتصال:** تُخزن الأشعة محليًا، ويُوضع الرفع في طابور عبر `SyncQueueRepository`

### 2.4 روبوت المحادثة بالذكاء الاصطناعي

- **وظيفتا حافة:** `ai-chat/index.ts` (Gemini) و`chatbot/index.ts` (Gemma) — وكلتاهما تقدّمان ردودًا متدفقة
- **`AiIntentClassifier`:** تصنيف حتمي لرسائل المستخدم إلى: `emergency` و`warning` و`tip` و`question`
- **`AiResponseSanitizer`:** دفاع الواجهة الأمامية ضد تسرب الـ prompt — يزيل أسطر system prompt، ويصلح تنسيق Markdown، وينظّف المحتوى غير الآمن
- **`AiContentNormalizer`:** ينظّم الردود إلى فقرات وكتل نقطية
- **`QuickReplies`:** أسئلة متابعة مقترحة من الذكاء الاصطناعي تُخزَّن في عمود JSONB `ai_messages.quick_replies`

### 2.5 المزامنة دون اتصال

- **`SyscQueueRepository`:** عمليات CRUD على جدول Drift `sync_queue` مع حالات `pending` و`processing` و`done` و`failed`
- **`OfflineSyncService`:** يعالج عناصر الطابور — ويدعم أنواع العمليات `insert` و`upsert` و`function` و`rpc`
- **`ConnectivitySyncCoordinator`:** يراقب الاتصال عبر `connectivity_plus`، ويبدأ المزامنة عند عودة الاتصال مع debounce
- **`LocalCacheRepository`:** يخبّئ الملفات الشخصية والمرضى والأطباء والعلامات الحيوية والتاريخ الطبي للقراءة دون اتصال

### 2.6 التنبيهات اللحظية

- **`AlertRealtimeService`:** يشترك في جدول `medical_alerts` عبر Supabase Realtime
- **`AlertNotificationService`:** يعرض إشعارات محلية مع صوت صفارة ونمط اهتزاز قابلين للضبط
- **نموذج `AppAlert`:** `severity` (critical/warning/info) و`audience` (doctor/patient/companion) و`dedupe_key` و`source_event_id`
- **`AlertCenterProvider`:** مزوّد Riverpod مركزي من نوع Notifier لإدارة حالة التنبيهات، والتأكيد، والحل

### 2.7 الدردشة بين الطبيب والمريض

- **`ChatRepository`:** يبث الرسائل عبر اشتراك Supabase Realtime في جدول `messages`
- **`ensure_direct_doctor_conversation`:** دالة PostgreSQL للعثور على محادثة بين مريض وطبيب أو إنشائها
- **النموذج `Message`:** `content` و`sender_id` و`conversation_id` و`is_read` و`created_at`
- **`ChatPreview`:** آخر رسالة، وعدد غير المقروء، والطابع الزمني لقائمة المحادثات

---

## الجزء 3 — تحليل بنية المشروع

### 3.1 تخطيط المجلدات
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
### 3.2 نقاط القوة

- ✅ فصل واضح للمسؤوليات (core/data/features/presentation)
- ✅ نمط Repository لتجريد الوصول إلى البيانات
- ✅ عزل الميزات حسب الدور
- ✅ دعم شامل للعمل دون اتصال
- ✅ نمط Edge Function للمنطق على الخادم
- ✅ قاعدة بيانات آمنة مفعَّل فيها RLS
- ✅ معمارية بث لحظي للعلامات الحيوية

### 3.3 مجالات التحسين

- ⚠️ اتساق ضعيف في التسمية (`custem_text.dart` يجب أن يكون `custom_text.dart`)
- ⚠️ تضخم في ملفات utilities: هناك 18 ملفًا في `core/utils/` — وبعضها يمكن دمجه (مثل `custem_bottom.dart` و`custem_field.dart` و`simple_buttom.dart` التي تحتوي على أخطاء إملائية في الأسماء)
- ⚠️ يوجد اختبار وحدوي واحد فقط في المشروع كله مقابل 153+ ملفًا من ملفات المصدر
- ⚠️ `analysis_options.yaml` يستخدم `flutter_lints/flutter.yaml` الأساسي فقط — دون قواعد مخصصة
- ⚠️ عدم تطابق: الاستدلال على الأشعة يستخدم 320×320 بينما خط أنابيب Python يستخدم 224×224
- ⚠️ لا يوجد error boundary / wrapper على مستوى الواجهة — قد تظهر الأعطال كأخطاء خام

---

## الجزء 4 — مراجعة مخطط قاعدة البيانات والأمان

### 4.1 الجداول (18 جدولًا إجمالًا)

| الجدول | الغرض | الأعمدة الرئيسية |
|-------|-------|------------------|
| `profiles` | ملفات تعريف المستخدمين الشاملة | id, role, name, email, is_active, is_verified |
| `patients` | خاص بالمرضى | id, gender, age, companion_code, assigned_doctor_id |
| `doctors` | خاص بالأطباء | id, professional_id, verification_status, id_card_path |
| `companions` | خاص بالمرافقين | id, linked_patient_id |
| `facilities` | خاص بالمنشآت | id, address, facility_type, verification_status |
| `patient_medical_history` | السجل الطبي | patient_id (PK), allergies, medications, chronic_diseases |
| `patient_daily_reports` | التقارير الصحية اليومية | patient_id, heart_rate, oxygen_level, temperature |
| `patient_xray_results` | نتائج تحليل الأشعة | patient_id, prediction, confidence, report_text |
| `patient_documents` | المستندات المرفوعة | patient_id, file_path, document_type |
| `medical_feedback` | ملاحظات الطبيب على الأشعة | patient_id, doctor_id, xray_result_id, feedback_text |
| `facility_tests` | التحاليل المختبرية | facility_id, patient_id, test_type, file_path |
| `facility_offers` | عروض المنشآت | facility_id, title, description, image_path |
| `facility_appointments` | المواعيد | facility_id, patient_id, scheduled_at |
| `conversations` | محادثات الدردشة | id, last_message, last_message_at |
| `conversation_participants` | علاقة متعدد إلى متعدد | conversation_id, user_id (مفتاح مركب) |
| `messages` | رسائل الدردشة | conversation_id, sender_id, content, is_read |
| `patient_live_vitals` | العلامات الحيوية اللحظية | patient_id, device_id, bpm, spo2, temperature |
| `medical_alerts` | سجلات التنبيهات | patient_id, alert_type, alert_data, severity, dedupe_key |

### 4.2 الأمان (RLS)

- **الدوال المساعدة:** `is_admin()` و`is_owner()` و`assigned_doctor()` و`linked_companion()`
- **Profiles:** المستخدم يقرأ/يعدّل ملفه الشخصي فقط؛ المدير يقرأ الكل
- **Patients:** القراءة متاحة للمريض نفسه، والطبيب المعيّن، والمرافق المرتبط، والمدير
- **الجداول الفرعية الخاصة بالمريض (medical_history وxray_results وما إلى ذلك):** نفس نمط الوصول
- **Conversations:** المشاركون فقط
- **Messages:** المشاركون فقط
- **Facility offers:** قراءة عامة (لا تحتاج مصادقة)
- **سياسات التخزين:** ملكية مبنية على المسار (`split_part(name, '/', 1) = owner_id`)

**نتائج المراجعة الأمنية:**
- ✅ RLS مفعّل على جميع الجداول
- ✅ `SECURITY DEFINER` على الدوال المساعدة مع `search_path = public`
- ✅ سياسات التخزين تطابق أنماط RLS للجداول
- ✅ مفاتيح dedupe على التنبيهات تمنع المعالجة المكررة
- ⚠️ `facility_offers` لديه قراءة عامة — وهذا مقبول لميزة "العروض"

### 4.3 وظائف الحافة (11 وظيفة إجمالًا)

| الوظيفة | المُشغِّل | الغرض |
|----------|----------|-------|
| `hardware_telemetry` | POST من ESP32 | يستقبل العلامات الحيوية، ويبني مرشحات التنبيه، ويوصلها للمرافقين/الأطباء |
| `ai-chat` | طلب دردشة | يبث ردود Gemini بالذكاء الاصطناعي |
| `chatbot` | طلب دردشة | يبث ردود Gemma مع تنقية الأمان |
| `xray-inference` | رفع الأشعة | استدلال سحابي احتياطي قائم على HuggingFace |
| `upload_xray_result` | رفع إلى التخزين | يرفع صورة الأشعة + ينشئ سجلًا |
| `upload_medical_record` | رفع إلى التخزين | يرفع المستند الطبي |
| `upload_lab_report` | رفع إلى التخزين | يرفع التقرير المخبري |
| `upload_doctor_verification` | رفع إلى التخزين | يرفع بطاقة هوية الطبيب |
| `upload_lab_offer` | رفع إلى التخزين | يرفع صورة عرض المختبر + ينشئ سجلًا |
| `review_doctor_verification` | إجراء إداري | قبول/رفض توثيق الطبيب |
| `review_facility_verification` | إجراء إداري | قبول/رفض توثيق المنشأة |
| `generate_companion_code` | إجراء المريض | يولّد رمزًا فريدًا من 6 أحرف |

## الجزء 5 — أسئلة المقابلة والإجابات النموذجية

### 5.1 المعمارية والتصميم (30 سؤالًا)

**س1: لماذا اخترتم Riverpod بدلًا من BLoC أو Provider؟**
> اخترنا Riverpod لعدة أسباب: (1) **أمان على مستوى الترجمة** — Provider قد يعطي أخطاء وقت التشغيل عند نسيان provider، بينما Riverpod يلتقطها أثناء الترجمة. (2) **توليد الكود** عبر `riverpod_annotation` يقلل الـ boilerplate بشكل كبير — لا نحتاج إلى كتابة classes للأحداث أو الحالة أو blocs. (3) **الإزالة المدمجة** — عندما لا يعود provider مُستَمعًا إليه، يتم التخلص منه تلقائيًا، مما يمنع تسرب الذاكرة. (4) **قابلية الاختبار** — يمكننا استبدال أي provider بسهولة في الاختبارات دون widget trees. وبالنسبة لمشروع تخرج يضم 153+ ملفًا، كان هذا مكسبًا كبيرًا في الإنتاجية.

**س2: اشرح معمارية العمل دون اتصال.**
> طبقنا Offline-first على مستويين: (1) **ذاكرة محلية** عبر Drift (SQLite) — يتم تخزين الملفات الشخصية والمرضى والأطباء وأحدث العلامات الحيوية محليًا حتى يظل التطبيق قابلًا للاستخدام دون إنترنت. (2) **طابور مزامنة** — عندما ينفذ المستخدم عملية كتابة دون اتصال (مثل رفع أشعة أو إرسال رسالة)، تُخزَّن العملية في جدول `sync_queue` بالحالة `pending`. يراقب `ConnectivitySyncCoordinator` حالة الشبكة ويُشغّل `OfflineSyncService` عند عودة الاتصال، والذي يعالج كل عنصر بالترتيب ويحدّث الحالة إلى `done` أو `failed`. هذا يضمن عدم فقدان البيانات حتى مع الاتصال المتقطع.

**س3: كيف يعمل Row-Level Security في إعداد Supabase لديكم؟**
> يضمن RLS أن المستخدمين لا يصلون إلا إلى البيانات المصرح بها لهم. أنشأنا دوال مساعدة مثل `is_owner()` و`assigned_doctor()` و`linked_companion()` تتحقق من UUID الخاص بالمستخدم المصادَق عليه مقابل البيانات. ولكل جدول نعرّف سياسات مثل "patients read" التي تسمح بالوصول إذا كان المستخدم هو المريض نفسه، أو الطبيب المعيّن، أو المرافق المرتبط، أو المدير. الفكرة الأساسية أن RLS يُفرض على مستوى قاعدة البيانات — حتى لو أرسل العميل استعلامًا مُفبركًا، فلن يتمكن من تجاوز السياسات.

**س4: ما هو فصل الأدوار في التطبيق؟**
> هناك أربعة أدوار: (1) **Patient** — يعرض علاماته الحيوية، ويرفع الأشعة لتحليلها بالذكاء الاصطناعي، ويتحدث مع روبوت الدردشة، ويراسل الطبيب المعيّن، ويعرض التاريخ الطبي. (2) **Doctor** — يعرض العلامات الحيوية للمرضى المعيَّنين لحظيًا، ويتلقى التنبيهات، ويقدم ملاحظات على الأشعة، ويراسل المرضى. (3) **Companion** — يرتبط بمريض عبر رمز فريد، ويمكنه رؤية العلامات الحيوية والتنبيهات، ويعمل كمراقب/مرافق. (4) **Facility** — يدير الاختبارات المعملية، ويرفع العروض، ويدير المواعيد. ولكل دور shell widget خاص مع تنقل مخصص.

**س5: كيف تتعاملون مع بث العلامات الحيوية لحظيًا؟**
> يرسل جهاز ESP32 البيانات عبر HTTP POST إلى وظيفة الحافة `hardware_telemetry`. تقوم هذه الوظيفة بإدخال البيانات في جدول `patient_live_vitals` الذي يملك Realtime publication. على جانب Flutter، يشترك `SupabaseVitalsRepository` في تغييرات Realtime على `patient_live_vitals` مع فلترة `patient_id`، ويعيد `Stream<PatientLiveVitals>` في Dart. يحوّل المزود هذا stream إلى حالة الواجهة. ويعمل `AlertEvaluationEngine` على كل قراءة جديدة، ويطبق فحوصات العتبات والقواعد متعددة المتغيرات. وإذا تحقق شرط تنبيه، ينتظر 45 ثانية (عبر `AlertTimerService` مع تنعيم بنافذة متحركة) قبل إنشاء التنبيه لتجنب الإيجابيات الكاذبة الناتجة عن الارتفاعات العابرة.

**س6: صف خط أنابيب استدلال الأشعة السينية بالذكاء الاصطناعي.**
> نبدأ بنموذج DenseNet121 مدرَّب عبر FastAI ومصدَّر بصيغة `export.pkl`. ثم تحوّل سكربتات Python النموذج إلى ONNX، وتتحقق من التطابق مع PyTorch، ثم تحوّل ONNX إلى TFLite عبر `onnx2tf`. وبعد ذلك يُضمَّن نموذج TFLite داخل الأصول. على الجهاز، يحمّل `XrayInferenceServiceIO` النموذج، ويعالج الصورة مسبقًا (إعادة التحجيم، والتطبيع بإحصاءات ImageNet)، ثم يجري الاستدلال، ويطبق softmax للحصول على احتمالات الفئات، ويعيد التنبؤ ("Pneumonia" أو "Normal") مع الثقة. وميزة تراكب heatmap (المرحلة 2) ستعرض مناطق انتباه النموذج عبر Grad-CAM.

**س7: كيف يعمل روبوت المحادثة بالذكاء الاصطناعي؟**
> توجد وظيفتا حافة كخلفية: `ai-chat` (Gemini) و`chatbot` (Gemma). كلتاهما تستقبلان تاريخ المحادثة ومحتوى رسالة المستخدم، وتبثان الرد مرة أخرى. على جانب Flutter، يدير `AiChatRepository` المحادثات والرسائل في Supabase، بينما يتولى المزود حالة البث. الميزات الأساسية: (1) **تصنيف النية** — مطابقة حتمية للكلمات المفتاحية تصنف الرسائل إلى emergency/warning/tip/question. (2) **التنقية** — `AiResponseSanitizer` يزيل نصوص النظام المتسربة ويصلح Markdown في الواجهة والخلفية. (3) **تنظيم المحتوى** — يبني الردود في كتل. (4) **الردود السريعة** — يولّد الذكاء الاصطناعي أسئلة متابعة مقترحة تُخزَّن بصيغة JSONB.

**س8: لماذا يوجد وظيفتا حافة منفصلتان لروبوت الدردشة؟**
> يستخدم `ai-chat` نموذج Gemini Pro من Google للاستفسارات الطبية الأكثر تعقيدًا التي تتطلب استدلالًا أعمق حول العلامات الحيوية والأعراض. أما `chatbot` فيستخدم Gemma (أصغر وأسرع) للإرشادات الصحية العامة والردود السريعة. كما أن `chatbot` يمتلك تنقية أكثر صرامة لأنه الواجهة الأساسية للمستخدم. هذا الفصل يسمح لنا بتحسين التكلفة وزمن الاستجابة — Gemma للأسئلة البسيطة وGemini للأسئلة المعقدة.

**س9: اشرح استراتيجية إزالة التكرار في التنبيهات.**
> لكل تنبيه عمود `dedupe_key` مع قيد فريد مع `patient_id` و`is_resolved`. ينشئ الخادم المفتاح عبر تجزئة `alert_type + patient_id + metric_values`. إذا كان هناك تنبيه بنفس المفتاح و`is_resolved = false`، يتم تجاوز الإضافة الجديدة (ويُحدَّث فقط `last_seen_at`). هذا يمنع طوفان التنبيهات عندما تتجاوز عدة قراءات متتالية الحدود. وبمجرد تأكيد التنبيه (من الطبيب أو المريض)، تُضبط `is_resolved` إلى true، مما يسمح بتنبيهات جديدة من النوع نفسه.

**س10: كيف تتعاملون مع الردود المتدفقة من روبوت الدردشة بالذكاء الاصطناعي؟**
> تبث وظيفة الحافة رد الذكاء الاصطناعي على شكل SSE (Server-Sent Events). وعلى جانب العميل، يشترك `AiChatRepository` في جدول `ai_messages` عبر Realtime، والذي يستقبل المحتوى المتدفق صفًا بعد صف. يحافظ المزود على متغير حالة `streamingContent` الذي يكبر مع وصول الأجزاء. وعند اكتمال البث، تتغير حالة الرسالة من `streaming` إلى `complete`، ويُنهى المزود الرسالة. ويرسم عنصر `AiMessageBubble` المحتوى الجزئي في الوقت الحقيقي باستخدام نمط شبيه بـ `StreamBuilder`.

**س11-30:** (تغطي الأسئلة الإضافية: Riverpod providers مقابل ChangeNotifier، هجرات Drift، سياسات Supabase Storage، توليد companion code، دوال `SECURITY DEFINER`، نافذة المؤقت 45 ثانية للتنبيه، watchdog للبيانات القديمة، المصادقة البيومترية، تراكب heat map للأشعة، إعادة تشغيل طابور عدم الاتصال، debounce في connectivity coordinator، والمزيد.)

### 5.2 Flutter وDart (30 سؤالًا)

**س11: كيف تديرون الحالة باستخدام Riverpod في هذا المشروع؟**
> نستخدم `riverpod_annotation` لتوليد الكود. كل provider يُوسم بـ `@riverpod` ويولّد ملفًا `.g.dart`. لدينا: `StateNotifierProvider` لمتحكمات مثل `authProvider` و`patientProvider`; و`StreamProvider` للعلامات الحيوية اللحظية; و`FutureProvider` لجلب لمرة واحدة مثل تعيينات الأطباء; و`NotifierProvider` لحالة مركز التنبيهات. يتم التخلص من providers تلقائيًا عندما لا تكون قيد الاستخدام. كما نستبدل providers في الاختبارات للمحاكاة.

**س12: كيف يعمل عنصر `AuthGate`؟**
> `AuthGate` هو العنصر الجذري بعد شاشة البداية. يستخدم `ref.watch(authProvider)` لمراقبة حالة المصادقة تفاعليًا. إذا كانت `null` يعرض `AuthScreen`. وإذا كان المستخدم مصادَقًا لكن الملف غير مكتمل، يعرض `OnboardingScreen`. وإذا كان مكتملًا، يتحقق من `role` ويوجّه إلى shell المناسب: `MainPatient` أو `MainDoctor` أو `MainCompanion` أو `MainFacility`. وكل shell يستخدم `IndexedStack` مع `FlexibleNavBar` للتنقل بين التبويبات.

**س13: اشرح إعداد قاعدة بيانات Drift.**
> نعرّف الجداول كفئات Dart ترث من `Table` مع annotations الخاصة بـ Drift. وفئة قاعدة البيانات `VitaGuardLocalDatabase` ترث من `$VitaGuardLocalDatabase` (المولَّدة). لدينا 7 جداول ذاكرة مؤقتة: `CachedProfiles` و`CachedPatients` و`CachedDoctors` و`CachedVitals` و`CachedMedicalHistory` و`CachedConversations` و`CachedMessages`. بالإضافة إلى جدول `sync_queue` لعمليات العمل دون اتصال. يتم تهيئة ملف قاعدة البيانات بكسل في `main.dart` ثم تمريره عبر شجرة الواجهة أو الوصول إليه عبر providers.

**س14: كيف تتعاملون مع الأخطاء في سياق سريري؟**
> لدينا `ClinicalErrorArea` enum (auth, supabase, database, ai, vitals, chat, sync, storage, general) وفئة `ErrorMapper` التي تربط أخطاء Supabase من نوع `AuthException` و`PostgrestException` وغيرها برسائل موجهة للمستخدم مع سياق سريري. يوفر نظام `ClinicalFeedback` رسائل toast، وطبقات popup، واستجابة اهتزازية مع دعم الوصول (إعلانات قارئ الشاشة). الرسائل مصاغة بصيغة مناسبة للسياق الطبي (مثل: "تعذر تحميل العلامات الحيوية. يُرجى التحقق من الاتصال.")

**س15-40:** (تغطي الرسامّات المخصصة، متحكمات الحركة، `ScreenUtil` للتجاوب، الفرق بين `IndexedStack` و`PageView`, `flutter_lints`, توليد `.g.dart`, قنوات المنصة مع `tflite_flutter`, تدفقات `connectivity_plus`, إعداد `flutter_local_notifications`, و25 سؤالًا إضافيًا خاصًا بـ Dart/Flutter.)

### 5.3 Supabase والخلفية (20 سؤالًا)

**س41: ما الجداول الموجودة في قاعدة البيانات وكيف ترتبط؟**
> يوجد 18 جدولًا إجمالًا. الأساس: `profiles` (الهوية المركزية) مع جداول فرعية 1:1 هي `patients` و`doctors` و`companions` و`facilities`. الطبي: `patient_medical_history` (1:1 مع المرضى) و`patient_daily_reports` و`patient_xray_results` و`patient_documents`. الدردشة: `conversations` → `conversation_participants` (many-to-many) → `messages`. المنشآت: `facility_tests` و`facility_offers` و`facility_appointments`. العلامات الحيوية: `patient_live_vitals` و`medical_alerts`.

**س42: كيف يتم تأمين تدفق ربط المرافق؟**
> تُعرَّف الدالة `link_companion_to_patient` على أنها `SECURITY DEFINER` مع `search_path = public`. تأخذ رمز المرافق (سلسلة فريدة من 6 أحرف)، ثم تبحث عن المريض بمطابقة الرمز دون حساسية لحالة الأحرف، ثم تُدرج/تُحدّث سجل المرافق. نقوم بـ `GRANT EXECUTE` لكل من `authenticated` و`anon` لأن المستخدم قد لا يكون مصادَقًا بعد عند إدخال الرمز. وتتحقق الدالة من أن المستخدم المستهدف موجود في `auth.users` قبل المتابعة.

**س43: اشرح معمارية توزيع التنبيهات اللحظية.**
> تضبط ترقية `alerting_realtime_alerts.sql` ما يلي: (1) جدول `medical_alert_deliveries` لتتبع حالة التسليم لكل مستلم. (2) الدالة `can_receive_medical_alert_broadcast()` التي تتحقق من أن المستخدم المصادَق عليه طبيب أو مريض أو مرافق مرتبط بمريض التنبيه. (3) trigger باسم `trg_broadcast_medical_alert_changes` على `medical_alerts` يستدعي `broadcast_medical_alert_changes()`، والذي يستخدم `pg_notify` للبث عبر Realtime. (4) دالة RPC `acknowledge_medical_alert()` لوضع علامة تأكيد على التنبيهات.

**س44-60:** (تغطي امتداد `pgcrypto`، بنية حاويات التخزين، publication `supabase_realtime` لـ `ai_messages`, فلترة PostgREST للتدفقات، مفاتيح `gen_random_uuid()` الأساسية، معالجة أخطاء Edge Function، رؤوس CORS في `_shared/`, thread safety في `supabase_service.dart`، والمزيد.)

### 5.4 الذكاء الاصطناعي/تعلم الآلة (15 سؤالًا)

**س61: ما معمارية النموذج المستخدم في مصنف الأشعة السينية؟**
> DenseNet121 (Densely Connected Convolutional Networks) بطبقات عددها 121. النموذج المدرَّب عبر FastAI يملك head مخصصًا: `AdaptiveConcatPool2d` (يجمع avg وmax pooling) → BatchNorm → Dropout(0.25) → Linear(2048→512) → ReLU → BatchNorm → Dropout(0.5) → Linear(512→2). الطبقة الأخيرة تُخرج 2 logits (Normal مقابل Pneumonia). نطبق softmax أثناء الاستدلال.

**س62: ما دقة الإدخال ولماذا 320×320 مقابل 224×224؟**
> يستخدم تطبيق Flutter قيمة 320×320، لكن خط أنابيب التدريب في Python يستخدم 224×224 (وهو الحجم القياسي لـ ImageNet). هذا عدم تطابق يحتاج إلى تحقيق — ويرجّح أنه خطأ. تم تصدير نموذج TFLite من ONNX ذي 224×224، لكن خدمة الاستدلال تعيد تحجيم الصور إلى 320×320. سيؤدي هذا إلى تنبؤات غير صحيحة لأن السمات التي تعلّمها النموذج تعتمد على المقياس. يجب تصحيح ذلك ليطابق حجم التدريب.

**س63: كيف تحققتُم من خط أنابيب تصدير النموذج؟**
> لدينا `parity_check_pt_onnx_tflite.py` الذي يشغّل الصورة نفسها عبر ثلاثة صيغ: (1) PyTorch عبر fastai learner، (2) ONNX عبر onnxruntime، (3) TFLite عبر TensorFlow Lite interpreter. يقارن logits ويعرض فروق max/mean. ويضيف السكربت `export_verify_tflite.py` بوابة parity توقف خط الأنابيب إذا تجاوز الفرق بين PT وONNX العتبة (الافتراضي 1e-3).

**س64-75:** (تغطي معايرة softmax، عتبات الثقة، pooling التكيفي مقابل الثابت، إصدار ONNX opset 18، تحويل onnx2tf، quantization، توليد heatmap (Grad-CAM)، fallback الخاص بـ HuggingFace، إصدار النموذج في قاعدة البيانات، والمزيد.)

### 5.5 ESP32 وIoT (10 أسئلة)

**س76: كيف يتواصل ESP32 مع الخلفية؟**
> يرسل ESP32 طلبات HTTP POST إلى وظيفة الحافة `hardware_telemetry` الخاصة بـ Supabase. وتتضمن الحمولة `device_id` و`bpm` و`spo2` و`temperature` و`recorded_at`. تقوم وظيفة الحافة بالمصادقة عبر token خاص بالجهاز، وتتحقق من صحة البيانات، وتدرجها في `patient_live_vitals`, وتشغّل تقييم التنبيه، وإذا تم تجاوز الحدود، تنشئ سجل `medical_alert` وتبثه عبر Realtime.

**س77: ماذا يحدث إذا فقد ESP32 الاتصال؟**
> لدى ESP32 مخزن محلي يحتفظ بالقراءات عند عدم الاتصال. وعند إعادة الاتصال، يرسل البيانات المخزنة دفعة واحدة. تضمن منطقية إزالة التكرار في وظيفة الحافة (عبر `source_event_id`) تجاهل القراءات المكررة. وسيُظهر watchdog للبيانات القديمة لمدة 60 ثانية داخل `AlertTimerService` على جانب Flutter تنبيه "device disconnected" إذا لم تصل بيانات جديدة ضمن النافذة.

**س78-85:** (تغطي تهيئة الجهاز، رمز المرافق لاقتران الجهاز، معدل البيانات، إدارة الطاقة، ESP32 deep sleep، إدارة بيانات WiFi، تحديثات OTA، وrate limiting في وظائف الحافة.)

### 5.6 إدارة المشروع والمنهجية (10 أسئلة)

**س86: ما حجم الفريق وما هو دورك؟**
> [خصّص هذا حسب حالتك]

**س87: كيف أدرت الجدول الزمني للمشروع؟**
> [خصّص هذا]

**س88-95:** (تغطي التحديات التي واجهتها، الأدوات المستخدمة، استراتيجية الاختبار، النشر، الخطط المستقبلية، قابلية التوسع، والدروس المستفادة.)

### 5.7 الأمان والخصوصية (10 أسئلة)

**س96: كيف يتم حماية البيانات الطبية للمريض؟**
> (1) **أثناء النقل:** استخدام HTTPS لكل استدعاءات API، وقنوات Supabase موثَّقة. (2) **أثناء التخزين:** سياسات RLS تضمن أن المستخدمين لا يصلون إلا إلى بياناتهم أو البيانات المصرح لهم بها. (3) **على الجهاز:** قاعدة بيانات Drift مشفَّرة على مستوى نظام التشغيل. (4) **التخزين:** كل حاويات التخزين الطبية (xray-results وmedical-records وdoctor-verifications) خاصة. (5) **معالجة الذكاء الاصطناعي:** وجود TFLite على الجهاز يعني أن الأشعة لا تغادر الهاتف للاستدلال. (6) **المصادقة:** Supabase Auth مع JWT tokens وauto-refresh.

**س97: ماذا عن روبوت الدردشة — هل تنتقل رسائل المرضى إلى خوادم Google؟**
> نعم، روبوت الدردشة يستخدم Gemini/Gemma عبر وظائف الحافة في Supabase، والتي تستدعي واجهة Google. اعتبرنا ذلك مقايضة ضرورية لأن تشغيل LLM طبي على الجهاز غير عملي. ومع ذلك: (1) تُزال المعلومات الشخصية PII من جانب العميل، (2) نسجل التفاعلات للجودة لكن بعد إزالة المعلومات التعريفية، (3) يوجّه system prompt الذكاء الاصطناعي صراحةً إلى عدم تخزين أو مشاركة البيانات الشخصية.

**س98: كيف تمنعون prompt injection في روبوت الدردشة؟**
> عبر ثلاث طبقات: (1) **تنقية الخلفية** — مصفوفة regex باسم `BLOCKED_LINE_PATTERNS` في وظيفة الحافة تلتقط system prompts المتسربة وتحجبها. (2) **الدالة `isUnsafe()`** — تتحقق مما إذا كان الرد يكرر prompt المستخدم أو يحتوي على أنماط غير آمنة معروفة. (3) **تنقية الواجهة الأمامية** — `AiResponseSanitizer` يعمل على كل رسالة واردة، ويزيل أي تسرب متبقٍ من system prompt، وأي user echo، ويصلح Markdown. كما لدينا المستند `plans/chatbot_prompt_leakage_fix.md` الذي يوثق هذا الدفاع.

**س99-105:** (تغطي المصادقة البيومترية، إدارة الجلسات، تسجيل التدقيق، الاحتفاظ بالبيانات، GDPR/الامتثال، Supabase MFA، وإدارة API key.)

### 5.8 النشر وDevOps (10 أسئلة)

**س106: كيف يتم نشر التطبيق؟**
> تطبيق Flutter: يتم بناؤه عبر `flutter build apk` / `flutter build ios` ثم نشره على المتاجر المناسبة. Supabase: تتم إدارته عبر Supabase CLI — `supabase db push` للهجرات، و`supabase functions deploy` لوظائف الحافة. أما سكربتات Python فهي أدوات تطوير لتحويل النموذج.

**س107: كيف تديرون الإعدادات الخاصة بكل بيئة؟**
> يتم حقن Supabase URL وanon key عبر `--dart-define` وقت البناء، ثم الوصول إليهما في `supabase_config.dart` بواسطة `String.fromEnvironment()`. وهذا يتيح إعدادات مختلفة للتطوير/الاختبار/الإنتاج دون hardcoding للأسرار.

**س108-115:** (تغطي CI/CD، التطوير المحلي لـ Supabase، `supabase db diff`، إصدار وظائف الحافة، نسخ التخزين الاحتياطية، المراقبة، التحليلات، وقياس الأداء.)

### 5.9 أسئلة خاصة بالكود (20 سؤالًا)

**س116: ماذا يفعل `ref.listen` مقارنةً بـ `ref.watch` في قاعدة الكود هذه؟**
> `ref.watch` يعيد بناء الـ widget عندما تتغير حالة provider — ويستخدم في الشاشات والـ widgets التي تعرض البيانات. أما `ref.listen` فينفذ callback عند تغير الحالة دون إعادة البناء — ويستخدم في `main_doctor.dart` للاشتراك في بث التنبيهات (عرض snackbar/dialog عند وصول تنبيه جديد دون إعادة بناء shell بالكامل).

**س117: اشرح mapping للأوزان في فئة `FastaiDenseNet121`.**
> يخزن fastai learner الأوزان بمفاتيح مثل `0.0.features.0.0.weight` (طبقات body) و`1.0.weight` (طبقات head). وبما أننا نعرّف النموذج يدويًا باستخدام `self.body` و`self.head`، فإن السكربت يعيد تعيين المفاتيح: `0.0.*` → `body.*`، و`0.1.*` → `body.*`، و`1.*` → `head.*`. وهذا يسمح بتحميل checkpoint الخاص بـ fastai داخل نموذج PyTorch العادي لأجل التصدير إلى ONNX.

**س118-135:** (تغطي أسطر محددة: أنماط `_stripSystemPromptLeakage`، ومنطق `AlertTimerService._resetOnsetTimer`، وتوزيع العمليات في `OfflineSyncService.processQueueItem`، ومؤقت debounce في `ConnectivitySyncCoordinator`، ومطابقة الأنماط في `ErrorMapper`، وأنماط الاهتزاز في `ClinicalFeedback`، وبث الرسائل في `AiChatRepository`, وهيكل الكتل في `AiContentNormalizer`, وSQL في `ensure_direct_doctor_conversation`, وRPC `acknowledge_medical_alert`, ووظيفة `generate_companion_code`, والمزيد.)

### 5.10 التفكير النقدي والحالات الحدّية (15 سؤالًا)

**س136: ماذا يحدث إذا رفع المستخدم صورة أشعة غير خاصة بالصدر؟**
> النموذج مدرَّب على أشعة الصدر فقط. يُفترض أن يلتقط `is_valid` في نموذج النتيجة هذا، لكن لا يوجد حاليًا ترشيح مسبق. ستنتج الصورة غير الخاصة بالصدر تنبؤًا ربما بثقة منخفضة، لكن من دون رفض صريح. هذه نقطة تحتاج تحسينًا — يمكننا إضافة مصنف ثنائي كبوابة قبل DenseNet.

**س137: كيف تتعاملون مع التقييم المتزامن للتنبيهات من عدة أجهزة؟**
> لكل تنبيه `dedupe_key` على `(patient_id, dedupe_key, is_resolved)`. إذا قامت جهتان (مثل ESP32 وإدخال يدوي) بإطلاق التنبيه نفسه في الوقت نفسه، يفشل الإدخال الثاني بسبب الفهرس الفريد، ويتم تحديث `last_seen_at` للتنبيه الموجود بدلًا من إنشاء تنبيه جديد.

**س138-150:** (تغطي: ماذا لو قدّم الذكاء الاصطناعي نصيحة طبية خاطئة، ماذا لو تعارضت مزامنة العمل دون اتصال، ماذا لو ادعى طبيبان نفس المريض، ماذا لو تم تخمين companion code بالقوة، ماذا لو أرسل ESP32 بيانات لمريض غير مسجّل، ماذا لو فشل تحميل نموذج TFLite، ماذا لو فشلت هجرة Drift، ماذا لو انقطع اشتراك Realtime، ماذا لو لم يكن لدى المستخدم طبيب معيّن لكنه حاول الدردشة، ماذا لو رفعت المنشأة محتوى خبيثًا، ماذا لو منعت RLS الوصول الشرعي، ماذا لو انقطع بث رد روبوت الدردشة، ماذا لو تعذر التحقق البيومتري.)

### 5.11 العرض التقديمي والديمو (10 أسئلة)

**س151: ما أكثر ميزة مبهرة لعرضها؟**
> المراقبة اللحظية للعلامات الحيوية باستخدام جهاز ESP32 القابل للارتداء — حيث تُشاهَد BPM وSpO2 تُحدَّث مباشرة على الشاشة مع تفعيل التنبيهات عندما تتجاوز القيم الحدود. كما أن تحليل الأشعة بالذكاء الاصطناعي بصري جدًا ومبهر — حيث تُعرض الصورة المرفوعة وتراكب heatmap وتنبؤ الذكاء الاصطناعي مع درجة الثقة.

**س152-160:** (تغطي إعداد العرض الحي، خطة بديلة إذا فشل الديمو، كيفية شرح الذكاء الاصطناعي، ما المقاييس التي يجب إبرازها، كيفية إدارة الأسئلة والأجوبة، إلخ.)

### 5.12 العمل المستقبلي والقابلية للتوسع (10 أسئلة)

**س161-170:** (تغطي إضافة دعم ECG، تعدد اللغات، تكامل FHIR، التشغيل البيني مع HL7، مكالمات فيديو طب عن بُعد، سوق للأجهزة القابلة للارتداء، ميزات التجارب السريرية، تحديثات نموذج ML عبر OTA، التوافق مع HIPAA، والتوسع باستخدام Kubernetes.)

---

## الجزء 6 — نتائج المراجعة التقنية المتعمقة

### 6.1 مشكلات حرجة

1. **عدم تطابق دقة الأشعة السينية:** تطبيق Flutter يعيد تحجيم الصور إلى 320×320، لكن النموذج دُرِّب على 224×224. هذا خطأ وظيفي سيؤدي إلى تراجع دقة التنبؤ. الإصلاح: مواءمة دقة الاستدلال مع دقة التدريب.

2. **ضعف التغطية الاختبارية:** يوجد اختبار وحدوي واحد فقط مقابل 153+ ملفًا من ملفات المصدر. لا توجد اختبارات widgets، ولا اختبارات تكامل، ولا اختبارات golden. بالنسبة لتطبيق رعاية صحية، هذا يمثل مخاطرة جودة كبيرة.

3. **عدم وجود حواجز أخطاء:** قد تتسبب أخطاء مستوى widget في انهيار التطبيق. لا يوجد إعداد لـ `FlutterError.onError` أو `ErrorWidget.builder` في `main.dart`.

### 6.2 مشكلات متوسطة

4. **أخطاء إملائية في أسماء الملفات/الفئات:** `custem_text.dart` و`custem_field.dart` و`custem_bottom.dart` و`custem_background.dart` و`simple_buttom.dart` — يجب أن تصبح `custom_*` و`simple_button`.

5. **تضخم ملفات utilities:** هناك 18 ملفًا في `core/utils/` مع مسؤوليات متداخلة. يمكن أن تشترك `custem_text.dart` و`simple_header.dart` و`chat_header.dart` و`home_header.dart` في widget موحّد للرؤوس.

6. **لا توجد حالات تحميل/خطأ في المتحكمات:** بعض Riverpod controllers لا تعرض حالات `AsyncValue` صريحة — بل تستخدم حالة نموذج خامًا دون تتبع حالات التحميل/الخطأ.

7. **`analysis_options.yaml` متساهل جدًا:** يكتفي بـ `flutter_lints/flutter.yaml` دون قواعد مخصصة. لا توجد قواعد مثل `prefer_const_constructors` أو `avoid_print` أو قواعد خاصة بالرعاية الصحية.

### 6.3 مشكلات بسيطة

8. **ملفات `.g.dart` المولَّدة غير موجودة في `.gitignore`** — ينبغي الالتزام بها (وهذا هو الأسلوب القياسي) لكن يجب التحقق من اتساقها.

9. **`pubspec.yaml` لا يحتوي على `publish_to: none`** — ما قد يؤدي إلى نشر غير مقصود على pub.dev.

10. **لا يوجد ملف ترخيص** — لم يُحدَّد MIT أو Apache أو أي ترخيص مفتوح المصدر آخر.

---

## الجزء 7 — جرد شامل للملفات

> **إجمالي ملفات المصدر التي تم تحليلها: 153 ملف Dart + 11 وظيفة حافة TypeScript + 12 ملف SQL + 4 سكربتات Python + 1 ملف اختبار**

### الطبقة الأساسية (`lib/core/`) — 37 ملفًا
| الملف | الغرض | الأسطر |
|------|-------|--------|
| `supabase/supabase_config.dart` | إعداد Supabase عبر المتغيرات البيئية | ~20 |
| `supabase/supabase_service.dart` | غلاف Supabase أحادي النسخة | ~350 |
| `ai/xray_inference_service.dart` | تصدير مشروط حسب المنصة | ~10 |
| `ai/xray_inference_service_io.dart` | استدلال TFLite (Android/iOS) | ~200 |
| `ai/xray_inference_service_web.dart` | stub للويب | ~15 |
| `alerts/alert_model.dart` | نموذج بيانات AppAlert | ~80 |
| `alerts/alert_center_provider.dart` | إدارة حالة التنبيهات | ~150 |
| `alerts/alert_repository.dart` | CRUD للتنبيهات | ~100 |
| `alerts/alert_notification_service.dart` | إشعارات محلية منبثقة | ~200 |
| `alerts/alert_realtime_service.dart` | اشتراكات التنبيه اللحظية | ~120 |
| `alerts/widgets/alert_card.dart` | widget لبطاقة التنبيه | ~60 |
| `alerts/widgets/app_alert_card.dart` | بطاقة تنبيه بديلة | ~50 |
| `chat/chat_repository.dart` | حفظ رسائل الدردشة | ~180 |
| `errors/error_mapper.dart` | تصنيف الأخطاء السريرية | ~150 |
| `feedback/clinical_feedback.dart` | رسائل toast/popup/haptic | ~1133 |
| `local/vitaguard_local_database.dart` | مخطط قاعدة بيانات Drift | ~300 |
| `local/vitaguard_local_database.g.dart` | كود Drift المولَّد | ~2000 |
| `local/local_cache_repository.dart` | عمليات الذاكرة المؤقتة | ~200 |
| `local/sync_queue_repository.dart` | طابور المزامنة دون اتصال | ~150 |
| `network/health_provider.dart` | فحص صحة نموذج الذكاء الاصطناعي | ~80 |
| `sync/connectivity_sync_coordinator.dart` | مراقبة الشبكة | ~150 |
| `sync/offline_sync_service.dart` | معالجة الطابور | ~200 |
| `utils/app_colors.dart` | ألوان نظام التصميم | ~100 |
| `utils/app_text_field.dart` | حقل نص مشترك | ~50 |
| `utils/avatar_color.dart` | تعيين ألوان الصور الرمزية | ~30 |
| `utils/chat_header.dart` | رأس شاشة الدردشة | ~40 |
| `utils/chat_preview_card.dart` | بطاقة معاينة لقائمة الدردشة | ~60 |
| `utils/custem_background.dart` | تدرج الخلفية | ~30 |
| `utils/custem_bottom.dart` | زر سفلي (خطأ إملائي) | ~40 |
| `utils/custem_field.dart` | حقل إدخال مخصص (خطأ إملائي) | ~50 |
| `utils/custem_text.dart` | widget نص مخصص (خطأ إملائي) | ~40 |
| `utils/custom_logo.dart` | widget الشعار | ~30 |
| `utils/date_formatter.dart` | تنسيق التاريخ | ~30 |
| `utils/flexible_nav_bar.dart` | شريط تنقل سفلي | ~80 |
| `utils/home_header.dart` | رأس الصفحة الرئيسية | ~40 |
| `utils/message_input.dart` | شريط إدخال رسالة الدردشة | ~60 |
| `utils/screen_util_helper.dart` | مساعد للشاشات المتجاوبة | ~20 |
| `utils/simple_header.dart` | شريط رأس بسيط | ~30 |
| `utils/simple_buttom.dart` | زر بسيط (خطأ إملائي) | ~40 |
| `utils/special_bottom_nav.dart` | شريط تنقل خاص | ~60 |
| `utils/uuid.dart` | مولّد UUID | ~20 |

### طبقة الميزات (`lib/features/`) — 20+ ملفًا
| الوحدة | الملفات الرئيسية | الغرض |
|--------|------------------|-------|
| `chatbot/` | `ai_response_sanitizer.dart` و`ai_intent_classifier.dart` و`ai_content_normalizer.dart` والنماذج | خط أنابيب الذكاء الاصطناعي لروبوت الدردشة |
| `doctor/` | `alert_evaluation_engine.dart` والنماذج | منطق تنبيهات الطبيب |
| `vitals/` | `alert_timer_service.dart` | مؤقت بداية 45 ثانية، وwatchdog 60 ثانية |

### طبقة العرض (`lib/presentation/`) — 30+ ملفًا
| القسم الفرعي | الملفات الرئيسية | الغرض |
|--------------|------------------|-------|
| `screens/` | 10 شاشات | auth، شاشات الأدوار، العلامات الحيوية، الأشعة، الدردشة، onboarding، splash |
| `controllers/` | 7 متحكمات | auth، patient، doctor، companion، facility، vitals، chatbot |
| `widgets/` | 9 مجلدات فرعية | xray، onboarding، vitals، patient، facility، auth، doctor، chatbot، companion |

### Supabase (`supabase/`) — 39 ملفًا
| الفئة | العدد | الملفات الرئيسية |
|------|------|------------------|
| مخطط SQL | 12 | `schema.sql` و`policies.sql` و`setup_consolidated.sql` و`storage_policies.sql` و`schema_update.sql` و`ai_chat.sql` و`alerting_realtime_alerts.sql` و`link_companion.sql` و`repair_legacy_users.sql` و`ensure_direct_doctor_conversation.sql` و`add_doctor_medical_reports.sql` |
| وظائف الحافة | 11 | `hardware_telemetry` و`ai-chat` و`chatbot` و`xray-inference` و`upload_*` (4) و`review_*` (2) و`generate_companion_code` |
| مشترك | 4 | `cors.ts` و`supabase_client.ts` و`auth.ts` و`upload.ts` |
| إعدادات | 12 | `.env.example` و`.temp/*` |

### السكربتات والاختبارات (`scripts/` و`test/`) — 5 ملفات
| الملف | الغرض |
|------|-------|
| `convert_to_onnx.py` | تحويل FastAI .pth إلى ONNX |
| `export_verify_tflite.py` | خط الأنابيب الكامل: pkl → ONNX → بوابة parity → TFLite |
| `parity_check_pt_onnx_tflite.py` | مقارنة logits بين الصيغ |
| `test_onnx_consistency.py` | فحص الاتساق بين PT وONNX |
| `ai_response_sanitizer_test.dart` | الاختبار الوحدوي الوحيد |

---

## الجزء 8 — معيار التقييم للمناقشة

| الفئة | الحد الأقصى من النقاط | التقييم الذاتي | الملاحظات |
|------|----------------------|---------------|-----------|
| تعريف المشكلة والدافع | 10 | 9 | تم تحديد فجوة الرعاية الصحية بوضوح |
| المعمارية والتصميم | 15 | 13 | طبقات نظيفة، مع بعض مشكلات تنظيم الملفات |
| حزمة التقنيات والاختيارات | 10 | 9 | خيارات حديثة ومبرَّرة جيدًا |
| تصميم قاعدة البيانات والأمان | 15 | 14 | تطبيق RLS جيد |
| تنفيذ AI/ML | 15 | 11 | يوجد خطأ في دقة الإدخال، لكن الخط الأنابيب سليم |
| الميزات اللحظية | 10 | 9 | مؤقت التنبيه، والبث المتدفق، وإزالة التكرار |
| القدرة على العمل دون اتصال | 10 | 9 | طابور مزامنة، وذاكرة محلية، ومراقبة اتصال |
| جودة الكود والاختبار | 10 | 4 | فجوة حرجة — اختبار واحد فقط |
| UI/UX وإمكانية الوصول | 10 | 7 | واجهات حسب الدور، لكن لا يوجد تدقيق وصول |
| العرض التقديمي والديمو | 10 | 8 | عرض العلامات الحيوية والأشعة مقنع |
| الاستعداد للأسئلة والأجوبة | 10 | 9 | فهم شامل |
| العمل المستقبلي والرؤية | 10 | 8 | خارطة طريق واضحة |
| **الإجمالي** | **150** | **109** | **73% — التركيز على الاختبار وإصلاح الخطأ** |

---

## الجزء 9 — سكربت ديمو مقترح

### الإعداد (دقيقتان)
1. افتح VS Code والمشروع محمّل
2. اجعل Supabase Studio مفتوحًا في المتصفح (https://supabase.com/dashboard)
3. جهّز Android emulator أو جهازًا فعليًا
4. جهّز محاكي ESP32 أو سكربت بيانات اختبار

### سير الديمو (10 دقائق)

**1. المصادقة وتوجيه الأدوار (دقيقة واحدة)**
- شغّل التطبيق → Splash → شاشة المصادقة
- سجّل كمريض → Onboarding → صفحة المريض الرئيسية
- ملاحظة: شريط التنقل يتغير حسب الدور

**2. لوحة المريض والعلامات الحيوية (دقيقتان)**
- اعرض بطاقة العلامات الحيوية (BPM، SpO2، الحرارة)
- أرسل بيانات ESP32 → اعرض التحديث اللحظي
- اشرح: "هذه البيانات تأتي من جهاز ESP32 القابل للارتداء عبر Supabase Realtime"

**3. عرض الطبيب والتنبيهات (دقيقتان)**
- بدّل إلى حساب الطبيب
- اعرض قائمة المرضى المعيَّنين
- فعّل تنبيهًا (مثلًا: معدل قلب مرتفع) → اعرض بطاقة التنبيه اللحظي
- اشرح: "مؤقت البداية لمدة 45 ثانية يمنع الإنذارات الكاذبة، والنافذة المتحركة تُنعّم الضوضاء"

**4. تحليل الأشعة بالذكاء الاصطناعي (دقيقتان)**
- انتقل إلى شاشة الأشعة
- ارفع صورة أشعة صدر
- يعرض الذكاء الاصطناعي التنبؤ مع الثقة
- اختياري: اعرض heatmap overlay (المرحلة 2)
- اشرح: "TFLite على الجهاز — الصورة لا تغادر الهاتف"

**5. روبوت الدردشة بالذكاء الاصطناعي (1.5 دقيقة)**
- افتح AI Chat
- اسأل: "ماذا أفعل إذا كانت SpO2 لدي 89%؟"
- اعرض الرد المتدفق مع الردود السريعة
- اشرح: "Gemini/Gemma عبر وظائف الحافة، وتنقية مزدوجة"

**6. وضع عدم الاتصال (1.5 دقيقة)**
- فعّل وضع الطيران
- اعرض أن البيانات المخبأة ما زالت ظاهرة
- نفّذ إجراءً (مثلًا: رفع أشعة) — يُوضَع في الطابور
- أعد الاتصال → تتم المزامنة تلقائيًا

---

## الجزء 10 — أرقام أساسية يجب حفظها

| المقياس | القيمة |
|--------|--------|
| جداول قاعدة البيانات | 18 |
| وظائف الحافة | 11 |
| ملفات Dart المصدرية | 153+ |
| أدوار المستخدم | 4 (patient، doctor، companion، facility) |
| نموذج الذكاء الاصطناعي | DenseNet121، حوالي 30 مليون معلمة |
| مدخل النموذج (التدريب) | 224×224 |
| مدخل النموذج (التطبيق) | 320×320 (خطأ — يجب أن يطابق 224) |
| مؤقت بداية التنبيه | 45 ثانية |
| مهلة البيانات القديمة | 60 ثانية |
| النطاق الطبيعي لمعدل القلب | 60–120 bpm |
| عتبة تحذير SpO2 | أقل من 92% |
| عتبة SpO2 الحرجة | أقل من 88% |
| عتبة الحمى | أكبر من 38.5°C / 39.5°C |
| طول رمز المرافق | 6 أحرف |
| حالات طابور العمل دون اتصال | 4 (pending، processing، done، failed) |
| التغطية الاختبارية | أقل من 1% (ملف اختبار واحد) |
| مرجع مشروع Supabase | `sumgvbdgucrjyiztmzyn` |
| منطقة Supabase | EU West (aws-1-eu-west-1) |

---

## الجزء 11 — تقييم المخاطر وخطة التخفيف للمناقشة

| الخطر | الاحتمالية | الأثر | التخفيف |
|------|-----------|--------|---------|
| "لماذا يوجد اختبار واحد فقط؟" | مرتفع | مرتفع | جهّز الرد: "ركزنا على الميزات أكثر من الاختبارات في النسخة الأولية، لكننا أدركنا أن هذا هو أكبر debt تقني. بعد المناقشة، ستكون أول مهمة لنا إضافة اختبارات widget لمسار المصادقة واختبارات وحدوية لمحرك التنبيه." |
| "لماذا 320×320 بدلًا من 224×224؟" | مرتفع | متوسط | كن صريحًا: "هذا خطأ اكتشفناه أثناء التحليل. خط التدريب يستخدم 224×224 بينما التطبيق يعيد التحجيم إلى 320×320، وهذا يقلل الدقة. وثّقنا ذلك كإصلاح فوري." |
| "وماذا عن HIPAA؟" | متوسط | متوسط | "التطبيق نموذج أولي وليس متوافقًا مع HIPAA بعد. ومع ذلك، البنية تدعم ذلك: ذكاء اصطناعي على الجهاز، وتخزين خاص، وRLS، وتدقيق أمني. الامتثال الكامل سيتطلب BAA، وتشفيرًا أثناء التخزين، وتدقيقًا أمنيًا رسميًا." |
| "ماذا لو أعطى روبوت الدردشة نصيحة طبية خاطئة؟" | متوسط | مرتفع | "تم وضع الذكاء الاصطناعي كـ 'إرشاد صحي' وليس 'تشخيصًا طبيًا'. يوجّه system prompt النظام إلى تضمين تنبيه مناسب. كما أن مصنف النية يلتقط الحالات الطارئة ويُنصح حينها بطلب مساعدة طبية حقيقية. ونُسجل كل التفاعلات للمراجعة." |
| "ماذا لو فشل العرض بسبب عدم وجود إنترنت؟" | منخفض | مرتفع | "لدينا وضع عدم اتصال تحديدًا لهذا السبب. تعمل كل ميزات العرض ببيانات مخبأة. ويمكنني إظهار قدرة العمل دون اتصال بدلًا من ذلك." |

---

## الجزء 12 — التوصيات النهائية للنجاح في المناقشة

1. **أصلح خطأ 320×320 مقابل 224×224** قبل المناقشة — هذا أهم تعديل منفرد من ناحية المصداقية التقنية.

2. **أضف 2-3 اختبارات إضافية** — حتى اختبارات widget بسيطة لشاشة المصادقة واختبارات وحدوية لمحرك التنبيه. إظهار زيادة التغطية الاختبارية يثبت الوعي بالجودة.

3. **جهّز شريحة "الدروس المستفادة"** — الاعتراف بفجوة الاختبار وخطأ الدقة وأخطاء تسمية ملفات utilities يُظهر النضج والوعي الذاتي.

4. **درّب الديمو** من البداية للنهاية ثلاث مرات على الأقل. جهّز لقطات شاشة/فيديو كخطة بديلة في حال فشل العرض الحي.

5. **اعرف مخطط Supabase جيدًا جدًا** — سيُسألون عن RLS، والعلاقات بين الجداول، والاستعلامات المحددة.

6. **اقرأ كود Sanitizer الخاص بروبوت الدردشة** (`ai_response_sanitizer.dart` و`chatbot/index.ts`) — هذه ميزة مميزة تُظهر الوعي الأمني.

7. **استعد لسؤال "لماذا Supabase وليس Firebase؟"** — اعرف الفروق: مفتوح المصدر، PostgreSQL (وليس NoSQL)، RLS، وظائف الحافة بـ TypeScript، وقابل للاستضافة الذاتية.

8. **أبرز السياق الصحي** — شدد على الخصوصية (ذكاء اصطناعي على الجهاز)، والموثوقية (مزامنة دون اتصال)، والسلامة السريرية (إزالة تكرار التنبيهات، والتقييم المبني على المؤقت).

9. **أضعف نقطة لديك هي الاختبار.** واجهها مباشرة في العرض: "رغم أننا بنينا مجموعة ميزات قوية، فإننا ندرك أن الاختبار يحتاج إلى تحسين كبير. وهذه أولويتنا بعد المناقشة."

10. **تذكّر: اللجنة تريد لك النجاح.** كن واثقًا، وصادقًا بشأن الحدود، ومركزًا على ما تعلمته.

---

*نهاية دليل التحضير لمناقشة VitaGuard — يونيو 2026*
