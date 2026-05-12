import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/dashboard_screen.dart'; // Import ini jika ingin langsung ke Dashboard

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // WAJIB: Harus 'id_ID' agar sinkron dengan file Dashboard
  await initializeDateFormatting('id_ID', null);

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D3BB5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // Kamu bisa ganti ke DashboardScreen() jika ingin langsung lihat hasilnya
      home: const DashboardScreen(),
    );
  }
}
