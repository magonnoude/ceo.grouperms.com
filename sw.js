// sw.js - Service Worker for PWA
const CACHE_NAME = 'rms-cache-v2';
const urlsToCache = [
    '/',
    '/index.html',
    '/advisory.html',
    '/platform.html',
    '/academy.html',
    '/about.html',
    '/blog.html',
    '/contact.html',
    '/css/styles.css',
    '/js/main.js',
    '/images/rms-logo.svg',
    '/images/Modeste_AGONNOUDE.jpg'
];

self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                console.log('Cache opened');
                return cache.addAll(urlsToCache);
            })
    );
});

self.addEventListener('fetch', event => {
    event.respondWith(
        caches.match(event.request)
            .then(response => {
                if (response) {
                    return response;
                }
                return fetch(event.request);
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
});