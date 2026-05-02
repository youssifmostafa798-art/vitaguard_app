import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitaguard_app/core/alerts/alert_notification_service.dart';
import 'package:vitaguard_app/core/utils/screen_util_helper.dart';
import 'package:vitaguard_app/presentation/widgets/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CRITICAL: Supabase MUST be fully initialized before runApp().
  await Supabase.initialize(
    url: 'https://sumgvbdgucrjyiztmzyn.supabase.co',
    anonKey: 'sb_publishable_mn_LuYvFSEJBx4Kqt07Xpg_6mHktGkV',
  );

  // Initialize alert service after Supabase is ready (it may need the client).
  AlertNotificationService.instance.initialize().catchError((_) {});

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: ScreenUtilHelper.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      enableScaleWH: () => false,
      enableScaleText: () => false,
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'WixMadeforDisplay'),
          home: child,
        );
      },
      child: const AuthGate(),
    );
  }
}
