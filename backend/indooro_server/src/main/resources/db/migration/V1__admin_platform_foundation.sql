CREATE TABLE regions (
    id UUID PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT ck_regions_status CHECK (status IN ('ACTIVE', 'ARCHIVED'))
);

CREATE TABLE stores (
    id UUID PRIMARY KEY,
    region_id UUID NOT NULL REFERENCES regions(id),
    store_code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    street VARCHAR(150) NOT NULL,
    zip_code VARCHAR(20) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    notes TEXT,
    status VARCHAR(20) NOT NULL,
    archived_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT ck_stores_status CHECK (status IN ('ACTIVE', 'ARCHIVED'))
);

CREATE TABLE beacons (
    id UUID PRIMARY KEY,
    beacon_code VARCHAR(60) NOT NULL UNIQUE,
    identity_key VARCHAR(140) NOT NULL UNIQUE,
    uuid UUID NOT NULL,
    major INTEGER,
    minor INTEGER,
    notes TEXT,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT ck_beacons_status CHECK (status IN ('ACTIVE', 'ARCHIVED'))
);

CREATE TABLE beacon_assignments (
    id UUID PRIMARY KEY,
    beacon_id UUID NOT NULL REFERENCES beacons(id),
    store_id UUID NOT NULL REFERENCES stores(id),
    assigned_at TIMESTAMPTZ NOT NULL,
    released_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE layout_versions (
    id UUID PRIMARY KEY,
    store_id UUID NOT NULL REFERENCES stores(id),
    version_no INTEGER NOT NULL,
    layout_name VARCHAR(150),
    layout_json JSONB NOT NULL,
    status VARCHAR(20) NOT NULL,
    change_note TEXT,
    created_by_role VARCHAR(40),
    created_by_label VARCHAR(120),
    activated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT ck_layout_versions_status CHECK (status IN ('DRAFT', 'ACTIVE', 'ARCHIVED')),
    CONSTRAINT uk_layout_version_store_no UNIQUE (store_id, version_no)
);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY,
    entity_type VARCHAR(40) NOT NULL,
    entity_id UUID NOT NULL,
    action VARCHAR(40) NOT NULL,
    actor_role VARCHAR(40),
    actor_label VARCHAR(120),
    summary TEXT,
    before_json JSONB,
    after_json JSONB,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_stores_region_status ON stores(region_id, status);
CREATE INDEX idx_beacon_assignments_store_active ON beacon_assignments(store_id, is_active);
CREATE INDEX idx_layout_versions_store_status_created ON layout_versions(store_id, status, created_at DESC);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id, created_at DESC);

CREATE UNIQUE INDEX uk_beacon_active_assignment ON beacon_assignments(beacon_id) WHERE is_active = TRUE;
CREATE UNIQUE INDEX uk_store_active_layout ON layout_versions(store_id) WHERE status = 'ACTIVE';
