create table wallets (
    id uuid primary key default gen_random_uuid(),
    nama text not null,
    tipe text not null check (tipe in ('CASH', 'BANK', 'E-WALLET')),
    saldo integer not null default 0,
    nama_bank text,
    warna text not null default '#2A2D3E',
    created_at timestamptz not null default now()
);