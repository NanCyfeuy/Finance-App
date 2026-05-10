import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../services/transaction_service.dart';
import '../utils/currency_formatter.dart';
import '../widgets/transaction_card.dart';
import '../widgets/wallet_card.dart';

/// Enum untuk filter periode tampilan ringkasan keuangan
enum PeriodeFilter { hari, minggu, bulan, tahun, semua }

/// Halaman Dashboard utama aplikasi keuangan.
/// Menampilkan:
/// - Filter periode (Hari / Minggu / Bulan / Tahun / Semua)
/// - Card total saldo, pemasukan, dan pengeluaran
/// - Daftar dompet yang bisa di-scroll horizontal
/// - Riwayat transaksi terakhir dikelompokkan per tanggal
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ─── Service & State ────────────────────────────────────────────────────────

  final TransactionService _transactionService = TransactionService();

  /// Filter periode yang sedang aktif
  PeriodeFilter _periodeAktif = PeriodeFilter.bulan;

  /// Semua transaksi yang sudah difilter sesuai periode
  List<TransactionModel> _transaksiFiltered = [];

  /// Status loading data dari Supabase
  bool _isLoading = true;

  /// Apakah saldo ditampilkan atau disembunyikan
  bool _saldoTerlihat = true;

  // ─── Data Dummy Dompet ───────────────────────────────────────────────────────
  // TODO: Ganti dengan data dari Supabase setelah tabel wallet dibuat

  final List<WalletModel> _daftarDompet = [
    WalletModel(
      id: '1',
      nama: 'Cash',
      tipe: 'CASH',
      saldo: 2000,
      warna: const Color(0xFF2A2D3E),
    ),
    WalletModel(
      id: '2',
      nama: 'BRI',
      tipe: 'BANK',
      saldo: 554806,
      namaBank: 'BRI',
      warna: const Color(0xFF1A3A5C),
    ),
    WalletModel(
      id: '3',
      nama: 'GoPay',
      tipe: 'E-WALLET',
      saldo: 125000,
      warna: const Color(0xFF1A3A2A),
    ),
    WalletModel(
      id: '4',
      nama: 'OVO',
      tipe: 'E-WALLET',
      saldo: 75000,
      warna: const Color(0xFF3A1A5C),
    ),
  ];

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ─── Logic: Load & Filter Data ───────────────────────────────────────────────

  /// Memuat semua transaksi dari Supabase lalu menerapkan filter periode
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final semua = await _transactionService.getAll();
      setState(() {
        _transaksiFiltered = _filterByPeriode(semua, _periodeAktif);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    }
  }

  /// Memfilter daftar transaksi berdasarkan periode yang dipilih
  List<TransactionModel> _filterByPeriode(
    List<TransactionModel> semua,
    PeriodeFilter periode,
  ) {
    final now = DateTime.now();
    switch (periode) {
      case PeriodeFilter.hari:
        // Hanya transaksi hari ini
        return semua.where((t) {
          return t.tanggal.year == now.year &&
              t.tanggal.month == now.month &&
              t.tanggal.day == now.day;
        }).toList();

      case PeriodeFilter.minggu:
        // Transaksi 7 hari terakhir
        final weekAgo = now.subtract(const Duration(days: 7));
        return semua.where((t) => t.tanggal.isAfter(weekAgo)).toList();

      case PeriodeFilter.bulan:
        // Transaksi bulan ini
        return semua.where((t) {
          return t.tanggal.year == now.year && t.tanggal.month == now.month;
        }).toList();

      case PeriodeFilter.tahun:
        // Transaksi tahun ini
        return semua.where((t) => t.tanggal.year == now.year).toList();

      case PeriodeFilter.semua:
        return semua;
    }
  }

  /// Dipanggil saat pengguna mengganti filter periode
  void _onPeriodeChanged(PeriodeFilter periode) async {
    setState(() {
      _periodeAktif = periode;
      _isLoading = true;
    });
    try {
      final semua = await _transactionService.getAll();
      setState(() {
        _transaksiFiltered = _filterByPeriode(semua, periode);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ─── Logic: Kalkulasi Ringkasan ──────────────────────────────────────────────

  /// Menghitung total pemasukan dari transaksi yang sudah difilter
  int get _totalPemasukan => _transaksiFiltered
      .where((t) => t.tipe == 'pemasukan')
      .fold(0, (sum, t) => sum + t.nominal);

  /// Menghitung total pengeluaran dari transaksi yang sudah difilter
  int get _totalPengeluaran => _transaksiFiltered
      .where((t) => t.tipe == 'pengeluaran')
      .fold(0, (sum, t) => sum + t.nominal);

  /// Total saldo keseluruhan dari semua dompet
  int get _totalSaldo =>
      _daftarDompet.fold(0, (sum, w) => sum + w.saldo);

  // ─── Logic: Grouping Transaksi per Tanggal ───────────────────────────────────

  /// Mengelompokkan transaksi berdasarkan tanggal (yyyy-MM-dd)
  /// dan mengurutkan dari tanggal terbaru
  Map<String, List<TransactionModel>> get _transaksiPerTanggal {
    final Map<String, List<TransactionModel>> grouped = {};
    for (final t in _transaksiFiltered) {
      // Key berupa string tanggal untuk pengelompokan
      final key = DateFormat('yyyy-MM-dd').format(t.tanggal);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    // Urutkan key dari terbaru ke terlama
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return {for (final k in sortedKeys) k: grouped[k]!};
  }

  /// Format tanggal untuk header grup transaksi
  /// Contoh: "Sabtu, 9 Mei 2026"
  String _formatTanggalHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  /// Menghitung total nominal bersih per tanggal (pemasukan - pengeluaran)
  int _totalPerTanggal(List<TransactionModel> transaksi) {
    int total = 0;
    for (final t in transaksi) {
      if (t.tipe == 'pemasukan') {
        total += t.nominal;
      } else {
        total -= t.nominal;
      }
    }
    return total;
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141E), // latar belakang gelap utama
      body: SafeArea(
        child: RefreshIndicator(
          // Pull-to-refresh untuk memuat ulang data
          onRefresh: _loadData,
          color: const Color(0xFF4A90D9),
          backgroundColor: const Color(0xFF1E2130),
          child: CustomScrollView(
            slivers: [
              // ── Filter Periode ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildPeriodeFilter(),
              ),

              // ── Card Ringkasan Saldo ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSaldoCard(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Section Dompet Saya ────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  title: 'Dompet Saya',
                  onMore: () {
                    // TODO: Navigasi ke halaman kelola dompet
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: _buildDompetList(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Section Riwayat Transaksi ──────────────────────────────────
              SliverToBoxAdapter(
                child: _buildTransaksiHeader(),
              ),

              // Konten transaksi: loading / kosong / daftar
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4A90D9),
                      ),
                    ),
                  ),
                )
              else if (_transaksiFiltered.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState())
              else
                SliverToBoxAdapter(
                  child: _buildTransaksiList(),
                ),

              // Padding bawah agar konten tidak tertutup navbar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Widget Builders ─────────────────────────────────────────────────────────

  /// Membangun tab filter periode di bagian atas layar
  Widget _buildPeriodeFilter() {
    final labels = {
      PeriodeFilter.hari: 'Hari',
      PeriodeFilter.minggu: 'Minggu',
      PeriodeFilter.bulan: 'Bulan',
      PeriodeFilter.tahun: 'Tahun',
      PeriodeFilter.semua: 'Semua',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: labels.entries.map((entry) {
          final isActive = _periodeAktif == entry.key;
          return GestureDetector(
            onTap: () => _onPeriodeChanged(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                // Tab aktif menggunakan warna putih, tidak aktif transparan
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF12141E) // teks gelap di tab aktif
                      : Colors.white54,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Membangun card utama yang menampilkan total saldo, pemasukan, pengeluaran
  Widget _buildSaldoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Gradient dari biru tua ke hijau teal, mirip referensi desain
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A6C), Color(0xFF0D6E6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Label "Total Saldo" dengan tombol sembunyikan
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Total Saldo (IDR)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _saldoTerlihat = !_saldoTerlihat),
                child: Icon(
                  _saldoTerlihat
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white54,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Nominal total saldo (bisa disembunyikan)
          Text(
            _saldoTerlihat
                ? CurrencyFormatter.format(_totalSaldo)
                : '••••••••',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Baris pemasukan dan pengeluaran
          Row(
            children: [
              // Pemasukan
              Expanded(
                child: _buildSaldoItem(
                  label: 'Pemasukan',
                  amount: _totalPemasukan,
                  icon: Icons.arrow_downward_rounded,
                  iconColor: const Color(0xFF2ECC71),
                  isVisible: _saldoTerlihat,
                ),
              ),
              const SizedBox(width: 12),
              // Pengeluaran
              Expanded(
                child: _buildSaldoItem(
                  label: 'Pengeluaran',
                  amount: _totalPengeluaran,
                  icon: Icons.arrow_upward_rounded,
                  iconColor: const Color(0xFFE74C3C),
                  isVisible: _saldoTerlihat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget item pemasukan / pengeluaran di dalam card saldo
  Widget _buildSaldoItem({
    required String label,
    required int amount,
    required IconData icon,
    required Color iconColor,
    required bool isVisible,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Ikon arah (naik/turun)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isVisible ? CurrencyFormatter.format(amount) : '••••',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun header section dengan judul dan tombol titik tiga
  Widget _buildSectionHeader({
    required String title,
    VoidCallback? onMore,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: const Icon(
                Icons.more_vert,
                color: Colors.white54,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  /// Membangun daftar dompet yang bisa di-scroll horizontal
  Widget _buildDompetList() {
    return SizedBox(
      height: 130, // tinggi kartu dompet
      child: ListView.builder(
        // Scroll horizontal ke kiri dan kanan
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: _daftarDompet.length,
        itemBuilder: (context, index) {
          return WalletCard(
            wallet: _daftarDompet[index],
            onTap: () {
              // TODO: Navigasi ke detail dompet
            },
          );
        },
      ),
    );
  }

  /// Membangun header section riwayat transaksi dengan tombol "Lihat Semua"
  Widget _buildTransaksiHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Transaksi Terakhir',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () {
              // TODO: Navigasi ke halaman semua transaksi
            },
            child: const Text(
              'Lihat Semua',
              style: TextStyle(
                color: Color(0xFF4A90D9),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun daftar transaksi yang dikelompokkan per tanggal
  Widget _buildTransaksiList() {
    final grouped = _transaksiPerTanggal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: grouped.entries.map((entry) {
          final dateKey = entry.key;
          final transaksi = entry.value;
          final totalHari = _totalPerTanggal(transaksi);
          final isPositif = totalHari >= 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Header tanggal dengan total bersih hari itu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTanggalHeader(dateKey),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    // Tampilkan tanda + atau - di depan total harian
                    '${isPositif ? '+' : ''}${CurrencyFormatter.format(totalHari.abs())}',
                    style: TextStyle(
                      color: isPositif
                          ? const Color(0xFF2ECC71)
                          : const Color(0xFFE74C3C),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Daftar transaksi untuk tanggal ini
              ...transaksi.map(
                (t) => TransactionCard(
                  transaction: t,
                  onTap: () {
                    // TODO: Navigasi ke detail transaksi
                  },
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Tampilan kosong ketika tidak ada transaksi pada periode yang dipilih
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada transaksi',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ketuk tombol + untuk menambah transaksi',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
