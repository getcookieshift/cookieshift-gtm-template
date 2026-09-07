#!/usr/bin/env node
/**
 * Local logic tests for CookieShift GTM Community Template.
 * Mirrors sandboxed template behavior (cannot run GTM Template Editor here).
 */
'use strict';

const fs = require('fs');
const path = require('path');
const assert = require('assert');

const ROOT = path.join(__dirname, '..');
const TPL = fs.readFileSync(path.join(ROOT, 'template.tpl'), 'utf8');

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const VALID = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';

function mapConsent(state) {
  const marketing = !!state.marketing;
  return {
    analytics_storage: state.analytics ? 'granted' : 'denied',
    ad_storage: marketing ? 'granted' : 'denied',
    ad_user_data: marketing ? 'granted' : 'denied',
    ad_personalization: marketing ? 'granted' : 'denied',
    functionality_storage: state.preferences ? 'granted' : 'denied',
    security_storage: 'granted',
  };
}

function buildUrl(siteId) {
  return (
    'https://cookieshift.com/cmp.js?site_id=' +
    encodeURIComponent(siteId) +
    '&gcm_owner=gtm'
  );
}

function defaults(waitMs) {
  return {
    ad_storage: 'denied',
    ad_user_data: 'denied',
    ad_personalization: 'denied',
    analytics_storage: 'denied',
    functionality_storage: 'denied',
    security_storage: 'granted',
    wait_for_update: waitMs || 1500,
  };
}

let passed = 0;
function test(name, fn) {
  fn();
  passed += 1;
  console.log('PASS:', name);
}

test('default denied state', () => {
  const d = defaults(1500);
  assert.strictEqual(d.ad_storage, 'denied');
  assert.strictEqual(d.ad_user_data, 'denied');
  assert.strictEqual(d.ad_personalization, 'denied');
  assert.strictEqual(d.analytics_storage, 'denied');
  assert.strictEqual(d.functionality_storage, 'denied');
});

test('security_storage granted', () => {
  assert.strictEqual(defaults().security_storage, 'granted');
});

test('analytics consent update', () => {
  const u = mapConsent({
    necessary: true,
    analytics: true,
    marketing: false,
    preferences: false,
  });
  assert.strictEqual(u.analytics_storage, 'granted');
  assert.strictEqual(u.ad_storage, 'denied');
});

test('marketing consent update', () => {
  const u = mapConsent({
    necessary: true,
    analytics: false,
    marketing: true,
    preferences: false,
  });
  assert.strictEqual(u.ad_storage, 'granted');
  assert.strictEqual(u.ad_user_data, 'granted');
  assert.strictEqual(u.ad_personalization, 'granted');
});

test('preferences consent update', () => {
  const u = mapConsent({
    necessary: true,
    analytics: false,
    marketing: false,
    preferences: true,
  });
  assert.strictEqual(u.functionality_storage, 'granted');
  assert.strictEqual(u.security_storage, 'granted');
});

test('listener registration path present in template', () => {
  assert.ok(TPL.includes("callInWindow('CookieShift.registerConsentListener'"));
  assert.ok(TPL.includes('CookieShift.registerConsentListener'));
});

test('invalid Site ID', () => {
  assert.ok(!UUID_RE.test('not-a-uuid'));
  assert.ok(!UUID_RE.test(''));
  assert.ok(UUID_RE.test(VALID));
});

test('script injection URL', () => {
  const url = buildUrl(VALID);
  assert.ok(url.startsWith('https://cookieshift.com/cmp.js?'));
  assert.ok(url.includes('site_id=' + VALID));
});

test('gcmOwner=gtm', () => {
  assert.ok(buildUrl(VALID).includes('gcm_owner=gtm'));
  assert.ok(TPL.includes('gcm_owner=gtm'));
});

test("no gtag('consent') calls", () => {
  assert.ok(!/gtag\s*\(\s*['"]consent['"]/.test(TPL));
  assert.ok(TPL.includes('setDefaultConsentState'));
  assert.ok(TPL.includes('updateConsentState'));
  assert.ok(!TPL.includes("require('gtag')"));
});

test('no arbitrary script/API URL fields', () => {
  assert.ok(!/"name":\s*"apiBase"/.test(TPL));
  assert.ok(!/"name":\s*"scriptUrl"/.test(TPL));
  assert.ok(TPL.includes('https://cookieshift.com/cmp.js'));
});

test('permissions and categories present', () => {
  assert.ok(TPL.includes('access_consent'));
  assert.ok(TPL.includes('inject_script'));
  assert.ok(TPL.includes('access_globals'));
  assert.ok(TPL.includes('PERSONALIZATION'));
  assert.ok(TPL.includes('Consent Initialization'));
});

console.log('\n' + passed + ' local logic tests passed');
