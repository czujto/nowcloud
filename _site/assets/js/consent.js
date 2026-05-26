(function () {
  'use strict';

  var storageKey = 'nowcloud_cookie_consent';
  var bannerId = 'cookie-consent-banner';

  function readChoice() {
    try {
      return window.localStorage.getItem(storageKey);
    } catch (error) {
      return null;
    }
  }

  function storeChoice(choice) {
    try {
      window.localStorage.setItem(storageKey, choice);
    } catch (error) {
      // The preference cannot persist when browser storage is unavailable.
    }
  }

  function updateConsent(accepted) {
    if (typeof window.gtag !== 'function') {
      return;
    }

    window.gtag('consent', 'update', {
      'analytics_storage': accepted ? 'granted' : 'denied',
      'ad_storage': 'denied',
      'ad_user_data': 'denied',
      'ad_personalization': 'denied'
    });
  }

  function removeBanner() {
    var banner = document.getElementById(bannerId);

    if (banner) {
      banner.parentNode.removeChild(banner);
    }
  }

  function choose(accepted) {
    storeChoice(accepted ? 'accepted' : 'rejected');
    updateConsent(accepted);
    removeBanner();
  }

  function renderBanner() {
    if (readChoice() === 'accepted' || readChoice() === 'rejected') {
      return;
    }

    var banner = document.createElement('section');
    banner.id = bannerId;
    banner.className = 'cookie-consent';
    banner.setAttribute('aria-label', 'Analytics cookie consent');
    banner.setAttribute('role', 'region');
    banner.innerHTML =
      '<p>This site uses analytics cookies to understand which Azure architecture notes are useful. You can accept or reject analytics cookies.</p>' +
      '<div class="cookie-consent-actions">' +
      '<button class="cookie-consent-reject" type="button">Reject analytics</button>' +
      '<button class="cookie-consent-accept" type="button">Accept analytics</button>' +
      '</div>';

    banner.querySelector('.cookie-consent-reject').addEventListener('click', function () {
      choose(false);
    });
    banner.querySelector('.cookie-consent-accept').addEventListener('click', function () {
      choose(true);
    });

    document.body.appendChild(banner);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', renderBanner);
  } else {
    renderBanner();
  }
}());
