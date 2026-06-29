# Upsell Candidate Ranking

## Current Strategy

The upsell plan now uses an AI-first ranking strategy.

The backend no longer tries to semantically decide which products fit a trigger product before OpenAI runs. It loads a bounded store catalog, removes products that must never be suggested, and lets OpenAI decide which products are useful add-ons for each shopping station.

The server still keeps the non-negotiable safety contract:

- The OpenAI API key stays server-side.
- Only existing catalog product IDs can be returned.
- Products already open on the shopping list, completed products, and trigger products are excluded before the AI request.
- Returned product IDs are validated against the server candidate map.
- Duplicate product IDs in one opportunity are ignored.
- The OpenAI prompt rejects another brand, package size, flavor, or variant of the trigger product because it is an alternative, not an add-on.
- If OpenAI is disabled, unavailable, times out, or returns invalid JSON, the backend returns empty suggestions instead of deterministic fallback guesses.

This intentionally prefers no popup over weak server-generated suggestions.

## Flow

The mobile app calls `POST /api/mobile/upsell/plan` after the user selects a store and the route is known.

Backend flow:

1. Normalize route opportunities such as `station:<shelf-id>` or `item:<uuid>`.
2. Load a bounded OpenSearch candidate pool with the current store filter when available.
3. Exclude invalid products, duplicate product IDs, current list products, completed products, and trigger products.
4. Build one shared `candidateProducts` catalog for the OpenAI request.
5. Send all opportunities plus the shared catalog to OpenAI.
6. Expect structured JSON with known `opportunityId` and candidate `productId` values.
7. Validate every returned product ID against the server candidate map.
8. Return validated suggestions, or loaded-empty opportunities when OpenAI returns no strong fit.

## Config

- `upsell.max-candidates` limits the shared OpenSearch candidate catalog. Default: `150`.
- `upsell.max-suggestions` limits returned suggestions per opportunity. Default: `3`.
- `openai.upsell.timeout-ms` controls the backend OpenAI request timeout. Default: `12000`.
- `openai.upsell.enabled`, `openai.api-key`, `openai.upsell.model`, and `openai.upsell.reasoning-effort` keep their existing behavior.

The plan cache version is `upsell-plan-v5`, so responses created before the alternative-product prompt rule are not reused.

## OpenAI Payload Shape

OpenAI receives:

- `opportunities`: station IDs and trigger product IDs/names.
- `candidateProducts`: one shared bounded catalog for the store.
- `maxSuggestionsPerOpportunity`.

Each candidate contains compact catalog fields only:

- `id`
- `name`
- `categoryCode`
- `layoutCode`
- `hasLayoutPosition`

The backend does not send API secrets, internal cache hashes, user identifiers beyond the shopping-list context already needed for cache separation, or full product descriptions.

## Timeout And Retry Behavior

iOS uses a longer `POST /mobile/upsell/plan` timeout than the backend OpenAI timeout. This prevents the app from aborting a valid backend response just before it returns.

While one plan request is already in flight, iOS does not cancel it and does not start a second plan request for list changes caused by checking items. This avoids wasting tokens on a second OpenAI call while the first one is still running.

If the user checks an item before the plan response arrives, the existing pending-opportunity logic waits for the response and shows the popup only if that exact opportunity returns suggestions.

## Logs And Debug

Useful backend log lines:

- `Upsell plan candidate ranking requestId=... broadCandidates=... rankedCandidates=... perOpportunity=...`
- `Upsell plan OpenAI skipped requestId=... enabled=... hasApiKey=... opportunities=... candidates=...`
- `OpenAI upsell plan ranking succeeded requestId=... inputTokens=... outputTokens=... totalTokens=...`
- `Upsell plan response requestId=... source=... elapsedMs=... openAiElapsedMs=... fallbackReason=...`

Useful iOS debug lines:

- `preloadPlan requestId=... timeout=25.0s`
- `preloadPlan skipped reason=in_flight_waiting`
- `preloadPlan decoded ... totalTokens=...`
- `loaded_empty`: the backend evaluated the opportunity and intentionally returned no suggestions.
- `loaded_with_suggestions`: the opportunity has cached suggestions.
- `no_suggestions`: the sheet is skipped because the cached opportunity is empty.
- `source_key_fallback`: a cache entry created under `shopping_session` or `shopping_list` was reused for the equivalent source.

## Manual Checks

- The first store-selected plan request should not time out at six seconds anymore.
- Checking products while the plan is still loading should not start another OpenAI request.
- `source=openai` means OpenAI returned valid structured output.
- `source=cache` means the cached plan was reused.
- `source=none` with `fallbackReason=openai_unavailable_timeout_or_invalid` means no deterministic server fallback was used.
- Weak cases such as Gouda, eggs, cola, cleaner, or softener may return no popup if OpenAI finds no clear add-on.
- Apples should not suggest other apple variants, and cola should not suggest another cola size or brand.

## Tradeoff

This version may use more input tokens than strict server-side prefiltering because the AI sees a wider catalog. The benefit is that product-fit judgment is centralized in the model instead of brittle Java heuristics.

If token usage becomes too high, the next safe optimization is not semantic prefiltering again, but payload compaction or a two-step AI flow:

1. Ask the model to choose candidate IDs from a compact ID/name/category list.
2. Ask the model to write short reasons only for the selected IDs.
