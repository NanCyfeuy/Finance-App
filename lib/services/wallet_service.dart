import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_model.dart';

/// Service untuk CRUD dompet ke tabel `wallets` di Supabase.
///
/// Skema tabel (jalankan di Supabase SQL Editor):
/// ```sql
/// create table wallets (
///   id uuid primary key default gen_random_uuid(),
///   nama text not null,
///   tipe text not null,
///   saldo bigint not null default 0,
///   nama_bank text,
///   warna_hex text,
///   created_at timestamptz default now()
/// );
/// ```
class WalletService {
  final _supabase = Supabase.instance.client;

  /// Ambil semua dompet dari Supabase
  Future<List<WalletModel>> getAll() async {
    final response = await _supabase
        .from('wallets')
        .select()
        .order('created_at', ascending: true);

    return (response as List).map((e) => _fromMap(e)).toList();
  }

  /// Tambah dompet baru, kembalikan model dengan id dari Supabase
  Future<WalletModel> insert(WalletModel wallet) async {
    final payload = _toMap(wallet);
    debugPrint('[WalletService] INSERT payload: $payload');
    try {
      final response = await _supabase
          .from('wallets')
          .insert(payload)
          .select()
          .single();
      debugPrint('[WalletService] INSERT success: $response');
      return _fromMap(response);
    } catch (e, st) {
      debugPrint('[WalletService] INSERT error: $e');
      debugPrint('[WalletService] Stack: $st');
      rethrow;
    }
  }

  /// Update dompet (nama, tipe, saldo, dll)
  Future<void> update(WalletModel wallet) async {
    await _supabase
        .from('wallets')
        .update(_toMap(wallet))
        .eq('id', wallet.id);
  }

  /// Update hanya saldo dompet (lebih efisien)
  Future<void> updateSaldo(String id, int saldoBaru) async {
    await _supabase
        .from('wallets')
        .update({'saldo': saldoBaru})
        .eq('id', id);
  }

  /// Hapus dompet
  Future<void> delete(String id) async {
    await _supabase.from('wallets').delete().eq('id', id);
  }

  // ── Konversi ──────────────────────────────────────────────────────────────

  /// Static version untuk dipakai dari WalletProvider (Realtime callback)
  static WalletModel fromMapStatic(Map<String, dynamic> map) {
    final tipe = map['tipe'] as String;
    return WalletModel(
      id: map['id'] as String,
      nama: map['nama'] as String,
      tipe: tipe,
      saldo: (map['saldo'] as num).toInt(),
      namaBank: map['nama_bank'] as String?,
      warna: _warnaFromTipeStatic(tipe),
    );
  }

  static Color _warnaFromTipeStatic(String tipe) {
    switch (tipe) {
      case 'BANK': return const Color(0xFF1A3A5C);
      case 'E-WALLET': return const Color(0xFF1A3A2A);
      default: return const Color(0xFF2A2D3E);
    }
  }

  WalletModel _fromMap(Map<String, dynamic> map) => WalletService.fromMapStatic(map);

  Map<String, dynamic> _toMap(WalletModel w) {
    return {
      'nama': w.nama,
      'tipe': w.tipe,
      'saldo': w.saldo,
      'nama_bank': w.namaBank,
    };
  }


}
