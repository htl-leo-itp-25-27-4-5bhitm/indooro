ALTER TABLE beacons
    ALTER COLUMN uuid TYPE VARCHAR(32)
    USING replace(lower(uuid::text), '-', '');

UPDATE beacons
SET uuid = replace(lower(uuid), '-', ''),
    identity_key = CASE
        WHEN major IS NOT NULL AND minor IS NOT NULL
            THEN replace(lower(uuid), '-', '') || ':' || major || ':' || minor
        ELSE replace(lower(uuid), '-', '')
    END;
