// Service Worker - SMA Plus Almunawwarah
// Cache-first strategy for offline support and fast loading

const CACHE_NAME = 'smaplus-cache-v1';
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

// Install - cache core assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[SW] Caching core assets');
      return cache.addAll(CACHE_URLS).catch((err) => {
        console.warn('[SW] Some assets failed to cache:', err);
      });
    })
  );
  self.skipWaiting();
});

// Activate - clean old caches
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

// Fetch - Cache-first strategy
self.addEventListener('fetch', (event) => {
  // Skip non-GET requests
  if (event.request.method !== 'GET') return;

  // Skip Supabase API calls (always fetch fresh)
  if (event.request.url.includes('supabase.co') || 
      event.request.url.includes('supabase.com')) return;

  // Skip external CDN resources (let browser handle)
  if (event.request.url.includes('cdnjs.cloudflare.com') ||
      event.request.url.includes('unpkg.com') ||
      event.request.url.includes('fonts.googleapis.com') ||
      event.request.url.includes('fonts.gstatic.com')) return;

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        // Return cached version, and update cache in background
        event.waitUntil(
          fetch(event.request).then((networkResponse) => {
            if (networkResponse && networkResponse.status === 200) {
              caches.open(CACHE_NAME).then((cache) => {
                cache.put(event.request, networkResponse);
              });
            }
          }).catch(() => {})
        );
        return cachedResponse;
      }

      // Not in cache - fetch from network and cache it
      return fetch(event.request).then((networkResponse) => {
        if (!networkResponse || networkResponse.status !== 200) {
          return networkResponse;
        }
        const responseClone = networkResponse.clone();
        caches.open(CACHE_NAME).then((cache) => {
          cache.put(event.request, responseClone);
        });
        return networkResponse;
      }).catch(() => {
        // Network failed, return offline fallback for HTML pages
        if (event.request.headers.get('accept')?.includes('text/html')) {
          return caches.match('/index.html');
        }
      });
    })
  );
});
