const CACHE_NAME = 'unsure-calculator-v1';
const BASE_URL = new URL('./', self.location);

const ASSETS = [
  '',
  'index.html',
  'manifest.json',
  'main.dart.js',
  'worker.dart.js',
  'styles.css',
  'app_component/app_component.css',
  'app_component/app_component.html',
  'favicon.png',
  'images/three-dots.svg',
  'images/screenshot.png',
  'images/pwa-192.png',
  'images/pwa-512.png'
].map(path => new URL(path, BASE_URL).href);

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(ASSETS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys
          .filter(key => key.startsWith('unsure-calculator-')
            && key !== CACHE_NAME)
          .map(key => caches.delete(key))
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const request = event.request;

  if (request.method !== 'GET' ||
      new URL(request.url).origin !== self.location.origin) {
    return;
  }

  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .catch(() => caches.match(new URL('index.html', BASE_URL).href))
    );
    return;
  }

  event.respondWith(
    caches.match(request)
      .then(cached => cached || fetch(request))
  );
});
