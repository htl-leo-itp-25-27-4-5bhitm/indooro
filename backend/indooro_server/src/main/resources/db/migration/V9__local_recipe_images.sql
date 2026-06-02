-- Recipe images are served as static backend assets from
-- META-INF/resources/images/recipes so the mobile app gets stable images.
UPDATE recipes AS recipe
SET image_url = image_data.image_url,
    image_alt = image_data.image_alt,
    updated_at = NOW()
FROM (
    VALUES
        ('apfel-hafer-crumble', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/apfel-hafer-crumble.jpg', 'Rezeptbild fuer Apfel-Hafer-Crumble'),
        ('apfel-pancakes', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/apfel-pancakes.jpg', 'Rezeptbild fuer Apfel-Pancakes'),
        ('apfelmus-hafer-dessert', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/apfelmus-hafer-dessert.jpg', 'Rezeptbild fuer Apfelmus-Hafer-Dessert'),
        ('bananen-joghurt-smoothie', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/bananen-joghurt-smoothie.jpg', 'Rezeptbild fuer Bananen-Joghurt-Smoothie'),
        ('bananen-porridge', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/bananen-porridge.jpg', 'Rezeptbild fuer Bananen-Porridge'),
        ('caprese-salat', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/caprese-salat.jpg', 'Rezeptbild fuer Caprese-Salat'),
        ('couscous-salat', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/couscous-salat.jpg', 'Rezeptbild fuer Couscous-Salat'),
        ('cremige-tomatenpasta', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/cremige-tomatenpasta.jpg', 'Rezeptbild fuer Cremige Tomatenpasta'),
        ('eier-omelett', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/eier-omelett.jpg', 'Rezeptbild fuer Eier-Omelett'),
        ('eier-reis-salat', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/eier-reis-salat.jpg', 'Rezeptbild fuer Eier-Reis-Salat'),
        ('fruehstuecks-muesli', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/fruehstuecks-muesli.jpg', 'Rezeptbild fuer Fruehstuecks-Muesli'),
        ('haferdrink-bananen-shake', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/haferdrink-bananen-shake.jpg', 'Rezeptbild fuer Haferdrink-Bananen-Shake'),
        ('joghurt-beeren-bowl', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/joghurt-beeren-bowl.jpg', 'Rezeptbild fuer Joghurt-Beeren-Bowl'),
        ('kaese-nudel-auflauf', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/kaese-nudel-auflauf.jpg', 'Rezeptbild fuer Kaese-Nudel-Auflauf'),
        ('kartoffel-gouda-auflauf', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/kartoffel-gouda-auflauf.jpg', 'Rezeptbild fuer Kartoffel-Gouda-Auflauf'),
        ('linsen-bolognese', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/linsen-bolognese.jpg', 'Rezeptbild fuer Linsen-Bolognese'),
        ('linsen-tomaten-eintopf', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/linsen-tomaten-eintopf.jpg', 'Rezeptbild fuer Linsen-Tomaten-Eintopf'),
        ('milchreis', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/milchreis.jpg', 'Rezeptbild fuer Milchreis'),
        ('protein-fruehstueck', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/protein-fruehstueck.jpg', 'Rezeptbild fuer Protein-Fruehstueck'),
        ('reis-gemuese-pfanne', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/reis-gemuese-pfanne.jpg', 'Rezeptbild fuer Reis-Gemuese-Pfanne'),
        ('reispfanne-mit-ei', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/reispfanne-mit-ei.jpg', 'Rezeptbild fuer Reispfanne mit Ei'),
        ('spaghetti-arrabbiata', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/spaghetti-arrabbiata.jpg', 'Rezeptbild fuer Spaghetti Arrabbiata'),
        ('toast-mit-frischkaese', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/toast-mit-frischkaese.jpg', 'Rezeptbild fuer Toast mit Frischkaese'),
        ('tomaten-bruschetta', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/tomaten-bruschetta.jpg', 'Rezeptbild fuer Tomaten-Bruschetta'),
        ('tomaten-pasta', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/tomaten-pasta.jpg', 'Rezeptbild fuer Tomaten-Pasta'),
        ('tomaten-reis-suppe', 'https://it220209.cloud.htl-leonding.ac.at/images/recipes/tomaten-reis-suppe.jpg', 'Rezeptbild fuer Tomaten-Reis-Suppe')
) AS image_data(slug, image_url, image_alt)
WHERE recipe.slug = image_data.slug;
