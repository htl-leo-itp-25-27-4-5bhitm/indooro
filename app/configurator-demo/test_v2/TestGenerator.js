/* ----- Data (aus React übernommen) ----- */
let PRODUCT_CATEGORIES = []; // Will be loaded from JSON

const ELEMENT_TYPES = [
  { id: 'shelf', name: 'Regal', icon: '▭' },
  { id: 'counter', name: 'Theke', icon: '▬' },
  { id: 'cooler', name: 'Kühlregal', icon: '❄' },
  { id: 'freezer', name: 'Tiefkühlregal', icon: '🧊' },
  { id: 'entrance', name: 'Eingang', icon: '🚪' },
  { id: 'checkout', name: 'Kasse', icon: '💳' },
];

const TEMPLATES = [
  { id: 'small', name: 'Kleiner Laden (15x20m)', width: 15, height: 20 },
  { id: 'medium', name: 'Mittlerer Laden (40x60m)', width: 40, height: 60 },
  { id: 'large', name: 'Großer Laden (60x80m)', width: 60, height: 80 },
];

/* ----- State (Vanilla) ----- */
let elements = [];
let selectedElement = null;
let isDrawing = false;
let drawStart = null;
let isDragging = false;
let dragOffset = { x: 0, y: 0 };

let currentTool = 'select';
let currentCategory = null; // No default category
let currentElementType = ELEMENT_TYPES[0];
let gridSize = { width: 40, height: 60 };
let showGrid = true;
let zoom = 1;
let shopName = 'Mein Supermarkt';

const cellSize = 20; // pixels per meter cell

/* ----- Undo/Redo System ----- */
let history = [];
let historyIndex = -1;
const MAX_HISTORY = 50;

function saveState() {
  // Remove any future states if we're not at the end
  history = history.slice(0, historyIndex + 1);
  
  // Deep clone current state
  const state = JSON.parse(JSON.stringify(elements));
  history.push(state);
  
  // Limit history size
  if (history.length > MAX_HISTORY) {
    history.shift();
  } else {
    historyIndex++;
  }
}

function undo() {
  if (historyIndex > 0) {
    historyIndex--;
    elements = JSON.parse(JSON.stringify(history[historyIndex]));
    selectedElement = null;
    renderCanvas();
    renderProperties();
  }
}

function redo() {
  if (historyIndex < history.length - 1) {
    historyIndex++;
    elements = JSON.parse(JSON.stringify(history[historyIndex]));
    selectedElement = null;
    renderCanvas();
    renderProperties();
  }
}

/* ----- Collision Detection Helper ----- */
function checkCollision(el1, el2) {
  // Check if two elements overlap
  return !(
    el1.x + el1.width <= el2.x ||
    el2.x + el2.width <= el1.x ||
    el1.y + el1.height <= el2.y ||
    el2.y + el2.height <= el1.y
  );
}

function hasCollisions(element) {
  return elements.some(other => 
    other.id !== element.id && checkCollision(element, other)
  );
}

/* ----- DOM references ----- */
const toolSelectBtn = document.getElementById('toolSelect');
const toolDrawBtn = document.getElementById('toolDraw');
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

/* ----- Load Categories from JSON ----- */
async function loadCategories() {
  try {
    const response = await fetch('../../assets/data/categories.json');
    const data = await response.json();
    
    // Transform JSON structure to match expected format
    PRODUCT_CATEGORIES = data.map(cat => ({
      id: cat.categoryCode.toString(),
      name: cat.categoryName,
      color: getCategoryColor(cat.categoryCode),
      icon: getCategoryIcon(cat.categoryCode)
    }));
  } catch (error) {
    console.error('Failed to load categories:', error);
    // Fallback to minimal categories
    PRODUCT_CATEGORIES = [
      { id: '310', name: 'Obst & Gemüse', color: '#4CAF50', icon: '🥬' },
      { id: '520', name: 'Molkereiprodukte', color: '#BBDEFB', icon: '🥛' },
    ];
  }
}

// Helper functions for category mapping
function getCategoryColor(code) {
  const colorMap = {
    310: '#4CAF50', // Obst & Gemüse
    420: '#FF9800', // Konserven
    430: '#FFC107', // Teigwaren
    440: '#FFE082', // Müsli
    445: '#FFEB3B', // Backmittel
    450: '#FFF59D', // Öle
    470: '#E91E63', // Snacks
    510: '#2196F3', // Getränke
    520: '#BBDEFB', // Molkerei
    525: '#FFE082', // Käse
    530: '#B3E5FC', // Tiefkühl
    610: '#795548', // Haushalt
    640: '#00BCD4', // Körperpflege
  };
  return colorMap[code] || '#E5E7EB';
}

function getCategoryIcon(code) {
  const iconMap = {
    310: '🥬', 420: '🥫', 430: '🍝', 440: '🥣', 445: '🧁',
    450: '🫒', 470: '🍿', 510: '🥤', 520: '🥛', 525: '🧀',
    530: '❄️', 610: '🧹', 640: '🧴',
  };
  return iconMap[code] || '📦';
}

/* ----- Init UI ----- */
async function initUI() {
  // Load categories first
  await loadCategories();

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

  // Keyboard shortcuts for undo/redo
  window.addEventListener('keydown', (e) => {
    // Undo: Ctrl+Z or Cmd+Z
    if ((e.ctrlKey || e.metaKey) && e.key === 'z' && !e.shiftKey) {
      e.preventDefault();
      undo();
    }
    // Redo: Ctrl+Y or Ctrl+Shift+Z or Cmd+Shift+Z
    else if ((e.ctrlKey || e.metaKey) && (e.key === 'y' || (e.shiftKey && e.key === 'z'))) {
      e.preventDefault();
      redo();
    }
  });

  // Arrow key navigation for selected element
  window.addEventListener('keydown', (e) => {
    // Check if user is typing in an input or textarea
    const activeElement = document.activeElement;
    const isTyping = activeElement && (
      activeElement.tagName === 'INPUT' || 
      activeElement.tagName === 'TEXTAREA' ||
      activeElement.isContentEditable
    );
    
    // Only process arrow keys if not typing and an element is selected
    if (!isTyping && selectedElement && ['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.key)) {
      e.preventDefault();
      saveState(); // Save state before movement
      
      const el = selectedElement;
      
      switch(e.key) {
        case 'ArrowUp':
          el.y = Math.max(0, el.y - 1);
          break;
        case 'ArrowDown':
          el.y = Math.min(gridSize.height - el.height, el.y + 1);
          break;
        case 'ArrowLeft':
          el.x = Math.max(0, el.x - 1);
          break;
        case 'ArrowRight':
          el.x = Math.min(gridSize.width - el.width, el.x + 1);
          break;
      }
      
      // Update element in array
      elements = elements.map(it => it.id === el.id ? el : it);
      renderCanvas();
      renderProperties();
    }
  });

  // initial render
  setTool('select');
  saveState(); // Initial state
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
    const cat = el.category ? PRODUCT_CATEGORIES.find(c => c.id === el.category) : null;
    const elementType = ELEMENT_TYPES.find(t => t.id === el.type) || ELEMENT_TYPES[0];
    
    // Check for collisions
    const hasCollision = hasCollisions(el);
    
    const div = document.createElement('div');
    div.className = 'absolute border-2 element-box flex items-center justify-center text-center text-xs font-medium overflow-hidden';
    if (selectedElement && selectedElement.id === el.id) div.classList.add('selected');
    
    // Apply collision styling
    if (hasCollision) {
      div.classList.add('border-red-600');
      div.style.borderWidth = '3px';
    }
    
    div.style.left = (el.x * cellSize * zoom) + 'px';
    div.style.top = (el.y * cellSize * zoom) + 'px';
    div.style.width = (el.width * cellSize * zoom) + 'px';
    div.style.height = (el.height * cellSize * zoom) + 'px';
    
    // Background color with collision warning
    if (hasCollision) {
      div.style.backgroundColor = '#fca5a5'; // light red tint
    } else {
      div.style.backgroundColor = el.color || '#E5E7EB';
    }
    
    div.style.opacity = '0.95';
    div.dataset.id = el.id;
    
    // Add tooltip with full information
    const tooltipText = `${elementType.name}${cat ? ' - ' + cat.name : ' - Leer'}${hasCollision ? ' ⚠️ ÜBERLAPPUNG!' : ''}`;
    div.title = tooltipText;

    const inner = document.createElement('div');
    inner.className = 'p-1 flex flex-col items-center justify-center';
    const icon = cat ? cat.icon : '📦';
    
    // Refined smart rendering: hide text if element is narrow in ANY dimension
    const isNarrow = el.width < 2 || el.height < 2;
    
    if (isNarrow) {
      // Only show icon for narrow elements (thin strips)
      inner.innerHTML = `<div class="text-lg">${icon}</div>`;
    } else {
      // Show full details for larger elements
      inner.innerHTML = `
        <div class="font-bold text-[11px] mb-0.5 px-1.5 py-0.5 bg-white bg-opacity-70 rounded">${elementType.name}</div>
        <div class="text-lg">${icon}</div>
        <div class="text-[10px] leading-tight">${el.label}</div>
      `;
    }
    div.appendChild(inner);

    // click to select
    div.addEventListener('mousedown', (ev) => {
      ev.stopPropagation();
      // Save state before dragging starts
      saveState();
      
      // compute cell coords with snapping
      const rect = canvasContainer.getBoundingClientRect();
      const x = Math.round((ev.clientX - rect.left) / (cellSize * zoom));
      const y = Math.round((ev.clientY - rect.top) / (cellSize * zoom));
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

/* track mouse cell for preview with snapping */
let currentMouseCell = { x: 0, y: 0 };

/* ----- Mouse events on canvasContainer ----- */
canvasContainer.addEventListener('mousedown', (e) => {
  const rect = canvasContainer.getBoundingClientRect();
  const x = Math.round((e.clientX - rect.left) / (cellSize * zoom));
  const y = Math.round((e.clientY - rect.top) / (cellSize * zoom));
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
    // Save state before drawing
    saveState();
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

  const x = Math.round((e.clientX - rect.left) / (cellSize * zoom));
  const y = Math.round((e.clientY - rect.top) / (cellSize * zoom));
  currentMouseCell = { x, y };

  if (isDragging && selectedElement) {
    // move selected element with snapping
    selectedElement.x = Math.round(x - dragOffset.x);
    selectedElement.y = Math.round(y - dragOffset.y);
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
  const x = Math.round((e.clientX - rect.left) / (cellSize * zoom));
  const y = Math.round((e.clientY - rect.top) / (cellSize * zoom));

  if (isDrawing && drawStart) {
    const nx = Math.max(0, Math.min(gridSize.width-1, x));
    const ny = Math.max(0, Math.min(gridSize.height-1, y));

    const newElement = {
      id: Date.now() + Math.floor(Math.random()*1000),
      type: currentElementType.id,
      category: null, // No category assigned yet
      x: Math.min(drawStart.x, nx),
      y: Math.min(drawStart.y, ny),
      width: Math.abs(nx - drawStart.x) + 1,
      height: Math.abs(ny - drawStart.y) + 1,
      label: 'Leer',
      color: '#E5E7EB', // Neutral gray
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
    // Check if user is typing in an input or textarea
    const activeElement = document.activeElement;
    const isTyping = activeElement && (
      activeElement.tagName === 'INPUT' || 
      activeElement.tagName === 'TEXTAREA' ||
      activeElement.isContentEditable
    );
    
    // Only delete element if not typing in a text field
    if (!isTyping && selectedElement) {
      e.preventDefault(); // Prevent browser back navigation
      saveState(); // Save state before deletion
      elements = elements.filter(el => el.id !== selectedElement.id);
      selectedElement = null;
      renderProperties();
      renderCanvas();
    }
  }
});

/* ----- Properties panel ----- */
function renderProperties() {
  if (!selectedElement) {
    propertiesWrapper.innerHTML = '<p class="text-sm text-gray-500">Wähle ein Element aus, um seine Eigenschaften zu bearbeiten.</p>';
    return;
  }

  const el = selectedElement;
  const cat = el.category ? PRODUCT_CATEGORIES.find(c => c.id === el.category) : null;

  const container = document.createElement('div');
  container.className = 'space-y-4';

  const header = document.createElement('div');
  header.className = 'flex items-center justify-between pb-3 border-b';
  header.innerHTML = `<h4 class="font-medium">Element bearbeiten</h4>`;
  
  // Action buttons (delete and duplicate)
  const actionsDiv = document.createElement('div');
  actionsDiv.className = 'flex gap-1';
  
  const duplicateBtn = document.createElement('button');
  duplicateBtn.className = 'p-2 text-blue-500 hover:bg-blue-50 rounded';
  duplicateBtn.title = 'Duplizieren';
  duplicateBtn.innerHTML = '<svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor"><rect x="9" y="9" width="13" height="13" rx="2" ry="2" stroke-width="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" stroke-width="2"/></svg>';
  duplicateBtn.onclick = () => {
    saveState(); // Save state before duplication
    
    // Deep clone the element
    const duplicate = JSON.parse(JSON.stringify(el));
    
    // Assign new unique ID
    duplicate.id = Date.now() + Math.floor(Math.random() * 1000);
    
    // Smart placement logic
    let newX, newY;
    
    // Try 1: Place to the right
    newX = el.x + el.width;
    newY = el.y;
    
    if (newX + duplicate.width > gridSize.width) {
      // Try 2: Place below
      newX = el.x;
      newY = el.y + el.height;
      
      if (newY + duplicate.height > gridSize.height) {
        // Fallback: Original offset logic with bounds checking
        newX = Math.min(el.x + 1, gridSize.width - duplicate.width);
        newY = Math.min(el.y + 1, gridSize.height - duplicate.height);
        
        // Ensure non-negative
        newX = Math.max(0, newX);
        newY = Math.max(0, newY);
      }
    }
    
    duplicate.x = newX;
    duplicate.y = newY;
    
    // Add to elements and select
    elements.push(duplicate);
    selectedElement = duplicate;
    
    renderCanvas();
    renderProperties();
  };
  
  const delBtn = document.createElement('button');
  delBtn.className = 'p-2 text-red-500 hover:bg-red-50 rounded';
  delBtn.title = 'Löschen';
  delBtn.innerHTML = '<svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/></svg>';
  delBtn.onclick = () => {
    saveState(); // Save state before deletion
    elements = elements.filter(it => it.id !== el.id);
    selectedElement = null;
    renderProperties();
    renderCanvas();
  };
  
  actionsDiv.appendChild(duplicateBtn);
  actionsDiv.appendChild(delBtn);
  header.appendChild(actionsDiv);
  container.appendChild(header);

  // label
  const labelDiv = document.createElement('div');
  labelDiv.innerHTML = `
    <div>
      <label class="block text-sm font-medium mb-1">Bezeichnung</label>
      <input id="propLabel" type="text" value="${escapeHtml(el.label)}" class="w-full px-2 py-1 border border-gray-300 rounded" />
    </div>
  `;
  container.appendChild(labelDiv);

  // Category selection
  const categorySection = document.createElement('div');
  categorySection.innerHTML = `
    <label class="block text-sm font-medium mb-2">Produktkategorie</label>
    <div id="categoriesList" class="space-y-1 max-h-64 overflow-y-auto border rounded p-2">
      <!-- filled below -->
    </div>
  `;
  container.appendChild(categorySection);

  const categoriesList = categorySection.querySelector('#categoriesList');
  PRODUCT_CATEGORIES.forEach(c => {
    const btn = document.createElement('button');
    btn.className = `w-full px-2 py-1.5 rounded text-left text-xs flex items-center gap-2 ${el.category === c.id ? 'ring-2 ring-blue-500' : 'hover:bg-gray-50'}`;
    btn.style.backgroundColor = el.category === c.id ? c.color : 'transparent';
    btn.innerHTML = `<span>${c.icon}</span><span class="flex-1">${c.name}</span>`;
    btn.onclick = () => {
      saveState(); // Save state before category change
      el.category = c.id;
      el.color = c.color;
      el.label = c.name;
      elements = elements.map(it => it.id === el.id ? el : it);
      renderCanvas();
      renderProperties();
    };
    categoriesList.appendChild(btn);
  });

  // dimensions with rotate button
  const dimDiv = document.createElement('div');
  dimDiv.innerHTML = `
    <div class="space-y-2">
      <div class="grid grid-cols-2 gap-2">
        <div>
          <label class="block text-sm font-medium mb-1">Breite</label>
          <input id="propW" type="number" value="${el.width}" min="1" class="w-full px-2 py-1 border border-gray-300 rounded" />
        </div>
        <div>
          <label class="block text-sm font-medium mb-1">Höhe</label>
          <input id="propH" type="number" value="${el.height}" min="1" class="w-full px-2 py-1 border border-gray-300 rounded" />
        </div>
      </div>
      <button id="rotateBtn" class="w-full px-3 py-2 bg-gray-100 hover:bg-gray-200 rounded text-sm flex items-center justify-center gap-2">
        <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
        Drehen (90°)
      </button>
    </div>
  `;
  container.appendChild(dimDiv);

  propertiesWrapper.innerHTML = '';
  propertiesWrapper.appendChild(container);

  // listeners
  let labelTimeout;
  document.getElementById('propLabel').addEventListener('input', (ev) => {
    // Debounce state saving for input events
    clearTimeout(labelTimeout);
    el.label = ev.target.value;
    elements = elements.map(it => it.id === el.id ? el : it);
    renderCanvas();
    
    labelTimeout = setTimeout(() => {
      saveState();
    }, 500);
  });

  document.getElementById('propW').addEventListener('change', (ev) => {
    saveState(); // Save state before dimension change
    el.width = Math.max(1, Math.round(parseFloat(ev.target.value)) || 1);
    el.width = Math.min(el.width, gridSize.width - el.x);
    elements = elements.map(it => it.id === el.id ? el : it);
    renderCanvas();
    renderProperties();
  });

  document.getElementById('propH').addEventListener('change', (ev) => {
    saveState(); // Save state before dimension change
    el.height = Math.max(1, Math.round(parseFloat(ev.target.value)) || 1);
    el.height = Math.min(el.height, gridSize.height - el.y);
    elements = elements.map(it => it.id === el.id ? el : it);
    renderCanvas();
    renderProperties();
  });

  // Rotate button handler
  document.getElementById('rotateBtn').addEventListener('click', () => {
    saveState(); // Save state before rotation
    
    // Swap width and height
    const newWidth = el.height;
    const newHeight = el.width;
    
    // Check if rotation would push element out of bounds
    let newX = el.x;
    let newY = el.y;
    
    // Adjust position if needed to keep element within grid
    if (newX + newWidth > gridSize.width) {
      newX = gridSize.width - newWidth;
    }
    if (newY + newHeight > gridSize.height) {
      newY = gridSize.height - newHeight;
    }
    
    // Ensure position is not negative
    newX = Math.max(0, newX);
    newY = Math.max(0, newY);
    
    // Apply rotation
    el.width = newWidth;
    el.height = newHeight;
    el.x = newX;
    el.y = newY;
    
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
  saveState(); // Save state before applying template
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
