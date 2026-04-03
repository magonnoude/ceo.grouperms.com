// sw.js — Service Worker for PWA
// ceo.grouperms.com | Updated: April 2026
const CACHE_NAME = 'ceo-cache-v1';
const urlsToCache = [
    '/',
    '/index.html',
    '/about.html',
    '/advisory.html',
    '/academy.html',
    '/blog.html',
    '/contact.html',
    '/css/styles.css',
    '/js/main.js',
    '/images/Modeste_AGONNOUDE.jpg',
    '/images/rms.jpg',
    '/manifest.json'
];

self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                console.log('Cache opened:', CACHE_NAME);
                return cache.addAll(urlsToCache);
            })
    );
    self.skipWaiting();
});

self.addEventListener('fetch', event => {
    // Only cache GET requests
    if (event.request.method !== 'GET') return;

    event.respondWith(
        caches.match(event.request)
            .then(response => {
                if (response) {
                    return response;
                }
                return fetch(event.request).then(fetchResponse => {
                    // Cache successful responses for same-origin requests
                    if (fetchResponse && fetchResponse.status === 200 &&
                        fetchResponse.type === 'basic') {
                        const responseToCache = fetchResponse.clone();
                        caches.open(CACHE_NAME).then(cache => {
                            cache.put(event.request, responseToCache);
                        });
                    }
                    return fetchResponse;
                });
            })
    );
});

self.addEventListener('activate', event => {
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames.map(cache => {
                    if (cache !== CACHE_NAME) {
                        console.log('Deleting old cache:', cache);
                        return caches.delete(cache);
                    }
                })
            );
        })
    );
    self.clients.claim();
});
