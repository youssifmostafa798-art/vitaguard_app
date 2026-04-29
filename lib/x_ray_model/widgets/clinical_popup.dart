import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PopupType { addToReport, flag, reviewed, override }

enum ClinicalPopupAnchor { bottomCenter, bottomRight, center }

class ClinicalPopupPalette {
  const ClinicalPopupPalette._();

  static const addToReport = Color(0xFF4F46E5);
  static const flag = Color(0xFFF59E0B);
  static const reviewed = Color(0xFF10B981);
  static const override = Color(0xFFEF4444);

  static Color forType(PopupType type) {
    switch (type) {
      case PopupType.addToReport:
        return addToReport;
      case PopupType.flag:
        return flag;
      case PopupType.reviewed:
        return reviewed;
      case PopupType.override:
        return override;
    }
  }
}

class ClinicalPopupController extends ChangeNotifier {
  static const Duration displayDuration = Duration(milliseconds: 1500);
  static const int maxVisiblePopups = 2;

  final List<_ClinicalPopupData> _popups = [];
  final Map<int, Timer> _timers = {};
  int _nextId = 0;

  List<_ClinicalPopupData> get _visiblePopups => List.unmodifiable(_popups);

  void showClinicalPopup({
    required String message,
    required Color color,
    required IconData icon,
    PopupType type = PopupType.reviewed,
    ClinicalPopupAnchor anchor = ClinicalPopupAnchor.bottomRight,
  }) {
    HapticFeedback.lightImpact();

    final existingIndex = _popups.indexWhere((popup) => popup.type == type);
    if (existingIndex != -1) {
      final old = _popups[existingIndex];
      _cancelTimer(old.id);
      _popups[existingIndex] = old.copyWith(
        message: message,
        color: color,
        icon: icon,
        anchor: anchor,
        revision: old.revision + 1,
        exiting: false,
      );
      _startDismissTimer(old.id);
      notifyListeners();
      return;
    }

    final popup = _ClinicalPopupData(
      id: _nextId++,
      message: message,
      color: color,
      icon: icon,
      type: type,
      anchor: anchor,
    );

    _popups.insert(0, popup);
    while (_popups.length > maxVisiblePopups) {
      final removed = _popups.removeLast();
      _cancelTimer(removed.id);
    }
    _startDismissTimer(popup.id);
    notifyListeners();
  }

  void dismiss(int id) {
    final index = _popups.indexWhere((popup) => popup.id == id);
    if (index == -1) return;
    _cancelTimer(id);
    if (_popups[index].exiting) return;
    _popups[index] = _popups[index].copyWith(exiting: true);
    notifyListeners();
    _timers[id] = Timer(
      const Duration(milliseconds: 150),
      () => _removeNow(id),
    );
  }

  void _removeNow(int id) {
    final index = _popups.indexWhere((popup) => popup.id == id);
    if (index == -1) return;
    _popups.removeAt(index);
    _cancelTimer(id);
    notifyListeners();
  }

  void _startDismissTimer(int id) {
    _timers[id] = Timer(displayDuration, () => dismiss(id));
  }

  void _cancelTimer(int id) {
    _timers.remove(id)?.cancel();
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}

class ClinicalPopupHost extends StatefulWidget {
  const ClinicalPopupHost({
    super.key,
    required this.controller,
    required this.child,
  });

  final ClinicalPopupController controller;
  final Widget child;

  @override
  State<ClinicalPopupHost> createState() => _ClinicalPopupHostState();
}

class _ClinicalPopupHostState extends State<ClinicalPopupHost> {
  final OverlayPortalController _overlayController = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handlePopupStateChanged);
  }

  @override
  void didUpdateWidget(covariant ClinicalPopupHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_handlePopupStateChanged);
    widget.controller.addListener(_handlePopupStateChanged);
    _handlePopupStateChanged();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handlePopupStateChanged);
    super.dispose();
  }

  void _handlePopupStateChanged() {
    if (!mounted) return;
    if (widget.controller._visiblePopups.isEmpty) {
      _overlayController.hide();
    } else {
      _overlayController.show();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: (context) {
        return IgnorePointer(
          child: _ClinicalPopupOverlay(popups: widget.controller._visiblePopups),
        );
      },
      child: widget.child,
    );
  }
}

class _ClinicalPopupOverlay extends StatelessWidget {
  const _ClinicalPopupOverlay({required this.popups});

  final List<_ClinicalPopupData> popups;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var index = popups.length - 1; index >= 0; index--)
          _AnchoredPopup(
            popup: popups[index],
            stackIndex: index,
          ),
      ],
    );
  }
}

class _AnchoredPopup extends StatelessWidget {
  const _AnchoredPopup({
    required this.popup,
    required this.stackIndex,
  });

  final _ClinicalPopupData popup;
  final int stackIndex;

  @override
  Widget build(BuildContext context) {
    final bottomOffset = 104.0 + (stackIndex * 68.0);
    final horizontalInset = 18.0;

    switch (popup.anchor) {
      case ClinicalPopupAnchor.center:
        return Center(
          child: _ClinicalPopupCard(
            key: ValueKey('${popup.id}-${popup.revision}'),
            popup: popup,
          ),
        );
      case ClinicalPopupAnchor.bottomCenter:
        return Positioned(
          left: horizontalInset,
          right: horizontalInset,
          bottom: bottomOffset,
          child: Center(
            child: _ClinicalPopupCard(
              key: ValueKey('${popup.id}-${popup.revision}'),
              popup: popup,
            ),
          ),
        );
      case ClinicalPopupAnchor.bottomRight:
        return Positioned(
          right: horizontalInset,
          bottom: bottomOffset,
          child: _ClinicalPopupCard(
            key: ValueKey('${popup.id}-${popup.revision}'),
            popup: popup,
          ),
        );
    }
  }
}

class _ClinicalPopupCard extends StatefulWidget {
  const _ClinicalPopupCard({
    super.key,
    required this.popup,
  });

  final _ClinicalPopupData popup;

  @override
  State<_ClinicalPopupCard> createState() => _ClinicalPopupCardState();
}

class _ClinicalPopupCardState extends State<_ClinicalPopupCard>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _progressController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _shake;
  late final Animation<double> _borderPulse;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: ClinicalPopupController.displayDuration,
    );

    final curved = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(curved);
    _scale = _scaleTween().animate(curved);
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -2, end: 2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 2, end: 0), weight: 1),
    ]).animate(curved);
    _borderPulse = Tween<double>(begin: 0.35, end: 0.9).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );

    _entryController.forward();
    _progressController.forward();
  }

  Tween<double> _scaleTween() {
    if (widget.popup.type == PopupType.addToReport) {
      return Tween<double>(begin: 0.95, end: 1.05);
    }
    return Tween<double>(begin: 0.95, end: 1);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.popup.color;
    return AnimatedBuilder(
      animation: Listenable.merge([_entryController, _progressController]),
      builder: (context, child) {
        final xOffset = widget.popup.type == PopupType.flag ? _shake.value : 0.0;
        final borderAlpha = widget.popup.type == PopupType.override
            ? _borderPulse.value
            : 0.22;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          opacity: widget.popup.exiting ? 0 : _fade.value,
          child: Transform.translate(
            offset: Offset(xOffset, 0),
            child: Transform.scale(
              scale: _scale.value,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 330),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF).withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: widget.popup.type == PopupType.override
                            ? color.withValues(alpha: borderAlpha)
                            : Colors.white.withValues(alpha: 0.46),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.14),
                          blurRadius: 24,
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
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.22),
                                    ),
                                  ),
                                  child: Icon(
                                    widget.popup.icon,
                                    size: 18,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    widget.popup.message,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 13.5,
                                      height: 1.25,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: 1 - _progressController.value,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(999),
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
        );
      },
    );
  }
}

class _ClinicalPopupData {
  const _ClinicalPopupData({
    required this.id,
    required this.message,
    required this.color,
    required this.icon,
    required this.type,
    required this.anchor,
    this.revision = 0,
    this.exiting = false,
  });

  final int id;
  final String message;
  final Color color;
  final IconData icon;
  final PopupType type;
  final ClinicalPopupAnchor anchor;
  final int revision;
  final bool exiting;

  _ClinicalPopupData copyWith({
    String? message,
    Color? color,
    IconData? icon,
    ClinicalPopupAnchor? anchor,
    int? revision,
    bool? exiting,
  }) {
    return _ClinicalPopupData(
      id: id,
      message: message ?? this.message,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      type: type,
      anchor: anchor ?? this.anchor,
      revision: revision ?? this.revision,
      exiting: exiting ?? this.exiting,
    );
  }
}
