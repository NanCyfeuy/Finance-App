CREATE TABLE transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    judul TEXT NOT NULL,
    nominal BIGINT NOT NULL,
    tipe TEXT NOT NULL CHECK (tipe IN ('pemasukan', 'pengeluaran')),
    kategori TEXT NOT NULL,
    catatan TEXT,
    tanggal DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);