import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum ClinicalPopupType { success, warning, error, info, loading, critical }

enum ClinicalPopupAnchor { bottomCenter, bottomRight, center, aboveBottomNav }

class FeedbackOwner {
  FeedbackOwner();

  final Set<String> _ids = <String>{};
  VoidCallback? _onDispose;
  bool _disposed = false;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _onDispose?.call();
    _ids.clear();
  }
}

@immutable
class ClinicalFeedbackTheme {
  const ClinicalFeedbackTheme({
    required this.surface,
    required this.border,
    required this.text,
    required this.subtleText,
    required this.shadow,
  });

  final Color surface;
  final Color border;
  final Color text;
  final Color subtleText;
  final Color shadow;

  factory ClinicalFeedbackTheme.from(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    return ClinicalFeedbackTheme(
      surface: isDark
          ? const Color(0xFF111827).withValues(alpha: 0.78)
          : const Color(0xFFF8FBFF).withValues(alpha: 0.82),
      border: isDark
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.white.withValues(alpha: 0.58),
      text: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
      subtleText: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF526173),
      shadow: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.28 : 0.14),
    );
  }
}

@immutable
class ClinicalPopupRequest {
  const ClinicalPopupRequest({
    required this.type,
    required this.title,
    required this.message,
    this.anchor = ClinicalPopupAnchor.aboveBottomNav,
    this.duration = const Duration(milliseconds: 3200),
    this.persistent = false,
    this.routeScoped = true,
    this.dedupeKey,
    this.operationId,
    this.developerDiagnostics,
    this.actionLabel,
    this.onAction,
    this.owner,
  });

  final ClinicalPopupType type;
  final String title;
  final String message;
  final ClinicalPopupAnchor anchor;
  final Duration? duration;
  final bool persistent;
  final bool routeScoped;
  final String? dedupeKey;
  final String? operationId;
  final String? developerDiagnostics;
  final String? actionLabel;
  final VoidCallback? onAction;
  final FeedbackOwner? owner;

  String get effectiveDedupeKey =>
      dedupeKey ?? '${type.name}|$title|$message|${operationId ?? ''}';
}

@immutable
class ClinicalPopupEntry {
  const ClinicalPopupEntry({
    required this.id,
    required this.request,
    required this.revision,
    required this.createdAt,
    this.exiting = false,
    this.paused = false,
    this.remainingDuration,
  });

  final String id;
  final ClinicalPopupRequest request;
  final int revision;
  final DateTime createdAt;
  final bool exiting;
  final bool paused;
  final Duration? remainingDuration;

  bool get isTransient =>
      request.type != ClinicalPopupType.loading &&
      request.type != ClinicalPopupType.critical &&
      !request.persistent;

  ClinicalPopupEntry copyWith({
    ClinicalPopupRequest? request,
    int? revision,
    bool? exiting,
    bool? paused,
    Duration? remainingDuration,
  }) {
    return ClinicalPopupEntry(
      id: id,
      request: request ?? this.request,
      revision: revision ?? this.revision,
      createdAt: createdAt,
      exiting: exiting ?? this.exiting,
      paused: paused ?? this.paused,
      remainingDuration: remainingDuration ?? this.remainingDuration,
    );
  }
}

final clinicalFeedbackControllerProvider = Provider<ClinicalFeedbackController>(
  (ref) {
    final controller = ClinicalFeedbackController();
    ref.onDispose(controller.dispose);
    return controller;
  },
);

class ClinicalFeedbackController extends ChangeNotifier
    with WidgetsBindingObserver {
  static const int maxVisiblePopups = 2;
  static const Duration exitDuration = Duration(milliseconds: 170);

  final List<ClinicalPopupEntry> _entries = <ClinicalPopupEntry>[];
  final Map<String, Timer> _timers = <String, Timer>{};
  final Map<String, DateTime> _timerStartedAt = <String, DateTime>{};
  int _nextId = 0;

  ClinicalFeedbackController() {
    WidgetsBinding.instance.addObserver(this);
  }

  List<ClinicalPopupEntry> get entries => List.unmodifiable(_entries);

  String show(ClinicalPopupRequest request) {
    final duplicateIndex = _entries.indexWhere(
      (entry) =>
          !entry.exiting &&
          entry.request.effectiveDedupeKey == request.effectiveDedupeKey,
    );
    if (duplicateIndex != -1) {
      final old = _entries[duplicateIndex];
      _cancelTimer(old.id);
      _entries[duplicateIndex] = old.copyWith(
        request: request,
        revision: old.revision + 1,
        exiting: false,
      );
      _startTimerIfNeeded(old.id, request.duration);
      _attachOwner(request.owner, old.id);
      _performHaptic(request.type);
      notifyListeners();
      return old.id;
    }

    if (request.type == ClinicalPopupType.loading &&
        (request.operationId ?? '').isNotEmpty) {
      final loadingIndex = _entries.indexWhere(
        (entry) =>
            entry.request.type == ClinicalPopupType.loading &&
            entry.request.operationId == request.operationId,
      );
      if (loadingIndex != -1) {
        final old = _entries[loadingIndex];
        _entries[loadingIndex] = old.copyWith(
          request: request,
          revision: old.revision + 1,
        );
        _attachOwner(request.owner, old.id);
        notifyListeners();
        return old.id;
      }
    }

    _evictFor(request);

    final id = 'clinical-feedback-${_nextId++}';
    final entry = ClinicalPopupEntry(
      id: id,
      request: request,
      revision: 0,
      createdAt: DateTime.now(),
    );
    _entries.insert(0, entry);
    _attachOwner(request.owner, id);
    _startTimerIfNeeded(id, request.duration);
    _performHaptic(request.type);
    notifyListeners();
    return id;
  }

  void dismiss(String id) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index == -1) return;
    _cancelTimer(id);
    if (_entries[index].exiting) return;
    _entries[index] = _entries[index].copyWith(exiting: true);
    notifyListeners();
    _timers[id] = Timer(exitDuration, () => _removeNow(id));
  }

  void clearRouteTransientPopups() {
    final ids = _entries
        .where((entry) => entry.request.routeScoped && entry.isTransient)
        .map((entry) => entry.id)
        .toList(growable: false);
    for (final id in ids) {
      dismiss(id);
    }
  }

  void _evictFor(ClinicalPopupRequest request) {
    if (request.type == ClinicalPopupType.critical ||
        request.type == ClinicalPopupType.loading) {
      return;
    }

    final transientEntries = _entries.where((entry) => entry.isTransient);
    if (transientEntries.length < maxVisiblePopups) return;

    final oldest = transientEntries.reduce(
      (a, b) => a.createdAt.isBefore(b.createdAt) ? a : b,
    );
    dismiss(oldest.id);
  }

  void _startTimerIfNeeded(String id, Duration? duration) {
    if (duration == null) return;
    final entry = _entries.firstWhere((entry) => entry.id == id);
    if (entry.request.persistent ||
        entry.request.type == ClinicalPopupType.loading ||
        entry.request.type == ClinicalPopupType.critical) {
      return;
    }
    _timerStartedAt[id] = DateTime.now();
    _timers[id] = Timer(duration, () => dismiss(id));
  }

  void _cancelTimer(String id) {
    _timers.remove(id)?.cancel();
    _timerStartedAt.remove(id);
  }

  void _removeNow(String id) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index == -1) return;
    _entries.removeAt(index);
    _cancelTimer(id);
    notifyListeners();
  }

  void _attachOwner(FeedbackOwner? owner, String id) {
    if (owner == null) return;
    owner._ids.add(id);
    owner._onDispose ??= () {
      for (final entryId in owner._ids.toList(growable: false)) {
        dismiss(entryId);
      }
    };
  }

  void _performHaptic(ClinicalPopupType type) {
    if (type == ClinicalPopupType.info || type == ClinicalPopupType.loading) {
      return;
    }
    HapticFeedback.lightImpact();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _pauseTimers();
    } else if (state == AppLifecycleState.resumed) {
      _resumeTimers();
    }
  }

  void _pauseTimers() {
    for (final id in _timers.keys.toList(growable: false)) {
      final entryIndex = _entries.indexWhere((entry) => entry.id == id);
      if (entryIndex == -1) continue;
      final duration = _entries[entryIndex].request.duration;
      final startedAt = _timerStartedAt[id];
      if (duration == null || startedAt == null) continue;
      final elapsed = DateTime.now().difference(startedAt);
      final remaining = duration - elapsed;
      _timers.remove(id)?.cancel();
      _entries[entryIndex] = _entries[entryIndex].copyWith(
        paused: true,
        remainingDuration: remaining.isNegative ? Duration.zero : remaining,
      );
    }
    notifyListeners();
  }

  void _resumeTimers() {
    for (var i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      if (!entry.paused || entry.remainingDuration == null) continue;
      _entries[i] = entry.copyWith(paused: false);
      _timerStartedAt[entry.id] = DateTime.now();
      _timers[entry.id] = Timer(entry.remainingDuration!, () {
        dismiss(entry.id);
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _timerStartedAt.clear();
    super.dispose();
  }
}

class ClinicalFeedbackNavigatorObserver extends NavigatorObserver {
  ClinicalFeedbackNavigatorObserver(this.controller);

  final ClinicalFeedbackController controller;

  bool _isFullScreenRoute(Route<dynamic>? route) {
    if (route == null || route is PopupRoute) return false;
    return route is PageRoute;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (_isFullScreenRoute(newRoute)) {
      controller.clearRouteTransientPopups();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isFullScreenRoute(route)) {
      controller.clearRouteTransientPopups();
    }
  }
}

class ClinicalFeedbackScope extends InheritedWidget {
  const ClinicalFeedbackScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final ClinicalFeedbackController controller;

  static ClinicalFeedbackController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ClinicalFeedbackScope>();
    assert(
      scope != null,
      'ClinicalFeedbackHost is missing above this context.',
    );
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(ClinicalFeedbackScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

class ClinicalFeedbackHost extends ConsumerStatefulWidget {
  const ClinicalFeedbackHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ClinicalFeedbackHost> createState() =>
      _ClinicalFeedbackHostState();
}

class _ClinicalFeedbackHostState extends ConsumerState<ClinicalFeedbackHost> {
  late final ClinicalFeedbackController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(clinicalFeedbackControllerProvider);
    _controller.addListener(_handleFeedbackChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleFeedbackChanged);
    super.dispose();
  }

  void _handleFeedbackChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ClinicalFeedbackScope(
      controller: _controller,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          _ClinicalFeedbackOverlay(controller: _controller),
        ],
      ),
    );
  }
}

String showClinicalPopup(
  BuildContext context, {
  required ClinicalPopupType type,
  required String title,
  required String message,
  ClinicalPopupAnchor anchor = ClinicalPopupAnchor.aboveBottomNav,
  Duration? duration = const Duration(milliseconds: 3200),
  bool persistent = false,
  bool routeScoped = true,
  String? dedupeKey,
  String? operationId,
  String? developerDiagnostics,
  String? actionLabel,
  VoidCallback? onAction,
  FeedbackOwner? owner,
}) {
  return ClinicalFeedbackScope.of(context).show(
    ClinicalPopupRequest(
      type: type,
      title: title,
      message: message,
      anchor: anchor,
      duration: duration,
      persistent: persistent,
      routeScoped: routeScoped,
      dedupeKey: dedupeKey,
      operationId: operationId,
      developerDiagnostics: developerDiagnostics,
      actionLabel: actionLabel,
      onAction: onAction,
      owner: owner,
    ),
  );
}

class _ClinicalFeedbackOverlay extends StatelessWidget {
  const _ClinicalFeedbackOverlay({required this.controller});

  final ClinicalFeedbackController controller;

  @override
  Widget build(BuildContext context) {
    final entries = controller.entries;
    if (entries.isEmpty) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            for (var i = entries.length - 1; i >= 0; i--)
              _AnchoredClinicalPopup(
                entry: entries[i],
                stackIndex: i,
                onDismiss: () => controller.dismiss(entries[i].id),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnchoredClinicalPopup extends StatelessWidget {
  const _AnchoredClinicalPopup({
    required this.entry,
    required this.stackIndex,
    required this.onDismiss,
  });

  final ClinicalPopupEntry entry;
  final int stackIndex;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottom = media.padding.bottom + 86 + (stackIndex * 76);
    final inset = 16.w;
    final card = _ClinicalPopupCard(
      key: ValueKey('${entry.id}-${entry.revision}'),
      entry: entry,
      onDismiss: onDismiss,
    );

    switch (entry.request.anchor) {
      case ClinicalPopupAnchor.center:
        return Center(child: card);
      case ClinicalPopupAnchor.bottomCenter:
      case ClinicalPopupAnchor.aboveBottomNav:
        return PositionedDirectional(
          start: inset,
          end: inset,
          bottom: bottom.h,
          child: Align(alignment: AlignmentDirectional.center, child: card),
        );
      case ClinicalPopupAnchor.bottomRight:
        return PositionedDirectional(end: inset, bottom: bottom.h, child: card);
    }
  }
}

class _ClinicalPopupCard extends StatefulWidget {
  const _ClinicalPopupCard({
    super.key,
    required this.entry,
    required this.onDismiss,
  });

  final ClinicalPopupEntry entry;
  final VoidCallback onDismiss;

  @override
  State<_ClinicalPopupCard> createState() => _ClinicalPopupCardState();
}

class _ClinicalPopupCardState extends State<_ClinicalPopupCard>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController? _progressController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final duration = widget.entry.request.duration;
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 210),
      reverseDuration: ClinicalFeedbackController.exitDuration,
    );
    final curved = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(curved);
    _scale = Tween<double>(begin: 0.96, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(curved);
    _progressController =
        duration != null &&
            widget.entry.request.type != ClinicalPopupType.loading &&
            !widget.entry.request.persistent
        ? AnimationController(vsync: this, duration: duration)
        : null;
    _entryController.forward();
    _progressController?.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = _reducedMotion;
    _entryController.duration = reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 210);
    _entryController.reverseDuration = reducedMotion
        ? Duration.zero
        : ClinicalFeedbackController.exitDuration;
  }

  bool get _reducedMotion {
    final media = MediaQuery.maybeOf(context);
    return media?.disableAnimations ?? false;
  }

  @override
  void didUpdateWidget(covariant _ClinicalPopupCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entry.exiting && !oldWidget.entry.exiting) {
      _entryController.reverse();
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _progressController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ClinicalFeedbackTheme.from(context);
    final color = _semanticColor(widget.entry.request.type);
    final icon = _semanticIcon(widget.entry.request.type);
    final severity = _semanticLabel(widget.entry.request.type);
    final semantics = _semanticAnnouncement(widget.entry.request);
    final developerDiagnostics = widget.entry.request.developerDiagnostics;
    final actionLabel = widget.entry.request.actionLabel;

    return Semantics(
      liveRegion: true,
      container: true,
      label: semantics,
      child: AnimatedBuilder(
        animation: Listenable.merge([_entryController, ?_progressController]),
        builder: (context, child) {
          return FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: ScaleTransition(
                scale: _scale,
                child: RepaintBoundary(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 380.w),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: theme.border),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadow,
                                blurRadius: 26,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                    14.w,
                                    12.h,
                                    10.w,
                                    10.h,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _SemanticIconBox(
                                        color: color,
                                        icon: icon,
                                        isLoading:
                                            widget.entry.request.type ==
                                            ClinicalPopupType.loading,
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              widget.entry.request.title,
                                              style: TextStyle(
                                                color: theme.text,
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w800,
                                                height: 1.18,
                                              ),
                                            ),
                                            SizedBox(height: 3.h),
                                            Text(
                                              widget.entry.request.message,
                                              style: TextStyle(
                                                color: theme.subtleText,
                                                fontSize: 12.5.sp,
                                                fontWeight: FontWeight.w600,
                                                height: 1.28,
                                              ),
                                            ),
                                            if (kDebugMode &&
                                                developerDiagnostics != null &&
                                                developerDiagnostics.isNotEmpty)
                                              _DeveloperDiagnostics(
                                                diagnostics:
                                                    developerDiagnostics,
                                              ),
                                            if (actionLabel != null &&
                                                actionLabel.isNotEmpty)
                                              Padding(
                                                padding:
                                                    EdgeInsetsDirectional.only(
                                                      top: 8.h,
                                                    ),
                                                child: TextButton(
                                                  onPressed: () {
                                                    widget
                                                        .entry
                                                        .request
                                                        .onAction
                                                        ?.call();
                                                    HapticFeedback.lightImpact();
                                                  },
                                                  style: TextButton.styleFrom(
                                                    minimumSize: Size(
                                                      44.w,
                                                      44.h,
                                                    ),
                                                    foregroundColor: color,
                                                    padding:
                                                        EdgeInsetsDirectional.symmetric(
                                                          horizontal: 8.w,
                                                        ),
                                                  ),
                                                  child: Text(actionLabel),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (widget.entry.request.persistent ||
                                          widget.entry.request.type ==
                                              ClinicalPopupType.critical)
                                        IconButton(
                                          tooltip: 'Dismiss $severity message',
                                          constraints: BoxConstraints(
                                            minWidth: 44.w,
                                            minHeight: 44.h,
                                          ),
                                          onPressed: widget.onDismiss,
                                          icon: Icon(
                                            Icons.close_rounded,
                                            color: theme.subtleText,
                                            size: 18.sp,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (_progressController case final progress?)
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: FractionallySizedBox(
                                      widthFactor: 1 - progress.value,
                                      child: Container(
                                        height: 2.h,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(
                                            999.r,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SemanticIconBox extends StatelessWidget {
  const _SemanticIconBox({
    required this.color,
    required this.icon,
    required this.isLoading,
  });

  final Color color;
  final IconData icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34.w,
      height: 34.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: 17.w,
                height: 17.w,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, size: 19.sp, color: color),
      ),
    );
  }
}

class _DeveloperDiagnostics extends StatelessWidget {
  const _DeveloperDiagnostics({required this.diagnostics});

  final String diagnostics;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      dense: true,
      title: const Text('Developer details'),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SelectableText(
            diagnostics,
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}

class ClinicalFeedbackPanel extends StatelessWidget {
  const ClinicalFeedbackPanel({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.developerDiagnostics,
  });

  final ClinicalPopupType type;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? developerDiagnostics;

  @override
  Widget build(BuildContext context) {
    final color = _semanticColor(type);
    final theme = ClinicalFeedbackTheme.from(context);
    final diagnostics = developerDiagnostics;
    final label = actionLabel;
    return Semantics(
      container: true,
      label: _semanticAnnouncement(
        ClinicalPopupRequest(type: type, title: title, message: message),
      ),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              width: double.infinity,
              padding: EdgeInsetsDirectional.all(14.r),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: color.withValues(alpha: 0.22)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SemanticIconBox(
                    color: color,
                    icon: _semanticIcon(type),
                    isLoading: type == ClinicalPopupType.loading,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          message,
                          style: TextStyle(
                            color: theme.subtleText,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        if (kDebugMode &&
                            diagnostics != null &&
                            diagnostics.isNotEmpty)
                          _DeveloperDiagnostics(diagnostics: diagnostics),
                        if (label != null && label.isNotEmpty)
                          Padding(
                            padding: EdgeInsetsDirectional.only(top: 8.h),
                            child: TextButton(
                              onPressed: onAction,
                              child: Text(label),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showClinicalActionDialog<T>({
  required BuildContext context,
  required ClinicalPopupType type,
  required String title,
  required Widget content,
  required String primaryLabel,
  required VoidCallback onPrimary,
  String secondaryLabel = 'Cancel',
}) {
  final color = _semanticColor(type);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierLabel: title,
    transitionDuration: const Duration(milliseconds: 190),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final theme = ClinicalFeedbackTheme.from(dialogContext);
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 520.w),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: 20.w),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: Material(
                  color: theme.surface,
                  child: Padding(
                    padding: EdgeInsetsDirectional.all(24.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _SemanticIconBox(
                              color: color,
                              icon: _semanticIcon(type),
                              isLoading: false,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: theme.text,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        content,
                        SizedBox(height: 18.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text(secondaryLabel),
                            ),
                            SizedBox(width: 8.w),
                            FilledButton(
                              onPressed: onPrimary,
                              child: Text(primaryLabel),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.of(context).disableAnimations) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Color _semanticColor(ClinicalPopupType type) {
  switch (type) {
    case ClinicalPopupType.success:
      return const Color(0xFF10B981);
    case ClinicalPopupType.warning:
      return const Color(0xFFF59E0B);
    case ClinicalPopupType.error:
      return const Color(0xFFE15A5A); // Softer, nicer red instead of harsh standard red
    case ClinicalPopupType.info:
    case ClinicalPopupType.loading:
      return const Color(0xFF4F46E5);
    case ClinicalPopupType.critical:
      return const Color(0xFFEF4444);
  }
}

IconData _semanticIcon(ClinicalPopupType type) {
  switch (type) {
    case ClinicalPopupType.success:
      return Icons.check_circle_outline_rounded;
    case ClinicalPopupType.warning:
      return Icons.warning_amber_rounded;
    case ClinicalPopupType.error:
    case ClinicalPopupType.critical:
      return Icons.error_outline_rounded;
    case ClinicalPopupType.info:
      return Icons.info_outline_rounded;
    case ClinicalPopupType.loading:
      return Icons.hourglass_empty_rounded;
  }
}

String _semanticLabel(ClinicalPopupType type) {
  switch (type) {
    case ClinicalPopupType.success:
      return 'Success';
    case ClinicalPopupType.warning:
      return 'Warning';
    case ClinicalPopupType.error:
      return 'Error';
    case ClinicalPopupType.info:
      return 'Information';
    case ClinicalPopupType.loading:
      return 'In progress';
    case ClinicalPopupType.critical:
      return 'Critical alert';
  }
}

String _semanticAnnouncement(ClinicalPopupRequest request) {
  if (request.type == ClinicalPopupType.loading) {
    return 'In progress: ${request.title}. ${request.message}';
  }
  if (request.type == ClinicalPopupType.critical) {
    return 'Critical alert: ${request.title}. ${request.message}. Action required.';
  }
  return '${_semanticLabel(request.type)}: ${request.title}. ${request.message}';
}
