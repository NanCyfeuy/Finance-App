import 'package:flutter/material.dart';

/// Model untuk merepresentasikan dompet / rekening pengguna.
/// Setiap dompet memiliki nama, tipe (cash/bank/e-wallet), dan saldo.
class WalletModel {
  final String id;
  final String nama;
  final String tipe; // 'CASH', 'BANK', 'E-WALLET'
  final int saldo;
  final String? namaBank; // opsional, diisi jika tipe == 'BANK'
  final Color warna; // warna kartu dompet

  WalletModel({
    required this.id,
    required this.nama,
    required this.tipe,
    required this.saldo,
    this.namaBank,
    this.warna = const Color(0xFF2A2D3E),
  });
}
