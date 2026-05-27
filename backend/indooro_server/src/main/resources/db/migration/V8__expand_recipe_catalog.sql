UPDATE recipes
SET image_url = 'https://source.unsplash.com/900x650/?tomato,pasta',
    image_alt = 'Tomaten-Pasta in einer Schale',
    updated_at = NOW()
WHERE id = '00000000-0000-0000-0000-000000000101';

UPDATE recipes
SET image_url = 'https://source.unsplash.com/900x650/?muesli,yogurt,banana',
    image_alt = 'Muesli mit Joghurt und Banane',
    updated_at = NOW()
WHERE id = '00000000-0000-0000-0000-000000000102';

UPDATE recipe_ingredients
SET display_name = 'Nudeln', updated_at = NOW()
WHERE id = '00000000-0000-0000-0000-000000000301';

UPDATE recipe_ingredients
SET display_name = 'Tomaten', updated_at = NOW()
WHERE id = '00000000-0000-0000-0000-000000000302';

UPDATE recipe_ingredients
SET display_name = 'Joghurt', updated_at = NOW()
WHERE id = '00000000-0000-0000-0000-000000000304';

UPDATE recipe_ingredients
SET display_name = 'Bananen', updated_at = NOW()
WHERE id = '00000000-0000-0000-0000-000000000305';

INSERT INTO recipe_tags (id, code, name, kind, status, created_at, updated_at) VALUES
    ('00000000-0000-0000-0000-000000000204', 'vegan', 'Vegan', 'diet', 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000205', 'lunch', 'Mittagessen', 'occasion', 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000206', 'dinner', 'Abendessen', 'occasion', 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000207', 'breakfast', 'Fruehstueck', 'occasion', 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000208', 'snack', 'Snack', 'occasion', 'ACTIVE', NOW(), NOW())
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name,
    kind = EXCLUDED.kind,
    status = EXCLUDED.status,
    updated_at = NOW();

INSERT INTO recipes (
    id, slug, title, summary, description, image_url, image_alt, servings,
    prep_time_minutes, cook_time_minutes, total_time_minutes, status,
    published_at, created_by_role, created_by_label, created_at, updated_at
) VALUES
    ('00000000-0000-0000-0000-000000000103', 'caprese-salat', 'Caprese-Salat', 'Tomaten mit Mozzarella und Basilikum.', 'Ein leichter Salat fuer schnelle Einkaeufe und kurze Wege durch den Markt.', 'https://source.unsplash.com/900x650/?caprese,salad', 'Caprese-Salat mit Tomaten und Mozzarella', 2, 10, 0, 10, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000104', 'bananen-porridge', 'Bananen-Porridge', 'Warmer Haferbrei mit Banane und Milch.', 'Ein einfaches Fruehstueck mit haltbaren Basiszutaten.', 'https://source.unsplash.com/900x650/?banana,porridge', 'Porridge mit Bananenscheiben', 2, 5, 8, 13, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000105', 'apfel-pancakes', 'Apfel-Pancakes', 'Suesse Pancakes mit Apfel und Joghurt.', 'Ein Familienrezept mit wenigen Standardprodukten.', 'https://source.unsplash.com/900x650/?apple,pancakes', 'Pancakes mit Apfelstuecken', 3, 10, 15, 25, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000106', 'linsen-tomaten-eintopf', 'Linsen-Tomaten-Eintopf', 'Saettigender Eintopf mit Linsen und Tomaten.', 'Ein unkomplizierter Vorratsklassiker fuer mehrere Portionen.', 'https://source.unsplash.com/900x650/?lentil,tomato,soup', 'Linseneintopf mit Tomaten', 4, 10, 25, 35, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000107', 'reis-gemuese-pfanne', 'Reis-Gemuese-Pfanne', 'Reis mit Paprika und cremigem Frischkaese.', 'Eine schnelle Pfanne fuer Mittag oder Abend.', 'https://source.unsplash.com/900x650/?rice,vegetables', 'Reis-Gemuese-Pfanne', 3, 10, 20, 30, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000108', 'toast-mit-frischkaese', 'Toast mit Frischkaese', 'Knuspriger Toast mit Frischkaese und Tomaten.', 'Ein schneller Snack mit frischen und gekuehlten Zutaten.', 'https://source.unsplash.com/900x650/?toast,cream,cheese', 'Toast mit Frischkaese', 2, 8, 4, 12, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000109', 'eier-omelett', 'Eier-Omelett', 'Klassisches Omelett mit Milch und Butter.', 'Ein kurzes Pfannengericht fuer Fruehstueck oder Abendessen.', 'https://source.unsplash.com/900x650/?omelette,eggs', 'Omelett in einer Pfanne', 2, 5, 8, 13, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000110', 'joghurt-beeren-bowl', 'Joghurt-Beeren-Bowl', 'Joghurt mit Haferflocken, Beeren und Honig.', 'Eine frische Bowl, bei der nicht gemappte Zutaten sichtbar bleiben koennen.', 'https://source.unsplash.com/900x650/?yogurt,berries,bowl', 'Joghurt-Bowl mit Beeren', 2, 8, 0, 8, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000111', 'spaghetti-arrabbiata', 'Spaghetti Arrabbiata', 'Scharfe Pasta mit Tomatensauce.', 'Ein Pasta-Rezept mit mehreren gut mapbaren Tomatenprodukten.', 'https://source.unsplash.com/900x650/?spaghetti,arrabbiata', 'Spaghetti Arrabbiata', 2, 8, 15, 23, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000112', 'milchreis', 'Milchreis', 'Cremiger Milchreis mit Zucker und Zimt.', 'Ein suesses Basisrezept mit haltbaren Produkten.', 'https://source.unsplash.com/900x650/?rice,pudding', 'Milchreis mit Zimt', 3, 5, 25, 30, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000113', 'apfelmus-hafer-dessert', 'Apfelmus-Hafer-Dessert', 'Dessert aus Apfelmus, Haferflocken und Joghurt.', 'Ein schnelles Dessert aus Kuehl- und Vorratsregal.', 'https://source.unsplash.com/900x650/?apple,sauce,oats', 'Dessert mit Apfelmus und Hafer', 2, 6, 0, 6, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000114', 'couscous-salat', 'Couscous-Salat', 'Couscous mit Tomaten, Gurke und Kraeutern.', 'Ein Rezept mit gemappten und bewusst freien Zutaten.', 'https://source.unsplash.com/900x650/?couscous,salad', 'Couscous-Salat mit Gemuese', 3, 15, 5, 20, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000115', 'kartoffel-gouda-auflauf', 'Kartoffel-Gouda-Auflauf', 'Cremiger Auflauf mit Gouda und Milch.', 'Ein Familiengericht, bei dem Kaese und Milch direkt in die Liste wandern.', 'https://source.unsplash.com/900x650/?potato,cheese,casserole', 'Kartoffelauflauf mit Kaese', 4, 15, 35, 50, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000116', 'tomaten-reis-suppe', 'Tomaten-Reis-Suppe', 'Waermende Suppe mit Reis und passierten Tomaten.', 'Ein einfaches Suppenrezept mit gut routbaren Produkten.', 'https://source.unsplash.com/900x650/?tomato,rice,soup', 'Tomaten-Reis-Suppe', 3, 8, 20, 28, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000117', 'bananen-joghurt-smoothie', 'Bananen-Joghurt-Smoothie', 'Smoothie aus Banane, Joghurt und Milch.', 'Ein schnelles Rezept mit drei klaren Produktzuordnungen.', 'https://source.unsplash.com/900x650/?banana,yogurt,smoothie', 'Bananen-Joghurt-Smoothie', 2, 6, 0, 6, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000118', 'kaese-nudel-auflauf', 'Kaese-Nudel-Auflauf', 'Nudeln mit Gouda und Milch ueberbacken.', 'Ein Rezept, das bestehende Pasta- und Kuehlregalprodukte nutzt.', 'https://source.unsplash.com/900x650/?macaroni,cheese,casserole', 'Kaese-Nudel-Auflauf', 4, 10, 25, 35, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000119', 'apfel-hafer-crumble', 'Apfel-Hafer-Crumble', 'Warmer Crumble mit Apfel, Hafer und Butter.', 'Ein Dessert mit gut sichtbaren Mengen fuer die Einkaufsliste.', 'https://source.unsplash.com/900x650/?apple,crumble,oats', 'Apfel-Hafer-Crumble', 4, 12, 25, 37, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000120', 'linsen-bolognese', 'Linsen-Bolognese', 'Vegetarische Bolognese mit Linsen und Spaghetti.', 'Eine fleischlose Pasta mit Produkten aus Vorrats- und Saucenregal.', 'https://source.unsplash.com/900x650/?lentil,bolognese,pasta', 'Linsen-Bolognese mit Spaghetti', 4, 10, 25, 35, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000121', 'tomaten-bruschetta', 'Tomaten-Bruschetta', 'Geröstetes Brot mit Tomaten und Frischkaese.', 'Ein Snack mit teilweise freier Zutat fuer Brot.', 'https://source.unsplash.com/900x650/?bruschetta,tomato', 'Bruschetta mit Tomaten', 2, 10, 5, 15, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000122', 'reispfanne-mit-ei', 'Reispfanne mit Ei', 'Reis, Ei und Butter aus der Pfanne.', 'Ein kurzer Einkauf mit Produkten aus mehreren Regalbereichen.', 'https://source.unsplash.com/900x650/?fried,rice,egg', 'Reispfanne mit Ei', 2, 8, 15, 23, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000123', 'protein-fruehstueck', 'Protein-Fruehstueck', 'Eier, Joghurt und Banane fuer den Start.', 'Ein Fruehstueck mit Kuehlregal und Obstbereich.', 'https://source.unsplash.com/900x650/?breakfast,eggs,yogurt,banana', 'Protein-Fruehstueck mit Ei und Joghurt', 2, 8, 7, 15, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000124', 'cremige-tomatenpasta', 'Cremige Tomatenpasta', 'Pasta mit Tomaten und Frischkaese.', 'Eine cremige Variante der schnellen Tomatenpasta.', 'https://source.unsplash.com/900x650/?creamy,tomato,pasta', 'Cremige Tomatenpasta', 3, 8, 15, 23, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000125', 'haferdrink-bananen-shake', 'Haferdrink-Bananen-Shake', 'Shake mit Haferdrink, Banane und Haferflocken.', 'Eine vegane schnelle Option mit Obst und haltbaren Produkten.', 'https://source.unsplash.com/900x650/?oat,milk,banana,smoothie', 'Shake mit Haferdrink und Banane', 2, 5, 0, 5, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000126', 'eier-reis-salat', 'Eier-Reis-Salat', 'Kalter Salat mit Reis, Ei und Joghurt-Dressing.', 'Ein vorbereitbares Rezept mit klaren Einkaufslistenpositionen.', 'https://source.unsplash.com/900x650/?rice,salad,egg', 'Reissalat mit Ei', 3, 12, 15, 27, 'PUBLISHED', NOW(), 'SYSTEM', 'seed', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO recipe_ingredients (
    id, recipe_id, position, display_name, canonical_name, quantity, quantity_text,
    unit_code, preparation_note, is_optional, created_at, updated_at
) VALUES
    ('00000000-0000-0000-0000-000000000307', '00000000-0000-0000-0000-000000000103', 1, 'Tomaten', 'tomaten', 300, '300', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000308', '00000000-0000-0000-0000-000000000103', 2, 'Mozzarella', 'mozzarella', 125, '125', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000309', '00000000-0000-0000-0000-000000000103', 3, 'Basilikum', 'basilikum', NULL, NULL, NULL, 'frisch', TRUE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000310', '00000000-0000-0000-0000-000000000104', 1, 'Haferflocken', 'haferflocken', 100, '100', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000311', '00000000-0000-0000-0000-000000000104', 2, 'Bananen', 'bananen', 1, '1', 'piece', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000312', '00000000-0000-0000-0000-000000000104', 3, 'Milch', 'milch', 300, '300', 'ml', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000313', '00000000-0000-0000-0000-000000000105', 1, 'Mehl', 'mehl', 180, '180', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000314', '00000000-0000-0000-0000-000000000105', 2, 'Eier', 'eier', 2, '2', 'piece', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000315', '00000000-0000-0000-0000-000000000105', 3, 'Aepfel', 'aepfel', 2, '2', 'piece', 'in Scheiben', FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000316', '00000000-0000-0000-0000-000000000106', 1, 'Linsen', 'linsen', 250, '250', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000317', '00000000-0000-0000-0000-000000000106', 2, 'Passierte Tomaten', 'tomaten', 500, '500', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000318', '00000000-0000-0000-0000-000000000106', 3, 'Zwiebel', 'zwiebel', 1, '1', 'piece', 'gewuerfelt', FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000319', '00000000-0000-0000-0000-000000000107', 1, 'Reis', 'reis', 250, '250', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000320', '00000000-0000-0000-0000-000000000107', 2, 'Paprika', 'paprika', 2, '2', 'piece', 'bunt', FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000321', '00000000-0000-0000-0000-000000000107', 3, 'Frischkaese', 'frischkaese', 100, '100', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000322', '00000000-0000-0000-0000-000000000108', 1, 'Toastbrot', 'toastbrot', 4, '4', 'piece', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000323', '00000000-0000-0000-0000-000000000108', 2, 'Frischkaese', 'frischkaese', 120, '120', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000324', '00000000-0000-0000-0000-000000000108', 3, 'Tomaten', 'tomaten', 150, '150', 'g', 'in Scheiben', FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000325', '00000000-0000-0000-0000-000000000109', 1, 'Eier', 'eier', 4, '4', 'piece', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000326', '00000000-0000-0000-0000-000000000109', 2, 'Milch', 'milch', 80, '80', 'ml', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000327', '00000000-0000-0000-0000-000000000109', 3, 'Butter', 'butter', 20, '20', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000328', '00000000-0000-0000-0000-000000000110', 1, 'Joghurt', 'joghurt', 400, '400', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000329', '00000000-0000-0000-0000-000000000110', 2, 'Haferflocken', 'haferflocken', 60, '60', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000330', '00000000-0000-0000-0000-000000000110', 3, 'Honig', 'honig', 2, '2', 'tbsp', 'optional', TRUE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000331', '00000000-0000-0000-0000-000000000111', 1, 'Spaghetti', 'nudeln', 250, '250', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000332', '00000000-0000-0000-0000-000000000111', 2, 'Arrabbiata-Sauce', 'tomatensauce', 500, '500', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000333', '00000000-0000-0000-0000-000000000111', 3, 'Tomatenmark', 'tomatenmark', 1, '1', 'tbsp', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000334', '00000000-0000-0000-0000-000000000112', 1, 'Reis', 'reis', 200, '200', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000335', '00000000-0000-0000-0000-000000000112', 2, 'Milch', 'milch', 800, '800', 'ml', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000336', '00000000-0000-0000-0000-000000000112', 3, 'Zucker', 'zucker', 40, '40', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000337', '00000000-0000-0000-0000-000000000113', 1, 'Apfelmus', 'apfelmus', 250, '250', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000338', '00000000-0000-0000-0000-000000000113', 2, 'Haferflocken', 'haferflocken', 80, '80', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000339', '00000000-0000-0000-0000-000000000113', 3, 'Joghurt', 'joghurt', 250, '250', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000340', '00000000-0000-0000-0000-000000000114', 1, 'Couscous', 'couscous', 200, '200', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000341', '00000000-0000-0000-0000-000000000114', 2, 'Tomaten', 'tomaten', 200, '200', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000342', '00000000-0000-0000-0000-000000000114', 3, 'Gurke', 'gurke', 1, '1', 'piece', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000343', '00000000-0000-0000-0000-000000000115', 1, 'Kartoffeln', 'kartoffeln', 700, '700', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000344', '00000000-0000-0000-0000-000000000115', 2, 'Gouda', 'kaese', 200, '200', 'g', 'gerieben oder Scheiben', FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000345', '00000000-0000-0000-0000-000000000115', 3, 'Milch', 'milch', 250, '250', 'ml', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000346', '00000000-0000-0000-0000-000000000116', 1, 'Passierte Tomaten', 'tomaten', 500, '500', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000347', '00000000-0000-0000-0000-000000000116', 2, 'Reis', 'reis', 120, '120', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000348', '00000000-0000-0000-0000-000000000116', 3, 'Zwiebel', 'zwiebel', 1, '1', 'piece', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000349', '00000000-0000-0000-0000-000000000117', 1, 'Bananen', 'bananen', 2, '2', 'piece', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000350', '00000000-0000-0000-0000-000000000117', 2, 'Joghurt', 'joghurt', 300, '300', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000351', '00000000-0000-0000-0000-000000000117', 3, 'Milch', 'milch', 200, '200', 'ml', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000352', '00000000-0000-0000-0000-000000000118', 1, 'Nudeln', 'nudeln', 300, '300', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000353', '00000000-0000-0000-0000-000000000118', 2, 'Gouda', 'kaese', 200, '200', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000354', '00000000-0000-0000-0000-000000000118', 3, 'Milch', 'milch', 200, '200', 'ml', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000355', '00000000-0000-0000-0000-000000000119', 1, 'Aepfel', 'aepfel', 4, '4', 'piece', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000356', '00000000-0000-0000-0000-000000000119', 2, 'Haferflocken', 'haferflocken', 100, '100', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000357', '00000000-0000-0000-0000-000000000119', 3, 'Butter', 'butter', 80, '80', 'g', 'kalt', FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000358', '00000000-0000-0000-0000-000000000120', 1, 'Linsen', 'linsen', 200, '200', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000359', '00000000-0000-0000-0000-000000000120', 2, 'Spaghetti', 'nudeln', 350, '350', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000360', '00000000-0000-0000-0000-000000000120', 3, 'Tomatenmark', 'tomatenmark', 2, '2', 'tbsp', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000361', '00000000-0000-0000-0000-000000000121', 1, 'Brot', 'brot', 4, '4', 'piece', 'Scheiben', FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000362', '00000000-0000-0000-0000-000000000121', 2, 'Tomaten', 'tomaten', 250, '250', 'g', 'gewuerfelt', FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000363', '00000000-0000-0000-0000-000000000121', 3, 'Frischkaese', 'frischkaese', 80, '80', 'g', NULL, TRUE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000364', '00000000-0000-0000-0000-000000000122', 1, 'Reis', 'reis', 220, '220', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000365', '00000000-0000-0000-0000-000000000122', 2, 'Eier', 'eier', 2, '2', 'piece', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000366', '00000000-0000-0000-0000-000000000122', 3, 'Butter', 'butter', 25, '25', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000367', '00000000-0000-0000-0000-000000000123', 1, 'Eier', 'eier', 3, '3', 'piece', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000368', '00000000-0000-0000-0000-000000000123', 2, 'Joghurt', 'joghurt', 250, '250', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000369', '00000000-0000-0000-0000-000000000123', 3, 'Bananen', 'bananen', 1, '1', 'piece', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000370', '00000000-0000-0000-0000-000000000124', 1, 'Spaghetti', 'nudeln', 300, '300', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000371', '00000000-0000-0000-0000-000000000124', 2, 'Passierte Tomaten', 'tomaten', 500, '500', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000372', '00000000-0000-0000-0000-000000000124', 3, 'Frischkaese', 'frischkaese', 120, '120', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000373', '00000000-0000-0000-0000-000000000125', 1, 'Haferdrink', 'haferdrink', 300, '300', 'ml', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000374', '00000000-0000-0000-0000-000000000125', 2, 'Bananen', 'bananen', 2, '2', 'piece', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000375', '00000000-0000-0000-0000-000000000125', 3, 'Haferflocken', 'haferflocken', 40, '40', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000376', '00000000-0000-0000-0000-000000000126', 1, 'Reis', 'reis', 180, '180', 'g', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000377', '00000000-0000-0000-0000-000000000126', 2, 'Eier', 'eier', 3, '3', 'piece', NULL, FALSE, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000378', '00000000-0000-0000-0000-000000000126', 3, 'Joghurt', 'joghurt', 150, '150', 'g', 'fuer Dressing', FALSE, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO recipe_steps (id, recipe_id, position, instruction, duration_minutes, created_at, updated_at) VALUES
    ('00000000-0000-0000-0000-000000000407', '00000000-0000-0000-0000-000000000103', 1, 'Tomaten schneiden und anrichten.', 4, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000408', '00000000-0000-0000-0000-000000000103', 2, 'Mozzarella dazugeben und wuerzen.', 4, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000409', '00000000-0000-0000-0000-000000000103', 3, 'Mit Basilikum servieren.', 2, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000410', '00000000-0000-0000-0000-000000000104', 1, 'Haferflocken mit Milch aufkochen.', 5, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000411', '00000000-0000-0000-0000-000000000104', 2, 'Banane zerdruecken und einruehren.', 3, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000412', '00000000-0000-0000-0000-000000000104', 3, 'Warm servieren.', 1, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000413', '00000000-0000-0000-0000-000000000105', 1, 'Teig aus Mehl, Eiern und Milch ruehren.', 5, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000414', '00000000-0000-0000-0000-000000000105', 2, 'Pancakes portionsweise backen.', 10, NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000415', '00000000-0000-0000-0000-000000000105', 3, 'Mit Apfelstuecken servieren.', 3, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO recipe_steps (id, recipe_id, position, instruction, duration_minutes, created_at, updated_at)
SELECT
    ('00000000-0000-0000-0000-' || lpad((416 + ((r.recipe_no - 106) * 3) + step_no - 1)::text, 12, '0'))::uuid,
    ('00000000-0000-0000-0000-' || lpad(r.recipe_no::text, 12, '0'))::uuid,
    step_no,
    CASE step_no
        WHEN 1 THEN 'Zutaten vorbereiten und nach Rezept sortieren.'
        WHEN 2 THEN 'Hauptzutaten garen, ruehren oder anrichten.'
        ELSE 'Abschmecken und direkt servieren.'
    END,
    CASE step_no WHEN 1 THEN 5 WHEN 2 THEN 15 ELSE 3 END,
    NOW(),
    NOW()
FROM generate_series(106, 126) AS r(recipe_no)
CROSS JOIN generate_series(1, 3) AS s(step_no)
ON CONFLICT (id) DO NOTHING;

INSERT INTO recipe_tag_assignments (recipe_id, tag_id) VALUES
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000201'),
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000202'),
    ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000207'),
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0000-000000000203'),
    ('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0000-000000000204'),
    ('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0000-000000000206'),
    ('00000000-0000-0000-0000-000000000107', '00000000-0000-0000-0000-000000000205'),
    ('00000000-0000-0000-0000-000000000108', '00000000-0000-0000-0000-000000000208'),
    ('00000000-0000-0000-0000-000000000109', '00000000-0000-0000-0000-000000000207'),
    ('00000000-0000-0000-0000-000000000110', '00000000-0000-0000-0000-000000000207'),
    ('00000000-0000-0000-0000-000000000111', '00000000-0000-0000-0000-000000000206'),
    ('00000000-0000-0000-0000-000000000112', '00000000-0000-0000-0000-000000000203'),
    ('00000000-0000-0000-0000-000000000113', '00000000-0000-0000-0000-000000000208'),
    ('00000000-0000-0000-0000-000000000114', '00000000-0000-0000-0000-000000000204'),
    ('00000000-0000-0000-0000-000000000115', '00000000-0000-0000-0000-000000000203'),
    ('00000000-0000-0000-0000-000000000116', '00000000-0000-0000-0000-000000000205'),
    ('00000000-0000-0000-0000-000000000117', '00000000-0000-0000-0000-000000000201'),
    ('00000000-0000-0000-0000-000000000118', '00000000-0000-0000-0000-000000000206'),
    ('00000000-0000-0000-0000-000000000119', '00000000-0000-0000-0000-000000000203'),
    ('00000000-0000-0000-0000-000000000120', '00000000-0000-0000-0000-000000000202'),
    ('00000000-0000-0000-0000-000000000121', '00000000-0000-0000-0000-000000000208'),
    ('00000000-0000-0000-0000-000000000122', '00000000-0000-0000-0000-000000000205'),
    ('00000000-0000-0000-0000-000000000123', '00000000-0000-0000-0000-000000000207'),
    ('00000000-0000-0000-0000-000000000124', '00000000-0000-0000-0000-000000000206'),
    ('00000000-0000-0000-0000-000000000125', '00000000-0000-0000-0000-000000000204'),
    ('00000000-0000-0000-0000-000000000126', '00000000-0000-0000-0000-000000000205')
ON CONFLICT DO NOTHING;

INSERT INTO ingredient_product_mappings (
    id, recipe_ingredient_id, canonical_name, store_id, store_code, product_id,
    product_name_snapshot, layout_code_snapshot, mapping_type, confidence,
    manually_confirmed, status, created_at, updated_at
) VALUES
    ('00000000-0000-0000-0000-000000000601', '00000000-0000-0000-0000-000000000301', NULL, NULL, NULL, 32, 'Barilla Spaghetti N.5 500g', '430/1/1/1', 'MANUAL', 0.950, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000602', '00000000-0000-0000-0000-000000000302', NULL, NULL, NULL, 20, 'Tomaten passiert 500g', '420/1/1/1', 'MANUAL', 0.920, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000603', '00000000-0000-0000-0000-000000000304', NULL, NULL, NULL, 91, 'S-BUDGET Joghurt 500g', '520/1/3/2', 'MANUAL', 0.900, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000604', '00000000-0000-0000-0000-000000000305', NULL, NULL, NULL, 2, 'Bananen lose', '310/1/1/2', 'MANUAL', 0.920, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000605', '00000000-0000-0000-0000-000000000307', NULL, NULL, NULL, 20, 'Tomaten passiert 500g', '420/1/1/1', 'MANUAL', 0.780, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000606', '00000000-0000-0000-0000-000000000310', NULL, NULL, NULL, 44, 'S-BUDGET Haferflocken 500g', '440/1/3/2', 'MANUAL', 0.920, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000607', '00000000-0000-0000-0000-000000000311', NULL, NULL, NULL, 2, 'Bananen lose', '310/1/1/2', 'MANUAL', 0.940, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000608', '00000000-0000-0000-0000-000000000312', NULL, NULL, NULL, 86, 'Frische Vollmilch 1L', '520/1/1/1', 'MANUAL', 0.900, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000609', '00000000-0000-0000-0000-000000000313', NULL, NULL, NULL, 49, 'S-BUDGET Mehl 1kg', '445/1/1/1', 'MANUAL', 0.900, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000610', '00000000-0000-0000-0000-000000000314', NULL, NULL, NULL, 88, 'Naturpur Bio-Eier 10 Stk.', '520/1/2/1', 'MANUAL', 0.900, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000611', '00000000-0000-0000-0000-000000000316', NULL, NULL, NULL, 30, 'Linsen 500g', '420/1/4/1', 'MANUAL', 0.940, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000612', '00000000-0000-0000-0000-000000000317', NULL, NULL, NULL, 26, 'Passierte Tomaten 500g', '420/2/1/1', 'MANUAL', 0.940, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000613', '00000000-0000-0000-0000-000000000319', NULL, NULL, NULL, 46, 'S-BUDGET Reis 1kg', '440/1/5/2', 'MANUAL', 0.900, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000614', '00000000-0000-0000-0000-000000000321', NULL, NULL, NULL, 107, 'Frischkaese Kraeuter 200g', '525/2/2/1', 'MANUAL', 0.850, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000615', '00000000-0000-0000-0000-000000000323', NULL, NULL, NULL, 108, 'S-BUDGET Frischkaese Natur 200g', '525/2/2/2', 'MANUAL', 0.900, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000616', '00000000-0000-0000-0000-000000000324', NULL, NULL, NULL, 20, 'Tomaten passiert 500g', '420/1/1/1', 'MANUAL', 0.740, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000617', '00000000-0000-0000-0000-000000000325', NULL, NULL, NULL, 88, 'Naturpur Bio-Eier 10 Stk.', '520/1/2/1', 'MANUAL', 0.930, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000618', '00000000-0000-0000-0000-000000000326', NULL, NULL, NULL, 86, 'Frische Vollmilch 1L', '520/1/1/1', 'MANUAL', 0.900, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000619', '00000000-0000-0000-0000-000000000327', NULL, NULL, NULL, 102, 'Butter 250g', '525/1/2/1', 'MANUAL', 0.900, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000620', '00000000-0000-0000-0000-000000000328', NULL, NULL, NULL, 91, 'S-BUDGET Joghurt 500g', '520/1/3/2', 'MANUAL', 0.940, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000621', '00000000-0000-0000-0000-000000000329', NULL, NULL, NULL, 44, 'S-BUDGET Haferflocken 500g', '440/1/3/2', 'MANUAL', 0.920, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000622', '00000000-0000-0000-0000-000000000331', NULL, NULL, NULL, 34, 'S-BUDGET Spaghetti 500g', '430/1/2/1', 'MANUAL', 0.940, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000623', '00000000-0000-0000-0000-000000000332', NULL, NULL, NULL, 23, 'Nudelsauce Arrabbiata 500g', '420/1/2/2', 'MANUAL', 0.950, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000624', '00000000-0000-0000-0000-000000000333', NULL, NULL, NULL, 28, 'Tomatenmark 200g', '420/2/2/1', 'MANUAL', 0.900, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000625', '00000000-0000-0000-0000-000000000334', NULL, NULL, NULL, 46, 'S-BUDGET Reis 1kg', '440/1/5/2', 'MANUAL', 0.900, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000626', '00000000-0000-0000-0000-000000000335', NULL, NULL, NULL, 86, 'Frische Vollmilch 1L', '520/1/1/1', 'MANUAL', 0.900, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000627', '00000000-0000-0000-0000-000000000336', NULL, NULL, NULL, 50, 'Zucker 1kg', '445/1/1/2', 'MANUAL', 0.900, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000628', '00000000-0000-0000-0000-000000000337', NULL, NULL, NULL, 6, 'S-BUDGET Apfelmus 250g', '310/1/3/2', 'MANUAL', 0.940, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000629', '00000000-0000-0000-0000-000000000344', NULL, NULL, NULL, 100, 'Gouda in Scheiben 250g', '525/1/1/1', 'MANUAL', 0.850, TRUE, 'ACTIVE', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000630', '00000000-0000-0000-0000-000000000373', NULL, NULL, NULL, 99, 'S-BUDGET Haferdrink 1L', '520/2/4/2', 'MANUAL', 0.920, TRUE, 'ACTIVE', NOW(), NOW())
ON CONFLICT DO NOTHING;

WITH default_product_mappings(canonical_name, product_id, product_name_snapshot, layout_code_snapshot, confidence) AS (
    VALUES
        ('tomaten', 20, 'Tomaten passiert 500g', '420/1/1/1', 0.780),
        ('bananen', 2, 'Bananen lose', '310/1/1/2', 0.940),
        ('joghurt', 91, 'S-BUDGET Joghurt 500g', '520/1/3/2', 0.940),
        ('haferflocken', 44, 'S-BUDGET Haferflocken 500g', '440/1/3/2', 0.920),
        ('milch', 86, 'Frische Vollmilch 1L', '520/1/1/1', 0.900),
        ('mehl', 49, 'S-BUDGET Mehl 1kg', '445/1/1/1', 0.900),
        ('eier', 88, 'Naturpur Bio-Eier 10 Stk.', '520/1/2/1', 0.900),
        ('aepfel', 1, 'Gala Aepfel lose', '310/1/1/1', 0.850),
        ('linsen', 30, 'Linsen 500g', '420/1/4/1', 0.940),
        ('reis', 46, 'S-BUDGET Reis 1kg', '440/1/5/2', 0.900),
        ('frischkaese', 108, 'S-BUDGET Frischkaese Natur 200g', '525/2/2/2', 0.900),
        ('butter', 102, 'Butter 250g', '525/1/2/1', 0.900),
        ('nudeln', 34, 'S-BUDGET Spaghetti 500g', '430/1/2/1', 0.940),
        ('tomatensauce', 23, 'Nudelsauce Arrabbiata 500g', '420/1/2/2', 0.950),
        ('tomatenmark', 28, 'Tomatenmark 200g', '420/2/2/1', 0.900),
        ('zucker', 50, 'Zucker 1kg', '445/1/1/2', 0.900),
        ('apfelmus', 6, 'S-BUDGET Apfelmus 250g', '310/1/3/2', 0.940),
        ('kaese', 100, 'Gouda in Scheiben 250g', '525/1/1/1', 0.850),
        ('haferdrink', 99, 'S-BUDGET Haferdrink 1L', '520/2/4/2', 0.920)
),
ingredients_without_mapping AS (
    SELECT
        ingredient.id AS recipe_ingredient_id,
        mapping.canonical_name,
        mapping.product_id,
        mapping.product_name_snapshot,
        mapping.layout_code_snapshot,
        mapping.confidence,
        row_number() OVER (ORDER BY ingredient.id) AS mapping_no
    FROM recipe_ingredients ingredient
    JOIN default_product_mappings mapping
        ON lower(ingredient.canonical_name) = mapping.canonical_name
    WHERE NOT EXISTS (
        SELECT 1
        FROM ingredient_product_mappings existing
        WHERE existing.recipe_ingredient_id = ingredient.id
          AND existing.status = 'ACTIVE'
    )
)
INSERT INTO ingredient_product_mappings (
    id, recipe_ingredient_id, canonical_name, store_id, store_code, product_id,
    product_name_snapshot, layout_code_snapshot, mapping_type, confidence,
    manually_confirmed, status, created_at, updated_at
)
SELECT
    ('00000000-0000-0000-0000-' || lpad((700 + mapping_no)::text, 12, '0'))::uuid,
    recipe_ingredient_id,
    NULL,
    NULL,
    NULL,
    product_id,
    product_name_snapshot,
    layout_code_snapshot,
    'SYNONYM',
    confidence,
    TRUE,
    'ACTIVE',
    NOW(),
    NOW()
FROM ingredients_without_mapping
ON CONFLICT DO NOTHING;
