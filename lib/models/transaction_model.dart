class TransactionModel {
  final String? id;
  final String judul;
  final int nominal;
  final String tipe; // 'pemasukan' atau 'pengeluaran'
  final String kategori;
  final String? catatan;
  final DateTime tanggal;
  final String? walletId;

  TransactionModel({
    this.id,
    required this.judul,
    required this.nominal,
    required this.tipe,
    required this.kategori,
    this.catatan,
    required this.tanggal,
    this.walletId,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      judul: map['judul'],
      nominal: map['nominal'],
      tipe: map['tipe'],
      kategori: map['kategori'],
      catatan: map['catatan'],
      // Supabase mengembalikan timestamptz sebagai UTC (+00)
      // DateTime.parse otomatis set isUtc=true jika ada +00/Z
      // .toLocal() konversi ke timezone device
      tanggal: DateTime.parse(map['tanggal']).toLocal(),
      walletId: map['wallet_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'judul': judul,
      'nominal': nominal,
      'tipe': tipe,
      'kategori': kategori,
      'catatan': catatan,
      // Kirim sebagai UTC agar Supabase menyimpan dengan timezone yang benar
      // DateTime.now() adalah local → .toUtc() konversi ke UTC → simpan ke DB
      'tanggal': tanggal.toUtc().toIso8601String(),
      'wallet_id': walletId,
    };
  }
}
