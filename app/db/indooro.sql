-- -----------------------------------------------------
-- Tabelle: STORE (Der Laden)
-- Speichert die einzelnen Läden/Filialen.
-- -----------------------------------------------------
CREATE TABLE STORE (
  StoreID INT PRIMARY KEY AUTO_INCREMENT,
  Name VARCHAR(255) NOT NULL,
  Address TEXT
);

-- -----------------------------------------------------
-- Tabelle: FLOOR_PLAN (Der Grundriss)
-- Speichert die Grundrisse/Karten für einen Laden.
-- -----------------------------------------------------
CREATE TABLE FLOOR_PLAN (
  FloorPlanID INT PRIMARY KEY AUTO_INCREMENT,
  StoreID INT NOT NULL,
  Name VARCHAR(100) NOT NULL,         -- z.B. "Verkaufsfläche EG"
  MapImagePath VARCHAR(255),          -- Pfad zum Hintergrundbild der Karte
  FOREIGN KEY (StoreID) REFERENCES STORE(StoreID)
);

-- -----------------------------------------------------
-- Tabelle: NODE (Navigations-Knoten)
-- Das Herzstück der Navigation. Jeder Punkt auf der Karte (Regal, Kreuzung, Eingang).
-- -----------------------------------------------------
CREATE TABLE NODE (
  NodeID INT PRIMARY KEY AUTO_INCREMENT,
  FloorPlanID INT NOT NULL,
  NodeName VARCHAR(50) UNIQUE,        -- Eure ID, z.B. "N-07-A", "N-Eingang"
  PositionX INT NOT NULL,
  PositionY INT NOT NULL,
  NodeType VARCHAR(50) NOT NULL,      -- 'Regal', 'Kreuzung', 'Eingang', 'Kasse'
  Description TEXT,
  FOREIGN KEY (FloorPlanID) REFERENCES FLOOR_PLAN(FloorPlanID)
);

-- -----------------------------------------------------
-- Tabelle: EDGE (Navigations-Kante)
-- Verbindet zwei Knoten zu einem Graphen für den A*-Algorithmus.
-- -----------------------------------------------------
CREATE TABLE EDGE (
  EdgeID INT PRIMARY KEY AUTO_INCREMENT,
  NodeStartID INT NOT NULL,
  NodeEndID INT NOT NULL,
  Distance INT NOT NULL,              -- Die "Kosten" / Distanz für die Route
  FOREIGN KEY (NodeStartID) REFERENCES NODE(NodeID),
  FOREIGN KEY (NodeEndID) REFERENCES NODE(NodeID)
);

-- -----------------------------------------------------
-- Tabelle: BEACON (Startpunkt-Sender)
-- Speichert die physischen Beacons und verknüpft sie mit einem Start-Knoten.
-- -----------------------------------------------------
CREATE TABLE BEACON (
  BeaconID INT PRIMARY KEY AUTO_INCREMENT,
  StoreID INT NOT NULL,
  UUID VARCHAR(255) NOT NULL,
  Major INT NOT NULL,
  Minor INT NOT NULL,
  StartNodeID INT NOT NULL,           -- Der Knoten, der als Startposition dient
  FOREIGN KEY (StoreID) REFERENCES STORE(StoreID),
  FOREIGN KEY (StartNodeID) REFERENCES NODE(NodeID)
);

-- -----------------------------------------------------
-- Tabelle: CATEGORY (Produktkategorie)
-- Speichert die Hauptkategorien basierend auf dem Belegplan.
-- -----------------------------------------------------
CREATE TABLE CATEGORY (
  CategoryID INT PRIMARY KEY AUTO_INCREMENT,
  StoreID INT NOT NULL,
  CategoryCode VARCHAR(50) NOT NULL,  -- Die 1. Zahl ("510"), generisch als Text
  Name VARCHAR(100) NOT NULL,         -- z.B. "Getränke"
  FOREIGN KEY (StoreID) REFERENCES STORE(StoreID),
  UNIQUE(StoreID, CategoryCode)       -- Der Kategorie-Code ist pro Laden einzigartig
);

-- -----------------------------------------------------
-- Tabelle: SHELF_SECTION (Regal-Abschnitt / "Meter-Block")
-- Verbindet die abstrakte Belegplan-Logik mit der physischen Karte.
-- -----------------------------------------------------
CREATE TABLE SHELF_SECTION (
  SectionID INT PRIMARY KEY AUTO_INCREMENT,
  CategoryID INT NOT NULL,
  SectionCode VARCHAR(50) NOT NULL,     -- Die 2. Zahl ("3"), der "Meter"
  NavigationNodeID INT NOT NULL,      -- Der Knoten, zu dem navigiert werden soll
  FOREIGN KEY (CategoryID) REFERENCES CATEGORY(CategoryID),
  FOREIGN KEY (NavigationNodeID) REFERENCES NODE(NodeID),
  UNIQUE(CategoryID, SectionCode)       -- Der Meter-Code ist pro Kategorie einzigartig
);

-- -----------------------------------------------------
-- Tabelle: PRODUCT (Produktdaten)
-- Die Stammdaten des Produkts, inklusive der genauen Regalposition.
-- -----------------------------------------------------
CREATE TABLE PRODUCT (
  ProductID INT PRIMARY KEY AUTO_INCREMENT,
  SectionID INT NOT NULL,             -- Der Regal-Abschnitt, in dem es steht
  Name VARCHAR(255) NOT NULL,
  Price DECIMAL(10, 2),               -- Preis, kann NULL sein
  LayoutCode VARCHAR(100) UNIQUE,     -- Der volle Code ("510/3/3/2/1"), als Referenz
  
  -- Extrahierte Daten aus dem Code für die App: --
  LayoutShelfLevel INT,               -- Die 3. Zahl ("Fach von oben")
  LayoutShelfRow INT,                 -- Die 4. Zahl ("Reihe von links")
  
  FOREIGN KEY (SectionID) REFERENCES SHELF_SECTION(SectionID)
);

-- -----------------------------------------------------
-- Tabelle: ADMIN_USER (Verwaltungs-Benutzer)
-- Benutzerkonten für den Admin-Editor.
-- -----------------------------------------------------
CREATE TABLE ADMIN_USER (
  AdminID INT PRIMARY KEY AUTO_INCREMENT,
  StoreID INT NOT NULL,               -- Der Laden, den dieser Admin verwaltet
  Username VARCHAR(100) NOT NULL UNIQUE,
  PasswordHash VARCHAR(255) NOT NULL,
  Email VARCHAR(255) UNIQUE,
  FOREIGN KEY (StoreID) REFERENCES STORE(StoreID)
);

-- -----------------------------------------------------
-- Tabelle: SEARCH_KEYWORD (Such-Schlagworte)
-- Trennt Suchbegriffe vom Produktnamen für eine bessere Suche (N:M).
-- -----------------------------------------------------
CREATE TABLE SEARCH_KEYWORD (
  KeywordID INT PRIMARY KEY AUTO_INCREMENT,
  ProductID INT NOT NULL,
  Keyword VARCHAR(100) NOT NULL,
  FOREIGN KEY (ProductID) REFERENCES PRODUCT(ProductID) ON DELETE CASCADE
);