document.addEventListener('DOMContentLoaded', function() {
    // Get or create the main container
    const contentWrapper = document.querySelector('.content-wrapper');
    const container = document.getElementById('supermarket-container');
    
    // Create product details panel and add it to the content wrapper
    createProductDetailsPanel(contentWrapper);
    
    // Create supermarket layout
    createSupermarketLayout(container);
    
    // Load products and place them on shelves
    loadProducts();
});

function createSupermarketContainer() {
    const container = document.createElement('div');
    container.id = 'supermarket-container';
    document.body.appendChild(container);
    return container;
}

function createSupermarketLayout(container) {
    // Create shelves according to layout in image
    // Shelves are grouped with gray spacers between them
    const shelveGroups = [
        [1, 2],     // Regal 1 and 2
        [3, 4],     // Regal 3 and 4
        [5, 6],     // Unnamed shelves in group 3
        [7, 8],     // Unnamed shelves in group 4
        [9, 10],    // Unnamed shelves in group 5
    ];
    
    const supermarket = document.createElement('div');
    supermarket.className = 'supermarket';
    
    shelveGroups.forEach((group, groupIndex) => {
        const shelfGroup = document.createElement('div');
        shelfGroup.className = 'shelf-group';
        
        group.forEach(shelfNum => {
            const shelf = document.createElement('div');
            shelf.className = 'shelf';
            shelf.id = `shelf-${shelfNum}`;
            
            // Add shelf label for the first 4 shelves as shown in image
            if (shelfNum <= 4) {
                const label = document.createElement('div');
                label.className = 'shelf-label';
                label.textContent = `Regal ${shelfNum}`;
                shelf.appendChild(label);
            }
            
            // Create grid cells for each shelf (9 columns as shown in image)
            for (let i = 0; i < 9; i++) {
                const cell = document.createElement('div');
                cell.className = 'shelf-cell';
                cell.dataset.column = i;
                
                // Each cell gets a position identifier (left, middle, right)
                if (i < 3) cell.dataset.position = 'A'; // Left
                else if (i < 6) cell.dataset.position = 'B'; // Middle
                else cell.dataset.position = 'C'; // Right
                
                shelf.appendChild(cell);
            }
            
            shelfGroup.appendChild(shelf);
        });
        
        // Add a spacer after each group except the last
        if (groupIndex < shelveGroups.length - 1) {
            const spacer = document.createElement('div');
            spacer.className = 'shelf-spacer';
            supermarket.appendChild(shelfGroup);
            supermarket.appendChild(spacer);
        } else {
            supermarket.appendChild(shelfGroup);
        }
    });
    
    container.appendChild(supermarket);
}

function createProductDetailsPanel(parentElement) {
    const detailsPanel = document.createElement('div');
    detailsPanel.id = 'product-details-panel';
    detailsPanel.innerHTML = `
        <h2>Produktdetails</h2>
        <div id="product-details-content">
            <p>Wählen Sie ein Produkt aus, um Details anzuzeigen.</p>
        </div>
    `;
    // Append to the parent element (content-wrapper) instead of body
    parentElement.appendChild(detailsPanel);
}

function loadProducts() {
    // Fix the path to point to the correct location of items.json
    fetch('assets/data/items.json')
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! Status: ${response.status}`);
            }
            return response.json();
        })
        .then(products => {
            console.log('Products loaded:', products); // Debug: log products
            if (products && products.length > 0) {
                products.forEach(product => placeProductOnShelf(product));
            } else {
                console.error('No products found in the JSON file');
            }
        })
        .catch(error => {
            console.error('Error loading products:', error);
            // Display error message on page for user feedback
            const container = document.getElementById('supermarket-container');
            const errorMsg = document.createElement('div');
            errorMsg.className = 'error-message';
            errorMsg.textContent = `Fehler beim Laden der Produkte: ${error.message}`;
            container.appendChild(errorMsg);
            
            // Add a help message with possible solutions
            const helpMsg = document.createElement('div');
            helpMsg.className = 'help-message';
            helpMsg.innerHTML = `
                <p>Mögliche Lösungen:</p>
                <ul>
                    <li>Überprüfen Sie, ob die Datei unter <code>app/assets/data/items.json</code> existiert</li>
                    <li>Stellen Sie sicher, dass die JSON-Datei gültig ist</li>
                    <li>Versuchen Sie, die Seite über einen Webserver statt als lokale Datei zu öffnen</li>
                </ul>
            `;
            container.appendChild(helpMsg);
        });
}

function placeProductOnShelf(product) {
    // Parse the nodeId to get shelf number and position
    const nodeId = product.location.nodeId;
    const match = nodeId.match(/N-(\d+)-([A-Z])/);
    
    if (!match) {
        console.error(`Invalid nodeId format for product: ${product.name}`);
        return;
    }
    
    const shelfNum = parseInt(match[1]);
    const position = match[2]; // A = Left, B = Middle, C = Right
    
    // Find the shelf
    const shelf = document.getElementById(`shelf-${shelfNum}`);
    if (!shelf) {
        console.error(`Shelf #${shelfNum} not found for product: ${product.name}`);
        return;
    }
    
    // Find cells with matching position
    const cells = shelf.querySelectorAll(`.shelf-cell[data-position="${position}"]`);
    
    if (cells.length === 0) {
        console.error(`No cells with position ${position} found in shelf #${shelfNum} for product: ${product.name}`);
        return;
    }
    
    // Place product in an available cell
    let placed = false;
    cells.forEach(cell => {
        if (!placed && !cell.querySelector('.product-marker')) {
            const productMarker = document.createElement('div');
            productMarker.className = 'product-marker';
            productMarker.dataset.productId = product.id;
            productMarker.title = `${product.name} - €${product.price}`;
            
            // Add product name as text inside marker
            const productName = document.createElement('span');
            productName.className = 'product-name';
            productName.textContent = product.name.substring(0, 3); // First 3 chars of name
            productMarker.appendChild(productName);
            
            // Add click event to show product details
            productMarker.addEventListener('click', () => showProductDetails(product));
            
            cell.appendChild(productMarker);
            placed = true;
        }
    });
    
    if (!placed) {
        console.warn(`No available cell to place product: ${product.name} in shelf #${shelfNum}, position ${position}`);
    }
}

function showProductDetails(product) {
    // Update product details in the right panel instead of creating a popup
    const detailsContent = document.getElementById('product-details-content');
    
    if (detailsContent) {
        detailsContent.innerHTML = `
            <h3>${product.name}</h3>
            <p class="product-price">€${product.price.toFixed(2)}</p>
            <p><strong>Kategorie:</strong> ${product.category}</p>
            <div class="location-details">
                <p><strong>Standort:</strong></p>
                <p>Gang ${product.location.aisle}</p>
                <p>${product.location.description}</p>
            </div>
        `;
        
        // Highlight the selected product
        const allMarkers = document.querySelectorAll('.product-marker');
        allMarkers.forEach(marker => {
            marker.classList.remove('selected');
        });
        
        const selectedMarker = document.querySelector(`.product-marker[data-product-id="${product.id}"]`);
        if (selectedMarker) {
            selectedMarker.classList.add('selected');
        }
    }
}
