import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/presentation/screens/auth/role_screen.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/core/utils/home_header.dart';
import 'package:vitaguard_app/presentation/widgets/patient/category_grid_patient.dart';
import 'package:vitaguard_app/presentation/widgets/patient/home_search.dart';
import 'package:vitaguard_app/presentation/screens/patient/chat_list_patient.dart';
import 'package:vitaguard_app/presentation/controllers/auth/auth_provider.dart';

import '../../../core/utils/custem_background.dart';
import '../../../core/utils/custem_text.dart';
class PatientHome extends ConsumerStatefulWidget {
  final String name;

  const PatientHome({super.key, required this.name});

  @override
  ConsumerState<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends ConsumerState<PatientHome> {
  String _searchQuery = '';
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeHeader(
        name_: widget.name,
        onExit: () {
          ref.read(authControllerProvider.notifier).logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const RoleScreen()),
            (route) => false,
          );
        },
      ),
      body: SafeArea(
        child: AppBackground(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: ListView(
              children: [
                Gap(20.h),
                HomeSearch(
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),

                if (_searchQuery.isEmpty) ...[
                  Gap(10.h),
                  _buildAvailableDoctorsList(),
                ],

                Gap(30.h),
                CategoryGridPatient(
                  patientName: widget.name,
                  searchQuery: _searchQuery,
                ),
                Gap(10.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableDoctorsList() {
    final doctors = [
      {
        'name': 'Dr. Ahmed Mahmoud',
        'specialization': 'Cardiology - Saudi German Hospital',
        'verification_status': 'approved',
        'rating': '4.9',
        'experience': '15',
      },
      {
        'name': 'Dr. Sarah Samy',
        'specialization': 'Pulmonology - Al Andalus Clinic',
        'verification_status': 'approved',
        'rating': '4.8',
        'experience': '10',
      },
      {
        'name': 'Dr. Mohamed Ali',
        'specialization': 'Internal Medicine - Elite Care',
        'verification_status': 'approved',
        'rating': '4.7',
        'experience': '12',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustemText(
          text: "Suggested Doctors",
          size: 22,
          spacing: 3,
          color: const Color(0xff003F6B),
          weight: FontWeight.bold,
        ),
        Gap(15.h),
        SizedBox(
          height: 180.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: doctors.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final doc = doctors[index];
              return _DoctorSuggestionCard(
                name: doc['name']!,
                specialization: doc['specialization']!,
                verificationStatus: doc['verification_status']!,
                rating: doc['rating']!,
                experience: doc['experience']!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatListPatient(),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Removed _LatestVitalsCard from here ─────────────────────────────────────

// ─── Doctor suggestion card ───────────────────────────────────────────────────

class _DoctorSuggestionCard extends StatelessWidget {
  const _DoctorSuggestionCard({
    required this.name,
    required this.specialization,
    required this.verificationStatus,
    required this.rating,
    required this.experience,
    required this.onTap,
  });

  final String name;
  final String specialization;
  final String verificationStatus;
  final String rating;
  final String experience;
  final VoidCallback onTap;

  bool get isVerified => verificationStatus == 'approved';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160.w,
        margin: EdgeInsets.only(right: 14.w),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isVerified
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.border.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 30.r,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 32.r,
                  ),
                ),
                if (isVerified)
                  Container(
                    padding: EdgeInsets.all(2.r),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      color: AppColors.success,
                      size: 16.r,
                    ),
                  ),
              ],
            ),
            Gap(8.h),
            Text(
              name,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Gap(2.h),
            Text(
              specialization,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Gap(6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, color: Colors.orange, size: 14.sp),
                Gap(2.w),
                Text(
                  rating,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Gap(8.w),
                Icon(Icons.work_history_rounded, color: AppColors.textSecondary, size: 12.sp),
                Gap(2.w),
                Text(
                  '$experience y',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Gap(8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Book Appointment',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
