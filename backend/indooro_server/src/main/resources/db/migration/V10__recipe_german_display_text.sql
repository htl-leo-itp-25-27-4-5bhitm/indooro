UPDATE recipe_tags
SET name = 'Frühstück',
    updated_at = NOW()
WHERE code = 'breakfast';

UPDATE units
SET display_name = 'Stück',
    updated_at = NOW()
WHERE code = 'piece';

UPDATE recipes AS recipe
SET title = text_data.title,
    summary = text_data.summary,
    description = text_data.description,
    image_alt = text_data.image_alt,
    updated_at = NOW()
FROM (
    VALUES
        ('tomaten-pasta', 'Tomaten-Pasta', 'Schnelle Pasta mit Tomaten und Parmesan.', 'Eine einfache Tomaten-Pasta für den schnellen Einkauf nach der Arbeit.', 'Rezeptbild für Tomaten-Pasta'),
        ('fruehstuecks-muesli', 'Frühstücks-Müsli', 'Müsli mit Joghurt, Banane und Honig.', 'Ein schneller Frühstücksplan mit frischen und haltbaren Zutaten.', 'Rezeptbild für Frühstücks-Müsli'),
        ('apfel-pancakes', 'Apfel-Pancakes', 'Süße Pancakes mit Apfel und Joghurt.', 'Ein Familienrezept mit wenigen Standardprodukten.', 'Rezeptbild für Apfel-Pancakes'),
        ('linsen-tomaten-eintopf', 'Linsen-Tomaten-Eintopf', 'Sättigender Eintopf mit Linsen und Tomaten.', 'Ein unkomplizierter Vorratsklassiker für mehrere Portionen.', 'Rezeptbild für Linsen-Tomaten-Eintopf'),
        ('reis-gemuese-pfanne', 'Reis-Gemüse-Pfanne', 'Reis mit Paprika und cremigem Frischkäse.', 'Eine schnelle Pfanne für Mittag oder Abend.', 'Rezeptbild für Reis-Gemüse-Pfanne'),
        ('toast-mit-frischkaese', 'Toast mit Frischkäse', 'Knuspriger Toast mit Frischkäse und Tomaten.', 'Ein schneller Snack mit frischen und gekühlten Zutaten.', 'Rezeptbild für Toast mit Frischkäse'),
        ('eier-omelett', 'Eier-Omelett', 'Klassisches Omelett mit Milch und Butter.', 'Ein kurzes Pfannengericht für Frühstück oder Abendessen.', 'Rezeptbild für Eier-Omelett'),
        ('joghurt-beeren-bowl', 'Joghurt-Beeren-Bowl', 'Joghurt mit Haferflocken, Beeren und Honig.', 'Eine frische Bowl, bei der Zutaten ohne Marktprodukt sichtbar bleiben können.', 'Rezeptbild für Joghurt-Beeren-Bowl'),
        ('couscous-salat', 'Couscous-Salat', 'Couscous mit Tomaten, Gurke und Kräutern.', 'Ein Rezept mit Marktprodukten und bewusst freien Zutaten.', 'Rezeptbild für Couscous-Salat'),
        ('kartoffel-gouda-auflauf', 'Kartoffel-Gouda-Auflauf', 'Cremiger Auflauf mit Gouda und Milch.', 'Ein Familiengericht, bei dem Käse und Milch direkt in die Liste wandern.', 'Rezeptbild für Kartoffel-Gouda-Auflauf'),
        ('tomaten-reis-suppe', 'Tomaten-Reis-Suppe', 'Wärmende Suppe mit Reis und passierten Tomaten.', 'Ein einfaches Suppenrezept mit gut routbaren Produkten.', 'Rezeptbild für Tomaten-Reis-Suppe'),
        ('kaese-nudel-auflauf', 'Käse-Nudel-Auflauf', 'Nudeln mit Gouda und Milch überbacken.', 'Ein Rezept, das bestehende Pasta- und Kühlregalprodukte nutzt.', 'Rezeptbild für Käse-Nudel-Auflauf'),
        ('protein-fruehstueck', 'Protein-Frühstück', 'Eier, Joghurt und Banane für den Start.', 'Ein Frühstück mit Kühlregal und Obstbereich.', 'Rezeptbild für Protein-Frühstück'),
        ('haferdrink-bananen-shake', 'Haferdrink-Bananen-Shake', 'Shake mit Haferdrink, Banane und Haferflocken.', 'Eine vegane schnelle Option mit Obst und haltbaren Produkten.', 'Rezeptbild für Haferdrink-Bananen-Shake')
) AS text_data(slug, title, summary, description, image_alt)
WHERE recipe.slug = text_data.slug;

UPDATE recipe_ingredients AS ingredient
SET display_name = text_data.display_name,
    canonical_name = text_data.canonical_name,
    preparation_note = text_data.preparation_note,
    updated_at = NOW()
FROM (
    VALUES
        ('00000000-0000-0000-0000-000000000315'::uuid, 'Äpfel', 'aepfel', 'in Scheiben'),
        ('00000000-0000-0000-0000-000000000318'::uuid, 'Zwiebel', 'zwiebel', 'gewürfelt'),
        ('00000000-0000-0000-0000-000000000321'::uuid, 'Frischkäse', 'frischkaese', NULL),
        ('00000000-0000-0000-0000-000000000323'::uuid, 'Frischkäse', 'frischkaese', NULL),
        ('00000000-0000-0000-0000-000000000344'::uuid, 'Gouda', 'kaese', 'gerieben oder Scheiben'),
        ('00000000-0000-0000-0000-000000000355'::uuid, 'Äpfel', 'aepfel', NULL),
        ('00000000-0000-0000-0000-000000000362'::uuid, 'Tomaten', 'tomaten', 'gewürfelt'),
        ('00000000-0000-0000-0000-000000000363'::uuid, 'Frischkäse', 'frischkaese', NULL),
        ('00000000-0000-0000-0000-000000000372'::uuid, 'Frischkäse', 'frischkaese', NULL),
        ('00000000-0000-0000-0000-000000000378'::uuid, 'Joghurt', 'joghurt', 'für Dressing')
) AS text_data(id, display_name, canonical_name, preparation_note)
WHERE ingredient.id = text_data.id;

UPDATE recipe_steps
SET instruction = replace(instruction, 'fuer', 'für'),
    updated_at = NOW()
WHERE instruction LIKE '%fuer%';

UPDATE recipe_steps
SET instruction = replace(instruction, 'ruehren', 'rühren'),
    updated_at = NOW()
WHERE instruction LIKE '%ruehren%';

UPDATE recipe_steps
SET instruction = replace(instruction, 'einruehren', 'einrühren'),
    updated_at = NOW()
WHERE instruction LIKE '%einruehren%';

UPDATE recipe_steps
SET instruction = replace(instruction, 'wuerzen', 'würzen'),
    updated_at = NOW()
WHERE instruction LIKE '%wuerzen%';

UPDATE recipe_steps
SET instruction = replace(instruction, 'erwaermen', 'erwärmen'),
    updated_at = NOW()
WHERE instruction LIKE '%erwaermen%';

UPDATE recipe_steps
SET instruction = replace(instruction, 'Muesli', 'Müsli'),
    updated_at = NOW()
WHERE instruction LIKE '%Muesli%';

UPDATE recipe_steps
SET instruction = replace(instruction, 'Apfelstuecken', 'Apfelstücken'),
    updated_at = NOW()
WHERE instruction LIKE '%Apfelstuecken%';

UPDATE ingredient_product_mappings
SET product_name_snapshot = replace(product_name_snapshot, 'Aepfel', 'Äpfel'),
    updated_at = NOW()
WHERE lower(product_name_snapshot) LIKE '%aepfel%';
