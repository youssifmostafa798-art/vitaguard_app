import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vitaguard_app/auth/data/auth_repository.dart';
import 'package:vitaguard_app/Companion/data/companion_repository.dart';
import 'package:vitaguard_app/core/alerts/alert_realtime_service.dart';
import 'package:vitaguard_app/core/alerts/alert_repository.dart';
import 'package:vitaguard_app/core/chat/chat_repository.dart';
import 'package:vitaguard_app/core/local/local_cache_repository.dart';
import 'package:vitaguard_app/core/local/sync_queue_repository.dart';
import 'package:vitaguard_app/core/local/vitaguard_local_database.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';
import 'package:vitaguard_app/core/sync/connectivity_sync_coordinator.dart';
import 'package:vitaguard_app/core/sync/offline_sync_service.dart';
import 'package:vitaguard_app/Doctor/data/doctor_repository.dart';
import 'package:vitaguard_app/facility/data/facility_repository.dart';
import 'package:vitaguard_app/patient/data/patient_repository.dart';
import 'package:vitaguard_app/patient/models/patient_models.dart';
import 'package:vitaguard_app/ai_chat/data/ai_chat_models.dart';
import 'package:vitaguard_app/ai_chat/data/ai_chat_repository.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
part 'providers_modern.g.dart';

@Riverpod(keepAlive: true)
SupabaseService supabaseService(Ref ref) {
  return SupabaseService.instance;
}

@Riverpod(keepAlive: true)
VitaGuardLocalDatabase vitaGuardLocalDatabase(Ref ref) {
  final database = VitaGuardLocalDatabase();
  ref.onDispose(database.close);
  return database;
}

@Riverpod(keepAlive: true)
SyncQueueRepository syncQueueRepository(Ref ref) {
  return SyncQueueRepository(ref.watch(vitaGuardLocalDatabaseProvider));
}

@Riverpod(keepAlive: true)
LocalCacheRepository localCacheRepository(Ref ref) {
  return LocalCacheRepository(ref.watch(vitaGuardLocalDatabaseProvider));
}

@Riverpod(keepAlive: true)
OfflineSyncService offlineSyncService(Ref ref) {
  return OfflineSyncService(
    supabase: ref.watch(supabaseServiceProvider),
    syncQueue: ref.watch(syncQueueRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
ConnectivitySyncCoordinator connectivitySyncCoordinator(Ref ref) {
  final coordinator = ConnectivitySyncCoordinator(
    offlineSyncService: ref.watch(offlineSyncServiceProvider),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(supabase: ref.watch(supabaseServiceProvider));
}

@riverpod
PatientRepository patientRepository(Ref ref) {
  return PatientRepository(
    supabase: ref.watch(supabaseServiceProvider),
    localCache: ref.watch(localCacheRepositoryProvider),
    syncQueue: ref.watch(syncQueueRepositoryProvider),
  );
}

@riverpod
DoctorRepository doctorRepository(Ref ref) {
  return DoctorRepository(supabase: ref.watch(supabaseServiceProvider));
}

@riverpod
CompanionRepository companionRepository(Ref ref) {
  return CompanionRepository(supabase: ref.watch(supabaseServiceProvider));
}

@riverpod
FacilityRepository facilityRepository(Ref ref) {
  return FacilityRepository(supabase: ref.watch(supabaseServiceProvider));
}

@riverpod
ChatRepository chatRepository(Ref ref) {
  return ChatRepository(supabase: ref.watch(supabaseServiceProvider));
}

@riverpod
AiChatRepository aiChatRepository(Ref ref) {
  return SupabaseAiChatRepository(supabase: ref.watch(supabaseServiceProvider));
}

@riverpod
AlertRepository alertRepository(Ref ref) {
  return AlertRepository(supabase: ref.watch(supabaseServiceProvider));
}

@riverpod
AlertRealtimeService alertRealtimeService(Ref ref) {
  return AlertRealtimeService(supabase: ref.watch(supabaseServiceProvider));
}

class AuthControllerState {
  const AuthControllerState({
    this.currentUser,
    this.error,
    this.isLoading = false,
  });

  final Map<String, dynamic>? currentUser;
  final String? error;
  final bool isLoading;

  String get userName => currentUser?['name']?.toString() ?? 'User';

  AuthControllerState copyWith({
    Map<String, dynamic>? currentUser,
    String? error,
    bool? isLoading,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthControllerState(
      currentUser: clearUser ? null : currentUser ?? this.currentUser,
      error: clearError ? null : error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class AuthController extends _$AuthController {
  @override
  AuthControllerState build() {
    return const AuthControllerState();
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.login(email, password);
      final currentUser = await repository.getMe();
      state = AuthControllerState(currentUser: currentUser);
      return true;
    } catch (error) {
      state = AuthControllerState(error: error.toString());
      return false;
    }
  }

  Future<String?> getUserRole() async {
    final cachedRole = state.currentUser?['role'];
    if (cachedRole is String && cachedRole.isNotEmpty) return cachedRole;

    final currentUser = await ref.read(authRepositoryProvider).getMe();
    state = state.copyWith(currentUser: currentUser);
    return currentUser['role'] as String?;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthControllerState();
  }
}

@riverpod
class PatientMedicalHistoryController
    extends _$PatientMedicalHistoryController {
  @override
  Future<MedicalHistory> build() {
    return ref.read(patientRepositoryProvider).getMedicalHistory();
  }

  Future<bool> saveHistory(MedicalHistory history) async {
    final previous = state.value;
    state = const AsyncLoading<MedicalHistory>();
    try {
      await ref.read(patientRepositoryProvider).updateMedicalHistory(history);
      state = AsyncData(history);
      return true;
    } catch (error, stackTrace) {
      state = previous == null
          ? AsyncError<MedicalHistory>(error, stackTrace)
          : AsyncData(previous);
      return false;
    }
  }
}

class AiChatControllerState {
  const AiChatControllerState({
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.conversation,
    this.messageStream,
    this.loadedUserId,
    this.lastMessageSentAt,
  });

  final bool isLoading;
  final bool isSending;
  final String? error;
  final AiConversation? conversation;
  final Stream<List<AiMessage>>? messageStream;
  final String? loadedUserId;
  final DateTime? lastMessageSentAt;

  AiChatControllerState copyWith({
    bool? isLoading,
    bool? isSending,
    String? error,
    AiConversation? conversation,
    Stream<List<AiMessage>>? messageStream,
    String? loadedUserId,
    DateTime? lastMessageSentAt,
    bool clearError = false,
  }) {
    return AiChatControllerState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : error ?? this.error,
      conversation: conversation ?? this.conversation,
      messageStream: messageStream ?? this.messageStream,
      loadedUserId: loadedUserId ?? this.loadedUserId,
      lastMessageSentAt: lastMessageSentAt ?? this.lastMessageSentAt,
    );
  }
}

@riverpod
class AiChatController extends _$AiChatController {
  @override
  AiChatControllerState build() {
    return const AiChatControllerState();
  }

  Future<List<AiConversation>> fetchUserHistory() async {
    final repo = ref.read(aiChatRepositoryProvider);
    if (repo.currentUserIdOrNull == null) return [];
    return await repo.fetchConversationHistory();
  }

  Future<void> ensureConversation({bool forceRefresh = false, String? conversationId}) async {
    final repo = ref.read(aiChatRepositoryProvider);
    final currentUserId = repo.currentUserIdOrNull;
    if (currentUserId == null) {
      state = state.copyWith(
        conversation: null,
        messageStream: null,
        loadedUserId: null,
        error: 'You must be logged in to chat with VitaGuard AI.',
      );
      return;
    }

    final isTargetingDifferentConversation = conversationId != null && state.conversation?.id != conversationId;

    if (!forceRefresh &&
        !isTargetingDifferentConversation &&
        state.conversation != null &&
        state.loadedUserId == currentUserId &&
        state.messageStream != null) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final conversation = await repo.ensureConversation(conversationId);
      final messageStream = repo.streamMessages(conversation.id);
      
      state = state.copyWith(
        conversation: conversation,
        messageStream: messageStream,
        loadedUserId: currentUserId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: ErrorMapper.map(e),
        isLoading: false,
      );
    }
  }

  Future<bool> sendMessage(String content) async {
    final text = content.trim();
    if (text.isEmpty || state.isSending) return false;

    final now = DateTime.now();
    if (state.lastMessageSentAt != null && 
        now.difference(state.lastMessageSentAt!).inMilliseconds < 1000) {
       return false;
    }

    state = state.copyWith(lastMessageSentAt: now);

    await ensureConversation();
    final conversation = state.conversation;
    if (conversation == null) {
      return false;
    }

    state = state.copyWith(isSending: true, clearError: true);

    try {
      final repo = ref.read(aiChatRepositoryProvider);
      final userMessageId = await repo.insertUserMessage(
        conversation.id,
        text,
      );
      await repo.requestAssistantReply(
        conversationId: conversation.id,
        userMessageId: userMessageId,
      );
      state = state.copyWith(isSending: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: ErrorMapper.map(e),
        isSending: false,
      );
      return false;
    }
  }

  void clearError() {
    if (state.error == null) return;
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = const AiChatControllerState();
  }
}

