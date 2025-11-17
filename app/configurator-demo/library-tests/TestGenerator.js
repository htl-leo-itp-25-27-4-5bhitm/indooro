/* ----- Data (aus React übernommen) ----- */
const PRODUCT_CATEGORIES = [
  { id: 'entrance', name: 'Eingang/Wagenzone', color: '#E8F5E9', icon: '🚪' },
  { id: 'seating', name: 'Sitzbereich', color: '#FFF3E0', icon: '🪑' },
  { id: 'wc', name: 'Kunden-WC', color: '#F3E5F5', icon: '🚻' },
  { id: 'bakery', name: 'Backwaren', color: '#FFEB3B', icon: '🥖' },
  { id: 'fruits', name: 'Obst & Gemüse', color: '#4CAF50', icon: '🥬' },
  { id: 'convenience', name: 'Convenience', color: '#FF9800', icon: '🍱' },
  { id: 'flowers', name: 'Blumen', color: '#E91E63', icon: '🌸' },
  { id: 'books', name: 'Bücher/Schreibwaren', color: '#9C27B0', icon: '📚' },
  { id: 'hygiene', name: 'Hygiene/Windeln', color: '#00BCD4', icon: '🧴' },
  { id: 'household', name: 'Haushaltswaren', color: '#795548', icon: '🍳' },
  { id: 'bread', name: 'Brot/Kuchen', color: '#FFC107', icon: '🍞' },
  { id: 'dairy', name: 'Molkerei/Eier', color: '#BBDEFB', icon: '🥛' },
  { id: 'cheese', name: 'Käse', color: '#FFE082', icon: '🧀' },
  { id: 'meat', name: 'Fleisch/Wurst', color: '#FFCDD2', icon: '🥩' },
  { id: 'counter', name: 'Bedienungstheke', color: '#F44336', icon: '👨‍🍳' },
  { id: 'beverages', name: 'Getränke', color: '#2196F3', icon: '🍺' },
  { id: 'frozen', name: 'Tiefkühl', color: '#B3E5FC', icon: '❄️' },
  { id: 'nonfood', name: 'Non-Food', color: '#CFD8DC', icon: '📦' },
  { id: 'seasonal', name: 'Saison/Aktion', color: '#FFAB91', icon: '⭐' },
  { id: 'checkout', name: 'Kassen', color: '#81C784', icon: '💳' },
  { id: 'service', name: 'Servicepunkt', color: '#64B5F6', icon: 'ℹ️' },
  { id: 'shopinshop', name: 'Shop-in-Shop', color: '#BA68C8', icon: '🏪' },
  { id: 'storage', name: 'Lager', color: '#757575', icon: '📦' },
  { id: 'staff', name: 'Personalbereich', color: '#9E9E9E', icon: '👥' },
];

const ELEMENT_TYPES = [
  { id: 'shelf', name: 'Regal', icon: '▭' },
  { id: 'island', name: 'Insel', icon: '◯' },
  { id: 'counter', name: 'Theke', icon: '▬' },
  { id: 'cooler', name: 'Kühlregal', icon: '❄' },
  { id: 'area', name: 'Fläche', icon: '◻' },
];

const TEMPLATES = [
  { id: 'small', name: 'Kleiner Laden (15x20m)', width: 30, height: 40 },
  { id: 'medium', name: 'Mittlerer Laden (20x30m)', width: 40, height: 60 },
  { id: 'large', name: 'Großer Laden (30x40m)', width: 60, height: 80 },
  { id: 'custom', name: 'Eigene Größe', width: 40, height: 60 },
];

/* ----- State (Vanilla) ----- */
let elements = [];
let selectedElement = null;
let isDrawing = false;
let drawStart = null;
let isDragging = false;
let dragOffset = { x: 0, y: 0 };

let currentTool = 'select';
let currentCategory = PRODUCT_CATEGORIES[0];
let currentElementType = ELEMENT_TYPES[0];
let gridSize = { width: 40, height: 60 };
let showGrid = true;
let zoom = 1;
let shopName = 'Mein Supermarkt';

const cellSize = 20; // pixels per meter cell

/* ----- DOM references ----- */
const toolSelectBtn = document.getElementById('toolSelect');
const toolDrawBtn = document.getElementById('toolDraw');
const categoriesDiv = document.getElementById('categories');
const elementTypesDiv = document.getElementById('elementTypes');
const templatesDiv = document.getElementById('templates');
const canvasContainer = document.getElementById('canvasContainer');
const showGridCheckbox = document.getElementById('showGrid');
const zoomLabel = document.getElementById('zoomLabel');
const zoomInBtn = document.getElementById('zoomIn');
const zoomOutBtn = document.getElementById('zoomOut');
const exportBtn = document.getElementById('exportBtn');
const fileInput = document.getElementById('fileInput');
const countElementsSpan = document.getElementById('countElements');
const areaSizeW = document.getElementById('areaSize');
const areaSizeH = document.getElementById('areaSizeH');
const gridWidthInput = document.getElementById('gridWidth');
const gridHeightInput = document.getElementById('gridHeight');
const propertiesWrapper = document.getElementById('propertiesWrapper');
const modeLabel = document.getElementById('modeLabel');
const shopNameInput = document.getElementById('shopName');

/* ----- Init UI ----- */
function initUI() {
  // element types
  ELEMENT_TYPES.forEach(type => {
    const btn = document.createElement('button');
    btn.className = `px-3 py-2 rounded text-sm ${currentElementType.id === type.id ? 'bg-blue-500 text-white' : 'bg-gray-100'}`;
    btn.innerText = `${type.icon} ${type.name}`;
    btn.onclick = () => {
      currentElementType = type;
      Array.from(elementTypesDiv.children).forEach(c => c.classList.remove('bg-blue-500','text-white'));
      btn.classList.add('bg-blue-500','text-white');
    };
    elementTypesDiv.appendChild(btn);
  });

  // categories
  PRODUCT_CATEGORIES.forEach(cat => {
    const btn = document.createElement('button');
    btn.className = `w-full px-3 py-2 rounded text-left text-sm flex items-center gap-2`;
    btn.style.backgroundColor = cat.color;
    btn.innerHTML = `<span>${cat.icon}</span><span class="flex-1">${cat.name}</span>`;
    btn.onclick = () => {
      currentCategory = cat;
      Array.from(categoriesDiv.children).forEach(c => c.classList.remove('ring-2','ring-blue-500'));
      btn.classList.add('ring-2','ring-blue-500');
    };
    if (cat.id === currentCategory.id) btn.classList.add('ring-2','ring-blue-500');
    categoriesDiv.appendChild(btn);
  });

  // templates
  TEMPLATES.forEach(t => {
    const b = document.createElement('button');
    b.className = 'w-full px-3 py-2 bg-gray-100 hover:bg-gray-200 rounded text-sm text-left';
    b.innerText = t.name;
    b.onclick = () => applyTemplate(t);
    templatesDiv.appendChild(b);
  });

  // grid size inputs listeners
  gridWidthInput.value = gridSize.width;
  gridHeightInput.value = gridSize.height;
  gridWidthInput.addEventListener('change', () => {
    gridSize.width = Math.max(1, parseInt(gridWidthInput.value) || 1);
    renderCanvas();
  });
  gridHeightInput.addEventListener('change', () => {
    gridSize.height = Math.max(1, parseInt(gridHeightInput.value) || 1);
    renderCanvas();
  });

  // tool buttons
  toolSelectBtn.onclick = () => setTool('select');
  toolDrawBtn.onclick = () => setTool('draw');

  // grid toggle
  showGridCheckbox.onchange = () => { showGrid = showGridCheckbox.checked; renderCanvas(); };

  // zoom
  function setZoom(z) { zoom = Math.max(0.1, Math.min(3, Math.round(z*10)/10)); zoomLabel.innerText = Math.round(zoom*100)+'%'; renderCanvas(); }
  zoomInBtn.onclick = () => setZoom(zoom + 0.1);
  zoomOutBtn.onclick = () => setZoom(zoom - 0.1);

  // export/import
  exportBtn.onclick = exportLayout;
  fileInput.onchange = importLayout;
  document.getElementById('newBtn').onclick = () => {
  if (confirm('Möchtest du wirklich ein neues Layout starten? Alle aktuellen Elemente gehen verloren.')) {
    elements = [];
    selectedElement = null;
    renderProperties();
    renderCanvas();
  }
};


  // shop name
  shopNameInput.addEventListener('input', () => shopName = shopNameInput.value);

  // initial render
  setTool('select');
  renderCanvas();
}

/* ----- Tool management ----- */
function setTool(t) {
  currentTool = t;
  if (t === 'select') {
    toolSelectBtn.classList.add('bg-blue-500','text-white');
    toolSelectBtn.classList.remove('bg-gray-100');
    toolDrawBtn.classList.remove('bg-blue-500','text-white');
    toolDrawBtn.classList.add('bg-gray-100');
    modeLabel.innerText = 'Auswahlmodus';
  } else {
    toolDrawBtn.classList.add('bg-blue-500','text-white');
    toolDrawBtn.classList.remove('bg-gray-100');
    toolSelectBtn.classList.remove('bg-blue-500','text-white');
    toolSelectBtn.classList.add('bg-gray-100');
    modeLabel.innerText = 'Zeichenmodus';
  }
}

/* ----- Canvas rendering ----- */
function renderCanvas() {
  // size container
  const widthPx = gridSize.width * cellSize * zoom;
  const heightPx = gridSize.height * cellSize * zoom;
  canvasContainer.style.width = widthPx + 'px';
  canvasContainer.style.height = heightPx + 'px';

  // content
  canvasContainer.innerHTML = '';

  // grid SVG
  if (showGrid) {
    const svg = document.createElementNS('http://www.w3.org/2000/svg','svg');
    svg.setAttribute('class','absolute inset-0 pointer-events-none');
    svg.setAttribute('width', widthPx);
    svg.setAttribute('height', heightPx);
    svg.style.left = '0';
    svg.style.top = '0';
    svg.style.position = 'absolute';

    for (let i=0;i<=gridSize.width;i++) {
      const line = document.createElementNS('http://www.w3.org/2000/svg','line');
      line.setAttribute('x1', i*cellSize*zoom);
      line.setAttribute('y1', 0);
      line.setAttribute('x2', i*cellSize*zoom);
      line.setAttribute('y2', heightPx);
      line.setAttribute('stroke', '#e5e7eb');
      line.setAttribute('stroke-width', '1');
      svg.appendChild(line);
    }
    for (let i=0;i<=gridSize.height;i++) {
      const line = document.createElementNS('http://www.w3.org/2000/svg','line');
      line.setAttribute('x1', 0);
      line.setAttribute('y1', i*cellSize*zoom);
      line.setAttribute('x2', widthPx);
      line.setAttribute('y2', i*cellSize*zoom);
      line.setAttribute('stroke', '#e5e7eb');
      line.setAttribute('stroke-width', '1');
      svg.appendChild(line);
    }
    canvasContainer.appendChild(svg);
  }

  // elements
  elements.forEach(el => {
    const cat = PRODUCT_CATEGORIES.find(c => c.id === el.category) || currentCategory;
    const div = document.createElement('div');
    div.className = 'absolute border-2 element-box flex items-center justify-center text-center text-xs font-medium overflow-hidden';
    if (selectedElement && selectedElement.id === el.id) div.classList.add('selected');
    div.style.left = (el.x * cellSize * zoom) + 'px';
    div.style.top = (el.y * cellSize * zoom) + 'px';
    div.style.width = (el.width * cellSize * zoom) + 'px';
    div.style.height = (el.height * cellSize * zoom) + 'px';
    div.style.backgroundColor = el.color || cat.color;
    div.style.opacity = '0.95';
    div.dataset.id = el.id;

    const inner = document.createElement('div');
    inner.className = 'p-1';
    inner.innerHTML = `<div class="text-lg">${cat.icon}</div><div class="text-[10px] leading-tight">${el.label}</div>`;
    div.appendChild(inner);

    // click to select
    div.addEventListener('mousedown', (ev) => {
      ev.stopPropagation();
      // compute cell coords
      const rect = canvasContainer.getBoundingClientRect();
      const x = Math.floor((ev.clientX - rect.left) / (cellSize * zoom));
      const y = Math.floor((ev.clientY - rect.top) / (cellSize * zoom));
      selectedElement = el;
      isDragging = true;
      dragOffset = { x: x - el.x, y: y - el.y };
      renderCanvas();
      renderProperties();
    });

    canvasContainer.appendChild(div);
  });

  // drawing preview
  if (isDrawing && drawStart) {
    const preview = document.createElement('div');
    preview.className = 'absolute border-2 border-dashed border-blue-500 bg-blue-100 opacity-50';
    const dx = Math.min(drawStart.x, currentMouseCell.x);
    const dy = Math.min(drawStart.y, currentMouseCell.y);
    const w = Math.abs(currentMouseCell.x - drawStart.x) + 1;
    const h = Math.abs(currentMouseCell.y - drawStart.y) + 1;
    preview.style.left = (dx * cellSize * zoom) + 'px';
    preview.style.top = (dy * cellSize * zoom) + 'px';
    preview.style.width = (w * cellSize * zoom) + 'px';
    preview.style.height = (h * cellSize * zoom) + 'px';
    canvasContainer.appendChild(preview);
  }

  // update counters
  countElementsSpan.innerText = elements.length;
  areaSizeW.innerText = gridSize.width;
  areaSizeH.innerText = gridSize.height;
}

/* track mouse cell for preview */
let currentMouseCell = { x: 0, y: 0 };

/* ----- Mouse events on canvasContainer ----- */
canvasContainer.addEventListener('mousedown', (e) => {
  const rect = canvasContainer.getBoundingClientRect();
  const x = Math.floor((e.clientX - rect.left) / (cellSize * zoom));
  const y = Math.floor((e.clientY - rect.top) / (cellSize * zoom));
  if (currentTool === 'select') {
    // click on empty space -> deselect
    const clicked = elements.find(el =>
      x >= el.x && x < el.x + el.width && y >= el.y && y < el.y + el.height
    );
    if (!clicked) {
      selectedElement = null;
      renderProperties();
      renderCanvas();
    } else {
      // handled by element mousedown handler (stops propagation)
    }
  } else if (currentTool === 'draw') {
    isDrawing = true;
    drawStart = { x, y };
    currentMouseCell = { x, y };
    renderCanvas();
  }
});

window.addEventListener('mousemove', (e) => {
  // compute mouse in canvas coords if inside container
  const rect = canvasContainer.getBoundingClientRect();
  const inside = e.clientX >= rect.left && e.clientX <= rect.right && e.clientY >= rect.top && e.clientY <= rect.bottom;
  if (!inside && !isDragging && !isDrawing) return;

  const x = Math.floor((e.clientX - rect.left) / (cellSize * zoom));
  const y = Math.floor((e.clientY - rect.top) / (cellSize * zoom));
  currentMouseCell = { x, y };

  if (isDragging && selectedElement) {
    // move selected element
    selectedElement.x = x - dragOffset.x;
    selectedElement.y = y - dragOffset.y;
    // clamp
    selectedElement.x = Math.max(0, Math.min(selectedElement.x, gridSize.width - selectedElement.width));
    selectedElement.y = Math.max(0, Math.min(selectedElement.y, gridSize.height - selectedElement.height));
    // update in elements array
    elements = elements.map(el => el.id === selectedElement.id ? selectedElement : el);
    renderCanvas();
    renderProperties();
  } else if (isDrawing && drawStart) {
    renderCanvas();
  }
});

window.addEventListener('mouseup', (e) => {
  const rect = canvasContainer.getBoundingClientRect();
  const x = Math.floor((e.clientX - rect.left) / (cellSize * zoom));
  const y = Math.floor((e.clientY - rect.top) / (cellSize * zoom));

  if (isDrawing && drawStart) {
    const nx = Math.max(0, Math.min(gridSize.width-1, x));
    const ny = Math.max(0, Math.min(gridSize.height-1, y));

    const newElement = {
      id: Date.now() + Math.floor(Math.random()*1000),
      type: currentElementType.id,
      category: currentCategory.id,
      x: Math.min(drawStart.x, nx),
      y: Math.min(drawStart.y, ny),
      width: Math.abs(nx - drawStart.x) + 1,
      height: Math.abs(ny - drawStart.y) + 1,
      label: currentCategory.name,
      color: currentCategory.color,
    };
    // add and select
    elements.push(newElement);
    selectedElement = newElement;
    renderProperties();
    renderCanvas();
  }

  isDrawing = false;
  drawStart = null;
  isDragging = false;
});

/* clicking outside canvas should stop dragging/drawing */
window.addEventListener('blur', () => { isDrawing = false; isDragging = false; renderCanvas(); });

/* delete key support */
window.addEventListener('keydown', (e) => {
  if (e.key === 'Delete' || e.key === 'Backspace') {
    if (selectedElement) {
      elements = elements.filter(el => el.id !== selectedElement.id);
      selectedElement = null;
      renderProperties();
      renderCanvas();
    }
  }
});

/* ----- Properties panel ----- */
function renderProperties() {
  propertiesWrapper.innerHTML = '';
  if (!selectedElement) return;

  const el = selectedElement;
  const cat = PRODUCT_CATEGORIES.find(c => c.id === el.category) || PRODUCT_CATEGORIES[0];

  const container = document.createElement('div');
  container.className = 'p-4 border-b border-gray-200';

  const header = document.createElement('div');
  header.className = 'flex items-center justify-between mb-3';
  header.innerHTML = `<h3 class="font-semibold">Eigenschaften</h3>`;
  const delBtn = document.createElement('button');
  delBtn.className = 'p-2 text-red-500 hover:bg-red-50 rounded';
  delBtn.innerHTML = '<svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/></svg>';
  delBtn.onclick = () => {
    elements = elements.filter(it => it.id !== el.id);
    selectedElement = null;
    renderProperties();
    renderCanvas();
  };
  header.appendChild(delBtn);
  container.appendChild(header);

  // label
  const labelDiv = document.createElement('div');
  labelDiv.className = 'space-y-3';
  labelDiv.innerHTML = `
    <div>
      <label class="block text-sm font-medium mb-1">Bezeichnung</label>
      <input id="propLabel" type="text" value="${escapeHtml(el.label)}" class="w-full px-2 py-1 border border-gray-300 rounded" />
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">Kategorie</label>
      <select id="propCategory" class="w-full px-2 py-1 border border-gray-300 rounded"></select>
    </div>
    <div>
      <label class="block text-sm font-medium mb-1">Farbe</label>
      <input id="propColor" type="color" value="${el.color || cat.color}" class="w-full h-10 border border-gray-300 rounded" />
    </div>
    <div class="grid grid-cols-2 gap-2 mt-2">
      <div>
        <label class="block text-sm font-medium mb-1">Breite</label>
        <input id="propW" type="number" value="${el.width}" min="1" class="w-full px-2 py-1 border border-gray-300 rounded" />
      </div>
      <div>
        <label class="block text-sm font-medium mb-1">Höhe</label>
        <input id="propH" type="number" value="${el.height}" min="1" class="w-full px-2 py-1 border border-gray-300 rounded" />
      </div>
    </div>
  `;
  container.appendChild(labelDiv);
  propertiesWrapper.appendChild(container);

  // fill category select
  const sel = document.getElementById('propCategory');
  PRODUCT_CATEGORIES.forEach(c => {
    const o = document.createElement('option');
    o.value = c.id;
    o.textContent = `${c.icon} ${c.name}`;
    if (c.id === el.category) o.selected = true;
    sel.appendChild(o);
  });

  // listeners
  document.getElementById('propLabel').addEventListener('input', (ev) => {
    el.label = ev.target.value;
    elements = elements.map(it => it.id === el.id ? el : it);
    renderCanvas();
  });
  document.getElementById('propCategory').addEventListener('change', (ev) => {
    const cat = PRODUCT_CATEGORIES.find(c => c.id === ev.target.value);
    if (cat) {
      el.category = cat.id;
      el.color = cat.color;
      el.label = cat.name;
      elements = elements.map(it => it.id === el.id ? el : it);
      renderCanvas();
      renderProperties();
    }
  });
  document.getElementById('propColor').addEventListener('input', (ev) => {
    el.color = ev.target.value;
    elements = elements.map(it => it.id === el.id ? el : it);
    renderCanvas();
  });
  document.getElementById('propW').addEventListener('change', (ev) => {
    el.width = Math.max(1, parseInt(ev.target.value) || 1);
    // clamp within grid
    el.width = Math.min(el.width, gridSize.width - el.x);
    elements = elements.map(it => it.id === el.id ? el : it);
    renderCanvas();
    renderProperties();
  });
  document.getElementById('propH').addEventListener('change', (ev) => {
    el.height = Math.max(1, parseInt(ev.target.value) || 1);
    el.height = Math.min(el.height, gridSize.height - el.y);
    elements = elements.map(it => it.id === el.id ? el : it);
    renderCanvas();
    renderProperties();
  });
}

/* escaping helper */
function escapeHtml(s) {
  return (s+'').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}

/* ----- Templates ----- */
function applyTemplate(t) {
  gridSize.width = t.width;
  gridSize.height = t.height;
  gridWidthInput.value = gridSize.width;
  gridHeightInput.value = gridSize.height;
  elements = [];
  selectedElement = null;
  renderProperties();
  renderCanvas();
}

/* ----- Export / Import ----- */
function exportLayout() {
  const data = { shopName: shopNameInput.value || 'Mein_Supermarkt', gridSize, elements, exportDate: new Date().toISOString() };
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `${(shopNameInput.value || 'shop').replace(/\s/g,'_')}_layout.json`;
  a.click();
  URL.revokeObjectURL(url);
}

function importLayout(e) {
  const file = e.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = (ev) => {
    try {
      const data = JSON.parse(ev.target.result);
      shopNameInput.value = data.shopName || 'Importierter Shop';
      gridSize = data.gridSize || gridSize;
      gridWidthInput.value = gridSize.width;
      gridHeightInput.value = gridSize.height;
      elements = data.elements || [];
      selectedElement = null;
      renderProperties();
      renderCanvas();
    } catch (err) {
      alert('Fehler beim Laden der Datei');
    }
  };
  reader.readAsText(file);
}

/* ----- Utilities ----- */
// find element by id helper (not strictly necessary)
function findElementById(id) {
  return elements.find(e => e.id === id);
}

/* ----- Kickoff ----- */
initUI();
renderCanvas();
