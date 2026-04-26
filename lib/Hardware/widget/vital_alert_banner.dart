import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/doctor/data/vital_alert_model.dart';

/// Three-state animated banner that lives at the top of [HardwareScreen].
///
/// State A — Active alert  : full-width red/orange banner
/// State B — Pre-alert     : slim translucent amber progress strip
/// State C — No alert      : [SizedBox.shrink] — zero layout cost
///
/// Haptics:
///   Pre-alert onset  → [HapticFeedback.selectionClick]
///   Alert fires      → [HapticFeedback.heavyImpact]
class VitalAlertBanner extends StatefulWidget {
  final VitalAlertState alertState;

  /// Called when the dismiss ("×") button is tapped.
  /// The parent is responsible for calling [AlertTimerService.snooze].
  final VoidCallback onDismiss;

  const VitalAlertBanner({
    super.key,
    required this.alertState,
    required this.onDismiss,
  });

  @override
  State<VitalAlertBanner> createState() => _VitalAlertBannerState();
}

class _VitalAlertBannerState extends State<VitalAlertBanner>
    with SingleTickerProviderStateMixin {
  // Track previous states so we fire haptics exactly once per transition.
  bool _wasAlert    = false;
  bool _wasPreAlert = false;

  @override
  void didUpdateWidget(VitalAlertBanner old) {
    super.didUpdateWidget(old);

    final isAlert    = widget.alertState.hasAlert;
    final isPreAlert = widget.alertState.hasPreAlert;

    if (isAlert && !_wasAlert) {
      HapticFeedback.heavyImpact();
    } else if (isPreAlert && !_wasPreAlert && !isAlert) {
      HapticFeedback.selectionClick();
    }

    _wasAlert    = isAlert;
    _wasPreAlert = isPreAlert;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve:  Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end:   Offset.zero,
        ).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final state = widget.alertState;

    if (state.hasAlert) {
      return _ActiveAlertBanner(
        key:        ValueKey('alert_${state.primaryAlert!.id}'),
        alertState: state,
        onDismiss:  widget.onDismiss,
      );
    }

    if (state.hasPreAlert) {
      return _PreAlertStrip(
        key:     const ValueKey('pre_alert'),
        preAlert: state.preAlert!,
      );
    }

    return const SizedBox.shrink(key: ValueKey('none'));
  }
}

// ─── State A: Full active-alert banner ────────────────────────────────────────

class _ActiveAlertBanner extends StatelessWidget {
  final VitalAlertState alertState;
  final VoidCallback onDismiss;

  const _ActiveAlertBanner({
    super.key,
    required this.alertState,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final alert = alertState.primaryAlert!;
    final isCritical = alert.severity == AlertSeverity.critical;

    final Color bg   = isCritical ? const Color(0xFFC62828) : const Color(0xFFE65100);
    final Color soft = isCritical ? const Color(0xFFEF9A9A) : const Color(0xFFFFCC80);

    final int extra = alertState.allAlerts.length - 1;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ───────────────────────────────────────────────────────
              _PulsingIcon(
                icon:  isCritical
                    ? Icons.warning_rounded
                    : Icons.info_outline_rounded,
                color: Colors.white,
              ),
              Gap(12.w),

              // ── Message + timestamp ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.message,
                      style: TextStyle(
                        color:      Colors.white,
                        fontSize:   14.sp,
                        fontWeight: FontWeight.w700,
                        height:     1.3,
                      ),
                    ),
                    Gap(2.h),
                    Row(
                      children: [
                        Text(
                          _timeAgo(alert.timestamp),
                          style: TextStyle(
                            color:   Colors.white.withValues(alpha: 0.75),
                            fontSize: 11.sp,
                          ),
                        ),
                        if (extra > 0) ...[
                          Gap(8.w),
                          GestureDetector(
                            onTap: () => _showAllAlerts(context),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w, vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                '+$extra more',
                                style: TextStyle(
                                  color:      soft,
                                  fontSize:   10.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Dismiss ────────────────────────────────────────────────────
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color:  Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size:  18.r,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllAlerts(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => _AllAlertsSheet(alerts: alertState.allAlerts),
    );
  }

  String _timeAgo(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 60) return 'Just now';
    return '${diff.inMinutes}m ago';
  }
}

// ─── State B: Pre-alert progress strip ────────────────────────────────────────

class _PreAlertStrip extends StatelessWidget {
  final PreAlertInfo preAlert;

  const _PreAlertStrip({super.key, required this.preAlert});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.withValues(alpha: 0.12),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
              child: Row(
                children: [
                  _PulsingDot(),
                  Gap(10.w),
                  Expanded(
                    child: Text(
                      preAlert.label,
                      style: TextStyle(
                        color:      const Color(0xFFE65100),
                        fontSize:   13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${((1.0 - preAlert.progress) * VitalThresholds.alertOnsetDelay.inSeconds).ceil()}s',
                    style: TextStyle(
                      color:      const Color(0xFFE65100).withValues(alpha: 0.7),
                      fontSize:   11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            LinearProgressIndicator(
              value:           preAlert.progress,
              minHeight:       3,
              backgroundColor: Colors.orange.withValues(alpha: 0.15),
              valueColor:      const AlwaysStoppedAnimation<Color>(
                Color(0xFFE65100),
              ),
            ),
            Gap(2.h),
          ],
        ),
      ),
    );
  }
}

// ─── All-alerts bottom sheet ──────────────────────────────────────────────────

class _AllAlertsSheet extends StatelessWidget {
  final List<VitalAlert> alerts;

  const _AllAlertsSheet({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          Gap(16.h),
          Text(
            'Active Alerts',
            style: TextStyle(
              fontSize:   17.sp,
              fontWeight: FontWeight.w700,
              color:      const Color(0xFF1E2A3E),
            ),
          ),
          Gap(12.h),
          ...alerts.map((a) => _AlertRow(alert: a)),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final VitalAlert alert;

  const _AlertRow({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = VitalThresholds.getSeverityColor(alert.severity);
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Icon(
            alert.severity == AlertSeverity.critical
                ? Icons.warning_rounded
                : Icons.info_outline_rounded,
            color: color,
            size:  20.r,
          ),
          Gap(10.w),
          Expanded(
            child: Text(
              alert.message,
              style: TextStyle(
                fontSize:   13.sp,
                fontWeight: FontWeight.w600,
                color:      const Color(0xFF1E2A3E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable animated helpers ────────────────────────────────────────────────

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _PulsingIcon({required this.icon, required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(widget.icon, color: widget.color, size: 24.r),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width:  9.r,
        height: 9.r,
        decoration: const BoxDecoration(
          color: Color(0xFFE65100),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
