import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class AnalisisScreen extends StatefulWidget {
  const AnalisisScreen({super.key});

  @override
  State<AnalisisScreen> createState() => _AnalisisScreenState();
}

class _AnalisisScreenState extends State<AnalisisScreen> {
  // Pakai TransactionService dari Anggota 4 — tidak perlu buat ulang
  final TransactionService _service = TransactionService();

  bool _isLoading = true;
  List<TransactionModel> _semuaTransaksi = [];

  // ── URL gambar grafik dari QuickChart.io ──────────────────────────────────
  String _pieChartUrl = '';
  String _barChartUrl = '';

  // ── Ringkasan angka ───────────────────────────────────────────────────────
  int _totalPemasukan = 0;
  int _totalPengeluaran = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Ambil data & olah semuanya di sini ──────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Pakai getAll() dari TransactionService milik Anggota 4
      final data = await _service.getAll();

      // Hitung ringkasan
      int pemasukan = 0;
      int pengeluaran = 0;
      for (var t in data) {
        if (t.tipe == 'pemasukan') {
          pemasukan += t.nominal;
        } else {
          pengeluaran += t.nominal;
        }
      }

      setState(() {
        _semuaTransaksi = data;
        _totalPemasukan = pemasukan;
        _totalPengeluaran = pengeluaran;
        _pieChartUrl = _buildPieChartUrl(data);
        _barChartUrl = _buildBarChartUrl(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ── Buat URL Pie Chart (pengeluaran per kategori) ─────────────────────
  String _buildPieChartUrl(List<TransactionModel> data) {
    // Filter hanya pengeluaran
    final pengeluaran = data.where((t) => t.tipe == 'pengeluaran').toList();
    if (pengeluaran.isEmpty) return '';

    // Hitung total per kategori menggunakan field .kategori dari TransactionModel
    final Map<String, int> perKategori = {};
    for (var t in pengeluaran) {
      perKategori[t.kategori] = (perKategori[t.kategori] ?? 0) + t.nominal;
    }

    final labels = perKategori.keys.toList();
    final values = perKategori.values.toList();

    final config = {
      "type": "pie",
      "data": {
        "labels": labels,
        "datasets": [
          {
            "data": values,
            "backgroundColor": [
              "#4A90D9",
              "#E74C3C",
              "#2ECC71",
              "#F39C12",
              "#9B59B6",
              "#1ABC9C",
              "#E67E22",
              "#3498DB",
            ],
          },
        ],
      },
      "options": {
        "plugins": {
          "legend": {"position": "bottom"},
          "title": {
            "display": true,
            "text": "Pengeluaran per Kategori",
            "color": "#FFFFFF",
            "font": {"size": 14},
          },
        },
      },
    };

    final encoded = Uri.encodeComponent(jsonEncode(config));
    return 'https://quickchart.io/chart?c=$encoded&w=400&h=300&backgroundColor=rgb(18,20,30)';
  }

  // ── Buat URL Bar Chart (pemasukan vs pengeluaran per bulan) ───────────
  String _buildBarChartUrl(List<TransactionModel> data) {
    if (data.isEmpty) return '';

    // Kelompokkan berdasarkan bulan menggunakan field .tanggal (DateTime)
    final Map<String, int> pemasukanPerBulan = {};
    final Map<String, int> pengeluaranPerBulan = {};

    for (var t in data) {
      // Format bulan jadi "Jan 2024", "Feb 2024", dst
      final bulan = _formatBulan(t.tanggal);

      if (t.tipe == 'pemasukan') {
        pemasukanPerBulan[bulan] = (pemasukanPerBulan[bulan] ?? 0) + t.nominal;
      } else {
        pengeluaranPerBulan[bulan] =
            (pengeluaranPerBulan[bulan] ?? 0) + t.nominal;
      }
    }

    // Gabungkan semua bulan, urutkan
    final semuaBulan = {
      ...pemasukanPerBulan.keys,
      ...pengeluaranPerBulan.keys,
    }.toList()..sort();

    if (semuaBulan.isEmpty) return '';

    final config = {
      "type": "bar",
      "data": {
        "labels": semuaBulan,
        "datasets": [
          {
            "label": "Pemasukan",
            "data": semuaBulan.map((b) => pemasukanPerBulan[b] ?? 0).toList(),
            "backgroundColor": "#4A90D9",
          },
          {
            "label": "Pengeluaran",
            "data": semuaBulan.map((b) => pengeluaranPerBulan[b] ?? 0).toList(),
            "backgroundColor": "#E74C3C",
          },
        ],
      },
      "options": {
        "plugins": {
          "legend": {"position": "top"},
          "title": {
            "display": true,
            "text": "Pemasukan vs Pengeluaran",
            "color": "#FFFFFF",
            "font": {"size": 14},
          },
        },
        "scales": {
          "x": {
            "ticks": {"color": "#AAAAAA"},
          },
          "y": {
            "ticks": {"color": "#AAAAAA"},
          },
        },
      },
    };

    final encoded = Uri.encodeComponent(jsonEncode(config));
    return 'https://quickchart.io/chart?c=$encoded&w=400&h=300&backgroundColor=rgb(18,20,30)';
  }

  // ── Helper: format DateTime jadi "Jan 2024" ────────────────────────────
  String _formatBulan(DateTime dt) {
    const namaBulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${namaBulan[dt.month - 1]} ${dt.year}';
  }

  // ── Helper: format angka jadi "Rp 1.000.000" ──────────────────────────
  String _formatRupiah(int nominal) {
    final str = nominal.toString();
    final buffer = StringBuffer('Rp ');
    int counter = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (counter > 0 && counter % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      counter++;
    }
    return buffer.toString().split('').reversed.join('');
  }

  // ── Tampilan UI ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141E), // Cocok dengan tema dark app
      appBar: AppBar(
        backgroundColor: const Color(0xFF12141E),
        title: const Text(
          'Analisis Keuangan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // Tombol refresh manual di kanan atas
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A90D9)),
            )
          : _semuaTransaksi.isEmpty
          ? _buildKosong()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF4A90D9),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Kartu ringkasan angka ──
                    _buildKartuRingkasan(),
                    const SizedBox(height: 24),

                    // ── Pie Chart ──
                    _buildSectionTitle('Pengeluaran per Kategori'),
                    const SizedBox(height: 12),
                    _buildGrafik(_pieChartUrl),
                    const SizedBox(height: 24),

                    // ── Bar Chart ──
                    _buildSectionTitle('Pemasukan vs Pengeluaran'),
                    const SizedBox(height: 12),
                    _buildGrafik(_barChartUrl),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Widget: kartu ringkasan pemasukan & pengeluaran ───────────────────
  Widget _buildKartuRingkasan() {
    return Row(
      children: [
        Expanded(
          child: _buildKartuAngka(
            label: 'Total Pemasukan',
            nominal: _totalPemasukan,
            warna: const Color(0xFF2ECC71),
            ikon: Icons.arrow_downward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKartuAngka(
            label: 'Total Pengeluaran',
            nominal: _totalPengeluaran,
            warna: const Color(0xFFE74C3C),
            ikon: Icons.arrow_upward,
          ),
        ),
      ],
    );
  }

  Widget _buildKartuAngka({
    required String label,
    required int nominal,
    required Color warna,
    required IconData ikon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warna.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, color: warna, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatRupiah(nominal),
            style: TextStyle(
              color: warna,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget: judul section ─────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ── Widget: tampilkan gambar grafik dari QuickChart.io ────────────────
  Widget _buildGrafik(String url) {
    if (url.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2030),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Belum ada data untuk ditampilkan',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        // Tampilkan loading saat gambar belum selesai dimuat
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2030),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A90D9)),
            ),
          );
        },
        // Tampilkan pesan kalau gambar gagal dimuat
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2030),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Grafik gagal dimuat\n(cek koneksi internet)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Widget: tampilan kalau data kosong ────────────────────────────────
  Widget _buildKosong() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Belum ada transaksi',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambah transaksi dulu\nlalu kembali ke halaman ini',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
