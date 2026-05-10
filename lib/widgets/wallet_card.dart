import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../utils/currency_formatter.dart';

/// Widget kartu dompet yang ditampilkan dalam horizontal scroll list.
/// Menampilkan nama dompet, tipe, dan saldo.
class WalletCard extends StatelessWidget {
  final WalletModel wallet;
  final VoidCallback? onTap;

  const WalletCard({
    super.key,
    required this.wallet,
    this.onTap,
  });

  /// Mengembalikan ikon yang sesuai berdasarkan tipe dompet
  IconData _getWalletIcon() {
    switch (wallet.tipe.toUpperCase()) {
      case 'BANK':
        return Icons.account_balance;
      case 'E-WALLET':
        return Icons.phone_android;
      case 'CASH':
      default:
        return Icons.wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Warna kartu dari model, default gelap
          color: wallet.warna,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris atas: ikon dompet
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getWalletIcon(),
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Nama dompet
            Text(
              wallet.nama,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Tipe dompet (CASH • IDR, BANK • IDR, dll)
            Text(
              '${wallet.tipe} • IDR',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 10),

            // Saldo dompet
            Text(
              CurrencyFormatter.format(wallet.saldo),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
