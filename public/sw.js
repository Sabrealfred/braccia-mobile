/**
 * Service Worker — Braccia Capital Mobile CRM
 * Cache-first strategy with network fallback
 */

const CACHE_NAME = 'braccia-mobile-v1';

const PRECACHE_URLS = [
  '/',
  '/index.html',
  '/manifest.json',
];

// Install: pre-cache essential assets
self.addEventListener('install', (event) => {
  console.log('[SW] Installing service worker...');
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[SW] Pre-caching essential assets');
      return cache.addAll(PRECACHE_URLS);
    })
  );
  // Activate immediately without waiting for existing clients to close
  self.skipWaiting();
});

// Activate: clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating service worker...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => {
            console.log('[SW] Removing old cache:', name);
            return caches.delete(name);
          })
      );
    })
  );
  // Take control of all clients immediately
  self.clients.claim();
});

// Fetch: cache-first for static assets, network-first for API calls
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Skip non-GET requests
  if (request.method !== 'GET') return;

  // Skip cross-origin requests (e.g., analytics, external APIs)
  if (url.origin !== self.location.origin) return;

  // Network-first for API calls
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(networkFirst(request));
    return;
  }

  // Cache-first for static assets (JS, CSS, fonts, images, icons)
  if (isStaticAsset(url.pathname)) {
    event.respondWith(cacheFirst(request));
    return;
  }

  // Network-first for navigation (HTML pages)
  if (request.mode === 'navigate') {
    event.respondWith(networkFirst(request));
    return;
  }

  // Default: cache-first
  event.respondWith(cacheFirst(request));
});

// Listen for skip waiting message from the app
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

/**
 * Cache-first strategy: serve from cache, fall back to network
 */
async function cacheFirst(request) {
  const cached = await caches.match(request);
  if (cached) {
    return cached;
  }

  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    // If both cache and network fail, return offline fallback for navigations
    if (request.mode === 'navigate') {
      return caches.match('/index.html');
    }
    throw error;
  }
}

/**
 * Network-first strategy: try network, fall back to cache
 */
async function networkFirst(request) {
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    const cached = await caches.match(request);
    if (cached) {
      return cached;
    }
    // For navigations, serve the cached index.html (SPA fallback)
    if (request.mode === 'navigate') {
      return caches.match('/index.html');
    }
    throw error;
  }
}

/**
 * Check if a pathname is a static asset worth caching aggressively
 */
function isStaticAsset(pathname) {
  return /\.(js|css|woff2?|ttf|otf|eot|png|jpg|jpeg|gif|svg|ico|webp)(\?.*)?$/.test(pathname)
    || pathname.startsWith('/assets/')
    || pathname.startsWith('/icons/');
}
