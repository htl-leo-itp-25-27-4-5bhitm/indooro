# Upsell Candidate Ranking

## Flow

The mobile app still calls `POST /api/mobile/upsell/plan` once after the user selects a store and the shopping route is known.

Backend flow:

1. Normalize route opportunities such as `station:<shelf-id>` or `item:<uuid>`.
2. Load a bounded OpenSearch candidate pool with the current store filter when available.
3. Exclude products already in the list, completed products, trigger products, invalid products, and duplicate product ids.
4. Resolve trigger products when possible and derive internal product classifications from name and `layoutCode`.
5. Apply hard quality gates for product domain, product class, already-present classes, and forbidden family pairs.
6. Score candidates separately for each opportunity using explicit complement rules.
7. Deduplicate repeated product ids and normalized product classes across the whole plan.
8. Send only each opportunity's quality-gated candidate list to OpenAI when OpenAI is enabled and configured.
9. Validate OpenAI product ids against the candidate map for that same opportunity.
10. If OpenAI is unavailable, invalid, or disabled, return deterministic fallback suggestions only when their deterministic score is strong enough.

## Config

- `upsell.max-candidates` limits the broad OpenSearch pool. Default: `50`.
- `upsell.per-opportunity-candidates` limits the candidates sent per opportunity. Default: `10`.
- `upsell.min-deterministic-score` drops weak deterministic candidates before OpenAI/fallback. Default: `40`.
- `upsell.max-suggestions` limits returned suggestions per opportunity. Default: `3`.
- `openai.upsell.enabled`, `openai.api-key`, `openai.upsell.model`, `openai.upsell.timeout-ms`, and `openai.upsell.reasoning-effort` keep their existing behavior.

Changing ranking-related config is part of the plan cache hash. The plan cache version is `upsell-plan-v3`, so old broad-candidate responses are not reused.

## Classification And Gates

The backend derives internal-only classification signals:

- Product domain: food, drink, cleaning, laundry, paper-household, personal-care, pet, non-food, or unknown.
- Product family: apple, oats/cereal, butter, eggs, flour, pasta, risotto/rice, cola/soft-drink, cleaner, softener, paper towel, and related families.
- Product class key: stable duplicate class such as `apple`, `flour`, `pasta`, `cleaning_spray`, or `laundry_softener`.

These signals are not exposed in public product responses. They are used only inside ranking and filtering.

Hard gates run before OpenAI and fallback:

- Unknown triggers or unknown candidates are suppressed for quality-sensitive upsell.
- Cleaning and laundry triggers cannot receive food, drink, fruit, dairy, cereal, baking, or cooking suggestions.
- Food and drink triggers cannot receive cleaning, laundry, hygiene, or unrelated non-food suggestions.
- Same normalized class is suppressed when the class is already on the list, already completed, accepted from upsell, or is the trigger class.
- Known bad family pairs are impossible rather than merely low-scored, for example risotto to fruit and cola to flour.

Fallback is intentionally stricter than OpenAI. If only weak candidates exist, the backend returns an empty opportunity. Empty is a valid result and should not be interpreted as a failed request.

## Complement Rules

Initial explicit complement groups:

- Oats/cereal -> milk, yogurt, banana, apples, honey, fruit, breakfast products.
- Butter -> flour, sugar, eggs, bread, baking staples, spreads, milk.
- Eggs -> flour, butter, bread, baking staples, milk, cheese, cooking vegetables.
- Risotto/rice -> parmesan/cheese, broth, mushrooms, onion, oil, cooking vegetables.
- Pasta -> sauce, pesto/tomato products, parmesan/cheese, oil, herbs, vegetables.
- Cola/soft drinks -> salty snacks/chips, otherwise no suggestions.
- Cleaner -> paper towels, cleaning cloths/sponges, trash bags, gloves, otherwise no suggestions.
- Softener/laundry -> detergent, stain remover, laundry products, otherwise no suggestions.
- Paper towels -> cleaner, cloths/sponges, trash bags, gloves.

Plan-level deduplication assigns a repeated product id or repeated product class to its strongest opportunity and suppresses weaker repeats. This prevents one strong generic candidate, such as flour, from appearing on several unrelated stations.

## Logs And Debug

Useful log lines:

- `Upsell plan candidate ranking requestId=... broadCandidates=... rankedCandidates=... perOpportunity=station:a=5,...`
- `Upsell plan OpenAI skipped requestId=... enabled=... hasApiKey=... opportunities=... candidates=...`
- `OpenAI upsell plan ranking succeeded requestId=... inputTokens=... outputTokens=... totalTokens=...`
- `Upsell plan response requestId=... source=... elapsedMs=... openAiElapsedMs=... fallbackReason=...`
- Debug-level suppression reasons include `unknown_candidate`, `unknown_trigger`, `same_class`, `already_in_list_or_completed`, `incompatible_domain`, `forbidden_family`, `no_family_rule`, `below_threshold`, `deduped_plan_product`, and `deduped_plan_class`.

Response `debug.candidateCount` now reflects the ranked candidates for fallback/OpenAI paths. It is `0` for `no_ranked_candidates`.

On iOS, `[UpsellDebug]` distinguishes:

- `loaded_empty`: the backend evaluated the opportunity and intentionally returned no suggestions.
- `loaded_with_suggestions`: the opportunity has cached suggestions.
- `no_suggestions`: the sheet is skipped because the cached opportunity is empty.
- `source_key_fallback`: a cache entry created under `shopping_session` or `shopping_list` was reused for the equivalent source.
- `pendingOpportunity dropped reason=loaded_empty` or `pendingOpportunity dropped reason=not_in_plan`: an in-flight completion was resolved without showing stale suggestions.

## Manual Checks

- Butter should prefer bread/bakery, spreads, eggs, flour, and milk over pasta/sauce when those products exist.
- Pasta should still surface sauce, tomato, parmesan/cheese, and oil style candidates.
- Fruit should prefer yogurt/dairy, oats/cereal, honey/spreads, and breakfast candidates.
- Cola should show chips/snacks or nothing, never flour, pasta, butter, or eggs.
- Risotto should show cheese/broth/mushrooms/onion/oil/cooking vegetables or nothing, never fruit.
- Cleaning and laundry products should show only compatible household/laundry products or nothing.
- Unknown categories may return no suggestions instead of forcing weak products.
- `source=openai` means OpenAI returned valid structured output.
- `source=fallback` means deterministic ranked candidates were used because OpenAI was disabled, unavailable, timed out, or invalid.
- `source=cache` means the cached plan was reused.
- `source=none` with `fallbackReason=no_candidates` means OpenSearch returned no usable products.
- `source=none` with `fallbackReason=no_ranked_candidates` means products existed, but none passed the deterministic score threshold.

## Deferred

The first implementation does not skip OpenAI for very strong deterministic matches. That can be added later with a separate threshold and margin if token cost is still too high after measuring the per-opportunity payload.
