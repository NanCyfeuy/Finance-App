import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/wallet_model.dart';

/// Layar form untuk menambahkan dompet baru.
/// Mengembalikan [WalletModel] jika berhasil disimpan.
class TambahDompetScreen extends StatefulWidget {
  const TambahDompetScreen({super.key});

  @override
  State<TambahDompetScreen> createState() => _TambahDompetScreenState();
}

class _TambahDompetScreenState extends State<TambahDompetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _saldoCtrl = TextEditingController(text: '0');

  String _tipe = 'BANK'; // default tipe

  // Pilihan tipe dompet
  static const _tipeOptions = [
    {'value': 'BANK', 'label': 'Bank', 'icon': Icons.account_balance},
    {'value': 'E-WALLET', 'label': 'E-Wallet', 'icon': Icons.phone_android},
    {'value': 'CASH', 'label': 'Kas', 'icon': Icons.wallet},
  ];

  // Warna kartu berdasarkan tipe
  Color _warnaFromTipe(String tipe) {
    switch (tipe) {
      case 'BANK':
        return const Color(0xFF1A3A5C);
      case 'E-WALLET':
        return const Color(0xFF1A3A2A);
      case 'CASH':
      default:
        return const Color(0xFF2A2D3E);
    }
  }

  void _simpan() {
    debugPrint('[TambahDompet] _simpan called, nama=${_namaCtrl.text}, saldo=${_saldoCtrl.text}, tipe=$_tipe');
    if (!_formKey.currentState!.validate()) {
      debugPrint('[TambahDompet] Form validation FAILED');
      return;
    }

    final saldo = int.tryParse(
          _saldoCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    final wallet = WalletModel(
      id: 'new',
      nama: _namaCtrl.text.trim(),
      tipe: _tipe,
      saldo: saldo,
      namaBank: _tipe == 'BANK' ? _namaCtrl.text.trim() : null,
      warna: _warnaFromTipe(_tipe),
    );

    debugPrint('[TambahDompet] Popping with wallet: ${wallet.nama}');
    Navigator.pop(context, wallet);
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _saldoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12141E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tambah Dompet Baru',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF4A90D9)),
            onPressed: _simpan,
            tooltip: 'Simpan',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Section: Detail Dompet ─────────────────────────────────────
            const Text(
              'Detail Dompet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Nama Dompet
            _buildLabel('Nama Dompet'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _namaCtrl,
              hint: 'misal: BCA, GoPay, Tunai',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            // Saldo Awal
            _buildLabel('Saldo Awal'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _saldoCtrl,
              hint: '0',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Saldo wajib diisi';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tipe Dompet
            _buildLabel('Tipe'),
            const SizedBox(height: 8),
            Row(
              children: _tipeOptions.map((opt) {
                final isActive = _tipe == opt['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _tipe = opt['value'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF4A90D9)
                            : const Color(0xFF1E2130),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF4A90D9)
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            opt['icon'] as IconData,
                            size: 16,
                            color: isActive ? Colors.white : Colors.white54,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            opt['label'] as String,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.white54,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90D9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Simpan Dompet',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 13),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF1E2130),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A90D9), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
