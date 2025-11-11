# Indooro API Dokumentation

## Übersicht

Die Indooro API ist eine RESTful-Schnittstelle zur Verwaltung und Suche von Supermarkt-Produkten mit OpenSearch-Integration. Der Server läuft auf Port **8080**.

OpenSearch ist eine Suchmaschine, die es ermöglicht, große Mengen an Daten schnell zu durchsuchen. Die API dient als Schnittstelle zwischen dem Frontend (Webseite) und OpenSearch.

---

## Inhaltsverzeichnis

1. [Setup & Installation](#setup--installation)
2. [Admin-Endpunkte](#admin-endpunkte)
3. [Produkt-Endpunkte](#produkt-endpunkte)
4. [Datenmodell](#datenmodell)
5. [Fehlerbehandlung](#fehlerbehandlung)

---

## Setup & Installation

### 1. Docker starten

OpenSearch läuft in einem Docker-Container. Docker ist eine Virtualisierungssoftware, die es ermöglicht, Anwendungen isoliert laufen zu lassen.

```bash
# Docker-Container starten (falls docker-compose verwendet wird)
docker-compose up -d

# Alternativ: OpenSearch-Container direkt starten
docker run -d -p 9200:9200 -p 9600:9600 \
  -e "discovery.type=single-node" \
  -e "OPENSEARCH_INITIAL_ADMIN_PASSWORD=Admin123!" \
  opensearchproject/opensearch:latest
```

**Was passiert hier?**
- `-d`: Container läuft im Hintergrund
- `-p 9200:9200`: OpenSearch API ist auf Port 9200 erreichbar
- `-e "discovery.type=single-node"`: OpenSearch läuft als einzelner Knoten (für Entwicklung)
- `OPENSEARCH_INITIAL_ADMIN_PASSWORD`: Setzt das Admin-Passwort

### 2. Server starten

Der Quarkus-Server verbindet sich mit OpenSearch und stellt die API bereit.

```bash
# Im backend/indooro_server Verzeichnis
./mvnw quarkus:dev
```

Der Server läuft jetzt auf `http://localhost:8080`

**Was macht der Server?**
- Nimmt HTTP-Anfragen entgegen (GET, POST, DELETE)
- Kommuniziert mit OpenSearch
- Gibt Antworten im JSON-Format zurück

### 3. Index erstellen

Ein Index in OpenSearch ist wie eine Datenbank-Tabelle - er definiert die Struktur und speichert die Daten.

```bash
curl -X POST http://localhost:8080/api/admin/index/create
```

**Was passiert?**
- Ein neuer Index namens "products" wird in OpenSearch erstellt
- Definiert Felder: id, name, price, layoutCode
- Konfiguriert Sucheinstellungen (z.B. Volltext-Suche für Namen)

**Antwort:**
```json
{
  "message": "Index created successfully"
}
```

**Wichtig:** Der Index muss nur einmal erstellt werden. Bei erneutem Aufruf gibt es einen Fehler.

### 4. Daten importieren

Nachdem der Index erstellt wurde, können Produkte hinzugefügt werden.

```bash
# Bulk-Import aller Produkte aus belegplan.json
curl -X POST http://localhost:8080/api/products/bulk \
  -H "Content-Type: application/json" \
  -d @belegplan.json
```

**Was passiert?**
- Alle 153 Produkte aus der JSON-Datei werden gelesen
- Jedes Produkt wird in OpenSearch indexiert (= hinzugefügt)
- OpenSearch analysiert die Produktnamen für die Volltextsuche

**Antwort:**
```json
{
  "message": "Successfully indexed 153 products"
}
```

---

## Admin-Endpunkte

Base URL: `/api/admin`

Diese Endpunkte dienen der Verwaltung und sind normalerweise nur für Administratoren gedacht.

### 1. Index erstellen

**Zweck:** Erstellt die Datenstruktur in OpenSearch für Produkte.

**Endpunkt:** `POST /api/admin/index/create`

**Wann verwenden?**
- Beim ersten Setup
- Nach dem Löschen des Index
- Wenn die Datenstruktur geändert wurde

**Beispiel:**
```bash
curl -X POST http://localhost:8080/api/admin/index/create
```

**Erfolgsantwort (200):**
```json
{
  "message": "Index created successfully"
}
```

**Fehlerfall:**
```json
{
  "error": "Index already exists"
}
```

**Was macht der Code intern?**
```java
// Erstellt einen Index mit Mapping (Feldtypen)
{
  "mappings": {
    "properties": {
      "id": { "type": "integer" },
      "name": { "type": "text" },  // Volltext-Suche möglich
      "price": { "type": "double" },
      "layoutCode": { "type": "keyword" }  // Exakte Suche
    }
  }
}
```

---

### 2. Index löschen

**Zweck:** Löscht den kompletten Index inkl. aller gespeicherten Produkte.

**Endpunkt:** `DELETE /api/admin/index`

**Wann verwenden?**
- Zum Zurücksetzen aller Daten
- Bei Problemen mit der Datenstruktur
- Vor einem kompletten Neuimport

**⚠️ ACHTUNG:** Alle Produktdaten werden unwiderruflich gelöscht!

**Beispiel:**
```bash
curl -X DELETE http://localhost:8080/api/admin/index
```

**Erfolgsantwort (200):**
```json
{
  "message": "Index deleted successfully"
}
```

**Typischer Workflow nach dem Löschen:**
```bash
# 1. Index löschen
curl -X DELETE http://localhost:8080/api/admin/index

# 2. Index neu erstellen
curl -X POST http://localhost:8080/api/admin/index/create

# 3. Daten neu importieren
curl -X POST http://localhost:8080/api/products/bulk \
  -H "Content-Type: application/json" \
  -d @belegplan.json
```

---

### 3. Health Check

**Zweck:** Überprüft, ob der Server läuft und erreichbar ist.

**Endpunkt:** `GET /api/admin/health`

**Wann verwenden?**
- Monitoring / Überwachung
- Testen der Verbindung
- Automatische Health-Checks

**Beispiel:**
```bash
curl http://localhost:8080/api/admin/health
```

**Erfolgsantwort (200):**
```json
{
  "status": "UP"
}
```

**Verwendung in Skripten:**
```bash
# Warte bis Server bereit ist
while ! curl -s http://localhost:8080/api/admin/health > /dev/null; do
  echo "Warte auf Server..."
  sleep 1
done
echo "Server ist bereit!"
```

---

## Produkt-Endpunkte

Base URL: `/api/products`

Diese Endpunkte werden vom Frontend (Webseite) verwendet, um Produktdaten abzurufen.

### 1. Alle Produkte abrufen

**Zweck:** Holt alle oder eine bestimmte Anzahl von Produkten aus der Datenbank.

**Endpunkt:** `GET /api/products`

**Query Parameter:**
- `size` (optional, default: 100) - Maximale Anzahl der Ergebnisse

**Wann verwenden?**
- Beim Laden der Supermarkt-Visualisierung
- Zum Anzeigen aller verfügbaren Produkte
- Export von Produktlisten

**Beispiele:**

```bash
# Alle Produkte (max 100)
curl http://localhost:8080/api/products

# Erste 200 Produkte (für größere Supermärkte)
curl http://localhost:8080/api/products?size=200

# Nur 10 Produkte (für Tests)
curl http://localhost:8080/api/products?size=10
```

**Erfolgsantwort (200):**
```json
[
  {
    "id": 1,
    "name": "Gala Äpfel lose",
    "price": 2.99,
    "layoutCode": "310/1/1/1"
  },
  {
    "id": 2,
    "name": "Bananen lose",
    "price": 1.99,
    "layoutCode": "310/1/1/2"
  }
]
```

**Was macht der Code intern?**
```java
// OpenSearch Query
{
  "size": 200,  // Anzahl der Ergebnisse
  "query": {
    "match_all": {}  // Hole alle Dokumente
  }
}
```

**Frontend-Verwendung:**
```javascript
// Alle Produkte laden
const response = await fetch('http://localhost:8080/api/products?size=200');
const products = await response.json();

// Produkte suchen
const searchResponse = await fetch(
  `http://localhost:8080/api/products/search?q=${query}&size=50`
);
const results = await searchResponse.json();
```

---

### 2. Produkt nach ID abrufen

**Zweck:** Holt ein einzelnes, spezifisches Produkt anhand seiner eindeutigen ID.

**Endpunkt:** `GET /api/products/{id}`

**Path Parameter:**
- `id` (erforderlich) - Eindeutige Produkt-ID (Integer)

**Wann verwenden?**
- Detailansicht eines Produkts
- Prüfen, ob ein Produkt existiert
- Aktualisieren einzelner Produktdaten

**Beispiel:**
```bash
# Produkt mit ID 1 abrufen
curl http://localhost:8080/api/products/1

# Produkt mit ID 42 abrufen
curl http://localhost:8080/api/products/42
```

**Erfolgsantwort (200):**
```json
{
  "id": 1,
  "name": "Gala Äpfel lose",
  "price": 2.99,
  "layoutCode": "310/1/1/1"
}
```

**Fehlerantwort (404) - Produkt nicht gefunden:**
```json
{
  "error": "Product not found"
}
```

**Was macht der Code intern?**
```java
// OpenSearch Get-Request mit ID
GET /products/_doc/1  // Hole Dokument mit ID 1
```

**Frontend-Verwendung:**
```javascript
// Einzelnes Produkt laden
async function getProduct(id) {
  const response = await fetch(`http://localhost:8080/api/products/${id}`);
  if (response.ok) {
    return await response.json();
  } else {
    console.error('Produkt nicht gefunden');
    return null;
  }
}
```

---

### 3. Produkte suchen

**Zweck:** Volltextsuche über alle Produktnamen. Findet Produkte auch bei Tippfehlern oder Teilwörtern.

**Endpunkt:** `GET /api/products/search`

**Query Parameter:**
- `q` (erforderlich) - Suchbegriff
- `size` (optional, default: 10) - Maximale Anzahl der Ergebnisse

**Wann verwenden?**
- Suchfunktion im Frontend
- Produktempfehlungen
- Autovervollständigung

**Wie funktioniert die Suche?**
- **Volltext:** Sucht in allen Wörtern des Produktnamens
- **Fuzzy:** Toleriert kleine Tippfehler (z.B. "Apfl" findet "Apfel")
- **Relevanz:** Sortiert Ergebnisse nach Übereinstimmung

**Beispiele:**

```bash
# Nach "Apfel" suchen
curl "http://localhost:8080/api/products/search?q=apfel"
# Findet: "Gala Äpfel", "Bio-Äpfel", "Apfelmus", etc.

# Nach "Bio" suchen, max 20 Ergebnisse
curl "http://localhost:8080/api/products/search?q=bio&size=20"
# Findet: "Bio-Äpfel", "Bio-Milch", "Bio-Joghurt", etc.

# Nach "Spaghetti" suchen
curl "http://localhost:8080/api/products/search?q=spaghetti"
# Findet: "Barilla Spaghetti", "S-BUDGET Spaghetti"

# Nach "Budget" suchen (findet alle Budget-Produkte)
curl "http://localhost:8080/api/products/search?q=budget"

# Nach "Milch 1L" suchen (mehrere Wörter)
curl "http://localhost:8080/api/products/search?q=milch+1l"
```

**Erfolgsantwort (200):**
```json
[
  {
    "id": 3,
    "name": "Bio-Äpfel 1kg",
    "price": 2.79,
    "layoutCode": "310/1/2/1"
  },
  {
    "id": 5,
    "name": "Bio-Apfelmus 250g",
    "price": 1.79,
    "layoutCode": "310/1/3/1"
  }
]
```

**Fehlerantwort (400) - Fehlender Suchbegriff:**
```json
{
  "error": "Query parameter 'q' is required"
}
```

**Was macht der Code intern?**
```java
// OpenSearch Match Query mit Fuzzy-Matching
{
  "size": 10,
  "query": {
    "match": {
      "name": {
        "query": "apfel",
        "fuzziness": "AUTO"  // Toleriert Tippfehler
      }
    }
  }
}
```

**Frontend-Verwendung:**
```javascript
// Suchfunktion
async function searchProducts(query) {
  const response = await fetch(
    `http://localhost:8080/api/products/search?q=${encodeURIComponent(query)}&size=50`
  );
  return await response.json();
}

// Verwendung
const results = await searchProducts('apfel');
console.log(`${results.length} Produkte gefunden`);
```

**Suchbeispiele:**
- `"apfel"` → Findet alle Produkte mit "Apfel" im Namen
- `"s-budget"` → Findet alle S-BUDGET Produkte
- `"milch bio"` → Findet Bio-Milchprodukte
- `"1kg"` → Findet alle 1kg-Produkte

---

### 4. Einzelnes Produkt indexieren

**Zweck:** Fügt ein neues Produkt hinzu oder aktualisiert ein bestehendes Produkt.

**Endpunkt:** `POST /api/products`

**Request Body:** JSON-Objekt mit Produktdaten

**Wann verwenden?**
- Neues Produkt zum Sortiment hinzufügen
- Preis eines Produkts aktualisieren
- Standort (layoutCode) eines Produkts ändern

**Beispiel - Neues Produkt hinzufügen:**
```bash
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "id": 200,
    "name": "Neues Testprodukt",
    "price": 4.99,
    "layoutCode": "310/1/1/1"
  }'
```

**Beispiel - Produkt aktualisieren:**
```bash
# Preis von Produkt 1 ändern
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "id": 1,
    "name": "Gala Äpfel lose",
    "price": 3.49,
    "layoutCode": "310/1/1/1"
  }'
```

**Erfolgsantwort (200) - Neu erstellt:**
```json
{
  "result": "created"
}
```

**Erfolgsantwort (200) - Aktualisiert:**
```json
{
  "result": "updated"
}
```

**Was passiert intern?**
- Wenn ID existiert: Produkt wird überschrieben (Update)
- Wenn ID neu ist: Neues Produkt wird angelegt (Create)
- OpenSearch re-indexiert das Produkt für die Suche

**Frontend-Verwendung:**
```javascript
// Produkt hinzufügen/aktualisieren
async function saveProduct(product) {
  const response = await fetch('http://localhost:8080/api/products', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(product)
  });
  return await response.json();
}

// Verwendung
const result = await saveProduct({
  id: 200,
  name: 'Neues Bio-Produkt',
  price: 5.99,
  layoutCode: '310/1/1/1'
});
```

---

### 5. Mehrere Produkte bulk-indexieren

**Zweck:** Importiert viele Produkte gleichzeitig - viel schneller als einzeln.

**Endpunkt:** `POST /api/products/bulk`

**Request Body:** JSON-Array von Produkten

**Wann verwenden?**
- Initiales Befüllen der Datenbank
- Import aus Excel/CSV
- Massenaktualisierungen
- Synchronisation mit anderen Systemen

**Beispiel - 2 Produkte:**
```bash
curl -X POST http://localhost:8080/api/products/bulk \
  -H "Content-Type: application/json" \
  -d '[
    {
      "id": 201,
      "name": "Produkt 1",
      "price": 1.99,
      "layoutCode": "310/1/1/1"
    },
    {
      "id": 202,
      "name": "Produkt 2",
      "price": 2.99,
      "layoutCode": "310/1/1/2"
    }
  ]'
```

**Beispiel - Alle Produkte aus Datei:**
```bash
# Import der kompletten belegplan.json (153 Produkte)
curl -X POST http://localhost:8080/api/products/bulk \
  -H "Content-Type: application/json" \
  -d @belegplan.json
```

**Erfolgsantwort (200):**
```json
{
  "message": "Successfully indexed 153 products"
}
```

**Performance:**
- Einzeln: ~1 Sekunde pro Produkt = 153 Sekunden
- Bulk: ~2-3 Sekunden für 153 Produkte
- **50x schneller!**

**Was passiert intern?**
```java
// OpenSearch Bulk API
POST /_bulk
{ "index": { "_id": "1" } }
{ "id": 1, "name": "Produkt 1", ... }
{ "index": { "_id": "2" } }
{ "id": 2, "name": "Produkt 2", ... }
// Alle Operationen in einer Anfrage
```

**Frontend-Verwendung:**
```javascript
// Bulk-Import
async function importProducts(products) {
  const response = await fetch('http://localhost:8080/api/products/bulk', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(products)
  });
  return await response.json();
}

// Verwendung
const products = [
  { id: 1, name: 'Produkt 1', price: 1.99, layoutCode: '310/1/1/1' },
  { id: 2, name: 'Produkt 2', price: 2.99, layoutCode: '310/1/1/2' }
];
const result = await importProducts(products);
console.log(result.message);  // "Successfully indexed 2 products"
```

---

## Datenmodell

### Product

Jedes Produkt hat genau 4 Felder:

```json
{
  "id": 1,                 // Eindeutige Nummer (Integer)
  "name": "Gala Äpfel",    // Produktname (String)
  "price": 2.99,           // Preis in Euro (Number/Double)
  "layoutCode": "310/1/1/1" // Position im Regal (String)
}
```

**Feldtypen in OpenSearch:**
- `id`: **integer** - Für exakte Suchen und Sortierung
- `name`: **text** - Für Volltextsuche (wird analysiert)
- `price`: **double** - Für Bereichssuchen (z.B. Preis < 5€)
- `layoutCode`: **keyword** - Für exakte Filter (nicht analysiert)

---

### Layout-Code Format

Der `layoutCode` beschreibt die Position des Produkts im Regal.

**Format:** `{categoryCode}/{meter}/{fach}/{reihe}`

#### Aufbau der 4 Zahlen:

1. **categoryCode** - Warengruppe (3-stellig)
2. **meter** - Regalabschnitt von links (1-5)
3. **fach** - Regalfach von oben (1-7)
4. **reihe** - Position von links im Fach (1-3)

**Beispiel:** `"310/2/3/1"`
