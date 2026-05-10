import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard_screen.dart';
import 'statistik_screen.dart';
import 'dompet_screen.dart';
import 'tambah_transaksi_screen.dart';

/// HomeScreen adalah shell utama aplikasi yang mengelola navigasi
/// antar halaman menggunakan bottom navigation bar floating.
///
/// Struktur navigasi:
/// [0] Dashboard  - Ringkasan keuangan (halaman utama)
/// [1] Statistik  - Grafik dan analisis (placeholder)
/// [2] Dompet     - Kelola dompet/rekening (placeholder)
/// FAB (+)        - Tambah transaksi baru
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Indeks halaman yang sedang aktif
  int _currentIndex = 0;

  /// Daftar halaman yang bisa diakses via navbar
  final List<Widget> _pages = const [
    DashboardScreen(),  // index 0 - Dashboard
    StatistikScreen(),  // index 1 - Statistik
    DompetScreen(),     // index 2 - Dompet
  ];

  /// Mengganti halaman aktif dan memberikan haptic feedback
  void _onNavTap(int index) {
    if (_currentIndex == index) return; // tidak perlu rebuild jika sama
    HapticFeedback.lightImpact(); // feedback getaran ringan
    setState(() => _currentIndex = index);
  }

  /// Membuka halaman tambah transaksi sebagai modal bottom sheet
  void _onFabTap() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TambahTransaksiScreen(),
        fullscreenDialog: true, // animasi dari bawah ke atas
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141E),

      // Gunakan IndexedStack agar state setiap halaman tetap terjaga
      // saat berpindah tab (tidak di-rebuild dari awal)
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // Sembunyikan default bottom nav bar karena kita buat custom
      extendBody: true,

      // ── Floating Action Button (Tambah Transaksi) ──────────────────────────
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,

      // ── Bottom Navigation Bar Custom ───────────────────────────────────────
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// Membangun floating action button "+" untuk tambah transaksi
  Widget _buildFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FloatingActionButton(
        onPressed: _onFabTap,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF12141E),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  /// Membangun bottom navigation bar dengan desain floating pill (kapsul)
  Widget _buildBottomNavBar() {
    return Padding(
      // Padding agar navbar tidak menempel di tepi layar
      padding: const EdgeInsets.fromLTRB(16, 0, 80, 16),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          // Warna navbar sedikit lebih terang dari background
          color: const Color(0xFF1E2130),
          borderRadius: BorderRadius.circular(32), // bentuk pill/kapsul
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // ── Tab Dashboard ──────────────────────────────────────────────
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Dashboard',
            ),

            // ── Tab Statistik ──────────────────────────────────────────────
            _buildNavItem(
              index: 1,
              icon: Icons.bar_chart_outlined,
              activeIcon: Icons.bar_chart_rounded,
              label: 'Statistik',
            ),

            // ── Tab Dompet ─────────────────────────────────────────────────
            _buildNavItem(
              index: 2,
              icon: Icons.wallet_outlined,
              activeIcon: Icons.wallet_rounded,
              label: 'Dompet',
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun satu item navigasi di bottom navbar
  ///
  /// [index]      - indeks halaman yang dituju
  /// [icon]       - ikon saat tidak aktif
  /// [activeIcon] - ikon saat aktif (biasanya versi filled)
  /// [label]      - label teks di bawah ikon
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque, // area tap lebih luas
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Latar lingkaran untuk tab yang aktif
          color: isActive
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ikon berubah antara outlined dan filled saat aktif
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? Colors.white : Colors.white38,
              size: 24,
            ),
            // Label hanya ditampilkan saat tab aktif
            if (isActive) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
