# Upsell Quality Gate Evidence

This note captures the simulator findings that drove `harden-upsell-prefilter-quality`.

## Observed Cases

| Trigger | Previous result | Source/fallback signal | Desired behavior |
| --- | --- | --- | --- |
| Coca-Cola | Flour or other baking/cooking products could appear | Fallback/OpenAI over noisy candidates | Only salty snacks/chips, or no prompt |
| Risotto | Apples, carrots, or oranges could appear | OpenAI received weak candidate pool | Cheese, broth, mushrooms, onion, oil, cooking vegetables, or no prompt |
| Butter | Pasta/sauce could repeatedly appear | Broad category/keyword relation | Bread, baking, eggs, flour, spreads, milk, or no prompt |
| Eggs | Sometimes no popup after session limit was consumed by weaker prompts | iOS session limit | Good prompts only; empty/weak opportunities do not show a sheet |
| Bad-Reiniger | Empty OpenAI result was correct but iOS could later treat it as cache miss | Loaded empty not cached | Cache loaded-empty and log `no_suggestions` |
| Weichspueler | `no_ranked_candidates` was correct | Strict no-safe-candidate case | Laundry-only suggestions or empty |
| Apple variants | Other apple products could remain candidates | Exact product id exclusion only | Suppress by normalized `apple` class |
| Flour repeats | Same flour class could appear across several opportunities | No plan-level class dedupe | Assign repeated class to strongest opportunity only |
| `shopping_session` vs `shopping_list` | Same opportunity could miss cache because source differed | Source was part of key | Reuse equivalent source when list/store/opportunity match |

## Regression Fixtures

Backend tests in `UpsellSuggestionServiceTest` now cover:

- Product classification for butter, apple, flour, cola, cleaner, softener, and unknown battery products.
- Cola not returning flour, pasta, butter, or eggs.
- Risotto not returning fruit.
- Cleaner not returning food.
- Softener returning only laundry suggestions or empty.
- Apple variants suppressed by product class.
- Plan-level flour dedupe across butter and eggs.

Manual iOS verification should check for these debug lines:

- `preloadPlan cached loaded_empty ...`
- `showOpportunity skipped ... reason=no_suggestions`
- `cache source_key_fallback ...`
- `pendingOpportunity dropped reason=loaded_empty ...`
- `pendingOpportunity dropped reason=not_in_plan ...`
