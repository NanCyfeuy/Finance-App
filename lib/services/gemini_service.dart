import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/gemini_config.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class GeminiService {
  late final GenerativeModel _model;
  final _formatRupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // model gratis & cepat
      apiKey: GeminiConfig.apiKey,
    );
  }

  // Fungsi utama: minta saran keuangan
  Future<String> getSaranKeuangan(List<TransactionModel> transactions) async {
    try {
      // 1. Siapkan ringkasan data transaksi
      final ringkasan = _buatRingkasan(transactions);

      // 2. Buat prompt untuk Gemini
      final prompt =
          '''
Kamu adalah asisten keuangan pribadi yang membantu mahasiswa Indonesia.
Berikan analisis dan saran keuangan yang singkat, ramah, dan praktis
dalam Bahasa Indonesia berdasarkan data transaksi berikut:

$ringkasan

Berikan respons dalam format:
1. Ringkasan kondisi keuangan (2-3 kalimat)
2. Hal positif dari pola keuangan user (1-2 poin)
3. Saran perbaikan yang spesifik (2-3 poin)
4. Motivasi singkat di akhir (1 kalimat)

Gunakan emoji yang relevan. Jawab maksimal 200 kata.
''';

      // 3. Kirim ke Gemini
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      // 4. Kembalikan hasil
      return response.text ?? 'Tidak ada saran yang tersedia.';
    } catch (e) {
      // Cek jenis error
      final errorMsg = e.toString();

      if (errorMsg.contains('quota') || errorMsg.contains('rate')) {
        return '⏳ Permintaan terlalu sering.\n\nCoba lagi dalam beberapa detik ya!';
      } else if (errorMsg.contains('API key')) {
        return '🔑 API Key tidak valid.\n\nCek kembali konfigurasi Gemini kamu.';
      } else if (errorMsg.contains('network') ||
          errorMsg.contains('connection')) {
        return '📶 Tidak ada koneksi internet.\n\nPastikan HP kamu terhubung ke internet.';
      } else {
        return '❌ Gagal mendapatkan saran.\n\nCoba lagi beberapa saat.';
      }
    }
  }

  // Helper: buat ringkasan transaksi untuk dikirim ke Gemini
  String _buatRingkasan(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return 'Belum ada transaksi.';

    // Hitung total
    int totalPemasukan = 0;
    int totalPengeluaran = 0;
    Map<String, int> pengeluaranPerKategori = {};

    for (var t in transactions) {
      if (t.tipe == 'pemasukan') {
        totalPemasukan += t.nominal;
      } else {
        totalPengeluaran += t.nominal;
        pengeluaranPerKategori[t.kategori] =
            (pengeluaranPerKategori[t.kategori] ?? 0) + t.nominal;
      }
    }

    // Format ringkasan
    String ringkasan =
        '''
Total Pemasukan  : ${_formatRupiah.format(totalPemasukan)}
Total Pengeluaran: ${_formatRupiah.format(totalPengeluaran)}
Saldo            : ${_formatRupiah.format(totalPemasukan - totalPengeluaran)}
Jumlah Transaksi : ${transactions.length}

Pengeluaran per Kategori:
''';

    pengeluaranPerKategori.forEach((kategori, nominal) {
      ringkasan += '- $kategori: ${_formatRupiah.format(nominal)}\n';
    });

    return ringkasan;
  }
}
