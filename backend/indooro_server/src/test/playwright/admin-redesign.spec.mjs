import { expect, test } from "@playwright/test";

const routes = [
  ["/admin/", "Dashboard"],
  ["/admin/regions/", "Regionen"],
  ["/admin/stores/", "Stores"],
  ["/admin/stores/detail/?storeId=store-1", "Store Detail"],
  ["/admin/beacons/", "Beacons"],
  ["/admin/products/", "Produkte"],
  ["/admin/categories/", "Kategorien"],
  ["/admin/recipes/", "Rezepte"],
  ["/admin/server-logs/", "Diagnose"]
];

for (const [path, title] of routes) {
  test(`renders ${path}`, async ({ page }) => {
    await page.goto(path);
    await expect(page.getByRole("heading", { name: title })).toBeVisible();
    await expect(page.getByRole("navigation", { name: "Admin Navigation" })).toBeVisible();
  });
}

test("renders layout editor canvas and professional tool panels", async ({ page }) => {
  await page.goto("/admin/editor/?storeId=store-1");
  await expect(page.getByRole("heading", { name: "Layout Editor" })).toBeVisible();
  await expect(page.locator("#canvasContainer")).toBeVisible();
  await expect(page.locator("#propertiesWrapper")).toBeVisible();
  await expect(page.locator("#layersList")).toBeVisible();
  await expect(page.locator("#validationPanel")).toBeVisible();
  await page.getByRole("button", { name: "Validate" }).click();
  await expect(page.locator("#validationPanel")).toContainText(/Layout|Warnung|Fehler|bereit/i);
});

test("renders recipe list controls and edit entry points", async ({ page }) => {
  await page.goto("/admin/recipes/");
  await expect(page.getByRole("heading", { name: "Rezepte" })).toBeVisible();
  await expect(page.getByRole("button", { name: "Rezept anlegen" })).toBeVisible();
  await expect(page.getByText("Rezepte suchen")).toBeVisible();
  await expect(page.locator('[data-filter="query"]')).toBeVisible();
  await expect(page.locator(".filters label", { hasText: "Status" })).toBeVisible();
  await expect(page.locator('[data-filter="status"]')).toBeVisible();
  await expect(page.locator(".filters label", { hasText: "Sortierung" })).toBeVisible();
  await expect(page.locator('[data-filter="sort"]')).toBeVisible();
  await expect(page.locator("strong", { hasText: "Apfelkuchen" })).toBeVisible();
  await expect(page.getByRole("button", { name: "Bearbeiten" })).toBeVisible();
  await expect(page.getByRole("button", { name: "Mapping" })).toBeVisible();
});
