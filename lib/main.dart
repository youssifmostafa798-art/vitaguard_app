import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitaguard_app/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://sumgvbdgucrjyiztmzyn.supabase.co',
    anonKey: 'sb_publishable_mn_LuYvFSEJBx4Kqt07Xpg_6mHktGkV',
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'WixMadeforDisplay'),
      home: const SplashScreen(),
    );
  }
}
