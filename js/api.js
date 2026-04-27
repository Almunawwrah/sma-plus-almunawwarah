/**
 * api.js — File terpusat untuk konfigurasi database, cache, dan utilitas
 * Website SMA Plus Almunawwarah
 * Menggunakan Supabase JS SDK v2 via CDN
 */

// ============================================================
// 1) KONFIGURASI SUPABASE
// ============================================================

/**
 * @const {string} URL proyek Supabase
 * ⚠️ WAJIB GANTI dengan URL proyek Supabase Anda!
 * Contoh: 'https://abcdefghijk.supabase.co'
 * Dapatkan dari: Supabase Dashboard → Settings → API → Project URL
 */
const SUPABASE_URL = 'https://pnokbrxzwvbbytxdoxpq.supabase.co';

/**
 * @const {string} Kunci anonimus (public) Supabase
 * ⚠️ WAJIB GANTI dengan anon key proyek Supabase Anda!
 * Dapatkan dari: Supabase Dashboard → Settings → API → Project API keys → anon public
 */
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBub2ticnh6d3ZiYnl0eGRveHBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcyNTEyMjIsImV4cCI6MjA5MjgyNzIyMn0.fQefx0mxPJ2kzqF_rEJE1AdNIbHmpQqVM7oyfU8YnXs';

/**
 * @const {string} Kunci service role Supabase (hanya untuk CMS / admin)
 * ⚠️ WAJIB GANTI dengan service_role key proyek Supabase Anda!
 * Dapatkan dari: Supabase Dashboard → Settings → API → Project API keys → service_role
 */
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBub2ticnh6d3ZiYnl0eGRveHBxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NzI1MTIyMiwiZXhwIjoyMDkyODI3MjIyfQ.wYMYZ3RZ-gMfn6Qmn5YjQLc5lIfjEaHG8OXHNZylCVM';

/**
 * Inisialisasi lazy client Supabase.
 * Menunggu hingga CDN Supabase JS SDK tersedia di window.supabase
 * sebelum membuat instance klien.
 *
 * @param {number} [maxRetries=20] - Jumlah percobaan ulang maksimal
 * @param {number} [interval=250] - Jeda antar percobaan (ms)
 * @returns {Promise<SupabaseClient>} Instance SupabaseClient
 */
async function getSupabaseClient(maxRetries = 20, interval = 250) {
  // Jika sudah pernah diinisialisasi, kembalikan instance yang sama
  if (getSupabaseClient._instance) {
    return getSupabaseClient._instance;
  }

  // Periksa apakah URL Supabase sudah dikonfigurasi
  if (!SUPABASE_URL || SUPABASE_URL === 'YOUR_SUPABASE_URL' || !SUPABASE_URL.startsWith('https://')) {
    console.error(
      '⛔ SUPABASE_URL belum dikonfigurasi!\n' +
      'Buka file js/api.js dan ganti YOUR_SUPABASE_URL dengan URL proyek Supabase Anda.\n' +
      'Dapatkan URL dari: Supabase Dashboard → Settings → API → Project URL'
    );
    throw new Error(
      'Supabase belum dikonfigurasi. Silakan ganti YOUR_SUPABASE_URL dan YOUR_SUPABASE_ANON_KEY di file js/api.js sesuai proyek Supabase Anda. '
    );
  }

  if (!SUPABASE_ANON_KEY || SUPABASE_ANON_KEY === 'YOUR_SUPABASE_ANON_KEY') {
    console.error(
      '⛔ SUPABASE_ANON_KEY belum dikonfigurasi!\n' +
      'Buka file js/api.js dan ganti YOUR_SUPABASE_ANON_KEY dengan anon key proyek Supabase Anda.\n' +
      'Dapatkan key dari: Supabase Dashboard → Settings → API → Project API keys → anon public'
    );
    throw new Error(
      'Supabase ANON KEY belum dikonfigurasi. Silakan ganti YOUR_SUPABASE_ANON_KEY di file js/api.js.'
    );
  }

  // Tunggu hingga window.supabase tersedia (CDN dimuat)
  let retries = 0;
  while (!window.supabase && retries < maxRetries) {
    await new Promise(resolve => setTimeout(resolve, interval));
    retries++;
  }

  if (!window.supabase) {
    throw new Error('Supabase JS SDK tidak ditemukan. Pastikan CDN telah dimuat.');
  }

  // Buat instance klien menggunakan createClient dari SDK
  getSupabaseClient._instance = window.supabase.createClient(
    SUPABASE_URL,
    SUPABASE_ANON_KEY
  );

  return getSupabaseClient._instance;
}

/** Simpan instance agar tidak dibuat ulang */
getSupabaseClient._instance = null;

// ============================================================
// 2) SISTEM CACHE (localStorage)
// ============================================================

/** @const {string} Prefix untuk key cache di localStorage */
const CACHE_PREFIX = 'smaplus_';

/** @const {number} Durasi TTL default cache (30 menit dalam milidetik) */
const CACHE_DEFAULT_TTL = 30 * 60 * 1000;

/**
 * Mengambil data dari cache localStorage.
 * Mengembalikan null jika data tidak ditemukan atau sudah kedaluwarsa.
 *
 * @param {string} key - Kunci cache (tanpa prefix)
 * @returns {any|null} Data yang di-cache, atau null jika tidak valid
 */
function getCachedData(key) {
  try {
    const raw = localStorage.getItem(CACHE_PREFIX + key);
    if (!raw) return null;

    const parsed = JSON.parse(raw);

    // Periksa apakah data sudah kedaluwarsa
    if (parsed._expiry && Date.now() > parsed._expiry) {
      localStorage.removeItem(CACHE_PREFIX + key);
      return null;
    }

    return parsed._data;
  } catch {
    // Jika parsing gagal, hapus entry yang rusak
    localStorage.removeItem(CACHE_PREFIX + key);
    return null;
  }
}

/**
 * Menyimpan data ke cache localStorage dengan durasi TTL tertentu.
 *
 * @param {string} key - Kunci cache (tanpa prefix)
 * @param {any} data - Data yang akan di-cache
 * @param {number} [duration=CACHE_DEFAULT_TTL] - Durasi TTL dalam milidetik
 */
function setCachedData(key, data, duration = CACHE_DEFAULT_TTL) {
  try {
    const entry = {
      _data: data,
      _expiry: Date.now() + duration,
    };
    localStorage.setItem(CACHE_PREFIX + key, JSON.stringify(entry));
  } catch {
    // localStorage penuh atau tidak tersedia — abaikan secara diam-diam
    console.warn(`Gagal menyimpan cache untuk key "${key}".`);
  }
}

/**
 * Menghapus data dari cache.
 * Jika key diberikan, hanya key tersebut yang dihapus.
 * Jika tanpa key, semua cache dengan prefix akan dihapus.
 *
 * @param {string} [key] - Kunci cache yang dihapus (opsional)
 */
function clearCache(key) {
  if (key) {
    localStorage.removeItem(CACHE_PREFIX + key);
    return;
  }

  // Hapus semua item dengan prefix smaplus_
  const keysToRemove = [];
  for (let i = 0; i < localStorage.length; i++) {
    const k = localStorage.key(i);
    if (k && k.startsWith(CACHE_PREFIX)) {
      keysToRemove.push(k);
    }
  }
  keysToRemove.forEach(k => localStorage.removeItem(k));
}

// ============================================================
// 3) FUNGSI FETCH GENERIK
// ============================================================

/**
 * Mengambil data dari tabel Supabase dengan opsi fleksibel.
 * Hasilnya otomatis di-cache ke localStorage.
 *
 * @param {string} table - Nama tabel di Supabase
 * @param {Object} [opts={}] - Opsi query
 * @param {string}       [opts.select]       - Kolom yang dipilih (default '*')
 * @param {Object}       [opts.filter]       - Filter { key, value }
 * @param {Object}       [opts.order]        - Pengurutan { column, asc }
 * @param {Object}       [opts.range]        - Rentang baris { from, to }
 * @param {number}       [opts.limit]        - Batas jumlah baris
 * @param {boolean}      [opts.single]       - Jika true, kembalikan satu objek
 * @returns {Promise<Array|Object|null>} Data hasil query
 */
async function fetchFromTable(table, opts = {}) {
  const {
    select = '*',
    filter,
    order,
    range,
    limit,
    single = false,
  } = opts;

  // Buat kunci cache unik berdasarkan tabel dan opsi
  const cacheKey = `${table}:${JSON.stringify(opts)}`;

  // Cek cache terlebih dahulu
  const cached = getCachedData(cacheKey);
  if (cached !== null) {
    return cached;
  }

  try {
    const client = await getSupabaseClient();
    let query = client.from(table).select(select);

    // Terapkan filter
    if (filter) {
      query = query.eq(filter.key, filter.value);
    }

    // Terapkan pengurutan
    if (order) {
      query = query.order(order.column, { ascending: order.asc });
    }

    // Terapkan rentang baris
    if (range) {
      query = query.range(range.from, range.to);
    }

    // Terapkan batas jumlah
    if (limit) {
      query = query.limit(limit);
    }

    // Jika single, ambil satu baris
    if (single) {
      query = query.single();
    }

    const { data, error } = await query;

    if (error) {
      console.error(`Error fetchFromTable("${table}"):`, error.message);
      return single ? null : [];
    }

    // Simpan ke cache
    setCachedData(cacheKey, data);

    return data;
  } catch (err) {
    console.error(`Gagal mengambil data dari tabel "${table}":`, err);
    return single ? null : [];
  }
}

// ============================================================
// 4) OBJEK SMAPlusAPI — Method Data Sekolah
// ============================================================

const SMAPlusAPI = {
  /**
   * Mengambil URL gambar Struktur Organisasi Sekolah
   * Gambar disimpan di pengaturan_situs key='gambar_struktur_organisasi'
   * @returns {Promise<string>} URL gambar struktur organisasi
   */
  async fetchGambarStrukturOrganisasi() {
    const result = await fetchFromTable('pengaturan_situs', {
      filter: { key: 'key', value: 'gambar_struktur_organisasi' },
      single: true,
      select: 'nilai',
    });
    return result?.nilai || '';
  },

  /**
   * Mengambil URL gambar Struktur Organisasi OSIS
   * Gambar disimpan di pengaturan_situs key='gambar_struktur_osis'
   * @returns {Promise<string>} URL gambar struktur OSIS
   */
  async fetchGambarStrukturOsis() {
    const result = await fetchFromTable('pengaturan_situs', {
      filter: { key: 'key', value: 'gambar_struktur_osis' },
      single: true,
      select: 'nilai',
    });
    return result?.nilai || '';
  },

  /**
   * Mengambil URL gambar Struktur Organisasi OSPM
   * Gambar disimpan di pengaturan_situs key='gambar_struktur_ospm'
   * @returns {Promise<string>} URL gambar struktur OSPM
   */
  async fetchGambarStrukturOspm() {
    const result = await fetchFromTable('pengaturan_situs', {
      filter: { key: 'key', value: 'gambar_struktur_ospm' },
      single: true,
      select: 'nilai',
    });
    return result?.nilai || '';
  },

  /**
   * Mengambil data Tenaga Pendidik (guru & staf)
   * @returns {Promise<Array>} Daftar tenaga pendidik
   */
  fetchTenagaPendidik() {
    return fetchFromTable('tenaga_pendidik', {
      order: { column: 'urutan', asc: true },
    });
  },

  /**
   * Mengambil data Sarana & Prasarana
   * @param {string} [kategori] - Filter berdasarkan kategori (opsional)
   * @returns {Promise<Array>} Daftar sarana prasarana
   */
  fetchSaranaPrasarana(kategori) {
    const opts = {
      order: { column: 'urutan', asc: true },
    };
    if (kategori) {
      opts.filter = { key: 'kategori', value: kategori };
    }
    return fetchFromTable('sarana_prasarana', opts);
  },

  /**
   * Mengambil data Prestasi sekolah
   * @returns {Promise<Array>} Daftar prestasi (terbaru dulu)
   */
  fetchPrestasi() {
    return fetchFromTable('prestasi', {
      order: { column: 'tahun', asc: false },
    });
  },

  // CATATAN: fetchOsis() & fetchOspm() dihapus karena tabel osis/ospm sudah tidak ada.
  // Gunakan fetchGambarStrukturOsis() dan fetchGambarStrukturOspm() untuk mengambil
  // gambar struktur organisasi dari pengaturan_situs.

  /**
   * Mengambil data Ekstrakurikuler
   * @returns {Promise<Array>} Daftar ekstrakurikuler
   */
  fetchEkstrakurikuler() {
    return fetchFromTable('ekstrakurikuler', {});
  },

  /**
   * Mengambil daftar berita yang sudah dipublikasikan
   * @returns {Promise<Array>} Daftar berita (terbaru dulu)
   */
  fetchBerita() {
    return fetchFromTable('berita', {
      filter: { key: 'status', value: 'published' },
      order: { column: 'created_at', asc: false },
    });
  },

  /**
   * Mengambil satu berita berdasarkan slug
   * @param {string} slug - Slug berita
   * @returns {Promise<Object|null>} Data berita atau null
   */
  fetchBeritaBySlug(slug) {
    return fetchFromTable('berita', {
      filter: { key: 'slug', value: slug },
      single: true,
    });
  },

  /**
   * Mengambil berita terbaru
   * @param {number} [limit=3] - Jumlah berita yang diambil
   * @returns {Promise<Array>} Daftar berita terbaru
   */
  fetchBeritaTerbaru(limit = 3) {
    return fetchFromTable('berita', {
      filter: { key: 'status', value: 'published' },
      order: { column: 'created_at', asc: false },
      limit,
    });
  },

  /**
   * Mengambil data galeri
   * @param {string} [kategori] - Filter berdasarkan kategori (opsional)
   * @param {number} [limit] - Batas jumlah yang diambil (opsional)
   * @returns {Promise<Array>} Daftar galeri
   */
  fetchGaleri(kategori, limit) {
    const opts = {
      order: { column: 'tanggal', asc: false },
    };
    if (kategori) {
      opts.filter = { key: 'kategori', value: kategori };
    }
    if (limit) {
      opts.limit = limit;
    }
    return fetchFromTable('galeri', opts);
  },

  /**
   * Mengambil informasi PSB (Penerimaan Siswa Baru) yang masih aktif
   * @returns {Promise<Array>} Daftar info PSB aktif
   */
  fetchInfoPSB() {
    return fetchFromTable('info_psb', {
      filter: { key: 'status_aktif', value: true },
    });
  },

  /**
   * Mengambil daftar agenda kegiatan sekolah
   * @returns {Promise<Array>} Daftar agenda (10 terdekat)
   */
  fetchAgenda() {
    return fetchFromTable('agenda', {
      order: { column: 'tanggal_mulai', asc: true },
      limit: 10,
    });
  },

  /**
   * Mengambil data slider gambar yang aktif
   * @returns {Promise<Array>} Daftar slider
   */
  fetchSliders() {
    return fetchFromTable('sliders', {
      filter: { key: 'aktif', value: true },
      order: { column: 'urutan', asc: true },
    });
  },

  /**
   * Mengambil data testimoni
   * @returns {Promise<Array>} Daftar testimoni (rating tertinggi dulu)
   */
  fetchTestimoni() {
    return fetchFromTable('testimoni', {
      order: { column: 'rating', asc: false },
    });
  },

  /**
   * Mengambil data statistik sekolah yang aktif
   * @returns {Promise<Array>} Daftar statistik sekolah
   */
  fetchStatistikSekolah() {
    return fetchFromTable('statistik_sekolah', {
      filter: { key: 'aktif', value: true },
      order: { column: 'urutan', asc: true },
    });
  },

  /**
   * Mengambil data kelas yang aktif
   * @returns {Promise<Array>} Daftar kelas
   */
  fetchKelas() {
    return fetchFromTable('kelas', {
      filter: { key: 'aktif', value: true },
      order: { column: 'urutan', asc: true },
    });
  },

  /**
   * Mengambil jadwal pelajaran berdasarkan kelas
   * @param {string} kelasId - ID kelas
   * @returns {Promise<Array>} Daftar jadwal pelajaran
   */
  fetchJadwalPelajaran(kelasId) {
    const opts = {
      order: { column: 'urutan', asc: true },
    };
    if (kelasId) {
      opts.filter = { key: 'kelas_id', value: kelasId };
    }
    return fetchFromTable('jadwal_pelajaran', opts);
  },

  /**
   * Mengambil nilai pengaturan situs berdasarkan key
   * @param {string} key - Kunci pengaturan
   * @returns {Promise<string>} Nilai pengaturan
   */
  fetchPengaturanSitus(key) {
    const opts = {
      filter: { key: 'key', value: key },
      single: true,
      select: 'nilai',
    };
    return fetchFromTable('pengaturan_situs', opts);
  },

  /**
   * Mengambil semua pengaturan situs berdasarkan kategori
   * @param {string} [kategori] - Filter berdasarkan kategori (opsional)
   * @returns {Promise<Array>} Daftar pengaturan
   */
  fetchAllPengaturanSitus(kategori) {
    const opts = {
      order: { column: 'key', asc: true },
    };
    if (kategori) {
      opts.filter = { key: 'kategori', value: kategori };
    }
    return fetchFromTable('pengaturan_situs', opts);
  },
};

// ============================================================
// 5) FUNGSI UTILITAS
// ============================================================

/**
 * Memformat tanggal ISO ke format panjang Indonesia.
 * Contoh: "25 April 2026"
 *
 * @param {string} iso - Tanggal dalam format ISO 8601
 * @returns {string} Tanggal terformat
 */
function formatDate(iso) {
  if (!iso) return '';
  try {
    const date = new Date(iso);
    return new Intl.DateTimeFormat('id-ID', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    }).format(date);
  } catch {
    return iso;
  }
}

/**
 * Memformat tanggal ISO ke format pendek Indonesia.
 * Contoh: "25 Apr 2026"
 *
 * @param {string} iso - Tanggal dalam format ISO 8601
 * @returns {string} Tanggal terformat pendek
 */
function formatDateShort(iso) {
  if (!iso) return '';
  try {
    const date = new Date(iso);
    return new Intl.DateTimeFormat('id-ID', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
    }).format(date);
  } catch {
    return iso;
  }
}

/**
 * Memotong teks yang terlalu panjang dan menambahkan elipsis.
 *
 * @param {string} text - Teks asli
 * @param {number} [max=100] - Panjang maksimum karakter
 * @returns {string} Teks yang sudah dipotong
 */
function truncateText(text, max = 100) {
  if (!text) return '';
  if (text.length <= max) return text;
  return text.substring(0, max) + '...';
}

/**
 * Mengubah teks menjadi slug URL-friendly.
 * Huruf kecil, spasi jadi strip, hapus karakter khusus.
 *
 * @param {string} text - Teks asli
 * @returns {string} Slug
 */
function slugify(text) {
  if (!text) return '';
  return text
    .toLowerCase()
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9-]/g, '')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

/**
 * Mengkonversi URL Google Drive menjadi URL thumbnail yang bisa ditampilkan.
 *
 * @param {string} link - URL gambar asli
 * @returns {string} URL thumbnail atau placeholder
 */
function getImageUrl(link) {
  // Jika link kosong atau falsy, kembalikan placeholder
  if (!link) {
    return 'https://via.placeholder.com/800x600/059669/ffffff?text=SMA+Plus';
  }

  // Pola 1: /d/FILE_ID/  (format share Google Drive)
  const dMatch = link.match(/\/d\/([a-zA-Z0-9_-]+)/);
  if (dMatch) {
    return `https://drive.google.com/thumbnail?id=${dMatch[1]}&sz=w800`;
  }

  // Pola 2: ?id=FILE_ID  (format URL parameter)
  const idMatch = link.match(/[?&]id=([a-zA-Z0-9_-]+)/);
  if (idMatch) {
    return `https://drive.google.com/thumbnail?id=${idMatch[1]}&sz=w800`;
  }

  // Jika bukan URL Google Drive, kembalikan apa adanya
  return link;
}

/**
 * Fungsi debounce standar untuk menunda eksekusi fungsi.
 *
 * @param {Function} fn - Fungsi yang akan di-debounce
 * @param {number} [wait=300] - Jeda waktu dalam milidetik
 * @returns {Function} Fungsi yang sudah di-debounce
 */
function debounce(fn, wait = 300) {
  let timer;
  return function (...args) {
    clearTimeout(timer);
    timer = setTimeout(() => fn.apply(this, args), wait);
  };
}

/**
 * Menampilkan indikator loading (spinner) di dalam container tertentu.
 *
 * @param {HTMLElement} container - Elemen DOM sebagai wadah spinner
 */
function showLoading(container) {
  if (!container) return;
  container.innerHTML = `
    <div class="spinner" style="
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 2rem;
    ">
      <div style="
        width: 40px;
        height: 40px;
        border: 4px solid #e5e7eb;
        border-top-color: #059669;
        border-radius: 50%;
        animation: smaplus-spin 0.8s linear infinite;
      "></div>
      <style>
        @keyframes smaplus-spin {
          to { transform: rotate(360deg); }
        }
      </style>
    </div>
  `;
}

/**
 * Mengamankan string dari serangan XSS dengan mengubah karakter HTML berbahaya.
 *
 * @param {string} str - String mentah
 * @returns {string} String yang sudah di-escape
 */
function escapeHtml(str) {
  if (!str) return '';
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;',
  };
  return str.replace(/[&<>"']/g, char => map[char]);
}

/**
 * Menyimpan data halaman ke cache secara agresif.
 * Digunakan oleh setiap halaman untuk menyimpan konten yang sudah dimuat.
 *
 * @param {string} pageName - Nama halaman (e.g., 'beranda', 'osis')
 * @param {Object} data - Data yang akan di-cache
 * @param {number} [duration] - Durasi TTL dalam milidetik (default 60 menit)
 */
function cachePageData(pageName, data, duration) {
  setCachedData('page_' + pageName, data, duration || 60 * 60 * 1000);
}

/**
 * Mengambil data halaman dari cache.
 *
 * @param {string} pageName - Nama halaman
 * @returns {any|null} Data cache atau null
 */
function getCachedPageData(pageName) {
  return getCachedData('page_' + pageName);
}

/**
 * Mengambil data dengan strategi stale-while-revalidate:
 * Langsung kembalikan data cache jika ada, lalu fetch data baru di background.
 *
 * @param {string} cacheKey - Kunci cache
 * @param {Function} fetchFn - Fungsi async untuk mengambil data baru
 * @param {Function} onRefresh - Callback ketika data baru diterima
 * @returns {Promise<any>} Data dari cache atau hasil fetch
 */
async function fetchWithSWR(cacheKey, fetchFn, onRefresh) {
  const cached = getCachedData(cacheKey);
  if (cached !== null) {
    // Return cached data immediately, then refresh in background
    try {
      const fresh = await fetchFn();
      if (fresh) {
        setCachedData(cacheKey, fresh);
        if (onRefresh) onRefresh(fresh);
      }
    } catch (e) {
      // Silent fail on background refresh
      console.warn('Background refresh failed for', cacheKey, e);
    }
    return cached;
  }
  // No cache, fetch fresh
  const fresh = await fetchFn();
  if (fresh) {
    setCachedData(cacheKey, fresh);
  }
  return fresh;
}

// ============================================================
// 6) EXPORT KE WINDOW (Global Scope)
// ============================================================

window.SMAPlusAPI = SMAPlusAPI;
window.formatDate = formatDate;
window.formatDateShort = formatDateShort;
window.truncateText = truncateText;
window.slugify = slugify;
window.getImageUrl = getImageUrl;
window.debounce = debounce;
window.showLoading = showLoading;
window.escapeHtml = escapeHtml;
window.cachePageData = cachePageData;
window.getCachedPageData = getCachedPageData;
window.fetchWithSWR = fetchWithSWR;
window.clearCache = clearCache;
window.SUPABASE_URL = SUPABASE_URL;
window.getSupabaseClient = getSupabaseClient;
window.SUPABASE_SERVICE_ROLE_KEY = SUPABASE_SERVICE_ROLE_KEY;

// ============================================================
// 7) FUNGSI AUTENTIKASI (Supabase Auth)
// ============================================================

/**
 * Login menggunakan Supabase Auth (email + password).
 * @param {string} email - Email pengguna
 * @param {string} password - Password pengguna
 * @returns {Promise<{user: Object, session: Object}|null>} Data user & session, atau null jika gagal
 */
async function authLogin(email, password) {
  try {
    const client = await getSupabaseClient();
    const { data, error } = await client.auth.signInWithPassword({ email, password });
    if (error) throw error;
    return data;
  } catch (err) {
    console.error('Login gagal:', err.message);
    return null;
  }
}

/**
 * Logout dari Supabase Auth.
 * @returns {Promise<boolean>} true jika berhasil
 */
async function authLogout() {
  try {
    const client = await getSupabaseClient();
    const { error } = await client.auth.signOut();
    if (error) throw error;
    localStorage.removeItem('smaplus_auth_session');
    return true;
  } catch (err) {
    console.error('Logout gagal:', err.message);
    return false;
  }
}

/**
 * Mengambil session user yang sedang login.
 * @returns {Promise<Object|null>} Session atau null
 */
async function authGetSession() {
  try {
    const client = await getSupabaseClient();
    const { data: { session } } = await client.auth.getSession();
    return session;
  } catch {
    return null;
  }
}

/**
 * Mengambil profile user yang sedang login dari tabel profiles.
 * @returns {Promise<Object|null>} Profile user atau null
 */
async function authGetProfile() {
  try {
    const session = await authGetSession();
    if (!session?.user) return null;
    const client = await getSupabaseClient();
    const { data, error } = await client
      .from('profiles')
      .select('*')
      .eq('id', session.user.id)
      .single();
    if (error) throw error;
    return data;
  } catch {
    return null;
  }
}

/**
 * Mengecek apakah user sudah login dan memiliki role admin/editor.
 * @returns {Promise<{authenticated: boolean, role: string, nama: string}>}
 */
async function authCheck() {
  const session = await authGetSession();
  if (!session?.user) return { authenticated: false, role: '', nama: '' };
  const profile = await authGetProfile();
  return {
    authenticated: true,
    role: profile?.role || 'editor',
    nama: profile?.nama || session.user.email,
  };
}

window.authLogin = authLogin;
window.authLogout = authLogout;
window.authGetSession = authGetSession;
window.authGetProfile = authGetProfile;
window.authCheck = authCheck;
