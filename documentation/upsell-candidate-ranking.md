# Upsell Candidate Ranking

## Flow

The mobile app still calls `POST /api/mobile/upsell/plan` once after the user selects a store and the shopping route is known.

Backend flow:

1. Normalize route opportunities such as `station:<shelf-id>` or `item:<uuid>`.
2. Load a bounded OpenSearch candidate pool with the current store filter when available.
3. Exclude products already in the list, completed products, trigger products, invalid products, and duplicate product ids.
4. Resolve trigger products when possible and derive category codes from the first `layoutCode` segment.
5. Score candidates separately for each opportunity.
6. Send only each opportunity's ranked candidate list to OpenAI when OpenAI is enabled and configured.
7. Validate OpenAI product ids against the candidate map for that same opportunity.
8. If OpenAI is unavailable, invalid, or disabled, return deterministic fallback suggestions from each opportunity's ranked candidates.

## Config

- `upsell.max-candidates` limits the broad OpenSearch pool. Default: `50`.
- `upsell.per-opportunity-candidates` limits the candidates sent per opportunity. Default: `10`.
- `upsell.min-deterministic-score` drops weak deterministic candidates before OpenAI/fallback. Default: `40`.
- `upsell.max-suggestions` limits returned suggestions per opportunity. Default: `3`.
- `openai.upsell.enabled`, `openai.api-key`, `openai.upsell.model`, `openai.upsell.timeout-ms`, and `openai.upsell.reasoning-effort` keep their existing behavior.

Changing ranking-related config is part of the plan cache hash. The plan cache version is `upsell-plan-v2`, so old broad-candidate responses are not reused.

## Current Rule Assumptions

Category codes are derived from the first `layoutCode` segment:

- `525`: butter/dairy-adjacent staples
- `430`: pasta
- `420`: sauces/preserved cooking products
- `310`: fruit
- `440`: cereal/oats
- `445`: baking staples
- `510`: bread/bakery
- `470`: spreads/honey/jam
- `520`: milk/yogurt/dairy
- `450`: oil/cooking staple

Keyword rules cover butter, pasta, sauces, oats/cereal, fruit, milk/yogurt, bread, coffee/tea, spreads, cheese, oil, and baking staples. Butter-like triggers intentionally penalize pasta and tomato-sauce candidates so direct bread/baking/breakfast complements rank first when present.

## Logs And Debug

Useful log lines:

- `Upsell plan candidate ranking requestId=... broadCandidates=... rankedCandidates=... perOpportunity=station:a=5,...`
- `Upsell plan OpenAI skipped requestId=... enabled=... hasApiKey=... opportunities=... candidates=...`
- `OpenAI upsell plan ranking succeeded requestId=... inputTokens=... outputTokens=... totalTokens=...`
- `Upsell plan response requestId=... source=... elapsedMs=... openAiElapsedMs=... fallbackReason=...`

Response `debug.candidateCount` now reflects the ranked candidates for fallback/OpenAI paths. It is `0` for `no_ranked_candidates`.

## Manual Checks

- Butter should prefer bread/bakery, spreads, eggs, flour, and milk over pasta/sauce when those products exist.
- Pasta should still surface sauce, tomato, parmesan/cheese, and oil style candidates.
- Fruit should prefer yogurt/dairy, oats/cereal, honey/spreads, and breakfast candidates.
- Unknown categories may return no suggestions instead of forcing weak products.
- `source=openai` means OpenAI returned valid structured output.
- `source=fallback` means deterministic ranked candidates were used because OpenAI was disabled, unavailable, timed out, or invalid.
- `source=cache` means the cached plan was reused.
- `source=none` with `fallbackReason=no_candidates` means OpenSearch returned no usable products.
- `source=none` with `fallbackReason=no_ranked_candidates` means products existed, but none passed the deterministic score threshold.

## Deferred

The first implementation does not skip OpenAI for very strong deterministic matches. That can be added later with a separate threshold and margin if token cost is still too high after measuring the per-opportunity payload.
