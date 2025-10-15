let items = [];

// Supermarkt Grid erstellen (wie im Bild)
function createSupermarketLayout() {
    const supermarket = document.getElementById('supermarket');
    
    // 17 Reihen, 9 Spalten (wie im Bild: 2 Regal + 1 Gang = 3, mal 4 Regale = 12, plus extra)
    for (let row = 1; row <= 17; row++) {
        for (let col = 1; col <= 9; col++) {
            const cell = document.createElement('div');
            cell.dataset.row = row;
            cell.dataset.col = col;
            
            // Gänge sind bei jeder 3. Reihe (3, 6, 9, 12, 15)
            const isAisle = row === 3 || row === 6 || row === 9 || row === 12 || row === 15;
            
            if (isAisle) {
                cell.classList.add('aisle');
            } else {
                cell.classList.add('shelf');
                
                // Bestimme Position basierend auf Reihe
                let position;
                if (row === 1) {
                    position = 'A'; // Regal 1, Seite 1
                } else if (row === 2) {
                    position = 'A'; // Regal 1, Seite 2
                } else if (row === 4) {
                    position = 'B'; // Regal 2, Seite 1
                } else if (row === 5) {
                    position = 'B'; // Regal 2, Seite 2
                } else if (row === 7) {
                    position = 'C'; // Regal 3, Seite 1
                } else if (row === 8) {
                    position = 'C'; // Regal 3, Seite 2
                } else if (row === 10) {
                    position = 'A'; // Regal 4, Seite 1
                } else if (row === 11) {
                    position = 'A'; // Regal 4, Seite 2
                } else if (row === 13) {
                    position = 'B'; // Regal 5, Seite 1
                } else if (row === 14) {
                    position = 'B'; // Regal 5, Seite 2
                } else if (row === 16) {
                    position = 'C'; // Regal 6, Seite 1
                } else if (row === 17) {
                    position = 'C'; // Regal 6, Seite 2
                }
                
                const aisleNumber = col;
                cell.dataset.nodeId = `N-${String(aisleNumber).padStart(2, '0')}-${position}`;
            }
            
            supermarket.appendChild(cell);
        }
    }
}

// Produkte als Marker hinzufügen
function displayProducts() {
    items.forEach(item => {
        // Finde nur EINE Zelle mit dieser NodeId
        const cell = document.querySelector(`[data-node-id="${item.location.nodeId}"]`);
        
        if (cell && !cell.querySelector('.product-marker')) {
            const marker = document.createElement('div');
            marker.classList.add('product-marker');
            marker.dataset.productId = item.id;
            marker.addEventListener('click', (e) => {
                e.stopPropagation();
                showProductDetails(item.id);
            });
            cell.appendChild(marker);
        }
    });
}

// Produktdetails anzeigen
function showProductDetails(productId) {
    const product = items.find(item => item.id === productId);
    if (!product) return;
    
    const detailsPanel = document.getElementById('productDetails');
    detailsPanel.innerHTML = `
        <div class="product-info">
            <h3>${product.name}</h3>
            <p><strong>Kategorie:</strong> ${product.category}</p>
            <div class="price">€${product.price.toFixed(2)}</div>
            <div class="location">
                <p><strong>📍 Standort:</strong></p>
                <p>Gang ${product.location.aisle}</p>
                <p>Position: ${product.location.nodeId}</p>
                <p>${product.location.description}</p>
            </div>
        </div>
    `;
}

// Produkte laden
async function loadItems() {
    try {
        const response = await fetch('assets/data/items.json');
        items = await response.json();
        console.log('Produkte geladen:', items);
        displayProducts();
    } catch (error) {
        console.error('Fehler beim Laden der Produkte:', error);
    }
}

// Initialisierung
document.addEventListener('DOMContentLoaded', async () => {
    createSupermarketLayout();
    await loadItems();
});
