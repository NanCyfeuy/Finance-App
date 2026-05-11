import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/home_screen.dart';
import 'screens/saran_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi data locale untuk package intl (contoh: id_ID)
  await initializeDateFormatting('id_ID', null);

  // Paksa status bar transparan agar UI menyatu dengan background gelap
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // ikon putih di status bar
    ),
  );

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance App',
      debugShowCheckedModeBanner: false,

      // ── Tema Gelap ──────────────────────────────────────────────────────────
      // Seluruh aplikasi menggunakan dark theme agar konsisten dengan desain
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF12141E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90D9),
          brightness: Brightness.dark,
        ),
        // Font default menggunakan sistem (bisa diganti dengan Google Fonts)
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),

      home: const HomeScreen(),

      routes: {
        // '/': (context) => const HomeScreen(),
        '/saran': (context) => const SaranScreen(),
      },
    );
  }
}
