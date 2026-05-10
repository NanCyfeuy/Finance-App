import 'package:flutter/material.dart';

/// Halaman Statistik - placeholder untuk sementara.
/// Akan diisi dengan grafik dan analisis keuangan di iterasi berikutnya.
class StatistikScreen extends StatelessWidget {
  const StatistikScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF12141E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: Color(0xFF4A90D9),
            ),
            SizedBox(height: 16),
            Text(
              'Menu Statistik',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Fitur ini sedang dalam pengembangan',
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
