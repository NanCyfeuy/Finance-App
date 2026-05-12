import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../screens/tambah_transaksi_screen.dart';
import '../services/transaction_service.dart';
import '../utils/currency_formatter.dart';
import '../widgets/transaction_card.dart';

class SemuaTransaksiScreen extends StatelessWidget {
  const SemuaTransaksiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = TransactionProviderScope.of(context);
    final walletProvider = WalletProviderScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF12141E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12141E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Semua Transaksi',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: () => txProvider.loadFromSupabase(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: txProvider.loadFromSupabase,
        color: const Color(0xFF4A90D9),
        backgroundColor: const Color(0xFF1E2130),
        child: _buildBody(context, txProvider, walletProvider),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TransactionProvider txProvider,
      WalletProvider walletProvider) {
    if (txProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF4A90D9)),
            SizedBox(height: 16),
            Text('Memuat transaksi...',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }

    if (txProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text('Gagal memuat:\n${txProvider.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: txProvider.loadFromSupabase,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90D9)),
              ),
            ],
          ),
        ),
      );
    }

    final transactions = txProvider.transactions;

    if (transactions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.white.withValues(alpha: 0.15)),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('Belum ada transaksi.',
                style: TextStyle(color: Colors.white38, fontSize: 15)),
          ),
        ],
      );
    }

    // Group per tanggal
    final grouped = <DateTime, List<TransactionModel>>{};
    for (final t in transactions) {
      final key = DateTime(t.tanggal.year, t.tanggal.month, t.tanggal.day);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: dates.length,
      itemBuilder: (_, i) {
        final date = dates[i];
        final items = grouped[date]!;
        final totalHari = items.fold<int>(0, (sum, t) =>
            t.tipe == 'pengeluaran' ? sum - t.nominal : sum + t.nominal);
        final isPositif = totalHari >= 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatHeader(date),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(
                    CurrencyFormatter.formatWithSign(
                        totalHari.abs(),
                        isPositif ? 'pemasukan' : 'pengeluaran'),
                    style: TextStyle(
                      color: isPositif
                          ? const Color(0xFF2ECC71)
                          : const Color(0xFFE74C3C),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            ...items.map((t) {
              final walletName = t.walletId != null
                  ? walletProvider.dompet
                      .where((w) => w.id == t.walletId)
                      .map((w) => w.nama)
                      .firstOrNull
                  : null;
              return TransactionCard(
                transaction: t,
                walletName: walletName,
                onTap: () => _openEdit(context, t),
                onMenuSelected: (v) {
                  if (v == 'edit') _openEdit(context, t);
                  if (v == 'delete') _delete(context, t);
                },
              );
            }),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  Future<void> _openEdit(BuildContext context, TransactionModel t) async {
    await Navigator.push<TransactionModel?>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahTransaksiScreen(transaction: t),
        fullscreenDialog: true,
      ),
    );
    // Realtime update otomatis
  }

  Future<void> _delete(BuildContext context, TransactionModel t) async {
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
      await TransactionService().delete(t.id!);
      messenger.showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dihapus.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  String _formatHeader(DateTime date) {
    const hari = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
    const bulan = ['Jan','Feb','Mar','Apr','Mei','Jun',
                   'Jul','Agu','Sep','Okt','Nov','Des'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return 'Hari Ini, ${date.day} ${bulan[date.month-1]}';
    if (date == yesterday) return 'Kemarin, ${date.day} ${bulan[date.month-1]}';
    return '${hari[date.weekday-1]}, ${date.day} ${bulan[date.month-1]} ${date.year}';
  }
}
