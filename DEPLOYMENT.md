# Indooro Deployment

Stand: 2026-04-08

Dieses Dokument beschreibt den aktuellen LeoCloud-Stand von Indooro und den Weg, wie das Backend unter `https://it220209.cloud.htl-leonding.ac.at/` erreichbar gemacht wird.

## LeoCloud Kontext

- Kubernetes Context: `leocloud`
- Namespace: `student-it220209`
- Benutzer: `it220209`
- Gewuenschter Hostname: `it220209.cloud.htl-leonding.ac.at`

## Aktueller Live-Stand

Im Cluster laufen aktuell diese Deployments:

- `indooro-backend`
- `opensearch`
- `dashboards`
- `postgres`

Im Namespace `student-it220209` wurde der `Ingress` `indooro-backend-ingress` erfolgreich angelegt. Der Test auf `/api/admin/health` liefert bereits `{"status":"UP"}`.

Das bedeutet:

- das Backend ist jetzt ueber die LeoCloud-URL erreichbar
- fuer die App und externe Clients soll ab jetzt die URL `https://it220209.cloud.htl-leonding.ac.at/` verwendet werden
- die Web-Oberflaechen werden jetzt ebenfalls ueber dasselbe Backend ausgeliefert

## Wichtige Repo-Dateien

- `k8s/opensearch.yaml`
- `k8s/postgres.yaml`
- `k8s/backend.yaml`
- `backend/indooro_server/.mvn/jvm.config`
- `.github/workflows/ci.yaml`
- `backend/indooro_server/build.sh`

## Was aktuell zusammenpasst

- Das Backend-Image im Cluster ist `ghcr.io/htl-leo-itp-25-27-4-5bhitm/indooro-backend-v2:latest`
- Die GitHub Action baut ebenfalls `.../indooro-backend-v2`
- `k8s/backend.yaml` zeigt ebenfalls auf `.../indooro-backend-v2:latest`
- Das Backend spricht in Production intern mit dem Kubernetes-Service `opensearch`
- Das Admin-Datenmodell nutzt PostgreSQL ueber den internen Kubernetes-Service `postgres`

## Was aktuell nicht sauber zusammenpasst

- `backend/indooro_server/build.sh` pusht noch `ghcr.io/htl-leo-itp-25-27-4-5bhitm/indooro-backend:latest` ohne `-v2`
- `k8s/volume-claim.yaml` ist sehr wahrscheinlich ein alter Rest, weil `k8s/opensearch.yaml` bereits den aktuell verwendeten PVC `opensearch-data` enthaelt
- `build.sh` kennt den neuen PostgreSQL-/Admin-Stack noch nicht explizit, auch wenn das Quarkus-Backend jetzt darauf vorbereitet ist

## Wie das Deployment aktuell funktioniert

### 1. Backend Image bauen und pushen

Bei einem Push auf `main` oder `master` baut GitHub Actions automatisch das Backend-Image und pusht es nach GHCR.

Relevant ist:

- Workflow: `.github/workflows/ci.yaml`
- Ziel-Image: `ghcr.io/htl-leo-itp-25-27-4-5bhitm/indooro-backend-v2:latest`

### 2. Kubernetes Manifeste anwenden

Die bestehenden Manifeste werden im Namespace `student-it220209` angewendet:

```bash
kubectl apply -n student-it220209 -f k8s/postgres.yaml
kubectl apply -n student-it220209 -f k8s/opensearch.yaml
kubectl apply -n student-it220209 -f k8s/backend.yaml
```

Wenn das Image mit dem Tag `latest` neu gebaut wurde, ist oft noch ein Rollout noetig:

```bash
kubectl rollout restart deployment/indooro-backend -n student-it220209
```

## Wie die URL ueber LeoCloud funktioniert

Bei der anderen Projektgruppe wurde die URL nicht direkt ueber `NodePort` verwendet, sondern ueber ein `Ingress`.

Das Muster war:

- Host: `it22....cloud.htl-leonding.ac.at`
- `Ingress` mit `ingressClassName: nginx`
- Weiterleitung auf einen internen Service

Fuer Indooro bedeutet das:

- Host: `it220209.cloud.htl-leonding.ac.at`
- Ziel-Service: `indooro-backend`
- Ziel-Port: `8080`

## Empfohlenes Ingress fuer Indooro

Die Datei liegt bereits unter `k8s/backend-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: indooro-backend-ingress
spec:
  ingressClassName: nginx
  rules:
    - host: it220209.cloud.htl-leonding.ac.at
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: indooro-backend
                port:
                  number: 8080
```

Anwenden mit:

```bash
kubectl apply -n student-it220209 -f k8s/backend-ingress.yaml
```

## Welche URL danach gelten sollte

Wenn das `Ingress` aktiv ist, sollte das Backend unter diesen URLs erreichbar sein:

- `https://it220209.cloud.htl-leonding.ac.at/api/admin/health`
- `https://it220209.cloud.htl-leonding.ac.at/api/products`
- `https://it220209.cloud.htl-leonding.ac.at/api/products/search?q=test`

Wichtig: Das Backend selbst hat seine Endpunkte bereits unter `/api/...`, daher reicht im `Ingress` der Pfad `/`.

## Gehostete Web-Oberflaechen

Die statischen Seiten werden jetzt direkt vom Quarkus-Backend ausgeliefert. Dadurch braucht es in LeoCloud keinen extra Web-Container fuer Admin oder Kundenseite.

Diese Pfade sind vorgesehen:

- `https://it220209.cloud.htl-leonding.ac.at/` fuer die Startseite mit Auswahl
- `https://it220209.cloud.htl-leonding.ac.at/admin/` fuer den Admin-Editor
- `https://it220209.cloud.htl-leonding.ac.at/customer/` fuer die Kundensuche

## Layout am Server speichern

Der Admin-Editor exportiert das Layout jetzt nicht nur als Download, sondern speichert es auch serverseitig.

Dafuer gibt es diese API:

- `GET /api/layout/current`
- `POST /api/layout/current`

Damit koennen diese Clients dasselbe Layout verwenden:

- der Admin-Editor
- die gehostete Kundensuche
- die Swift-App

## Neue Admin-Plattform Grundlage

Das Backend hat jetzt zusaetzlich eine relationale Grundlage fuer die neue Admin-Plattform:

- `regions`
- `stores`
- `beacons`
- `beacon_assignments`
- `layout_versions`
- `audit_logs`

Die Datenbank-Migration liegt unter:

- `backend/indooro_server/src/main/resources/db/migration/V1__admin_platform_foundation.sql`

Neue REST-Endpunkte wurden fuer den Sprint vorbereitet:

- `/api/regions`
- `/api/stores`
- `/api/beacons`
- `/api/stores/{storeId}/layout/...`
- `/api/mobile/stores/...`

Damit ist die Grundlage fuer:

- Filialverwaltung
- Beacon-Verwaltung
- filialspezifische Layouts
- spaetere iOS-Filialerkennung per Beacon

bereits im Backend angelegt.

## Produktdaten importieren

Damit die App Produkte anzeigen kann, muss der OpenSearch-Index auch wirklich mit Daten befuellt sein.

Aktuell ist das Deployment erreichbar, aber ein laufendes Backend allein bedeutet noch nicht, dass schon Produktdaten im Index liegen.

Im Repo liegt eine passende JSON-Datei:

- `backend/indooro_server/belegplan.json`

Falls der Index leer oder fast leer ist, koennt ihr ihn mit dieser Datei befuellen:

```bash
curl -X POST https://it220209.cloud.htl-leonding.ac.at/api/products/bulk \
  -H "Content-Type: application/json" \
  --data @backend/indooro_server/belegplan.json
```

Danach testen mit:

```bash
curl https://it220209.cloud.htl-leonding.ac.at/api/products?size=20
```

Wenn dort viele Produkte zurueckkommen, sollte die Xcode-App ebenfalls Daten anzeigen.

## Xcode App auf die URL umstellen

In der iOS-App steht aktuell noch `http://localhost:8080/api` in `swift/indooroApp/indooroApp/Managers/BeaconManager.swift`.

Fuer den Zugriff auf die LeoCloud-Instanz muss dort diese Base-URL verwendet werden:

```swift
private let apiBase = "https://it220209.cloud.htl-leonding.ac.at/api"
```

Danach spricht die App direkt mit dem Backend in der LeoCloud.

## Wichtiger Hinweis zum Service-Typ

Aktuell ist `indooro-backend` in `k8s/backend.yaml` als `NodePort` definiert.

Das kann fuer den bestehenden Stand bleiben. Fuer einen sauberen `Ingress`-Betrieb ist aber langfristig `ClusterIP` meist die bessere Wahl, weil:

- der externe Zugriff dann ueber das `Ingress` laeuft
- der Service intern bleibt
- die URL nicht von NodePorts abhaengt

## Praktische Reihenfolge fuer euch

Wenn ihr das heute neu oder sauber aufsetzen wollt:

1. Backend-Code auf `main` pushen
2. Warten, bis GitHub Actions das Image `indooro-backend-v2:latest` gebaut hat
3. `kubectl apply -n student-it220209 -f k8s/postgres.yaml`
4. `kubectl apply -n student-it220209 -f k8s/opensearch.yaml`
5. `kubectl apply -n student-it220209 -f k8s/backend.yaml`
6. `kubectl apply -n student-it220209 -f k8s/backend-ingress.yaml`
7. Falls noetig: `kubectl rollout restart deployment/indooro-backend -n student-it220209`
8. Testen: `https://it220209.cloud.htl-leonding.ac.at/api/admin/health`

## Build-Hinweis fuer Java 24

Auf diesem Projekt laeuft Quarkus 3.6 aktuell nicht sauber auf Java 24 ohne Byte-Buddy-Flag.
Damit `sh mvnw package` lokal trotzdem funktioniert, liegt jetzt diese Datei im Repo:

- `backend/indooro_server/.mvn/jvm.config`

mit folgendem Inhalt:

```text
-Dnet.bytebuddy.experimental=true
```

Dadurch koennen lokale Builds auf neueren JDKs laufen, ohne dass bei jedem Aufruf manuell `MAVEN_OPTS` gesetzt werden muss.

## Muss man das jedes Mal machen

Nein, nicht alles.

Einmalig oder nur selten:

- `kubectl apply -n student-it220209 -f k8s/backend-ingress.yaml`
- nur wenn ihr den Host, den Namen oder die Ingress-Regeln aendert

Bei Backend-Code-Aenderungen:

- Code committen und auf `main` pushen
- GitHub Actions baut das Backend-Image automatisch neu und pusht es nach GHCR

Was oft trotzdem noch noetig ist:

- `kubectl rollout restart deployment/indooro-backend -n student-it220209`

Der Grund ist das Image-Tag `latest`. Das neue Image wird zwar gebaut, aber der laufende Pod wird nicht immer automatisch neu erstellt.

Wenn ihr spaeter ein saubereres Deployment wollt, solltet ihr statt `latest` mit festen Versionen oder SHA-Tags arbeiten.

Bei Daten-Aenderungen:

- Produktdaten werden nicht automatisch aus dem Repo in OpenSearch geladen
- wenn ihr neue oder andere Produktdaten wollt, muesst ihr sie aktiv importieren
- das betrifft die Datei `belegplan.json` oder andere Importquellen

## Offene Punkte

- `postgres` sollte ins Repo uebernommen werden, wenn es wirklich zu Indooro gehoert
- `build.sh` sollte auf `indooro-backend-v2` umgestellt werden
- `k8s/volume-claim.yaml` kann wahrscheinlich entfernt werden, wenn es wirklich nur ein Altbestand ist
