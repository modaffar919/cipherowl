/**
 * CipherOwl Browser Extension — Popup Script
 *
 * Flow:
 *  1. Check chrome.storage.local for Supabase session (access_token).
 *  2. If no session → show Auth view.
 *  3. If session but no sync key → show Key Import view.
 *  4. If session + sync key → decrypt vault from Supabase and show credentials.
 *
 * Crypto:
 *  - Ciphertext format: base64( nonce[12] || AES-256-GCM(ciphertext+tag) )
 *  - Sync key: 64-char hex string exported from the mobile app settings.
 *  - Supabase table: browser_autofill (RLS — only the authenticated user's rows).
 */

// ── Configuration ────────────────────────────────────────────────────────────
// Replace with your actual Supabase project values.
// These are public keys — safe to embed in the extension.
const SUPABASE_URL  = 'https://YOUR_PROJECT.supabase.co';
const SUPABASE_ANON = 'YOUR_ANON_KEY';

// chrome.storage.local keys
const STORAGE_ACCESS_TOKEN  = 'co_access_token';
const STORAGE_REFRESH_TOKEN = 'co_refresh_token';
const STORAGE_USER_ID       = 'co_user_id';
const STORAGE_SYNC_KEY_HEX  = 'co_sync_key_hex';
// Decrypted credential cache (cleared on lock / logout)
const STORAGE_CRED_CACHE    = 'co_cred_cache';

// ── DOM refs ────────────────────────────────────────────────────────────────
const views = {
  loading: document.getElementById('view-loading'),
  auth:    document.getElementById('view-auth'),
  key:     document.getElementById('view-key'),
  main:    document.getElementById('view-main'),
};
const $badge    = document.getElementById('status-badge');
const $credList = document.getElementById('cred-list');
const $noResults = document.getElementById('no-results');
const $emptyVault = document.getElementById('empty-vault');
const $search    = document.getElementById('search');
const $domainBanner = document.getElementById('domain-banner');
const $domainBannerText = document.getElementById('domain-banner-text');

// ── Startup ──────────────────────────────────────────────────────────────────
async function init() {
  showView('loading');
  const { co_access_token: token, co_sync_key_hex: keyHex } =
    await chrome.storage.local.get([STORAGE_ACCESS_TOKEN, STORAGE_SYNC_KEY_HEX]);

  if (!token) {
    showView('auth');
    setBadge('disconnected');
    return;
  }
  if (!keyHex) {
    showView('key');
    setBadge('locked');
    return;
  }

  await loadCredentials(token, keyHex);
}

// ── Auth ─────────────────────────────────────────────────────────────────────
document.getElementById('btn-login').addEventListener('click', async () => {
  const email    = document.getElementById('email').value.trim();
  const password = document.getElementById('password').value;
  const errEl    = document.getElementById('auth-error');
  const btnText  = document.getElementById('btn-login-text');
  const spinner  = document.getElementById('btn-login-spinner');

  if (!email || !password) {
    showError(errEl, 'أدخل البريد الإلكتروني وكلمة المرور');
    return;
  }

  btnText.classList.add('hidden');
  spinner.classList.remove('hidden');
  errEl.classList.add('hidden');

  try {
    const res = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_ANON,
      },
      body: JSON.stringify({ email, password }),
    });
    const data = await res.json();

    if (!res.ok) {
      showError(errEl, data.error_description || data.msg || 'فشل تسجيل الدخول');
      return;
    }

    await chrome.storage.local.set({
      [STORAGE_ACCESS_TOKEN]:  data.access_token,
      [STORAGE_REFRESH_TOKEN]: data.refresh_token,
      [STORAGE_USER_ID]:       data.user.id,
    });

    // Check if we already have a sync key stored
    const { co_sync_key_hex: keyHex } =
      await chrome.storage.local.get(STORAGE_SYNC_KEY_HEX);
    if (!keyHex) {
      showView('key');
      setBadge('locked');
    } else {
      await loadCredentials(data.access_token, keyHex);
    }
  } catch (e) {
    showError(errEl, 'خطأ في الشبكة — تحقق من اتصالك');
  } finally {
    btnText.classList.remove('hidden');
    spinner.classList.add('hidden');
  }
});

// ── Key Import ────────────────────────────────────────────────────────────────
document.getElementById('btn-import-key').addEventListener('click', async () => {
  const input  = document.getElementById('sync-key-input').value.trim().toLowerCase();
  const errEl  = document.getElementById('key-error');

  if (!/^[0-9a-f]{64}$/.test(input)) {
    showError(errEl, 'المفتاح يجب أن يكون 64 حرفاً هكساديسيمال (0-9, a-f)');
    return;
  }

  // Quick validation: try importing as a CryptoKey
  try {
    await importSyncKey(input);
  } catch {
    showError(errEl, 'مفتاح غير صالح');
    return;
  }

  await chrome.storage.local.set({ [STORAGE_SYNC_KEY_HEX]: input });

  const { co_access_token: token } =
    await chrome.storage.local.get(STORAGE_ACCESS_TOKEN);
  if (token) {
    await loadCredentials(token, input);
  } else {
    showView('auth');
    setBadge('disconnected');
  }
});

document.getElementById('btn-logout-from-key').addEventListener('click', logout);

// ── Main view actions ─────────────────────────────────────────────────────────
$search.addEventListener('input', () => {
  renderList(currentCreds, $search.value.trim().toLowerCase(), currentDomain);
});

document.getElementById('btn-refresh').addEventListener('click', async () => {
  const { co_access_token: token, co_sync_key_hex: keyHex } =
    await chrome.storage.local.get([STORAGE_ACCESS_TOKEN, STORAGE_SYNC_KEY_HEX]);
  if (token && keyHex) await loadCredentials(token, keyHex);
});

document.getElementById('btn-lock').addEventListener('click', async () => {
  await chrome.storage.local.remove([STORAGE_CRED_CACHE, STORAGE_SYNC_KEY_HEX]);
  currentCreds = [];
  showView('key');
  setBadge('locked');
});

document.getElementById('btn-logout').addEventListener('click', logout);

// ── Core: load + decrypt ──────────────────────────────────────────────────────
let currentCreds = [];
let currentDomain = '';

async function loadCredentials(token, keyHex) {
  showView('loading');

  try {
    // Try to use cached decrypted creds first (faster popup open)
    const { co_cred_cache: cached } = await chrome.storage.local.get(STORAGE_CRED_CACHE);
    if (cached && cached.length) {
      currentCreds = cached;
      await showMainView();
      return;
    }

    // Fetch from Supabase
    const rows = await fetchRows(token);
    const cryptoKey = await importSyncKey(keyHex);

    const creds = [];
    for (const row of rows) {
      try {
        const json = await decryptPayload(row.encrypted_payload, cryptoKey);
        const cred = JSON.parse(json);
        if (cred && cred.id) creds.push(cred);
      } catch {
        // Skip rows that fail to decrypt (e.g., encrypted with a different key)
      }
    }

    currentCreds = creds;
    // Cache decrypted creds in session-scoped storage (cleared when browser closes
    // if using chrome.storage.session, or on explicit lock/logout here).
    await chrome.storage.local.set({ [STORAGE_CRED_CACHE]: creds });

    await showMainView();
  } catch (e) {
    if (e.message === 'UNAUTHORIZED') {
      // Token expired — go back to login
      await chrome.storage.local.remove([
        STORAGE_ACCESS_TOKEN, STORAGE_REFRESH_TOKEN,
        STORAGE_USER_ID, STORAGE_CRED_CACHE,
      ]);
      showView('auth');
      setBadge('disconnected');
    } else {
      showView('auth');
      showError(document.getElementById('auth-error'), 'فشل تحميل البيانات: ' + e.message);
    }
  }
}

async function showMainView() {
  // Detect the current tab's domain for highlighting suggestions
  try {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    if (tab?.url) {
      const url = new URL(tab.url);
      currentDomain = url.hostname.toLowerCase();
      $domainBannerText.textContent = `اقتراحات لـ ${currentDomain}`;
      $domainBanner.classList.remove('hidden');
    }
  } catch {
    currentDomain = '';
  }

  renderList(currentCreds, '', currentDomain);
  setBadge('connected');
  showView('main');
}

function renderList(creds, query, domain) {
  $credList.innerHTML = '';
  $noResults.classList.add('hidden');
  $emptyVault.classList.add('hidden');

  if (!creds.length) {
    $emptyVault.classList.remove('hidden');
    return;
  }

  // Filter by query
  let filtered = creds;
  if (query) {
    filtered = creds.filter(c =>
      (c.title   || '').toLowerCase().includes(query) ||
      (c.username|| '').toLowerCase().includes(query) ||
      (c.url     || '').toLowerCase().includes(query)
    );
  }

  if (!filtered.length) {
    $noResults.classList.remove('hidden');
    return;
  }

  // Sort: exact domain match first, then partial, then rest
  filtered.sort((a, b) => {
    const sa = domainScore(a.url, domain);
    const sb = domainScore(b.url, domain);
    return sb - sa;
  });

  filtered.forEach(cred => $credList.appendChild(buildCard(cred)));
}

function domainScore(url, domain) {
  if (!domain || !url) return 0;
  try {
    const host = new URL(url.includes('://') ? url : `https://${url}`).hostname.toLowerCase();
    if (host === domain) return 2;
    if (host.endsWith(`.${domain}`) || domain.endsWith(`.${host}`)) return 1;
    return 0;
  } catch { return 0; }
}

function buildCard(cred) {
  const card = document.createElement('div');
  card.className = 'cred-card';
  card.innerHTML = `
    <div class="cred-info">
      <div class="cred-title" title="${esc(cred.title)}">${esc(cred.title)}</div>
      <div class="cred-username" title="${esc(cred.username)}">${esc(cred.username || '')}</div>
    </div>
    <div class="cred-actions">
      <button class="action-btn" title="نسخ اسم المستخدم">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2" aria-hidden="true">
          <path d="M20 14H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h8l5 5v4z"/>
          <path d="M17 22H4a2 2 0 0 1-2-2v-7"/>
        </svg>
      </button>
      <button class="action-btn fill-btn" title="ملء تلقائي">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2" aria-hidden="true">
          <polyline points="20 6 9 17 4 12"/>
        </svg>
      </button>
    </div>`;

  // Copy username
  card.querySelector('.action-btn').addEventListener('click', e => {
    e.stopPropagation();
    navigator.clipboard.writeText(cred.username || '').catch(() => {});
    flashCard(card, '✓ تم النسخ');
  });

  // Fill form on current tab
  card.querySelector('.fill-btn').addEventListener('click', e => {
    e.stopPropagation();
    fillForm(cred);
  });

  // Click card → also fill
  card.addEventListener('click', () => fillForm(cred));

  return card;
}

function fillForm(cred) {
  chrome.tabs.query({ active: true, currentWindow: true }, ([tab]) => {
    if (!tab?.id) return;
    chrome.tabs.sendMessage(tab.id, {
      action: 'CIPHEROWL_FILL',
      username: cred.username || '',
      password: cred.password || '',
    }).catch(() => {
      // Content script might not be injected on privileged pages
      navigator.clipboard.writeText(cred.password || '').catch(() => {});
    });
    window.close();
  });
}

function flashCard(card, msg) {
  const original = card.querySelector('.cred-title').textContent;
  card.querySelector('.cred-title').textContent = msg;
  setTimeout(() => { card.querySelector('.cred-title').textContent = original; }, 1200);
}

// ── Supabase helpers ──────────────────────────────────────────────────────────
async function fetchRows(token) {
  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/browser_autofill?select=id,encrypted_payload,url_hint&is_deleted=eq.false`,
    {
      headers: {
        'apikey':        SUPABASE_ANON,
        'Authorization': `Bearer ${token}`,
      },
    }
  );
  if (res.status === 401) throw new Error('UNAUTHORIZED');
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

// ── WebCrypto helpers ─────────────────────────────────────────────────────────

/** Import a 64-char hex sync key as a WebCrypto AES-GCM key. */
async function importSyncKey(hexKey) {
  const keyBytes = hexToBytes(hexKey);
  return crypto.subtle.importKey(
    'raw', keyBytes, { name: 'AES-GCM' }, false, ['decrypt']
  );
}

/**
 * Decrypt an AES-256-GCM blob.
 * Blob format: base64( nonce[12] || ciphertext+tag )
 * — matches the layout produced by the Rust `aes_gcm::encrypt()`.
 */
async function decryptPayload(base64Blob, cryptoKey) {
  const bytes = base64ToBytes(base64Blob);
  const nonce = bytes.slice(0, 12);
  const data  = bytes.slice(12);
  const plain = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: nonce },
    cryptoKey,
    data
  );
  return new TextDecoder().decode(plain);
}

// ── Utility ───────────────────────────────────────────────────────────────────
function hexToBytes(hex) {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++)
    bytes[i] = parseInt(hex.substr(i * 2, 2), 16);
  return bytes;
}

function base64ToBytes(b64) {
  const binary = atob(b64);
  const bytes  = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

function esc(str) {
  return String(str ?? '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function showView(name) {
  Object.values(views).forEach(v => v.classList.remove('active'));
  views[name].classList.add('active');
}

function setBadge(state) {
  $badge.className = `badge badge-${state}`;
  $badge.textContent = state === 'connected' ? '● متصل' :
                       state === 'locked'    ? '● مقفل' : '● غير متصل';
  $badge.title = state;
}

function showError(el, msg) {
  el.textContent = msg;
  el.classList.remove('hidden');
}

async function logout() {
  await chrome.storage.local.remove([
    STORAGE_ACCESS_TOKEN, STORAGE_REFRESH_TOKEN,
    STORAGE_USER_ID, STORAGE_SYNC_KEY_HEX, STORAGE_CRED_CACHE,
  ]);
  currentCreds = [];
  showView('auth');
  setBadge('disconnected');
}

// ── Boot ──────────────────────────────────────────────────────────────────────
init();
