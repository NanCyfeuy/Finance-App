import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
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
      _selectedMode = txn.tipe == 'pemasukan'
          ? TransactionMode.pemasukan
          : TransactionMode.pengeluaran;
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _nominalController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Color get _modeColor {
    return _selectedMode == TransactionMode.pemasukan
        ? const Color(0xFF2ECC71)
        : const Color(0xFFE74C3C);
  }

  String get _modeLabel {
    return _selectedMode == TransactionMode.pemasukan
        ? 'Terima Uang'
        : 'Kirim Uang';
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final nominalText = _nominalController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final nominal = int.tryParse(nominalText);
    if (nominal == null || nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal yang valid.')),
      );
      return;
    }

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
    );

    setState(() => _isSaving = true);
    try {
      if (_isEditMode) {
        await _transactionService.update(transaction.id!, transaction);
      } else {
        await _transactionService.insert(transaction);
      }
      if (!mounted) return;
      Navigator.pop(context, transaction);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan transaksi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
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
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih tipe transaksi',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildModeChip(
                      label: 'Pengeluaran',
                      icon: Icons.arrow_upward,
                      selected: _selectedMode == TransactionMode.pengeluaran,
                      color: const Color(0xFFE74C3C),
                      onTap: () => setState(
                        () => _selectedMode = TransactionMode.pengeluaran,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModeChip(
                      label: 'Pemasukan',
                      icon: Icons.arrow_downward,
                      selected: _selectedMode == TransactionMode.pemasukan,
                      color: const Color(0xFF2ECC71),
                      onTap: () => setState(
                        () => _selectedMode = TransactionMode.pemasukan,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _modeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _selectedMode == TransactionMode.pemasukan
                    ? 'Pemasukan akan menambah saldo dompet.'
                    : 'Pengeluaran akan mengurangi saldo dompet.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _judulController,
                      label: 'Judul Transaksi',
                      hint: 'Contoh: Beli kopi atau Gaji bulan ini',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nominalController,
                      label: 'Nominal',
                      hint: 'Masukkan angka, contoh 50000',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final raw =
                            value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                        if (raw.isEmpty) {
                          return 'Nominal tidak boleh kosong';
                        }
                        if (int.tryParse(raw) == null) {
                          return 'Masukkan nominal valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedKategori,
                      items: _kategoriOptions
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF1E2130),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      dropdownColor: const Color(0xFF12141E),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedKategori = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _catatanController,
                      label: 'Catatan (opsional)',
                      hint: 'Tambah detail transaksi',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _modeColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : const Color(0xFF1E2130),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : Colors.white54, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.white70,
                fontWeight: FontWeight.w600,
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
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
        filled: true,
        fillColor: const Color(0xFF1E2130),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
