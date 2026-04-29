# VitaGuard Local Data Layer

This folder is the client-only offline foundation for the modernization.

- `vitaguard_local_database.dart` defines Drift tables that mirror existing Supabase payloads by storing the original row JSON alongside stable lookup columns.
- `local_cache_repository.dart` caches read models without renaming Supabase fields or changing response shapes.
- `sync_queue_repository.dart` stores offline writes for later replay by repositories when connectivity returns.
- `../sync/offline_sync_service.dart` replays queued inserts/upserts/RPCs/functions through `SupabaseService`.
- `../sync/connectivity_sync_coordinator.dart` triggers replay when connectivity returns.
- `sync_conflicts` records unresolved local/server conflicts so healthcare data is never overwritten silently.

Initial rollout rule: repositories may read/write this local layer, but no Supabase schema, RPC, Edge Function, storage bucket, auth metadata, or realtime payload contract changes are required.
