import 'package:flutter/material.dart';

/// Model untuk merepresentasikan dompet / rekening pengguna.
class WalletModel {
  final String id;
  final String nama;
  final String tipe; // 'CASH', 'BANK', 'E-WALLET'
  final int saldo;
  final String? namaBank;
  final Color warna;

  /// Jika true, saldo dompet ini tidak dihitung ke total saldo utama
  final bool dikecualikan;

  WalletModel({
    required this.id,
    required this.nama,
    required this.tipe,
    required this.saldo,
    this.namaBank,
    this.warna = const Color(0xFF2A2D3E),
    this.dikecualikan = false,
  });
}
