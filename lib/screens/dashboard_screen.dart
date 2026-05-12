import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../providers/wallet_provider.dart';
import '../services/transaction_service.dart';
import '../utils/currency_formatter.dart';
import '../widgets/transaction_card.dart';
import '../widgets/wallet_card.dart';
import 'tambah_transaksi_screen.dart';
import 'semua_transaksi_screen.dart';

enum PeriodeFilter { hari, minggu, bulan, tahun, semua }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TransactionService _transactionService = TransactionService();

  PeriodeFilter _periodeAktif = PeriodeFilter.bulan;
  List<TransactionModel> _transaksiFiltered = [];
  bool _isLoading = true;
  bool _saldoTerlihat = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

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

  List<TransactionModel> _filterByPeriode(
    List<TransactionModel> semua,
    PeriodeFilter periode,
  ) {
    final now = DateTime.now();
    switch (periode) {
      case PeriodeFilter.hari:
        return semua.where((t) =>
          t.tanggal.year == now.year &&
          t.tanggal.month == now.month &&
          t.tanggal.day == now.day).toList();
      case PeriodeFilter.minggu:
        final weekAgo = now.subtract(const Duration(days: 7));
        return semua.where((t) => t.tanggal.isAfter(weekAgo)).toList();
      case PeriodeFilter.bulan:
        return semua.where((t) =>
          t.tanggal.year == now.year &&
          t.tanggal.month == now.month).toList();
      case PeriodeFilter.tahun:
        return semua.where((t) => t.tanggal.year == now.year).toList();
      case PeriodeFilter.semua:
        return semua;
    }
  }

  void _onPeriodeChanged(PeriodeFilter periode) async {
    setState(() { _periodeAktif = periode; _isLoading = true; });
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

  int get _totalPemasukan => _transaksiFiltered
      .where((t) => t.tipe == 'pemasukan')
      .fold(0, (s, t) => s + t.nominal);

  int get _totalPengeluaran => _transaksiFiltered
      .where((t) => t.tipe == 'pengeluaran')
      .fold(0, (s, t) => s + t.nominal);

  int get _totalSaldo => WalletProviderScope.of(context).totalSaldo;

  /// Transaksi minggu ini (7 hari terakhir), diurutkan terbaru
  List<TransactionModel> get _transaksiMingguIni {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final list = _transaksiFiltered
        .where((t) => t.tanggal.isAfter(weekAgo))
        .toList();
    list.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return list;
  }

  /// Group transaksi per tanggal (key: DateTime tanpa jam)
  Map<DateTime, List<TransactionModel>> get _transaksiGrouped {
    final grouped = <DateTime, List<TransactionModel>>{};
    for (final t in _transaksiMingguIni) {
      final key = DateTime(t.tanggal.year, t.tanggal.month, t.tanggal.day);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return grouped;
  }

  void _openAllTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SemuaTransaksiScreen()),
    );
  }

  Future<void> _openEditTransaction(TransactionModel t) async {
    final updated = await Navigator.push<TransactionModel?>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahTransaksiScreen(transaction: t),
        fullscreenDialog: true,
      ),
    );
    if (updated != null) await _loadData();
  }

  Future<void> _deleteTransaction(TransactionModel t) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2130),
        title: const Text('Hapus Transaksi',
            style: TextStyle(color: Colors.white)),
        content: Text('Yakin hapus "${t.judul}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _transactionService.delete(t.id!);
      if (!mounted) return;
      await _loadData();
      messenger.showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dihapus.')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141E),
      body: SafeArea(
        bottom: false, // biarkan konten extend ke bawah navbar floating
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF4A90D9),
          backgroundColor: const Color(0xFF1E2130),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header Greeting ──────────────────────────────────────────
              SliverToBoxAdapter(child: _buildHeader()),

              // ── Filter Periode ───────────────────────────────────────────
              SliverToBoxAdapter(child: _buildPeriodeFilter()),

              // ── Card Saldo Utama ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSaldoCard(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Section Dompet ───────────────────────────────────────────
              SliverToBoxAdapter(child: _buildSectionTitle('Dompet Saya')),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(child: _buildDompetList()),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Section Transaksi Terbaru ────────────────────────────────
              SliverToBoxAdapter(child: _buildTransaksiHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF4A90D9)),
                    ),
                  ),
                )
              else if (_transaksiMingguIni.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState())
              else
                SliverToBoxAdapter(child: _buildTransaksiList()),

              // Padding bawah adaptif: navbar (64) + padding navbar (24) + system bar
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 100 + MediaQuery.of(context).padding.bottom,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Widget Builders ──────────────────────────────────────────────────────

  Widget _buildHeader() {
    final now = DateTime.now();
    final hour = now.hour;
    final String greeting = hour < 12
        ? 'Selamat Pagi'
        : hour < 15
            ? 'Selamat Siang'
            : hour < 18
                ? 'Selamat Sore'
                : 'Selamat Malam';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Ringkasan Keuangan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Tombol refresh manual
          GestureDetector(
            onTap: _loadData,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2130),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: Colors.white54, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodeFilter() {
    final labels = {
      PeriodeFilter.hari: 'Hari',
      PeriodeFilter.minggu: 'Minggu',
      PeriodeFilter.bulan: 'Bulan',
      PeriodeFilter.tahun: 'Tahun',
      PeriodeFilter.semua: 'Semua',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2130),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: labels.entries.map((entry) {
            final isActive = _periodeAktif == entry.key;
            return Expanded(
              child: GestureDetector(
                onTap: () => _onPeriodeChanged(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    entry.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF12141E)
                          : Colors.white54,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSaldoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A6C), Color(0xFF0D6E6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Total saldo
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
                onTap: () =>
                    setState(() => _saldoTerlihat = !_saldoTerlihat),
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
          const SizedBox(height: 6),
          Text(
            _saldoTerlihat
                ? CurrencyFormatter.format(_totalSaldo)
                : '••••••••',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Pemasukan & Pengeluaran
          Row(
            children: [
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
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 13),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDompetList() {
    final dompet = WalletProviderScope.of(context).dompet;
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        itemCount: dompet.length,
        itemBuilder: (_, i) => WalletCard(wallet: dompet[i]),
      ),
    );
  }

  Widget _buildTransaksiHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Transaksi Terbaru',
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
              style: TextStyle(
                color: Color(0xFF4A90D9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransaksiList() {
    final provider = WalletProviderScope.of(context);
    final grouped = _transaksiGrouped;
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedDates.map((date) {
          final items = grouped[date]!;
          final totalHari = items.fold<int>(0, (sum, t) =>
              t.tipe == 'pengeluaran' ? sum - t.nominal : sum + t.nominal);
          final isPositif = totalHari >= 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header tanggal ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTanggalHeader(date),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatWithSign(
                          totalHari.abs(),
                          isPositif ? 'pemasukan' : 'pengeluaran'),
                      style: TextStyle(
                        color: isPositif
                            ? const Color(0xFF2ECC71)
                            : const Color(0xFFE74C3C),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // ── Daftar transaksi hari itu ──────────────────────────────
              ...items.map((t) {
                final walletName = t.walletId != null
                    ? provider.dompet
                        .where((w) => w.id == t.walletId)
                        .map((w) => w.nama)
                        .firstOrNull
                    : null;
                return TransactionCard(
                  transaction: t,
                  walletName: walletName,
                  onTap: () => _openEditTransaction(t),
                  onMenuSelected: (v) {
                    if (v == 'edit') _openEditTransaction(t);
                    if (v == 'delete') _deleteTransaction(t);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Format tanggal untuk header grup: "Selasa, 12 Mei 2026"
  String _formatTanggalHeader(DateTime date) {
    const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                   'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'Hari Ini, ${date.day} ${bulan[date.month - 1]}';
    if (date == yesterday) return 'Kemarin, ${date.day} ${bulan[date.month - 1]}';
    return '${hari[date.weekday - 1]}, ${date.day} ${bulan[date.month - 1]} ${date.year}';
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 52,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada transaksi',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ketuk tombol + untuk menambah transaksi',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
