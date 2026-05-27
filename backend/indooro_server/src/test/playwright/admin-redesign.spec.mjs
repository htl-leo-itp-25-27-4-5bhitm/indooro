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
