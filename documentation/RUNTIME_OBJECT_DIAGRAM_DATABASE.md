# Indooro Laufzeit-Objektdiagramm der Datenbank

Stand: 2026-04-15

Dieses Dokument zeigt die aktuelle Datenbankstruktur nicht nur abstrakt, sondern als Laufzeit-Objektdiagramm mit echten Werten aus der LeoCloud-PostgreSQL-Datenbank.

Quelle der Daten:

- Kubernetes Namespace: `student-it220209`
- PostgreSQL Pod: `postgres-679889fbd6-mwcgk`
- Datenbank: `indooro`
- Zeitpunkt der Abfrage: 2026-04-15

## 1. Aktueller Tabellenstand

| Tabelle | Anzahl Datensaetze |
|---|---:|
| `regions` | 1 |
| `stores` | 2 |
| `beacons` | 4 |
| `beacon_assignments` | 3 |
| `layout_versions` | 1 |
| `audit_logs` | 12 |
| `error_logs` | 1 |

## 2. ER-Diagramm der Datenbankstruktur

Dieses Diagramm zeigt die strukturellen Beziehungen der Tabellen.

```mermaid
erDiagram
    REGIONS ||--o{ STORES : contains
    STORES ||--o{ BEACON_ASSIGNMENTS : has
    BEACONS ||--o{ BEACON_ASSIGNMENTS : assigned_by
    STORES ||--o{ LAYOUT_VERSIONS : has
    AUDIT_LOGS }o--|| REGIONS : can_reference
    AUDIT_LOGS }o--|| STORES : can_reference
    AUDIT_LOGS }o--|| BEACONS : can_reference
    AUDIT_LOGS }o--|| LAYOUT_VERSIONS : can_reference

    REGIONS {
        uuid id PK
        varchar code UK
        varchar name
        varchar status
        timestamptz created_at
        timestamptz updated_at
    }

    STORES {
        uuid id PK
        uuid region_id FK
        varchar store_code UK
        varchar name
        varchar street
        varchar zip_code
        varchar city
        varchar country
        varchar status
        timestamptz archived_at
        timestamptz created_at
        timestamptz updated_at
    }

    BEACONS {
        uuid id PK
        varchar beacon_code UK
        varchar identity_key UK
        uuid uuid
        int major
        int minor
        varchar status
        text notes
        timestamptz created_at
        timestamptz updated_at
    }

    BEACON_ASSIGNMENTS {
        uuid id PK
        uuid beacon_id FK
        uuid store_id FK
        timestamptz assigned_at
        timestamptz released_at
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    LAYOUT_VERSIONS {
        uuid id PK
        uuid store_id FK
        int version_no
        varchar layout_name
        jsonb layout_json
        varchar status
        text change_note
        timestamptz activated_at
        timestamptz created_at
        timestamptz updated_at
    }

    AUDIT_LOGS {
        uuid id PK
        varchar entity_type
        uuid entity_id
        varchar action
        varchar actor_role
        varchar actor_label
        text summary
        jsonb before_json
        jsonb after_json
        timestamptz created_at
    }

    ERROR_LOGS {
        uuid id PK
        int status_code
        varchar method
        varchar path
        text message
        varchar error_type
        text stack_trace
        timestamptz created_at
    }
```

## 3. Laufzeit-Objektdiagramm mit echten Werten

Dieses Diagramm zeigt konkrete Objektinstanzen aus der aktuellen Datenbank.

### 3.1 Kompakte Laufzeitansicht

Diese Darstellung ist fuer die Sprint-Demo am einfachsten zu erklaeren: Jede Box ist ein echtes Objekt aus der Datenbank.

```mermaid
flowchart LR
    region["Region<br/>id: 593cd902-c79e-4a14-b1e1-c85f30143004<br/>code: AT-OÖ<br/>name: Oberösterreich<br/>status: ACTIVE"]

    storeLeonding["Filiale<br/>id: ad61389a-7486-48fa-afa2-9b5e4132f6a8<br/>code: SPAR-Leonding-001<br/>name: Eurospar Poststraße<br/>ort: 4060 Leonding<br/>status: ACTIVE"]
    storeHoersching["Filiale<br/>id: 0b1e94e5-75cb-48e5-a271-b5cbd209fddd<br/>code: Spar-Hörsching-001<br/>name: Spar-Hörsching<br/>ort: 4063 Hörsching<br/>status: ACTIVE"]

    beaconArchived["Beacon<br/>id: 7e9a1bcc-fdf0-4b58-b1de-8977fbdd95ba<br/>code: IndooroTest1<br/>uuid: 123e4567-e89b-12d3-a456-426614174000<br/>major/minor: 1/1<br/>status: ARCHIVED"]

    beacon1["Beacon<br/>id: 837b4188-beba-4681-9c8e-05f17b74fb68<br/>code: DemoBeaconX1<br/>uuid: 6f1a7f7e-1c44-4d8f-9a7e-8b9a4a2d1c11<br/>major/minor: 1/101<br/>status: ACTIVE"]
    beacon2["Beacon<br/>id: d519049e-9862-4a06-bfca-2f4bfb253827<br/>code: DemoBeaconX2<br/>uuid: 6f1a7f7e-1c44-4d8f-9a7e-8b9a4a2d1c12<br/>major/minor: 1/102<br/>status: ACTIVE"]
    beacon3["Beacon<br/>id: c8f6e9ad-656a-401d-a8ac-a0b9a8d93f2f<br/>code: DemoBeaconX3<br/>uuid: 6f1a7f7e-1c44-4d8f-9a7e-8b9a4a2d1c13<br/>major/minor: 2/201<br/>status: ACTIVE"]

    assignment1["BeaconAssignment<br/>id: f11eb49b-d946-4605-9b8d-18d601f37f95<br/>active: true<br/>assignedAt: 2026-04-08 08:54:29 UTC"]
    assignment2["BeaconAssignment<br/>id: f75bed6e-90a2-431c-8781-3d4d5143e8a3<br/>active: true<br/>assignedAt: 2026-04-08 08:54:32 UTC"]
    assignment3["BeaconAssignment<br/>id: 5f8b1f22-249f-418b-a870-d95e5cedf8c3<br/>active: true<br/>assignedAt: 2026-04-08 08:54:34 UTC"]

    layout["LayoutVersion<br/>id: f2fa5b31-5c9c-4066-acf3-70fe2157fa83<br/>store: Spar-Hörsching-001<br/>version: 1<br/>status: ACTIVE<br/>shopName: Spar-Hörsching<br/>elements: 39<br/>grid: 40 x 60"]

    region -->|"hat Filiale"| storeLeonding
    region -->|"hat Filiale"| storeHoersching

    storeLeonding -->|"hat aktive Zuordnung"| assignment1
    storeLeonding -->|"hat aktive Zuordnung"| assignment2
    storeLeonding -->|"hat aktive Zuordnung"| assignment3

    assignment1 -->|"verweist auf"| beacon1
    assignment2 -->|"verweist auf"| beacon2
    assignment3 -->|"verweist auf"| beacon3

    storeHoersching -->|"hat aktives Layout"| layout

    beaconArchived -.->|"archiviert, keiner Filiale aktiv zugeordnet"| storeLeonding
```

### 3.2 Detailliertes Objektdiagramm

```mermaid
classDiagram
    direction LR

    class region_593cd902 {
        <<Region>>
        id = 593cd902-c79e-4a14-b1e1-c85f30143004
        code = AT-OÖ
        name = Oberösterreich
        status = ACTIVE
        createdAt = 2026-04-08 08:25:05 UTC
    }

    class store_ad61389a {
        <<Store>>
        id = ad61389a-7486-48fa-afa2-9b5e4132f6a8
        storeCode = SPAR-Leonding-001
        name = Eurospar Poststraße
        street = Poststraße 23
        zipCode = 4060
        city = Leonding
        country = Austria
        status = ACTIVE
        archivedAt = null
    }

    class store_0b1e94e5 {
        <<Store>>
        id = 0b1e94e5-75cb-48e5-a271-b5cbd209fddd
        storeCode = Spar-Hörsching-001
        name = Spar-Hörsching
        street = Hörsching 1
        zipCode = 4063
        city = Hörsching
        country = Austria
        status = ACTIVE
        archivedAt = null
    }

    class beacon_7e9a1bcc {
        <<Beacon>>
        id = 7e9a1bcc-fdf0-4b58-b1de-8977fbdd95ba
        beaconCode = IndooroTest1
        uuid = 123e4567-e89b-12d3-a456-426614174000
        major = 1
        minor = 1
        identityKey = 123e4567-e89b-12d3-a456-426614174000:1:1
        status = ARCHIVED
        notes = test
    }

    class beacon_837b4188 {
        <<Beacon>>
        id = 837b4188-beba-4681-9c8e-05f17b74fb68
        beaconCode = DemoBeaconX1
        uuid = 6f1a7f7e-1c44-4d8f-9a7e-8b9a4a2d1c11
        major = 1
        minor = 101
        identityKey = 6f1a7f7e-1c44-4d8f-9a7e-8b9a4a2d1c11:1:101
        status = ACTIVE
        notes = Demo
    }

    class beacon_d519049e {
        <<Beacon>>
        id = d519049e-9862-4a06-bfca-2f4bfb253827
        beaconCode = DemoBeaconX2
        uuid = 6f1a7f7e-1c44-4d8f-9a7e-8b9a4a2d1c12
        major = 1
        minor = 102
        identityKey = 6f1a7f7e-1c44-4d8f-9a7e-8b9a4a2d1c12:1:102
        status = ACTIVE
        notes = null
    }

    class beacon_c8f6e9ad {
        <<Beacon>>
        id = c8f6e9ad-656a-401d-a8ac-a0b9a8d93f2f
        beaconCode = DemoBeaconX3
        uuid = 6f1a7f7e-1c44-4d8f-9a7e-8b9a4a2d1c13
        major = 2
        minor = 201
        identityKey = 6f1a7f7e-1c44-4d8f-9a7e-8b9a4a2d1c13:2:201
        status = ACTIVE
        notes = null
    }

    class assignment_f11eb49b {
        <<BeaconAssignment>>
        id = f11eb49b-d946-4605-9b8d-18d601f37f95
        assignedAt = 2026-04-08 08:54:29 UTC
        releasedAt = null
        isActive = true
    }

    class assignment_f75bed6e {
        <<BeaconAssignment>>
        id = f75bed6e-90a2-431c-8781-3d4d5143e8a3
        assignedAt = 2026-04-08 08:54:32 UTC
        releasedAt = null
        isActive = true
    }

    class assignment_5f8b1f22 {
        <<BeaconAssignment>>
        id = 5f8b1f22-249f-418b-a870-d95e5cedf8c3
        assignedAt = 2026-04-08 08:54:34 UTC
        releasedAt = null
        isActive = true
    }

    class layout_f2fa5b31 {
        <<LayoutVersion>>
        id = f2fa5b31-5c9c-4066-acf3-70fe2157fa83
        storeId = 0b1e94e5-75cb-48e5-a271-b5cbd209fddd
        versionNo = 1
        layoutName = Spar-Hörsching
        status = ACTIVE
        shopName = Spar-Hörsching
        gridSize = 40 x 60
        elementCount = 39
        activatedAt = 2026-04-08 08:54:02 UTC
    }

    region_593cd902 "1" --> "1" store_ad61389a : contains
    region_593cd902 "1" --> "1" store_0b1e94e5 : contains

    store_ad61389a "1" --> "1" assignment_f11eb49b : has active assignment
    store_ad61389a "1" --> "1" assignment_f75bed6e : has active assignment
    store_ad61389a "1" --> "1" assignment_5f8b1f22 : has active assignment

    assignment_f11eb49b "1" --> "1" beacon_837b4188 : references
    assignment_f75bed6e "1" --> "1" beacon_d519049e : references
    assignment_5f8b1f22 "1" --> "1" beacon_c8f6e9ad : references

    store_0b1e94e5 "1" --> "1" layout_f2fa5b31 : active layout
```

## 4. Laufzeit-Interpretation

### 4.1 Region

Aktuell gibt es genau eine Region:

| Region-ID | Code | Name | Status |
|---|---|---|---|
| `593cd902-c79e-4a14-b1e1-c85f30143004` | `AT-OÖ` | `Oberösterreich` | `ACTIVE` |

Diese Region enthaelt beide Filialen.

### 4.2 Filialen

| Store-ID | Store-Code | Name | Ort | Status |
|---|---|---|---|---|
| `ad61389a-7486-48fa-afa2-9b5e4132f6a8` | `SPAR-Leonding-001` | `Eurospar Poststraße` | `Leonding` | `ACTIVE` |
| `0b1e94e5-75cb-48e5-a271-b5cbd209fddd` | `Spar-Hörsching-001` | `Spar-Hörsching` | `Hörsching` | `ACTIVE` |

### 4.3 Beacons

| Beacon-ID | Code | UUID | Major | Minor | Status |
|---|---|---|---:|---:|---|
| `7e9a1bcc-fdf0-4b58-b1de-8977fbdd95ba` | `IndooroTest1` | `123e4567-e89b-12d3-a456-426614174000` | 1 | 1 | `ARCHIVED` |
| `837b4188-beba-4681-9c8e-05f17b74fb68` | `DemoBeaconX1` | `6f1a7f7e-1c44-4d8f-9a7e-8b9a4a2d1c11` | 1 | 101 | `ACTIVE` |
| `d519049e-9862-4a06-bfca-2f4bfb253827` | `DemoBeaconX2` | `6f1a7f7e-1c44-4d8f-9a7e-8b9a4a2d1c12` | 1 | 102 | `ACTIVE` |
| `c8f6e9ad-656a-401d-a8ac-a0b9a8d93f2f` | `DemoBeaconX3` | `6f1a7f7e-1c44-4d8f-9a7e-8b9a4a2d1c13` | 2 | 201 | `ACTIVE` |

### 4.4 Aktive Beacon-Zuordnungen

Aktuell sind drei Beacons aktiv der Filiale `SPAR-Leonding-001` zugeordnet.

| Assignment-ID | Beacon | Filiale | Aktiv |
|---|---|---|---|
| `f11eb49b-d946-4605-9b8d-18d601f37f95` | `DemoBeaconX1` | `SPAR-Leonding-001` | `true` |
| `f75bed6e-90a2-431c-8781-3d4d5143e8a3` | `DemoBeaconX2` | `SPAR-Leonding-001` | `true` |
| `5f8b1f22-249f-418b-a870-d95e5cedf8c3` | `DemoBeaconX3` | `SPAR-Leonding-001` | `true` |

### 4.5 Layout-Version

Aktuell gibt es eine gespeicherte store-spezifische Layout-Version.

| Layout-ID | Store-Code | Version | Status | Shop-Name | Elemente |
|---|---|---:|---|---|---:|
| `f2fa5b31-5c9c-4066-acf3-70fe2157fa83` | `Spar-Hörsching-001` | 1 | `ACTIVE` | `Spar-Hörsching` | 39 |

Wichtig: Die aktive Layout-Version gehoert aktuell zur Filiale `Spar-Hörsching-001`, waehrend die aktiven Beacons aktuell der Filiale `SPAR-Leonding-001` zugeordnet sind. Das ist technisch erlaubt, bedeutet aber fachlich, dass die aktuell gespeicherten Beacon-Zuordnungen und das aktuell gespeicherte Layout auf unterschiedliche Filialen zeigen.

## 5. Audit- und Fehlerobjekte

### 5.1 Letzte Audit-Logs

Die neuesten Audit-Objekte zeigen vor allem Beacon-Zuordnungen und Layout-Aktivierung.

```mermaid
classDiagram
    direction TB

    class audit_764e36f9 {
        <<AuditLog>>
        id = 764e36f9-8f2e-49c7-a055-29f7c3db831a
        entityType = BEACON
        entityId = c8f6e9ad-656a-401d-a8ac-a0b9a8d93f2f
        action = ASSIGN
        summary = Beacon einer Filiale zugeordnet
        actor = SYSTEM / system
        createdAt = 2026-04-08 08:54:34 UTC
    }

    class audit_62828dd1 {
        <<AuditLog>>
        id = 62828dd1-5bdd-4e7b-86f3-1bfd2411710e
        entityType = BEACON
        entityId = d519049e-9862-4a06-bfca-2f4bfb253827
        action = ASSIGN
        summary = Beacon einer Filiale zugeordnet
        actor = SYSTEM / system
        createdAt = 2026-04-08 08:54:32 UTC
    }

    class audit_226c09dd {
        <<AuditLog>>
        id = 226c09dd-53b2-46ef-914a-4006fba6f9b9
        entityType = BEACON
        entityId = 837b4188-beba-4681-9c8e-05f17b74fb68
        action = ASSIGN
        summary = Beacon einer Filiale zugeordnet
        actor = SYSTEM / system
        createdAt = 2026-04-08 08:54:29 UTC
    }

    audit_764e36f9 --> beacon_c8f6e9ad : references entityId
    audit_62828dd1 --> beacon_d519049e : references entityId
    audit_226c09dd --> beacon_837b4188 : references entityId
```

### 5.2 Fehlerlog-Objekt

Aktuell existiert ein Fehlerlog-Eintrag.

```mermaid
classDiagram
    class error_d5443fd6 {
        <<ErrorLog>>
        id = d5443fd6-2517-458b-9c3a-632b4412c7ef
        statusCode = 400
        method = POST
        path = /api/beacons
        message = Major und Minor muessen entweder beide gesetzt oder beide leer sein.
        errorType = jakarta.ws.rs.WebApplicationException
        createdAt = 2026-04-08 09:06:23 UTC
    }
```

Dieser Fehler entstand durch einen Beacon-Create-Request, bei dem `major` gesetzt war, aber `minor` fehlte.

## 6. Fachliche Aussage des Laufzeitdiagramms

Der aktuelle Laufzeitstand sagt fachlich:

1. Es gibt eine aktive Region `Oberösterreich`.
2. Diese Region verwaltet zwei aktive Filialen.
3. Es gibt vier Beacon-Objekte.
4. Drei Beacons sind aktiv und einer ist archiviert.
5. Alle drei aktiven Beacons sind aktuell `SPAR-Leonding-001` zugeordnet.
6. Eine aktive Layout-Version existiert aktuell fuer `Spar-Hörsching-001`.
7. Audit-Logs dokumentieren die letzten erfolgreichen Aktionen.
8. Error-Logs dokumentieren fehlgeschlagene API-Requests.

## 7. Relevante SQL-Abfragen

Diese Abfragen wurden genutzt, um die Werte fuer dieses Dokument zu bestimmen.

```sql
select 'regions' as table_name, count(*) from regions
union all select 'stores', count(*) from stores
union all select 'beacons', count(*) from beacons
union all select 'beacon_assignments', count(*) from beacon_assignments
union all select 'layout_versions', count(*) from layout_versions
union all select 'audit_logs', count(*) from audit_logs
union all select 'error_logs', count(*) from error_logs;
```

```sql
select id, code, name, status, created_at
from regions
order by created_at;
```

```sql
select id, region_id, store_code, name, street, zip_code, city, country, status, archived_at, created_at
from stores
order by created_at;
```

```sql
select id, beacon_code, identity_key, uuid, major, minor, status, notes, created_at
from beacons
order by created_at;
```

```sql
select ba.id, b.beacon_code, ba.beacon_id, s.store_code, ba.store_id, ba.assigned_at, ba.released_at, ba.is_active
from beacon_assignments ba
join beacons b on b.id = ba.beacon_id
join stores s on s.id = ba.store_id
order by ba.assigned_at;
```

```sql
select lv.id, s.store_code, lv.store_id, lv.version_no, lv.layout_name, lv.status,
       lv.activated_at, lv.created_at,
       jsonb_array_length(coalesce(lv.layout_json->'elements','[]'::jsonb)) as element_count,
       lv.layout_json->>'shopName' as shop_name
from layout_versions lv
join stores s on s.id = lv.store_id
order by lv.created_at;
```
