const STORAGE_KEY = 'loginEntries';
const FILLED_FLAG_PREFIX = 'passwordHolderFilled:';
const MAX_ATTEMPTS = 12;
const ATTEMPT_DELAY_MS = 800;

const main = async () => {
  if (!chrome?.storage?.local) {
    return;
  }
  const entries = await getStoredEntries();
  if (!entries.length) {
    return;
  }
  const target = pickMatchingEntry(entries, window.location.href);
  if (!target) {
    return;
  }
  if (hasAlreadyFilled(target)) {
    return;
  }
  waitForFormAndFill(target);
};

main();

function getStoredEntries() {
  return new Promise((resolve) => {
    chrome.storage.local.get([STORAGE_KEY], (result) => {
      resolve(result?.[STORAGE_KEY] ?? []);
    });
  });
}

function pickMatchingEntry(entries, currentUrl) {
  let url;
  try {
    url = new URL(currentUrl);
  } catch (_) {
    return null;
  }
  const currentHost = url.hostname.replace(/^www\./i, '').toLowerCase();
  const currentPath = url.pathname.replace(/\/+$/, '').toLowerCase();
  let bestScore = 0;
  let bestEntry = null;
  entries.forEach((entry) => {
    if (!entry?.loginUrl) return;
    try {
      const entryUrl = new URL(entry.loginUrl);
      const entryHost = entryUrl.hostname.replace(/^www\./i, '').toLowerCase();
      if (entryHost !== currentHost) {
        return;
      }
      const entryPath = entryUrl.pathname.replace(/\/+$/, '').toLowerCase();
      let score = 1;
      if (entryPath && currentPath.startsWith(entryPath)) {
        score += entryPath.length;
      }
      if (score > bestScore) {
        bestScore = score;
        bestEntry = entry;
      }
    } catch (_) {
      /* noop */
    }
  });
  return bestEntry;
}

function waitForFormAndFill(entry, attempt = 0) {
  if (fillForm(entry)) {
    markFilled(entry);
    return;
  }
  if (attempt >= MAX_ATTEMPTS) {
    observeLateForms(entry);
    return;
  }
  setTimeout(() => waitForFormAndFill(entry, attempt + 1), ATTEMPT_DELAY_MS);
}

function fillForm(entry) {
  const emailInput = findEmailInput();
  const passwordInput = findPasswordInput();
  if (!emailInput || !passwordInput) {
    return false;
  }
  setInputValue(emailInput, entry.email);
  setInputValue(passwordInput, entry.password);
  return true;
}

function observeLateForms(entry) {
  const observer = new MutationObserver(() => {
    if (fillForm(entry)) {
      observer.disconnect();
      markFilled(entry);
    }
  });
  observer.observe(document.documentElement, {
    childList: true,
    subtree: true,
  });
  setTimeout(() => observer.disconnect(), 8000);
}

function findEmailInput() {
  const selectors = [
    'input[type="email"]',
    'input[name="username" i]',
    'input[name="user" i]',
    'input[name="login" i]',
    'input[name="log" i]',
    'input[name*="email" i]',
    'input[id*="email" i]',
    'input[id="login_field"]',
    'input[id*="user" i]',
    'input[id*="login" i]',
    'input[placeholder*="mail" i]',
    'input[placeholder*="kullanıcı" i]',
    'input[placeholder*="e-posta" i]',
    'input[placeholder*="email" i]',
    'input[placeholder*="giriş" i]',
  ];
  for (const selector of selectors) {
    const input = document.querySelector(selector);
    if (isFillableInput(input)) {
      return input;
    }
  }
  return null;
}

function findPasswordInput() {
  const selectors = [
    'input[type="password"]',
    'input[name="password" i]',
    'input[name="pass" i]',
    'input[name="pwd" i]',
    'input[id="password"]',
    'input[id*="pass" i]',
    'input[id*="pwd" i]',
    'input[placeholder*="şifre" i]',
    'input[placeholder*="parola" i]',
  ];
  for (const selector of selectors) {
    const input = document.querySelector(selector);
    if (isFillableInput(input)) {
      return input;
    }
  }
  return null;
}

function isFillableInput(input) {
  return (
    input &&
    input instanceof HTMLInputElement &&
    !input.readOnly &&
    !input.disabled &&
    input.offsetParent !== null
  );
}

function setInputValue(input, value) {
  if (typeof value !== 'string' || !input) {
    return;
  }
  input.focus({ preventScroll: true });
  input.value = value;
  input.dispatchEvent(new Event('input', { bubbles: true }));
  input.dispatchEvent(new Event('change', { bubbles: true }));
}

function hasAlreadyFilled(entry) {
  if (!entry?.id) {
    return false;
  }
  const key = FILLED_FLAG_PREFIX + entry.id;
  return sessionStorage.getItem(key) === '1';
}

function markFilled(entry) {
  if (!entry?.id) {
    return;
  }
  const key = FILLED_FLAG_PREFIX + entry.id;
  sessionStorage.setItem(key, '1');
}


