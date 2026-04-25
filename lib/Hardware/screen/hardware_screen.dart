import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart' as legacy;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitaguard_app/core/network/vital_alert_service.dart';
import 'package:vitaguard_app/Hardware/screen/metric_card.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';

class HardwareScreen extends legacy.ConsumerStatefulWidget {
  const HardwareScreen({
    super.key,
    this.patientId,
    this.patientName,
    this.automaticallyImplyLeading = true,
  });

  /// When set (e.g. doctor viewing a patient), vitals load for this id; otherwise uses the signed-in user.
  final String? patientId;
  final String? patientName;
  final bool automaticallyImplyLeading;

  @override
  legacy.ConsumerState<HardwareScreen> createState() => _HardwareScreenState();
}

class _HardwareScreenState extends legacy.ConsumerState<HardwareScreen> with TickerProviderStateMixin {
  static const double _horizontalPadding = 24;

  Map<String, dynamic>? _latestVitals;
  RealtimeChannel? _channel;
  late AnimationController _alertController;

  @override
  void initState() {
    super.initState();
    _alertController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _subscribeToVitals();
  }

  Future<void> _subscribeToVitals() async {
    final String? patientId =
        widget.patientId ?? Supabase.instance.client.auth.currentUser?.id;
    if (patientId == null) return;

    // 1. Load the most recent row right away so the screen isn't blank
    try {
      final row = await Supabase.instance.client
          .from('patient_live_vitals')
          .select()
          .eq('patient_id', patientId)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row != null && mounted) {
        setState(() => _latestVitals = row);
      }
    } catch (_) {}

    // 2. Real-time push: fires instantly when ESP32 inserts a new row
    _channel = Supabase.instance.client
        .channel('hw_vitals_$patientId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all, // Listen for inserts and updates
          schema: 'public',
          table: 'patient_live_vitals',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: patientId,
          ),
          callback: (payload) {
            if (mounted) {
              final newRecord = payload.newRecord;
              setState(() {
                _latestVitals = newRecord;
              });

              // Staff Implementation: Pipe raw metrics into clinical alert service
              final bpm = double.tryParse(newRecord['bpm']?.toString() ?? '0') ?? 0;
              final spo2 = double.tryParse(newRecord['spo2']?.toString() ?? '0') ?? 0;
              
              // Correct access for clinical metrics using legacy notifier
              ref.read(vitalAlertProvider).processMetrics(
                spo2: spo2,
                bpm: bpm,
              );
            }
          },
        )
        .subscribe();
  }

  Future<void> _onRefresh() async {
    _channel?.unsubscribe();
    await _subscribeToVitals();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _alertController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final data = _latestVitals;

    // Helper to parse vitals safely whether they come as String or num
    double parseVital(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    final double bpmVal = parseVital(data?['bpm']);
    final double spo2Val = parseVital(data?['spo2']);
    final double tempVal = parseVital(data?['temperature']);

    // Senior Staff Implementation: React to sustained clinical alerts from the provider
    final alertState = ref.watch(vitalAlertProvider);
    
    final String bpm = bpmVal > 0 ? bpmVal.toInt().toString() : '--';
    final String spo2 = spo2Val > 0 ? '${spo2Val.toInt()}%' : '--';
    final String temp = tempVal > 0 ? '${tempVal.toStringAsFixed(1)}°C' : '--';

    final String status;
    final Color statusColor;
    final String battery;
    final String signal;
    
    final deviceStatus = data?['device_status'] ?? 'Offline';
    
    // An emergency is either a hardware-detected event or a sustained clinical violation
    final bool isEmergency = deviceStatus.toString().contains('EMERGENCY') || alertState.state.isTriggered;

    if (data == null) {
      status = 'Offline';
      statusColor = Colors.grey;
      battery = '--';
      signal = '--';
    } else if (deviceStatus == 'Waiting for Finger') {
      status = 'Awaiting Patient';
      statusColor = Colors.orange;
      battery = '100%';
      signal = 'Strong';
    } else if (isEmergency) {
      status = 'CRITICAL ALERT';
      statusColor = AppColors.error;
      battery = '100%';
      signal = 'Strong';
    } else {
      status = 'Online';
      statusColor = AppColors.success;
      battery = '100%';
      signal = 'Strong';
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBackground(
          child: AppBar(
            automaticallyImplyLeading: widget.automaticallyImplyLeading,
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: AnimatedBuilder(
          animation: _alertController,
          builder: (context, child) {
            final alertOpacity = isEmergency ? (0.2 + 0.3 * _alertController.value) : 0.0;
            return Stack(
              children: [
                // Emergency Pulse Background
                if (isEmergency)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: AppColors.error.withValues(alpha: alertOpacity),
                  ),
                SafeArea(
                  child: AppBackground(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: _horizontalPadding.w,
                        vertical: 18.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isEmergency) ...[
                            _EmergencyBanner(
                              status: deviceStatus,
                              clinicalMessage: alertState.state.isTriggered ? alertState.state.message : null,
                            ),
                            SizedBox(height: 20.h),
                          ],
                          Text(
                            'DEVICE LIVE STATUS',
                            style: textTheme.labelMedium?.copyWith(
                              fontSize: 13.sp,
                              color: isEmergency ? AppColors.error : AppColors.primary.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Container(
                                width: 11.w,
                                height: 11.w,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                  boxShadow: isEmergency ? [
                                    BoxShadow(
                                      color: AppColors.error.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ] : null,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'VitaGuard Core',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontSize: 32.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (widget.patientName != null &&
                                        widget.patientName!.isNotEmpty) ...[
                                      SizedBox(height: 4.h),
                                      Text(
                                        widget.patientName!,
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontSize: 16.sp,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 34.h),
                          _HeartRateRing(
                            bpm: bpm, 
                            isEmergency: isEmergency,
                            pulseValue: _alertController.value,
                          ),
                          SizedBox(height: 24.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 18.w,
                              vertical: 18.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isEmergency 
                                  ? AppColors.error.withValues(alpha: 0.3)
                                  : colorScheme.outlineVariant.withValues(
                                      alpha: 0.26,
                                    ),
                                width: isEmergency ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _StatusInfoItem(
                                    title: 'Status',
                                    value: status,
                                    valueColor: statusColor,
                                  ),
                                ),
                                Expanded(
                                  child: _StatusInfoItem(
                                    title: 'Battery',
                                    value: battery,
                                  ),
                                ),
                                Expanded(
                                  child: _StatusInfoItem(
                                    title: 'Signal',
                                    value: signal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 30.h),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sensor Array',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontSize: 38.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Real-time peripheral metrics',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontSize: 18.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.wifi_tethering_rounded,
                                size: 30.sp,
                                color: isEmergency 
                                  ? AppColors.error.withValues(alpha: 0.5)
                                  : AppColors.primary.withValues(alpha: 0.32),
                              ),
                            ],
                          ),
                          SizedBox(height: 18.h),
                          Row(
                            children: [
                              MetricCard(
                                icon: Icons.water_drop_rounded,
                                iconColor: const Color(0xFF0F766E),
                                iconBackgroundColor: const Color(0xFFD7F3EF),
                                value: spo2,
                                label: 'SPO2 (%)',
                              ),
                              SizedBox(width: 14.w),
                              MetricCard(
                                icon: Icons.device_thermostat_rounded,
                                iconColor: AppColors.primary,
                                iconBackgroundColor: const Color(0xFFE4EEFD),
                                value: temp,
                                label: 'BODY TEMP',
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  final String status;
  final String? clinicalMessage;
  const _EmergencyBanner({required this.status, this.clinicalMessage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clinicalMessage != null ? 'CLINICAL ALERT' : 'EMERGENCY DETECTED',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16.sp,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  clinicalMessage ?? (status == 'EMERGENCY_NO_PULSE' 
                    ? 'Check patient immediately - No Pulse Detected' 
                    : 'Unusual vitals or fall detected'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartRateRing extends StatelessWidget {
  final String bpm;
  final bool isEmergency;
  final double pulseValue;
  
  const _HeartRateRing({
    required this.bpm, 
    this.isEmergency = false,
    this.pulseValue = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ringColor = isEmergency ? AppColors.error : const Color(0xFFE6E8EE);
    final iconColor = isEmergency ? AppColors.error : AppColors.primary;
    
    return Align(
      child: Container(
        width: 280.w,
        height: 280.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isEmergency 
              ? ringColor.withValues(alpha: 0.3 + 0.4 * pulseValue)
              : ringColor, 
            width: 14.w + (isEmergency ? 4.w * pulseValue : 0),
          ),
        ),
        child: Center(
          child: Container(
            width: 214.w,
            height: 214.w,
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite, 
                  color: iconColor, 
                  size: 36.sp + (isEmergency ? 10.sp * pulseValue : 0),
                ),
                SizedBox(height: 8.h),
                Text(
                  bpm,
                  style: textTheme.displayMedium?.copyWith(
                    fontSize: 78.sp,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                    color: isEmergency ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'BPM',
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 22.sp,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _StatusInfoItem extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _StatusInfoItem({
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontSize: 20.sp,
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
