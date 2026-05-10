# Dokumentasi Finance App — Dashboard Update
---

## Daftar Isi

1. [Gambaran Umum](#gambaran-umum)
2. [Struktur File](#struktur-file)
3. [File Baru](#file-baru)
4. [File Diperbarui](#file-diperbarui)
5. [Navigasi Aplikasi](#navigasi-aplikasi)
6. [Palet Warna](#palet-warna)
7. [Alur Data Dashboard](#alur-data-dashboard)
8. [Kategori Transaksi](#kategori-transaksi)
9. [Yang Perlu Dikerjakan Selanjutnya (TODO)](#yang-perlu-dikerjakan-selanjutnya)

---

## Gambaran Umum

Pembaruan ini menambahkan halaman **Dashboard** lengkap sebagai tampilan utama aplikasi pencatat keuangan. Dashboard menampilkan ringkasan saldo, daftar dompet yang bisa di-scroll horizontal, dan riwayat transaksi yang dikelompokkan per tanggal. Seluruh UI menggunakan **dark theme** dengan skema warna biru-teal.

---

## Struktur File

```
lib/
├── main.dart                          ← Diperbarui
├── config/
│   ├── supabase_config.dart           ← Baru (dibuat dari .example)
│   └── supabase_config.example.dart   ← Tidak diubah
├── models/
│   ├── transaction_model.dart         ← Tidak diubah
│   └── wallet_model.dart              ← Baru
├── screens/
│   ├── home_screen.dart               ← Diperbarui (shell navigasi)
│   ├── dashboard_screen.dart          ← Baru
│   ├── statistik_screen.dart          ← Baru (placeholder)
│   ├── dompet_screen.dart             ← Baru (placeholder)
│   ├── tambah_transaksi_screen.dart   ← Baru (placeholder)
│   ├── analisis_screen.dart           ← Tidak diubah
│   └── transaction_form_screen.dart   ← Tidak diubah
├── services/
│   └── transaction_service.dart       ← Tidak diubah
├── utils/
│   └── currency_formatter.dart        ← Baru
└── widgets/
    ├── transaction_card.dart          ← Diperbarui (redesign)
    └── wallet_card.dart               ← Baru
```

---

## File Baru

### `lib/config/supabase_config.dart`

Berisi konfigurasi koneksi ke Supabase (URL dan anon key). Dibuat dari file `.example` yang sudah ada.

> ⚠️ **Jangan commit file ini ke repository publik** karena berisi `anonKey`.

```dart
class SupabaseConfig {
  static const String url = '...';
  static const String anonKey = '...';
}
```

---

### `lib/models/wallet_model.dart`

Model data untuk merepresentasikan dompet atau rekening pengguna.

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | ID unik dompet |
| `nama` | `String` | Nama dompet (contoh: "BRI", "Cash") |
| `tipe` | `String` | Tipe dompet: `CASH`, `BANK`, atau `E-WALLET` |
| `saldo` | `int` | Saldo saat ini dalam Rupiah |
| `namaBank` | `String?` | Nama bank, opsional, diisi jika tipe `BANK` |
| `warna` | `Color` | Warna kartu dompet, default `#2A2D3E` |

> **Catatan:** Data dompet saat ini masih dummy (hardcoded). Perlu dibuat tabel `wallets` di Supabase untuk koneksi nyata.

---

### `lib/utils/currency_formatter.dart`

Utility class untuk memformat angka integer menjadi format mata uang Rupiah menggunakan package `intl`.

| Method | Input | Output | Contoh |
|---|---|---|---|
| `format(int amount)` | `1500000` | `"Rp1.500.000,00"` | Untuk saldo dan ringkasan |
| `formatWithSign(int amount, String tipe)` | `41750, 'pengeluaran'` | `"-Rp41.750,00"` | Untuk item transaksi |

---

### `lib/screens/dashboard_screen.dart`

Halaman utama dashboard. Merupakan `StatefulWidget` karena mengelola state filter periode, data transaksi, dan visibilitas saldo.

#### Enum `PeriodeFilter`

```
PeriodeFilter.hari    → transaksi hari ini saja
PeriodeFilter.minggu  → 7 hari terakhir
PeriodeFilter.bulan   → bulan berjalan (default)
PeriodeFilter.tahun   → tahun berjalan
PeriodeFilter.semua   → semua transaksi tanpa filter
```

#### State yang dikelola

| State | Tipe | Fungsi |
|---|---|---|
| `_periodeAktif` | `PeriodeFilter` | Filter periode yang sedang aktif |
| `_transaksiFiltered` | `List<TransactionModel>` | Transaksi hasil filter |
| `_isLoading` | `bool` | Status loading dari Supabase |
| `_saldoTerlihat` | `bool` | Toggle tampil/sembunyikan saldo |
| `_daftarDompet` | `List<WalletModel>` | Data dompet (sementara dummy) |

#### Computed properties (getter)

| Getter | Keterangan |
|---|---|
| `_totalPemasukan` | Jumlah semua transaksi `tipe == 'pemasukan'` pada periode aktif |
| `_totalPengeluaran` | Jumlah semua transaksi `tipe == 'pengeluaran'` pada periode aktif |
| `_totalSaldo` | Jumlah saldo dari semua dompet |
| `_transaksiPerTanggal` | `Map` transaksi dikelompokkan per tanggal, diurutkan terbaru |

#### Widget builder methods

| Method | Menghasilkan |
|---|---|
| `_buildPeriodeFilter()` | Tab filter Hari/Minggu/Bulan/Tahun/Semua dengan animasi |
| `_buildSaldoCard()` | Card gradient biru-teal berisi total saldo, pemasukan, pengeluaran |
| `_buildSaldoItem()` | Sub-widget item pemasukan atau pengeluaran di dalam card saldo |
| `_buildSectionHeader()` | Header section dengan judul dan tombol titik tiga (⋮) |
| `_buildDompetList()` | `ListView` horizontal berisi kartu-kartu dompet |
| `_buildTransaksiHeader()` | Header "Transaksi Terakhir" dengan link "Lihat Semua" |
| `_buildTransaksiList()` | Daftar transaksi dikelompokkan per tanggal dengan header total harian |
| `_buildEmptyState()` | Tampilan kosong ketika tidak ada transaksi di periode yang dipilih |

#### Fitur tambahan

- **Pull-to-refresh** — tarik layar ke bawah untuk reload data dari Supabase
- **Toggle saldo** — ikon mata (👁) untuk menyembunyikan/menampilkan nominal saldo
- **CustomScrollView + Sliver** — performa scroll lebih baik untuk konten panjang

---

### `lib/screens/statistik_screen.dart`

Halaman placeholder untuk menu Statistik. Menampilkan ikon dan teks "Fitur ini sedang dalam pengembangan". Akan diisi dengan grafik dan analisis keuangan di iterasi berikutnya.

---

### `lib/screens/dompet_screen.dart`

Halaman placeholder untuk menu Dompet. Akan diisi dengan fitur manajemen dompet dan rekening (tambah, edit, hapus dompet).

---

### `lib/screens/tambah_transaksi_screen.dart`

Halaman placeholder untuk form tambah transaksi. Dibuka sebagai `fullscreenDialog` (animasi slide dari bawah) saat FAB "+" ditekan. Memiliki tombol close (✕) di AppBar untuk kembali.

---

### `lib/widgets/wallet_card.dart`

Widget kartu dompet untuk ditampilkan dalam horizontal scroll list di dashboard.

**Props:**

| Prop | Tipe | Keterangan |
|---|---|---|
| `wallet` | `WalletModel` | Data dompet yang ditampilkan |
| `onTap` | `VoidCallback?` | Callback saat kartu ditekan |

**Logika ikon berdasarkan tipe:**

| Tipe | Ikon |
|---|---|
| `CASH` | `Icons.wallet` |
| `BANK` | `Icons.account_balance` |
| `E-WALLET` | `Icons.phone_android` |

---

## File Diperbarui

### `lib/main.dart`

Perubahan dari versi sebelumnya:

| Sebelum | Sesudah |
|---|---|
| Light theme default Flutter | Dark theme penuh (`Brightness.dark`) |
| Tidak ada konfigurasi status bar | Status bar transparan, ikon putih |
| `scaffoldBackgroundColor` default | `#12141E` (biru gelap) |
| `seedColor` biru standar | `#4A90D9` (biru muda) |

---

### `lib/screens/home_screen.dart`

Diubah total dari `StatelessWidget` sederhana menjadi **shell navigasi utama** (`StatefulWidget`).

**Perubahan utama:**

- Menggunakan `IndexedStack` agar state tiap halaman tetap terjaga saat berpindah tab (tidak di-rebuild dari awal)
- Bottom navigation bar custom berbentuk **pill/kapsul** floating
- Floating Action Button (FAB) "+" di pojok kanan bawah
- Haptic feedback saat berpindah tab (`lightImpact`) dan saat tekan FAB (`mediumImpact`)
- Tab aktif menampilkan label teks + latar semi-transparan, tab tidak aktif hanya ikon

**Struktur navigasi:**

```
Index 0 → DashboardScreen
Index 1 → StatistikScreen
Index 2 → DompetScreen
FAB (+) → TambahTransaksiScreen (fullscreenDialog)
```

---

### `lib/widgets/transaction_card.dart`

Redesign total mengikuti dark theme. Perubahan utama:

| Aspek | Sebelum | Sesudah |
|---|---|---|
| Latar card | Default Material | `#1E2130` dengan border tipis |
| Ikon kategori | Tidak ada | Ikon berwarna per kategori dengan latar semi-transparan |
| Warna nominal | Tidak ada pembeda | Hijau untuk pemasukan, merah untuk pengeluaran |
| Waktu transaksi | Tidak ditampilkan | Ditampilkan di pojok kanan atas (format HH:mm) |
| Warna teks kategori | Abu-abu | Mengikuti warna ikon kategori |

**Pemetaan warna kategori:**

| Kategori | Warna |
|---|---|
| Makanan & Minum | `#E67E22` (oranye) |
| Transportasi | `#3498DB` (biru) |
| Belanja | `#9B59B6` (ungu) |
| Hiburan | `#E74C3C` (merah) |
| Kesehatan | `#2ECC71` (hijau) |
| Pendidikan | `#1ABC9C` (teal) |
| Gaji / Pendapatan | `#27AE60` (hijau tua) |
| Tagihan | `#E74C3C` (merah) |
| Investasi | `#2980B9` (biru tua) |
| Lainnya | `#7F8C8D` (abu-abu) |

---

## Navigasi Aplikasi

```
HomeScreen (shell)
│
├── [Tab 0] DashboardScreen
│     ├── Filter Periode (Hari/Minggu/Bulan/Tahun/Semua)
│     ├── Card Saldo (Total, Pemasukan, Pengeluaran)
│     ├── Dompet Saya (horizontal scroll)
│     └── Transaksi Terakhir (grouped by date)
│
├── [Tab 1] StatistikScreen (placeholder)
│
├── [Tab 2] DompetScreen (placeholder)
│
└── [FAB +] TambahTransaksiScreen (fullscreenDialog, placeholder)
```

---

## Palet Warna

| Nama | Hex | Digunakan untuk |
|---|---|---|
| Background utama | `#12141E` | Scaffold, layar semua halaman |
| Background card | `#1E2130` | Card transaksi, navbar |
| Background card dompet (default) | `#2A2D3E` | Kartu dompet Cash |
| Biru aksen | `#4A90D9` | Link, loading indicator, ikon placeholder |
| Gradient card saldo (kiri) | `#1A3A6C` | Card saldo |
| Gradient card saldo (kanan) | `#0D6E6E` | Card saldo |
| Hijau pemasukan | `#2ECC71` | Nominal pemasukan, ikon panah turun |
| Merah pengeluaran | `#E74C3C` | Nominal pengeluaran, ikon panah naik |

---

## Alur Data Dashboard

```
initState()
    │
    └─► _loadData()
            │
            ├─► TransactionService.getAll()  ← Supabase
            │
            └─► _filterByPeriode(semua, _periodeAktif)
                    │
                    └─► setState(_transaksiFiltered = hasil filter)
                              │
                              ├─► _totalPemasukan  (getter, dihitung ulang)
                              ├─► _totalPengeluaran (getter, dihitung ulang)
                              └─► _transaksiPerTanggal (getter, dikelompokkan)

Saat pengguna ganti filter:
    _onPeriodeChanged(periode)
        │
        └─► _loadData() ulang dengan periode baru
```

---

## Kategori Transaksi

Kategori yang sudah didukung dengan ikon dan warna khusus di `TransactionCard`:

- Makanan & Minum / Makanan
- Transportasi
- Belanja
- Hiburan
- Kesehatan
- Pendidikan
- Gaji / Pendapatan
- Tagihan
- Investasi
- *(kategori lain)* → ikon dan warna default

---

## Yang Perlu Dikerjakan Selanjutnya

### Prioritas Tinggi

- [ ] **Tabel `wallets` di Supabase** — buat tabel dan `WalletService` agar data dompet tidak lagi hardcoded
- [ ] **Form Tambah Transaksi** — implementasi `TambahTransaksiScreen` dengan field judul, nominal, tipe, kategori, tanggal, dan pilihan dompet
- [ ] **Halaman Detail Transaksi** — tap pada `TransactionCard` membuka detail lengkap dengan opsi edit/hapus

### Prioritas Sedang

- [ ] **Halaman Statistik** — grafik pie chart pengeluaran per kategori, bar chart tren bulanan
- [ ] **Halaman Dompet** — daftar semua dompet, tambah dompet baru, edit saldo awal
- [ ] **Halaman Semua Transaksi** — tap "Lihat Semua" di dashboard membuka daftar lengkap dengan fitur search dan filter

### Prioritas Rendah

- [ ] **Notifikasi anggaran** — peringatan saat pengeluaran mendekati batas anggaran
- [ ] **Export data** — ekspor transaksi ke CSV atau PDF
- [ ] **Multi-currency** — dukungan mata uang selain IDR
