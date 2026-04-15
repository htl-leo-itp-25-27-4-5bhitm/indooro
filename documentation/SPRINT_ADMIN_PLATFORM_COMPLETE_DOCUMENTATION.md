# Indooro Admin Platform Complete Documentation

Stand: 2026-04-08

## 1. Ziel dieses Dokuments

Dieses Dokument beschreibt den kompletten aktuellen Stand der im Sprint umgesetzten Admin-Plattform fuer Indooro.

Es deckt ab:

- Sprint-Ziele und Umsetzungsstand
- Systemarchitektur
- LeoCloud-Deployment
- Datenmodell in PostgreSQL
- OpenSearch- und Legacy-Teile
- Admin-Weboberflaeche
- Layout-Editor-Integration
- Beacon-Verwaltung
- Logging und Fehlerlogging
- REST-Endpunkte
- Mobile-/iOS-Vorbereitung
- bekannte Grenzen und offene Punkte

Das Ziel ist, dass dieses Dokument als technische Referenz fuer Review, Abgabe, weitere Sprints und Onboarding genutzt werden kann.

---

## 2. Sprint-Kontext

Der Sprint hatte als Schwerpunkt den Aufbau einer neuen Admin-Plattform fuer:

- Regionen
- Filialen
- Beacons
- filialspezifische Layouts
- spaetere automatische Filialerkennung in der iOS-App per Beacon

Zusatzanforderungen waren:

- Hosting in der LeoCloud
- Integration des bestehenden Layout-Editors
- Nachvollziehbarkeit von Aenderungen
- spaetere Erweiterbarkeit um Authentifizierung und Rollen

---

## 3. Gesamtstatus

### 3.1 Im Sprint umgesetzt

Folgende Teile sind umgesetzt und lauffaehig:

- neue Admin-Plattform im Browser unter `/admin/`
- PostgreSQL-basierte Verwaltungsdatenbank
- Regionen anlegen, lesen, bearbeiten, archivieren
- Filialen anlegen, lesen, bearbeiten, archivieren
- Beacon anlegen, bulk anlegen, bearbeiten, archivieren
- freie und zugewiesene Beacons anzeigen
- Beacon einer Filiale zuordnen und wieder freigeben
- store-spezifische Layout-Versionen
- bestehender Layout-Editor in den Filialkontext integriert
- Audit-Logs fuer erfolgreiche Verwaltungsaktionen
- separate Fehlerlog-Seite fuer 4xx- und 5xx-API-Fehler
- Mobile-API als Vorbereitung fuer spaetere iOS-Beacon-Erkennung
- Deployment in der LeoCloud

### 3.2 Teilweise umgesetzt / vorbereitet

Diese Punkte sind vorbereitet, aber noch nicht voll fertig:

- Rollenmodell fuer Administrator, Regionsleiter und Marktleiter
- Authentifizierung / Keycloak
- echte Rechtepruefung pro Region oder Filiale
- vollstaendige iOS-Integration der Beacon-Erkennung

### 3.3 Bewusst nicht umgesetzt

- echte Benutzerverwaltung
- Login / Keycloak-Absicherung
- produktive Rechtepruefung im UI und Backend
- komplexe Beacon-Passwortverwaltung
- echtes Hard-Delete fuer Regionen, Filialen oder Beacons

---

## 4. Live-System und URLs

### 4.1 LeoCloud Kontext

- Kubernetes Context: `leocloud`
- Namespace: `student-it220209`
- User: `it220209`
- Host: `https://it220209.cloud.htl-leonding.ac.at/`

### 4.2 Aktuelle Live-URLs

- Startseite: `https://it220209.cloud.htl-leonding.ac.at/`
- Admin-Plattform: `https://it220209.cloud.htl-leonding.ac.at/admin/`
- Layout-Editor: `https://it220209.cloud.htl-leonding.ac.at/admin/editor/`
- Fehlerlog-Seite: `https://it220209.cloud.htl-leonding.ac.at/admin/server-logs/`
- Customer-Webansicht: `https://it220209.cloud.htl-leonding.ac.at/customer/`
- Healthcheck: `https://it220209.cloud.htl-leonding.ac.at/api/admin/health`
- System-Logs API: `https://it220209.cloud.htl-leonding.ac.at/api/admin/logs`
- Fehler-Logs API: `https://it220209.cloud.htl-leonding.ac.at/api/admin/error-logs`

---

## 5. Architektur

### 5.1 Hauptkomponenten

Das System besteht aktuell aus diesen Hauptkomponenten:

1. Quarkus Backend
2. PostgreSQL
3. OpenSearch
4. OpenSearch Dashboards
5. statische Admin- und Customer-Seiten, ausgeliefert direkt durch Quarkus
6. Kubernetes + Ingress in der LeoCloud

### 5.2 Technische Rollen der Komponenten

#### Quarkus Backend

Das Backend ist die zentrale Anwendung.

Es liefert:

- REST-API fuer Verwaltungsdaten
- REST-API fuer Layouts
- REST-API fuer Mobile/iOS-Vorbereitung
- die Admin-Plattform als statische Weboberflaeche
- den bestehenden Layout-Editor
- die Customer-Webansicht
- Audit-Logs und Fehler-Logs

#### PostgreSQL

PostgreSQL ist die relationale Verwaltungsdatenbank fuer:

- Regionen
- Filialen
- Beacons
- Beacon-Zuordnungen
- Layout-Versionen
- Audit-Logs
- Fehler-Logs

#### OpenSearch

OpenSearch bleibt fuer die bestehende Produktsuche und das alte/Legacy-Layoutsystem relevant.

OpenSearch wird aktuell weiter genutzt fuer:

- Produktdaten
- Legacy-Layout-Endpunkte unter `/api/layout/...`

#### Admin-Weboberflaeche

Die Admin-Plattform laeuft direkt unter `/admin/` und spricht mit dem Backend ueber REST.

#### Layout-Editor

Der bestehende Editor wurde nicht ersetzt, sondern store-spezifisch erweitert.

#### Mobile-/iOS-Vorbereitung

Das Backend bietet bereits Endpunkte, um spaeter:

- aus einer Beacon-ID eine Filiale zu bestimmen
- das passende Filiallayout zu laden

---

## 6. Persistenzmodell

### 6.1 Hauptdatenbank

Die Hauptpersistenz fuer die neue Admin-Plattform ist PostgreSQL.

Konfiguration in Quarkus:

- `quarkus.datasource.db-kind=postgresql`
- `quarkus.flyway.migrate-at-start=true`
- `quarkus.hibernate-orm.database.generation=validate`

### 6.2 Legacy-/Bestandsdaten

Legacy-Daten liegen weiter in OpenSearch:

- Produktindex
- Legacy-Layouts fuer die alte Layout-API

---

## 7. Datenmodell in PostgreSQL

### 7.1 Migrationen

Es gibt aktuell zwei Flyway-Migrationen:

1. `V1__admin_platform_foundation.sql`
2. `V2__error_logs.sql`

### 7.2 Tabellen aus V1

#### `regions`

Felder:

- `id`
- `code`
- `name`
- `description`
- `status`
- `created_at`
- `updated_at`

Zweck:

- logische Gruppierung von Filialen

#### `stores`

Felder:

- `id`
- `region_id`
- `store_code`
- `name`
- `street`
- `zip_code`
- `city`
- `country`
- `notes`
- `status`
- `archived_at`
- `created_at`
- `updated_at`

Zweck:

- einzelne Filiale / einzelner Supermarkt

#### `beacons`

Felder:

- `id`
- `beacon_code`
- `identity_key`
- `uuid`
- `major`
- `minor`
- `notes`
- `status`
- `created_at`
- `updated_at`

Zweck:

- globale Verwaltung der Beacon-Hardware

#### `beacon_assignments`

Felder:

- `id`
- `beacon_id`
- `store_id`
- `assigned_at`
- `released_at`
- `is_active`
- `created_at`
- `updated_at`

Zweck:

- Zuordnung Beacon -> Filiale
- Historie ueber Freigabe und Neu-Zuordnung

#### `layout_versions`

Felder:

- `id`
- `store_id`
- `version_no`
- `layout_name`
- `layout_json`
- `status`
- `change_note`
- `created_by_role`
- `created_by_label`
- `activated_at`
- `created_at`
- `updated_at`

Zweck:

- filialspezifische Layout-Versionierung
- Speicherung des kompletten Marktlayouts als JSONB

#### `audit_logs`

Felder:

- `id`
- `entity_type`
- `entity_id`
- `action`
- `actor_role`
- `actor_label`
- `summary`
- `before_json`
- `after_json`
- `created_at`
- `updated_at`

Zweck:

- Protokoll erfolgreicher Aktionen

### 7.3 Tabellen aus V2

#### `error_logs`

Felder:

- `id`
- `status_code`
- `method`
- `path`
- `message`
- `error_type`
- `stack_trace`
- `created_at`
- `updated_at`

Zweck:

- Protokoll fehlgeschlagener API-Requests und interner Fehler

### 7.4 Wichtige fachliche Regeln im Schema

- `regions.code` ist eindeutig
- `stores.store_code` ist eindeutig
- `beacons.beacon_code` ist eindeutig
- `beacons.identity_key` ist eindeutig
- pro Beacon darf nur eine aktive Zuordnung existieren
- pro Filiale darf nur ein aktives Layout existieren
- Layout-Versionen sind pro Filiale eindeutig nummeriert

---

## 8. Fachlogik

### 8.1 Regionen

Regionen dienen als organisatorische Gruppierung von Filialen.

Aktuell koennen Regionen:

- angelegt werden
- bearbeitet werden
- archiviert werden
- aktiv gefiltert werden

### 8.2 Filialen

Filialen sind die Kernobjekte der Admin-Plattform.

Aktuell koennen Filialen:

- angelegt werden
- bearbeitet werden
- archiviert werden
- gelistet werden
- gesucht und gefiltert werden
- mit Layout und Beacons dargestellt werden

Beim Archivieren einer Filiale werden aktive Beacon-Zuordnungen beendet.

### 8.3 Beacons

Beacons sind global verwaltete Hardwareobjekte.

Aktuell koennen Beacons:

- einzeln angelegt werden
- in Bulk angelegt werden
- bearbeitet werden
- archiviert werden
- einer Filiale zugeordnet werden
- wieder freigegeben werden
- als frei oder zugewiesen angezeigt werden

### 8.4 Layouts

Jede Filiale kann ein eigenes aktives Layout haben.

Das Layout wird als JSON gespeichert und versioniert.

Ein neues Speichern erzeugt eine neue Layout-Version.

### 8.5 Logs

Es gibt zwei Log-Arten:

1. `audit_logs`
   - erfolgreiche Aktionen
2. `error_logs`
   - fehlgeschlagene Anfragen oder interne Fehler

---

## 9. Beacon-Identitaet und Validierung

### 9.1 Felder

Ein Beacon besteht fachlich aktuell aus:

- `uuid`
- optional `major`
- optional `minor`
- `beaconCode`

### 9.2 Identity Key

Intern wird ein `identity_key` erzeugt.

Der Zweck ist:

- eindeutige Identifikation des Beacons
- spaetere flexible Unterstuetzung von `uuid` oder `uuid + major + minor`

### 9.3 Validierungsregeln

Beim Beacon-Create/Update gelten:

- `uuid` ist Pflicht
- `major` und `minor` muessen entweder beide gesetzt oder beide leer sein
- `beaconCode` muss eindeutig sein
- `identity_key` muss eindeutig sein

### 9.4 Konsequenz fuer die Admin-Oberflaeche

Wenn im UI ein Beacon angelegt wird mit:

- UUID gesetzt
- nur `major`, aber kein `minor`

oder umgekehrt, dann antwortet das Backend mit `400 Bad Request`.

---

## 10. REST-API

### 10.1 Regionen

#### `GET /api/regions`

Zweck:

- Liste von Regionen laden

Query-Parameter:

- `status`

#### `POST /api/regions`

Zweck:

- Region anlegen

#### `GET /api/regions/{regionId}`

Zweck:

- einzelne Region laden

#### `PUT /api/regions/{regionId}`

Zweck:

- Region aktualisieren

#### `PATCH /api/regions/{regionId}/archive`

Zweck:

- Region archivieren

### 10.2 Filialen

#### `GET /api/stores`

Zweck:

- paginierte Filialliste laden

Query-Parameter:

- `query`
- `regionId`
- `status`
- `page`
- `size`

#### `POST /api/stores`

Zweck:

- Filiale anlegen

#### `GET /api/stores/{storeId}`

Zweck:

- Filialdetails laden

#### `PUT /api/stores/{storeId}`

Zweck:

- Filiale aktualisieren

#### `PATCH /api/stores/{storeId}/archive`

Zweck:

- Filiale archivieren

#### `GET /api/stores/{storeId}/audit`

Zweck:

- Audit-Historie einer Filiale laden

#### `GET /api/stores/{storeId}/beacons`

Zweck:

- alle aktiven Beacon-Zuordnungen dieser Filiale laden

### 10.3 Beacons

#### `GET /api/beacons`

Zweck:

- Liste aller Beacons laden

Query-Parameter:

- `status`
- `assigned`
- `storeId`
- `query`

#### `GET /api/beacons/free`

Zweck:

- freie Beacons laden

#### `POST /api/beacons`

Zweck:

- Beacon einzeln anlegen

#### `POST /api/beacons/bulk`

Zweck:

- mehrere Beacons auf einmal anlegen

#### `GET /api/beacons/{beaconId}`

Zweck:

- einzelnen Beacon laden

#### `PUT /api/beacons/{beaconId}`

Zweck:

- Beacon aktualisieren

#### `PATCH /api/beacons/{beaconId}/archive`

Zweck:

- Beacon archivieren

#### `POST /api/beacons/{beaconId}/assign`

Zweck:

- Beacon einer Filiale zuordnen

#### `POST /api/beacons/{beaconId}/release`

Zweck:

- Beacon wieder freigeben

### 10.4 Store-Layouts

#### `GET /api/stores/{storeId}/layout/current`

Zweck:

- aktives Layout einer Filiale laden

#### `GET /api/stores/{storeId}/layout/versions`

Zweck:

- alle Layout-Versionen einer Filiale laden

#### `GET /api/stores/{storeId}/layout/versions/{layoutId}`

Zweck:

- konkrete Layout-Version laden

#### `POST /api/stores/{storeId}/layout/versions`

Zweck:

- neue Layout-Version speichern

#### `POST /api/stores/{storeId}/layout/versions/{layoutId}/activate`

Zweck:

- alte Version wieder als aktive Version setzen

#### `GET /api/stores/{storeId}/layout/editor-context`

Zweck:

- filialspezifischen Editor-Kontext laden

Enthaelt:

- Filialreferenz
- aktuelles Layout
- zugewiesene Beacons

### 10.5 System-Logs

#### `GET /api/admin/logs`

Zweck:

- erfolgreiche Aktionen als kompakte System-Logs laden

Query-Parameter:

- `limit`

### 10.6 Fehler-Logs

#### `GET /api/admin/error-logs`

Zweck:

- protokollierte API-Fehler laden

Query-Parameter:

- `limit`

### 10.7 Mobile-/iOS-Vorbereitung

#### `GET /api/mobile/stores`

Zweck:

- Liste aktiver Filialen fuer spaetere manuelle Auswahl

#### `GET /api/mobile/stores/by-beacon`

Zweck:

- Filiale anhand Beacon bestimmen

Query-Parameter:

- `uuid`
- `major`
- `minor`

#### `GET /api/mobile/stores/{storeId}/layout/current`

Zweck:

- aktuelles Layout einer Filiale fuer die App laden

### 10.8 Legacy-Layout-API

Diese Endpunkte existieren weiterhin fuer bestehende Funktionen:

- `GET /api/layout/current`
- `POST /api/layout/current`
- `GET /api/layout/history`
- `GET /api/layout/versions/{layoutId}`

Sie dienen aktuell weiterhin als Legacy-/Kompatibilitaetsschicht fuer das alte globale Layoutsystem.

---

## 11. Admin-Weboberflaeche

### 11.1 Route

Die Plattform liegt unter:

- `/admin/`

### 11.2 Bereiche der Seite

Die Hauptseite enthaelt:

1. Dashboard / Status
2. kompakte System-Log-Vorschau
3. Regionen
4. Filialen
5. Filialdetail
6. Beacon-Verwaltung
7. Navigation zum globalen Editor
8. Navigation zur Fehlerlog-Seite

### 11.3 Funktionen der UI

#### Dashboard

Zeigt:

- aktive Regionen
- aktive Filialen
- freie Beacons
- zugewiesene Beacons

#### System Log

Zeigt:

- letzte erfolgreiche Systemaktionen
- ein-/ausklappbar
- kompakte Vorschau statt voller Langliste

#### Regionen

Moeglich:

- neue Region anlegen
- Region bearbeiten
- Region archivieren

#### Filialen

Moeglich:

- neue Filiale anlegen
- Filiale bearbeiten
- Filiale archivieren
- Suche nach Name, Store-Code oder Ort
- Filter nach Status
- Filter nach Region

#### Filialdetail

Zeigt:

- Stammdaten
- zugewiesene Beacons
- Layout-Versionen
- Audit-Historie
- Link in den Editor

#### Beacons

Moeglich:

- Beacon einzeln anlegen
- Beacon bulk anlegen
- Beacons filtern
- Beacon bearbeiten
- Beacon archivieren
- Beacon zuordnen
- Beacon freigeben

### 11.4 Frontend-Fehlerbehandlung

Das Admin-Frontend liest Error-Responses jetzt korrekt aus.

Der fruehere Fehler `Response.text: Body has already been consumed.` wurde behoben.

---

## 12. Layout-Editor-Integration

### 12.1 Route

- `/admin/editor/`
- store-spezifisch mit `?storeId=<UUID>`

### 12.2 Verhalten ohne `storeId`

Ohne `storeId` arbeitet der Editor weiter im Legacy-/globalen Modus.

### 12.3 Verhalten mit `storeId`

Mit `storeId` gilt:

- aktuelles Filiallayout wird geladen
- zugewiesene Beacons werden geladen
- nur diese Beacons koennen verwendet werden
- Speichern erzeugt eine neue Layout-Version fuer diese Filiale
- das Layout wird direkt aktiviert

### 12.4 Beacon-Verwendung im Editor

Im Filialkontext:

- der Editor zeigt die zugewiesenen Beacons an
- bereits verwendete Beacons werden markiert
- neue Beacon-Elemente werden aus dem noch freien Pool genommen
- wenn kein Beacon mehr frei ist, wird das im Editor gemeldet

### 12.5 Layout-Format

Das Layout bleibt JSON-basiert.

Es enthaelt unter anderem:

- `shopName`
- `gridSize`
- `elements`
- `rotation`
- `accessAngle`
- `locked`
- `meter`

### 12.6 Rotation

Der neue Editor unterstuetzt gedrehte Regale.

Das Layoutformat enthaelt `rotation`, und der Editor exportiert diese Werte beim Speichern.

---

## 13. Customer-Webansicht

Die Customer-Ansicht liegt unter:

- `/customer/`

Sie nutzt weiterhin das bestehende/legacy Layoutsystem, greift also nicht direkt auf die neuen store-spezifischen Layout-Endpunkte zurueck.

Das bedeutet:

- die neue Admin-Plattform und store-spezifische Layouts sind der neue Verwaltungsweg
- das alte globale Layoutsystem existiert aus Kompatibilitaetsgruenden noch parallel

---

## 14. Logging und Diagnostik

### 14.1 Erfolgs-Logs (`audit_logs`)

Erfolgreiche Aktionen wie:

- CREATE
- UPDATE
- ARCHIVE
- ASSIGN
- RELEASE
- ACTIVATE

werden in `audit_logs` gespeichert.

Sie werden in der Admin-Hauptseite unter `System Log` angezeigt.

### 14.2 Fehler-Logs (`error_logs`)

Fehlgeschlagene Requests wie:

- `400 Bad Request`
- `409 Conflict`
- `500 Internal Server Error`

werden ueber ExceptionMapper automatisch protokolliert.

Gespeichert werden:

- HTTP-Status
- Methode
- Pfad
- Message
- Fehlertyp
- Stacktrace
- Zeitstempel

### 14.3 Fehlerlog-Seite

Die Fehlerlog-Seite liegt unter:

- `/admin/server-logs/`

Sie zeigt:

- die letzten Fehler
- Stacktrace ein-/ausklappbar
- CLI-Befehle fuer rohe Backend-Logs

### 14.4 Rohe LeoCloud Logs

Fuer rohe Container-/Pod-Logs werden diese Commands verwendet:

```bash
kubectl logs deployment/indooro-backend -n student-it220209 --tail=200
kubectl logs deployment/indooro-backend -n student-it220209 -f
kubectl get pods -n student-it220209
kubectl logs pod/<POD_NAME> -n student-it220209 --tail=200
```

---

## 15. Mobile-/iOS-Vorbereitung

### 15.1 Was vorbereitet ist

Das Backend kann bereits:

- aktive Filialen listen
- eine Filiale anhand eines Beacons aufloesen
- das passende Filiallayout liefern

### 15.2 Geplantes spaeteres Verhalten

Ziel fuer die iOS-App:

1. App erkennt Beacon
2. App ruft `/api/mobile/stores/by-beacon` auf
3. Backend liefert Filiale
4. App ruft `/api/mobile/stores/{storeId}/layout/current` auf
5. App laedt das passende Layout

### 15.3 Was noch nicht fertig ist

Nicht Teil dieses Sprintabschlusses:

- die eigentliche Swift-Implementierung dieser Beacon-Erkennung
- automatische Filialumschaltung in der App
- Rollen-/Login-Logik fuer mobile Benutzer

---

## 16. Deployment in der LeoCloud

### 16.1 Kubernetes-Dateien

Relevante Manifeste:

- `k8s/backend.yaml`
- `k8s/backend-ingress.yaml`
- `k8s/postgres.yaml`
- `k8s/opensearch.yaml`

### 16.2 Backend Deployment

Das Backend verwendet aktuell:

- Image: `ghcr.io/htl-leo-itp-25-27-4-5bhitm/indooro-backend-v2:latest`
- Port: `8080`
- PostgreSQL-Service: `postgres`
- OpenSearch-Service: `opensearch`

### 16.3 Ingress

Ingress-Host:

- `it220209.cloud.htl-leonding.ac.at`

Ingress leitet `/` auf den Service `indooro-backend` Port `8080`.

### 16.4 PostgreSQL Deployment

PostgreSQL laeuft mit:

- Image: `postgres:16-alpine`
- Datenbankname: `indooro`
- User: `indooro`
- Passwort: -||-
- PVC: `postgres-data`

### 16.5 Typischer Deploy-Ablauf

```bash
git push origin main
kubectl apply -n student-it220209 -f k8s/postgres.yaml
kubectl apply -n student-it220209 -f k8s/opensearch.yaml
kubectl apply -n student-it220209 -f k8s/backend.yaml
kubectl apply -n student-it220209 -f k8s/backend-ingress.yaml
kubectl rollout restart deployment/indooro-backend -n student-it220209
```

### 16.6 Wichtiger Hinweis zu `latest`

Da das Backend-Image aktuell mit `latest` deployed wird, braucht es nach einem neuen Build oft einen manuellen:

```bash
kubectl rollout restart deployment/indooro-backend -n student-it220209
```

---

## 17. Build und lokale Entwicklung

### 17.1 Maven / Quarkus

Lokaler Build:

```bash
cd backend/indooro_server
sh mvnw -q -DskipTests package
```

### 17.2 Java 24 Hinweis

Fuer Java 24 wurde ein Byte-Buddy-Flag ueber `.mvn/jvm.config` hinterlegt, damit Quarkus lokal korrekt baut.

### 17.3 Frontend-Dateien

Die Admin-Oberflaeche ist plain HTML/CSS/JS und wird statisch vom Backend ausgeliefert.

Es gibt kein separates Frontend-Buildsystem fuer die neue Admin-Plattform.

---

## 18. Aktuelle Grenzen und offene Punkte

### 18.1 Benutzer und Rollen

Aktuell gibt es keine echte Benutzerverwaltung.

Das bedeutet:

- Administrator, Regionsleiter und Marktleiter sind nur fachlich gedacht
- es gibt keine echte Zugriffsbeschraenkung im Code
- jeder Admin-Endpunkt ist technisch allgemein erreichbar

### 18.2 Kein Keycloak im Sprint

Keycloak wurde bewusst noch nicht integriert.

### 18.3 Kein Hard Delete

Es gibt Archivierung, aber keine echten `DELETE`-Endpunkte fuer Regionen, Filialen oder Beacons.

### 18.4 Doppelte Layout-Welt

Aktuell existieren zwei Layout-Welten parallel:

1. store-spezifische Layouts in PostgreSQL
2. legacy globale Layouts in OpenSearch

Das ist fuer Kompatibilitaet aktuell okay, sollte aber spaeter vereinheitlicht werden.

### 18.5 Customer-Ansicht nutzt noch nicht store-spezifische Layouts

Die Customer-Webansicht haengt derzeit noch am alten Layout-Flow.

---

## 19. Relevante Dateien

### 19.1 Backend Ressourcen

- `backend/indooro_server/src/main/java/at/htl/resource/admin/RegionAdminResource.java`
- `backend/indooro_server/src/main/java/at/htl/resource/admin/StoreAdminResource.java`
- `backend/indooro_server/src/main/java/at/htl/resource/admin/BeaconAdminResource.java`
- `backend/indooro_server/src/main/java/at/htl/resource/admin/StoreLayoutAdminResource.java`
- `backend/indooro_server/src/main/java/at/htl/resource/admin/AdminLogResource.java`
- `backend/indooro_server/src/main/java/at/htl/resource/admin/ErrorLogResource.java`
- `backend/indooro_server/src/main/java/at/htl/resource/admin/ApiWebApplicationExceptionMapper.java`
- `backend/indooro_server/src/main/java/at/htl/resource/admin/ApiThrowableExceptionMapper.java`
- `backend/indooro_server/src/main/java/at/htl/resource/mobile/MobileStoreResource.java`
- `backend/indooro_server/src/main/java/at/htl/resource/LayoutResource.java`

### 19.2 Backend Services

- `backend/indooro_server/src/main/java/at/htl/admin/service/RegionAdminService.java`
- `backend/indooro_server/src/main/java/at/htl/admin/service/StoreAdminService.java`
- `backend/indooro_server/src/main/java/at/htl/admin/service/BeaconAdminService.java`
- `backend/indooro_server/src/main/java/at/htl/admin/service/StoreLayoutAdminService.java`
- `backend/indooro_server/src/main/java/at/htl/admin/service/AuditLogService.java`
- `backend/indooro_server/src/main/java/at/htl/admin/service/ErrorLogService.java`
- `backend/indooro_server/src/main/java/at/htl/admin/service/MobileStoreService.java`

### 19.3 Admin Frontend

- `backend/indooro_server/src/main/resources/META-INF/resources/admin/index.html`
- `backend/indooro_server/src/main/resources/META-INF/resources/admin/app.js`
- `backend/indooro_server/src/main/resources/META-INF/resources/admin/app.css`
- `backend/indooro_server/src/main/resources/META-INF/resources/admin/editor/index.html`
- `backend/indooro_server/src/main/resources/META-INF/resources/admin/editor.js`
- `backend/indooro_server/src/main/resources/META-INF/resources/admin/editor.css`
- `backend/indooro_server/src/main/resources/META-INF/resources/admin/server-logs/index.html`
- `backend/indooro_server/src/main/resources/META-INF/resources/admin/server-logs/server-logs.js`
- `backend/indooro_server/src/main/resources/META-INF/resources/admin/server-logs/server-logs.css`

### 19.4 Datenbank / Migrationen

- `backend/indooro_server/src/main/resources/db/migration/V1__admin_platform_foundation.sql`
- `backend/indooro_server/src/main/resources/db/migration/V2__error_logs.sql`

### 19.5 Deployment

- `backend/indooro_server/src/main/resources/application.properties`
- `k8s/backend.yaml`
- `k8s/backend-ingress.yaml`
- `k8s/postgres.yaml`
- `k8s/opensearch.yaml`
- `DEPLOYMENT.md`

---

## 20. Zusammenfassung

Die neue Admin-Plattform wurde fuer den Sprint erfolgreich als funktionierende LeoCloud-Loesung aufgebaut.

Der aktuelle Stand bietet:

- zentrale Verwaltung von Regionen, Filialen und Beacons
- store-spezifische Layouts mit Versionierung
- Integration des bestehenden Editors in den Filialkontext
- nachvollziehbare Erfolgs-Logs und separate Fehler-Logs
- technische Grundlage fuer die spaetere iOS-Filialerkennung per Beacon

Noch offen bleiben vor allem:

- Benutzer-/Rollenlogik
- Authentifizierung mit Keycloak
- vollstaendige mobile Integration
- langfristige Bereinigung der parallelen Layout-Welten
