import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class StatistikScreen extends StatefulWidget {
  const StatistikScreen({super.key});

  @override
  State<StatistikScreen> createState() => _StatistikScreenState();
}

class _StatistikScreenState extends State<StatistikScreen>
    with SingleTickerProviderStateMixin {
  final TransactionService _service = TransactionService();

  bool _isLoading = true;
  List<TransactionModel> _data = [];

  int _totalPemasukan = 0;
  int _totalPengeluaran = 0;

  Map<String, int> _perKategori = {};

  List<String> _labelBulan = [];
  List<double> _dataPemasukan = [];
  List<double> _dataPengeluaran = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Palet warna modern
  static const Color _bg = Color(0xFF0D0F1A);
  static const Color _surface = Color(0xFF161928);
  static const Color _surfaceAlt = Color(0xFF1C1F2E);
  static const Color _blue = Color(0xFF4A90D9);
  static const Color _green = Color(0xFF2ECC71);
  static const Color _red = Color(0xFFE74C3C);
  static const Color _amber = Color(0xFFF39C12);
  static const Color _purple = Color(0xFF9B59B6);
  static const Color _teal = Color(0xFF1ABC9C);

  final List<Color> _warnaPie = const [
    _blue,
    _red,
    _green,
    _amber,
    _purple,
    _teal,
    Color(0xFFE67E22),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAll();

      int pemasukan = 0;
      int pengeluaran = 0;
      final Map<String, int> perKategori = {};
      final Map<String, int> pemasukanBulan = {};
      final Map<String, int> pengeluaranBulan = {};

      for (var t in data) {
        final bulan = _formatBulan(t.tanggal);
        if (t.tipe == 'pemasukan') {
          pemasukan += t.nominal;
          pemasukanBulan[bulan] = (pemasukanBulan[bulan] ?? 0) + t.nominal;
        } else {
          pengeluaran += t.nominal;
          pengeluaranBulan[bulan] = (pengeluaranBulan[bulan] ?? 0) + t.nominal;
          perKategori[t.kategori] = (perKategori[t.kategori] ?? 0) + t.nominal;
        }
      }

      final semuaBulan = {
        ...pemasukanBulan.keys,
        ...pengeluaranBulan.keys,
      }.toList()..sort();

      setState(() {
        _data = data;
        _totalPemasukan = pemasukan;
        _totalPengeluaran = pengeluaran;
        _perKategori = perKategori;
        _labelBulan = semuaBulan;
        _dataPemasukan = semuaBulan
            .map((b) => (pemasukanBulan[b] ?? 0).toDouble())
            .toList();
        _dataPengeluaran = semuaBulan
            .map((b) => (pengeluaranBulan[b] ?? 0).toDouble())
            .toList();
        _isLoading = false;
      });

      _animController.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: _red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  String _formatBulan(DateTime dt) {
    const nama = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${nama[dt.month - 1]} ${dt.year}';
  }

  String _formatRupiah(int nominal) {
    if (nominal >= 1000000) {
      final juta = nominal / 1000000;
      return 'Rp ${juta % 1 == 0 ? juta.toInt() : juta.toStringAsFixed(1)}jt';
    } else if (nominal >= 1000) {
      final ribu = nominal / 1000;
      return 'Rp ${ribu % 1 == 0 ? ribu.toInt() : ribu.toStringAsFixed(1)}rb';
    }
    return 'Rp $nominal';
  }

  String _formatRupiahLengkap(int nominal) {
    final str = nominal.toString();
    final buffer = StringBuffer();
    int counter = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (counter > 0 && counter % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      counter++;
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoading()
          : _data.isEmpty
          ? _buildKosong()
          : FadeTransition(
              opacity: _fadeAnim,
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: _blue,
                backgroundColor: _surface,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKartuRingkasan(),
                      const SizedBox(height: 14),
                      _buildKartuSaldo(),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        icon: Icons.donut_large_rounded,
                        title: 'Pengeluaran per Kategori',
                      ),
                      const SizedBox(height: 12),
                      _buildPieChart(),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        icon: Icons.bar_chart_rounded,
                        title: 'Pemasukan vs Pengeluaran',
                      ),
                      const SizedBox(height: 12),
                      _buildBarChart(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bg,
      automaticallyImplyLeading: false,
      elevation: 0,
      titleSpacing: 20,
      title: const Text(
        'Statistik',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white60,
                size: 18,
              ),
              onPressed: _loadData,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(color: _blue, strokeWidth: 2.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat data...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dua kartu ringkasan (pemasukan & pengeluaran) ────────────────────────
  Widget _buildKartuRingkasan() {
    return Row(
      children: [
        Expanded(
          child: _buildKartuAngka(
            label: 'Pemasukan',
            nominal: _totalPemasukan,
            warna: _green,
            ikon: Icons.arrow_circle_down_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildKartuAngka(
            label: 'Pengeluaran',
            nominal: _totalPengeluaran,
            warna: _red,
            ikon: Icons.arrow_circle_up_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildKartuAngka({
    required String label,
    required int nominal,
    required Color warna,
    required IconData ikon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(ikon, color: warna, size: 12),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: warna,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _formatRupiahLengkap(nominal),
            style: TextStyle(
              color: warna,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Total keseluruhan',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ── Kartu saldo bersih ───────────────────────────────────────────────────
  Widget _buildKartuSaldo() {
    final saldo = _totalPemasukan - _totalPengeluaran;
    final isPositif = saldo >= 0;
    final warna = isPositif ? _blue : _red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: warna.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo Bersih',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (isPositif ? '' : '-') + _formatRupiahLengkap(saldo.abs()),
                style: TextStyle(
                  color: warna,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPositif
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: warna,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section header ───────────────────────────────────────────────────────
  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _blue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: _blue, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE0E4F0),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Pie / Donut Chart ────────────────────────────────────────────────────
  Widget _buildPieChart() {
    if (_perKategori.isEmpty) {
      return _buildKotakKosong('Belum ada data pengeluaran');
    }

    final entries = _perKategori.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = _perKategori.values.fold(0, (a, b) => a + b);
    // Nilai terbesar untuk scale progress bar relatif
    final maxNilai = entries.first.value.toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          // ── Donut di tengah ──
          SizedBox(
            width: 180,
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 52,
                startDegreeOffset: -90,
                sections: List.generate(entries.length, (i) {
                  return PieChartSectionData(
                    color: _warnaPie[i % _warnaPie.length],
                    value: entries[i].value.toDouble(),
                    title: '',
                    radius: 52,
                  );
                }),
              ),
            ),
          ),

          // ── Legend horizontal di bawah donut ──
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(entries.length, (i) {
              final warna = _warnaPie[i % _warnaPie.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: warna,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    entries[i].key,
                    style: const TextStyle(
                      color: Color(0xFFC5CADB),
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }),
          ),

          // ── Divider ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(
              color: Colors.white.withValues(alpha: 0.05),
              height: 1,
            ),
          ),

          // ── Detail list dengan progress bar di-scale ke nilai terbesar ──
          Column(
            children: List.generate(entries.length, (i) {
              final persen = entries[i].value / total * 100;
              // Scale bar relatif ke kategori terbesar, bukan ke 100%
              // Sehingga bar terpanjang = full, yang kecil proporsional
              final scaleBar = entries[i].value / maxNilai;
              final warna = _warnaPie[i % _warnaPie.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: warna,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entries[i].key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          _formatRupiahLengkap(entries[i].value),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 42,
                          child: Text(
                            '${persen.toStringAsFixed(1)}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: warna,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: scaleBar,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        color: warna,
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Bar Chart ────────────────────────────────────────────────────────────
  Widget _buildBarChart() {
    if (_labelBulan.isEmpty) {
      return _buildKotakKosong('Belum ada data transaksi');
    }

    double maxVal = 0;
    for (int i = 0; i < _labelBulan.length; i++) {
      if (_dataPemasukan[i] > maxVal) maxVal = _dataPemasukan[i];
      if (_dataPengeluaran[i] > maxVal) maxVal = _dataPengeluaran[i];
    }
    final double maxY = (maxVal * 1.3).ceilToDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF252840),
                    tooltipRoundedRadius: 10,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = rodIndex == 0 ? 'Pemasukan' : 'Pengeluaran';
                      final warna = rodIndex == 0 ? _blue : _red;
                      return BarTooltipItem(
                        '$label\n',
                        TextStyle(
                          color: warna,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: _formatRupiahLengkap(rod.toY.toInt()),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _labelBulan.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _labelBulan[idx],
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == maxY) {
                          return const SizedBox();
                        }
                        return Text(
                          _formatRupiah(value.toInt()),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.04),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_labelBulan.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _dataPemasukan[i],
                        color: _blue,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                      BarChartRodData(
                        toY: _dataPengeluaran[i],
                        color: _red,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(_blue, 'Pemasukan'),
              const SizedBox(width: 28),
              _buildLegendItem(_red, 'Pengeluaran'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color warna, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildKotakKosong(String pesan) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          pesan,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildKosong() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.bar_chart_rounded, size: 40, color: _blue),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum ada statistik',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambah transaksi terlebih dahulu\nlalu tarik ke bawah untuk refresh',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
