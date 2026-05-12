import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../services/transaction_service.dart';
import '../utils/currency_formatter.dart';
import '../widgets/transaction_card.dart';
import '../widgets/wallet_card.dart';
import 'tambah_transaksi_screen.dart';
import 'semua_transaksi_screen.dart';

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

  /// Semua transaksi mentah yang sudah diambil dari Supabase
  List<TransactionModel> _allTransactions = [];

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
        _allTransactions = semua;
        _transaksiFiltered = _filterByPeriode(semua, _periodeAktif);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
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
  int get _totalSaldo => _daftarDompet.fold(0, (sum, w) => sum + w.saldo);

  // ─── Logic: Grouping Transaksi per Tanggal ───────────────────────────────────

  /// Transaksi terbaru yang ditampilkan di dashboard (maksimal 3 item)
  List<TransactionModel> get _latestTransaksi {
    final latest = List<TransactionModel>.from(_transaksiFiltered);
    latest.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return latest.take(3).toList();
  }

  int _walletDeltaFromTransaction(TransactionModel transaction) {
    return transaction.tipe == 'pemasukan'
        ? transaction.nominal
        : -transaction.nominal;
  }

  void _updateDefaultWalletBalance(int delta) {
    final defaultIndex = _daftarDompet.indexWhere((wallet) => wallet.id == '1');
    if (defaultIndex < 0) return;

    final wallet = _daftarDompet[defaultIndex];
    final updatedWallet = WalletModel(
      id: wallet.id,
      nama: wallet.nama,
      tipe: wallet.tipe,
      saldo: wallet.saldo + delta,
      namaBank: wallet.namaBank,
      warna: wallet.warna,
    );

    setState(() {
      _daftarDompet[defaultIndex] = updatedWallet;
    });
  }

  /// Terapkan perubahan saldo pada dompet default ketika menambah transaksi baru.
  void _applyTransactionToWallet(TransactionModel transaction) {
    _updateDefaultWalletBalance(_walletDeltaFromTransaction(transaction));
  }

  void _reverseTransactionOnWallet(TransactionModel transaction) {
    _updateDefaultWalletBalance(-_walletDeltaFromTransaction(transaction));
  }

  void _applyEditedTransactionToWallet(
    TransactionModel oldTransaction,
    TransactionModel newTransaction,
  ) {
    _reverseTransactionOnWallet(oldTransaction);
    _applyTransactionToWallet(newTransaction);
  }

  /// Buka layar tambah transaksi dan reload data saat transaksi baru disimpan.
  Future<void> _openTambahTransaksi() async {
    final newTransaction = await Navigator.push<TransactionModel?>(
      context,
      MaterialPageRoute(
        builder: (_) => const TambahTransaksiScreen(),
        fullscreenDialog: true,
      ),
    );

    if (newTransaction != null) {
      _applyTransactionToWallet(newTransaction);
      _loadData();
    }
  }

  void _openAllTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SemuaTransaksiScreen(
          initialTransactions: _allTransactions,
          onTransactionDeleted: _reverseTransactionOnWallet,
        ),
      ),
    );
  }

  Future<void> _openEditTransaction(TransactionModel transaction) async {
    final updated = await Navigator.push<TransactionModel?>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahTransaksiScreen(transaction: transaction),
        fullscreenDialog: true,
      ),
    );

    if (updated != null) {
      _applyEditedTransactionToWallet(transaction, updated);
      await _loadData();
    }
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF12141E),
          title: const Text(
            'Hapus transaksi',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Yakin ingin menghapus transaksi "${transaction.judul}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _transactionService.delete(transaction.id!);
      _reverseTransactionOnWallet(transaction);
      if (!mounted) return;
      await _loadData();
      messenger.showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil dihapus.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus transaksi: $e')),
      );
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141E), // latar belakang gelap utama
      floatingActionButton: FloatingActionButton(
        onPressed: _openTambahTransaksi,
        backgroundColor: const Color(0xFF4A90D9),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: RefreshIndicator(
          // Pull-to-refresh untuk memuat ulang data
          onRefresh: _loadData,
          color: const Color(0xFF4A90D9),
          backgroundColor: const Color(0xFF1E2130),
          child: CustomScrollView(
            slivers: [
              // ── Filter Periode ─────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildPeriodeFilter()),

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
              SliverToBoxAdapter(child: _buildDompetList()),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Section Riwayat Transaksi ──────────────────────────────────
              SliverToBoxAdapter(child: _buildTransaksiHeader()),

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
                SliverToBoxAdapter(child: _buildTransaksiList()),

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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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
            _saldoTerlihat ? CurrencyFormatter.format(_totalSaldo) : '••••••••',
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
  Widget _buildSectionHeader({required String title, VoidCallback? onMore}) {
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
            'Riwayat 3 Transaksi Terbaru',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: _openAllTransactions,
            child: const Text(
              'Lihat Semua',
              style: TextStyle(color: Color(0xFF4A90D9), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun daftar 3 transaksi terbaru di dashboard
  Widget _buildTransaksiList() {
    final latest = _latestTransaksi;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...latest.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TransactionCard(
                      transaction: t,
                      onTap: () => _openEditTransaction(t),
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: const Color(0xFF1E2130),
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openEditTransaction(t);
                      } else if (value == 'delete') {
                        _deleteTransaction(t);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (latest.isNotEmpty && _transaksiFiltered.length > 3) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _openAllTransactions,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'Lihat semua transaksi',
                    style: TextStyle(
                      color: Color(0xFF4A90D9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF4A90D9),
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
          if (latest.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Belum ada transaksi terbaru. Tekan tombol + untuk menambahkan.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ),
        ],
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
