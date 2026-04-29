CREATE TABLE user_access_assignments (
    id UUID PRIMARY KEY,
    keycloak_subject VARCHAR(120) NOT NULL,
    username VARCHAR(120) NOT NULL,
    email VARCHAR(254),
    role VARCHAR(40) NOT NULL,
    region_id UUID REFERENCES regions(id),
    store_id UUID REFERENCES stores(id),
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT ck_user_access_role CHECK (role IN ('admin', 'region-manager', 'store-manager')),
    CONSTRAINT ck_user_access_status CHECK (status IN ('ACTIVE', 'DISABLED')),
    CONSTRAINT ck_user_access_scope CHECK (
        (role = 'admin' AND region_id IS NULL AND store_id IS NULL)
        OR (role = 'region-manager' AND region_id IS NOT NULL AND store_id IS NULL)
        OR (role = 'store-manager' AND store_id IS NOT NULL)
    )
);

CREATE UNIQUE INDEX uk_user_access_active_subject
    ON user_access_assignments(keycloak_subject)
    WHERE status = 'ACTIVE';

CREATE INDEX idx_user_access_region_status ON user_access_assignments(region_id, status);
CREATE INDEX idx_user_access_store_status ON user_access_assignments(store_id, status);

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
) VALUES (
    '00000000-0000-0000-0000-000000000101',
    '11111111-1111-1111-1111-111111111111',
    'indooro-admin',
    'admin@indooro.local',
    'admin',
    NULL,
    NULL,
    'ACTIVE',
    NOW(),
    NOW()
);
