const API = '/api/admin/error-logs';

const els = {
  pageStatus: document.getElementById('pageStatus'),
  refreshLogsBtn: document.getElementById('refreshLogsBtn'),
  errorLogs: document.getElementById('errorLogs'),
};

function setStatus(message, tone = 'neutral') {
  els.pageStatus.textContent = message;
  els.pageStatus.className = tone === 'error' ? 'error-banner banner' : 'banner';
  if (tone === 'neutral') {
    els.pageStatus.className = '';
  }
}

async function fetchJson(url) {
  const response = await fetch(url, { credentials: 'same-origin' });
  const rawBody = await response.text();

  if (!response.ok) {
    if (response.status === 401) {
      window.location.href = '/admin/';
      throw new Error('Login erforderlich.');
    }
    throw new Error(rawBody || `Request failed with status ${response.status}`);
  }

  return rawBody ? JSON.parse(rawBody) : null;
}

function formatDate(value) {
  return new Intl.DateTimeFormat('de-AT', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));
}

function escapeHtml(value) {
  return String(value ?? '').replace(/[&<>\"']/g, (char) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;'
  }[char]));
}

function renderEntry(entry) {
  return `
    <article class="error-log-entry">
      <div class="error-log-header">
        <div class="error-log-meta">
          <span class="error-status status-${entry.statusCode >= 500 ? 'server' : 'client'}">${entry.statusCode}</span>
          <strong>${escapeHtml(entry.method || 'UNKNOWN')} ${escapeHtml(entry.path)}</strong>
        </div>
        <time>${formatDate(entry.createdAt)}</time>
      </div>
      <p class="error-message">${escapeHtml(entry.message || 'Keine Fehlermeldung gespeichert')}</p>
      <div class="item-meta">${escapeHtml(entry.errorType || 'Kein Fehlertyp')}</div>
      ${entry.stackTrace ? `<details><summary>Stacktrace anzeigen</summary><pre>${escapeHtml(entry.stackTrace)}</pre></details>` : ''}
    </article>
  `;
}

async function loadLogs() {
  setStatus('Lade die letzten Fehler aus dem Backend...');
  const payload = await fetchJson(`${API}?limit=50`);
  const entries = payload.entries || [];
  els.errorLogs.innerHTML = entries.length
    ? entries.map(renderEntry).join('')
    : '<div class="empty-state">Noch keine Fehler protokolliert. Sobald im Backend 4xx- oder 5xx-Fehler auftreten, erscheinen sie hier.</div>';
  setStatus('Fehlerlog ist aktuell.', 'success');
}

els.refreshLogsBtn.addEventListener('click', async () => {
  try {
    await loadLogs();
  } catch (error) {
    setStatus(error.message, 'error');
  }
});

loadLogs().catch((error) => {
  setStatus(`Fehlerlog konnte nicht geladen werden: ${error.message}`, 'error');
});
