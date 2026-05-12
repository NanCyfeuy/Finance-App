import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../providers/wallet_provider.dart';
import '../services/transaction_service.dart';
import '../utils/currency_formatter.dart';
import 'tambah_dompet_screen.dart';
import 'edit_dompet_screen.dart';

/// Halaman Dompet — menampilkan semua dompet dikelompokkan per tipe,
/// total saldo, dan tombol tambah dompet baru.
class DompetScreen extends StatefulWidget {
  const DompetScreen({super.key});

  @override
  State<DompetScreen> createState() => _DompetScreenState();
}

class _DompetScreenState extends State<DompetScreen> {
  final _transactionService = TransactionService();
  int _totalPemasukan = 0;
  int _totalPengeluaran = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final semua = await _transactionService.getAll();
      setState(() {
        _totalPemasukan = semua
            .where((t) => t.tipe == 'pemasukan')
            .fold(0, (s, t) => s + t.nominal);
        _totalPengeluaran = semua
            .where((t) => t.tipe == 'pengeluaran')
            .fold(0, (s, t) => s + t.nominal);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final provider = WalletProviderScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF12141E),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => _loadSummary(),
          color: const Color(0xFF4A90D9),
          backgroundColor: const Color(0xFF1E2130),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Dompet Saya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openTambahDompet(context, provider),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2130),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Card Total Saldo ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _TotalSaldoCard(
                    provider: provider,
                    totalPemasukan: _totalPemasukan,
                    totalPengeluaran: _totalPengeluaran,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Daftar Dompet per Grup ───────────────────────────────────
              SliverToBoxAdapter(
                child: _DompetList(provider: provider),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 160)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTambahDompet(
      BuildContext context, WalletProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    debugPrint('[DompetScreen] Opening TambahDompetScreen...');
    final result = await Navigator.push<WalletModel>(
      context,
      MaterialPageRoute(
          builder: (_) => const TambahDompetScreen(), fullscreenDialog: true),
    );
    debugPrint('[DompetScreen] Result from TambahDompetScreen: $result');
    if (result == null) {
      debugPrint('[DompetScreen] Result is null, user cancelled');
      return;
    }

    debugPrint('[DompetScreen] Calling provider.tambah with: ${result.nama}');
    try {
      await provider.tambah(result);
      debugPrint('[DompetScreen] tambah SUCCESS');
      messenger.showSnackBar(
        const SnackBar(content: Text('Dompet berhasil ditambahkan.')),
      );
    } catch (e) {
      debugPrint('[DompetScreen] tambah ERROR: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan dompet: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

// ─── Card Total Saldo ──────────────────────────────────────────────────────────

class _TotalSaldoCard extends StatelessWidget {
  final WalletProvider provider;
  final int totalPemasukan;
  final int totalPengeluaran;

  const _TotalSaldoCard({
    required this.provider,
    required this.totalPemasukan,
    required this.totalPengeluaran,
  });

  @override
  Widget build(BuildContext context) {
    final totalSaldo = provider.totalSaldo;

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
          // Label — tanpa ikon swap
          Text(
            'Total Saldo (IDR)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),

          // Nominal total
          Text(
            CurrencyFormatter.format(totalSaldo),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Pemasukan & Pengeluaran (ganti grid 4 kotak)
          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  label: 'Pemasukan',
                  value: CurrencyFormatter.format(totalPemasukan),
                  iconColor: const Color(0xFF2ECC71),
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoBox(
                  label: 'Pengeluaran',
                  value: CurrencyFormatter.format(totalPengeluaran),
                  iconColor: const Color(0xFFE74C3C),
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final Color iconColor;
  final IconData icon;

  const _InfoBox({
    required this.label,
    required this.value,
    required this.iconColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
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
                  value,
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
}

// ─── Daftar Dompet per Grup ────────────────────────────────────────────────────

class _DompetList extends StatelessWidget {
  final WalletProvider provider;
  const _DompetList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final dompet = provider.dompet;
    const grupOrder = ['CASH', 'BANK', 'E-WALLET'];
    const grupLabel = {
      'CASH': 'Tunai',
      'BANK': 'Akun Bank',
      'E-WALLET': 'E-Wallet',
    };

    final widgets = <Widget>[];

    for (final tipe in grupOrder) {
      final list = dompet.where((w) => w.tipe == tipe).toList();
      if (list.isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            grupLabel[tipe]!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      for (final wallet in list) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _DompetItem(
              wallet: wallet,
              onEdit: () => _openEditDompet(context, provider, wallet),
              onHapus: () => _konfirmasiHapus(context, provider, wallet),
            ),
          ),
        );
      }

      widgets.add(const SizedBox(height: 4));
    }

    if (widgets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Belum ada dompet.\nKetuk + untuk menambahkan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Future<void> _openEditDompet(
    BuildContext context,
    WalletProvider provider,
    WalletModel wallet,
  ) async {
    final updated = await Navigator.push<WalletModel>(
      context,
      MaterialPageRoute(
        builder: (_) => EditDompetScreen(wallet: wallet),
        fullscreenDialog: true,
      ),
    );
    if (updated != null) provider.edit(updated);
  }

  Future<void> _konfirmasiHapus(
    BuildContext context,
    WalletProvider provider,
    WalletModel wallet,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2130),
        title: const Text('Hapus Dompet',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Yakin ingin menghapus dompet "${wallet.nama}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) provider.hapus(wallet.id);
  }
}

// ─── Item Card Dompet ──────────────────────────────────────────────────────────

class _DompetItem extends StatelessWidget {
  final WalletModel wallet;
  final VoidCallback onEdit;
  final VoidCallback onHapus;

  const _DompetItem({
    required this.wallet,
    required this.onEdit,
    required this.onHapus,
  });

  IconData get _icon {
    switch (wallet.tipe) {
      case 'BANK':
        return Icons.account_balance;
      case 'E-WALLET':
        return Icons.phone_android;
      default:
        return Icons.wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit, // tap card → buka edit
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2130),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Ikon dompet
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: wallet.warna,
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: Colors.white70, size: 20),
            ),
            const SizedBox(width: 14),

            // Nama & tipe
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.nama,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${wallet.tipe} • IDR',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Saldo kanan — dengan padding yang cukup
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Saldo Saat Ini',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    CurrencyFormatter.format(wallet.saldo),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Menu titik 3
            PopupMenuButton<String>(
              color: const Color(0xFF2A2D3E),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert,
                  color: Colors.white38, size: 18),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'hapus') onHapus();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit',
                      style: TextStyle(color: Colors.white)),
                ),
                PopupMenuItem(
                  value: 'hapus',
                  child: Text('Hapus',
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
