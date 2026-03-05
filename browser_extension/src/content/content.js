/**
 * CipherOwl Browser Extension — Content Script
 *
 * Detects login forms on web pages and injects an autofill button.
 * Receives fill commands (CIPHEROWL_FILL) from the popup.
 *
 * Security: credentials are NEVER stored in the content script context.
 * They arrive as a one-shot message from the popup and are used immediately.
 */

(function () {
  'use strict';

  // Avoid double-injection
  if (window.__cipherOwlInjected) return;
  window.__cipherOwlInjected = true;

  // ── Constants ──────────────────────────────────────────────────────────────
  const ICON_URL = chrome.runtime.getURL('icons/icon.svg');
  const INJECTED_CLASS  = 'co-autofill-btn';
  const DEBOUNCE_MS = 400;

  // ── Listen for fill messages from popup ───────────────────────────────────
  chrome.runtime.onMessage.addListener((msg) => {
    if (msg.action !== 'CIPHEROWL_FILL') return;
    fillLoginForm(msg.username, msg.password);
  });

  // ── DOM observation ────────────────────────────────────────────────────────
  // We use a MutationObserver to handle SPAs that inject forms dynamically.
  let debounceTimer = null;

  function scheduleFormScan() {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(scanForms, DEBOUNCE_MS);
  }

  const observer = new MutationObserver(scheduleFormScan);
  observer.observe(document.body, { childList: true, subtree: true });

  // Initial scan (page already loaded when content script runs at document_idle)
  scheduleFormScan();

  // ── Form scanning ──────────────────────────────────────────────────────────
  function scanForms() {
    const passwordFields = document.querySelectorAll(
      'input[type="password"]:not([data-co-processed])'
    );

    passwordFields.forEach(pwField => {
      pwField.setAttribute('data-co-processed', '1');
      injectButton(pwField);
    });
  }

  // ── Button injection ───────────────────────────────────────────────────────
  function injectButton(pwField) {
    // Wrap the password field in a relative container if needed
    const parent = pwField.parentElement;
    if (!parent) return;

    // Avoid injecting twice
    if (parent.querySelector(`.${INJECTED_CLASS}`)) return;

    // Create the CipherOwl fill button
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = INJECTED_CLASS;
    btn.title = 'ملء بـ CipherOwl';
    btn.setAttribute('aria-label', 'ملء بـ CipherOwl');
    btn.innerHTML = `<img src="${ICON_URL}" width="16" height="16" alt="" />`;

    // Style: small icon button overlaid on the right of the input
    const btnStyle = {
      position:      'absolute',
      'z-index':     '2147483647',
      background:    'rgba(15,244,198,.15)',
      border:        '1px solid rgba(15,244,198,.4)',
      'border-radius': '5px',
      padding:       '2px 4px',
      cursor:        'pointer',
      display:       'flex',
      'align-items': 'center',
      'line-height': '1',
    };
    Object.assign(btn.style, btnStyle);

    // Position relative to the password input
    positionButton(btn, pwField);

    // Re-position on scroll/resize
    const reposition = () => positionButton(btn, pwField);
    window.addEventListener('scroll', reposition, { passive: true });
    window.addEventListener('resize', reposition, { passive: true });

    // On click → open extension popup (background handles the rest)
    btn.addEventListener('click', e => {
      e.preventDefault();
      e.stopPropagation();
      // Ask the background to open the popup so the user can pick credentials.
      // If the popup is already open, the user just fills from there.
      chrome.runtime.sendMessage({ action: 'CIPHEROWL_OPEN_POPUP' });
    });

    document.body.appendChild(btn);
  }

  function positionButton(btn, input) {
    const rect = input.getBoundingClientRect();
    const scrollX = window.scrollX || window.pageXOffset;
    const scrollY = window.scrollY || window.pageYOffset;

    // Place the button inside the input on the left side (RTL-friendly)
    btn.style.top  = `${rect.top  + scrollY + (rect.height - 20) / 2}px`;
    btn.style.left = `${rect.left + scrollX + 4}px`;
  }

  // ── Programmatic autofill ─────────────────────────────────────────────────
  /**
   * Fills the nearest login form on the page.
   * Looks for a password field, then searches for a username/email sibling.
   */
  function fillLoginForm(username, password) {
    const pwField = findBestPasswordField();
    if (!pwField) return;

    if (password) {
      setNativeValue(pwField, password);
      pwField.dispatchEvent(new Event('input', { bubbles: true }));
      pwField.dispatchEvent(new Event('change', { bubbles: true }));
    }

    if (username) {
      const userField = findUsernameField(pwField);
      if (userField) {
        setNativeValue(userField, username);
        userField.dispatchEvent(new Event('input', { bubbles: true }));
        userField.dispatchEvent(new Event('change', { bubbles: true }));
      }
    }

    // Attempt to submit only if there's exactly one submit button in the form
    const form = pwField.closest('form');
    if (form) {
      const submitBtns = form.querySelectorAll('[type="submit"], button:not([type])');
      if (submitBtns.length === 1) {
        // Don't auto-submit — let the user review
      }
    }
  }

  function findBestPasswordField() {
    // Prefer a focused field or the first visible one
    const active = document.activeElement;
    if (active?.type === 'password') return active;
    return [...document.querySelectorAll('input[type="password"]')]
      .find(f => isVisible(f));
  }

  function findUsernameField(pwField) {
    // Walk backwards from the password field looking for text/email inputs
    const form = pwField.closest('form') || document.body;
    const inputs = [...form.querySelectorAll('input')];
    const pwIndex = inputs.indexOf(pwField);

    for (let i = pwIndex - 1; i >= 0; i--) {
      const t = inputs[i].type;
      if (['text', 'email', 'tel'].includes(t) && isVisible(inputs[i])) {
        return inputs[i];
      }
    }
    return null;
  }

  /** Uses React/Vue-compatible setter so framework state gets updated. */
  function setNativeValue(el, value) {
    const nativeDescriptor =
      Object.getOwnPropertyDescriptor(
        Object.getPrototypeOf(el), 'value'
      );
    if (nativeDescriptor && nativeDescriptor.set) {
      nativeDescriptor.set.call(el, value);
    } else {
      el.value = value;
    }
  }

  function isVisible(el) {
    if (!el) return false;
    const r = el.getBoundingClientRect();
    return r.width > 0 && r.height > 0 &&
           getComputedStyle(el).visibility !== 'hidden' &&
           getComputedStyle(el).display    !== 'none';
  }
})();
