import { USERS_BASE, HOLDERS_BASE } from './apiConfig.js';
const LOGIN_ENTRIES_KEY = 'loginEntries';

const loginSection = document.getElementById('login-section');
const appSection = document.getElementById('app-section');
const loginForm = document.getElementById('login-form');
const loginErrorEl = document.getElementById('login-error');
const userNameEl = document.getElementById('user-name');
const userEmailEl = document.getElementById('user-email');
const refreshBtn = document.getElementById('refresh-btn');
const entryToggleBtn = document.getElementById('entry-toggle-btn');
const logoutBtn = document.getElementById('logout-btn');
const entriesContainer = document.getElementById('entries-container');
const entriesEmpty = document.getElementById('entries-empty');
const entriesError = document.getElementById('entries-error');
const entryTemplate = document.getElementById('entry-template');
const entryForm = document.getElementById('entry-form');
const entryFormPanel = document.getElementById('entry-form-panel');
const entryFormSummary = document.getElementById('entry-form-summary');
const entrySubmitBtn = document.getElementById('entry-submit-btn');
const entryCancelBtn = document.getElementById('entry-cancel-btn');
const entryErrorEl = document.getElementById('entry-error');
const entryIdInput = document.getElementById('entry-id');

const storage = chrome?.storage?.local;

const state = {
  token: null,
  department: null,
  email: null,
  name: null,
  userId: null,
  entries: [],
  entryOrder: [],
  loadingEntries: false,
  savingEntry: false,
  loggingIn: false,
  loggingOut: false,
};

const entryFieldMap = {
  title: ['name', 'holder_title', 'holderTitle', 'title'],
  email: ['email', 'holder_email', 'holderEmail', 'mail', 'username'],
  password: ['password', 'holder_password', 'holderPassword', 'secret'],
  loginUrl: [
    'login_url',
    'loginUrl',
    'loginURL',
    'url',
    'login_link',
    'loginLink',
  ],
  id: ['id', 'holder_id', 'holderId', 'password_id', 'passwordId', 'identifier'],
};

loginForm.addEventListener('submit', handleLogin);
logoutBtn.addEventListener('click', handleLogout);
refreshBtn.addEventListener('click', fetchEntries);
entryForm.addEventListener('submit', submitEntryForm);
entryCancelBtn.addEventListener('click', resetEntryForm);
entryToggleBtn?.addEventListener('click', () => {
  setEntryPanelOpen(!(entryFormPanel?.open ?? false));
});

const emailInput = loginForm?.querySelector('input[name="email"]');
if (emailInput) {
  emailInput.addEventListener('blur', handleEmailBlur);
}

init();

async function init() {
  setupDragAndDropContainer();
  await restoreSession();
  setEntryPanelOpen(false);
  setEntryMode('create');
  if (state.token) {
    await fetchEntries();
  }
}

async function restoreSession() {
  const saved = await storageGet('passwordHolderAuth');
  if (!saved || !saved.token) {
    showLogin();
    return;
  }
  const department = (saved.department ?? '').toLowerCase();
  if (department === 'admin') {
    // Admin oturumunu temizle
    await clearSession();
    showLogin();
    return;
  }
  Object.assign(state, saved);
  const savedOrder = await storageGet('passwordHolderEntryOrder');
  if (savedOrder && Array.isArray(savedOrder)) {
    state.entryOrder = savedOrder;
  }
  applySessionToUi();
  showApp();
}

function applySessionToUi() {
  userNameEl.textContent = state.name ?? 'Kullanıcı';
  userEmailEl.textContent = state.email ?? '';
}

function showLogin() {
  loginSection.hidden = false;
  appSection.hidden = true;
}

function showApp() {
  loginSection.hidden = true;
  appSection.hidden = false;
}

function normalizeEmail(value) {
  const trimmed = value?.trim() ?? '';
  if (!trimmed) return trimmed;
  if (!trimmed.includes('@')) {
    return `${trimmed}@gmail.com`;
  }
  return trimmed;
}

function handleEmailBlur(event) {
  const input = event.target;
  if (!input || input.type !== 'email') return;
  const normalized = normalizeEmail(input.value);
  if (normalized !== input.value.trim()) {
    input.value = normalized;
    input.dispatchEvent(new Event('input', { bubbles: true }));
  }
}

async function handleLogin(event) {
  event.preventDefault();
  if (state.loggingIn) return;
  setLoginError();
  state.loggingIn = true;
  updateLoginUi();
  const formData = new FormData(loginForm);
  const email = normalizeEmail(formData.get('email')?.toString().trim());
  const password = formData.get('password')?.toString();

  try {
    const response = await fetchJson(`${USERS_BASE}/login`, {
      method: 'POST',
      body: JSON.stringify({ email, password }),
      headers: { 'Content-Type': 'application/json' },
    });
    const token = extractToken(response);
    const user = extractUser(response);
    if (!token || !user) {
      throw new Error('Sunucudan beklenen oturum bilgisi alınamadı.');
    }
    const department = (user.department ?? response.department ?? '').toLowerCase();
    if (department === 'admin') {
      throw new Error('Admin kullanıcıları extension üzerinden giriş yapamaz. Lütfen web arayüzünü kullanın.');
    }
    Object.assign(state, {
      token,
      department: user.department ?? response.department ?? null,
      email: user.email ?? response.email ?? email,
      name: user.name ?? response.name ?? 'Kullanıcı',
      userId: user.id ?? response.id ?? null,
    });
    await storageSet('passwordHolderAuth', {
      token: state.token,
      department: state.department,
      email: state.email,
      name: state.name,
      userId: state.userId,
    });
    applySessionToUi();
    showApp();
    loginForm.reset();
    await fetchEntries();
  } catch (error) {
    console.error('Login error:', error);
    setLoginError(error.message);
  } finally {
    state.loggingIn = false;
    updateLoginUi();
  }
}

function updateLoginUi() {
  const submitBtn = loginForm.querySelector('button[type="submit"]');
  if (submitBtn) {
    submitBtn.disabled = state.loggingIn;
    submitBtn.textContent = state.loggingIn ? 'Giriş yapılıyor...' : 'Giriş yap';
  }
}

async function handleLogout() {
  if (state.loggingOut) return;
  state.loggingOut = true;
  logoutBtn.disabled = true;
  try {
    if (state.token) {
      await apiFetch('/logout', { base: USERS_BASE, method: 'POST' });
    }
  } catch (error) {
    console.warn('Logout isteği başarısız:', error);
  } finally {
    state.loggingOut = false;
    logoutBtn.disabled = false;
    await clearSession();
  }
}

async function fetchEntries() {
  if (!state.token) {
    return;
  }
  state.loadingEntries = true;
  refreshBtn.disabled = true;
  entriesError.hidden = true;
  entriesEmpty.hidden = true;
  entriesContainer.innerHTML = '';
  try {
    const entries = await apiFetch('', { base: HOLDERS_BASE });
    if (!Array.isArray(entries)) {
      throw new Error('Beklenmeyen kayıt formatı alındı.');
    }
    state.entries = entries;
    
    // Yeni entry'lerin ID'lerini order'a ekle (eğer yoksa)
    const currentOrderIds = new Set(state.entryOrder);
    entries.forEach((entry) => {
      const id = resolveIdentifier(entry);
      if (id !== null) {
        const idStr = String(id);
        if (!currentOrderIds.has(idStr)) {
          state.entryOrder.push(idStr);
        }
      }
    });
    
    renderEntries();
    await persistLoginEntries(entries);
    if (state.entryOrder.length > 0) {
      await storageSet('passwordHolderEntryOrder', state.entryOrder);
    }
  } catch (error) {
    console.error('Kayıtları çekerken hata:', error);
    entriesError.textContent = error.message ?? String(error);
    entriesError.hidden = false;
  } finally {
    state.loadingEntries = false;
    refreshBtn.disabled = false;
  }
}

function renderEntries() {
  entriesContainer.innerHTML = '';
  if (!state.entries.length) {
    entriesEmpty.hidden = false;
    return;
  }
  entriesEmpty.hidden = true;
  
  // Sıralama: entryOrder'a göre sırala, yoksa mevcut sırayı koru
  const sortedEntries = [...state.entries].sort((a, b) => {
    const aId = String(resolveIdentifier(a) ?? '');
    const bId = String(resolveIdentifier(b) ?? '');
    const aIndex = state.entryOrder.indexOf(aId);
    const bIndex = state.entryOrder.indexOf(bId);
    
    // Eğer ikisi de order'da yoksa, mevcut sırayı koru
    if (aIndex === -1 && bIndex === -1) return 0;
    // Sadece a yoksa, a'yı sona koy
    if (aIndex === -1) return 1;
    // Sadece b yoksa, b'yi sona koy
    if (bIndex === -1) return -1;
    // İkisi de order'da varsa, order'a göre sırala
    return aIndex - bIndex;
  });
  
  sortedEntries.forEach((entry, index) => {
    const fragment = entryTemplate.content.cloneNode(true);
    const entryCard = fragment.querySelector('.entry-card');
    const entryId = resolveIdentifier(entry);
    if (entryId !== null) {
      entryCard.dataset.entryId = String(entryId);
    }
    const title = resolveField(entry, entryFieldMap.title) ?? 'İsimsiz kart';
    const email = resolveField(entry, entryFieldMap.email) ?? '—';
    const password = resolveField(entry, entryFieldMap.password) ?? '—';
    const loginUrl = resolveField(entry, entryFieldMap.loginUrl);
    fragment.querySelector('.entry-title').textContent = title;
    const emailContainer = fragment.querySelector('.entry-email');
    const emailValueEl = emailContainer.querySelector('.entry-field-value');
    emailValueEl.textContent = email;
    attachCopyBehavior(emailContainer, email);
    const passwordContainer = fragment.querySelector('.entry-password');
    const passwordValueEl =
      passwordContainer.querySelector('.entry-field-value');
    passwordValueEl.textContent = password;
    attachCopyBehavior(passwordContainer, password);
    const loginButton = fragment.querySelector('.entry-login-btn');
    attachLoginLink(loginButton, loginUrl);
    const dragHandle = fragment.querySelector('.entry-drag-handle');
    if (dragHandle) {
      attachDragAndDrop(entryCard, dragHandle, entry);
    }
    const editBtn = fragment.querySelector('.entry-edit-btn');
    const deleteBtn = fragment.querySelector('.entry-delete-btn');
    const menuWrapper = fragment.querySelector('.entry-menu-wrapper');
    const canModify = canModifyEntry(entry);
    if (!canModify && menuWrapper) {
      menuWrapper.style.display = 'none';
    }
    editBtn.disabled = !canModify;
    deleteBtn.disabled = !canModify;
    editBtn.addEventListener('click', () => {
      closeEntryMenu(entryCard);
      startEditing(entry);
    });
    deleteBtn.addEventListener('click', () => {
      closeEntryMenu(entryCard);
      confirmAndDelete(entry);
    });
    attachEntryToggle(entryCard);
    if (canModify) {
      attachEntryMenu(entryCard);
    }
    entriesContainer.appendChild(fragment);
  });
}

function startEditing(entry) {
  const id = resolveIdentifier(entry);
  if (!id) {
    alert('Kayıt kimliği bulunamadı.');
    return;
  }
  setEntryPanelOpen(true);
  entryIdInput.value = String(id);
  entryForm.elements.name.value =
    resolveField(entry, entryFieldMap.title) ?? '';
  entryForm.elements.email.value =
    resolveField(entry, entryFieldMap.email) ?? '';
  entryForm.elements.password.value =
    resolveField(entry, entryFieldMap.password) ?? '';
  entryForm.elements.loginUrl.value =
    resolveField(entry, entryFieldMap.loginUrl) ?? '';
  setEntryMode('edit');
}

async function confirmAndDelete(entry) {
  if (!canModifyEntry(entry)) {
    alert('Bu kartı yalnızca admin silebilir.');
    return;
  }
  const id = resolveIdentifier(entry);
  if (!id) {
    alert('Kayıt kimliği bulunamadı.');
    return;
  }
  const confirmed = confirm('Bu kaydı silmek istediğinize emin misiniz?');
  if (!confirmed) return;
  try {
    await apiFetch(`/${id}`, { base: HOLDERS_BASE, method: 'DELETE' });
    state.entries = state.entries.filter(
      (item) => resolveIdentifier(item) !== id,
    );
    renderEntries();
  } catch (error) {
    alert(`Silme başarısız: ${error.message ?? error}`);
  }
}

async function submitEntryForm(event) {
  event.preventDefault();
  if (state.savingEntry) return;
  entryErrorEl.hidden = true;
  entryErrorEl.textContent = '';
  const formData = new FormData(entryForm);
  const payload = {
    name: formData.get('name')?.toString().trim(),
    email: formData.get('email')?.toString().trim(),
    password: formData.get('password')?.toString(),
    loginUrl: normalizeLoginUrl(formData.get('loginUrl')),
  };
  if (!payload.name || !payload.email || !payload.password) {
    entryErrorEl.textContent = 'Tüm alanlar zorunludur.';
    entryErrorEl.hidden = false;
    return;
  }
  const entryId = formData.get('entryId');
  const isUpdate = entryId && entryId.toString().trim().length > 0;
  state.savingEntry = true;
  entrySubmitBtn.disabled = true;
  entrySubmitBtn.textContent = isUpdate ? 'Güncelleniyor...' : 'Kaydediliyor...';
  try {
    if (isUpdate) {
      await apiFetch(`/${entryId}`, {
        base: HOLDERS_BASE,
        method: 'PUT',
        body: JSON.stringify(payload),
      });
    } else {
      await apiFetch('', {
        base: HOLDERS_BASE,
        method: 'POST',
        body: JSON.stringify(payload),
      });
    }
    resetEntryForm();
    await fetchEntries();
  } catch (error) {
    console.error('Entry kaydı hata:', error);
    entryErrorEl.textContent = error.message ?? String(error);
    entryErrorEl.hidden = false;
  } finally {
    state.savingEntry = false;
    entrySubmitBtn.disabled = false;
    entrySubmitBtn.textContent = isUpdate ? 'Güncelle' : 'Kaydet';
  }
}

function resetEntryForm() {
  entryForm.reset();
  entryIdInput.value = '';
  setEntryPanelOpen(false);
  setEntryMode('create');
  entryErrorEl.hidden = true;
  // Form temizlendiğinde aktif sekme URL'sini doldur (form açıldığında kullanılacak)
  fillCurrentTabUrl();
}

function attachCopyBehavior(container, value) {
  if (!container) return;
  container.dataset.copyValue = value ?? '';
  const valueEl = container.querySelector('.entry-field-value');
  const handler = (event) => {
    event.stopPropagation();
    copyToClipboard(container.dataset.copyValue ?? '');
  };
  if (valueEl) {
    valueEl.addEventListener('click', handler);
  }
}

function attachLoginLink(button, url) {
  if (!button) return;
  if (url && url.trim().length > 0) {
    const normalized = normalizeLoginUrl(url);
    button.disabled = false;
    button.textContent = formatUrlChip(normalized);
    button.title = normalized;
    button.dataset.url = normalized;
    button.onclick = (event) => {
      event.stopPropagation();
      openLoginUrl(normalized);
    };
  } else {
    button.disabled = true;
    button.textContent = '—';
    button.title = 'Bağlantı yok';
    button.dataset.url = '';
    button.onclick = null;
  }
}

function openLoginUrl(url) {
  if (!url) {
    showToast('Bağlantı bulunamadı');
    return;
  }
  try {
    if (chrome?.tabs?.create) {
      chrome.tabs.create({ url });
    } else {
      window.open(url, '_blank', 'noopener,noreferrer');
    }
  } catch (error) {
    showToast(error.message ?? 'Bağlantı açılamadı');
  }
}

async function copyToClipboard(value) {
  if (!value) return;
  try {
    await navigator.clipboard.writeText(value);
    showToast('Kopyalandı');
  } catch (error) {
    console.warn('Kopyalama başarısız:', error);
  }
}

let draggedCard = null;
let dragAnimationFrame = null;
let lastDragY = null;

function attachDragAndDrop(entryCard, dragHandle, entry) {
  dragHandle.addEventListener('dragstart', (e) => {
    draggedCard = entryCard;
    entryCard.classList.add('dragging');
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/plain', '');
    lastDragY = e.clientY;
  });
  
  dragHandle.addEventListener('dragend', async () => {
    if (draggedCard) {
      draggedCard.classList.remove('dragging');
      
      const newOrder = Array.from(entriesContainer.children)
        .map((card) => card.dataset.entryId)
        .filter((id) => id !== undefined);
      
      state.entryOrder = newOrder;
      await storageSet('passwordHolderEntryOrder', newOrder);
      showToast('Sıralama kaydedildi');
      
      draggedCard = null;
    }
    if (dragAnimationFrame) {
      cancelAnimationFrame(dragAnimationFrame);
      dragAnimationFrame = null;
    }
    lastDragY = null;
  });
  
  entryCard.addEventListener('dragover', (e) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    
    if (!draggedCard || draggedCard === entryCard) return;
    
    lastDragY = e.clientY;
    
    if (dragAnimationFrame) {
      cancelAnimationFrame(dragAnimationFrame);
    }
    
    dragAnimationFrame = requestAnimationFrame(() => {
      updateDragPosition(e.clientY);
    });
  });
  
  entryCard.addEventListener('drop', (e) => {
    e.preventDefault();
  });
}

function updateDragPosition(y) {
  if (!draggedCard) return;
  
  const afterElement = getDragAfterElement(entriesContainer, y);
  const currentNextSibling = draggedCard.nextSibling;
  
  // Eğer pozisyon değişmediyse işlem yapma
  if (afterElement === currentNextSibling) return;
  
  // Smooth hareket için DOM manipülasyonu
  if (afterElement == null) {
    // En sona ekle
    if (draggedCard !== entriesContainer.lastElementChild) {
      entriesContainer.appendChild(draggedCard);
    }
  } else {
    // Belirtilen elementin önüne ekle
    if (draggedCard !== afterElement && draggedCard.nextSibling !== afterElement) {
      entriesContainer.insertBefore(draggedCard, afterElement);
    }
  }
}

function setupDragAndDropContainer() {
  if (!entriesContainer) return;
  
  entriesContainer.addEventListener('dragover', (e) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    
    if (!draggedCard) return;
    
    lastDragY = e.clientY;
    
    if (dragAnimationFrame) {
      cancelAnimationFrame(dragAnimationFrame);
    }
    
    dragAnimationFrame = requestAnimationFrame(() => {
      updateDragPosition(e.clientY);
    });
  });
  
  entriesContainer.addEventListener('drop', (e) => {
    e.preventDefault();
  });
}

function getDragAfterElement(container, y) {
  const draggableElements = [...container.querySelectorAll('.entry-card:not(.dragging)')];
  
  if (draggableElements.length === 0) return null;
  
  return draggableElements.reduce((closest, child) => {
    const box = child.getBoundingClientRect();
    const offset = y - box.top - box.height / 2;
    
    if (offset < 0 && offset > closest.offset) {
      return { offset: offset, element: child };
    } else {
      return closest;
    }
  }, { offset: Number.NEGATIVE_INFINITY }).element;
}

let toastTimeout;
function showToast(message) {
  let toast = document.getElementById('copy-toast');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'copy-toast';
    toast.className = 'toast';
    document.body.appendChild(toast);
  }
  toast.textContent = message;
  toast.classList.add('visible');
  clearTimeout(toastTimeout);
  toastTimeout = setTimeout(() => {
    toast.classList.remove('visible');
  }, 1500);
}

function canModifyEntry(entry) {
  if ((state.department ?? '').toLowerCase() === 'admin') {
    return true;
  }
  const control = parseInt(entry.control ?? entry.Control ?? entry.Cntrl, 10);
  return Number.isNaN(control) || control === 0;
}

function resolveField(entry, keys) {
  for (const key of keys) {
    const value = entry[key];
    if (value !== undefined && value !== null) {
      const str = value.toString().trim();
      if (str.length) return str;
    }
  }
  return undefined;
}

function resolveIdentifier(entry) {
  for (const key of entryFieldMap.id) {
    const value = entry[key];
    const parsed = parseInt(value, 10);
    if (!Number.isNaN(parsed)) {
      return parsed;
    }
  }
  for (const key of Object.keys(entry)) {
    if (key.toLowerCase().includes('id')) {
      const parsed = parseInt(entry[key], 10);
      if (!Number.isNaN(parsed)) {
        return parsed;
      }
    }
  }
  return null;
}

function setLoginError(message) {
  if (!message) {
    loginErrorEl.hidden = true;
    loginErrorEl.textContent = '';
    return;
  }
  loginErrorEl.hidden = false;
  loginErrorEl.textContent = message;
}

function normalizeLoginUrl(value) {
  if (!value) return null;
  const trimmed = value.toString().trim();
  if (!trimmed) return null;
  if (/^https?:\/\//i.test(trimmed)) {
    return trimmed;
  }
  return `https://${trimmed}`;
}

function formatUrlChip(url) {
  try {
    const parsed = new URL(url);
    return parsed.hostname.replace(/^www\./, '');
  } catch (_) {
    return url.length > 20 ? `${url.slice(0, 20)}…` : url;
  }
}

function persistLoginEntries(entries) {
  if (!chrome?.storage?.local) {
    return Promise.resolve();
  }
  const payload = (entries ?? [])
    .map((entry) => {
      const loginUrl = normalizeLoginUrl(resolveField(entry, entryFieldMap.loginUrl));
      const email = resolveField(entry, entryFieldMap.email);
      const password = resolveField(entry, entryFieldMap.password);
      if (!loginUrl || !email || !password) {
        return null;
      }
      return {
        id: resolveIdentifier(entry),
        loginUrl,
        email,
        password,
        title: resolveField(entry, entryFieldMap.title),
      };
    })
    .filter((item) => item !== null);
  return new Promise((resolve) => {
    chrome.storage.local.set({ [LOGIN_ENTRIES_KEY]: payload }, resolve);
  });
}

function attachEntryToggle(card) {
  if (!card) return;
  const header = card.querySelector('.entry-header');
  if (!header) return;
  setEntryCardExpanded(card, false);
  header.addEventListener('click', () => {
    closeAllEntryMenus();
    const willExpand = !card.classList.contains('expanded');
    setEntryCardExpanded(card, willExpand);
  });
}

function setEntryCardExpanded(card, expand) {
  if (expand) {
    collapseOtherEntryCards(card);
    card.classList.add('expanded');
    card.classList.remove('collapsed');
  } else {
    card.classList.remove('expanded');
    card.classList.add('collapsed');
  }
}

function collapseOtherEntryCards(currentCard) {
  if (!entriesContainer) return;
  const cards = entriesContainer.querySelectorAll('.entry-card');
  cards.forEach((card) => {
    if (card !== currentCard) {
      card.classList.remove('expanded');
      card.classList.add('collapsed');
    }
  });
}

function attachEntryMenu(card) {
  const menuBtn = card.querySelector('.entry-menu-btn');
  const menu = card.querySelector('.entry-menu');
  if (!menuBtn || !menu) return;
  menuBtn.addEventListener('click', (event) => {
    event.stopPropagation();
    const willExpand = card.classList.contains('menu-open');
    closeAllEntryMenus(card);
    if (!willExpand) {
      openEntryMenu(card);
    }
  });
  ensureGlobalMenuCloser();
}

function openEntryMenu(card) {
  const menuBtn = card.querySelector('.entry-menu-btn');
  const menu = card.querySelector('.entry-menu');
  if (!menuBtn || !menu) return;
  card.classList.add('menu-open');
  menuBtn.setAttribute('aria-expanded', 'true');
  menu.classList.add('visible');
}

function closeEntryMenu(card) {
  if (!card) return;
  const menuBtn = card.querySelector('.entry-menu-btn');
  const menu = card.querySelector('.entry-menu');
  if (menuBtn) {
    menuBtn.setAttribute('aria-expanded', 'false');
  }
  if (menu) {
    menu.classList.remove('visible');
  }
  card.classList.remove('menu-open');
}

function closeAllEntryMenus(exceptCard) {
  if (!entriesContainer) return;
  entriesContainer.querySelectorAll('.entry-card.menu-open').forEach((card) => {
    if (card === exceptCard) return;
    closeEntryMenu(card);
  });
}

let menuCloserAttached = false;
function ensureGlobalMenuCloser() {
  if (menuCloserAttached) return;
  menuCloserAttached = true;
  document.addEventListener('click', (event) => {
    if (event.target.closest('.entry-menu-wrapper')) {
      return;
    }
    closeAllEntryMenus();
  });
}

function setEntryPanelOpen(forceOpen) {
  if (!entryFormPanel) return;
  if (typeof forceOpen === 'boolean') {
    entryFormPanel.open = forceOpen;
  } else {
    entryFormPanel.open = !entryFormPanel.open;
  }
  syncEntryPanelToggleState();
  if (entryFormPanel.open) {
    entryToggleBtn?.setAttribute('aria-label', 'Kayıt formunu kapat');
    // Form açıldığında ve yeni kayıt modundaysa aktif sekme URL'sini doldur
    if (entryFormSummary?.dataset.mode !== 'edit') {
      fillCurrentTabUrl();
    }
  } else {
    entryToggleBtn?.setAttribute('aria-label', 'Yeni kayıt formunu aç');
  }
}

function syncEntryPanelToggleState() {
  if (!entryToggleBtn || !entryFormPanel) return;
  const isOpen = entryFormPanel.open;
  const isEdit = entryFormSummary?.dataset.mode === 'edit';
  entryToggleBtn.setAttribute('aria-expanded', String(isOpen));
  let symbol = '+';
  if (isEdit) {
    symbol = '✎';
  } else if (isOpen) {
    symbol = '×';
  }
  entryToggleBtn.textContent = symbol;
}

function setEntryMode(mode) {
  if (!entryFormSummary) return;
  if (mode === 'edit') {
    entryFormSummary.dataset.mode = 'edit';
    entryFormSummary.setAttribute('aria-label', 'Kaydı düzenle');
    entrySubmitBtn.textContent = 'Güncelle';
    setEntryPanelOpen(true);
  } else {
    delete entryFormSummary.dataset.mode;
    entryFormSummary.setAttribute('aria-label', 'Yeni kayıt oluştur');
    entrySubmitBtn.textContent = 'Kaydet';
    // Yeni kayıt moduna geçildiğinde aktif sekme URL'sini doldur
    fillCurrentTabUrl();
  }
  syncEntryPanelToggleState();
}

async function fillCurrentTabUrl() {
  if (!entryForm || !entryForm.elements.loginUrl) return;
  // Eğer loginUrl alanı zaten doluysa, değiştirme
  const currentValue = entryForm.elements.loginUrl.value?.trim();
  if (currentValue) return;
  
  try {
    // Chrome extension API'sini kullanarak aktif sekmenin URL'sini al
    if (chrome?.tabs?.query) {
      const tabs = await new Promise((resolve) => {
        chrome.tabs.query({ active: true, currentWindow: true }, resolve);
      });
      if (tabs && tabs.length > 0 && tabs[0].url) {
        const url = tabs[0].url;
        // Sadece http/https URL'lerini kabul et (chrome://, about:, vb. hariç)
        if (url && /^https?:\/\//i.test(url)) {
          entryForm.elements.loginUrl.value = url;
        }
      }
    }
  } catch (error) {
    console.warn('Aktif sekme URL\'si alınamadı:', error);
  }
}

async function clearSession() {
  Object.assign(state, {
    token: null,
    department: null,
    email: null,
    name: null,
    userId: null,
    entries: [],
  });
  if (chrome?.storage?.local) {
    chrome.storage.local.remove(LOGIN_ENTRIES_KEY);
  }
  await storageRemove('passwordHolderAuth');
  showLogin();
}

async function apiFetch(path, { base, method = 'GET', body } = {}) {
  if (!state.token) {
    throw new Error('Oturum bulunamadı. Tekrar giriş yapın.');
  }
  const headers = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${state.token}`,
  };
  const response = await fetch(`${base}${path}`, {
    method,
    headers,
    body,
  });
  if (!response.ok) {
    const text = await response.text();
    throw new Error(parseErrorMessage(text) ?? `${response.status} - ${text}`);
  }
  if (response.status === 204) {
    return null;
  }
  const contentType = response.headers.get('content-type') ?? '';
  if (contentType.includes('application/json')) {
    return response.json();
  }
  return response.text();
}

async function fetchJson(url, options) {
  const response = await fetch(url, options);
  if (!response.ok) {
    const text = await response.text();
    throw new Error(parseErrorMessage(text) ?? `${response.status} - ${text}`);
  }
  const contentType = response.headers.get('content-type') ?? '';
  if (contentType.includes('application/json')) {
    return response.json();
  }
  return response.text();
}

function parseErrorMessage(text) {
  if (!text) return null;
  try {
    const parsed = JSON.parse(text);
    if (parsed?.message) {
      return parsed.message;
    }
  } catch (error) {
    /* noop */
  }
  return text;
}

function extractToken(source) {
  if (!source) return null;
  if (typeof source === 'string') {
    return source;
  }
  if (source.token && typeof source.token === 'string') {
    return source.token;
  }
  if (source.jwt && typeof source.jwt === 'string') {
    return source.jwt;
  }
  if (typeof source === 'object') {
    for (const value of Object.values(source)) {
      const nested = extractToken(value);
      if (nested) return nested;
    }
  }
  return null;
}

function extractUser(source) {
  if (!source || typeof source !== 'object') {
    return null;
  }
  if (source.user && typeof source.user === 'object') {
    return source.user;
  }
  if (
    source.email &&
    source.name &&
    (source.department || source.departmentId)
  ) {
    return source;
  }
  for (const value of Object.values(source)) {
    if (value && typeof value === 'object') {
      const nested = extractUser(value);
      if (nested) return nested;
    }
  }
  return null;
}

function storageGet(key) {
  if (!storage) {
    return Promise.resolve(null);
  }
  return new Promise((resolve) => {
    storage.get([key], (result) => resolve(result?.[key] ?? null));
  });
}

function storageSet(key, value) {
  if (!storage) {
    return Promise.resolve();
  }
  return new Promise((resolve) => {
    storage.set({ [key]: value }, resolve);
  });
}

function storageRemove(key) {
  if (!storage) {
    return Promise.resolve();
  }
  return new Promise((resolve) => {
    storage.remove(key, resolve);
  });
}

