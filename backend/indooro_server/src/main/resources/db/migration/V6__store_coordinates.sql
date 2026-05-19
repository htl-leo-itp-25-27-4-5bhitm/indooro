ALTER TABLE stores
    ADD COLUMN latitude DOUBLE PRECISION,
    ADD COLUMN longitude DOUBLE PRECISION;

ALTER TABLE stores
    ADD CONSTRAINT ck_stores_latitude_range
        CHECK (latitude IS NULL OR (latitude >= -90 AND latitude <= 90)),
    ADD CONSTRAINT ck_stores_longitude_range
        CHECK (longitude IS NULL OR (longitude >= -180 AND longitude <= 180));

UPDATE stores
SET latitude = 48.2680495,
    longitude = 14.2618747,
    street = 'Poststraße 10',
    zip_code = '4060',
    city = 'Leonding',
    name = 'EUROSPAR Leonding/Hart',
    updated_at = NOW()
WHERE id = 'ad61389a-7486-48fa-afa2-9b5e4132f6a8'
   OR store_code = 'SPAR-Leonding-001';

UPDATE stores
SET latitude = 48.3665000,
    longitude = 14.5206688,
    street = 'Hauptstraße 69',
    zip_code = '4232',
    city = 'Hagenberg im Mühlkreis',
    name = 'SPAR Speychal Hagenberg',
    updated_at = NOW()
WHERE id = '8c45864d-5041-4b07-aca0-2405db5a2ca7'
   OR store_code = 'HA-01';

UPDATE stores
SET latitude = 48.2230684,
    longitude = 14.1783480,
    street = 'Humerstraße 16',
    zip_code = '4063',
    city = 'Hörsching',
    name = 'EUROSPAR Mayrhuber Hörsching',
    updated_at = NOW()
WHERE id = '0b1e94e5-75cb-48e5-a271-b5cbd209fddd'
   OR store_code = 'Spar-Hörsching-001';
