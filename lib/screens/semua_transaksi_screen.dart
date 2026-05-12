import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../screens/tambah_transaksi_screen.dart';
import '../services/transaction_service.dart';
import '../widgets/transaction_card.dart';

class SemuaTransaksiScreen extends StatefulWidget {
  const SemuaTransaksiScreen({super.key});

  @override
  State<SemuaTransaksiScreen> createState() => _SemuaTransaksiScreenState();
}

class _SemuaTransaksiScreenState extends State<SemuaTransaksiScreen> {
  final TransactionService _transactionService = TransactionService();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final data = await _transactionService.getAll();
      data.sort((a, b) => b.tanggal.compareTo(a.tanggal));
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal memuat transaksi: $e')),
      );
    }
  }

  Future<void> _openEdit(TransactionModel transaction) async {
    final updated = await Navigator.push<TransactionModel?>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahTransaksiScreen(transaction: transaction),
        fullscreenDialog: true,
      ),
    );

    if (updated != null) {
      await _loadTransactions();
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
      if (!mounted) return;
      await _loadTransactions();
      messenger.showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil dihapus.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  Widget _buildTransactionRow(TransactionModel transaction) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TransactionCard(
              transaction: transaction,
              onTap: () => _openEdit(transaction),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            color: const Color(0xFF1E2130),
            icon: const Icon(Icons.more_vert, color: Colors.white54),
            onSelected: (value) {
              if (value == 'edit') {
                _openEdit(transaction);
              } else if (value == 'delete') {
                _deleteTransaction(transaction);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12141E),
        elevation: 0,
        title: const Text(
          'Semua Transaksi',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        color: const Color(0xFF4A90D9),
        backgroundColor: const Color(0xFF1E2130),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4A90D9)),
              )
            : _transactions.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 72,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Belum ada transaksi.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 16, bottom: 32),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];
                  return _buildTransactionRow(transaction);
                },
              ),
      ),
    );
  }
}
