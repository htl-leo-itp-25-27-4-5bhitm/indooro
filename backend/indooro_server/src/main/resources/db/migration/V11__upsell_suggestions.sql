CREATE TABLE upsell_suggestion_cache (
    id UUID PRIMARY KEY,
    checked_product_id INTEGER NOT NULL,
    store_id UUID,
    store_code VARCHAR(50),
    context_hash VARCHAR(128) NOT NULL,
    response_json TEXT NOT NULL,
    source VARCHAR(40) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT uk_upsell_suggestion_cache_context UNIQUE (context_hash)
);

CREATE INDEX idx_upsell_suggestion_cache_lookup
    ON upsell_suggestion_cache (checked_product_id, store_id, store_code, expires_at);

CREATE TABLE upsell_events (
    id UUID PRIMARY KEY,
    event_type VARCHAR(40) NOT NULL,
    checked_product_id INTEGER,
    suggested_product_id INTEGER,
    store_id UUID,
    store_code VARCHAR(50),
    session_hash VARCHAR(128),
    source VARCHAR(40),
    metadata_json TEXT,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_upsell_events_product_created
    ON upsell_events (checked_product_id, created_at DESC);

CREATE TABLE upsell_dismissals (
    id UUID PRIMARY KEY,
    checked_product_id INTEGER NOT NULL,
    suggested_product_id INTEGER,
    store_id UUID,
    store_code VARCHAR(50),
    session_hash VARCHAR(128),
    dismissal_count INTEGER NOT NULL DEFAULT 1,
    suppressed_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT ck_upsell_dismissals_count CHECK (dismissal_count > 0)
);

CREATE INDEX idx_upsell_dismissals_lookup
    ON upsell_dismissals (checked_product_id, suggested_product_id, store_id, session_hash);
