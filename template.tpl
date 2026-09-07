___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.

___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "CookieShift Consent Mode",
  "brand": {
    "id": "brand_cookieshift",
    "displayName": "CookieShift"
  },
  "categories": [
    "PERSONALIZATION",
    "TAG_MANAGEMENT",
    "UTILITY"
  ],
  "description": "Loads CookieShift CMP and syncs consent categories to Google Consent Mode v2. Install on Consent Initialization – All Pages. Enter your CookieShift Site ID (UUID).",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "LABEL",
    "name": "installHelp",
    "displayName": "Install this template on the Consent Initialization – All Pages trigger. Enter the CookieShift Site ID from CookieShift. Do not install the CookieShift WordPress/Shopify/direct CMP snippet separately on the same page unless documented as compatible. This template owns Google Consent Mode when data-gcm-owner=\"gtm\" is used (applied via the fixed cmp.js load)."
  },
  {
    "type": "TEXT",
    "name": "siteId",
    "displayName": "CookieShift Site ID",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      },
      {
        "type": "REGEX",
        "args": [
          "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$"
        ],
        "errorMessage": "Enter a valid CookieShift Site ID (UUID)."
      }
    ],
    "help": "Paste the Site ID (UUID) from your CookieShift dashboard. Script and API URLs are fixed to cookieshift.com and cannot be changed."
  },
  {
    "type": "TEXT",
    "name": "waitForUpdate",
    "displayName": "Consent wait_for_update (ms)",
    "simpleValueType": true,
    "defaultValue": "1500",
    "help": "Milliseconds Google tags should wait for CookieShift to update Consent Mode after defaults. Default: 1500.",
    "valueValidators": [
      {
        "type": "POSITIVE_NUMBER"
      }
    ]
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

/**
 * CookieShift Consent Mode — GTM Community Template
 *
 * Owns Google Consent Mode via setDefaultConsentState / updateConsentState.
 * Does not call the gtag consent API. Does not read cookies. Does not push
 * arbitrary dataLayer events. Does not accept custom script/API URLs.
 *
 * GTM injectScript cannot set HTML data-* attributes. CookieShift cmp.js
 * accepts equivalent query parameters:
 *   data-id           → ?site_id=
 *   data-gcm-owner    → ?gcm_owner=gtm
 *   data-api          → script origin (https://cookieshift.com)
 */

const setDefaultConsentState = require('setDefaultConsentState');
const updateConsentState = require('updateConsentState');
const injectScript = require('injectScript');
const callInWindow = require('callInWindow');
const queryPermission = require('queryPermission');
const makeString = require('makeString');
const makeNumber = require('makeNumber');
const encodeUriComponent = require('encodeUriComponent');

const CMP_ORIGIN = 'https://cookieshift.com';
const CMP_SCRIPT_BASE = CMP_ORIGIN + '/cmp.js';

const isHexChar = function(ch) {
  return (
    (ch >= '0' && ch <= '9') ||
    (ch >= 'a' && ch <= 'f') ||
    (ch >= 'A' && ch <= 'F')
  );
};

const isHexBlock = function(str, expectedLen) {
  if (!str || str.length !== expectedLen) {
    return false;
  }
  let i = 0;
  while (i < expectedLen) {
    if (!isHexChar(str.charAt(i))) {
      return false;
    }
    i = i + 1;
  }
  return true;
};

const isValidSiteIdUuid = function(value) {
  if (!value || typeof value !== 'string' || value.length !== 36) {
    return false;
  }
  if (
    value.charAt(8) !== '-' ||
    value.charAt(13) !== '-' ||
    value.charAt(18) !== '-' ||
    value.charAt(23) !== '-'
  ) {
    return false;
  }
  const p0 = value.substring(0, 8);
  const p1 = value.substring(9, 13);
  const p2 = value.substring(14, 18);
  const p3 = value.substring(19, 23);
  const p4 = value.substring(24, 36);
  if (
    !isHexBlock(p0, 8) ||
    !isHexBlock(p1, 4) ||
    !isHexBlock(p2, 4) ||
    !isHexBlock(p3, 4) ||
    !isHexBlock(p4, 12)
  ) {
    return false;
  }
  const version = p2.charAt(0).toLowerCase();
  if (version < '1' || version > '5') {
    return false;
  }
  const variant = p3.charAt(0).toLowerCase();
  if (
    variant !== '8' &&
    variant !== '9' &&
    variant !== 'a' &&
    variant !== 'b'
  ) {
    return false;
  }
  return true;
};

const siteId = makeString(data.siteId || '').trim();
let waitMs = makeNumber(data.waitForUpdate);
if (!waitMs || waitMs < 0) {
  waitMs = 1500;
}

const defaults = {
  ad_storage: 'denied',
  ad_user_data: 'denied',
  ad_personalization: 'denied',
  analytics_storage: 'denied',
  functionality_storage: 'denied',
  security_storage: 'granted',
  wait_for_update: waitMs
};

setDefaultConsentState(defaults);

if (!siteId || !isValidSiteIdUuid(siteId)) {
  data.gtmOnFailure();
  return;
}

/**
 * Map CookieShift category booleans → Google Consent Mode types.
 * Payload from CookieShift.registerConsentListener (no PII).
 */
const applyCookieShiftConsent = (state) => {
  if (!state) {
    return;
  }
  const marketing = !!state.marketing;
  updateConsentState({
    analytics_storage: state.analytics ? 'granted' : 'denied',
    ad_storage: marketing ? 'granted' : 'denied',
    ad_user_data: marketing ? 'granted' : 'denied',
    ad_personalization: marketing ? 'granted' : 'denied',
    functionality_storage: state.preferences ? 'granted' : 'denied',
    security_storage: 'granted'
  });
};

const onScriptSuccess = () => {
  if (queryPermission('access_globals', 'execute', 'CookieShift.registerConsentListener')) {
    callInWindow('CookieShift.registerConsentListener', applyCookieShiftConsent);
  }
  data.gtmOnSuccess();
};

const onScriptFailure = () => {
  data.gtmOnFailure();
};

// Fixed CDN + GTM ownership. site_id / gcm_owner mirror required data-* attrs.
const scriptUrl =
  CMP_SCRIPT_BASE +
  '?site_id=' + encodeUriComponent(siteId) +
  '&gcm_owner=gtm';

if (queryPermission('inject_script', scriptUrl)) {
  injectScript(scriptUrl, onScriptSuccess, onScriptFailure, scriptUrl);
} else {
  data.gtmOnFailure();
}


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "access_consent",
        "versionId": "1"
      },
      "param": [
        {
          "key": "consentTypes",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "ad_storage" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "ad_user_data" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "ad_personalization" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "analytics_storage" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "functionality_storage" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "security_storage" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "inject_script",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://cookieshift.com/cmp.js*"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_globals",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "key" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" },
                  { "type": 1, "string": "execute" }
                ],
                "mapValue": [
                  { "type": 1, "string": "CookieShift.registerConsentListener" },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": false },
                  { "type": 8, "boolean": true }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: Default denied state and security_storage granted
  code: |-
    const mockData = {
      siteId: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
      waitForUpdate: '1500',
      gtmOnSuccess: () => {},
      gtmOnFailure: () => {}
    };
    let defaults;
    mock('setDefaultConsentState', (obj) => { defaults = obj; });
    mock('queryPermission', () => true);
    mock('injectScript', (url, onSuccess) => { onSuccess(); });
    mock('callInWindow', () => {});
    runCode(mockData);
    assertThat(defaults.ad_storage).isEqualTo('denied');
    assertThat(defaults.ad_user_data).isEqualTo('denied');
    assertThat(defaults.ad_personalization).isEqualTo('denied');
    assertThat(defaults.analytics_storage).isEqualTo('denied');
    assertThat(defaults.functionality_storage).isEqualTo('denied');
    assertThat(defaults.security_storage).isEqualTo('granted');
    assertThat(defaults.wait_for_update).isEqualTo(1500);

- name: Script injection with gcm_owner=gtm and site_id
  code: |-
    const mockData = {
      siteId: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
      waitForUpdate: '1500',
      gtmOnSuccess: () => {},
      gtmOnFailure: () => {}
    };
    let injectedUrl;
    mock('setDefaultConsentState', () => {});
    mock('queryPermission', () => true);
    mock('injectScript', (url, onSuccess) => {
      injectedUrl = url;
      onSuccess();
    });
    mock('callInWindow', () => {});
    runCode(mockData);
    assertThat(injectedUrl).contains('https://cookieshift.com/cmp.js');
    assertThat(injectedUrl).contains('site_id=aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee');
    assertThat(injectedUrl).contains('gcm_owner=gtm');
    assertApi('gtmOnSuccess').wasCalled();

- name: Listener registration after script load
  code: |-
    const mockData = {
      siteId: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
      waitForUpdate: '1500',
      gtmOnSuccess: () => {},
      gtmOnFailure: () => {}
    };
    let calledPath;
    let calledCb;
    mock('setDefaultConsentState', () => {});
    mock('queryPermission', () => true);
    mock('injectScript', (url, onSuccess) => { onSuccess(); });
    mock('callInWindow', (path, cb) => {
      calledPath = path;
      calledCb = cb;
    });
    runCode(mockData);
    assertThat(calledPath).isEqualTo('CookieShift.registerConsentListener');
    assertThat(typeof calledCb).isEqualTo('function');

- name: Analytics consent update
  code: |-
    const mockData = {
      siteId: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
      waitForUpdate: '1500',
      gtmOnSuccess: () => {},
      gtmOnFailure: () => {}
    };
    let updated;
    let listener;
    mock('setDefaultConsentState', () => {});
    mock('updateConsentState', (obj) => { updated = obj; });
    mock('queryPermission', () => true);
    mock('injectScript', (url, onSuccess) => { onSuccess(); });
    mock('callInWindow', (path, cb) => { listener = cb; });
    runCode(mockData);
    listener({
      necessary: true,
      analytics: true,
      marketing: false,
      preferences: false,
      decisionMade: true
    });
    assertThat(updated.analytics_storage).isEqualTo('granted');
    assertThat(updated.ad_storage).isEqualTo('denied');
    assertThat(updated.security_storage).isEqualTo('granted');

- name: Marketing consent update
  code: |-
    const mockData = {
      siteId: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
      waitForUpdate: '1500',
      gtmOnSuccess: () => {},
      gtmOnFailure: () => {}
    };
    let updated;
    let listener;
    mock('setDefaultConsentState', () => {});
    mock('updateConsentState', (obj) => { updated = obj; });
    mock('queryPermission', () => true);
    mock('injectScript', (url, onSuccess) => { onSuccess(); });
    mock('callInWindow', (path, cb) => { listener = cb; });
    runCode(mockData);
    listener({
      necessary: true,
      analytics: false,
      marketing: true,
      preferences: false,
      decisionMade: true
    });
    assertThat(updated.ad_storage).isEqualTo('granted');
    assertThat(updated.ad_user_data).isEqualTo('granted');
    assertThat(updated.ad_personalization).isEqualTo('granted');
    assertThat(updated.analytics_storage).isEqualTo('denied');

- name: Preferences consent update
  code: |-
    const mockData = {
      siteId: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
      waitForUpdate: '1500',
      gtmOnSuccess: () => {},
      gtmOnFailure: () => {}
    };
    let updated;
    let listener;
    mock('setDefaultConsentState', () => {});
    mock('updateConsentState', (obj) => { updated = obj; });
    mock('queryPermission', () => true);
    mock('injectScript', (url, onSuccess) => { onSuccess(); });
    mock('callInWindow', (path, cb) => { listener = cb; });
    runCode(mockData);
    listener({
      necessary: true,
      analytics: false,
      marketing: false,
      preferences: true,
      decisionMade: true
    });
    assertThat(updated.functionality_storage).isEqualTo('granted');
    assertThat(updated.security_storage).isEqualTo('granted');

- name: Invalid Site ID fails without inject
  code: |-
    const mockData = {
      siteId: 'not-a-uuid',
      waitForUpdate: '1500',
      gtmOnSuccess: () => {},
      gtmOnFailure: () => {}
    };
    let injected = false;
    let defaultsSet = false;
    mock('setDefaultConsentState', () => { defaultsSet = true; });
    mock('injectScript', () => { injected = true; });
    mock('callInWindow', () => {});
    mock('queryPermission', () => true);
    runCode(mockData);
    assertThat(defaultsSet).isEqualTo(true);
    assertThat(injected).isEqualTo(false);
    assertApi('gtmOnFailure').wasCalled();

- name: No gtag consent API used
  code: |-
    const mockData = {
      siteId: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
      waitForUpdate: '1500',
      gtmOnSuccess: () => {},
      gtmOnFailure: () => {}
    };
    let usedDefault = false;
    let usedUpdate = false;
    mock('setDefaultConsentState', () => { usedDefault = true; });
    mock('updateConsentState', () => { usedUpdate = true; });
    mock('queryPermission', () => true);
    mock('injectScript', (url, onSuccess) => { onSuccess(); });
    mock('callInWindow', (path, cb) => {
      cb({
        necessary: true,
        analytics: true,
        marketing: true,
        preferences: true,
        decisionMade: true
      });
    });
    runCode(mockData);
    assertThat(usedDefault).isEqualTo(true);
    assertThat(usedUpdate).isEqualTo(true);


___NOTES___

CookieShift Consent Mode Community Template.

Install on Consent Initialization – All Pages only.
Enter the CookieShift Site ID (UUID) from the CookieShift dashboard.
Do not also load the WordPress/Shopify/direct cmp.js snippet on the same page
unless CookieShift documents that combination as compatible.
This template owns Google Consent Mode (gcm_owner=gtm). CookieShift must not
write Consent Mode via the gtag consent API when loaded this way.

GTM injectScript cannot set data-* attributes. The template loads:
https://cookieshift.com/cmp.js?site_id=<UUID>&gcm_owner=gtm
which CookieShift treats as equivalent to:
data-id, data-gcm-owner="gtm", and data-api from the script origin.
