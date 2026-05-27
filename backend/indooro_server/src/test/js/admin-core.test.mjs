import assert from "node:assert/strict";
import test from "node:test";
import {
  canAccessRoute,
  parseImportText,
  readinessForProduct,
  routeFromPath,
  sortRows,
  validateBeaconForm,
  validateProductForm,
  validateStoreForm
} from "../../main/resources/META-INF/resources/admin/core.js";
import {
  clampElement,
  createHistory,
  pushHistory,
  redoHistory,
  snapValue,
  undoHistory,
  validateLayoutDocument
} from "../../main/resources/META-INF/resources/admin/editor-core.js";

test("routeFromPath resolves split admin pages", () => {
  assert.equal(routeFromPath("/admin/stores/detail/").id, "stores");
  assert.equal(routeFromPath("/admin/server-logs/").id, "server-logs");
});

test("role-aware navigation blocks admin-only routes for store managers", () => {
  assert.equal(canAccessRoute({ roles: ["store-manager"] }, routeFromPath("/admin/products/")), false);
  assert.equal(canAccessRoute({ roles: ["admin"] }, routeFromPath("/admin/products/")), true);
});

test("validators catch required operational fields", () => {
  assert.equal(validateStoreForm({}).regionId, "Region ist erforderlich.");
  assert.equal(validateBeaconForm({ uuid: "bad", major: 1, minor: 1 }).uuid, "UUID-Format wirkt ungueltig.");
  assert.equal(validateProductForm({ id: 0, name: "", price: -1, layoutCode: "" }).id, "Produkt-ID muss positiv sein.");
});

test("product readiness reports missing route metadata", () => {
  const readiness = readinessForProduct({ id: 1, name: "Apfel" });
  assert.equal(readiness.status, "warning");
  assert.ok(readiness.problems.includes("Layout-Code fehlt"));
});

test("imports support JSON arrays and NDJSON", () => {
  assert.equal(parseImportText('[{"id":1}]').length, 1);
  assert.equal(parseImportText('{"id":1}\n{"id":2}').length, 2);
});

test("table helpers sort naturally", () => {
  const sorted = sortRows([{ name: "B2" }, { name: "B10" }, { name: "B1" }], "name");
  assert.deepEqual(sorted.map((row) => row.name), ["B1", "B2", "B10"]);
});

test("layout validation reports publish blockers and warnings", () => {
  const result = validateLayoutDocument({
    width: 100,
    height: 100,
    gridSize: 10,
    elements: [
      { id: "b1", type: "beacon", x: 10, y: 10, width: 10, height: 10, beaconCode: "A" },
      { id: "b2", type: "beacon", x: 20, y: 10, width: 10, height: 10, beaconCode: "A" },
      { id: "s1", type: "shelf", x: 120, y: 0, width: 10, height: 10 }
    ]
  });
  assert.equal(result.readyToPublish, false);
  assert.ok(result.errorCount >= 2);
});

test("editor geometry and history helpers are deterministic", () => {
  assert.equal(snapValue(14, 10, true), 10);
  assert.equal(clampElement({ x: 99, y: -4, width: 20, height: 20 }, { width: 100, height: 100 }).x, 80);
  const history = pushHistory(createHistory({ value: 1 }), { value: 2 });
  assert.equal(undoHistory(history).present.value, 1);
  assert.equal(redoHistory(undoHistory(history)).present.value, 2);
});
