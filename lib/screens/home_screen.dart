import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard_screen.dart';
import 'statistik_screen.dart';
import 'dompet_screen.dart';
import 'tambah_transaksi_screen.dart';
import 'saran_screen.dart';

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
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    StatistikScreen(),
    DompetScreen(),
    SaranScreen(),
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
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: _buildPageWithFade(),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  /// Fade transition saat berpindah tab
  Widget _buildPageWithFade() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(
        key: ValueKey<int>(_currentIndex),
        child: _pages[_currentIndex],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Pill navbar dengan blur + transparan ─────────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    // Transparan dengan sedikit warna gelap
                    color: const Color(0xFF1A1D2E).withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(index: 0, icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded),
                      _buildNavItem(index: 1, icon: Icons.bar_chart_outlined,
                          activeIcon: Icons.bar_chart_rounded),
                      _buildNavItem(index: 2, icon: Icons.wallet_outlined,
                          activeIcon: Icons.wallet_rounded),
                      _buildNavItem(index: 3, icon: Icons.auto_awesome_outlined,
                          activeIcon: Icons.auto_awesome),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── Tombol + bulat ───────────────────────────────────────────────
          GestureDetector(
            onTap: _onFabTap,
            child: Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Color(0xFF12141E),
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          // Lingkaran solid gelap saat aktif, transparan saat tidak aktif
          color: isActive
              ? const Color(0xFF2E3248)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            isActive ? activeIcon : icon,
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
            size: 24,
          ),
        ),
      ),
    );
  }
}
