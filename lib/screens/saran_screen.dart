import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../services/transaction_service.dart';

class SaranScreen extends StatefulWidget {
  const SaranScreen({super.key});

  @override
  State<SaranScreen> createState() => _SaranScreenState();
}

class _SaranScreenState extends State<SaranScreen> {
  final _geminiService = GeminiService();
  final _transactionService = TransactionService();

  String _saran = '';
  bool _isLoading = false;
  bool _isError = false;
  String _errorMsg = '';

  Future<void> _getMintaSaran() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _saran = ''; // Reset agar animasi muncul dari awal
    });

    try {
      final transactions = await _transactionService.getAll();
      final saran = await _geminiService.getSaranKeuangan(transactions);

      final isError =
          saran.startsWith('⏳') ||
          saran.startsWith('🔑') ||
          saran.startsWith('📶') ||
          saran.startsWith('❌');

      setState(() {
        _isLoading = false;
        if (isError) {
          _isError = true;
          _errorMsg = saran;
        } else {
          _saran = saran;
          _isError = false;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMsg =
            '❌ Terjadi kesalahan saat mengambil saran. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A), // Warna background lebih deep
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AI Penasehat Keuanganku',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            // Dekorasi Background (Glow Effect)
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2D3BB5).withOpacity(0.15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  _buildGeminiBadge(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: _isLoading
                          ? _buildLoadingState()
                          : _isError
                          ? _buildErrorState()
                          : _saran.isEmpty
                          ? _buildEmptyState()
                          : _buildSuccessState(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildActionButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Badge Gemini yang lebih menarik
  Widget _buildGeminiBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2130),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2D3BB5).withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
          SizedBox(width: 8),
          Text(
            'Powered by Gemini 2.5 Flash',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Tampilan Sebelum Analisis (Empty State)
  Widget _buildEmptyState() {
    return Column(
      key: const ValueKey(1),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2130).withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            // child: Icon(Icons.insights_rounded, size: 80, color: Colors.white.withOpacity(0.2)),
            Icons.insights_rounded,
            size: 80,
            color: Color(0xFF4B5EE4),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Siap Mengatur Keuangan?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'AI akan menganalisis transaksimu dan memberikan strategi finansial terbaik untukmu.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  // 3. Tampilan Loading (Analysing State)
  Widget _buildLoadingState() {
    return Column(
      key: const ValueKey(2),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Color(0xFF4B5EE4),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Mengkalkulasi Data...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ini membutuhkan waktu sekitar 5 detik',
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
        ),
      ],
    );
  }

  // 4. Tampilan Hasil Analisis (Success State)
  Widget _buildSuccessState() {
    return SingleChildScrollView(
      key: const ValueKey(3),
      physics: const BouncingScrollPhysics(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2130),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.tips_and_updates_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Rekomendasi AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 32),
            Text(
              _saran,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Tampilan Error
  Widget _buildErrorState() {
    return Column(
      key: const ValueKey(4),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 60),
        const SizedBox(height: 16),
        Text(
          _errorMsg,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  // 6. Tombol Aksi Utama
  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _getMintaSaran,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D3BB5),
          disabledBackgroundColor: const Color(0xFF2D3BB5).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _saran.isEmpty
                        ? Icons.analytics_outlined
                        : Icons.refresh_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _saran.isEmpty ? 'Mulai Analisis' : 'Analisis Ulang',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
