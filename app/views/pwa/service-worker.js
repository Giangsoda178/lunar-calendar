const STATIC_CACHE = "moon-calendar-static-v1"
const RUNTIME_CACHE = "moon-calendar-runtime-v1"
const OFFLINE_FALLBACK_PATH = "/offline.html"
const STATIC_DESTINATIONS = new Set([
  "script",
  "style",
  "image",
  "font",
  "manifest",
  "worker",
])
const PRECACHE_URLS = [
  OFFLINE_FALLBACK_PATH,
  "/icon-192.png",
  "/icon-512.png",
  "/apple-touch-icon.png",
]

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(STATIC_CACHE)
      .then((cache) => cache.addAll(PRECACHE_URLS))
      .then(() => self.skipWaiting()),
  )
})

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys
            .filter((key) => key !== STATIC_CACHE && key !== RUNTIME_CACHE)
            .map((key) => caches.delete(key)),
        ),
      )
      .then(() => self.clients.claim()),
  )
})

function isSameOrigin(url) {
  return url.origin === self.location.origin
}

function isNavigationRequest(request) {
  return request.mode === "navigate"
}

function isStaticRequest(request, url) {
  if (!isSameOrigin(url)) return false
  if (request.destination && STATIC_DESTINATIONS.has(request.destination)) return true

  return /^\/assets\//.test(url.pathname)
}

async function staleWhileRevalidate(request) {
  const cache = await caches.open(RUNTIME_CACHE)
  const cached = await cache.match(request)
  const networkFetch = fetch(request)
    .then((response) => {
      if (response && response.ok) {
        cache.put(request, response.clone())
      }
      return response
    })
    .catch(() => undefined)

  return cached || networkFetch
}

async function navigationFallback() {
  const cache = await caches.open(STATIC_CACHE)
  return cache.match(OFFLINE_FALLBACK_PATH)
}

self.addEventListener("fetch", (event) => {
  const request = event.request
  if (request.method !== "GET") return

  const url = new URL(request.url)

  if (isNavigationRequest(request)) {
    event.respondWith(
      fetch(request).catch(async () => {
        const fallback = await navigationFallback()
        return fallback || Response.error()
      }),
    )
    return
  }

  if (isStaticRequest(request, url)) {
    event.respondWith(staleWhileRevalidate(request))
    return
  }
})
