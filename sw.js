// Service Worker - SMA Plus Almunawwarah
// Network-first strategy: always fetch fresh from network,
// only fall back to cache when offline.
//
// Cache lokal (localStorage) untuk DATA sudah dinonaktifkan di api.js,
// jadi setiap kunjungan selalu mengambil data terbaru dari Supabase.
// Service worker ini hanya menyediakan fallback offline untuk aset
// statis (HTML, JS, gambar) — bukan untuk data.

const CACHE_NAME = 'smaplus-cache-v2';
const OFFLINE_FALLBACK_URL = '/index.html';

// Daftar aset inti yang di-cache HANYA untuk fallback offline.
// Cache ini TIDAK dipakai untuk serving saat online — selalu network-first.
const CACHE_URLS = [
  '/',
  '/index.html',
  '/js/api.js',
  '/js/navbar.js',
  '/js/footer.js',
  '/assets/logo.png',
  '/pages/sejarah.html',
  '/pages/struktur-organisasi.html',
  '/pages/tenaga-pendidik.html',
  '/pages/sarana-prasarana.html',
  '/pages/prestasi.html',
  '/pages/kurikulum.html',
  '/pages/program-unggulan.html',
  '/pages/osis.html',
  '/pages/ospm.html',
  '/pages/ekstrakurikuler.html',
  '/pages/berita.html',
  '/pages/galeri.html',
  '/pages/info-psb.html',
  '/pages/link-psb.html'
];

// Install - pre-cache core assets untuk fallback offline
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[SW] Pre-caching offline fallback assets');
      return cache.addAll(CACHE_URLS).catch((err) => {
        console.warn('[SW] Some assets failed to pre-cache:', err);
      });
    })
  );
  self.skipWaiting();
});

// Activate - hapus cache versi lama
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => {
            console.log('[SW] Deleting old cache:', name);
            return caches.delete(name);
          })
      );
    })
  );
  self.clients.claim();
});

// Fetch - NETWORK-FIRST strategy
// Selalu ambil dari network dulu (fresh), jatuh ke cache hanya jika offline.
// Permintaan API Supabase TIDAK pernah di-cache.
self.addEventListener('fetch', (event) => {
  // Skip non-GET requests
  if (event.request.method !== 'GET') return;

  // Skip Supabase API calls — selalu network, tidak pernah di-cache
  if (event.request.url.includes('supabase.co') ||
      event.request.url.includes('supabase.com')) return;

  // Skip external CDN resources — biarkan browser handle
  if (event.request.url.includes('cdnjs.cloudflare.com') ||
      event.request.url.includes('unpkg.com') ||
      event.request.url.includes('fonts.googleapis.com') ||
      event.request.url.includes('fonts.gstatic.com') ||
      event.request.url.includes('drive.google.com')) return;

  event.respondWith(
    fetch(event.request)
      .then((networkResponse) => {
        // Berhasil fetch dari network — update cache utk fallback offline
        if (networkResponse && networkResponse.status === 200) {
          const responseClone = networkResponse.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseClone);
          });
        }
        return networkResponse;
      })
      .catch(() => {
        // Network gagal (offline) — coba cache
        return caches.match(event.request).then((cachedResponse) => {
          if (cachedResponse) return cachedResponse;
          // Fallback terakhir: index.html untuk navigasi HTML
          if (event.request.headers.get('accept')?.includes('text/html')) {
            return caches.match(OFFLINE_FALLBACK_URL);
          }
          return new Response('Offline', { status: 503, statusText: 'Offline' });
        });
      })
  );
});
