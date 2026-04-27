-- ============================================================
-- SMA Plus Almunawwarah - Supabase PostgreSQL Schema
-- IDEMPOTENT: Bisa di-run berulang tanpa error
--
-- CATATAN PENTING:
-- - Media sosial (Instagram, YouTube, TikTok) di-hardcode di
--   footer.js, BUKAN di database
-- - Google Maps embed URL di-hardcode di index.html, BUKAN di
--   database
-- - Struktur Organisasi menggunakan gambar penuh (upload via CMS),
--   bukan data individual per jabatan
-- - Autentikasi menggunakan Supabase Auth + profiles table
-- - Admin: admin@elmuna.com / Almunawwarah#29
-- ============================================================

-- ============================================================
-- 0. CLEANUP — Hapus tabel lama yang TIDAK dipakai lagi
-- ============================================================
DROP TABLE IF EXISTS struktur_organisasi CASCADE;
DROP TABLE IF EXISTS cms_users CASCADE;

-- CATATAN: Cleanup data sosmed & kolom lama dipindah ke SETELAH
-- semua tabel dibuat (Section 2b) agar tidak error jika tabel belum ada.

-- ============================================================
-- 1. EXTENSION & HELPER FUNCTION
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Auto-create profile when a new auth user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, nama, role, aktif)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'nama', NEW.email),
        COALESCE(NEW.raw_user_meta_data->>'role', 'editor'),
        true
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 2. TABLES (IF NOT EXISTS — idempotent)
-- ============================================================

CREATE TABLE IF NOT EXISTS sliders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    judul TEXT NOT NULL,
    deskripsi TEXT DEFAULT '',
    foto_link TEXT DEFAULT '',
    urutan INTEGER DEFAULT 0,
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS tenaga_pendidik (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nama TEXT NOT NULL,
    foto_link TEXT DEFAULT '',
    jabatan TEXT DEFAULT '',
    bidang_studi TEXT DEFAULT '',
    urutan INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS sarana_prasarana (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nama TEXT NOT NULL,
    deskripsi TEXT DEFAULT '',
    foto_link TEXT DEFAULT '',
    kategori TEXT DEFAULT 'Umum',
    urutan INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS prestasi (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    judul TEXT NOT NULL,
    deskripsi TEXT DEFAULT '',
    peserta TEXT DEFAULT '',
    tahun INTEGER NOT NULL,
    tingkat TEXT DEFAULT 'Sekolah',
    foto_link TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS osis (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    periode TEXT NOT NULL,
    jabatan TEXT NOT NULL,
    nama TEXT NOT NULL,
    foto_link TEXT DEFAULT '',
    logo_link TEXT DEFAULT '',
    urutan INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS ospm (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    periode TEXT NOT NULL,
    jabatan TEXT NOT NULL,
    nama TEXT NOT NULL,
    foto_link TEXT DEFAULT '',
    logo_link TEXT DEFAULT '',
    urutan INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS ekstrakurikuler (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nama TEXT NOT NULL,
    deskripsi TEXT DEFAULT '',
    foto_link TEXT DEFAULT '',
    pembina TEXT DEFAULT '',
    jadwal TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS berita (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    judul TEXT NOT NULL,
    konten TEXT DEFAULT '',
    ringkasan TEXT DEFAULT '',
    foto_link TEXT DEFAULT '',
    penulis TEXT DEFAULT 'Admin',
    status TEXT DEFAULT 'draft',
    slug TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS galeri (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    judul TEXT NOT NULL,
    deskripsi TEXT DEFAULT '',
    foto_link TEXT NOT NULL DEFAULT '',
    kategori TEXT DEFAULT 'Umum',
    tanggal DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS info_psb (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    judul TEXT NOT NULL,
    konten TEXT DEFAULT '',
    syarat TEXT[] DEFAULT '{}',
    alur_pendaftaran TEXT DEFAULT '',
    biaya TEXT DEFAULT '',
    kontak TEXT DEFAULT '',
    tahun_ajaran TEXT DEFAULT '2025/2026',
    status_aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS testimoni (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nama TEXT NOT NULL,
    jabatan TEXT DEFAULT 'Siswa',
    konten TEXT NOT NULL,
    foto_link TEXT DEFAULT '',
    rating INTEGER DEFAULT 5 CHECK (rating >= 1 AND rating <= 5),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS agenda (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    judul TEXT NOT NULL,
    deskripsi TEXT DEFAULT '',
    tanggal_mulai TIMESTAMPTZ NOT NULL,
    tanggal_selesai TIMESTAMPTZ NOT NULL,
    lokasi TEXT DEFAULT '',
    foto_link TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS statistik_sekolah (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    label TEXT NOT NULL,
    nilai INTEGER NOT NULL DEFAULT 0,
    ikon TEXT DEFAULT 'fa-users',
    urutan INTEGER DEFAULT 0,
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS kelas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nama_kelas TEXT NOT NULL,
    tingkat INTEGER NOT NULL DEFAULT 10,
    urutan INTEGER DEFAULT 0,
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS jadwal_pelajaran (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    kelas_id UUID NOT NULL REFERENCES kelas(id) ON DELETE CASCADE,
    hari TEXT NOT NULL,
    jam_ke INTEGER NOT NULL DEFAULT 1,
    mata_pelajaran TEXT NOT NULL,
    guru TEXT DEFAULT '',
    jam_mulai TEXT DEFAULT '',
    jam_selesai TEXT DEFAULT '',
    urutan INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- CATATAN: Media sosial (Instagram, YouTube, TikTok) dan Google Maps
-- TIDAK disimpan di database — sudah di-hardcode di footer.js dan index.html
CREATE TABLE IF NOT EXISTS pengaturan_situs (
    key TEXT PRIMARY KEY,
    nilai TEXT DEFAULT '',
    kategori TEXT DEFAULT 'umum',
    deskripsi TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- profiles (untuk Supabase Auth — menggantikan cms_users)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT NOT NULL,
    nama TEXT DEFAULT '',
    role TEXT DEFAULT 'editor',
    aktif BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Tambah kolom logo_link jika belum ada (untuk migrasi dari schema lama)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'osis' AND column_name = 'logo_link'
    ) THEN
        ALTER TABLE osis ADD COLUMN logo_link TEXT DEFAULT '';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'ospm' AND column_name = 'logo_link'
    ) THEN
        ALTER TABLE ospm ADD COLUMN logo_link TEXT DEFAULT '';
    END IF;
END $$;

-- ============================================================
-- 2b. CLEANUP MIGRASI (setelah semua tabel dibuat)
-- ============================================================

-- Hapus data sosmed & maps dari pengaturan_situs jika ada dari schema lama
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pengaturan_situs') THEN
        DELETE FROM pengaturan_situs WHERE key IN (
            'instagram_url', 'youtube_url', 'tiktok_url', 'facebook_url',
            'google_maps_embed', 'struktur_link'
        );
    END IF;
END $$;

-- Hapus kolom lama yang tidak dipakai lagi dari osis/ospm
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'osis' AND column_name = 'struktur_link'
    ) THEN
        ALTER TABLE osis DROP COLUMN struktur_link;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'ospm' AND column_name = 'struktur_link'
    ) THEN
        ALTER TABLE ospm DROP COLUMN struktur_link;
    END IF;
END $$;

-- ============================================================
-- 3. TRIGGERS (DROP IF EXISTS lalu CREATE — idempotent)
-- ============================================================

-- Auth user trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Updated_at triggers (drop lalu create)
DROP TRIGGER IF EXISTS update_sliders_updated_at ON sliders;
CREATE TRIGGER update_sliders_updated_at BEFORE UPDATE ON sliders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_tenaga_pendidik_updated_at ON tenaga_pendidik;
CREATE TRIGGER update_tenaga_pendidik_updated_at BEFORE UPDATE ON tenaga_pendidik
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_sarana_prasarana_updated_at ON sarana_prasarana;
CREATE TRIGGER update_sarana_prasarana_updated_at BEFORE UPDATE ON sarana_prasarana
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_prestasi_updated_at ON prestasi;
CREATE TRIGGER update_prestasi_updated_at BEFORE UPDATE ON prestasi
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_osis_updated_at ON osis;
CREATE TRIGGER update_osis_updated_at BEFORE UPDATE ON osis
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_ospm_updated_at ON ospm;
CREATE TRIGGER update_ospm_updated_at BEFORE UPDATE ON ospm
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_ekstrakurikuler_updated_at ON ekstrakurikuler;
CREATE TRIGGER update_ekstrakurikuler_updated_at BEFORE UPDATE ON ekstrakurikuler
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_berita_updated_at ON berita;
CREATE TRIGGER update_berita_updated_at BEFORE UPDATE ON berita
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_galeri_updated_at ON galeri;
CREATE TRIGGER update_galeri_updated_at BEFORE UPDATE ON galeri
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_info_psb_updated_at ON info_psb;
CREATE TRIGGER update_info_psb_updated_at BEFORE UPDATE ON info_psb
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_testimoni_updated_at ON testimoni;
CREATE TRIGGER update_testimoni_updated_at BEFORE UPDATE ON testimoni
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_agenda_updated_at ON agenda;
CREATE TRIGGER update_agenda_updated_at BEFORE UPDATE ON agenda
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_statistik_sekolah_updated_at ON statistik_sekolah;
CREATE TRIGGER update_statistik_sekolah_updated_at BEFORE UPDATE ON statistik_sekolah
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_kelas_updated_at ON kelas;
CREATE TRIGGER update_kelas_updated_at BEFORE UPDATE ON kelas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_jadwal_pelajaran_updated_at ON jadwal_pelajaran;
CREATE TRIGGER update_jadwal_pelajaran_updated_at BEFORE UPDATE ON jadwal_pelajaran
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_pengaturan_situs_updated_at ON pengaturan_situs;
CREATE TRIGGER update_pengaturan_situs_updated_at BEFORE UPDATE ON pengaturan_situs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 4. INDEXES (IF NOT EXISTS — idempotent)
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_sliders_aktif_urutan ON sliders(aktif, urutan);
CREATE INDEX IF NOT EXISTS idx_pendidik_bidang ON tenaga_pendidik(bidang_studi);
CREATE INDEX IF NOT EXISTS idx_sarana_kategori ON sarana_prasarana(kategori);
CREATE INDEX IF NOT EXISTS idx_prestasi_tahun ON prestasi(tahun DESC);
CREATE INDEX IF NOT EXISTS idx_prestasi_tingkat ON prestasi(tingkat);
CREATE INDEX IF NOT EXISTS idx_osis_periode ON osis(periode);
CREATE INDEX IF NOT EXISTS idx_ospm_periode ON ospm(periode);
CREATE INDEX IF NOT EXISTS idx_ekstrakurikuler_nama ON ekstrakurikuler(nama);
CREATE INDEX IF NOT EXISTS idx_berita_slug ON berita(slug);
CREATE INDEX IF NOT EXISTS idx_berita_status ON berita(status);
CREATE INDEX IF NOT EXISTS idx_berita_created ON berita(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_galeri_kategori ON galeri(kategori);
CREATE INDEX IF NOT EXISTS idx_galeri_tanggal ON galeri(tanggal DESC);
CREATE INDEX IF NOT EXISTS idx_info_psb_tahun ON info_psb(tahun_ajaran);
CREATE INDEX IF NOT EXISTS idx_info_psb_aktif ON info_psb(status_aktif);
CREATE INDEX IF NOT EXISTS idx_testimoni_rating ON testimoni(rating);
CREATE INDEX IF NOT EXISTS idx_agenda_tanggal ON agenda(tanggal_mulai DESC);
CREATE INDEX IF NOT EXISTS idx_statistik_aktif_urutan ON statistik_sekolah(aktif, urutan);
CREATE INDEX IF NOT EXISTS idx_kelas_tingkat ON kelas(tingkat, urutan);
CREATE INDEX IF NOT EXISTS idx_jadwal_kelas_id ON jadwal_pelajaran(kelas_id);
CREATE INDEX IF NOT EXISTS idx_jadwal_hari ON jadwal_pelajaran(hari);
CREATE INDEX IF NOT EXISTS idx_pengaturan_kategori ON pengaturan_situs(kategori);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- Hapus index lama jika ada (dari schema sebelumnya)
DROP INDEX IF EXISTS idx_cms_username;
DROP INDEX IF EXISTS idx_statistik_aktif_urutan_old;

-- ============================================================
-- 5. ROW LEVEL SECURITY (idempotent)
-- ============================================================

ALTER TABLE sliders ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenaga_pendidik ENABLE ROW LEVEL SECURITY;
ALTER TABLE sarana_prasarana ENABLE ROW LEVEL SECURITY;
ALTER TABLE prestasi ENABLE ROW LEVEL SECURITY;
ALTER TABLE osis ENABLE ROW LEVEL SECURITY;
ALTER TABLE ospm ENABLE ROW LEVEL SECURITY;
ALTER TABLE ekstrakurikuler ENABLE ROW LEVEL SECURITY;
ALTER TABLE berita ENABLE ROW LEVEL SECURITY;
ALTER TABLE galeri ENABLE ROW LEVEL SECURITY;
ALTER TABLE info_psb ENABLE ROW LEVEL SECURITY;
ALTER TABLE testimoni ENABLE ROW LEVEL SECURITY;
ALTER TABLE agenda ENABLE ROW LEVEL SECURITY;
ALTER TABLE statistik_sekolah ENABLE ROW LEVEL SECURITY;
ALTER TABLE kelas ENABLE ROW LEVEL SECURITY;
ALTER TABLE jadwal_pelajaran ENABLE ROW LEVEL SECURITY;
ALTER TABLE pengaturan_situs ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Hapus RLS dari tabel lama jika ada
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'struktur_organisasi') THEN
        ALTER TABLE struktur_organisasi ENABLE ROW LEVEL SECURITY;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'cms_users') THEN
        ALTER TABLE cms_users ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- Hapus semua policy lama lalu buat baru (idempotent)
-- Pendekatan: DROP IF EXISTS untuk setiap policy, lalu CREATE

-- ===== Public read policies =====
DROP POLICY IF EXISTS "Public read sliders" ON sliders;
DROP POLICY IF EXISTS "Public read access" ON sliders;
CREATE POLICY "Public read sliders" ON sliders FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Public read tenaga_pendidik" ON tenaga_pendidik;
DROP POLICY IF EXISTS "Public read access" ON tenaga_pendidik;
CREATE POLICY "Public read tenaga_pendidik" ON tenaga_pendidik FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Public read sarana_prasarana" ON sarana_prasarana;
DROP POLICY IF EXISTS "Public read access" ON sarana_prasarana;
CREATE POLICY "Public read sarana_prasarana" ON sarana_prasarana FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Public read prestasi" ON prestasi;
DROP POLICY IF EXISTS "Public read access" ON prestasi;
CREATE POLICY "Public read prestasi" ON prestasi FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Public read osis" ON osis;
DROP POLICY IF EXISTS "Public read access" ON osis;
CREATE POLICY "Public read osis" ON osis FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Public read ospm" ON ospm;
DROP POLICY IF EXISTS "Public read access" ON ospm;
CREATE POLICY "Public read ospm" ON ospm FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Public read ekstrakurikuler" ON ekstrakurikuler;
DROP POLICY IF EXISTS "Public read access" ON ekstrakurikuler;
CREATE POLICY "Public read ekstrakurikuler" ON ekstrakurikuler FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Public read berita" ON berita;
DROP POLICY IF EXISTS "Public read access" ON berita;
CREATE POLICY "Public read berita" ON berita FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Public read galeri" ON galeri;
DROP POLICY IF EXISTS "Public read access" ON galeri;
CREATE POLICY "Public read galeri" ON galeri FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Public read info_psb" ON info_psb;
DROP POLICY IF EXISTS "Public read access" ON info_psb;
CREATE POLICY "Public read info_psb" ON info_psb FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Public read testimoni" ON testimoni;
DROP POLICY IF EXISTS "Public read access" ON testimoni;
CREATE POLICY "Public read testimoni" ON testimoni FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Public read agenda" ON agenda;
DROP POLICY IF EXISTS "Public read access" ON agenda;
CREATE POLICY "Public read agenda" ON agenda FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Public read statistik_sekolah" ON statistik_sekolah;
DROP POLICY IF EXISTS "Public read access" ON statistik_sekolah;
CREATE POLICY "Public read statistik_sekolah" ON statistik_sekolah FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Public read kelas" ON kelas;
DROP POLICY IF EXISTS "Public read access" ON kelas;
CREATE POLICY "Public read kelas" ON kelas FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Public read jadwal_pelajaran" ON jadwal_pelajaran;
DROP POLICY IF EXISTS "Public read access" ON jadwal_pelajaran;
CREATE POLICY "Public read jadwal_pelajaran" ON jadwal_pelajaran FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Public read pengaturan_situs" ON pengaturan_situs;
DROP POLICY IF EXISTS "Public read access" ON pengaturan_situs;
CREATE POLICY "Public read pengaturan_situs" ON pengaturan_situs FOR SELECT TO anon, authenticated USING (true);

-- ===== Profiles: only authenticated can read =====
DROP POLICY IF EXISTS "Authenticated read profiles" ON profiles;
DROP POLICY IF EXISTS "Authenticated read cms_users" ON profiles;
CREATE POLICY "Authenticated read profiles" ON profiles FOR SELECT TO authenticated USING (true);

-- ===== Authenticated insert policies =====
DROP POLICY IF EXISTS "Auth insert sliders" ON sliders;
DROP POLICY IF EXISTS "Authenticated insert" ON sliders;
CREATE POLICY "Auth insert sliders" ON sliders FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Auth insert tenaga_pendidik" ON tenaga_pendidik;
DROP POLICY IF EXISTS "Authenticated insert" ON tenaga_pendidik;
CREATE POLICY "Auth insert tenaga_pendidik" ON tenaga_pendidik FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Auth insert sarana_prasarana" ON sarana_prasarana;
DROP POLICY IF EXISTS "Authenticated insert" ON sarana_prasarana;
CREATE POLICY "Auth insert sarana_prasarana" ON sarana_prasarana FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Auth insert prestasi" ON prestasi;
DROP POLICY IF EXISTS "Authenticated insert" ON prestasi;
CREATE POLICY "Auth insert prestasi" ON prestasi FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Auth insert osis" ON osis;
DROP POLICY IF EXISTS "Authenticated insert" ON osis;
CREATE POLICY "Auth insert osis" ON osis FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Auth insert ospm" ON ospm;
DROP POLICY IF EXISTS "Authenticated insert" ON ospm;
CREATE POLICY "Auth insert ospm" ON ospm FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Auth insert ekstrakurikuler" ON ekstrakurikuler;
DROP POLICY IF EXISTS "Authenticated insert" ON ekstrakurikuler;
CREATE POLICY "Auth insert ekstrakurikuler" ON ekstrakurikuler FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Auth insert berita" ON berita;
DROP POLICY IF EXISTS "Authenticated insert" ON berita;
CREATE POLICY "Auth insert berita" ON berita FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Auth insert galeri" ON galeri;
DROP POLICY IF EXISTS "Authenticated insert" ON galeri;
CREATE POLICY "Auth insert galeri" ON galeri FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Auth insert info_psb" ON info_psb;
DROP POLICY IF EXISTS "Authenticated insert" ON info_psb;
CREATE POLICY "Auth insert info_psb" ON info_psb FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Auth insert testimoni" ON testimoni;
DROP POLICY IF EXISTS "Authenticated insert" ON testimoni;
CREATE POLICY "Auth insert testimoni" ON testimoni FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Auth insert agenda" ON agenda;
DROP POLICY IF EXISTS "Authenticated insert" ON agenda;
CREATE POLICY "Auth insert agenda" ON agenda FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Auth insert statistik_sekolah" ON statistik_sekolah;
DROP POLICY IF EXISTS "Authenticated insert" ON statistik_sekolah;
CREATE POLICY "Auth insert statistik_sekolah" ON statistik_sekolah FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Auth insert kelas" ON kelas;
DROP POLICY IF EXISTS "Authenticated insert" ON kelas;
CREATE POLICY "Auth insert kelas" ON kelas FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Auth insert jadwal_pelajaran" ON jadwal_pelajaran;
DROP POLICY IF EXISTS "Authenticated insert" ON jadwal_pelajaran;
CREATE POLICY "Auth insert jadwal_pelajaran" ON jadwal_pelajaran FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Auth insert pengaturan_situs" ON pengaturan_situs;
DROP POLICY IF EXISTS "Authenticated insert" ON pengaturan_situs;
CREATE POLICY "Auth insert pengaturan_situs" ON pengaturan_situs FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Auth insert profiles" ON profiles;
DROP POLICY IF EXISTS "Authenticated insert profiles" ON profiles;
CREATE POLICY "Auth insert profiles" ON profiles FOR INSERT TO authenticated WITH CHECK (true);

-- ===== Authenticated update policies =====
DROP POLICY IF EXISTS "Auth update sliders" ON sliders;
DROP POLICY IF EXISTS "Authenticated update" ON sliders;
CREATE POLICY "Auth update sliders" ON sliders FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Auth update tenaga_pendidik" ON tenaga_pendidik;
DROP POLICY IF EXISTS "Authenticated update" ON tenaga_pendidik;
CREATE POLICY "Auth update tenaga_pendidik" ON tenaga_pendidik FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Auth update sarana_prasarana" ON sarana_prasarana;
DROP POLICY IF EXISTS "Authenticated update" ON sarana_prasarana;
CREATE POLICY "Auth update sarana_prasarana" ON sarana_prasarana FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Auth update prestasi" ON prestasi;
DROP POLICY IF EXISTS "Authenticated update" ON prestasi;
CREATE POLICY "Auth update prestasi" ON prestasi FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Auth update osis" ON osis;
DROP POLICY IF EXISTS "Authenticated update" ON osis;
CREATE POLICY "Auth update osis" ON osis FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Auth update ospm" ON ospm;
DROP POLICY IF EXISTS "Authenticated update" ON ospm;
CREATE POLICY "Auth update ospm" ON ospm FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Auth update ekstrakurikuler" ON ekstrakurikuler;
DROP POLICY IF EXISTS "Authenticated update" ON ekstrakurikuler;
CREATE POLICY "Auth update ekstrakurikuler" ON ekstrakurikuler FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Auth update berita" ON berita;
DROP POLICY IF EXISTS "Authenticated update" ON berita;
CREATE POLICY "Auth update berita" ON berita FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Auth update galeri" ON galeri;
DROP POLICY IF EXISTS "Authenticated update" ON galeri;
CREATE POLICY "Auth update galeri" ON galeri FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Auth update info_psb" ON info_psb;
DROP POLICY IF EXISTS "Authenticated update" ON info_psb;
CREATE POLICY "Auth update info_psb" ON info_psb FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Auth update testimoni" ON testimoni;
DROP POLICY IF EXISTS "Authenticated update" ON testimoni;
CREATE POLICY "Auth update testimoni" ON testimoni FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Auth update agenda" ON agenda;
DROP POLICY IF EXISTS "Authenticated update" ON agenda;
CREATE POLICY "Auth update agenda" ON agenda FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Auth update statistik_sekolah" ON statistik_sekolah;
DROP POLICY IF EXISTS "Authenticated update" ON statistik_sekolah;
CREATE POLICY "Auth update statistik_sekolah" ON statistik_sekolah FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Auth update kelas" ON kelas;
DROP POLICY IF EXISTS "Authenticated update" ON kelas;
CREATE POLICY "Auth update kelas" ON kelas FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Auth update jadwal_pelajaran" ON jadwal_pelajaran;
DROP POLICY IF EXISTS "Authenticated update" ON jadwal_pelajaran;
CREATE POLICY "Auth update jadwal_pelajaran" ON jadwal_pelajaran FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Auth update pengaturan_situs" ON pengaturan_situs;
DROP POLICY IF EXISTS "Authenticated update" ON pengaturan_situs;
CREATE POLICY "Auth update pengaturan_situs" ON pengaturan_situs FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Auth update profiles" ON profiles;
DROP POLICY IF EXISTS "Authenticated update profiles" ON profiles;
CREATE POLICY "Auth update profiles" ON profiles FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- ===== Authenticated delete policies =====
DROP POLICY IF EXISTS "Auth delete sliders" ON sliders;
DROP POLICY IF EXISTS "Authenticated delete" ON sliders;
CREATE POLICY "Auth delete sliders" ON sliders FOR DELETE TO authenticated USING (true);

DROP POLICY IF EXISTS "Auth delete tenaga_pendidik" ON tenaga_pendidik;
DROP POLICY IF EXISTS "Authenticated delete" ON tenaga_pendidik;
CREATE POLICY "Auth delete tenaga_pendidik" ON tenaga_pendidik FOR DELETE TO authenticated USING (true);

DROP POLICY IF EXISTS "Auth delete sarana_prasarana" ON sarana_prasarana;
DROP POLICY IF EXISTS "Authenticated delete" ON sarana_prasarana;
CREATE POLICY "Auth delete sarana_prasarana" ON sarana_prasarana FOR DELETE TO authenticated USING (true);

DROP POLICY IF EXISTS "Auth delete prestasi" ON prestasi;
DROP POLICY IF EXISTS "Authenticated delete" ON prestasi;
CREATE POLICY "Auth delete prestasi" ON prestasi FOR DELETE TO authenticated USING (true);

DROP POLICY IF EXISTS "Auth delete osis" ON osis;
DROP POLICY IF EXISTS "Authenticated delete" ON osis;
CREATE POLICY "Auth delete osis" ON osis FOR DELETE TO authenticated USING (true);

DROP POLICY IF EXISTS "Auth delete ospm" ON ospm;
DROP POLICY IF EXISTS "Authenticated delete" ON ospm;
CREATE POLICY "Auth delete ospm" ON ospm FOR DELETE TO authenticated USING (true);

DROP POLICY IF EXISTS "Auth delete ekstrakurikuler" ON ekstrakurikuler;
DROP POLICY IF EXISTS "Authenticated delete" ON ekstrakurikuler;
CREATE POLICY "Auth delete ekstrakurikuler" ON ekstrakurikuler FOR DELETE TO authenticated USING (true);

DROP POLICY IF EXISTS "Auth delete berita" ON berita;
DROP POLICY IF EXISTS "Authenticated delete" ON berita;
CREATE POLICY "Auth delete berita" ON berita FOR DELETE TO authenticated USING (true);

DROP POLICY IF EXISTS "Auth delete galeri" ON galeri;
DROP POLICY IF EXISTS "Authenticated delete" ON galeri;
CREATE POLICY "Auth delete galeri" ON galeri FOR DELETE TO authenticated USING (true);

DROP POLICY IF EXISTS "Auth delete info_psb" ON info_psb;
DROP POLICY IF EXISTS "Authenticated delete" ON info_psb;
CREATE POLICY "Auth delete info_psb" ON info_psb FOR DELETE TO authenticated USING (true);

DROP POLICY IF EXISTS "Auth delete testimoni" ON testimoni;
DROP POLICY IF EXISTS "Authenticated delete" ON testimoni;
CREATE POLICY "Auth delete testimoni" ON testimoni FOR DELETE TO authenticated USING (true);

DROP POLICY IF EXISTS "Auth delete agenda" ON agenda;
DROP POLICY IF EXISTS "Authenticated delete" ON agenda;
CREATE POLICY "Auth delete agenda" ON agenda FOR DELETE TO authenticated USING (true);

DROP POLICY IF EXISTS "Auth delete statistik_sekolah" ON statistik_sekolah;
DROP POLICY IF EXISTS "Authenticated delete" ON statistik_sekolah;
CREATE POLICY "Auth delete statistik_sekolah" ON statistik_sekolah FOR DELETE TO authenticated USING (true);

DROP POLICY IF EXISTS "Auth delete kelas" ON kelas;
DROP POLICY IF EXISTS "Authenticated delete" ON kelas;
CREATE POLICY "Auth delete kelas" ON kelas FOR DELETE TO authenticated USING (true);

DROP POLICY IF EXISTS "Auth delete jadwal_pelajaran" ON jadwal_pelajaran;
DROP POLICY IF EXISTS "Authenticated delete" ON jadwal_pelajaran;
CREATE POLICY "Auth delete jadwal_pelajaran" ON jadwal_pelajaran FOR DELETE TO authenticated USING (true);

DROP POLICY IF EXISTS "Auth delete pengaturan_situs" ON pengaturan_situs;
DROP POLICY IF EXISTS "Authenticated delete" ON pengaturan_situs;
CREATE POLICY "Auth delete pengaturan_situs" ON pengaturan_situs FOR DELETE TO authenticated USING (true);

-- ============================================================
-- 6. GRANT PERMISSIONS
-- ============================================================

GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

-- ============================================================
-- 7. SAMPLE DATA (ON CONFLICT — idempotent)
-- ============================================================

-- sliders
INSERT INTO sliders (judul, deskripsi, foto_link, urutan, aktif) VALUES
    ('Selamat Datang di SMA Plus Almunawwarah', 'Membentuk Generasi Berilmu, Berakhlak, dan Berprestasi', 'https://drive.google.com/file/d/1SliderWelcome/view', 1, true),
    ('PPDB 2025/2026 Telah Dibuka!', 'Segera daftarkan putra-putri Anda. Kuota terbatas untuk 288 peserta didik baru.', 'https://drive.google.com/file/d/1SliderPPDB/view', 2, true),
    ('Unggul dalam Prestasi, Berkarakter Mulia', 'Raih prestasi akademik dan non-akademik bersama kami', 'https://drive.google.com/file/d/1SliderPrestasi/view', 3, true),
    ('Kurikulum Terpadu Islami', 'Menggabungkan kurikulum nasional dengan pendidikan keislaman yang komprehensif', 'https://drive.google.com/file/d/1SliderKurikulum/view', 4, true)
ON CONFLICT DO NOTHING;

-- tenaga_pendidik
INSERT INTO tenaga_pendidik (nama, foto_link, jabatan, bidang_studi, urutan) VALUES
    ('H. Muhammad Arif, M.Pd.I', 'https://drive.google.com/file/d/1PendidikArif/view', 'Guru Senior', 'Pendidikan Agama Islam', 1),
    ('Hj. Siti Aisyah, S.Pd', 'https://drive.google.com/file/d/1PendidikAisyah/view', 'Guru', 'Bahasa Indonesia', 2),
    ('Budi Santoso, S.Pd', 'https://drive.google.com/file/d/1PendidikBudi/view', 'Guru', 'Matematika', 3),
    ('Dewi Rahmawati, S.Pd', 'https://drive.google.com/file/d/1PendidikDewi/view', 'Guru', 'Bahasa Inggris', 4),
    ('Ir. Hendra Wijaya, M.Si', 'https://drive.google.com/file/d/1PendidikHendra/view', 'Guru', 'Fisika', 5),
    ('Rina Marlina, S.Si', 'https://drive.google.com/file/d/1PendidikRina/view', 'Guru', 'Kimia', 6),
    ('Sri Wahyuni, S.Pd', 'https://drive.google.com/file/d/1PendidikSri/view', 'Guru', 'Biologi', 7),
    ('Agus Setiawan, S.Pd', 'https://drive.google.com/file/d/1PendidikAgus/view', 'Guru', 'Seni Budaya', 8)
ON CONFLICT DO NOTHING;

-- sarana_prasarana
INSERT INTO sarana_prasarana (nama, deskripsi, foto_link, kategori, urutan) VALUES
    ('Ruang Kelas Ber-AC', '24 ruang kelas ber-AC dengan fasilitas proyektor dan papan tulis interaktif', 'https://drive.google.com/file/d/1SaranaRuangKelas/view', 'Ruang', 1),
    ('Laboratorium IPA', 'Laboratorium lengkap untuk praktikum Fisika, Kimia, dan Biologi dengan peralatan modern', 'https://drive.google.com/file/d/1SaranaLabIPA/view', 'Lab', 2),
    ('Laboratorium Komputer', 'Laboratorium komputer dengan 40 unit PC terkoneksi internet berkecepatan tinggi', 'https://drive.google.com/file/d/1SaranaLabKomputer/view', 'Lab', 3),
    ('Perpustakaan Digital', 'Perpustakaan modern dengan koleksi 10.000+ buku dan akses e-library', 'https://drive.google.com/file/d/1SaranaPerpus/view', 'Umum', 4),
    ('Masjid Al-Hikmah', 'Masjid dua lantai untuk kegiatan ibadah dan pembinaan spiritual siswa', 'https://drive.google.com/file/d/1SaranaMasjid/view', 'Ibadah', 5),
    ('Lapangan Olahraga', 'Lapangan multifungsi untuk futsal, basket, dan upacara bendera', 'https://drive.google.com/file/d/1SaranaLapangan/view', 'Lapangan', 6),
    ('Ruang OSIS dan OSPM', 'Ruang kegiatan organisasi siswa yang representatif dan nyaman', 'https://drive.google.com/file/d/1SaranaRuangOsis/view', 'Ruang', 7),
    ('Kantin Sehat', 'Kantin bersih dan sehat dengan beragam pilihan makanan bergizi', 'https://drive.google.com/file/d/1SaranaKantin/view', 'Umum', 8)
ON CONFLICT DO NOTHING;

-- prestasi
INSERT INTO prestasi (judul, deskripsi, peserta, tahun, tingkat, foto_link) VALUES
    ('Juara 1 Olimpiade Matematika', 'Siswa SMA Plus Almunawwarah meraih juara pertama dalam Olimpiade Matematika tingkat Kabupaten', 'Muhammad Rizki', 2025, 'Kabupaten', 'https://drive.google.com/file/d/1PrestasiOlimMat/view'),
    ('Juara 2 Lomba Pidato Bahasa Inggris', 'Meraih penghargaan kedua dalam lomba pidato bahasa Inggris antar SMA se-Provinsi', 'Aisyah Putri', 2024, 'Provinsi', 'https://drive.google.com/file/d/1PrestasiPidato/view'),
    ('Juara 1 Pramuka Tingkat Kecamatan', 'Pasukan penggalang meraih juara umum dalam lomba Pramuka tingkat Kecamatan', 'Tim Pramuka', 2025, 'Kecamatan', 'https://drive.google.com/file/d/1PrestasiPramuka/view'),
    ('Juara 3 Lomba Cerdas Cermat Agama', 'Tim cerdas cermat meraih juara ketiga di tingkat Nasional', 'Tim Cerdas Cermat', 2024, 'Nasional', 'https://drive.google.com/file/d/1PrestasiCerdasCermat/view'),
    ('Juara 1 Turnamen Futsal', 'Tim futsal meraih juara pertama dalam turnamen antar SMA se-Kabupaten', 'Tim Futsal', 2025, 'Kabupaten', 'https://drive.google.com/file/d/1PrestasiFutsal/view')
ON CONFLICT DO NOTHING;

-- osis
INSERT INTO osis (periode, jabatan, nama, foto_link, urutan) VALUES
    ('2025/2026', 'Ketua OSIS', 'Muhammad Farhan', 'https://drive.google.com/file/d/1OsisKetua/view', 1),
    ('2025/2026', 'Wakil Ketua OSIS', 'Aisyah Rahmah', 'https://drive.google.com/file/d/1OsisWakil/view', 2),
    ('2025/2026', 'Sekretaris', 'Rina Agustina', 'https://drive.google.com/file/d/1OsisSekretaris/view', 3),
    ('2025/2026', 'Bendahara', 'Dina Safitri', 'https://drive.google.com/file/d/1OsisBendahara/view', 4),
    ('2025/2026', 'Sie Kurikulum', 'Ahmad Rizal', 'https://drive.google.com/file/d/1OsisSieKur/view', 5),
    ('2025/2026', 'Sie Kesiswaan', 'Siti Nurhaliza', 'https://drive.google.com/file/d/1OsisSieKes/view', 6)
ON CONFLICT DO NOTHING;

-- ospm
INSERT INTO ospm (periode, jabatan, nama, foto_link, urutan) VALUES
    ('2025/2026', 'Ketua OSPM', 'Ilham Maulana', 'https://drive.google.com/file/d/1OspmKetua/view', 1),
    ('2025/2026', 'Wakil Ketua OSPM', 'Fatimah Zahra', 'https://drive.google.com/file/d/1OspmWakil/view', 2),
    ('2025/2026', 'Sekretaris', 'Nur Amalina', 'https://drive.google.com/file/d/1OspmSekretaris/view', 3),
    ('2025/2026', 'Bendahara', 'Muhammad Yusuf', 'https://drive.google.com/file/d/1OspmBendahara/view', 4),
    ('2025/2026', 'Sie Pendidikan', 'Zainab Husna', 'https://drive.google.com/file/d/1OspmSiePendidikan/view', 5)
ON CONFLICT DO NOTHING;

-- ekstrakurikuler
INSERT INTO ekstrakurikuler (nama, deskripsi, foto_link, pembina, jadwal) VALUES
    ('Pramuka', 'Kegiatan kepramukaan untuk membentuk karakter, kemandirian, dan jiwa kepemimpinan siswa', 'https://drive.google.com/file/d/1EksPramuka/view', 'Budi Santoso, S.Pd', 'Setiap Jumat, 14:00 - 16:00 WIB'),
    ('PMR', 'Palang Merah Remaja untuk melatih keterampilan pertolongan pertama dan kepedulian sosial', 'https://drive.google.com/file/d/1EksPmr/view', 'Sri Wahyuni, S.Pd', 'Setiap Sabtu, 08:00 - 10:00 WIB'),
    ('Paskibra', 'Pasukan Pengibar Bendera untuk melatih kedisiplinan dan kecintaan terhadap tanah air', 'https://drive.google.com/file/d/1EksPaskibra/view', 'Ir. Hendra Wijaya, M.Si', 'Setiap Rabu, 15:00 - 17:00 WIB'),
    ('English Club', 'Klub bahasa Inggris untuk meningkatkan kemampuan berkomunikasi dalam bahasa Inggris', 'https://drive.google.com/file/d/1EksEnglish/view', 'Dewi Rahmawati, S.Pd', 'Setiap Senin, 14:00 - 15:30 WIB'),
    ('Robotik', 'Ekskul robotik untuk mengasah kreativitas dan kemampuan teknologi informasi', 'https://drive.google.com/file/d/1EksRobotik/view', 'Ir. Hendra Wijaya, M.Si', 'Setiap Kamis, 14:00 - 16:00 WIB'),
    ('Tahfidz', 'Program menghafal Al-Quran untuk memperkuat iman dan pengetahuan agama', 'https://drive.google.com/file/d/1EksTahfidz/view', 'H. Muhammad Arif, M.Pd.I', 'Setiap Senin - Jumat, 06:30 - 07:30 WIB'),
    ('Seni Tari', 'Ekskul seni tari tradisional dan modern untuk melestarikan budaya bangsa', 'https://drive.google.com/file/d/1EksSeniTari/view', 'Agus Setiawan, S.Pd', 'Setiap Selasa, 14:00 - 16:00 WIB'),
    ('Pencak Silat', 'Latihan pencak silat untuk menjaga kebugaran dan ketahanan fisik siswa', 'https://drive.google.com/file/d/1EksSilat/view', 'Ahmad Fauzi, S.Pd', 'Setiap Sabtu, 09:00 - 11:00 WIB')
ON CONFLICT DO NOTHING;

-- berita
INSERT INTO berita (judul, konten, ringkasan, foto_link, penulis, status, slug) VALUES
    ('SMA Plus Almunawwarah Raih Akreditasi A', '<p>SMA Plus Almunawwarah dengan bangga mengumumkan bahwa sekolah kami telah berhasil meraih akreditasi A dari Badan Akreditasi Nasional Sekolah/Madrasah (BAN-S/M). Pencapaian ini merupakan hasil kerja keras seluruh civitas akademika dalam meningkatkan mutu pendidikan secara berkelanjutan.</p><p>Penilaian meliputi berbagai aspek mulai dari standar kompetensi lulusan, standar isi pembelajaran, standar proses, hingga standar pengelolaan. Dengan akreditasi A ini, SMA Plus Almunawwarah semakin mempertegas komitmennya sebagai lembaga pendidikan berkualitas.</p>', 'SMA Plus Almunawwarah berhasil meraih akreditasi A dari BAN-S/M, mempertegas komitmen sebagai lembaga pendidikan berkualitas.', 'https://drive.google.com/file/d/1BeritaAkreditasi/view', 'Admin', 'published', 'sma-plus-almunawwarah-raih-akreditasi-a'),
    ('Penerimaan Peserta Didik Baru Tahun Ajaran 2025/2026 Dibuka', '<p>SMA Plus Almunawwarah secara resmi membuka pendaftaran Peserta Didik Baru (PPDB) untuk tahun ajaran 2025/2026. Pendaftaran dibuka mulai tanggal 1 Maret 2025 dan akan ditutup pada 30 April 2025.</p><p>Calon peserta didik dapat mendaftar secara online melalui website resmi sekolah atau datang langsung ke panitia PPDB di sekolah. Kuota yang tersedia untuk tahun ajaran ini adalah 288 peserta didik yang terbagi dalam 8 rombongan belajar.</p>', 'PPDB tahun ajaran 2025/2026 resmi dibuka dengan kuota 288 peserta didik. Pendaftaran online dan offline tersedia.', 'https://drive.google.com/file/d/1BeritaPPDB/view', 'Admin', 'published', 'ppdb-tahun-ajaran-2025-2026-dibuka'),
    ('Siswa Berprestasi Ikuti Olimpiade Sains Nasional', '<p>Tiga siswa SMA Plus Almunawwarah berhasil lolos seleksi dan akan mewakili Provinsi dalam Olimpiade Sains Nasional (OSN) yang akan diselenggarakan bulan depan. Ketiga siswa tersebut adalah Muhammad Rizki (Matematika), Rina Agustina (Biologi), dan Ahmad Rizal (Fisika).</p><p>Kepala Sekolah H. Muhammad Arif, M.Pd.I menyampaikan kebanggaannya atas pencapaian siswa-siswinya. "Ini adalah bukti bahwa kerja keras dan pembinaan yang intensif membuahkan hasil," ujarnya.</p>', 'Tiga siswa SMA Plus Almunawwarah lolos seleksi OSN tingkat nasional dalam bidang Matematika, Biologi, dan Fisika.', 'https://drive.google.com/file/d/1BeritaOSN/view', 'Admin', 'published', 'siswa-berprestasi-ikuti-olimpiade-sains-nasional')
ON CONFLICT DO NOTHING;

-- galeri
INSERT INTO galeri (judul, deskripsi, foto_link, kategori, tanggal) VALUES
    ('Upacara Bendera', 'Dokumentasi upacara bendera hari Senin rutin di lapangan sekolah', 'https://drive.google.com/file/d/1GaleriUpacara/view', 'Kegiatan', '2025-02-03'),
    ('Pembelajaran di Laboratorium', 'Siswa melakukan praktikum di laboratorium IPA', 'https://drive.google.com/file/d/1GaleriLab/view', 'Akademik', '2025-01-20'),
    ('Kegiatan Pramuka', 'Pasukan penggalang dalam kegiatan perkemahan', 'https://drive.google.com/file/d/1GaleriPramuka/view', 'Ekstrakurikuler', '2025-01-15'),
    ('Masjid Al-Hikmah', 'Masjid dua lantai sebagai pusat kegiatan keagamaan siswa', 'https://drive.google.com/file/d/1GaleriMasjid/view', 'Fasilitas', '2025-01-10'),
    ('Wisuda Kelas XII', 'Acara wisuda dan pelepasan siswa kelas XII tahun ajaran 2024/2025', 'https://drive.google.com/file/d/1GaleriWisuda/view', 'Kegiatan', '2025-01-05'),
    ('Perpustakaan Digital', 'Siswa membaca dan belajar di perpustakaan digital sekolah', 'https://drive.google.com/file/d/1GaleriPerpus/view', 'Fasilitas', '2024-12-18')
ON CONFLICT DO NOTHING;

-- info_psb
INSERT INTO info_psb (judul, konten, syarat, alur_pendaftaran, biaya, kontak, tahun_ajaran, status_aktif) VALUES
    ('Penerimaan Peserta Didik Baru 2025/2026', '<p>SMA Plus Almunawwarah membuka pendaftaran peserta didik baru untuk tahun ajaran 2025/2026. Kami mengundang putra-putri terbaik untuk bergabung menjadi bagian dari keluarga besar SMA Plus Almunawwarah.</p><p>Program unggulan yang kami tawarkan meliputi kelas reguler, kelas tahfidz, dan kelas bilingual. Sistem pendidikan kami mengintegrasikan kurikulum nasional dengan pendidikan karakter berbasis Islam.</p>', ARRAY['Lulusan SMP/MTs sederajat', 'Raport semester 1-5 dengan rata-rata minimal 75', 'Sertifikat prestasi (jika ada)', 'Surat keterangan sehat dari dokter', 'Pas foto 3x4 berwarna (4 lembar)', 'Fotokopi Akta Kelahiran', 'Fotokopi Kartu Keluarga'], '1. Pendaftaran online/offline -> 2. Verifikasi berkas -> 3. Tes akademik dan wawancara -> 4. Pengumuman hasil -> 5. Daftar ulang', 'Dana pendidikan tahunan Rp 3.500.000 (dapat dicicil 2 kali). Biaya seragam dan buku terpisah.', 'Panitia PPDB: 0812-3456-7890 / 0856-7890-1234. Email: ppdb@sma-almunawwarah.sch.id', '2025/2026', true)
ON CONFLICT DO NOTHING;

-- testimoni
INSERT INTO testimoni (nama, jabatan, konten, foto_link, rating) VALUES
    ('Muhammad Rizki', 'Siswa Kelas XII MIPA 1', 'Belajar di SMA Plus Almunawwarah adalah pengalaman yang sangat berharga. Guru-guru yang kompeten dan lingkungan yang islami membuat saya bisa berkembang baik secara akademik maupun karakter.', 'https://drive.google.com/file/d/1TestiRizki/view', 5),
    ('Hj. Siti Aminah', 'Orang Tua Siswa', 'Sebagai orang tua, saya sangat bersyukur anak saya bersekolah di sini. Pembinaan karakter dan akademik berjalan seimbang. Anak saya semakin rajin beribadah dan nilainya juga memuaskan.', 'https://drive.google.com/file/d/1TestiOrtu/view', 5),
    ('Aisyah Rahmah', 'Alumni Angkatan 2024', 'SMA Plus Almunawwarah membentuk saya menjadi pribadi yang lebih percaya diri dan bertanggung jawab. Pengalaman organisasi di OSIS sangat berpengaruh pada perkembangan diri saya.', 'https://drive.google.com/file/d/1TestiAlumni/view', 5)
ON CONFLICT DO NOTHING;

-- agenda
INSERT INTO agenda (judul, deskripsi, tanggal_mulai, tanggal_selesai, lokasi, foto_link) VALUES
    ('Ujian Tengah Semester Genap', 'Pelaksanaan UTS semester genap tahun ajaran 2025/2026 untuk seluruh kelas', '2026-03-09 07:30:00+07', '2026-03-14 12:00:00+07', 'Ruang Kelas SMA Plus Almunawwarah', 'https://drive.google.com/file/d/1AgendaUTS/view'),
    ('Peringatan Isra Mikraj', 'Acara peringatan Isra Mikraj Nabi Muhammad SAW dengan ceramah dan doa bersama', '2025-01-27 08:00:00+07', '2025-01-27 11:00:00+07', 'Masjid Al-Hikmah SMA Plus Almunawwarah', 'https://drive.google.com/file/d/1AgendaIsra/view'),
    ('Lomba 17 Agustus', 'Rangkaian lomba memperingati Hari Kemerdekaan RI ke-80 antar kelas', '2025-08-16 08:00:00+07', '2025-08-17 15:00:00+07', 'Lapangan SMA Plus Almunawwarah', 'https://drive.google.com/file/d/1Agenda17Agustus/view'),
    ('Study Tour Kelas XI', 'Kunjungan edukatif ke museum dan tempat bersejarah untuk siswa kelas XI', '2025-10-20 06:00:00+07', '2025-10-21 18:00:00+07', 'Museum Nasional dan Taman Mini Indonesia Indah', 'https://drive.google.com/file/d/1AgendaStudyTour/view'),
    ('Wisuda Kelas XII', 'Acara wisuda dan pelepasan siswa kelas XII tahun ajaran 2025/2026', '2026-05-23 08:00:00+07', '2026-05-23 13:00:00+07', 'Aula SMA Plus Almunawwarah', 'https://drive.google.com/file/d/1AgendaWisuda/view')
ON CONFLICT DO NOTHING;

-- statistik_sekolah
INSERT INTO statistik_sekolah (label, nilai, ikon, urutan, aktif) VALUES
    ('Siswa', 288, 'fa-user-graduate', 1, true),
    ('Guru', 24, 'fa-chalkboard-user', 2, true),
    ('15+ Tahun', 15, 'fa-clock', 3, true),
    ('Prestasi', 45, 'fa-trophy', 4, true)
ON CONFLICT DO NOTHING;

-- kelas
INSERT INTO kelas (nama_kelas, tingkat, urutan, aktif) VALUES
    ('X A', 10, 1, true),
    ('X B', 10, 2, true),
    ('XI A', 11, 3, true),
    ('XI B', 11, 4, true),
    ('XII A', 12, 5, true),
    ('XII B', 12, 6, true)
ON CONFLICT DO NOTHING;

-- jadwal_pelajaran (contoh untuk X A — skip jika kelas belum ada)
INSERT INTO jadwal_pelajaran (kelas_id, hari, jam_ke, mata_pelajaran, guru, jam_mulai, jam_selesai, urutan)
SELECT k.id, t.hari, t.jam_ke, t.mata_pelajaran, t.guru, t.jam_mulai, t.jam_selesai, t.urutan
FROM kelas k
CROSS JOIN (VALUES
    ('Senin', 1, 'Pendidikan Agama Islam', 'H. Muhammad Arif, M.Pd.I', '07:00', '07:45', 1),
    ('Senin', 2, 'Al-Quran & Hadits', 'H. Muhammad Arif, M.Pd.I', '07:45', '08:30', 2),
    ('Senin', 3, 'Matematika', 'Budi Santoso, S.Pd', '08:45', '09:30', 3),
    ('Senin', 4, 'Bahasa Indonesia', 'Hj. Siti Aisyah, S.Pd', '09:30', '10:15', 4),
    ('Senin', 5, 'Fisika', 'Ir. Hendra Wijaya, M.Si', '10:30', '11:15', 5),
    ('Selasa', 1, 'Bahasa Inggris', 'Dewi Rahmawati, S.Pd', '07:00', '07:45', 6),
    ('Selasa', 2, 'Kimia', 'Rina Marlina, S.Si', '07:45', '08:30', 7),
    ('Selasa', 3, 'Biologi', 'Sri Wahyuni, S.Pd', '08:45', '09:30', 8),
    ('Selasa', 4, 'Sejarah', 'Ahmad Fauzi, S.Pd', '09:30', '10:15', 9),
    ('Selasa', 5, 'Seni Budaya', 'Agus Setiawan, S.Pd', '10:30', '11:15', 10),
    ('Rabu', 1, 'Matematika', 'Budi Santoso, S.Pd', '07:00', '07:45', 11),
    ('Rabu', 2, 'Pendidikan Agama Islam', 'H. Muhammad Arif, M.Pd.I', '07:45', '08:30', 12),
    ('Rabu', 3, 'PJOK', 'Ahmad Fauzi, S.Pd', '08:45', '09:30', 13),
    ('Rabu', 4, 'IPS', 'Nurul Hidayah, M.Pd', '09:30', '10:15', 14),
    ('Rabu', 5, 'Bahasa Inggris', 'Dewi Rahmawati, S.Pd', '10:30', '11:15', 15),
    ('Kamis', 1, 'Fisika', 'Ir. Hendra Wijaya, M.Si', '07:00', '07:45', 16),
    ('Kamis', 2, 'Al-Quran & Hadits', 'H. Muhammad Arif, M.Pd.I', '07:45', '08:30', 17),
    ('Kamis', 3, 'Bahasa Indonesia', 'Hj. Siti Aisyah, S.Pd', '08:45', '09:30', 18),
    ('Kamis', 4, 'Kimia', 'Rina Marlina, S.Si', '09:30', '10:15', 19),
    ('Kamis', 5, 'Pramuka', 'Budi Santoso, S.Pd', '10:30', '11:15', 20),
    ('Jumat', 1, 'Biologi', 'Sri Wahyuni, S.Pd', '07:00', '07:45', 21),
    ('Jumat', 2, 'Matematika', 'Budi Santoso, S.Pd', '07:45', '08:30', 22),
    ('Jumat', 3, 'Pendidikan Agama Islam', 'H. Muhammad Arif, M.Pd.I', '08:45', '09:30', 23),
    ('Jumat', 4, 'Seni Budaya', 'Agus Setiawan, S.Pd', '09:30', '10:15', 24),
    ('Jumat', 5, 'PJOK', 'Ahmad Fauzi, S.Pd', '10:30', '11:15', 25)
) AS t(hari, jam_ke, mata_pelajaran, guru, jam_mulai, jam_selesai, urutan)
WHERE k.nama_kelas = 'X A'
ON CONFLICT DO NOTHING;

-- pengaturan_situs (ON CONFLICT UPDATE — idempotent)
-- CATATAN: Instagram, YouTube, TikTok, dan Google Maps TIDAK di DB (hardcode)
INSERT INTO pengaturan_situs (key, nilai, kategori, deskripsi) VALUES
    ('gambar_struktur_organisasi', '', 'gambar', 'URL gambar struktur organisasi sekolah (upload gambar full, bukan data individual)'),
    ('nama_sekolah', 'SMA Plus Almunawwarah', 'umum', 'Nama resmi sekolah'),
    ('tagline_sekolah', 'Boarding School Islami', 'umum', 'Tagline sekolah'),
    ('telepon_sekolah', '(0481) 123456', 'kontak', 'Nomor telepon sekolah'),
    ('email_sekolah', 'info@smaplus-almunawwarah.sch.id', 'kontak', 'Email sekolah'),
    ('alamat_sekolah', 'Jl. Raya Almunawwarah No. 1, Kabupaten Bone, Sulawesi Selatan 92713', 'kontak', 'Alamat lengkap sekolah'),
    ('wa_sekolah', '6212345678', 'kontak', 'Nomor WhatsApp sekolah (tanpa +, format internasional)'),
    ('link_psb', '#', 'pendaftaran', 'URL formulir pendaftaran siswa baru')
ON CONFLICT (key) DO UPDATE SET
    nilai = EXCLUDED.nilai,
    kategori = EXCLUDED.kategori,
    deskripsi = EXCLUDED.deskripsi;

-- ============================================================
-- 8. SUPABASE AUTH - ADMIN ACCOUNT SETUP
-- ============================================================
--
-- PENTING: Akun admin harus dibuat melalui Supabase Dashboard
-- (Authentication > Users > Add User) atau via Supabase Auth API,
-- BUKAN via SQL INSERT ke auth.users.
--
-- Langkah-langkah membuat akun admin:
-- 1. Buka Supabase Dashboard > Authentication > Users
-- 2. Klik "Add User" > "Create New User"
-- 3. Email: admin@elmuna.com
-- 4. Password: Almunawwarah#29
-- 5. Centang "Auto Confirm User"
-- 6. Klik "Create User"
--
-- Setelah user dibuat, trigger handle_new_user akan otomatis
-- membuat profile dengan role 'editor'. Jalankan SQL berikut
-- di SQL Editor untuk mengubah role menjadi 'admin':
--
-- UPDATE public.profiles
-- SET role = 'admin', nama = 'Administrator'
-- WHERE email = 'admin@elmuna.com';
--
-- ============================================================
