CREATE TABLE units (
    code VARCHAR(20) PRIMARY KEY,
    display_name VARCHAR(60) NOT NULL,
    unit_kind VARCHAR(20) NOT NULL,
    gram_factor NUMERIC(12,6),
    milliliter_factor NUMERIC(12,6),
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_units_status CHECK (status IN ('ACTIVE', 'ARCHIVED')),
    CONSTRAINT ck_units_kind CHECK (unit_kind IN ('MASS', 'VOLUME', 'COUNT', 'SPOON', 'PINCH', 'TEXT'))
);

CREATE TABLE recipes (
    id UUID PRIMARY KEY,
    slug VARCHAR(140) NOT NULL UNIQUE,
    title VARCHAR(180) NOT NULL,
    summary TEXT,
    description TEXT,
    image_url TEXT,
    image_alt VARCHAR(240),
    servings INTEGER NOT NULL,
    prep_time_minutes INTEGER,
    cook_time_minutes INTEGER,
    total_time_minutes INTEGER,
    status VARCHAR(20) NOT NULL,
    published_at TIMESTAMPTZ,
    archived_at TIMESTAMPTZ,
    created_by_role VARCHAR(40),
    created_by_label VARCHAR(120),
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT ck_recipes_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'ARCHIVED')),
    CONSTRAINT ck_recipes_servings CHECK (servings > 0),
    CONSTRAINT ck_recipes_prep_time CHECK (prep_time_minutes IS NULL OR prep_time_minutes >= 0),
    CONSTRAINT ck_recipes_cook_time CHECK (cook_time_minutes IS NULL OR cook_time_minutes >= 0),
    CONSTRAINT ck_recipes_total_time CHECK (total_time_minutes IS NULL OR total_time_minutes >= 0)
);

CREATE TABLE recipe_ingredients (
    id UUID PRIMARY KEY,
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    display_name VARCHAR(180) NOT NULL,
    canonical_name VARCHAR(180),
    quantity NUMERIC(12,3),
    quantity_text VARCHAR(80),
    unit_code VARCHAR(20) REFERENCES units(code) ON DELETE SET NULL,
    preparation_note TEXT,
    is_optional BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT uk_recipe_ingredients_position UNIQUE (recipe_id, position),
    CONSTRAINT ck_recipe_ingredients_position CHECK (position > 0)
);

CREATE TABLE recipe_steps (
    id UUID PRIMARY KEY,
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    instruction TEXT NOT NULL,
    duration_minutes INTEGER,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT uk_recipe_steps_position UNIQUE (recipe_id, position),
    CONSTRAINT ck_recipe_steps_position CHECK (position > 0),
    CONSTRAINT ck_recipe_steps_duration CHECK (duration_minutes IS NULL OR duration_minutes >= 0)
);

CREATE TABLE recipe_tags (
    id UUID PRIMARY KEY,
    code VARCHAR(80) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    kind VARCHAR(40),
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT ck_recipe_tags_status CHECK (status IN ('ACTIVE', 'ARCHIVED'))
);

CREATE TABLE recipe_tag_assignments (
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES recipe_tags(id) ON DELETE CASCADE,
    PRIMARY KEY (recipe_id, tag_id)
);

CREATE TABLE ingredient_product_mappings (
    id UUID PRIMARY KEY,
    recipe_ingredient_id UUID REFERENCES recipe_ingredients(id) ON DELETE CASCADE,
    canonical_name VARCHAR(180),
    store_id UUID REFERENCES stores(id) ON DELETE SET NULL,
    store_code VARCHAR(50),
    product_id INTEGER NOT NULL,
    product_name_snapshot VARCHAR(240),
    layout_code_snapshot VARCHAR(80),
    mapping_type VARCHAR(30) NOT NULL,
    confidence NUMERIC(4,3),
    manually_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT ck_ingredient_product_mappings_status CHECK (status IN ('ACTIVE', 'ARCHIVED')),
    CONSTRAINT ck_ingredient_product_mappings_type CHECK (mapping_type IN ('EXACT', 'CATEGORY', 'SYNONYM', 'MANUAL')),
    CONSTRAINT ck_ingredient_product_mappings_confidence CHECK (confidence IS NULL OR (confidence >= 0 AND confidence <= 1)),
    CONSTRAINT ck_ingredient_product_mappings_scope CHECK (recipe_ingredient_id IS NOT NULL OR canonical_name IS NOT NULL)
);

CREATE TABLE ingredient_synonyms (
    id UUID PRIMARY KEY,
    canonical_name VARCHAR(180) NOT NULL,
    synonym VARCHAR(180) NOT NULL,
    locale VARCHAR(12) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT uk_ingredient_synonyms_locale_synonym UNIQUE (locale, synonym),
    CONSTRAINT ck_ingredient_synonyms_status CHECK (status IN ('ACTIVE', 'ARCHIVED'))
);

CREATE INDEX idx_recipes_status_title ON recipes(status, lower(title));
CREATE INDEX idx_recipes_published_at ON recipes(status, published_at DESC);
CREATE INDEX idx_recipe_ingredients_recipe_position ON recipe_ingredients(recipe_id, position);
CREATE INDEX idx_recipe_ingredients_canonical ON recipe_ingredients(lower(canonical_name));
CREATE INDEX idx_recipe_steps_recipe_position ON recipe_steps(recipe_id, position);
CREATE INDEX idx_recipe_tags_status_name ON recipe_tags(status, lower(name));
CREATE INDEX idx_ingredient_mappings_ingredient_status ON ingredient_product_mappings(recipe_ingredient_id, status);
CREATE INDEX idx_ingredient_mappings_canonical_status ON ingredient_product_mappings(lower(canonical_name), status);
CREATE INDEX idx_ingredient_mappings_store_status ON ingredient_product_mappings(store_id, status);
CREATE INDEX idx_ingredient_mappings_product ON ingredient_product_mappings(product_id);
CREATE INDEX idx_ingredient_synonyms_canonical ON ingredient_synonyms(lower(canonical_name), status);

CREATE UNIQUE INDEX uk_active_recipe_ingredient_product_mapping
    ON ingredient_product_mappings(
        recipe_ingredient_id,
        COALESCE(store_id, '00000000-0000-0000-0000-000000000000'::uuid),
        product_id
    )
    WHERE status = 'ACTIVE' AND recipe_ingredient_id IS NOT NULL;

CREATE UNIQUE INDEX uk_active_canonical_product_mapping
    ON ingredient_product_mappings(
        lower(canonical_name),
        COALESCE(store_id, '00000000-0000-0000-0000-000000000000'::uuid),
        product_id
    )
    WHERE status = 'ACTIVE' AND canonical_name IS NOT NULL;

INSERT INTO units (code, display_name, unit_kind, gram_factor, milliliter_factor, status) VALUES
    ('g', 'Gramm', 'MASS', 1, NULL, 'ACTIVE'),
    ('kg', 'Kilogramm', 'MASS', 1000, NULL, 'ACTIVE'),
    ('ml', 'Milliliter', 'VOLUME', NULL, 1, 'ACTIVE'),
    ('l', 'Liter', 'VOLUME', NULL, 1000, 'ACTIVE'),
    ('piece', 'Stueck', 'COUNT', NULL, NULL, 'ACTIVE'),
    ('pinch', 'Prise', 'PINCH', NULL, NULL, 'ACTIVE'),
    ('tbsp', 'EL', 'SPOON', NULL, NULL, 'ACTIVE'),
    ('tsp', 'TL', 'SPOON', NULL, NULL, 'ACTIVE');

INSERT INTO recipe_tags (id, code, name, kind, status, created_at, updated_at) VALUES
    ('00000000-0000-0000-0000-000000000201', 'quick', 'Schnell', 'time', 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000202', 'vegetarian', 'Vegetarisch', 'diet', 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000203', 'family', 'Familie', 'occasion', 'ACTIVE', NOW(), NOW());

INSERT INTO recipes (
    id, slug, title, summary, description, image_url, image_alt, servings,
    prep_time_minutes, cook_time_minutes, total_time_minutes, status,
    published_at, created_by_role, created_by_label, created_at, updated_at
) VALUES
    (
        '00000000-0000-0000-0000-000000000101',
        'tomaten-pasta',
        'Tomaten-Pasta',
        'Schnelle Pasta mit Tomaten und Parmesan.',
        'Eine einfache Tomaten-Pasta fuer den schnellen Einkauf nach der Arbeit.',
        NULL,
        NULL,
        2,
        10,
        15,
        25,
        'PUBLISHED',
        NOW(),
        'SYSTEM',
        'seed',
        NOW(),
        NOW()
    ),
    (
        '00000000-0000-0000-0000-000000000102',
        'fruehstuecks-muesli',
        'Fruehstuecks-Muesli',
        'Muesli mit Joghurt, Banane und Honig.',
        'Ein schneller Fruehstuecksplan mit frischen und haltbaren Zutaten.',
        NULL,
        NULL,
        2,
        8,
        0,
        8,
        'PUBLISHED',
        NOW(),
        'SYSTEM',
        'seed',
        NOW(),
        NOW()
    );

INSERT INTO recipe_ingredients (
    id, recipe_id, position, display_name, canonical_name, quantity, quantity_text,
    unit_code, preparation_note, is_optional, created_at, updated_at
) VALUES
    ('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000101', 1, '250 g Nudeln', 'nudeln', 250, '250', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000302', '00000000-0000-0000-0000-000000000101', 2, '400 g Tomaten', 'tomaten', 400, '400', 'g', 'frisch oder passiert', FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000303', '00000000-0000-0000-0000-000000000101', 3, 'Parmesan', 'parmesan', NULL, NULL, NULL, 'nach Geschmack', TRUE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000304', '00000000-0000-0000-0000-000000000102', 1, '500 g Joghurt', 'joghurt', 500, '500', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000305', '00000000-0000-0000-0000-000000000102', 2, '2 Bananen', 'bananen', 2, '2', 'piece', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000306', '00000000-0000-0000-0000-000000000102', 3, 'Honig', 'honig', NULL, NULL, NULL, 'optional', TRUE, NOW(), NOW());

INSERT INTO recipe_steps (id, recipe_id, position, instruction, duration_minutes, created_at, updated_at) VALUES
    ('00000000-0000-0000-0000-000000000401', '00000000-0000-0000-0000-000000000101', 1, 'Nudeln in Salzwasser kochen.', 10, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000402', '00000000-0000-0000-0000-000000000101', 2, 'Tomaten erwaermen und mit den Nudeln mischen.', 8, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000403', '00000000-0000-0000-0000-000000000101', 3, 'Mit Parmesan servieren.', 2, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000404', '00000000-0000-0000-0000-000000000102', 1, 'Joghurt in Schalen verteilen.', 2, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000405', '00000000-0000-0000-0000-000000000102', 2, 'Bananen schneiden und mit Muesli mischen.', 4, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000406', '00000000-0000-0000-0000-000000000102', 3, 'Nach Geschmack mit Honig abrunden.', 2, NOW(), NOW());

INSERT INTO recipe_tag_assignments (recipe_id, tag_id) VALUES
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000201'),
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000202'),
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000201'),
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000203');

INSERT INTO ingredient_synonyms (id, canonical_name, synonym, locale, status, created_at, updated_at) VALUES
    ('00000000-0000-0000-0000-000000000501', 'tomaten', 'paradeiser', 'de_AT', 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000502', 'tomaten', 'tomate', 'de_AT', 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000503', 'bananen', 'banane', 'de_AT', 'ACTIVE', NOW(), NOW());
