# MCindooroApp Testing Notes

## Current Xcode test-target status

The Xcode project currently defines only one native target:

```text
MCindooroApp
```

There is no `MCindooroAppTests` XCTest target in:

```text
swift/indooro-EinkaeuferFinal/MCindooroApp.xcodeproj/project.pbxproj
```

Because the project has no existing test target, API/model tests were not added
directly to the `.pbxproj`. Creating XCTest targets by hand in a populated
Xcode project is fragile and can easily corrupt build phases, scheme settings,
or user state.

## Recommended next step

Create a new XCTest target in Xcode named:

```text
MCindooroAppTests
```

Then add unit tests for:

- `RecipeSummary`
- `RecipeDetail`
- `RecipeProductMappingResponse`
- `UpsellPlanResponse`
- `UpsellSuggestionResponse`
- backward-compatible `ShoppingListItem` decoding with recipe and upsell fields
- pure merge/deduplication behavior for recipe-sourced and upsell-sourced
  shopping-list items

The tests should use local JSON fixtures only and must not perform real network
calls.

