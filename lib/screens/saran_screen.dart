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
    });

    final transactions = await _transactionService.getAll();
    final saran = await _geminiService.getSaranKeuangan(transactions);

    // Cek apakah hasil adalah error
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12141E),
        elevation: 0,
        title: const Text(
          'AI Saran',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          children: [
            // ── Badge Gemini ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2130),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2D3BB5).withOpacity(0.5),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.amber, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Powered by Gemini 2.5 Flash',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Konten Utama ───────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _isError
                  ? _buildError()
                  : _saran.isEmpty
                  ? _buildEmpty()
                  : _buildHasilSaran(),
            ),

            const SizedBox(height: 16),

            // ── Tombol ─────────────────────────────────────────────────
            _buildTombol(),
          ],
        ),
      ),
    );
  }

  // ── Widget Loading ───────────────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: const Color(0xFF4B5EE4),
              backgroundColor: Colors.white.withOpacity(0.08),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Menganalisis keuanganmu...',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text(
            'Biasanya butuh 5-10 detik',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Widget Error ─────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Colors.redAccent,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMsg,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget Kosong (belum ada saran) ──────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustrasi sederhana
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2D3BB5).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum ada analisis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tekan tombol di bawah untuk mendapatkan\nsaran keuangan dari AI',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ── Widget Hasil Saran ───────────────────────────────────────────────
  Widget _buildHasilSaran() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label waktu
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.greenAccent,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Analisis selesai',
                style: TextStyle(
                  color: Colors.greenAccent.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Kartu hasil saran
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2130),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Text(
              _saran,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tombol Minta Saran ───────────────────────────────────────────────
  Widget _buildTombol() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _getMintaSaran,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D3BB5),
          disabledBackgroundColor: const Color(0xFF2D3BB5).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _saran.isEmpty ? 'Analisis Sekarang' : 'Analisis Ulang',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
