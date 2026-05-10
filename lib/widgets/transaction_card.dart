import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';

/// Widget untuk menampilkan satu item transaksi dalam daftar riwayat.
/// Menampilkan ikon kategori, judul, kategori, waktu, dan nominal.
class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
  });

  /// Mengembalikan ikon berdasarkan kategori transaksi
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

  /// Mengembalikan warna latar ikon berdasarkan kategori
  Color _getCategoryColor() {
    switch (transaction.kategori.toLowerCase()) {
      case 'makanan & minum':
      case 'makanan':
        return const Color(0xFFE67E22); // oranye
      case 'transportasi':
        return const Color(0xFF3498DB); // biru
      case 'belanja':
        return const Color(0xFF9B59B6); // ungu
      case 'hiburan':
        return const Color(0xFFE74C3C); // merah
      case 'kesehatan':
        return const Color(0xFF2ECC71); // hijau
      case 'pendidikan':
        return const Color(0xFF1ABC9C); // teal
      case 'gaji':
      case 'pendapatan':
        return const Color(0xFF27AE60); // hijau tua
      case 'tagihan':
        return const Color(0xFFE74C3C); // merah
      case 'investasi':
        return const Color(0xFF2980B9); // biru tua
      default:
        return const Color(0xFF7F8C8D); // abu-abu
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan apakah transaksi ini pemasukan atau pengeluaran
    final bool isPemasukan = transaction.tipe == 'pemasukan';
    final Color nominalColor =
        isPemasukan ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);

    // Format waktu transaksi (hanya jam:menit)
    final String waktu =
        '${transaction.tanggal.hour.toString().padLeft(2, '0')}:'
        '${transaction.tanggal.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2130), // warna card gelap
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Ikon kategori dengan latar berwarna
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _getCategoryColor().withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(),
                color: _getCategoryColor(),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Judul dan kategori transaksi
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
                    style: TextStyle(
                      // Warna kategori mengikuti warna ikon
                      color: _getCategoryColor(),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Waktu dan nominal di sisi kanan
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
          ],
        ),
      ),
    );
  }
}
