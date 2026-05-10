import 'package:intl/intl.dart';

/// Utility class untuk memformat angka menjadi format mata uang Rupiah.
/// Contoh: 1500000 → "Rp1.500.000,00"
class CurrencyFormatter {
  // Formatter dengan locale Indonesia
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 2,
  );

  /// Format angka integer ke string Rupiah
  static String format(int amount) {
    return _formatter.format(amount);
  }

  /// Format angka dengan tanda + atau - di depan (untuk transaksi)
  static String formatWithSign(int amount, String tipe) {
    final formatted = _formatter.format(amount.abs());
    return tipe == 'pemasukan' ? '+$formatted' : '-$formatted';
  }
}
