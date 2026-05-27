const API = {
  me: '/api/admin/me',
  adminLogs: '/api/admin/logs',
  regions: '/api/regions',
  stores: '/api/stores',
  beacons: '/api/beacons',
  products: '/api/admin/products',
  recipes: '/api/admin/recipes',
  recipeTags: '/api/admin/recipe-tags',
};

const state = {
  regions: [],
  stores: [],
  beacons: [],
  products: [],
  recipes: [],
  selectedRecipeDetail: null,
  currentUser: null,
  selectedStoreId: null,
  selectedStoreDetail: null,
  selectedStoreBeacons: [],
  selectedStoreLayouts: [],
  selectedStoreAudit: [],
  systemLogs: [],
  systemLogsExpanded: false,
  editingRegionId: null,
  editingStoreId: null,
  editingBeaconId: null,
  editingProductId: null,
  editingRecipeId: null,
  storeFilters: {
    query: '',
    status: 'ACTIVE',
    regionId: '',
  },
  beaconFilters: {
    query: '',
    assignment: 'all',
  },
  recipeFilters: {
    query: '',
    status: '',
  },
};

const ROUTES = {
  dashboard: '/admin/',
  regions: '/admin/regions/',
  stores: '/admin/stores/',
  'store-detail': '/admin/stores/detail/',
  beacons: '/admin/beacons/',
  products: '/admin/products/',
  recipes: '/admin/recipes/',
};

function currentRoute() {
  const path = window.location.pathname.replace(/\/+$/, '/') || '/admin/';
  if (path === '/admin/' || path === '/admin') return 'dashboard';
  if (path.startsWith('/admin/regions/')) return 'regions';
  if (path.startsWith('/admin/stores/detail/')) return 'store-detail';
  if (path.startsWith('/admin/stores/')) return 'stores';
  if (path.startsWith('/admin/beacons/')) return 'beacons';
  if (path.startsWith('/admin/products/')) return 'products';
  if (path.startsWith('/admin/recipes/')) return 'recipes';
  return 'dashboard';
}

function storeIdFromUrl() {
  return new URLSearchParams(window.location.search).get('storeId');
}

function applyPageRoute() {
  const route = currentRoute();
  document.body.dataset.page = route;
  document.querySelectorAll('[data-route-section]').forEach((section) => {
    section.classList.toggle('route-hidden', section.dataset.routeSection !== route);
  });
  document.querySelectorAll('[data-route]').forEach((link) => {
    link.classList.toggle('active', link.dataset.route === route);
    if (link.dataset.route === route) {
      link.setAttribute('aria-current', 'page');
    } else {
      link.removeAttribute('aria-current');
    }
  });
}

const els = {
  pageStatus: document.getElementById('pageStatus'),
  statRegions: document.getElementById('statRegions'),
  statStores: document.getElementById('statStores'),
  statFreeBeacons: document.getElementById('statFreeBeacons'),
  statAssignedBeacons: document.getElementById('statAssignedBeacons'),
  refreshAllBtn: document.getElementById('refreshAllBtn'),
  toggleSystemLogsBtn: document.getElementById('toggleSystemLogsBtn'),
  refreshLogsBtn: document.getElementById('refreshLogsBtn'),
  refreshBeaconsBtn: document.getElementById('refreshBeaconsBtn'),
  refreshStoreDetailBtn: document.getElementById('refreshStoreDetailBtn'),
  openEditorLink: document.getElementById('openEditorLink'),
  systemLogs: document.getElementById('systemLogs'),
  regionsList: document.getElementById('regionsList'),
  regionForm: document.getElementById('regionForm'),
  regionFormTitle: document.getElementById('regionFormTitle'),
  resetRegionFormBtn: document.getElementById('resetRegionFormBtn'),
  cancelRegionEditBtn: document.getElementById('cancelRegionEditBtn'),
  storesList: document.getElementById('storesList'),
  storeForm: document.getElementById('storeForm'),
  storeFormTitle: document.getElementById('storeFormTitle'),
  resetStoreFormBtn: document.getElementById('resetStoreFormBtn'),
  cancelStoreEditBtn: document.getElementById('cancelStoreEditBtn'),
  storeQuery: document.getElementById('storeQuery'),
  storeStatusFilter: document.getElementById('storeStatusFilter'),
  storeRegionFilter: document.getElementById('storeRegionFilter'),
  applyStoreFiltersBtn: document.getElementById('applyStoreFiltersBtn'),
  storeRegionInput: document.getElementById('storeRegionInput'),
  storeDetailEmpty: document.getElementById('storeDetailEmpty'),
  storeDetailContent: document.getElementById('storeDetailContent'),
  storeMeta: document.getElementById('storeMeta'),
  storeBeaconList: document.getElementById('storeBeaconList'),
  storeLayoutVersions: document.getElementById('storeLayoutVersions'),
  storeAuditTrail: document.getElementById('storeAuditTrail'),
  beaconForm: document.getElementById('beaconForm'),
  beaconFormTitle: document.getElementById('beaconFormTitle'),
  cancelBeaconEditBtn: document.getElementById('cancelBeaconEditBtn'),
  beaconBulkForm: document.getElementById('beaconBulkForm'),
  beaconsList: document.getElementById('beaconsList'),
  beaconAssignmentFilter: document.getElementById('beaconAssignmentFilter'),
  beaconQuery: document.getElementById('beaconQuery'),
  applyBeaconFiltersBtn: document.getElementById('applyBeaconFiltersBtn'),
  refreshProductsBtn: document.getElementById('refreshProductsBtn'),
  productsList: document.getElementById('productsList'),
  productForm: document.getElementById('productForm'),
  resetProductFormBtn: document.getElementById('resetProductFormBtn'),
  refreshRecipesBtn: document.getElementById('refreshRecipesBtn'),
  recipesList: document.getElementById('recipesList'),
  recipeForm: document.getElementById('recipeForm'),
  recipeFormTitle: document.getElementById('recipeFormTitle'),
  resetRecipeFormBtn: document.getElementById('resetRecipeFormBtn'),
  recipeQuery: document.getElementById('recipeQuery'),
  recipeStatusFilter: document.getElementById('recipeStatusFilter'),
  applyRecipeFiltersBtn: document.getElementById('applyRecipeFiltersBtn'),
  recipeDetailTools: document.getElementById('recipeDetailTools'),
  recipeIngredientForm: document.getElementById('recipeIngredientForm'),
  recipeStepForm: document.getElementById('recipeStepForm'),
  recipeMappingPreview: document.getElementById('recipeMappingPreview'),
  currentUserName: document.getElementById('currentUserName'),
  currentUserRole: document.getElementById('currentUserRole'),
  currentUserScope: document.getElementById('currentUserScope'),
  logoutLink: document.getElementById('logoutLink'),
};

function setStatus(message, tone = 'neutral') {
  els.pageStatus.textContent = message;
  els.pageStatus.className = tone === 'error' ? 'error-banner banner' : 'banner';
  if (tone === 'neutral') {
    els.pageStatus.className = '';
  }
}

async function fetchJson(url, options = {}) {
  const response = await fetch(url, {
    credentials: 'same-origin',
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
    ...options,
  });

  if (response.redirected && response.url.includes('/keycloak/')) {
    window.location.href = '/admin/';
    throw new Error('Login erforderlich.');
  }

  if (!response.ok) {
    if (response.status === 401) {
      window.location.href = '/admin/';
      throw new Error('Login erforderlich.');
    }

    let message = `Request failed with status ${response.status}`;
    const rawBody = await response.text();

    if (rawBody) {
      try {
        const payload = JSON.parse(rawBody);
        message = payload.error || payload.message || payload.details || rawBody || message;
      } catch (_error) {
        message = rawBody.trim().startsWith('<') ? message : rawBody;
      }
    }

    const error = new Error(message);
    error.status = response.status;
    throw error;
  }

  if (response.status === 204) {
    return null;
  }

  const contentType = response.headers.get('content-type') || '';
  if (!contentType.includes('application/json')) {
    window.location.href = '/admin/';
    throw new Error('Login erforderlich.');
  }

  return response.json();
}

async function loadCurrentUser() {
  state.currentUser = await fetchJson(API.me);
}

function renderCurrentUser() {
  if (!state.currentUser) {
    return;
  }

  const { username, email, role, scope } = state.currentUser;
  document.body.dataset.adminRole = role || 'unknown';
  els.currentUserName.textContent = username || email || 'Admin';
  els.currentUserRole.textContent = roleLabel(role);

  if (scope?.storeName) {
    els.currentUserScope.textContent = `Filiale: ${scope.storeName}`;
  } else if (scope?.regionName) {
    els.currentUserScope.textContent = `Region: ${scope.regionName}`;
  } else {
    els.currentUserScope.textContent = 'Alle Regionen und Filialen';
  }
}

function isAdmin() {
  return state.currentUser?.role === 'admin';
}

function isRegionManager() {
  return state.currentUser?.role === 'region-manager';
}

function isStoreManager() {
  return state.currentUser?.role === 'store-manager';
}

function canCreateStore() {
  return isAdmin() || isRegionManager();
}

function applyRoleUi() {
  const systemLogsPanel = document.getElementById('system-logs');
  systemLogsPanel?.classList.toggle('hidden', !isAdmin());
  document.querySelector('a[href="/admin/server-logs/"]')?.classList.toggle('hidden', !isAdmin());
  document.querySelectorAll('.admin-only').forEach((element) => {
    element.classList.toggle('hidden', !isAdmin());
  });
  els.resetRegionFormBtn.classList.toggle('hidden', !isAdmin());
  els.regionForm.classList.toggle('hidden', !isAdmin());
  els.resetStoreFormBtn.classList.toggle('hidden', !canCreateStore());
  els.storeForm.classList.toggle('hidden', !canCreateStore());

  if (!isAdmin() && ['products', 'recipes'].includes(currentRoute())) {
    window.location.replace('/admin/');
  }
}

function roleLabel(role) {
  if (role === 'admin') return 'Administrator';
  if (role === 'region-manager') return 'Region Manager';
  if (role === 'store-manager') return 'Store Manager';
  return role || 'Unbekannte Rolle';
}

function showAccessDenied(message) {
  setStatus(message || 'Kein Zugriff auf diese Admin-Funktion.', 'error');
}

function handleUiError(error) {
  if (error.status === 403) {
    showAccessDenied(error.message);
    return;
  }
  setStatus(error.message, 'error');
}

function formatDate(value) {
  if (!value) {
    return 'Noch nicht';
  }
  return new Intl.DateTimeFormat('de-AT', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));
}

function formatPrice(value) {
  if (value === null || value === undefined || Number.isNaN(Number(value))) {
    return '-';
  }

  return new Intl.NumberFormat('de-AT', {
    style: 'currency',
    currency: 'EUR',
  }).format(Number(value));
}

function formatCoordinates(latitude, longitude) {
  if (latitude === null || latitude === undefined || longitude === null || longitude === undefined) {
    return 'Nicht hinterlegt';
  }
  return `${Number(latitude).toFixed(7)}, ${Number(longitude).toFixed(7)}`;
}

function escapeHtml(value) {
  return String(value ?? '').replace(/[&<>"']/g, (char) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;'
  }[char]));
}

function normalizeBeaconUuid(value) {
  return String(value ?? '')
    .trim()
    .replace(/-/g, '')
    .toLowerCase();
}

function statusBadge(status) {
  if (status === 'ARCHIVED') {
    return '<span class="badge warn">Archiviert</span>';
  }
  return '<span class="badge">Aktiv</span>';
}

function assignmentBadge(beacon) {
  if (beacon.currentStore) {
    return `<span class="badge neutral">${escapeHtml(beacon.currentStore.name)}</span>`;
  }
  return '<span class="badge warn">Frei</span>';
}

function getRegionById(regionId) {
  return state.regions.find((region) => region.id === regionId) || null;
}

function getStoreById(storeId) {
  return state.stores.find((store) => store.id === storeId) || null;
}

function scrollToStoreDetail() {
  if (state.selectedStoreId) {
    window.location.href = `/admin/stores/detail/?storeId=${encodeURIComponent(state.selectedStoreId)}`;
  } else {
    window.location.href = '/admin/stores/detail/';
  }
}

async function loadBootstrapData() {
  const storeQuery = new URLSearchParams({
    status: state.storeFilters.status,
    size: '100',
    ...(state.storeFilters.query ? { query: state.storeFilters.query } : {}),
    ...(state.storeFilters.regionId ? { regionId: state.storeFilters.regionId } : {}),
  });

  const assigned = state.beaconFilters.assignment === 'all'
    ? ''
    : state.beaconFilters.assignment === 'assigned'
      ? 'true'
      : 'false';

  const beaconQuery = new URLSearchParams({
    status: 'ACTIVE',
    ...(assigned ? { assigned } : {}),
    ...(state.beaconFilters.query ? { query: state.beaconFilters.query } : {}),
  });

  const [regions, storesPage, beacons] = await Promise.all([
    fetchJson(`${API.regions}?status=ACTIVE`),
    fetchJson(`${API.stores}?${storeQuery.toString()}`),
    fetchJson(`${API.beacons}?${beaconQuery.toString()}`),
  ]);

  state.regions = regions;
  state.stores = storesPage.content || [];
  state.beacons = beacons;

  if (state.selectedStoreId && !state.stores.some((store) => store.id === state.selectedStoreId)) {
    state.selectedStoreId = null;
    clearSelectedStoreDetail();
  }
}

async function loadSystemLogs() {
  if (!isAdmin()) {
    state.systemLogs = [];
    return;
  }

  const payload = await fetchJson(`${API.adminLogs}?limit=20`);
  state.systemLogs = payload.entries || [];
}

async function loadProducts() {
  if (!isAdmin()) {
    state.products = [];
    return;
  }

  state.products = await fetchJson(`${API.products}?size=500`);
}

async function loadRecipes() {
  if (!isAdmin()) {
    state.recipes = [];
    state.selectedRecipeDetail = null;
    return;
  }

  const query = new URLSearchParams({
    page: '0',
    size: '100',
    ...(state.recipeFilters.query ? { q: state.recipeFilters.query } : {}),
    ...(state.recipeFilters.status ? { status: state.recipeFilters.status } : {}),
  });
  const page = await fetchJson(`${API.recipes}?${query.toString()}`);
  state.recipes = page.content || [];
}

async function loadRecipeDetail(recipeId) {
  state.selectedRecipeDetail = await fetchJson(`${API.recipes}/${recipeId}`);
  state.editingRecipeId = recipeId;
}

async function loadStoreDetail(storeId) {
  const [detail, beacons, layouts, audit] = await Promise.all([
    fetchJson(`${API.stores}/${storeId}`),
    fetchJson(`${API.stores}/${storeId}/beacons`),
    fetchJson(`${API.stores}/${storeId}/layout/versions`),
    fetchJson(`${API.stores}/${storeId}/audit`),
  ]);

  state.selectedStoreId = storeId;
  state.selectedStoreDetail = detail;
  state.selectedStoreBeacons = beacons;
  state.selectedStoreLayouts = layouts;
  state.selectedStoreAudit = audit.entries || [];
}

function clearSelectedStoreDetail() {
  state.selectedStoreDetail = null;
  state.selectedStoreBeacons = [];
  state.selectedStoreLayouts = [];
  state.selectedStoreAudit = [];
}

function renderStats() {
  const activeRegions = state.regions.length;
  const activeStores = state.stores.filter((store) => store.status === 'ACTIVE').length;
  const freeBeacons = state.beacons.filter((beacon) => !beacon.currentStore).length;
  const assignedBeacons = state.beacons.filter((beacon) => beacon.currentStore).length;

  els.statRegions.textContent = String(activeRegions);
  els.statStores.textContent = String(activeStores);
  els.statFreeBeacons.textContent = String(freeBeacons);
  els.statAssignedBeacons.textContent = String(assignedBeacons);
}

function renderSystemLogs() {
  els.systemLogs.classList.toggle('expanded', state.systemLogsExpanded);
  els.toggleSystemLogsBtn.textContent = state.systemLogsExpanded ? 'Weniger anzeigen' : 'Mehr anzeigen';

  els.systemLogs.innerHTML = state.systemLogs.length
    ? state.systemLogs.map((entry) => `
        <div class="timeline-entry">
          <div class="timeline-heading">
            <strong>${escapeHtml(entry.action)}</strong>
            <span class="badge neutral">${escapeHtml(entry.entityType)}</span>
          </div>
          <time>${formatDate(entry.createdAt)}</time>
          <p>${escapeHtml(entry.summary || 'Systemereignis protokolliert')}</p>
          <div class="item-meta">Rolle ${escapeHtml(entry.actorRole || 'SYSTEM')} · ${escapeHtml(entry.actorLabel || 'system')}</div>
        </div>
      `).join('')
    : '<div class="empty-state">Noch keine System-Logs vorhanden. Sobald Filialen, Regionen, Beacons oder Layouts geändert werden, erscheinen sie hier.</div>';
}

function renderRegionOptions() {
  const options = ['<option value="">Bitte wählen</option>']
    .concat(state.regions.map((region) => `<option value="${region.id}">${escapeHtml(region.name)} (${escapeHtml(region.code)})</option>`))
    .join('');

  els.storeRegionInput.innerHTML = options;
  els.storeRegionFilter.innerHTML = '<option value="">Alle Regionen</option>' + state.regions
    .map((region) => `<option value="${region.id}">${escapeHtml(region.name)}</option>`)
    .join('');
  els.storeRegionFilter.value = state.storeFilters.regionId || '';
}

function renderRegions() {
  if (!state.regions.length) {
    els.regionsList.innerHTML = '<div class="empty-state">Noch keine Regionen vorhanden. Lege zuerst eine Region an, damit danach Filialen sauber zugeordnet werden koennen.</div>';
    return;
  }

  els.regionsList.innerHTML = state.regions.map((region) => `
    <article class="list-item">
      <div class="item-header">
        <div>
          <h4>${escapeHtml(region.name)}</h4>
          <div class="item-meta">${escapeHtml(region.code)} · ${formatDate(region.updatedAt)}</div>
        </div>
        ${statusBadge(region.status)}
      </div>
      <p class="subtle">${escapeHtml(region.description || 'Keine Beschreibung hinterlegt.')}</p>
      <div class="item-footer">
        ${isAdmin() ? `<button type="button" class="action-button" data-action="edit-region" data-id="${region.id}">Bearbeiten</button>` : ''}
        ${isAdmin() ? `<button type="button" class="action-button warn" data-action="archive-region" data-id="${region.id}">Archivieren</button>` : ''}
      </div>
    </article>
  `).join('');
}

function renderStores() {
  if (!state.stores.length) {
    els.storesList.innerHTML = '<div class="empty-state">Keine Filialen für den aktuellen Filter gefunden.</div>';
    return;
  }

  els.storesList.innerHTML = state.stores.map((store) => `
    <article class="list-item ${state.selectedStoreId === store.id ? 'active' : ''}">
      <div class="item-header">
        <div>
          <h4>${escapeHtml(store.name)}</h4>
          <div class="item-meta">${escapeHtml(store.storeCode)} · ${escapeHtml(store.city)}</div>
        </div>
        ${statusBadge(store.status)}
      </div>
      <div class="badge-row">
        <span class="badge neutral">${escapeHtml(store.region.name)}</span>
        <span class="badge">${store.activeBeaconCount} aktive Beacons</span>
        ${store.hasActiveLayout ? '<span class="badge">Layout vorhanden</span>' : '<span class="badge warn">Noch kein Layout</span>'}
      </div>
      <div class="item-footer">
        <a class="inline-link" href="/admin/stores/detail/?storeId=${encodeURIComponent(store.id)}">Detail</a>
        <button type="button" class="action-button" data-action="edit-store" data-id="${store.id}">Bearbeiten</button>
        <a class="inline-link" href="/admin/editor/?storeId=${store.id}">Editor</a>
        ${isStoreManager() ? '' : `<button type="button" class="action-button warn" data-action="archive-store" data-id="${store.id}">Archivieren</button>`}
      </div>
    </article>
  `).join('');
}

function renderStoreDetail() {
  if (!state.selectedStoreDetail) {
    els.storeDetailEmpty.classList.remove('hidden');
    els.storeDetailContent.classList.add('hidden');
    els.refreshStoreDetailBtn.disabled = true;
    els.openEditorLink.classList.add('disabled-link');
    els.openEditorLink.href = '/admin/editor/';
    return;
  }

  const store = state.selectedStoreDetail;
  els.storeDetailEmpty.classList.add('hidden');
  els.storeDetailContent.classList.remove('hidden');
  els.refreshStoreDetailBtn.disabled = false;
  els.openEditorLink.classList.remove('disabled-link');
  els.openEditorLink.href = `/admin/editor/?storeId=${store.id}`;

  els.storeMeta.innerHTML = `
    <dt>Name</dt><dd>${escapeHtml(store.name)}</dd>
    <dt>Store-Code</dt><dd>${escapeHtml(store.storeCode)}</dd>
    <dt>Adresse</dt><dd>${escapeHtml(store.street)}, ${escapeHtml(store.zipCode)} ${escapeHtml(store.city)}, ${escapeHtml(store.country)}</dd>
    <dt>Koordinaten</dt><dd>${escapeHtml(formatCoordinates(store.latitude, store.longitude))}</dd>
    <dt>Region</dt><dd>${escapeHtml(store.region.name)} (${escapeHtml(store.region.code)})</dd>
    <dt>Status</dt><dd>${escapeHtml(store.status)}</dd>
    <dt>Aktives Layout</dt><dd>${store.activeLayout ? `Version ${store.activeLayout.versionNo} · ${formatDate(store.activeLayout.createdAt)}` : 'Noch keines gespeichert'}</dd>
    <dt>Notiz</dt><dd>${escapeHtml(store.notes || 'Keine Notiz')}</dd>
  `;

  els.storeBeaconList.innerHTML = state.selectedStoreBeacons.length
    ? state.selectedStoreBeacons.map((assignment) => `
        <article class="list-item">
          <div class="item-header">
            <h5>${escapeHtml(assignment.beaconCode)}</h5>
            <span class="badge neutral">Seit ${formatDate(assignment.assignedAt)}</span>
          </div>
          <p class="subtle">${escapeHtml(assignment.identityKey)}</p>
          <div class="item-footer">
            <button type="button" class="action-button warn" data-action="release-beacon" data-id="${assignment.beaconId}">Freigeben</button>
          </div>
        </article>
      `).join('')
    : '<div class="empty-state">Aktuell ist dieser Filiale noch kein Beacon zugewiesen.</div>';

  els.storeLayoutVersions.innerHTML = state.selectedStoreLayouts.length
    ? state.selectedStoreLayouts.map((layout) => `
        <article class="list-item">
          <div class="item-header">
            <h5>${escapeHtml(layout.layoutName || `Version ${layout.versionNo}`)}</h5>
            <span class="badge ${layout.status === 'ACTIVE' ? '' : 'warn'}">${escapeHtml(layout.status)}</span>
          </div>
          <div class="item-meta">Version ${layout.versionNo} · ${formatDate(layout.createdAt)}</div>
          <div class="item-footer">
            ${layout.status === 'ACTIVE' ? '' : `<button type="button" class="action-button" data-action="activate-layout" data-layout-id="${layout.layoutId}">Aktivieren</button>`}
            <a class="inline-link" href="/admin/editor/?storeId=${store.id}">Im Editor öffnen</a>
          </div>
        </article>
      `).join('')
    : '<div class="empty-state">Für diese Filiale gibt es noch keine gespeicherten Layout-Versionen.</div>';

  els.storeAuditTrail.innerHTML = state.selectedStoreAudit.length
    ? state.selectedStoreAudit.map((entry) => `
        <div class="timeline-entry">
          <strong>${escapeHtml(entry.action)}</strong>
          <time>${formatDate(entry.createdAt)}</time>
          <p>${escapeHtml(entry.summary || 'Änderung protokolliert')}</p>
        </div>
      `).join('')
    : '<div class="empty-state">Noch keine protokollierten Änderungen für diese Filiale.</div>';
}

function renderBeacons() {
  if (!state.beacons.length) {
    els.beaconsList.innerHTML = '<div class="empty-state">Keine Beacons für den aktuellen Filter gefunden.</div>';
    return;
  }

  els.beaconsList.innerHTML = state.beacons.map((beacon) => `
    <article class="list-item">
      <div class="item-header">
        <div>
          <h5>${escapeHtml(beacon.beaconCode)}</h5>
          <div class="item-meta">${escapeHtml(beacon.identityKey)}</div>
        </div>
        ${assignmentBadge(beacon)}
      </div>
      <div class="item-meta">UUID ${escapeHtml(beacon.uuid)}${beacon.major !== null && beacon.major !== undefined ? ` · Major ${beacon.major}` : ''}${beacon.minor !== null && beacon.minor !== undefined ? ` · Minor ${beacon.minor}` : ''}</div>
      <p class="subtle">${escapeHtml(beacon.notes || 'Keine Notiz')}</p>
      <div class="item-footer">
        <button type="button" class="action-button" data-action="edit-beacon" data-id="${beacon.id}">Bearbeiten</button>
        ${beacon.currentStore
          ? `<button type="button" class="action-button warn" data-action="release-beacon" data-id="${beacon.id}">Freigeben</button>`
          : renderAssignSelect(beacon.id)}
        <button type="button" class="action-button danger" data-action="archive-beacon" data-id="${beacon.id}">Archivieren</button>
      </div>
    </article>
  `).join('');
}

function renderProducts() {
  if (!els.productsList) {
    return;
  }

  if (!isAdmin()) {
    els.productsList.innerHTML = '';
    return;
  }

  if (!state.products.length) {
    els.productsList.innerHTML = '<div class="empty-state">Noch keine Produkte geladen. Lege ein Produkt an oder prüfe, ob der OpenSearch-Index bereits Daten enthält.</div>';
    return;
  }

  const products = [...state.products].sort((a, b) => Number(b.id) - Number(a.id));

  els.productsList.innerHTML = products.map((product) => `
    <article class="list-item">
      <div class="item-header">
        <div>
          <h4>${escapeHtml(product.name)}</h4>
          <div class="item-meta">ID ${escapeHtml(product.id)} · ${escapeHtml(product.layoutCode)}</div>
        </div>
        <span class="badge neutral">${escapeHtml(formatPrice(product.price))}</span>
      </div>
      <div class="item-footer">
        <button type="button" class="action-button" data-action="edit-product" data-id="${escapeHtml(product.id)}">Bearbeiten</button>
        <button type="button" class="action-button danger" data-action="delete-product" data-id="${escapeHtml(product.id)}">Löschen</button>
      </div>
    </article>
  `).join('');
}

function renderRecipes() {
  if (!els.recipesList) {
    return;
  }

  if (!isAdmin()) {
    els.recipesList.innerHTML = '';
    return;
  }

  if (!state.recipes.length) {
    els.recipesList.innerHTML = '<div class="empty-state">Noch keine Rezepte gefunden. Lege ein Rezept an oder passe den Filter an.</div>';
    renderRecipeDetailTools();
    return;
  }

  els.recipesList.innerHTML = state.recipes.map((recipe) => `
    <article class="list-item ${state.editingRecipeId === recipe.id ? 'active' : ''}">
      <div class="item-header">
        <div>
          <h4>${escapeHtml(recipe.title)}</h4>
          <div class="item-meta">${escapeHtml(recipe.slug)} · ${recipe.totalIngredientCount || 0} Zutaten · ${recipe.totalTimeMinutes ?? '-'} min</div>
        </div>
        <span class="badge ${recipe.status === 'PUBLISHED' ? '' : 'warn'}">${escapeHtml(recipe.status)}</span>
      </div>
      <p class="subtle">${escapeHtml(recipe.summary || 'Keine Zusammenfassung hinterlegt.')}</p>
      <div class="badge-row">
        ${(recipe.tags || []).map((tag) => `<span class="badge neutral">${escapeHtml(tag.name)}</span>`).join('')}
        <span class="badge">${recipe.mappedIngredientCount || 0}/${recipe.totalIngredientCount || 0} gemappt</span>
      </div>
      <div class="item-footer">
        <button type="button" class="action-button" data-action="select-recipe" data-id="${recipe.id}">Bearbeiten</button>
        <button type="button" class="action-button" data-action="publish-recipe" data-id="${recipe.id}">Veröffentlichen</button>
        <button type="button" class="action-button warn" data-action="deactivate-recipe" data-id="${recipe.id}">Deaktivieren</button>
        <button type="button" class="action-button danger" data-action="archive-recipe" data-id="${recipe.id}">Archivieren</button>
      </div>
    </article>
  `).join('');

  renderRecipeDetailTools();
}

function renderRecipeDetailTools() {
  if (!els.recipeDetailTools) {
    return;
  }

  const detail = state.selectedRecipeDetail;
  els.recipeDetailTools.classList.toggle('hidden', !detail);
  if (!detail) {
    els.recipeMappingPreview.innerHTML = '';
    return;
  }

  const ingredientList = detail.ingredients?.length
    ? detail.ingredients.map((ingredient) => `
        <article class="list-item">
          <div class="item-header">
            <h5>${ingredient.position}. ${escapeHtml(ingredient.displayName)}</h5>
            <span class="badge neutral">${escapeHtml(ingredient.unitCode || 'ohne Einheit')}</span>
          </div>
          <div class="item-meta">${escapeHtml(ingredient.canonicalName || 'kein Canonical Name')}</div>
        </article>
      `).join('')
    : '<div class="empty-state">Noch keine Zutaten.</div>';

  const stepList = detail.steps?.length
    ? detail.steps.map((step) => `
        <article class="list-item">
          <div class="item-header">
            <h5>${step.position}. Schritt</h5>
            <span class="badge neutral">${step.durationMinutes ?? '-'} min</span>
          </div>
          <p class="subtle">${escapeHtml(step.instruction)}</p>
        </article>
      `).join('')
    : '<div class="empty-state">Noch keine Schritte.</div>';

  els.recipeMappingPreview.innerHTML = `
    <h4>Aktuelle Zutaten</h4>
    ${ingredientList}
    <h4>Aktuelle Schritte</h4>
    ${stepList}
    <button type="button" class="secondary-button" data-action="preview-recipe-mapping" data-id="${detail.id}">Mapping-Status laden</button>
  `;
}

function parseDecimalInput(value) {
  const normalized = String(value ?? '').trim().replace(',', '.');
  return normalized ? Number(normalized) : Number.NaN;
}

function parseOptionalDecimalInput(value) {
  const normalized = String(value ?? '').trim().replace(',', '.');
  return normalized ? Number(normalized) : null;
}

function upsertProductInState(product) {
  state.products = [
    product,
    ...state.products.filter((entry) => String(entry.id) !== String(product.id)),
  ];
}

function removeProductFromState(productId) {
  state.products = state.products.filter((entry) => String(entry.id) !== String(productId));
}

function renderAssignSelect(beaconId) {
  const activeStores = state.stores.filter((store) => store.status === 'ACTIVE');
  if (!activeStores.length) {
    return '<span class="subtle">Keine aktive Filiale vorhanden</span>';
  }

  return `
    <label class="subtle">
      <span>Zuweisen zu</span>
      <select data-action="assign-beacon" data-id="${beaconId}">
        <option value="">Filiale wählen</option>
        ${activeStores.map((store) => `<option value="${store.id}">${escapeHtml(store.name)}</option>`).join('')}
      </select>
    </label>
  `;
}

function resetRegionForm() {
  state.editingRegionId = null;
  els.regionForm.reset();
  els.regionFormTitle.textContent = 'Region anlegen';
}

function resetStoreForm() {
  state.editingStoreId = null;
  els.storeForm.reset();
  els.storeFormTitle.textContent = 'Filiale anlegen';
  if (state.regions.length) {
    els.storeRegionInput.value = state.regions[0].id;
  }
}

function resetBeaconForm() {
  state.editingBeaconId = null;
  els.beaconForm.reset();
  els.beaconFormTitle.textContent = 'Beacon anlegen';
}

function resetProductForm() {
  state.editingProductId = null;
  els.productForm?.reset();
}

function resetRecipeForm() {
  state.editingRecipeId = null;
  state.selectedRecipeDetail = null;
  els.recipeForm?.reset();
  if (els.recipeForm) {
    els.recipeForm.elements.servings.value = '2';
    els.recipeForm.elements.status.value = 'DRAFT';
  }
  if (els.recipeFormTitle) {
    els.recipeFormTitle.textContent = 'Rezept anlegen';
  }
  renderRecipeDetailTools();
}

function populateRegionForm(regionId) {
  const region = state.regions.find((entry) => entry.id === regionId);
  if (!region) {
    return;
  }
  state.editingRegionId = region.id;
  els.regionFormTitle.textContent = 'Region bearbeiten';
  els.regionForm.elements.code.value = region.code;
  els.regionForm.elements.name.value = region.name;
  els.regionForm.elements.description.value = region.description || '';
}

async function populateStoreForm(storeId) {
  const store = state.selectedStoreDetail && state.selectedStoreDetail.id === storeId
    ? state.selectedStoreDetail
    : await fetchJson(`${API.stores}/${storeId}`);

  state.editingStoreId = store.id;
  els.storeFormTitle.textContent = 'Filiale bearbeiten';
  els.storeForm.elements.regionId.value = store.region.id;
  els.storeForm.elements.storeCode.value = store.storeCode;
  els.storeForm.elements.name.value = store.name;
  els.storeForm.elements.street.value = store.street;
  els.storeForm.elements.zipCode.value = store.zipCode;
  els.storeForm.elements.city.value = store.city;
  els.storeForm.elements.country.value = store.country;
  els.storeForm.elements.latitude.value = store.latitude ?? '';
  els.storeForm.elements.longitude.value = store.longitude ?? '';
  els.storeForm.elements.notes.value = store.notes || '';
}

async function populateBeaconForm(beaconId) {
  const beacon = state.beacons.find((entry) => entry.id === beaconId) || await fetchJson(`${API.beacons}/${beaconId}`);
  state.editingBeaconId = beacon.id;
  els.beaconFormTitle.textContent = 'Beacon bearbeiten';
  els.beaconForm.elements.beaconCode.value = beacon.beaconCode;
  els.beaconForm.elements.uuid.value = beacon.uuid;
  els.beaconForm.elements.major.value = beacon.major ?? '';
  els.beaconForm.elements.minor.value = beacon.minor ?? '';
  els.beaconForm.elements.notes.value = beacon.notes || '';
}

function populateProductForm(productId) {
  const product = state.products.find((entry) => String(entry.id) === String(productId));
  if (!product || !els.productForm) {
    return;
  }

  state.editingProductId = product.id;
  els.productForm.elements.id.value = product.id;
  els.productForm.elements.name.value = product.name || '';
  els.productForm.elements.price.value = product.price ?? '';
  els.productForm.elements.layoutCode.value = product.layoutCode || '';
  document.getElementById('products')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function populateRecipeForm(recipe) {
  if (!recipe || !els.recipeForm) {
    return;
  }
  state.editingRecipeId = recipe.id;
  els.recipeFormTitle.textContent = 'Rezept bearbeiten';
  els.recipeForm.elements.slug.value = recipe.slug || '';
  els.recipeForm.elements.title.value = recipe.title || '';
  els.recipeForm.elements.summary.value = recipe.summary || '';
  els.recipeForm.elements.description.value = recipe.description || '';
  els.recipeForm.elements.servings.value = recipe.servings || 2;
  els.recipeForm.elements.status.value = recipe.status || 'DRAFT';
  els.recipeForm.elements.prepTimeMinutes.value = recipe.prepTimeMinutes ?? '';
  els.recipeForm.elements.cookTimeMinutes.value = recipe.cookTimeMinutes ?? '';
  els.recipeForm.elements.imageUrl.value = recipe.imageUrl || '';
  document.getElementById('recipes')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

async function refreshAll({ keepStatusMessage = false } = {}) {
  if (!keepStatusMessage) {
    setStatus('Synchronisiere Admin-Plattform mit dem Backend...');
  }

  await loadCurrentUser();
  renderCurrentUser();
  applyRoleUi();
  await loadBootstrapData();
  await loadSystemLogs();
  await loadProducts();
  await loadRecipes();
  renderRegionOptions();
  renderStats();
  renderSystemLogs();
  renderRegions();
  renderStores();
  renderBeacons();
  renderProducts();
  renderRecipes();

  const routeStoreId = storeIdFromUrl();
  if (currentRoute() === 'store-detail' && routeStoreId) {
    state.selectedStoreId = routeStoreId;
  }

  if (state.selectedStoreId) {
    await loadStoreDetail(state.selectedStoreId);
  }

  renderStoreDetail();
  if (!keepStatusMessage) {
    setStatus('Admin-Plattform ist aktuell. Du kannst jetzt Filialen, Beacons und Layouts verwalten.', 'success');
  }
}

async function handleRegionSubmit(event) {
  event.preventDefault();
  const payload = {
    code: els.regionForm.elements.code.value.trim(),
    name: els.regionForm.elements.name.value.trim(),
    description: els.regionForm.elements.description.value.trim() || null,
  };

  const url = state.editingRegionId ? `${API.regions}/${state.editingRegionId}` : API.regions;
  const method = state.editingRegionId ? 'PUT' : 'POST';
  await fetchJson(url, { method, body: JSON.stringify(payload) });
  resetRegionForm();
  await refreshAll();
}

async function handleStoreSubmit(event) {
  event.preventDefault();
  const latitude = parseOptionalDecimalInput(els.storeForm.elements.latitude.value);
  const longitude = parseOptionalDecimalInput(els.storeForm.elements.longitude.value);

  if (latitude !== null && (!Number.isFinite(latitude) || latitude < -90 || latitude > 90)) {
    throw new Error('Latitude muss zwischen -90 und 90 liegen.');
  }
  if (longitude !== null && (!Number.isFinite(longitude) || longitude < -180 || longitude > 180)) {
    throw new Error('Longitude muss zwischen -180 und 180 liegen.');
  }

  const payload = {
    regionId: els.storeForm.elements.regionId.value,
    storeCode: els.storeForm.elements.storeCode.value.trim(),
    name: els.storeForm.elements.name.value.trim(),
    street: els.storeForm.elements.street.value.trim(),
    zipCode: els.storeForm.elements.zipCode.value.trim(),
    city: els.storeForm.elements.city.value.trim(),
    country: els.storeForm.elements.country.value.trim(),
    latitude,
    longitude,
    notes: els.storeForm.elements.notes.value.trim() || null,
  };

  const url = state.editingStoreId ? `${API.stores}/${state.editingStoreId}` : API.stores;
  const method = state.editingStoreId ? 'PUT' : 'POST';
  const result = await fetchJson(url, { method, body: JSON.stringify(payload) });
  resetStoreForm();
  await refreshAll();
  await loadStoreDetail(result.id);
  renderStoreDetail();
  scrollToStoreDetail();
}

async function handleBeaconSubmit(event) {
  event.preventDefault();
  const majorValue = els.beaconForm.elements.major.value.trim();
  const minorValue = els.beaconForm.elements.minor.value.trim();
  const payload = {
    beaconCode: els.beaconForm.elements.beaconCode.value.trim(),
    uuid: normalizeBeaconUuid(els.beaconForm.elements.uuid.value),
    major: majorValue ? Number(majorValue) : null,
    minor: minorValue ? Number(minorValue) : null,
    notes: els.beaconForm.elements.notes.value.trim() || null,
  };

  const url = state.editingBeaconId ? `${API.beacons}/${state.editingBeaconId}` : API.beacons;
  const method = state.editingBeaconId ? 'PUT' : 'POST';
  await fetchJson(url, { method, body: JSON.stringify(payload) });
  resetBeaconForm();
  await refreshAll();
}

async function handleBeaconBulkSubmit(event) {
  event.preventDefault();
  const lines = els.beaconBulkForm.elements.items.value
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);

  const items = lines.map((line) => {
    const [beaconCode, minorRaw] = line.split(/[;,]/).map((part) => part.trim());
    if (!beaconCode || !minorRaw) {
      throw new Error(`Ungültige Beacon-Zeile: ${line}`);
    }
    return {
      beaconCode,
      minor: Number(minorRaw),
    };
  });

  const majorValue = els.beaconBulkForm.elements.major.value.trim();
  const payload = {
    uuid: normalizeBeaconUuid(els.beaconBulkForm.elements.uuid.value),
    major: majorValue ? Number(majorValue) : null,
    notes: els.beaconBulkForm.elements.notes.value.trim() || null,
    items,
  };

  await fetchJson(`${API.beacons}/bulk`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });

  els.beaconBulkForm.reset();
  await refreshAll();
}

async function handleProductSubmit(event) {
  event.preventDefault();

  const id = Number(els.productForm.elements.id.value);
  const price = parseDecimalInput(els.productForm.elements.price.value);
  const payload = {
    id,
    name: els.productForm.elements.name.value.trim(),
    price,
    layoutCode: els.productForm.elements.layoutCode.value.trim(),
  };

  if (!Number.isInteger(id) || id < 1) {
    throw new Error('Produkt-ID muss eine positive ganze Zahl sein.');
  }
  if (!payload.name) {
    throw new Error('Produktname ist erforderlich.');
  }
  if (!Number.isFinite(price) || price < 0) {
    throw new Error('Preis ist erforderlich und darf nicht negativ sein.');
  }
  if (!payload.layoutCode) {
    throw new Error('Layout-Code ist erforderlich.');
  }

  const savedProduct = await fetchJson(API.products, {
    method: 'POST',
    body: JSON.stringify(payload),
  });

  resetProductForm();
  upsertProductInState(savedProduct);
  renderProducts();
  setStatus('Produkt wurde im Katalog gespeichert.', 'success');
}

async function handleRecipeSubmit(event) {
  event.preventDefault();
  const prepTime = els.recipeForm.elements.prepTimeMinutes.value.trim();
  const cookTime = els.recipeForm.elements.cookTimeMinutes.value.trim();
  const recipe = {
    slug: els.recipeForm.elements.slug.value.trim(),
    title: els.recipeForm.elements.title.value.trim(),
    summary: els.recipeForm.elements.summary.value.trim() || null,
    description: els.recipeForm.elements.description.value.trim() || null,
    imageUrl: els.recipeForm.elements.imageUrl.value.trim() || null,
    imageAlt: null,
    servings: Number(els.recipeForm.elements.servings.value),
    prepTimeMinutes: prepTime ? Number(prepTime) : null,
    cookTimeMinutes: cookTime ? Number(cookTime) : null,
    totalTimeMinutes: (prepTime ? Number(prepTime) : 0) + (cookTime ? Number(cookTime) : 0),
    status: els.recipeForm.elements.status.value,
    tagIds: [],
  };

  if (!recipe.slug || !recipe.title) {
    throw new Error('Slug und Titel sind erforderlich.');
  }
  if (!Number.isInteger(recipe.servings) || recipe.servings < 1) {
    throw new Error('Portionen müssen eine positive ganze Zahl sein.');
  }

  const payload = state.editingRecipeId ? recipe : { recipe, ingredients: [], steps: [] };
  const url = state.editingRecipeId ? `${API.recipes}/${state.editingRecipeId}` : API.recipes;
  const method = state.editingRecipeId ? 'PUT' : 'POST';
  const savedRecipe = await fetchJson(url, { method, body: JSON.stringify(payload) });
  state.selectedRecipeDetail = savedRecipe;
  state.editingRecipeId = savedRecipe.id;
  await loadRecipes();
  renderRecipes();
  populateRecipeForm(savedRecipe);
  setStatus('Rezept wurde gespeichert.', 'success');
}

async function handleRecipeIngredientSubmit(event) {
  event.preventDefault();
  if (!state.editingRecipeId) {
    throw new Error('Wähle zuerst ein Rezept aus.');
  }

  const quantityValue = els.recipeIngredientForm.elements.quantity.value.trim();
  const payload = {
    position: Number(els.recipeIngredientForm.elements.position.value),
    displayName: els.recipeIngredientForm.elements.displayName.value.trim(),
    canonicalName: els.recipeIngredientForm.elements.canonicalName.value.trim() || null,
    quantity: quantityValue ? Number(quantityValue.replace(',', '.')) : null,
    quantityText: els.recipeIngredientForm.elements.quantityText.value.trim() || null,
    unitCode: els.recipeIngredientForm.elements.unitCode.value.trim() || null,
    preparationNote: els.recipeIngredientForm.elements.preparationNote.value.trim() || null,
    optional: false,
  };
  await fetchJson(`${API.recipes}/${state.editingRecipeId}/ingredients`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  els.recipeIngredientForm.reset();
  await loadRecipeDetail(state.editingRecipeId);
  renderRecipeDetailTools();
  await loadRecipes();
  renderRecipes();
  setStatus('Zutat wurde hinzugefügt.', 'success');
}

async function handleRecipeStepSubmit(event) {
  event.preventDefault();
  if (!state.editingRecipeId) {
    throw new Error('Wähle zuerst ein Rezept aus.');
  }

  const durationValue = els.recipeStepForm.elements.durationMinutes.value.trim();
  const payload = {
    position: Number(els.recipeStepForm.elements.position.value),
    instruction: els.recipeStepForm.elements.instruction.value.trim(),
    durationMinutes: durationValue ? Number(durationValue) : null,
  };
  await fetchJson(`${API.recipes}/${state.editingRecipeId}/steps`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  els.recipeStepForm.reset();
  await loadRecipeDetail(state.editingRecipeId);
  renderRecipeDetailTools();
  await loadRecipes();
  renderRecipes();
  setStatus('Schritt wurde hinzugefügt.', 'success');
}

async function publishRecipe(recipeId) {
  await fetchJson(`${API.recipes}/${recipeId}/publish`, { method: 'PATCH' });
  await loadRecipes();
  if (state.editingRecipeId === recipeId) {
    await loadRecipeDetail(recipeId);
    populateRecipeForm(state.selectedRecipeDetail);
  }
  renderRecipes();
  setStatus('Rezept wurde veröffentlicht.', 'success');
}

async function deactivateRecipe(recipeId) {
  await fetchJson(`${API.recipes}/${recipeId}/deactivate`, { method: 'PATCH' });
  await loadRecipes();
  renderRecipes();
  setStatus('Rezept wurde deaktiviert.', 'success');
}

async function archiveRecipe(recipeId) {
  if (!window.confirm('Willst du dieses Rezept wirklich archivieren?')) {
    return;
  }
  await fetchJson(`${API.recipes}/${recipeId}/archive`, { method: 'PATCH' });
  if (state.editingRecipeId === recipeId) {
    resetRecipeForm();
  }
  await loadRecipes();
  renderRecipes();
  setStatus('Rezept wurde archiviert.', 'success');
}

async function previewRecipeMapping(recipeId) {
  const mapping = await fetchJson(`${API.recipes}/${recipeId}/mapping-status`);
  const rows = mapping.ingredients?.length
    ? mapping.ingredients.map((entry) => `
        <article class="list-item">
          <div class="item-header">
            <h5>${escapeHtml(entry.ingredientName)}</h5>
            <span class="badge ${entry.status === 'MAPPED' ? '' : 'warn'}">${escapeHtml(entry.status)}</span>
          </div>
          <p class="subtle">${escapeHtml(entry.product?.name || entry.reason || 'Keine Zuordnung')}</p>
          <div class="item-footer">
            <button type="button" class="action-button" data-action="load-recipe-mapping-suggestions" data-id="${recipeId}" data-ingredient-id="${entry.ingredientId}" data-query="${escapeHtml(entry.ingredientName)}">Produktvorschläge</button>
          </div>
        </article>
      `).join('')
    : '<div class="empty-state">Keine Zutaten für Mapping vorhanden.</div>';
  els.recipeMappingPreview.innerHTML = `<h4>Mapping-Status</h4>${rows}`;
}

async function loadRecipeMappingSuggestions(recipeId, ingredientId, query) {
  const encodedQuery = encodeURIComponent(query || '');
  const suggestions = await fetchJson(`${API.recipes}/${recipeId}/ingredients/${ingredientId}/mapping-suggestions?q=${encodedQuery}&size=10`);
  const rows = suggestions?.length
    ? suggestions.map((product) => `
        <article class="list-item">
          <div class="item-header">
            <div>
              <h5>${escapeHtml(product.name || `Produkt ${product.id}`)}</h5>
              <div class="item-meta">ID ${escapeHtml(product.id)} · ${escapeHtml(product.layoutCode || 'kein Layout')}</div>
            </div>
            <span class="badge neutral">${escapeHtml(product.storeCode || 'global')}</span>
          </div>
          <div class="item-footer">
            <button
              type="button"
              class="action-button"
              data-action="confirm-recipe-mapping"
              data-id="${recipeId}"
              data-ingredient-id="${ingredientId}"
              data-product-id="${escapeHtml(product.id)}"
              data-product-name="${escapeHtml(product.name || '')}"
              data-layout-code="${escapeHtml(product.layoutCode || '')}"
              data-store-id="${escapeHtml(product.storeId || '')}"
              data-store-code="${escapeHtml(product.storeCode || '')}">
              Mapping bestätigen
            </button>
          </div>
        </article>
      `).join('')
    : '<div class="empty-state">Keine passenden Produktvorschläge gefunden.</div>';

  els.recipeMappingPreview.innerHTML = `
    <h4>Produktvorschläge</h4>
    ${rows}
    <button type="button" class="secondary-button" data-action="preview-recipe-mapping" data-id="${recipeId}">Zurück zum Mapping-Status</button>
  `;
}

async function confirmRecipeMapping(button) {
  const { id: recipeId, ingredientId, productId, productName, layoutCode, storeId, storeCode } = button.dataset;
  await fetchJson(`${API.recipes}/${recipeId}/ingredients/${ingredientId}/product-mapping`, {
    method: 'PUT',
    body: JSON.stringify({
      productId: Number(productId),
      productName,
      layoutCode: layoutCode || null,
      storeId: storeId || null,
      storeCode: storeCode || null,
      mappingType: 'MANUAL',
      confidence: 1,
      manuallyConfirmed: true,
    }),
  });
  await previewRecipeMapping(recipeId);
  await loadRecipes();
  renderRecipes();
  setStatus('Produkt-Mapping wurde bestätigt.', 'success');
}

async function deleteProduct(productId) {
  const product = state.products.find((entry) => String(entry.id) === String(productId));
  const productLabel = product ? `${product.name} (ID ${product.id})` : `ID ${productId}`;

  if (!window.confirm(`Willst du das Produkt ${productLabel} wirklich löschen?`)) {
    return;
  }

  await fetchJson(`${API.products}/${encodeURIComponent(productId)}`, { method: 'DELETE' });

  if (String(state.editingProductId) === String(productId)) {
    resetProductForm();
  }
  removeProductFromState(productId);
  renderProducts();
  setStatus('Produkt wurde aus dem Katalog gelöscht.', 'success');
}

async function archiveRegion(regionId) {
  if (!window.confirm('Willst du diese Region wirklich archivieren?')) {
    return;
  }
  await fetchJson(`${API.regions}/${regionId}/archive`, { method: 'PATCH' });
  if (state.editingRegionId === regionId) {
    resetRegionForm();
  }
  await refreshAll();
}

async function archiveStore(storeId) {
  if (!window.confirm('Willst du diese Filiale wirklich archivieren? Zugewiesene Beacons werden dabei freigegeben.')) {
    return;
  }
  await fetchJson(`${API.stores}/${storeId}/archive`, { method: 'PATCH' });
  if (state.selectedStoreId === storeId) {
    clearSelectedStoreDetail();
    state.selectedStoreId = null;
  }
  if (state.editingStoreId === storeId) {
    resetStoreForm();
  }
  await refreshAll();
}

async function archiveBeacon(beaconId) {
  if (!window.confirm('Willst du diesen Beacon wirklich archivieren?')) {
    return;
  }
  await fetchJson(`${API.beacons}/${beaconId}/archive`, { method: 'PATCH' });
  if (state.editingBeaconId === beaconId) {
    resetBeaconForm();
  }
  await refreshAll();
}

async function releaseBeacon(beaconId) {
  await fetchJson(`${API.beacons}/${beaconId}/release`, { method: 'POST' });
  await refreshAll({ keepStatusMessage: true });
  if (state.selectedStoreId) {
    await loadStoreDetail(state.selectedStoreId);
    renderStoreDetail();
  }
  setStatus('Beacon wurde freigegeben.', 'success');
}

async function assignBeacon(beaconId, storeId) {
  if (!storeId) {
    return;
  }
  await fetchJson(`${API.beacons}/${beaconId}/assign`, {
    method: 'POST',
    body: JSON.stringify({ storeId }),
  });
  await refreshAll({ keepStatusMessage: true });
  if (state.selectedStoreId === storeId) {
    await loadStoreDetail(storeId);
    renderStoreDetail();
  }
  setStatus('Beacon wurde der Filiale zugeordnet.', 'success');
}

async function activateLayout(layoutId) {
  if (!state.selectedStoreId) {
    return;
  }
  await fetchJson(`${API.stores}/${state.selectedStoreId}/layout/versions/${layoutId}/activate`, {
    method: 'POST',
  });
  await loadStoreDetail(state.selectedStoreId);
  renderStoreDetail();
  setStatus('Layout-Version wurde aktiviert.', 'success');
}

function bindEvents() {
  els.refreshAllBtn.addEventListener('click', () => refreshAll());
  els.toggleSystemLogsBtn.addEventListener('click', () => {
    state.systemLogsExpanded = !state.systemLogsExpanded;
    renderSystemLogs();
  });
  els.refreshLogsBtn.addEventListener('click', async () => {
    if (!isAdmin()) {
      return;
    }
    await loadSystemLogs();
    renderSystemLogs();
    setStatus('System-Logs wurden aktualisiert.', 'success');
  });
  els.logoutLink?.addEventListener('click', (event) => {
    event.preventDefault();
    event.currentTarget.textContent = 'Logout...';
    event.currentTarget.setAttribute('aria-disabled', 'true');
    window.sessionStorage.clear();
    window.localStorage.removeItem('indooro-admin-state');
    window.location.assign(`/admin/logout?ts=${Date.now()}`);
  });
  els.refreshBeaconsBtn.addEventListener('click', () => refreshAll());
  els.refreshStoreDetailBtn.addEventListener('click', async () => {
    if (!state.selectedStoreId) {
      return;
    }
    await loadStoreDetail(state.selectedStoreId);
    renderStoreDetail();
    setStatus('Filialdetail aktualisiert.', 'success');
  });

  els.resetRegionFormBtn.addEventListener('click', resetRegionForm);
  els.cancelRegionEditBtn.addEventListener('click', resetRegionForm);
  els.regionForm.addEventListener('submit', async (event) => {
    try {
      await handleRegionSubmit(event);
    } catch (error) {
      handleUiError(error);
    }
  });

  els.resetStoreFormBtn.addEventListener('click', resetStoreForm);
  els.cancelStoreEditBtn.addEventListener('click', resetStoreForm);
  els.storeForm.addEventListener('submit', async (event) => {
    try {
      await handleStoreSubmit(event);
    } catch (error) {
      handleUiError(error);
    }
  });

  els.storeQuery.addEventListener('input', (event) => {
    state.storeFilters.query = event.target.value;
  });
  els.storeStatusFilter.addEventListener('change', (event) => {
    state.storeFilters.status = event.target.value;
  });
  els.storeRegionFilter.addEventListener('change', (event) => {
    state.storeFilters.regionId = event.target.value;
  });
  els.applyStoreFiltersBtn.addEventListener('click', () => refreshAll());

  els.beaconQuery.addEventListener('input', (event) => {
    state.beaconFilters.query = event.target.value;
  });
  els.beaconAssignmentFilter.addEventListener('change', (event) => {
    state.beaconFilters.assignment = event.target.value;
  });
  els.applyBeaconFiltersBtn.addEventListener('click', () => refreshAll());

  els.cancelBeaconEditBtn.addEventListener('click', resetBeaconForm);
  els.beaconForm.addEventListener('submit', async (event) => {
    try {
      await handleBeaconSubmit(event);
    } catch (error) {
      handleUiError(error);
    }
  });
  els.beaconBulkForm.addEventListener('submit', async (event) => {
    try {
      await handleBeaconBulkSubmit(event);
    } catch (error) {
      handleUiError(error);
    }
  });

  els.refreshProductsBtn?.addEventListener('click', async () => {
    try {
      await loadProducts();
      renderProducts();
      setStatus('Produktliste wurde aktualisiert.', 'success');
    } catch (error) {
      handleUiError(error);
    }
  });
  els.resetProductFormBtn?.addEventListener('click', resetProductForm);
  els.productForm?.addEventListener('submit', async (event) => {
    try {
      await handleProductSubmit(event);
    } catch (error) {
      handleUiError(error);
    }
  });

  els.refreshRecipesBtn?.addEventListener('click', async () => {
    try {
      await loadRecipes();
      renderRecipes();
      setStatus('Rezeptliste wurde aktualisiert.', 'success');
    } catch (error) {
      handleUiError(error);
    }
  });
  els.resetRecipeFormBtn?.addEventListener('click', resetRecipeForm);
  els.recipeQuery?.addEventListener('input', (event) => {
    state.recipeFilters.query = event.target.value;
  });
  els.recipeStatusFilter?.addEventListener('change', (event) => {
    state.recipeFilters.status = event.target.value;
  });
  els.applyRecipeFiltersBtn?.addEventListener('click', async () => {
    try {
      await loadRecipes();
      renderRecipes();
    } catch (error) {
      handleUiError(error);
    }
  });
  els.recipeForm?.addEventListener('submit', async (event) => {
    try {
      await handleRecipeSubmit(event);
    } catch (error) {
      handleUiError(error);
    }
  });
  els.recipeIngredientForm?.addEventListener('submit', async (event) => {
    try {
      await handleRecipeIngredientSubmit(event);
    } catch (error) {
      handleUiError(error);
    }
  });
  els.recipeStepForm?.addEventListener('submit', async (event) => {
    try {
      await handleRecipeStepSubmit(event);
    } catch (error) {
      handleUiError(error);
    }
  });

  document.body.addEventListener('click', async (event) => {
    const button = event.target.closest('[data-action]');
    if (!button) {
      return;
    }

    const { action, id, layoutId } = button.dataset;

    try {
      if (action === 'edit-region') {
        populateRegionForm(id);
      } else if (action === 'archive-region') {
        await archiveRegion(id);
      } else if (action === 'select-store') {
        const selectedStore = getStoreById(id);
        setStatus(`Lade Filialdetail${selectedStore ? ` für ${selectedStore.name}` : ''}...`);
        await loadStoreDetail(id);
        renderStores();
        renderStoreDetail();
        scrollToStoreDetail();
        setStatus('Filialdetail wurde geladen.', 'success');
      } else if (action === 'edit-store') {
        await populateStoreForm(id);
      } else if (action === 'archive-store') {
        await archiveStore(id);
      } else if (action === 'edit-beacon') {
        await populateBeaconForm(id);
      } else if (action === 'release-beacon') {
        await releaseBeacon(id);
      } else if (action === 'archive-beacon') {
        await archiveBeacon(id);
      } else if (action === 'activate-layout') {
        await activateLayout(layoutId);
      } else if (action === 'edit-product') {
        populateProductForm(id);
      } else if (action === 'delete-product') {
        await deleteProduct(id);
      } else if (action === 'select-recipe') {
        await loadRecipeDetail(id);
        populateRecipeForm(state.selectedRecipeDetail);
        renderRecipes();
      } else if (action === 'publish-recipe') {
        await publishRecipe(id);
      } else if (action === 'deactivate-recipe') {
        await deactivateRecipe(id);
      } else if (action === 'archive-recipe') {
        await archiveRecipe(id);
      } else if (action === 'preview-recipe-mapping') {
        await previewRecipeMapping(id);
      } else if (action === 'load-recipe-mapping-suggestions') {
        await loadRecipeMappingSuggestions(id, button.dataset.ingredientId, button.dataset.query);
      } else if (action === 'confirm-recipe-mapping') {
        await confirmRecipeMapping(button);
      }
    } catch (error) {
      handleUiError(error);
    }
  });

  document.body.addEventListener('change', async (event) => {
    const select = event.target.closest('select[data-action="assign-beacon"]');
    if (!select) {
      return;
    }

    try {
      await assignBeacon(select.dataset.id, select.value);
    } catch (error) {
      handleUiError(error);
    } finally {
      select.value = '';
    }
  });
}

async function init() {
  applyPageRoute();
  bindEvents();
  state.storeFilters.query = els.storeQuery.value;
  state.storeFilters.status = els.storeStatusFilter.value;
  state.beaconFilters.assignment = els.beaconAssignmentFilter.value;
  state.recipeFilters.query = els.recipeQuery?.value || '';
  state.recipeFilters.status = els.recipeStatusFilter?.value || '';
  await refreshAll();
  resetRegionForm();
  resetStoreForm();
  resetBeaconForm();
  resetProductForm();
  resetRecipeForm();
}

init().catch((error) => {
  if (error.status === 403) {
    showAccessDenied(error.message);
  } else {
    setStatus(`Admin-Plattform konnte nicht geladen werden: ${error.message}`, 'error');
  }
});
