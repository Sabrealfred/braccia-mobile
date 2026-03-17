/**
 * Service Worker Registration for Braccia Capital Mobile CRM
 * Enables PWA support: offline access, Add to Home Screen, background sync
 */

export function registerServiceWorker(): void {
  if (!('serviceWorker' in navigator)) {
    console.log('[SW] Service workers not supported in this browser');
    return;
  }

  window.addEventListener('load', async () => {
    try {
      const registration = await navigator.serviceWorker.register('/sw.js', {
        scope: '/',
      });

      console.log('[SW] Service worker registered with scope:', registration.scope);

      // Check for updates on registration
      registration.addEventListener('updatefound', () => {
        const newWorker = registration.installing;
        if (!newWorker) return;

        console.log('[SW] New service worker installing...');

        newWorker.addEventListener('statechange', () => {
          if (newWorker.state === 'installed') {
            if (navigator.serviceWorker.controller) {
              // New content available — prompt user to refresh
              console.log('[SW] New content available. Refresh to update.');
              dispatchUpdateEvent();
            } else {
              // First install — content cached for offline use
              console.log('[SW] Content cached for offline use.');
            }
          }
        });
      });

      // Periodic update check (every 60 minutes)
      setInterval(() => {
        registration.update().catch((err) => {
          console.warn('[SW] Update check failed:', err);
        });
      }, 60 * 60 * 1000);

    } catch (error) {
      console.error('[SW] Registration failed:', error);
    }
  });

  // Handle controller change (new SW activated)
  let refreshing = false;
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (refreshing) return;
    refreshing = true;
    window.location.reload();
  });
}

/**
 * Dispatch a custom event so the app can show an update notification
 */
function dispatchUpdateEvent(): void {
  const event = new CustomEvent('sw-update-available');
  window.dispatchEvent(event);
}

/**
 * Skip waiting on the new service worker (call when user accepts update)
 */
export async function applyServiceWorkerUpdate(): Promise<void> {
  const registration = await navigator.serviceWorker.getRegistration();
  if (registration?.waiting) {
    registration.waiting.postMessage({ type: 'SKIP_WAITING' });
  }
}
