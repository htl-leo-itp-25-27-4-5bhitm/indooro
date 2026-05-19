# Change: Add Real Store Coordinates

## Why
The final mobile user app must place selectable stores on the outdoor store map using real persisted coordinates. The current system exposes mobile store summaries without latitude/longitude, which forces clients to invent positions from city names or deterministic offsets. That is not acceptable for production store selection.

## What Changes
- Add latitude and longitude to the store domain model and database schema.
- Seed real coordinates for the known Leonding, Hagenberg, and Hoersching demo stores.
- Return address and coordinates from `GET /api/mobile/stores` and beacon-based store lookup responses.
- Add latitude/longitude to admin store DTOs and form flows with validation.
- Update the iOS app so store-map pins are rendered only from real coordinates and stores without coordinates are omitted from the map.
- Preserve store layout loading, beacon detection behavior, and in-store tap interactions.

## Impact
- Affects PostgreSQL migrations, backend store entity/DTOs/services, Admin Platform store forms, mobile API response contract, and the final SwiftUI user app under `swift/indooro-`.
- Existing mobile routes remain anonymous.
- Existing beacon and layout routes must keep their current behavior.
