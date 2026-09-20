/* Service worker — Mon Atelier Nail Art
   Portée limitée à /nail-studio/ (le fichier est servi depuis ce dossier).
   Cache PROPRE à cette appli (nailstudio-*) : on ne touche jamais aux caches
   des autres sites fadeflux.github.io. */
const CACHE = 'nailstudio-v1';
const CORE = ['./', './index.html', './manifest.webmanifest', './icon-192.png', './icon-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(CORE)).catch(()=>{}).then(()=> self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k.startsWith('nailstudio-') && k !== CACHE).map(k => caches.delete(k))))
      .then(()=> self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  let url; try { url = new URL(req.url); } catch(_) { return; }

  if (url.origin === location.origin) {
    // App : cache d'abord, réseau en secours (marche hors-ligne après la 1re visite)
    e.respondWith(
      caches.match(req).then(hit => hit || fetch(req).then(res => {
        const copy = res.clone(); caches.open(CACHE).then(c => c.put(req, copy)).catch(()=>{});
        return res;
      }).catch(()=> caches.match('./index.html')))
    );
  } else {
    // CDN (Tailwind, Supabase, polices…) : réseau d'abord, cache en secours hors-ligne
    e.respondWith(
      fetch(req).then(res => {
        const copy = res.clone(); caches.open(CACHE).then(c => c.put(req, copy)).catch(()=>{});
        return res;
      }).catch(()=> caches.match(req))
    );
  }
});
