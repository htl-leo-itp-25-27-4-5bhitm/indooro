let categoriesMap = {};
const API_BASE = 'http://localhost:8080/api';

async function loadCategories() {
  try {
    const res = await fetch('../assets/data/categories.json');
    if (!res.ok) throw new Error('Categories nicht gefunden');
    const categories = await res.json();
    categoriesMap = {};
    categories.forEach(cat => {
      categoriesMap[cat.categoryCode] = cat.categoryName;
    });
  } catch (error) {
    console.warn('Categories konnten nicht geladen werden:', error);
  }
}

async function loadProducts() {
  try {
    const res = await fetch(`${API_BASE}/products?size=200`);
    if (!res.ok) throw new Error('Netzwerkfehler');
    const raw = await res.json();
    return enrichProducts(raw);
  } catch (error) {
    console.error('Fehler beim Laden der Produkte:', error);
    throw error;
  }
}

async function searchProducts(query) {
  try {
    const res = await fetch(`${API_BASE}/products/search?q=${encodeURIComponent(query)}&size=50`);
    if (!res.ok) throw new Error('Suchfehler');
    const raw = await res.json();
    return enrichProducts(raw);
  } catch (error) {
    console.error('Fehler bei der Suche:', error);
    throw error;
  }
}

function parseLayoutCode(code) {
  if (typeof code !== 'string') return null;
  const parts = code.split('/');
  if (parts.length !== 4) return null;
  const [cat, meter, fach, reihe] = parts.map(n => Number.parseInt(n, 10));
  if ([cat, meter, fach, reihe].some(n => !Number.isFinite(n))) return null;
  return { cat, meter, fach, reihe };
}

function enrichProducts(products) {
  const out = [];
  for (const p of products) {
    const layout = parseLayoutCode(p.layoutCode);
    if (!layout) {
      console.warn('Ignoriere Produkt mit ungültigem layoutCode:', p);
      continue;
    }
    out.push({ 
      ...p, 
      categoryCode: layout.cat,
      layout 
    });
  }
  return out;
}

function buildModel(products) {
  const model = {};
  for (const p of products) {
    const cat = p.categoryCode;
    if (!model[cat]) {
      model[cat] = {
        categoryCode: cat,
        categoryName: categoriesMap[cat] || `Kategorie ${cat}`,
        products: [],
        meters: { 1: [], 2: [], 3: [], 4: [], 5: [] }
      };
    }
    model[cat].products.push(p);
    const m = Math.min(5, Math.max(1, p.layout.meter));
    model[cat].meters[m].push(p);
  }
  return model;
}

function renderMarket(model) {
  const container = document.getElementById('supermarket-container');
  container.innerHTML = '';
  
  const categories = Object.values(model).sort((a, b) => a.categoryCode - b.categoryCode);
  
  categories.forEach((category, index) => {
    const row = document.createElement('div');
    row.className = 'shelf-row';
    
    const label = document.createElement('div');
    label.className = 'shelf-label';
    label.textContent = category.categoryCode;
    row.appendChild(label);
    
    for (let meter = 1; meter <= 5; meter++) {
      const shelfMeter = document.createElement('div');
      shelfMeter.className = 'shelf-meter';
      shelfMeter.dataset.cat = category.categoryCode;
      shelfMeter.dataset.meter = meter;
      shelfMeter.setAttribute('role', 'button');
      shelfMeter.setAttribute('tabindex', '0');
      shelfMeter.setAttribute('aria-label', `Kategorie ${category.categoryCode}, Meter ${meter}`);
      
      const productsInMeter = category.meters[meter] || [];
      productsInMeter.forEach(product => {
        const marker = document.createElement('div');
        marker.className = 'product-marker';
        marker.title = `${product.name} – €${product.price.toFixed(2)}`;
        shelfMeter.appendChild(marker);
      });
      
      row.appendChild(shelfMeter);
    }
    
    container.appendChild(row);
    
    if (index < categories.length - 1) {
      const gang = document.createElement('div');
      gang.className = 'gang';
      container.appendChild(gang);
    }
  });
  
  container.addEventListener('click', (e) => {
    const meter = e.target.closest('.shelf-meter');
    if (!meter) return;
    
    const cat = Number(meter.dataset.cat);
    const meterNum = Number(meter.dataset.meter);
    
    document.querySelectorAll('.shelf-meter').forEach(el => el.classList.remove('selected'));
    meter.classList.add('selected');
    
    renderShelfDetail(cat, meterNum, model);
  });
  
  container.addEventListener('keydown', (e) => {
    if (e.key !== 'Enter' && e.key !== ' ') return;
    const meter = e.target.closest('.shelf-meter');
    if (!meter) return;
    
    e.preventDefault();
    const cat = Number(meter.dataset.cat);
    const meterNum = Number(meter.dataset.meter);
    
    document.querySelectorAll('.shelf-meter').forEach(el => el.classList.remove('selected'));
    meter.classList.add('selected');
    
    renderShelfDetail(cat, meterNum, model);
  });
}

function renderShelfDetail(categoryCode, meter, model) {
  const panel = document.getElementById('shelf-details-content');
  panel.innerHTML = '';
  
  const categoryName = model[categoryCode]?.categoryName || `Kategorie ${categoryCode}`;
  
  const header = document.createElement('h2');
  header.textContent = `${categoryName} – Meter ${meter}`;
  panel.appendChild(header);
  
  const list = (model[categoryCode]?.meters?.[meter] ?? []).filter(p => p?.layout);
  
  if (list.length === 0) {
    const empty = document.createElement('div');
    empty.className = 'empty-message';
    empty.textContent = 'Keine Produkte in diesem Regalabschnitt.';
    panel.appendChild(empty);
    return;
  }
  
  const maxFach = list.reduce((acc, p) => Math.max(acc, p.layout.fach ?? 0), 0) || 1;
  const maxReihe = list.reduce((acc, p) => Math.max(acc, p.layout.reihe ?? 0), 0) || 1;
  
  const grid = document.createElement('div');
  grid.className = 'shelf-matrix';
  grid.style.gridTemplateRows = `repeat(${maxFach}, minmax(60px, auto))`;
  grid.style.gridTemplateColumns = `repeat(${maxReihe}, 1fr)`;
  
  const cellMap = new Map();
  
  list.sort((a, b) => 
    (a.layout.fach - b.layout.fach) || 
    (a.layout.reihe - b.layout.reihe) || 
    a.name.localeCompare(b.name)
  );
  
  for (const p of list) {
    const { fach, reihe } = p.layout;
    const key = `${fach}-${reihe}`;
    
    if (!cellMap.has(key)) {
      const cell = document.createElement('div');
      cell.className = 'shelf-slot';
      cell.style.gridRowStart = String(fach);
      cell.style.gridColumnStart = String(reihe);
      
      const title = document.createElement('div');
      title.className = 'slot-title';
      title.textContent = `Fach ${fach}, Reihe ${reihe}`;
      
      const ul = document.createElement('ul');
      ul.className = 'slot-products';
      
      cell.appendChild(title);
      cell.appendChild(ul);
      cellMap.set(key, ul);
      grid.appendChild(cell);
    }
    
    const ul = cellMap.get(key);
    const li = document.createElement('li');
    li.innerHTML = `
      <div class="product-name">${p.name}</div>
      <div class="product-price">€${Number(p.price).toFixed(2)}</div>
    `;
    ul.appendChild(li);
  }
  
  panel.appendChild(grid);
}

function renderSearchResults(products) {
  const panel = document.getElementById('shelf-details-content');
  panel.innerHTML = '';
  
  const header = document.createElement('h2');
  header.textContent = `Suchergebnisse (${products.length})`;
  panel.appendChild(header);
  
  if (products.length === 0) {
    const empty = document.createElement('div');
    empty.className = 'empty-message';
    empty.textContent = 'Keine Produkte gefunden.';
    panel.appendChild(empty);
    return;
  }
  
  const resultList = document.createElement('div');
  resultList.className = 'search-results';
  
  products.forEach(p => {
    const item = document.createElement('div');
    item.className = 'search-result-item';
    
    const categoryName = categoriesMap[p.categoryCode] || `Kategorie ${p.categoryCode}`;
    const location = p.layout 
      ? `${categoryName} – Meter ${p.layout.meter}, Fach ${p.layout.fach}, Reihe ${p.layout.reihe}`
      : categoryName;
    
    item.innerHTML = `
      <div class="product-name">${p.name}</div>
      <div class="product-price">€${Number(p.price).toFixed(2)}</div>
      <div class="product-location">${location}</div>
    `;
    
    if (p.layout) {
      item.addEventListener('click', () => {
        document.querySelectorAll('.shelf-meter').forEach(el => el.classList.remove('selected'));
        const meter = document.querySelector(
          `.shelf-meter[data-cat="${p.categoryCode}"][data-meter="${p.layout.meter}"]`
        );
        if (meter) {
          meter.classList.add('selected');
          meter.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
        
        const model = buildModel(window.currentProducts || []);
        renderShelfDetail(p.categoryCode, p.layout.meter, model);
      });
      item.style.cursor = 'pointer';
    }
    
    resultList.appendChild(item);
  });
  
  panel.appendChild(resultList);
}

function setupSearch() {
  const searchInput = document.getElementById('search-input');
  const searchButton = document.getElementById('search-button');
  const clearButton = document.getElementById('clear-search');
  
  let searchTimeout;
  
  async function performSearch() {
    const query = searchInput.value.trim();
    
    if (!query) {
      clearButton.style.display = 'none';
      if (window.currentProducts) {
        const model = buildModel(window.currentProducts);
        renderMarket(model);
      }
      return;
    }
    
    clearButton.style.display = 'inline-block';
    
    try {
      const results = await searchProducts(query);
      window.searchResults = results;
      renderSearchResults(results);
    } catch (error) {
      const panel = document.getElementById('shelf-details-content');
      panel.innerHTML = '<div class="error-message">Fehler bei der Suche.</div>';
    }
  }
  
  searchInput.addEventListener('input', () => {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(performSearch, 300);
  });
  
  searchButton.addEventListener('click', performSearch);
  
  searchInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
      performSearch();
    }
  });
  
  clearButton.addEventListener('click', () => {
    searchInput.value = '';
    clearButton.style.display = 'none';
    if (window.currentProducts) {
      const model = buildModel(window.currentProducts);
      renderMarket(model);
    }
    const panel = document.getElementById('shelf-details-content');
    panel.innerHTML = '<p>Klicken Sie auf ein Regal, um Details anzuzeigen.</p>';
  });
}

document.addEventListener('DOMContentLoaded', async () => {
  try {
    await loadCategories();
    const enriched = await loadProducts();
    window.currentProducts = enriched;
    const model = buildModel(enriched);
    renderMarket(model);
    setupSearch();
  } catch (e) {
    const panel = document.getElementById('shelf-details-content');
    if (panel) {
      panel.innerHTML = '<div class="error-message">Daten konnten nicht geladen werden. Bitte stellen Sie sicher, dass der Server läuft.</div>';
    }
    console.error(e);
  }
});
