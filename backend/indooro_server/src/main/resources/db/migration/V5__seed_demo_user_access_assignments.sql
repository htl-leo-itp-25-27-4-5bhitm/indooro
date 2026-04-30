INSERT INTO user_access_assignments (
    id,
    keycloak_subject,
    username,
    email,
    role,
    region_id,
    store_id,
    status,
    created_at,
    updated_at
)
SELECT
    '00000000-0000-0000-0000-000000000102',
    '22222222-2222-2222-2222-222222222222',
    'indooro-region',
    'region@indooro.local',
    'region-manager',
    r.id,
    NULL,
    'ACTIVE',
    NOW(),
    NOW()
FROM regions r
WHERE r.name = 'Oberösterreich'
ON CONFLICT DO NOTHING;

INSERT INTO user_access_assignments (
    id,
    keycloak_subject,
    username,
    email,
    role,
    region_id,
    store_id,
    status,
    created_at,
    updated_at
)
SELECT
    '00000000-0000-0000-0000-000000000103',
    '33333333-3333-3333-3333-333333333333',
    'indooro-store',
    'store@indooro.local',
    'store-manager',
    NULL,
    s.id,
    'ACTIVE',
    NOW(),
    NOW()
FROM stores s
WHERE s.store_code = 'SPAR-Leonding-001'
ON CONFLICT DO NOTHING;
