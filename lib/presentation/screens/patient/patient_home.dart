import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/presentation/screens/auth/role_screen.dart';
import 'package:vitaguard_app/presentation/widgets/custem_background.dart';
import 'package:vitaguard_app/core/utils/home_header.dart';
import 'package:vitaguard_app/presentation/widgets/patient/category_grid_patient.dart';
import 'package:vitaguard_app/presentation/widgets/patient/home_search.dart';
import 'package:vitaguard_app/presentation/screens/patient/chat_list_patient.dart';
import 'package:vitaguard_app/presentation/widgets/custem_text.dart';
import 'package:vitaguard_app/presentation/controllers/auth/auth_provider.dart';
import 'package:vitaguard_app/presentation/controllers/patient/patient_provider.dart';

class PatientHome extends ConsumerStatefulWidget {
  final String name;

  const PatientHome({super.key, required this.name});

  @override
  ConsumerState<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends ConsumerState<PatientHome> {
  String _searchQuery = '';

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
                  Gap(20.h),
                  _buildAvailableDoctorsList(),
                ],

                Gap(30.h),
                CategoryGridPatient(patientName: widget.name, searchQuery: _searchQuery),
                Gap(10.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableDoctorsList() {
    final patientRepo = ref.read(patientControllerProvider.notifier).repository;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //Available Doctors
        CustemText(
          text: "Available Doctors",
          size: 22,
          spacing: 3,
          color: const Color(0xff003F6B),
          weight: FontWeight.bold,
        ),
        Gap(15.h),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: patientRepo.getAvailableDoctors(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Text("Error loading doctors.");
            }
            
            final doctors = snapshot.data ?? [];
            if (doctors.isEmpty) {
              return const Text("No doctors available offline.");
            }

            return SizedBox(
              height: 120.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: doctors.length,
                itemBuilder: (context, index) {
                  final doc = doctors[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChatListPatient(),
                        ),
                      );
                    },
                    child: Container(
                      width: 100.w,
                      margin: EdgeInsets.only(right: 15.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5.r,
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30.r,
                            backgroundColor: const Color(0xff003F6B).withValues(alpha: 0.1),
                            child: Icon(Icons.person, color: const Color(0xff003F6B), size: 30.r),
                          ),
                          Gap(10.h),
                          Text(
                            doc['name'] ?? 'Doctor',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff003F6B),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}