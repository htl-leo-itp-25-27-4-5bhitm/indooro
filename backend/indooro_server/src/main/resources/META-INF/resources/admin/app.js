const API = {
  me: '/api/admin/me',
  adminLogs: '/api/admin/logs',
  regions: '/api/regions',
  stores: '/api/stores',
  beacons: '/api/beacons',
};

const state = {
  regions: [],
  stores: [],
  beacons: [],
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
  storeFilters: {
    query: '',
    status: 'ACTIVE',
    regionId: '',
  },
  beaconFilters: {
    query: '',
    assignment: 'all',
  },
};

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
        message = rawBody;
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
  document.querySelector('a[href="#system-logs"]')?.classList.toggle('hidden', !isAdmin());
  document.querySelector('a[href="/admin/server-logs/"]')?.classList.toggle('hidden', !isAdmin());
  els.resetRegionFormBtn.classList.toggle('hidden', !isAdmin());
  els.regionForm.classList.toggle('hidden', !isAdmin());
  els.resetStoreFormBtn.classList.toggle('hidden', !canCreateStore());
  els.storeForm.classList.toggle('hidden', !canCreateStore());
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
  document.getElementById('store-detail')?.scrollIntoView({
    behavior: 'smooth',
    block: 'start',
  });
  history.replaceState(null, '', '#store-detail');
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
    : '<div class="empty-state">Noch keine System-Logs vorhanden. Sobald Filialen, Regionen, Beacons oder Layouts geaendert werden, erscheinen sie hier.</div>';
}

function renderRegionOptions() {
  const options = ['<option value="">Bitte waehlen</option>']
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
    els.storesList.innerHTML = '<div class="empty-state">Keine Filialen fuer den aktuellen Filter gefunden.</div>';
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
        <button type="button" class="action-button" data-action="select-store" data-id="${store.id}">Detail</button>
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
            <a class="inline-link" href="/admin/editor/?storeId=${store.id}">Im Editor oeffnen</a>
          </div>
        </article>
      `).join('')
    : '<div class="empty-state">Fuer diese Filiale gibt es noch keine gespeicherten Layout-Versionen.</div>';

  els.storeAuditTrail.innerHTML = state.selectedStoreAudit.length
    ? state.selectedStoreAudit.map((entry) => `
        <div class="timeline-entry">
          <strong>${escapeHtml(entry.action)}</strong>
          <time>${formatDate(entry.createdAt)}</time>
          <p>${escapeHtml(entry.summary || 'Aenderung protokolliert')}</p>
        </div>
      `).join('')
    : '<div class="empty-state">Noch keine protokollierten Aenderungen fuer diese Filiale.</div>';
}

function renderBeacons() {
  if (!state.beacons.length) {
    els.beaconsList.innerHTML = '<div class="empty-state">Keine Beacons fuer den aktuellen Filter gefunden.</div>';
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

function renderAssignSelect(beaconId) {
  const activeStores = state.stores.filter((store) => store.status === 'ACTIVE');
  if (!activeStores.length) {
    return '<span class="subtle">Keine aktive Filiale vorhanden</span>';
  }

  return `
    <label class="subtle">
      <span>Zuweisen zu</span>
      <select data-action="assign-beacon" data-id="${beaconId}">
        <option value="">Filiale waehlen</option>
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

async function refreshAll({ keepStatusMessage = false } = {}) {
  if (!keepStatusMessage) {
    setStatus('Synchronisiere Admin-Plattform mit dem Backend...');
  }

  await loadCurrentUser();
  renderCurrentUser();
  applyRoleUi();
  await loadBootstrapData();
  await loadSystemLogs();
  renderRegionOptions();
  renderStats();
  renderSystemLogs();
  renderRegions();
  renderStores();
  renderBeacons();

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
  const payload = {
    regionId: els.storeForm.elements.regionId.value,
    storeCode: els.storeForm.elements.storeCode.value.trim(),
    name: els.storeForm.elements.name.value.trim(),
    street: els.storeForm.elements.street.value.trim(),
    zipCode: els.storeForm.elements.zipCode.value.trim(),
    city: els.storeForm.elements.city.value.trim(),
    country: els.storeForm.elements.country.value.trim(),
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
      throw new Error(`Ungueltige Beacon-Zeile: ${line}`);
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
        setStatus(`Lade Filialdetail${selectedStore ? ` fuer ${selectedStore.name}` : ''}...`);
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
  bindEvents();
  state.storeFilters.query = els.storeQuery.value;
  state.storeFilters.status = els.storeStatusFilter.value;
  state.beaconFilters.assignment = els.beaconAssignmentFilter.value;
  await refreshAll();
  resetRegionForm();
  resetStoreForm();
  resetBeaconForm();
}

init().catch((error) => {
  if (error.status === 403) {
    showAccessDenied(error.message);
  } else {
    setStatus(`Admin-Plattform konnte nicht geladen werden: ${error.message}`, 'error');
  }
});
