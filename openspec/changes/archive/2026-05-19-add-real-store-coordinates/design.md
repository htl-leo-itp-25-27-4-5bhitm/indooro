# Design: Add Real Store Coordinates

## Backend
The existing `stores` table already stores address components (`street`, `zip_code`, `city`, `country`), so no separate `address` column is introduced. Mobile responses expose a formatted `address` string derived from those fields.

Latitude and longitude are nullable because existing or future stores may be created before exact coordinates are known. The mobile map must not invent locations for such stores.

## Database
A new Flyway migration adds:
- `stores.latitude DOUBLE PRECISION`
- `stores.longitude DOUBLE PRECISION`
- range checks for latitude and longitude
- targeted updates for the three known store records

The migration updates by UUID or store code so it works against LeoCloud/demo state even if one identifier has drifted.

## API
`MobileStoreSummary` includes `address`, `latitude`, and `longitude`. `GET /api/mobile/stores/by-beacon` reuses the same summary, so beacon-resolved store context receives the same fields without changing the route shape.

## Admin
Store create/update DTOs accept optional coordinates and validate ranges. The Admin Platform form includes optional latitude/longitude fields so future stores can be maintained without direct SQL.

## iOS
The final app path is `swift/indooro-`. It does not currently contain the named `MobileStoreModels.swift` or `StoreMapPage.swift`, so this change adds those files and integrates the page into the existing `ContentView` toolbar.

The store map uses MapKit pins only for stores with valid persisted coordinates. There is no city-based or deterministic coordinate fallback. Manual store selection calls the store-specific mobile layout route. Beacon/in-store navigation remains in `BeaconManager`.
