import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';

/// Provider untuk berbagi state daftar dompet antara semua screen.
/// Menggunakan Supabase Realtime agar semua device sync otomatis.
class WalletProvider extends ChangeNotifier {
  final _service = WalletService();
  final _txService = TransactionService();
  final _supabase = Supabase.instance.client;

  final List<WalletModel> _dompet = [];
  bool _isLoaded = false;
  RealtimeChannel? _channel;

  List<WalletModel> get dompet => List.unmodifiable(_dompet);
  bool get isLoaded => _isLoaded;

  int get totalSaldo =>
      _dompet.where((w) => !w.dikecualikan).fold(0, (s, w) => s + w.saldo);

  // ── Load & Realtime ───────────────────────────────────────────────────────

  Future<void> loadFromSupabase() async {
    try {
      final list = await _service.getAll();
      _dompet
        ..clear()
        ..addAll(list);
      _isLoaded = true;
      notifyListeners();
    } catch (_) {
      if (_dompet.isEmpty) {
        _isLoaded = true;
        notifyListeners();
      }
    }
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = _supabase
        .channel('wallets_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'wallets',
          callback: (payload) => _handleInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'wallets',
          callback: (payload) => _handleUpdate(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'wallets',
          callback: (payload) => _handleDelete(payload.oldRecord),
        )
        .subscribe();
  }

  void _handleInsert(Map<String, dynamic> record) {
    try {
      final wallet = WalletService.fromMapStatic(record);
      if (!_dompet.any((w) => w.id == wallet.id)) {
        _dompet.add(wallet);
        notifyListeners();
      }
    } catch (_) {}
  }

  void _handleUpdate(Map<String, dynamic> record) {
    try {
      final wallet = WalletService.fromMapStatic(record);
      final idx = _dompet.indexWhere((w) => w.id == wallet.id);
      if (idx >= 0) {
        _dompet[idx] = wallet;
        notifyListeners();
      }
    } catch (_) {}
  }

  void _handleDelete(Map<String, dynamic> record) {
    try {
      final id = record['id'] as String?;
      if (id != null) {
        _dompet.removeWhere((w) => w.id == id);
        notifyListeners();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> tambah(WalletModel wallet) async {
    final saved = await _service.insert(wallet);
    if (!_dompet.any((w) => w.id == saved.id)) {
      _dompet.add(saved);
      notifyListeners();
    }
    if (saved.saldo > 0 && _isValidUuid(saved.id)) {
      await _buatTransaksiSaldo(
        walletId: saved.id,
        walletNama: saved.nama,
        nominal: saved.saldo,
        tipe: 'pemasukan',
        keterangan: 'Saldo awal ${saved.nama}',
      );
    }
  }

  Future<void> edit(WalletModel updated) async {
    final idx = _dompet.indexWhere((w) => w.id == updated.id);
    final saldoLama = idx >= 0 ? _dompet[idx].saldo : 0;
    if (idx >= 0) _dompet[idx] = updated;
    notifyListeners();

    if (_isValidUuid(updated.id)) {
      await _service.update(updated);
      final selisih = updated.saldo - saldoLama;
      if (selisih != 0) {
        await _buatTransaksiSaldo(
          walletId: updated.id,
          walletNama: updated.nama,
          nominal: selisih.abs(),
          tipe: selisih > 0 ? 'pemasukan' : 'pengeluaran',
          keterangan: 'Penyesuaian saldo ${updated.nama}',
        );
      }
    }
  }

  Future<void> hapus(String id) async {
    _dompet.removeWhere((w) => w.id == id);
    notifyListeners();
    if (_isValidUuid(id)) await _service.delete(id);
  }

  Future<void> updateSaldo(String id, int delta) async {
    final idx = _dompet.indexWhere((w) => w.id == id);
    if (idx < 0) return;
    final w = _dompet[idx];
    final saldoBaru = w.saldo + delta;
    _dompet[idx] = WalletModel(
      id: w.id, nama: w.nama, tipe: w.tipe, saldo: saldoBaru,
      namaBank: w.namaBank, warna: w.warna, dikecualikan: w.dikecualikan,
    );
    notifyListeners();
    if (_isValidUuid(id)) {
      try { await _service.updateSaldo(id, saldoBaru); } catch (_) {}
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  Future<void> _buatTransaksiSaldo({
    required String walletId,
    required String walletNama,
    required int nominal,
    required String tipe,
    required String keterangan,
  }) async {
    try {
      await _txService.insert(TransactionModel(
        judul: keterangan,
        nominal: nominal,
        tipe: tipe,
        kategori: 'Lainnya',
        catatan: 'Otomatis dari penyesuaian saldo dompet',
        tanggal: DateTime.now(),
        walletId: walletId,
      ));
    } catch (_) {}
  }

  bool _isValidUuid(String id) {
    if (id.isEmpty || id == 'new') return false;
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(id);
  }
}

/// InheritedWidget wrapper
class WalletProviderScope extends InheritedNotifier<WalletProvider> {
  const WalletProviderScope({
    super.key,
    required WalletProvider provider,
    required super.child,
  }) : super(notifier: provider);

  static WalletProvider of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<WalletProviderScope>();
    assert(scope != null, 'WalletProviderScope tidak ditemukan di widget tree');
    return scope!.notifier!;
  }
}
