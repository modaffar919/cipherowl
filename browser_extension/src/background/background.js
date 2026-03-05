/**
 * CipherOwl Browser Extension — Background Service Worker
 *
 * Responsibilities:
 *  - Handle the CIPHEROWL_OPEN_POPUP message from content scripts
 *    (open the extension popup programmatically when available).
 *  - Keep the service worker alive during fast credential fetch cycles.
 *  - Clear the credential cache when it becomes stale (via alarm).
 *
 * NOTE: This is a Module-type service worker (manifest.json background.type=module).
 */

const STORAGE_CRED_CACHE  = 'co_cred_cache';
const CACHE_TTL_MINUTES   = 30;
const ALARM_NAME          = 'co_cache_expiry';

// ── Message listener ──────────────────────────────────────────────────────────
chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  if (msg.action === 'CIPHEROWL_OPEN_POPUP') {
    // Open the popup — works only in browsers that support programmatic popups.
    // In Chrome MV3, the popup is opened via the toolbar button by the user;
    // this call is a no-op on Chrome but works on Firefox.
    chrome.action.openPopup?.().catch(() => {});
    sendResponse({ ok: true });
  }
  return false; // Synchronous response
});

// ── Cache expiry alarm ────────────────────────────────────────────────────────
// Clears the decrypted credential cache after TTL to limit exposure.
chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === ALARM_NAME) {
    chrome.storage.local.remove(STORAGE_CRED_CACHE);
  }
});

// Reschedule alarm whenever the service worker wakes up.
chrome.alarms.create(ALARM_NAME, { periodInMinutes: CACHE_TTL_MINUTES });

// ── Install / update ──────────────────────────────────────────────────────────
chrome.runtime.onInstalled.addListener(({ reason }) => {
  if (reason === 'install') {
    // Clear any stale storage from a previous install
    chrome.storage.local.clear();
  }
});
