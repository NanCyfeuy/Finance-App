import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../providers/wallet_provider.dart';
import '../services/transaction_service.dart';

enum TransactionMode { pengeluaran, pemasukan }

class TambahTransaksiScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const TambahTransaksiScreen({super.key, this.transaction});

  @override
  State<TambahTransaksiScreen> createState() => _TambahTransaksiScreenState();
}

class _TambahTransaksiScreenState extends State<TambahTransaksiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _nominalController = TextEditingController();
  final _catatanController = TextEditingController();
  final TransactionService _transactionService = TransactionService();

  TransactionMode _selectedMode = TransactionMode.pengeluaran;
  String _selectedKategori = 'Belanja';
  String? _selectedWalletId;
  bool _isSaving = false;

  bool get _isEditMode => widget.transaction != null;

  final List<String> _kategoriOptions = [
    'Belanja',
    'Makanan',
    'Transportasi',
    'Hiburan',
    'Gaji',
    'Tagihan',
    'Investasi',
    'Kesehatan',
    'Pendidikan',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final txn = widget.transaction!;
      _judulController.text = txn.judul;
      _nominalController.text = txn.nominal.toString();
      _catatanController.text = txn.catatan ?? '';
      _selectedKategori = txn.kategori;
      _selectedWalletId = txn.walletId;
      _selectedMode = txn.tipe == 'pemasukan'
          ? TransactionMode.pemasukan
          : TransactionMode.pengeluaran;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set default wallet ke dompet pertama jika belum dipilih
    if (_selectedWalletId == null) {
      final dompet = WalletProviderScope.of(context).dompet;
      if (dompet.isNotEmpty) {
        _selectedWalletId = dompet.first.id;
      }
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _nominalController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Color get _modeColor => _selectedMode == TransactionMode.pemasukan
      ? const Color(0xFF2ECC71)
      : const Color(0xFFE74C3C);

  String get _modeLabel => _selectedMode == TransactionMode.pemasukan
      ? 'Terima Uang'
      : 'Kirim Uang';

  bool _isValidUuid(String? id) {
    if (id == null || id.isEmpty || id == 'new') return false;
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(id);
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final nominalText =
        _nominalController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final nominal = int.tryParse(nominalText);
    if (nominal == null || nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal yang valid.')),
      );
      return;
    }

    // Hanya kirim wallet_id ke Supabase jika id adalah UUID valid
    final validWalletId =
        _isValidUuid(_selectedWalletId) ? _selectedWalletId : null;

    final transaction = TransactionModel(
      id: widget.transaction?.id,
      judul: _judulController.text.trim(),
      nominal: nominal,
      tipe: _selectedMode == TransactionMode.pemasukan
          ? 'pemasukan'
          : 'pengeluaran',
      kategori: _selectedKategori,
      catatan: _catatanController.text.trim().isEmpty
          ? null
          : _catatanController.text.trim(),
      tanggal: widget.transaction?.tanggal ?? DateTime.now(),
      walletId: validWalletId,
    );

    setState(() => _isSaving = true);
    try {
      final provider = WalletProviderScope.of(context);

      if (_isEditMode) {
        final old = widget.transaction!;
        if (old.walletId != null && _isValidUuid(old.walletId)) {
          final oldDelta = old.tipe == 'pemasukan' ? -old.nominal : old.nominal;
          await provider.updateSaldo(old.walletId!, oldDelta);
        }
        await _transactionService.update(transaction.id!, transaction);
      } else {
        await _transactionService.insert(transaction);
      }

      // Update saldo dompet lokal (dan Supabase jika UUID valid)
      if (_selectedWalletId != null && _selectedWalletId!.isNotEmpty) {
        final delta = transaction.tipe == 'pemasukan' ? nominal : -nominal;
        await provider.updateSaldo(_selectedWalletId!, delta);
      }

      if (!mounted) return;
      Navigator.pop(context, transaction);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dompet = WalletProviderScope.of(context).dompet;

    return Scaffold(
      backgroundColor: const Color(0xFF12141E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12141E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? 'Edit Transaksi' : 'Tambah Transaksi',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Pilih Tipe ─────────────────────────────────────────────
              _buildSectionLabel('Tipe Transaksi'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildModeChip(
                      label: 'Pengeluaran',
                      icon: Icons.arrow_upward,
                      selected:
                          _selectedMode == TransactionMode.pengeluaran,
                      color: const Color(0xFFE74C3C),
                      onTap: () => setState(
                          () => _selectedMode = TransactionMode.pengeluaran),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModeChip(
                      label: 'Pemasukan',
                      icon: Icons.arrow_downward,
                      selected:
                          _selectedMode == TransactionMode.pemasukan,
                      color: const Color(0xFF2ECC71),
                      onTap: () => setState(
                          () => _selectedMode = TransactionMode.pemasukan),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Pilih Dompet ───────────────────────────────────────────
              _buildSectionLabel('Dompet'),
              const SizedBox(height: 10),
              if (dompet.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2130),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.white38, size: 18),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Belum ada dompet. Tambah di menu Dompet.',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildWalletSelector(dompet),
              const SizedBox(height: 24),

              // ── Form ───────────────────────────────────────────────────
              _buildSectionLabel(_modeLabel),
              const SizedBox(height: 6),
              Text(
                _selectedMode == TransactionMode.pemasukan
                    ? 'Pemasukan akan menambah saldo dompet.'
                    : 'Pengeluaran akan mengurangi saldo dompet.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _judulController,
                      label: 'Judul Transaksi',
                      hint: 'Contoh: Beli kopi atau Gaji bulan ini',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Judul tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _nominalController,
                      label: 'Nominal',
                      hint: 'Contoh: 50000',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final raw =
                            v?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                        if (raw.isEmpty) return 'Nominal tidak boleh kosong';
                        if (int.tryParse(raw) == null) {
                          return 'Masukkan nominal valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedKategori,
                      items: _kategoriOptions
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ))
                          .toList(),
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        labelStyle:
                            const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF1E2130),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      dropdownColor: const Color(0xFF1E2130),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedKategori = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _catatanController,
                      label: 'Catatan (opsional)',
                      hint: 'Tambah detail transaksi',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _modeColor,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isEditMode
                                    ? 'Simpan Perubahan'
                                    : 'Simpan Transaksi',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget Helpers ──────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Selector dompet — tampil sebagai horizontal scroll chips
  Widget _buildWalletSelector(List<WalletModel> dompet) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dompet.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final w = dompet[i];
          final isSelected = _selectedWalletId == w.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedWalletId = w.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? w.warna
                    : const Color(0xFF1E2130),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? w.warna
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _walletIcon(w.tipe),
                    size: 16,
                    color: isSelected ? Colors.white : Colors.white54,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        w.nama,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        w.tipe,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white70
                              : Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _walletIcon(String tipe) {
    switch (tipe) {
      case 'BANK':
        return Icons.account_balance;
      case 'E-WALLET':
        return Icons.phone_android;
      default:
        return Icons.wallet;
    }
  }

  Widget _buildModeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : const Color(0xFF1E2130),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? color
                : Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: selected ? color : Colors.white38, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.white54,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        filled: true,
        fillColor: const Color(0xFF1E2130),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: Color(0xFF4A90D9), width: 1.5),
        ),
      ),
    );
  }
}
