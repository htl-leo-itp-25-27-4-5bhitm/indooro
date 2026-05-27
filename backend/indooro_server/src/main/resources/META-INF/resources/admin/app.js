import {
  API,
  ROUTES,
  beaconState,
  buildProductPayload,
  buildStorePayload,
  canAccessRoute,
  escapeHtml,
  formatDate,
  includesText,
  normalizeList,
  paginateRows,
  parseImportText,
  readinessForProduct,
  recipeReadiness,
  routeFromPath,
  sortRows,
  summarizeScope,
  userRoles,
  validateBeaconForm,
  validateProductForm,
  validateRecipeForm,
  validateStoreForm
} from "./core.js";

const root = document.querySelector("#admin-root");
const state = {
  user: null,
  route: routeFromPath(location.pathname),
  cache: new Map(),
  filters: {},
  page: 1
};

init().catch((error) => fatal(error));

async function init() {
  state.user = await apiGet(API.me);
  renderShell();
  if (!canAccessRoute(state.user, state.route)) {
    renderAccessDenied();
    return;
  }
  await renderRoute();
}

function renderShell() {
  const nav = ROUTES
    .filter((route) => canAccessRoute(state.user, route))
    .map((route) => `
      <a href="${route.path}" aria-current="${route.id === state.route.id ? "page" : "false"}">
        <span class="nav-icon">${icon(route.icon)}</span>
        <span>${route.label}</span>
      </a>
    `)
    .join("");

  root.className = "admin-app";
  root.innerHTML = `
    <aside class="sidebar">
      <a class="brand" href="/admin/">
        <span class="brand-mark">I</span>
        <span>
          <span class="brand-title">Indooro Admin</span>
          <span class="brand-subtitle">Operations Platform</span>
        </span>
      </a>
      <nav class="nav" aria-label="Admin Navigation">${nav}</nav>
      <section class="user-card">
        <div class="user-name">${escapeHtml(state.user.displayName || state.user.username || state.user.email || "Staff")}</div>
        <div class="user-scope">${escapeHtml(summarizeScope(state.user))}</div>
        <button class="logout small" data-action="logout">Logout</button>
      </section>
    </aside>
    <main class="main">
      <header class="topbar">
        <div class="breadcrumbs"><a href="/admin/">Admin</a><span>/</span><span>${escapeHtml(state.route.label)}</span></div>
        <div class="page-header">
          <div>
            <h1 id="page-title">${escapeHtml(state.route.label)}</h1>
            <p class="page-description" id="page-description"></p>
          </div>
          <div class="toolbar" id="page-actions"></div>
        </div>
      </header>
      <section class="content" id="page-content"></section>
    </main>
    <div class="toast-region" id="toasts" aria-live="polite"></div>
  `;
  root.querySelector("[data-action='logout']").addEventListener("click", () => location.href = "/logout");
}

async function renderRoute() {
  const renderers = {
    dashboard: renderDashboard,
    regions: renderRegions,
    stores: renderStores,
    beacons: renderBeacons,
    products: renderProducts,
    categories: renderCategories,
    recipes: renderRecipes,
    "server-logs": renderServerLogs,
    editor: renderEditorEntry
  };
  await renderers[state.route.id]?.();
}

function setPage(title, description, actions = "") {
  document.querySelector("#page-title").textContent = title;
  document.querySelector("#page-description").textContent = description;
  document.querySelector("#page-actions").innerHTML = actions;
}

function content(html) {
  document.querySelector("#page-content").innerHTML = html;
}

async function renderDashboard() {
  setPage("Dashboard", "Kurzer Operations-Ueberblick mit naechsten sinnvollen Aktionen.", `
    <a class="button primary" href="/admin/stores/">Store verwalten</a>
    <a class="button" href="/admin/editor/">Editor oeffnen</a>
  `);
  content(`<div class="loading">Dashboard wird geladen...</div>`);
  const [regions, stores, beacons, logs] = await Promise.all([
    safeGet(API.regions, []),
    safeGet(API.stores, []),
    safeGet(API.beacons, []),
    canAccess("admin") ? safeGet(API.adminLogs, []) : []
  ]);
  const missingLayouts = normalizeList(stores).filter((store) => !store.hasActiveLayout).length;
  const freeBeacons = normalizeList(beacons).filter((beacon) => !beacon.currentStore && beacon.status !== "ARCHIVED").length;
  content(`
    <section class="grid four">
      ${stat("Regionen", normalizeList(regions).length, "verwaltete Gebiete")}
      ${stat("Stores", normalizeList(stores).length, "sichtbarer Scope")}
      ${stat("Freie Beacons", freeBeacons, "bereit zur Zuweisung")}
      ${stat("Layouts offen", missingLayouts, "Stores ohne aktives Layout")}
    </section>
    <section class="grid two" style="margin-top:16px">
      <div class="panel">
        <div class="panel-header"><h2>Setup-Warnungen</h2></div>
        ${missingLayouts || freeBeacons ? `
          <div class="stack">
            ${missingLayouts ? `<div class="notice warning">${missingLayouts} Store(s) haben noch kein aktives Layout.</div>` : ""}
            ${freeBeacons ? `<div class="notice">${freeBeacons} Beacon(s) sind frei und koennen zugewiesen werden.</div>` : ""}
          </div>
        ` : empty("Alles wirkt einsatzbereit.", "Keine offenen Setup-Warnungen im aktuellen Scope.")}
      </div>
      <div class="panel">
        <div class="panel-header"><h2>Letzte Audit Events</h2><a class="button small" href="/admin/server-logs/">Diagnose</a></div>
        ${renderEventList(normalizeList(logs).slice(0, 8))}
      </div>
    </section>
    <section class="panel" style="margin-top:16px">
      <div class="panel-header"><h2>Quick Actions</h2></div>
      <div class="toolbar">
        <a class="button" href="/admin/stores/">Store anlegen</a>
        <a class="button" href="/admin/beacons/">Beacon zuweisen</a>
        ${canAccess("admin") ? `<a class="button" href="/admin/products/">Produkte importieren</a><a class="button" href="/admin/recipes/">Rezept erstellen</a>` : ""}
      </div>
    </section>
  `);
}

async function renderRegions() {
  setPage("Regionen", "Regionen sauber scannen, bearbeiten und archivieren.", `<button class="primary" data-open-region>Region anlegen</button>`);
  const regions = normalizeList(await safeGet(API.regions, []));
  renderRegionTable(regions);
  document.querySelector("[data-open-region]")?.addEventListener("click", () => openRegionDrawer());
}

function renderRegionTable(regions) {
  content(`
    <section class="panel">
      <div class="filters">${searchFilter("Region suchen", "name, code")}</div>
      ${table({
        columns: ["Code", "Name", "Status", "Aktionen"],
        rows: regions.map((region) => [
          mono(region.code),
          escapeHtml(region.name),
          badge(region.status || "ACTIVE", region.status === "ARCHIVED" ? "muted" : "success"),
          actions([
            ["Bearbeiten", () => openRegionDrawer(region)],
            ["Archivieren", () => confirmMutation(`Region ${region.name} archivieren?`, "Bestehende Stores bleiben historisch sichtbar.", () => apiPatch(`${API.regions}/${region.id}/archive`, {}), renderRegions), "danger"]
          ])
        ]),
        emptyMessage: "Keine Regionen im aktuellen Scope."
      })}
    </section>
  `);
  hydrateActions();
}

async function renderStores() {
  const params = new URLSearchParams(location.search);
  const detailId = location.pathname.includes("/detail") ? params.get("storeId") : null;
  if (detailId) {
    await renderStoreDetail(detailId);
    return;
  }
  setPage("Stores", "Store-Liste, Layout-Readiness und gefuehrter Create/Edit Flow.", `<button class="primary" data-open-store>Store anlegen</button>`);
  const [stores, regions] = await Promise.all([safeGet(API.stores, []), safeGet(API.regions, [])]);
  renderStoreList(normalizeList(stores), normalizeList(regions));
  document.querySelector("[data-open-store]")?.addEventListener("click", () => openStoreDrawer(null, normalizeList(regions)));
}

function renderStoreList(stores, regions) {
  const filtered = applyQuery(stores, ["name", "storeCode", "city", "region.name"]);
  const sorted = sortRows(filtered, state.filters.sort || "name", state.filters.dir || "asc");
  const page = paginateRows(sorted, state.page, 25);
  content(`
    <section class="panel">
      <div class="filters">
        ${searchFilter("Stores suchen", "Name, Code, Stadt")}
        ${selectFilter("region", "Region", [["", "Alle"], ...regions.map((r) => [r.id, `${r.code} · ${r.name}`])])}
        ${selectFilter("layout", "Layout", [["", "Alle"], ["ready", "Aktiv"], ["missing", "Fehlt"]])}
        ${selectFilter("sort", "Sortierung", [["name", "Name"], ["storeCode", "Code"], ["city", "Stadt"]])}
      </div>
      ${table({
        columns: ["Store", "Region", "Ort", "Beacons", "Layout", "Aktionen"],
        rows: page.rows
          .filter((store) => !state.filters.region || store.region?.id === state.filters.region)
          .filter((store) => !state.filters.layout || (state.filters.layout === "ready" ? store.hasActiveLayout : !store.hasActiveLayout))
          .map((store) => [
            `<strong>${escapeHtml(store.name)}</strong><br><span class="muted mono">${escapeHtml(store.storeCode)}</span>`,
            escapeHtml(store.region?.name || "-"),
            escapeHtml(store.city || "-"),
            String(store.activeBeaconCount ?? 0),
            badge(store.hasActiveLayout ? "Aktiv" : "Fehlt", store.hasActiveLayout ? "success" : "warning"),
            actions([
              ["Details", `/admin/stores/detail/?storeId=${store.id}`],
              ["Bearbeiten", () => openStoreDrawer(store, regions)],
              ["Editor", `/admin/editor/?storeId=${store.id}`]
            ])
          ]),
        emptyMessage: "Keine Stores passen zu Suche oder Scope."
      })}
      ${pager(page)}
    </section>
  `);
  hydrateFilters(() => renderStoreList(stores, regions));
  hydrateActions();
}

async function renderStoreDetail(storeId) {
  setPage("Store Detail", "Metadaten, Beacon-Zuweisungen, Layout-Versionen und Audit Trail.", `
    <a class="button" href="/admin/stores/">Zur Liste</a>
    <a class="button primary" href="/admin/editor/?storeId=${encodeURIComponent(storeId)}">Layout bearbeiten</a>
  `);
  content(`<div class="loading">Store Detail wird geladen...</div>`);
  const [store, beacons, layouts, audit] = await Promise.all([
    safeGet(`${API.stores}/${storeId}`, null),
    safeGet(`${API.stores}/${storeId}/beacons`, []),
    safeGet(`${API.stores}/${storeId}/layout/versions`, []),
    safeGet(`${API.stores}/${storeId}/audit`, { entries: [] })
  ]);
  if (!store) {
    content(empty("Store nicht gefunden.", "Der Link ist ungueltig oder ausserhalb deines Scopes."));
    return;
  }
  content(`
    <section class="grid three">
      ${stat("Status", store.status || "ACTIVE", store.region?.name || "ohne Region")}
      ${stat("Aktives Layout", store.activeLayout ? `v${store.activeLayout.versionNo}` : "Fehlt", store.activeLayout ? formatDate(store.activeLayout.createdAt) : "Editor starten")}
      ${stat("Beacons", normalizeList(beacons).length, "aktive Zuweisungen")}
    </section>
    <section class="panel" style="margin-top:16px">
      <div class="tabs">
        <button class="tab" aria-selected="true">Ueberblick</button>
        <button class="tab">Beacons</button>
        <button class="tab">Layouts</button>
        <button class="tab">Audit</button>
      </div>
      <div class="grid two">
        <div>${detailList([
          ["Code", store.storeCode],
          ["Name", store.name],
          ["Adresse", `${store.street || ""}, ${store.zipCode || ""} ${store.city || ""}`],
          ["Koordinaten", [store.latitude, store.longitude].filter((v) => v != null).join(", ") || "-"],
          ["Notizen", store.notes || "-"]
        ])}</div>
        <div class="stack">
          <h3>Naechste Aktionen</h3>
          <a class="button" href="/admin/beacons/?storeId=${store.id}">Beacon zuweisen</a>
          <a class="button" href="/admin/editor/?storeId=${store.id}">Layout-Version erstellen</a>
          <button class="danger" data-archive-store="${store.id}">Store archivieren</button>
        </div>
      </div>
    </section>
    <section class="grid two" style="margin-top:16px">
      <div class="panel"><div class="panel-header"><h2>Beacons</h2></div>${renderBeaconMiniList(normalizeList(beacons))}</div>
      <div class="panel"><div class="panel-header"><h2>Layout-Versionen</h2></div>${renderLayoutList(normalizeList(layouts), store.id)}</div>
    </section>
    <section class="panel" style="margin-top:16px"><div class="panel-header"><h2>Audit History</h2></div>${renderEventList(normalizeList(audit.entries))}</section>
  `);
  document.querySelector("[data-archive-store]")?.addEventListener("click", () => {
    confirmMutation(`Store ${store.name} archivieren?`, "Der Store verschwindet aus aktiven Workflows.", () => apiPatch(`${API.stores}/${store.id}/archive`, {}), () => renderStoreDetail(store.id));
  });
}

async function renderBeacons() {
  setPage("Beacons", "Inventar, freie/zugewiesene Geraete und gefuehrte Assignment-Flows.", `<button class="primary" data-open-beacon>Beacon anlegen</button><button data-open-beacon-bulk>Bulk anlegen</button>`);
  const [beacons, stores] = await Promise.all([safeGet(API.beacons, []), safeGet(API.stores, [])]);
  renderBeaconPage(normalizeList(beacons), normalizeList(stores));
  document.querySelector("[data-open-beacon]")?.addEventListener("click", () => openBeaconDrawer(null, normalizeList(beacons)));
  document.querySelector("[data-open-beacon-bulk]")?.addEventListener("click", () => openBeaconBulkDrawer());
}

function renderBeaconPage(beacons, stores) {
  const filtered = applyQuery(beacons, ["beaconCode", "uuid", "identityKey", "currentStore.name"]).filter((beacon) => {
    if (!state.filters.state) return true;
    if (state.filters.state === "free") return !beacon.currentStore && beacon.status !== "ARCHIVED";
    if (state.filters.state === "assigned") return !!beacon.currentStore;
    if (state.filters.state === "archived") return beacon.status === "ARCHIVED";
    return true;
  });
  content(`
    <section class="panel">
      <div class="filters">
        ${searchFilter("Beacons suchen", "Code, UUID, Store")}
        ${selectFilter("state", "Status", [["", "Alle"], ["free", "Frei"], ["assigned", "Zugewiesen"], ["archived", "Archiviert"]])}
        ${selectFilter("sort", "Sortierung", [["beaconCode", "Code"], ["uuid", "UUID"], ["currentStore.storeCode", "Store"]])}
      </div>
      ${table({
        columns: ["Beacon", "Identitaet", "Status", "Store", "Aktionen"],
        rows: sortRows(filtered, state.filters.sort || "beaconCode").map((beacon) => {
          const status = beaconState(beacon);
          return [
            `<strong>${escapeHtml(beacon.beaconCode)}</strong><br><span class="muted">${escapeHtml(beacon.notes || "")}</span>`,
            `<span class="mono">${escapeHtml(beacon.identityKey || `${beacon.uuid}:${beacon.major}:${beacon.minor}`)}</span>`,
            badge(status.label, status.tone),
            escapeHtml(beacon.currentStore?.name || "-"),
            actions([
              ["Bearbeiten", () => openBeaconDrawer(beacon, beacons)],
              ["Zuweisen", () => openAssignDrawer(beacon, stores)],
              ["Freigeben", () => confirmMutation(`${beacon.beaconCode} freigeben?`, "Die aktive Store-Zuweisung wird beendet.", () => apiPost(`${API.beacons}/${beacon.id}/release`, {}), renderBeacons)],
              ["Archivieren", () => confirmMutation(`${beacon.beaconCode} archivieren?`, "Archivierte Beacons sind nicht mehr zuweisbar.", () => apiPatch(`${API.beacons}/${beacon.id}/archive`, {}), renderBeacons), "danger"]
            ])
          ];
        }),
        emptyMessage: "Keine Beacons passen zu Suche, Filter oder Scope."
      })}
    </section>
  `);
  hydrateFilters(() => renderBeaconPage(beacons, stores));
  hydrateActions();
}

async function renderProducts() {
  setPage("Produkte", "Katalog scannen, Layout-Readiness pruefen und Imports reviewen.", `<button class="primary" data-open-product>Produkt anlegen</button><button data-open-product-import>Import</button>`);
  const products = normalizeList(await safeGet(API.products, []));
  renderProductList(products);
  document.querySelector("[data-open-product]")?.addEventListener("click", () => openProductDrawer());
  document.querySelector("[data-open-product-import]")?.addEventListener("click", () => openImportDrawer("product"));
}

function renderProductList(products) {
  const filtered = applyQuery(products, ["id", "name", "layoutCode", "storeCode"]).filter((product) => {
    const readiness = readinessForProduct(product);
    return !state.filters.readiness || readiness.status === state.filters.readiness;
  });
  const page = paginateRows(sortRows(filtered, state.filters.sort || "name"), state.page, 30);
  content(`
    <section class="panel">
      <div class="filters">
        ${searchFilter("Produkte suchen", "ID, Name, Layout-Code")}
        ${selectFilter("readiness", "Readiness", [["", "Alle"], ["ready", "Routbar"], ["warning", "Nicht routbar"]])}
        ${selectFilter("sort", "Sortierung", [["name", "Name"], ["id", "ID"], ["layoutCode", "Layout-Code"]])}
      </div>
      ${table({
        columns: ["ID", "Produkt", "Preis", "Layout", "Store", "Readiness", "Aktionen"],
        rows: page.rows.map((product) => {
          const readiness = readinessForProduct(product);
          return [
            mono(product.id),
            escapeHtml(product.name),
            product.price == null ? "-" : `${Number(product.price).toFixed(2)} EUR`,
            mono(product.layoutCode || "-"),
            escapeHtml(product.storeCode || product.storeId || "-"),
            `${badge(readiness.label, readiness.status)}${readiness.problems.length ? `<br><span class="muted">${escapeHtml(readiness.problems.join(", "))}</span>` : ""}`,
            actions([
              ["Bearbeiten", () => openProductDrawer(product)],
              ["Loeschen", () => confirmMutation(`Produkt ${product.name} loeschen?`, "Das Produkt wird aus dem Admin-Katalog entfernt.", () => apiDelete(`/api/admin/products/${product.id}`), renderProducts), "danger"]
            ])
          ];
        }),
        emptyMessage: "Keine Produkte gefunden."
      })}
      ${pager(page)}
    </section>
  `);
  hydrateFilters(() => renderProductList(products));
  hydrateActions();
}

async function renderCategories() {
  setPage("Kategorien", "Kategorien verwalten und fuer Produktpflege bereitstellen.", `<button class="primary" data-open-category>Kategorie anlegen</button><button data-open-category-import>Kategorie-Import</button>`);
  const categories = normalizeList(await safeGet(API.categories, []));
  content(`
    <section class="panel">
      ${table({
        columns: ["Code", "Name", "Aktionen"],
        rows: categories.map((category) => [
          mono(category.categoryCode || category.id || category.code),
          escapeHtml(category.categoryName || category.name || category.displayName || "-"),
          actions([["Bearbeiten", () => openCategoryDrawer(category)]])
        ]),
        emptyMessage: "Keine Kategorien geladen."
      })}
    </section>
  `);
  hydrateActions();
  document.querySelector("[data-open-category]")?.addEventListener("click", () => openCategoryDrawer());
  document.querySelector("[data-open-category-import]")?.addEventListener("click", () => openImportDrawer("category"));
}

async function renderRecipes() {
  setPage("Rezepte", "Rezepte, Zutaten, Schritte, Mapping-Readiness und Publish Lifecycle.", `<button class="primary" data-open-recipe>Rezept anlegen</button>`);
  const recipes = normalizeList(await safeGet(API.recipes, []));
  renderRecipeList(recipes);
  document.querySelector("[data-open-recipe]")?.addEventListener("click", () => openRecipeDrawer());
}

function renderRecipeList(recipes) {
  const filtered = applyQuery(recipes, ["title", "slug", "status"]).filter((recipe) => !state.filters.status || recipe.status === state.filters.status);
  content(`
    <section class="panel">
      <div class="filters">
        ${searchFilter("Rezepte suchen", "Titel, Slug")}
        ${selectFilter("status", "Status", [["", "Alle"], ["DRAFT", "Draft"], ["PUBLISHED", "Published"], ["ARCHIVED", "Archived"]])}
        ${selectFilter("sort", "Sortierung", [["title", "Titel"], ["status", "Status"], ["publishedAt", "Publiziert"]])}
      </div>
      ${table({
        columns: ["Rezept", "Status", "Mapping", "Tags", "Aktionen"],
        rows: sortRows(filtered, state.filters.sort || "title").map((recipe) => {
          const readiness = recipeReadiness(recipe);
          return [
            `<strong>${escapeHtml(recipe.title)}</strong><br><span class="muted mono">${escapeHtml(recipe.slug)}</span>`,
            badge(recipe.status || "DRAFT", recipe.status === "PUBLISHED" ? "success" : recipe.status === "ARCHIVED" ? "muted" : "warning"),
            `${badge(readiness.label, readiness.status)}<br><span class="muted">${recipe.mappedIngredientCount ?? 0}/${recipe.totalIngredientCount ?? 0} Zutaten</span>`,
            escapeHtml((recipe.tags || []).map((tag) => tag.name).join(", ") || "-"),
            actions([
              ["Bearbeiten", () => openRecipeDrawer(recipe)],
              ["Mapping", () => openMappingDrawer(recipe)],
              ["Publish", () => confirmMutation(`${recipe.title} publizieren?`, "Das Rezept wird fuer mobile Nutzer sichtbar.", () => apiPatch(`${API.recipes}/${recipe.id}/publish`, {}), renderRecipes)],
              ["Deaktivieren", () => confirmMutation(`${recipe.title} deaktivieren?`, "Das Rezept bleibt erhalten, ist aber nicht aktiv.", () => apiPatch(`${API.recipes}/${recipe.id}/deactivate`, {}), renderRecipes)],
              ["Archivieren", () => confirmMutation(`${recipe.title} archivieren?`, "Archivierte Rezepte werden aus Arbeitslisten entfernt.", () => apiPatch(`${API.recipes}/${recipe.id}/archive`, {}), renderRecipes), "danger"]
            ])
          ];
        }),
        emptyMessage: "Keine Rezepte gefunden."
      })}
    </section>
  `);
  hydrateFilters(() => renderRecipeList(recipes));
  hydrateActions();
}

async function renderServerLogs() {
  setPage("Diagnose", "Admin-only Logs mit Stacktrace-Inspektion und Refresh.", `<button class="primary" data-refresh>Aktualisieren</button>`);
  const [audit, errors] = await Promise.all([safeGet(API.adminLogs, []), safeGet(API.errorLogs, [])]);
  content(`
    <section class="grid two">
      <div class="panel"><div class="panel-header"><h2>Audit Events</h2></div>${renderEventList(normalizeList(audit))}</div>
      <div class="panel"><div class="panel-header"><h2>Error Logs</h2></div>${renderDiagnostics(normalizeList(errors))}</div>
    </section>
  `);
  document.querySelector("[data-refresh]")?.addEventListener("click", renderServerLogs);
}

function renderEditorEntry() {
  setPage("Layout Editor", "Dediziertes Planungstool mit Canvas, Toolbar, Inspector und Validierung.", `<a class="button primary" href="/admin/editor/${location.search}">Editor oeffnen</a>`);
  content(`
    <section class="panel">
      <h2>Editor wird separat geladen</h2>
      <p class="muted">Die Editor-Seite besitzt eine eigene Tool-Oberflaeche. Store-Kontext und Legacy-Modus bleiben ueber Query-Parameter kompatibel.</p>
      <a class="button primary" href="/admin/editor/${location.search}">Zum Layout Editor</a>
    </section>
  `);
}

function openRegionDrawer(region = {}) {
  openDrawer(region.id ? "Region bearbeiten" : "Region anlegen", `
    <form class="stack" data-form="region">
      ${field("code", "Code", region.code || "", "text", "", "AT-OÖ")}
      ${field("name", "Name", region.name || "", "text", "", "Oberösterreich")}
      <div class="toolbar"><button class="primary">Speichern</button></div>
    </form>
  `, (drawer) => {
    drawer.querySelector("form").addEventListener("submit", async (event) => {
      event.preventDefault();
      const values = formValues(event.currentTarget);
      await (region.id ? apiPut(`${API.regions}/${region.id}`, values) : apiPost(API.regions, values));
      closeDrawer();
      toast("Region gespeichert.");
      renderRegions();
    });
  });
}

function openStoreDrawer(store = {}, regions = []) {
  const values = store || {};
  openDrawer(values.id ? "Store bearbeiten" : "Store anlegen", `
    <div class="stepper"><div class="step active">1 Identitaet</div><div class="step active">2 Adresse</div><div class="step active">3 Koordinaten</div><div class="step">4 Review</div></div>
    <form class="stack" data-form="store">
      <div class="form-grid">
        ${selectField("regionId", "Region", regions.map((r) => [r.id, `${r.code} · ${r.name}`]), values.region?.id || values.regionId || "")}
        ${field("storeCode", "Store-Code", values.storeCode || "", "text", "", "SPAR-Leonding-001")}
        ${field("name", "Name", values.name || "", "text", "", "EUROSPAR Leonding/Hart")}
        ${field("street", "Strasse", values.street || "", "text", "", "Leondinger Straße 32")}
        ${field("zipCode", "PLZ", values.zipCode || "", "text", "", "4060")}
        ${field("city", "Stadt", values.city || "", "text", "", "Leonding")}
        ${field("country", "Land", values.country || "Austria", "text", "", "Austria")}
        ${field("latitude", "Latitude", values.latitude ?? "", "number", "0.000001", "48.2680495")}
        ${field("longitude", "Longitude", values.longitude ?? "", "number", "0.000001", "14.2618747")}
        <div class="span-2">${textarea("notes", "Notizen", values.notes || "", "z.B. Haupteingang links, Tiefkühlbereich hinten")}</div>
      </div>
      <div class="notice">Nach dem Speichern geht es sinnvoll mit Beacon-Zuweisung oder Layout-Erstellung weiter.</div>
      <div class="toolbar"><button class="primary">Speichern</button></div>
    </form>
  `, (drawer) => {
    drawer.querySelector("form").addEventListener("submit", async (event) => {
      event.preventDefault();
      const values = formValues(event.currentTarget);
      const errors = validateStoreForm(values);
      if (showErrors(event.currentTarget, errors)) return;
      const saved = await (store?.id ? apiPut(`${API.stores}/${store.id}`, buildStorePayload(values)) : apiPost(API.stores, buildStorePayload(values)));
      closeDrawer();
      toast("Store gespeichert. Naechster Schritt: Beacons oder Layout.");
      location.href = `/admin/stores/detail/?storeId=${saved.id || store.id}`;
    });
  });
}

function openBeaconDrawer(beacon = {}, existing = []) {
  openDrawer(beacon.id ? "Beacon bearbeiten" : "Beacon anlegen", `
    <form class="stack">
      <div class="form-grid">
        ${field("beaconCode", "Beacon-Code", beacon.beaconCode || "", "text", "", "B-001")}
        ${field("uuid", "UUID", beacon.uuid || "", "text", "", "fda50693-a4e2-4fb1-afcf-c6eb07647825")}
        ${field("major", "Major", beacon.major ?? "", "number", "", "1")}
        ${field("minor", "Minor", beacon.minor ?? "", "number", "", "1")}
        <div class="span-2">${textarea("notes", "Notizen", beacon.notes || "", "z.B. Eingang Nord oder Kasse 1")}</div>
      </div>
      <div data-error-summary></div>
      <div class="toolbar"><button class="primary">Speichern</button></div>
    </form>
  `, (drawer) => {
    drawer.querySelector("form").addEventListener("submit", async (event) => {
      event.preventDefault();
      const values = { ...formValues(event.currentTarget), id: beacon.id };
      const errors = validateBeaconForm(values, existing);
      if (showErrors(event.currentTarget, errors)) return;
      await (beacon.id ? apiPut(`${API.beacons}/${beacon.id}`, values) : apiPost(API.beacons, values));
      closeDrawer();
      toast("Beacon gespeichert.");
      renderBeacons();
    });
  });
}

function openBeaconBulkDrawer() {
  openDrawer("Beacon Bulk anlegen", `
    <form class="stack">
      ${field("uuid", "Gemeinsame UUID", "", "text", "", "fda50693-a4e2-4fb1-afcf-c6eb07647825")}
      ${field("major", "Major", "", "number", "", "1")}
      ${textarea("items", "Beacon-Zeilen", "", "B-001,1\nB-002,2\nB-003,3")}
      <div class="notice">Review: Zeilen werden vor Commit geparst. Ungueltige Zeilen stoppen den Import.</div>
      <div class="toolbar"><button class="primary">Review & Commit</button></div>
    </form>
  `, (drawer) => {
    drawer.querySelector("form").addEventListener("submit", async (event) => {
      event.preventDefault();
      const values = formValues(event.currentTarget);
      const items = values.items.split(/\r?\n/).filter(Boolean).map((line) => {
        const [beaconCode, minor] = line.split(",").map((part) => part.trim());
        return { beaconCode, minor: Number(minor) };
      });
      if (!values.uuid || !items.length || items.some((item) => !item.beaconCode || Number.isNaN(item.minor))) {
        toast("Bulk-Review fehlgeschlagen: UUID und gueltige Zeilen sind erforderlich.", "danger");
        return;
      }
      await apiPost(`${API.beacons}/bulk`, { uuid: values.uuid, major: Number(values.major), items });
      closeDrawer();
      toast(`${items.length} Beacon(s) angelegt.`);
      renderBeacons();
    });
  });
}

function openAssignDrawer(beacon, stores) {
  openDrawer("Beacon zuweisen", `
    <form class="stack">
      <div class="notice">Beacon <strong>${escapeHtml(beacon.beaconCode)}</strong> wird nach Bestaetigung einem Store zugewiesen.</div>
      ${selectField("storeId", "Ziel-Store", stores.map((store) => [store.id, `${store.storeCode} · ${store.name}`]))}
      <div class="toolbar"><button class="primary">Zuweisung bestaetigen</button></div>
    </form>
  `, (drawer) => {
    drawer.querySelector("form").addEventListener("submit", async (event) => {
      event.preventDefault();
      const values = formValues(event.currentTarget);
      await apiPost(`${API.beacons}/${beacon.id}/assign`, { storeId: values.storeId });
      closeDrawer();
      toast("Beacon zugewiesen.");
      renderBeacons();
    });
  });
}

function openProductDrawer(product = {}) {
  openDrawer(product.id ? "Produkt bearbeiten" : "Produkt anlegen", `
    <form class="stack">
      <div class="form-grid">
        ${field("id", "Produkt-ID", product.id ?? "", "number", "", "101")}
        ${field("name", "Name", product.name || "", "text", "", "Apfel")}
        ${field("price", "Preis", product.price ?? "", "number", "0.01", "1.99")}
        ${field("layoutCode", "Layout-Code", product.layoutCode || "", "text", "", "A-01")}
        ${field("storeId", "Store-ID optional", product.storeId || "", "text", "", "ad61389a-7486-48fa-afa2-9b5e4132f6a8")}
        ${field("storeCode", "Store-Code optional", product.storeCode || "", "text", "", "SPAR-Leonding-001")}
      </div>
      <div data-error-summary></div>
      <div class="toolbar"><button class="primary">Speichern</button></div>
    </form>
  `, (drawer) => {
    drawer.querySelector("form").addEventListener("submit", async (event) => {
      event.preventDefault();
      const values = formValues(event.currentTarget);
      const errors = validateProductForm(values);
      if (showErrors(event.currentTarget, errors)) return;
      await apiPost(API.productWrite, buildProductPayload(values));
      closeDrawer();
      toast("Produkt gespeichert.");
      renderProducts();
    });
  });
}

function openCategoryDrawer(category = {}) {
  openDrawer(category.categoryCode ? "Kategorie bearbeiten" : "Kategorie anlegen", `
    <form class="stack">
      <div class="form-grid">
        ${field("categoryCode", "Kategorie-Code", category.categoryCode ?? "", "number", "", "310")}
        ${field("categoryName", "Name", category.categoryName || category.name || "", "text", "", "Obst & Gemüse")}
      </div>
      <div data-error-summary></div>
      <div class="toolbar"><button class="primary">Speichern</button></div>
    </form>
  `, (drawer) => {
    drawer.querySelector("form").addEventListener("submit", async (event) => {
      event.preventDefault();
      const values = formValues(event.currentTarget);
      if (!values.categoryCode || !values.categoryName?.trim()) {
        showErrors(event.currentTarget, { category: "Kategorie-Code und Name sind erforderlich." });
        return;
      }
      await apiPost("/api/categories", {
        categoryCode: Number(values.categoryCode),
        categoryName: values.categoryName.trim()
      });
      closeDrawer();
      toast("Kategorie gespeichert.");
      renderCategories();
    });
  });
}

function openImportDrawer(kind) {
  const title = kind === "category" ? "Kategorie-Import" : "Produkt-Import";
  openDrawer(title, `
    <form class="stack">
      ${textarea("payload", "JSON Array oder NDJSON", "", kind === "category" ? '[{"categoryCode":310,"categoryName":"Obst & Gemüse"}]' : '[{"id":101,"name":"Apfel","price":1.99,"layoutCode":"A-01","storeCode":"SPAR-Leonding-001"}]')}
      <div class="notice">Schritt 1 Parse, Schritt 2 Review, Schritt 3 Commit. Der Commit nutzt nur vorhandene Backend-Endpunkte.</div>
      <div class="toolbar"><button class="primary">Parsen und committen</button></div>
    </form>
  `, (drawer) => {
    drawer.querySelector("form").addEventListener("submit", async (event) => {
      event.preventDefault();
      try {
        const items = parseImportText(formValues(event.currentTarget).payload);
        if (!items.length) throw new Error("Keine Datensaetze gefunden.");
        await apiPost(kind === "category" ? API.categoryBulk : API.productBulk, items);
        closeDrawer();
        toast(`${items.length} Datensatz/Datensaetze importiert.`);
        kind === "category" ? renderCategories() : renderProducts();
      } catch (error) {
        toast(`Import abgebrochen: ${error.message}`, "danger");
      }
    });
  });
}

function openRecipeDrawer(recipe = {}) {
  openDrawer(recipe.id ? "Rezept bearbeiten" : "Rezept anlegen", `
    <div class="stepper"><div class="step active">1 Metadata</div><div class="step active">2 Zutaten</div><div class="step active">3 Schritte</div><div class="step">4 Publish</div></div>
    <form class="stack">
      <div class="form-grid">
        ${field("slug", "Slug", recipe.slug || "", "text", "", "apfel-hafer-crumble")}
        ${field("title", "Titel", recipe.title || "", "text", "", "Apfel-Hafer-Crumble")}
        ${field("servings", "Portionen", recipe.servings ?? 2, "number", "", "4")}
        ${field("prepTimeMinutes", "Vorbereitung min", recipe.prepTimeMinutes ?? "", "number", "", "12")}
        ${field("cookTimeMinutes", "Kochen min", recipe.cookTimeMinutes ?? "", "number", "", "25")}
        ${field("totalTimeMinutes", "Gesamt min", recipe.totalTimeMinutes ?? "", "number", "", "37")}
        <div class="span-2">${textarea("summary", "Summary", recipe.summary || "", "Warmer Crumble mit Apfel, Hafer und Butter.")}</div>
        <div class="span-2">${textarea("description", "Beschreibung", recipe.description || "", "Ein einfaches Ofenrezept fuer 4 Portionen.")}</div>
        <div class="span-2">${textarea("ingredientsText", "Zutaten", (recipe.ingredients || []).map((item, index) => `${index + 1};${item.displayName};${item.quantityText || ""}`).join("\n"), "1;Apfel;4 Stk\n2;Haferflocken;120 g\n3;Butter;80 g")}</div>
        <div class="span-2">${textarea("stepsText", "Schritte", (recipe.steps || []).map((item, index) => `${index + 1};${item.instruction}`).join("\n"), "1;Aepfel schneiden und in die Form geben\n2;Haferflocken und Butter verkneten\n3;25 Minuten backen")}</div>
      </div>
      <div data-error-summary></div>
      <div class="toolbar"><button class="primary">Speichern</button></div>
    </form>
  `, (drawer) => {
    drawer.querySelector("form").addEventListener("submit", async (event) => {
      event.preventDefault();
      const values = formValues(event.currentTarget);
      const errors = validateRecipeForm(values);
      if (showErrors(event.currentTarget, errors)) return;
      const recipePayload = {
        slug: values.slug,
        title: values.title,
        summary: values.summary || null,
        description: values.description || null,
        servings: Number(values.servings),
        prepTimeMinutes: numberOrNull(values.prepTimeMinutes),
        cookTimeMinutes: numberOrNull(values.cookTimeMinutes),
        totalTimeMinutes: numberOrNull(values.totalTimeMinutes),
        status: recipe.status || "DRAFT",
        tagIds: []
      };
      const ingredients = rowsFromText(values.ingredientsText).map(([position, displayName, quantityText]) => ({ position: Number(position), displayName, quantityText, optional: false }));
      const steps = rowsFromText(values.stepsText).map(([position, instruction]) => ({ position: Number(position), instruction }));
      if (recipe.id) {
        await apiPut(`${API.recipes}/${recipe.id}`, recipePayload);
      } else {
        await apiPost(API.recipes, { recipe: recipePayload, ingredients, steps });
      }
      closeDrawer();
      toast("Rezept gespeichert.");
      renderRecipes();
    });
  });
}

async function openMappingDrawer(recipe) {
  openDrawer("Zutaten-Mapping", `<div class="loading">Mapping wird geladen...</div>`);
  const mapping = await safeGet(`${API.recipes}/${recipe.id}/mapping-status`, { ingredients: [] });
  const drawer = document.querySelector(".drawer");
  drawer.innerHTML = `
    <div class="split"><h2>Zutaten-Mapping</h2><button class="ghost" data-close-drawer>Schliessen</button></div>
    <div class="stack">
      ${normalizeList(mapping.ingredients).map((item) => `
        <div class="panel">
          <div class="split"><strong>${escapeHtml(item.ingredientName)}</strong>${badge(item.status, item.status === "RESOLVED" ? "success" : "warning")}</div>
          <p class="muted">${escapeHtml(item.reason || "Vorschlaege pruefen oder manuell bestaetigen.")}</p>
          ${(item.candidates || []).map((candidate) => `<div class="split"><span>${escapeHtml(candidate.name)} <span class="mono">${escapeHtml(candidate.layoutCode || "-")}</span></span><button class="small" data-map="${item.ingredientId}" data-product="${candidate.id}">Zuordnen</button></div>`).join("") || empty("Keine Vorschlaege.", "Produktsuche im Backend lieferte keinen sicheren Treffer.")}
        </div>
      `).join("") || empty("Keine Mapping-Daten.", "Dieses Rezept hat noch keine Zutaten.")}
    </div>
  `;
  drawer.querySelector("[data-close-drawer]")?.addEventListener("click", closeDrawer);
  drawer.querySelectorAll("[data-map]").forEach((button) => {
    button.addEventListener("click", async () => {
      const candidate = normalizeList(mapping.ingredients).flatMap((item) => item.candidates || []).find((product) => String(product.id) === button.dataset.product);
      await apiPut(`${API.recipes}/${recipe.id}/ingredients/${button.dataset.map}/product-mapping`, {
        productId: candidate.id,
        productName: candidate.name,
        layoutCode: candidate.layoutCode,
        storeId: candidate.storeId || null,
        storeCode: candidate.storeCode || null,
        mappingType: "MANUAL",
        confidence: 1,
        manuallyConfirmed: true
      });
      toast("Mapping bestaetigt.");
      closeDrawer();
      renderRecipes();
    });
  });
}

function table({ columns, rows, emptyMessage }) {
  if (!rows.length) return empty(emptyMessage, "Passe Suche, Filter oder Scope an.");
  return `<div class="table-wrap"><table><thead><tr>${columns.map((c) => `<th>${escapeHtml(c)}</th>`).join("")}</tr></thead><tbody>${rows.map((row) => `<tr>${row.map((cell) => `<td>${cell}</td>`).join("")}</tr>`).join("")}</tbody></table></div>`;
}

function actions(items) {
  return `<div class="row-actions">${items.map(([label, action, tone]) => {
    if (typeof action === "string") return `<a class="button small ${tone || ""}" href="${action}">${escapeHtml(label)}</a>`;
    const id = `action-${Math.random().toString(36).slice(2)}`;
    actionRegistry.set(id, action);
    return `<button class="small ${tone || ""}" data-action-id="${id}">${escapeHtml(label)}</button>`;
  }).join("")}</div>`;
}

const actionRegistry = new Map();
function hydrateActions() {
  document.querySelectorAll("[data-action-id]").forEach((button) => {
    button.addEventListener("click", () => actionRegistry.get(button.dataset.actionId)?.());
  });
}

function hydrateFilters(callback) {
  document.querySelectorAll("[data-filter]").forEach((control) => {
    control.addEventListener("input", () => {
      state.filters[control.dataset.filter] = control.value;
      state.page = 1;
      callback();
    });
  });
}

function searchFilter(label, placeholder) {
  return `<div class="field"><label>${label}</label><input data-filter="query" value="${escapeHtml(state.filters.query || "")}" placeholder="${escapeHtml(placeholder)}"></div>`;
}

function selectFilter(name, label, options) {
  return `<div class="field"><label>${label}</label><select data-filter="${name}">${options.map(([value, text]) => `<option value="${escapeHtml(value)}" ${state.filters[name] === value ? "selected" : ""}>${escapeHtml(text)}</option>`).join("")}</select></div>`;
}

function applyQuery(rows, fields) {
  return rows.filter((row) => includesText(row, state.filters.query, fields));
}

function pager(page) {
  return `<div class="split" style="margin-top:12px"><span class="muted">${page.totalRows} Eintraege · Seite ${page.page}/${page.totalPages}</span><div class="toolbar"><button class="small" ${page.page <= 1 ? "disabled" : ""} data-page="${page.page - 1}">Zurueck</button><button class="small" ${page.page >= page.totalPages ? "disabled" : ""} data-page="${page.page + 1}">Weiter</button></div></div>`;
}

document.addEventListener("click", (event) => {
  const pageButton = event.target.closest("[data-page]");
  if (pageButton) {
    state.page = Number(pageButton.dataset.page);
    renderRoute();
  }
});

function openDrawer(title, html, hydrate = () => {}) {
  closeDrawer();
  const backdrop = document.createElement("div");
  backdrop.className = "drawer-backdrop";
  backdrop.innerHTML = `<aside class="drawer"><div class="split"><h2>${escapeHtml(title)}</h2><button class="ghost" data-close-drawer>Schliessen</button></div><div style="height:16px"></div>${html}</aside>`;
  document.body.append(backdrop);
  backdrop.querySelector("[data-close-drawer]").addEventListener("click", closeDrawer);
  hydrate(backdrop.querySelector(".drawer"));
}

function closeDrawer() {
  document.querySelector(".drawer-backdrop")?.remove();
}

function confirmMutation(title, body, mutate, after) {
  const backdrop = document.createElement("div");
  backdrop.className = "dialog-backdrop";
  backdrop.innerHTML = `
    <section class="dialog">
      <h2>${escapeHtml(title)}</h2>
      <p class="muted">${escapeHtml(body)}</p>
      <div class="toolbar"><button data-cancel>Abbrechen</button><button class="danger" data-confirm>Bestaetigen</button></div>
    </section>
  `;
  document.body.append(backdrop);
  backdrop.querySelector("[data-cancel]").addEventListener("click", () => backdrop.remove());
  backdrop.querySelector("[data-confirm]").addEventListener("click", async () => {
    await mutate();
    backdrop.remove();
    toast("Aktion abgeschlossen.");
    after?.();
  });
}

function formValues(form) {
  return Object.fromEntries(new FormData(form).entries());
}

function showErrors(form, errors) {
  const entries = Object.entries(errors);
  const summary = form.querySelector("[data-error-summary]");
  if (summary) summary.innerHTML = entries.length ? `<div class="notice danger">${entries.map(([, message]) => escapeHtml(message)).join("<br>")}</div>` : "";
  return entries.length > 0;
}

function field(name, label, value = "", type = "text", step = "", placeholder = "") {
  return `<div class="field"><label for="${name}">${escapeHtml(label)}</label><input id="${name}" name="${name}" type="${type}" value="${escapeHtml(value)}" ${step ? `step="${escapeHtml(step)}"` : ""} placeholder="${escapeHtml(placeholder)}"></div>`;
}

function textarea(name, label, value = "", placeholder = "") {
  return `<div class="field"><label for="${name}">${escapeHtml(label)}</label><textarea id="${name}" name="${name}" placeholder="${escapeHtml(placeholder)}">${escapeHtml(value)}</textarea></div>`;
}

function selectField(name, label, options, value = "") {
  return `<div class="field"><label for="${name}">${escapeHtml(label)}</label><select id="${name}" name="${name}"><option value="">Bitte waehlen</option>${options.map(([optionValue, text]) => `<option value="${escapeHtml(optionValue)}" ${String(optionValue) === String(value) ? "selected" : ""}>${escapeHtml(text)}</option>`).join("")}</select></div>`;
}

function stat(label, value, hint) {
  return `<div class="stat"><div class="stat-label">${escapeHtml(label)}</div><div class="stat-value">${escapeHtml(value)}</div><div class="stat-hint">${escapeHtml(hint)}</div></div>`;
}

function badge(label, tone = "muted") {
  return `<span class="badge ${tone}">${escapeHtml(label)}</span>`;
}

function mono(value) {
  return `<span class="mono">${escapeHtml(value ?? "-")}</span>`;
}

function empty(title, body) {
  return `<div class="empty"><strong>${escapeHtml(title)}</strong><br>${escapeHtml(body)}</div>`;
}

function detailList(items) {
  return `<dl class="stack">${items.map(([key, value]) => `<div><dt class="muted">${escapeHtml(key)}</dt><dd style="margin:0">${escapeHtml(value)}</dd></div>`).join("")}</dl>`;
}

function renderEventList(events) {
  if (!events.length) return empty("Keine Events.", "Noch keine sichtbaren Aktivitaeten.");
  return `<div class="stack">${events.map((event) => `<div class="notice"><div class="split"><strong>${escapeHtml(event.action || event.summary || "Event")}</strong><span class="muted">${formatDate(event.createdAt)}</span></div><div class="muted">${escapeHtml(event.summary || event.actorLabel || "")}</div></div>`).join("")}</div>`;
}

function renderDiagnostics(errors) {
  if (!errors.length) return empty("Keine Fehlerlogs.", "Systemdiagnose ist aktuell ruhig.");
  return `<div class="stack">${errors.slice(0, 30).map((log) => `<details class="notice"><summary><strong>${escapeHtml(log.message || log.error || "Fehler")}</strong> <span class="muted">${formatDate(log.createdAt)}</span></summary><pre class="mono">${escapeHtml(log.stackTrace || log.stack || JSON.stringify(log, null, 2))}</pre></details>`).join("")}</div>`;
}

function renderBeaconMiniList(beacons) {
  if (!beacons.length) return empty("Keine Beacons zugewiesen.", "Starte die Zuweisung aus Beacons oder Store Detail.");
  return `<div class="stack">${beacons.map((beacon) => `<div class="split"><span>${escapeHtml(beacon.beaconCode)}</span>${badge(beacon.identityKey || "aktiv", "info")}</div>`).join("")}</div>`;
}

function renderLayoutList(layouts, storeId) {
  if (!layouts.length) return empty("Keine Layout-Versionen.", "Oeffne den Editor und speichere eine erste Version.");
  return `<div class="stack">${layouts.map((layout) => `<div class="split"><span>Version ${escapeHtml(layout.versionNo || layout.layoutName || layout.layoutId)}</span><span>${badge(layout.active ? "Aktiv" : "Version", layout.active ? "success" : "muted")} <a class="button small" href="/admin/editor/?storeId=${storeId}&layoutId=${layout.layoutId || layout.id}">Oeffnen</a></span></div>`).join("")}</div>`;
}

function rowsFromText(text) {
  return String(text || "").split(/\r?\n/).filter(Boolean).map((line) => line.split(";").map((part) => part.trim()));
}

function numberOrNull(value) {
  return value === "" || value == null ? null : Number(value);
}

function canAccess(role) {
  return userRoles(state.user).includes(role);
}

async function safeGet(url, fallback) {
  try {
    return await apiGet(url);
  } catch (error) {
    toast(error.message, "danger");
    return fallback;
  }
}

async function apiGet(url) {
  return request(url);
}

async function apiPost(url, body) {
  return request(url, { method: "POST", body: JSON.stringify(body) });
}

async function apiPut(url, body) {
  return request(url, { method: "PUT", body: JSON.stringify(body) });
}

async function apiPatch(url, body) {
  return request(url, { method: "PATCH", body: JSON.stringify(body) });
}

async function apiDelete(url) {
  return request(url, { method: "DELETE" });
}

async function request(url, options = {}) {
  const response = await fetch(url, {
    credentials: "same-origin",
    headers: { Accept: "application/json", ...(options.body ? { "Content-Type": "application/json" } : {}) },
    ...options
  });
  const text = await response.text();
  const data = text ? parseMaybeJson(text) : null;
  if (response.status === 401) {
    location.href = "/admin/";
    throw new Error("Anmeldung erforderlich.");
  }
  if (response.status === 403) {
    throw new Error("Kein Zugriff auf diesen Workflow.");
  }
  if (!response.ok) {
    throw new Error(data?.message || data?.error || text || `Request failed (${response.status})`);
  }
  return data;
}

function parseMaybeJson(text) {
  try { return JSON.parse(text); } catch { return text; }
}

function renderAccessDenied() {
  setPage("Kein Zugriff", "Diese Seite liegt ausserhalb deiner Rolle oder deines Scopes.");
  content(`<section class="access-denied"><strong>403</strong><br>Navigation und Direktzugriff sind role-aware. Waehle links eine erlaubte Seite.</section>`);
}

function fatal(error) {
  root.className = "access-denied";
  root.innerHTML = `<strong>Admin Platform konnte nicht geladen werden.</strong><br>${escapeHtml(error.message || error)}`;
}

function toast(message, tone = "success") {
  const region = document.querySelector("#toasts") || document.body.appendChild(Object.assign(document.createElement("div"), { id: "toasts", className: "toast-region" }));
  const item = document.createElement("div");
  item.className = `toast ${tone}`;
  item.textContent = message;
  region.append(item);
  setTimeout(() => item.remove(), 4200);
}

function icon(name) {
  const icons = { grid: "▦", map: "⌖", store: "▤", radio: "◉", box: "□", tags: "⌗", book: "▧", layout: "▣", terminal: "▥" };
  return icons[name] || "•";
}
