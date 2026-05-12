import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';

/// Widget untuk menampilkan satu item transaksi.
/// Mendukung tampilan nama dompet di bawah ikon kategori.
class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final void Function(String value)? onMenuSelected;

  /// Nama dompet yang dipakai (opsional, tampil sebagai badge kecil di ikon)
  final String? walletName;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onMenuSelected,
    this.walletName,
  });

  IconData _getCategoryIcon() {
    switch (transaction.kategori.toLowerCase()) {
      case 'makanan & minum':
      case 'makanan':
        return Icons.restaurant;
      case 'transportasi':
        return Icons.directions_car;
      case 'belanja':
        return Icons.shopping_bag;
      case 'hiburan':
        return Icons.movie;
      case 'kesehatan':
        return Icons.local_hospital;
      case 'pendidikan':
        return Icons.school;
      case 'gaji':
      case 'pendapatan':
        return Icons.attach_money;
      case 'tagihan':
        return Icons.receipt;
      case 'investasi':
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor() {
    switch (transaction.kategori.toLowerCase()) {
      case 'makanan & minum':
      case 'makanan':
        return const Color(0xFFE67E22);
      case 'transportasi':
        return const Color(0xFF3498DB);
      case 'belanja':
        return const Color(0xFF9B59B6);
      case 'hiburan':
        return const Color(0xFFE74C3C);
      case 'kesehatan':
        return const Color(0xFF2ECC71);
      case 'pendidikan':
        return const Color(0xFF1ABC9C);
      case 'gaji':
      case 'pendapatan':
        return const Color(0xFF27AE60);
      case 'tagihan':
        return const Color(0xFFE74C3C);
      case 'investasi':
        return const Color(0xFF2980B9);
      default:
        return const Color(0xFF7F8C8D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPemasukan = transaction.tipe == 'pemasukan';
    final Color nominalColor =
        isPemasukan ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);
    final String waktu =
        '${transaction.tanggal.hour.toString().padLeft(2, '0')}:'
        '${transaction.tanggal.minute.toString().padLeft(2, '0')}';
    final color = _getCategoryColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2130),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // ── Ikon + badge dompet ──────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getCategoryIcon(), color: color, size: 22),
                ),
                // Badge nama dompet di pojok kanan bawah ikon
                if (walletName != null)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2D3E),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        walletName!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // ── Judul & kategori ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.judul,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    transaction.kategori,
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ],
              ),
            ),

            // ── Waktu & nominal ──────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  waktu,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatWithSign(
                      transaction.nominal, transaction.tipe),
                  style: TextStyle(
                    color: nominalColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            // ── Menu titik 3 ─────────────────────────────────────────────
            if (onMenuSelected != null) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                color: const Color(0xFF2A2D3E),
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 18,
                ),
                onSelected: onMenuSelected,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit',
                        style: TextStyle(color: Colors.white)),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
