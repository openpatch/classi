/* Classi landing page: language switch, latest-release links, copy button. */
(function () {
  'use strict';

  var STORE_KEY = 'classi-site-lang';
  var REPO = 'openpatch/classi';
  var lang = 'de';
  var release = null;

  /* ── language ──────────────────────────────────────────── */

  // German is authored inline, English lives in data-en* attributes. Snapshot the
  // German once so switching back does not depend on the DOM being untouched.
  function snapshot() {
    document.querySelectorAll('[data-en]').forEach(function (el) {
      if (el.dataset.de === undefined) el.dataset.de = el.textContent;
    });
    document.querySelectorAll('[data-en-alt]').forEach(function (el) {
      if (el.dataset.deAlt === undefined) el.dataset.deAlt = el.getAttribute('alt') || '';
    });
    document.querySelectorAll('[data-en-aria-label]').forEach(function (el) {
      if (el.dataset.deAriaLabel === undefined) el.dataset.deAriaLabel = el.getAttribute('aria-label') || '';
    });
  }

  function apply(next) {
    lang = next === 'en' ? 'en' : 'de';

    document.documentElement.lang = lang;

    document.querySelectorAll('[data-en]').forEach(function (el) {
      var text = lang === 'en' ? el.dataset.en : el.dataset.de;
      if (text !== undefined) {
        // <meta> carries its text in an attribute, everything else in the node.
        if (el.tagName === 'META') el.setAttribute('content', text);
        else el.textContent = text;
      }
    });
    document.querySelectorAll('[data-en-alt]').forEach(function (el) {
      el.setAttribute('alt', lang === 'en' ? el.dataset.enAlt : el.dataset.deAlt);
    });
    document.querySelectorAll('[data-en-aria-label]').forEach(function (el) {
      el.setAttribute('aria-label', lang === 'en' ? el.dataset.enAriaLabel : el.dataset.deAriaLabel);
    });

    document.querySelectorAll('.lang-switch button').forEach(function (btn) {
      btn.setAttribute('aria-pressed', String(btn.dataset.lang === lang));
    });

    renderRelease();

    try { localStorage.setItem(STORE_KEY, lang); } catch (e) { /* private mode */ }
  }

  function initialLang() {
    var fromUrl = new URLSearchParams(location.search).get('lang');
    if (fromUrl === 'en' || fromUrl === 'de') return fromUrl;
    try {
      var stored = localStorage.getItem(STORE_KEY);
      if (stored === 'en' || stored === 'de') return stored;
    } catch (e) { /* private mode */ }
    var nav = (navigator.languages && navigator.languages[0]) || navigator.language || 'de';
    return nav.toLowerCase().indexOf('de') === 0 ? 'de' : 'en';
  }

  /* ── latest release ────────────────────────────────────── */

  var MATCHERS = {
    android: /-android\.apk$/i,
    linux: /\.AppImage$/i,
    macos: /\.dmg$/i,
    windows: /\.exe$/i
  };

  function megabytes(bytes) {
    return Math.round(bytes / 1048576) + ' MB';
  }

  function renderRelease() {
    var line = document.querySelector('.release-line');

    if (!release) {
      if (line) line.textContent = lang === 'en' ? line.dataset.enReleaseIdle : line.dataset.releaseIdle;
      return;
    }

    if (line) {
      var date = new Date(release.published_at);
      var when = isNaN(date) ? '' : ' · ' + new Intl.DateTimeFormat(lang === 'en' ? 'en-GB' : 'de-DE', {
        day: 'numeric', month: 'long', year: 'numeric'
      }).format(date);
      line.textContent = (lang === 'en' ? 'Latest release: ' : 'Aktuelle Version: ') + release.tag_name + when;
    }

    Object.keys(MATCHERS).forEach(function (platform) {
      var asset = release.assets.filter(function (a) { return MATCHERS[platform].test(a.name); })[0];
      if (!asset) return;

      document.querySelectorAll('[data-asset="' + platform + '"]').forEach(function (el) {
        el.href = asset.browser_download_url;
      });
      document.querySelectorAll('[data-size="' + platform + '"]').forEach(function (el) {
        el.textContent = megabytes(asset.size);
      });
    });
  }

  function loadRelease() {
    // Best effort only: without it every button still points at the releases page.
    fetch('https://api.github.com/repos/' + REPO + '/releases/latest', {
      headers: { Accept: 'application/vnd.github+json' }
    })
      .then(function (res) { return res.ok ? res.json() : Promise.reject(res.status); })
      .then(function (data) {
        release = data;
        renderRelease();
      })
      .catch(function () {
        var line = document.querySelector('.release-line');
        if (line) line.textContent = '';
      });
  }

  /* ── copy button ───────────────────────────────────────── */

  function initCopy() {
    document.querySelectorAll('.copy').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var source = document.querySelector(btn.dataset.copy);
        if (!source || !navigator.clipboard) return;

        navigator.clipboard.writeText(source.textContent.trim()).then(function () {
          var before = btn.textContent;
          btn.textContent = lang === 'en' ? btn.dataset.enDone : btn.dataset.done;
          setTimeout(function () { btn.textContent = before; }, 1600);
        });
      });
    });
  }

  /* ── go ────────────────────────────────────────────────── */

  snapshot();
  apply(initialLang());
  initCopy();
  loadRelease();

  document.querySelectorAll('.lang-switch button').forEach(function (btn) {
    btn.addEventListener('click', function () { apply(btn.dataset.lang); });
  });
})();
