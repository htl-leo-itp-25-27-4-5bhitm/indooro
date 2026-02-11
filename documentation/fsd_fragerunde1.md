# FSD

## 0) Ziel & Output (für Codex/Cursor)

1. Was genau soll am Ende rausfallen: **eine** technische Spezifikation für das **gesamte System** (Backend + Web + App + Pipeline) oder nur für **eine Komponente**?
    1.  Eine umfassende technische Spezifikation für das **gesamte System** (Backend, Web-Admin, Mobile App, Python-Pipeline).
    *Begründung:* Auch wenn wir Modul für Modul implementieren, muss Codex den Gesamtkontext kennen, um Schnittstellen (API) korrekt zu definieren.
2. In welchem Format brauchst du die Spec: **Markdown**, **OpenAPI**, **ADR-Style**, **User Stories + Akzeptanzkriterien**, oder eine Mischung?
    
    **Markdown**. Innerhalb des Markdowns sollen spezifische Blöcke genutzt werden:
    
    - **Mermaid-Diagramme** für Datenflüsse und User-Flows.
    - **YAML/OpenAPI-Style** für API-Definitionen.
    - **Tabellen** für Datenbank-Schemas.
    - **User Stories** als Kontext, aber der Fokus liegt auf technischer Umsetzung.
3. Soll die Spec so geschrieben sein, dass Codex/Cursor daraus **direkt Tickets/Code-Struktur** ableiten kann (Module, Dateien, Endpoints, Datenmodelle)?
    1. **Ja, absolut.** Die Spec muss eine **Vorschlag für die Ordnerstruktur** (Directory Tree) und **konkrete Dateinamen** enthalten. Zudem sollen Datenmodelle (JSON-Schemas) exakt definiert sein.
4. Welche Detailtiefe ist gewünscht: „Implementierbar ohne Rückfragen“ vs. „Architektur + Leitplanken“?
    
    **„Implementierbar ohne Rückfragen“ (Low-Level Design).**
    
    - Nicht: "Das Backend speichert Daten."
    - Sondern: "Der Service `ProductService.java` nutzt `ProductRepository` und speichert folgende Felder: `ean` (String), `x_coord` (Int), `y_coord` (Int)..."
5. Soll die Spec auch **Nicht-Ziele** und **Explizite Annahmen** enthalten (damit Codex/Cursor nicht fantasieren muss)?
    1. **Ja.** Wir müssen explizit ausschließen: User-Accounts, Payment, Warenwirtschafts-Logik, Echtzeit-Bestandsführung. Das verhindert, dass die KI unnötige Komplexität einbaut.
6. Welche Sprache für die Spec: **Deutsch** oder **Englisch**?
    1. Englisch. Code, Kommentare und Specs sind international immer Englisch. Das reduziert Missverständnisse bei KI-Modellen massiv.

---

## 1) Scope & Use Cases

1. Welche zwei Haupt-Userrollen gibt es fix: **Kunde**, **Admin** – gibt es zusätzlich **Marktmitarbeiter** oder **Filialleiter** mit eigenen Views?
    1. nein es gibt nur die 2. kunde und admin
2. Was ist für den Kunden der Minimal-Flow: **Suche → Produkt finden → Regal markieren**, oder muss es echte **Routenführung** geben?
    1. ja eine echte routenführung
3. Muss der Kunde auch **mehrere Produkte** (Einkaufsliste) planen können (optimierte Route), oder nur **ein Produkt**?
    1. geplant ist nur ein produkt, später ein feature wenn wir fertig sind kommen auch solche features dazu
4. Gibt es **mehrere Stockwerke** oder ist es garantiert **1 Ebene**?
    1. es gibt garantiert eine ebene für den Anfang. später wenn größer kann man drüber nachdenken
5. Gibt es **mehrere Filialen** in einer Installation (Filialauswahl), oder ist es pro Filiale eine eigene Instanz?
    1. jetzt mal nur einen, später wenn weiter ausgerollt, dann muss es schon eine auswahl geben
6. Muss es **Mehrsprachigkeit** geben (DE/EN/…)?
    1. ja deutsch und englisch

---

## 2) Marktmodell / Karte / Koordinatensystem

1. Wie ist die Karte intern gedacht: **Grid in Zellen** (z. B. 10 cm/20 cm pro Cell) oder **freie Vektor-Geometrie**?
    1. grid in zellen mit x und y
2. Was ist die „Wahrheit“ der Maße: echtes Metermaß (skalierbar) oder reicht „relatives Grid“?
    1. ja schon ein echtes metermaß
3. Welche Objekte brauchst du im Layout mindestens: **Wände**, **Regale**, **Gänge**, **Kassen**, **Eingang**, **POIs**?
    1. **Regale**, **Gänge**, **Kassen**, **Eingang braucht man mindestens**
4. Müssen Regale **begehbare Kanten/Fronten** haben (für Routing), oder reicht „Regal als Block“?
    1. es reicht als block, Wir definieren Regale als Block, aber jedes Produkt hat einen „Access Point“ (Zugriffspunkt) im Gang davor.
5. Wie wird ein Regal-Code wie `510/3/3/2` auf die Karte gemappt: auf **ein Regal-Objekt**, auf **ein Segment**, oder auf **ein einzelnes Fach/Slot**?
    1. einfaches fach slot
6. Gibt es eine fixe Konvention, was die Teile des Codes bedeuten (Abteilung/Gang/Regal/Boden)? Wenn ja: wie genau?
    1. 510 - categorie mehrere regale können die gleiche categorie haben
    2. 3 - der meter, welches regal von der categorie
    3. 3 - welches fach von oben in dem regal
    4. 2 - in welcher spalte von dem fach ist es
7. Muss die Karte **zoombar** sein? Muss sie **rotierbar** sein?
    1. zoombar ja aufjedenfall, ja auch rotierbar

---

## 3) Positionierung via BLE (Beacons)

1. Welche Beacon-Hardware ist exakt gemeint mit „iBKS USB Beacons“ (Modell/Hersteller)?
    1. [https://accent-systems.com/product/ibks-usb/](https://accent-systems.com/product/ibks-usb/), wir haben von accent systems usb beacons, also brauchen immer einen usb port
2. Senden die Beacons **iBeacon**, **Eddystone**, oder proprietär? Welche Identifier stehen zur Verfügung (UUID/Major/Minor/MAC)?
    1. sie können beides, aber aktuell machen wir ios app und sie sind nur auf ibeacon eingestellt
    2. wir haben alle identifier
3. Wie viele Beacons sind realistisch pro Markt: fix **5**, oder kann es mehr/weniger sein?
    1. mehr oder weniger so viel wie nötig, aber sehr wahrscheinlich mehr. 
4. Wo sind die Beacons montiert (Decke, Regale, Wände) und wie hoch ungefähr?
    1. ja wenn möglich so hoch wie möglich über den regalen, also überall von den 3. 
5. Gibt es ein initiales **Kalibrierungs-Setup** (Beacon-Positionen manuell im Admin-Tool gesetzt), oder müssen die Positionen automatisch gelernt werden?
    1. wir haben einen admin editor wo wir regale und alles einzeichnen können, und da kann man auch die beacons plazieren.
6. Wie oft soll die Position aktualisiert werden (z. B. **1 Hz**, **5 Hz**, „so schnell wie möglich“)?
    1. so schnell wie möglich
7. Welche Genauigkeit ist „gut genug“: 1–2 m, 3–5 m, nur Gang-Erkennung?
    1. also schon so auf 1 meter und das halt erkannt wird ob man vor oder hinter dem regal ist
8. Wie soll sich das System verhalten, wenn nur 1–2 Beacons sichtbar sind (Fallback)?
    1. ja dann gehts nicht, man braucht 3 beacons für triangulation, Wenn wir nur 1 oder 2 Beacons sehen, können wir zumindest einen **Radius** (Kreis) um den Beacon zeichnen („Du bist hier irgendwo in der Nähe von der Milch“). Das ist besser als gar keine Position. Aber für das MVP bleiben wir bei „Kein Blue Dot unter 3 Beacons“.
9. Dürfen zusätzlich Sensorsignale genutzt werden: **Gyro/Accelerometer/Step detection** (Dead Reckoning), oder strikt nur RSSI?
    1. ja sicher kann sowas auch verwendet werden
10. Soll die App eine **Stabilitätsanzeige** haben („Position ungenau“), oder immer einfach Blue-Dot zeigen?
    1. blue dot

---

## 4) Navigation / Routing

1. Muss die App eine **Route** berechnen (A* o. ä.) oder reicht „Ziel blinkt“ + Blue-Dot?
    1. ja route berechnen mit blue dot wo man sich befindet
2. Wenn Route: soll es **Turn-by-turn** (Pfeile/Anweisungen) geben oder nur **Linie auf der Karte**?
    1. nur linie auf karte
3. Welche Regeln gelten fürs Routing: nur Gänge begehbar, keine Regale, Sperrzonen?
    1. nur gänge und sperrzonen durch die die route anders berechnet wird
4. Wie wird das Ziel definiert: „nächstgelegener Punkt am Regal“ oder „exakter Slot“?
    1. nächstgelegener punkt vom regal
5. Muss die Route sich live neu berechnen, wenn der Nutzer „abweicht“?
    1. ja schon live berechnen wenn der user falsch abbiegt oder so
6. Muss Barrierefreiheit berücksichtigt werden (z. B. keine engen Passagen)?
    1. nein, supermarkt ist ja eh barrierefrei
    

Live Neuberechnung" bedeutet, wir prüfen alle X Sekunden: "Ist Distanz(User, Route) > 3 Meter?". Wenn ja -> Recalc. Das spart Akku.

---

## 5) Admin Editor (Web)

1. Wer nutzt den Editor real: interner Entwickler, Filialpersonal, oder externe Dienstleister?
    1. filialen chef, und der interne entwickler um die fertige filiale schon zu bekommen
2. Muss der Editor „idiotensicher“ sein (no-code), oder reicht dev/tech-affin?
    1. ja muss ideotensicher sein
3. Welche Aktionen braucht der Editor zwingend: **zeichnen**, **verschieben**, **rotieren**, **skalieren**, **snappen**, **gruppen**, **löschen**?
    1. ja alles von dem
4. Brauchst du **Layer** (z. B. Wände/Regale/Beacons/POIs getrennt)?
    1. ja
5. Muss man **Beacon-Positionen** im Editor setzen und testen können (Beacon-ID zu Punkt)?
    1. ja
6. Muss der Editor **Versionierung** können (Layout v1/v2, Rollback)?
    1. ja schon auch mit export und import
7. Wie soll das Layout gespeichert werden: als **JSON-Datei**, in DB, in Git, oder beides?
    1. json und das json kann man ja dann in db speichern
8. Gibt es bereits ein gewünschtes JSON-Schema, oder soll es neu definiert werden?
    1. ja gibt es

---

## 6) Produktsuche & Datenmodell (Backend + OpenSearch)

1. Woher kommen die Produktdaten: Export aus Warenwirtschaft, CSV, API, manuell?
    1. es gibt tägliche pdfs die filialleiter geschickt bekommen mit änderungen. einen kompletten export gibt es nicht für uns zugänglich
2. Welche Felder sind fix notwendig: **EAN**, **Name**, **Marke**, **Kategorie**, **Synonyme**, **Regal-Code**, **Filiale**, **Gültig-ab/bis**?
    1. regal code wo sich etwas befindet aufjedenfall, rest optional
3. Wie oft ändern sich Produkte/Zuordnungen real: täglich, stündlich, ad-hoc?
    1. mit jeder lieferung kommt ein belegplan mit, das ist meistens jeden 2. tag
4. Muss die Suche **Autovervollständigung**, **Fuzzy**, **Synonyme**, **Umgangssprache** (z. B. „Topfen“ vs „Quark“) können?
    1. ja, das am besten mittels opensearch
5. Muss die Suche „keine Treffer“ sinnvoll behandeln (Alternativen, Kategorie-Vorschläge)?
    1. ja wär gut
6. Brauchst du ein Ranking (Beliebtheit/Verfügbarkeit), oder rein textbasiert?
    1. nein nur rein textbasiert
7. Muss das System **Mehrfilialigkeit** in OpenSearch abbilden (Index pro Filiale vs Feld)?
    
    Bitte keine "Indizes pro Filiale" anlegen (z. B. `products_store_1`, `products_store_2`). Das ist Wartungs-Hölle. Wir nutzen *einen* Index `products` und jedes Dokument hat das Feld `storeId: 1`. Das ist Standard in OpenSearch/Elastic.
    

---

## 7) PDF-Belegplan Pipeline (Python)

1. Woher kommt das PDF täglich: Download-Link, E-Mail-Anhang, Netzlaufwerk, SFTP?
    1. das bekommen sie über email mitgeschickt zu der bestellung, also wär optimal wenn wir das mitbekommen
2. Gibt es **mehrere PDF-Templates** (unterschiedliche Layouts je Filiale/Version), oder ist es standardisiert?
    1. gute frage, wir wissen es nur wie es bei einer filiale ausshieht
3. Was genau steht im PDF: Regal-Codes + Produktliste, oder Regalplan mit Positionen, oder nur Belegzuordnung?
    1. also es steht immer ein regalabschnitt pro seite, oben dabei eine grafik von dem regal, und unten die änderungen, und das alles mittels regal code, also alt und neu wenn änderungen
4. Sind die Regal-Codes im PDF **Text** oder in **Grafik/Scan**?
    1. wir haben nur ein foto davon bis jetzt, aber wir bekommen hoffentlich bald ein richtiges, dann sehen wir das
5. Muss OCR unterstützt werden, oder ist das ausgeschlossen?
    1. im besten fall nicht nein
6. Wie soll die Pipeline Fehler behandeln: Abbruch, Warnung, „letzter Stand bleibt aktiv“, Quarantäne?
    1. keine halben imports
7. Wie wird validiert, dass ein Update korrekt ist (Stichproben, Checksummen, Plausibilitätsregeln)?
    1. keine halben imports
8. Was ist das Output-Format der Pipeline: JSON, CSV, direkte REST-Calls ans Backend?
    1. also einmal nur als json, aber dann später halt das diese infos direkt ins backend und datenbank geschreiben werden
9. Muss die Pipeline ein **Diff** erzeugen (was hat sich geändert), oder nur den aktuellen Stand?
    1. keine halben imports
    2. Wenn das Skript einen Fehler findet (z. B. Regal-Code nicht lesbar), bricht es für diese Datei ab und schreibt eine Error-Log-Datei. **Keine halben Imports**, das macht die Datenbank kaputt.
10. Gibt es eine Anforderung für **Audit-Logs** (wer/was hat wann importiert)?
    1. wär nicht schlecht

 Das ist das größte Risiko. Wenn das PDF ein Bild ist (Scan), *brauchen* wir OCR (Tesseract). Wir gehen aber erstmal davon aus, dass es ein digitales PDF mit Text-Layer ist (viel einfacher)

---

## 8) REST API (Quarkus)

1. Welche Clients rufen die API auf: nur Web/App, oder auch externe Systeme?
    1. nur die ios app mal primär
2. Brauchst du Authentifizierung: **öffentlich für Kunden** (ohne Login) und **Login für Admin**, oder alles intern?
    1. ist für das gern produkt mal nicht notwendig ein login, dann schon einmal für admin, 
3. Welche Auth-Art: Basic, JWT, OAuth2, Key pro Filiale, IP-Whitelist?
    - **GET /products/search:** Öffentlich (kein Login nötig, damit Kunden sofort suchen können).
    - **POST /admin/...:** Geschützt mit einem einfachen **API-Key** (für den Anfang) oder Basic Auth. Das ist am einfachsten umzusetzen.
4. Welche Kern-Endpunkte brauchst du fix (Liste reicht): Suche, Produktdetail, Layout laden, Position-Config, Health, Admin CRUD?
    1. suche per opensearch, produkte, layout, änderungen, crud, ein lesen von pdf und schreiben
5. Muss es Rate-Limiting geben (z. B. Missbrauch verhindern)?
    1. wissen wir nicht
6. Muss die API offline-tauglich sein (Cache/Bundle), oder immer online?
    1. Die **Karte (JSON)** muss beim App-Start gecached werden (Local Storage). Die **Suche** geht nur online. Wenn das Netz weg ist, kann der Kunde die Karte noch sehen, aber nichts Neues suchen. Das ist der beste Kompromiss.

---

## 9) Deployment / Betrieb

1. Wo läuft das System: **on-prem im Markt**, **Cloud**, oder hybrid?
    1. **Zentrales Cloud-Hosting.** Das Backend (Quarkus API + OpenSearch) läuft auf einem zentralen Server/Cloud-Instanz. Die Filialen benötigen keine eigene Server-Hardware vor Ort.
2. Wie ist die Netzsituation im Markt: stabiles WLAN überall, Captive Portal, Ausfälle?
    1. **Unzuverlässig / Mobilfunk.** Die App muss "Offline-First" Anteile haben (z.B. das Layout/Karte wird beim Start gecached). Für die Produktsuche wird Internet (4G/5G oder Markt-WLAN) benötigt. Wir gehen von **kurzzeitigen Verbindungsabbrüchen** aus.
3. Soll OpenSearch im Markt via Docker laufen oder zentral?
    1. **Zentral via Docker.** Eine zentrale Instanz für alle Daten. (Kein Docker-Container pro Filiale).
4. Muss es Hochverfügbarkeit geben, oder reicht „ein Rechner/Server pro Filiale“?
    1. **Nein (für MVP).** Eine einfache Instanz reicht ("Best Effort"). Wenn der Server nachts neustartet, geht die Suche kurz nicht. Das ist für den Prototyp okay.
5. Welche Monitoring/Logging-Anforderungen gibt es (Prometheus, Grafana, ELK, simple Logs)?
    1. **Simple Logs.** Standard Quarkus Logging (Console/File) reicht vorerst. Wir brauchen noch kein komplexes Dashboard.
6. Welche Umgebungen brauchst du: dev/staging/prod getrennt?
    1. **Dev (Lokal) und Prod (Server).** Zwei Umgebungen reichen.

---

## 10) Mobile (Capacitor App)

1. Welche Plattformen sind Pflicht: iOS, Android, beide?
    1. primär ios, später auch android
2. Welche Mindest-OS-Versionen müssen unterstützt werden?
    - **Android:** Android 10 (API Level 29) oder höher.
    - **iOS:** iOS 15 oder höher.
    - Begründung: Diese Versionen bieten stabilen Support für moderne Web-Standards und Bluetooth-Scanning.
3. Soll die App im Store veröffentlicht werden oder nur als Unternehmens-App/TestFlight/Side-Load?
    1. optimal ja, aber es ist auch ja möglich in bereits betehende apps zu integrieren
4. Wie soll BLE permission/onboarding aussehen (Erklärung, Fehlermeldungen, Deep Links in Settings)?
5. Muss die App auch ohne BLE funktionieren (nur Suche + Karte)?
    1. wär nicht schlecht ja
6. Brauchst du Push Notifications (z. B. Aktionen/Angebote), oder strikt nicht?
    1. kann schon sein das man benutzer immer wie der dran erinnert aber einmal für aktuelles ziel nicht relevant

---

## 11) Datenschutz & Recht (realistisch, nicht akademisch)

1. Wird irgendeine Nutzer-ID gespeichert (auch anonym/pseudonym), oder gar nichts?
    1. nein nichts einmal, später mit premium funktionienen mittels anmeldung, aber nicht notwendig für aktuelles ziel
2. Werden Positionsdaten serverseitig gespeichert oder nur lokal?
    1. nur client seitig i guess
3. Muss es eine Datenschutzerklärung/Consent-Screen geben?
    1. kommt drauf an ob nötig
4. Gibt es Vorgaben vom Marktbetreiber zur Datenspeicherung (Retention, Zugriff, Export)?
    1. nein

---

## 12) Performance & Qualitätsziele

1. Wie groß ist ein typischer Markt im Layout (ungefähre Meter oder Grid-Zellen)?
    1. **Marktfläche ca. 800–2000 m².** Grid-Auflösung: **1 Grid-Zelle = 0.5 - 1m Meter**. Das ergibt bei einem mittleren Markt ein Raster von ca. 60x60 bis 100x100 Zellen.
2. Wie viele DOM-Elemente sind realistisch (Regal-Objekte/Cells)?
    1. **Max. 2.000 DOM-Elemente gleichzeitig.** Wir nutzen CSS-Grid oder Canvas-Ansätze, um die Performance hochzuhalten.
3. Welche Zielgeräte: „älteres Android“ konkret welches Niveau (RAM/CPU)?
    1.  **Mittelklasse-Smartphones (ca. 3-4 Jahre alt).** Referenz: Samsung Galaxy A51 oder iPhone 11. Die App darf auf High-End Geräten flüssig laufen, muss auf Mittelklasse aber benutzbar bleiben.
4. Welche KPI ist wichtig: Time-to-first-search, Map-FPS, Position-Lag, Search-Latency?
    1. **Position-Lag & Smoothness.** Der "Blue Dot" darf nicht ruckeln. Die Bewegung muss flüssig wirken (Interpolation der Beacon-Daten)
5. Welche maximal akzeptable Such-Latenz (z. B. <200ms, <500ms)?
    1. **< 300ms.** Da OpenSearch sehr schnell ist, sollte das Ergebnis fast sofort da sein (bei guter Netzverbindung).
6. Was ist der tolerierbare Blue-Dot-Jitter (visuell), bevor Nutzer es „schlecht“ finden?
    1. **< 2 Meter.** Wenn der Punkt im Stillstand mehr als 2 Meter springt, ist das für den Nutzer verwirrend (er würde ins falsche Regal springen).

---

## 13) Testing & Abnahme

1. Woran erkennst du „fertig“: Welche 5–10 Abnahmekriterien sind fix?
    1. Erkennung exakte position im supermarkt
    2. Korrekte route zum produkt berechnen
    3. das laden von daten und lauffähige änderungen
2. Gibt es Testumgebungen im echten Markt (Beacon-Setup), oder nur Labor/Mock?
    1. also daweil nur im eigenen labor testraum, aber ziel ist finale tests im echten supermarkt
3. Wie sollen Beacon-Daten in dev getestet werden: Simulator/Recorded RSSI-Logs?
    1. beacons wirklich exakte positionen anbriengen und live testen
4. Brauchst du automatische Tests für PDF-Parsing (Golden Files)?
    1. später wenn wir exakte files vom supermarkt haben ja

---

## 14) Prioritäten (damit die Spec nicht explodiert)

1. Was ist die **MVP-Liste** (max. 5–7 Must-haves)?
    - **Backend:** Funktionierende Produktsuche (Quarkus + OpenSearch) mit Regal-Code-Rückgabe.
    - **Admin:** Editor zum Zeichnen des Markt-Layouts (Regale & Wände) und Speichern als JSON.
    - **App (Map):** Darstellung des Marktes und Highlighting des Ziel-Regals.
    - **App (Positioning):** Integration der iBKS Beacons via Capacitor (Anzeige "Blue Dot").
    - **App (Navigation):** Einzeichnen einer einfachen Route (Linie) vom Blue Dot zum Produkt.
2. Was sind klare **Nice-to-haves**, die bewusst später kommen?
    1. einkaufslisten
    2. upselling
3. Was ist explizit **out of scope** außer Warenwirtschaft (z. B. Angebote, Warenverfügbarkeit, Einkaufslisten, Analytics)?
    - **Live-Warenbestand:** Wir gehen davon aus, dass das Produkt da ist, wenn es im Plan steht.
    - **Benutzerkonten:** Keine Registrierung nötig.
    - **Payment:** Bezahlen in der App.
    - **Analytics:** Tracking, wie lange Kunden vor welchem Regal stehen (Datenschutz!).

Wenn du mir diese Punkte beantwortest, kann ich danach gezielt die nächste Fragerunde machen (nur dort, wo noch Lücken sind).