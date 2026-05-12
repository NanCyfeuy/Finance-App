import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'providers/wallet_provider.dart';
import 'screens/saran_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Provider di level root agar semua route (termasuk fullscreenDialog) bisa akses
  final _walletProvider = WalletProvider();

  @override
  void initState() {
    super.initState();
    _walletProvider.loadFromSupabase();
  }

  @override
  void dispose() {
    _walletProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WalletProviderScope(
      provider: _walletProvider,
      child: MaterialApp(
        title: 'Finance App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2D3BB5),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        routes: {
          '/saran': (context) => const SaranScreen(),
        },
      ),
    );
  }
}
