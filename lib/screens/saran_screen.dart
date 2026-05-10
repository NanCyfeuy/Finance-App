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

  Future<void> _getMintaSaran() async {
    setState(() => _isLoading = true);

    // 1. Ambil data transaksi dari Supabase
    final transactions = await _transactionService.getAll();

    // 2. Kirim ke Gemini
    final saran = await _geminiService.getSaranKeuangan(transactions);

    setState(() {
      _saran = saran;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _getMintaSaran(); // langsung minta saran saat halaman dibuka
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saran Keuangan AI',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2D3BB5),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3BB5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Text('🤖', style: TextStyle(fontSize: 32)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Asisten Keuangan AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Powered by Gemini',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Konten saran
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF2D3BB5)),
                          SizedBox(height: 16),
                          Text(
                            'Gemini sedang menganalisis\nkeuangan kamu...',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _saran,
                          style: const TextStyle(fontSize: 15, height: 1.6),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // Tombol refresh
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _getMintaSaran,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Minta Saran Baru',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3BB5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
