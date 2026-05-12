import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

/// Provider untuk transaksi dengan Supabase Realtime.
/// Semua device akan sync otomatis saat ada perubahan transaksi.
class TransactionProvider extends ChangeNotifier {
  final _service = TransactionService();
  final _supabase = Supabase.instance.client;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _channel;

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Load & Realtime ───────────────────────────────────────────────────────

  Future<void> loadFromSupabase() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _service.getAll();
      list.sort((a, b) => b.tanggal.compareTo(a.tanggal));
      _transactions = list;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }

    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = _supabase
        .channel('transactions_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'transactions',
          callback: (payload) => _handleInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'transactions',
          callback: (payload) => _handleUpdate(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'transactions',
          callback: (payload) => _handleDelete(payload.oldRecord),
        )
        .subscribe();
  }

  void _handleInsert(Map<String, dynamic> record) {
    try {
      final tx = TransactionModel.fromMap(record);
      if (!_transactions.any((t) => t.id == tx.id)) {
        _transactions.insert(0, tx);
        _transactions.sort((a, b) => b.tanggal.compareTo(a.tanggal));
        notifyListeners();
      }
    } catch (_) {}
  }

  void _handleUpdate(Map<String, dynamic> record) {
    try {
      final tx = TransactionModel.fromMap(record);
      final idx = _transactions.indexWhere((t) => t.id == tx.id);
      if (idx >= 0) {
        _transactions[idx] = tx;
        _transactions.sort((a, b) => b.tanggal.compareTo(a.tanggal));
        notifyListeners();
      }
    } catch (_) {}
  }

  void _handleDelete(Map<String, dynamic> record) {
    try {
      final id = record['id'] as String?;
      if (id != null) {
        _transactions.removeWhere((t) => t.id == id);
        notifyListeners();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  /// Filter transaksi berdasarkan periode
  List<TransactionModel> filterByPeriode(String periode) {
    final now = DateTime.now();
    switch (periode) {
      case 'hari':
        return _transactions.where((t) =>
          t.tanggal.year == now.year &&
          t.tanggal.month == now.month &&
          t.tanggal.day == now.day).toList();
      case 'minggu':
        final weekAgo = now.subtract(const Duration(days: 7));
        return _transactions.where((t) => t.tanggal.isAfter(weekAgo)).toList();
      case 'bulan':
        return _transactions.where((t) =>
          t.tanggal.year == now.year &&
          t.tanggal.month == now.month).toList();
      case 'tahun':
        return _transactions.where((t) => t.tanggal.year == now.year).toList();
      default:
        return List.from(_transactions);
    }
  }

  int totalPemasukan(List<TransactionModel> list) =>
      list.where((t) => t.tipe == 'pemasukan').fold(0, (s, t) => s + t.nominal);

  int totalPengeluaran(List<TransactionModel> list) =>
      list.where((t) => t.tipe == 'pengeluaran').fold(0, (s, t) => s + t.nominal);
}

/// InheritedWidget wrapper
class TransactionProviderScope extends InheritedNotifier<TransactionProvider> {
  const TransactionProviderScope({
    super.key,
    required TransactionProvider provider,
    required super.child,
  }) : super(notifier: provider);

  static TransactionProvider of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<TransactionProviderScope>();
    assert(scope != null,
        'TransactionProviderScope tidak ditemukan di widget tree');
    return scope!.notifier!;
  }
}
