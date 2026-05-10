import 'package:flutter/material.dart';

/// Halaman Dompet - placeholder untuk sementara.
/// Akan diisi dengan manajemen dompet/rekening di iterasi berikutnya.
class DompetScreen extends StatelessWidget {
  const DompetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF12141E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wallet_rounded,
              size: 64,
              color: Color(0xFF4A90D9),
            ),
            SizedBox(height: 16),
            Text(
              'Menu Dompet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kelola dompet & rekening Anda di sini',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
