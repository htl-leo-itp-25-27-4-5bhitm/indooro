## Context

The current upsell flow already preloads a station plan after a manual store tap and caches suggestions by opportunity. The latest tests show that the transport flow is mostly working: duplicate requests are suppressed, stale responses are ignored, accepted upsell products are not used as triggers, and OpenAI can return useful results when the candidate pool is good.

The remaining quality problem is before and around OpenAI:

- Fallback can still return weak products such as cola to flour.
- OpenAI can make weak choices when the backend allows noisy candidates such as fruit for risotto.
- Equivalent variants such as multiple apple products are not suppressed by product class.
- The same product, especially flour, can appear across several unrelated stations.
- Backend empty results are correct for non-food items such as softener, but iOS currently treats empty opportunities like cache misses because it only caches populated suggestions.
- `shopping_session` and `shopping_list` can produce different cache keys for the same opportunity, which creates false misses.

The current product model is still lean: id, name, price, layoutCode, storeId, and storeCode. There is no reliable explicit taxonomy, inventory, purchase history, image classification, margin, or recipe graph. Therefore the fix must be a deterministic MVP-quality layer based on product names, layout-code category, and explicit rules. It should improve visible quality without pretending to be a production recommender.

## Goals / Non-Goals

**Goals:**

- Make bad suggestions much rarer by adding hard compatibility gates before OpenAI and fallback.
- Prefer no popup over a weak popup.
- Separate food, drink, cleaning, laundry, paper/household, hygiene, cooking, baking, dairy, fruit, cereal/breakfast, snack, and unknown domains where reliable.
- Exclude same product classes already present on the list or completed, not just exact product ids.
- Prevent repeated products/classes across a single plan response.
- Keep OpenAI as a ranker/explainer over a small quality-gated candidate pool, not as a full-catalog search engine.
- Make fallback stricter than OpenAI: fallback should only show high-confidence deterministic pairs.
- Make iOS represent loaded-empty opportunities distinctly from missing cache entries.
- Add tests based on observed bad cases: cola to flour, risotto to fruit, repeated flour, cleaning to food, softener empty, apple variants, and session-limit behavior.

**Non-Goals:**

- No full product ontology, admin-managed recommender UI, customer tracking, purchase-history learning, inventory integration, or A/B testing dashboard.
- No sending the full catalog to OpenAI.
- No new public product-class API.
- No guarantee that every product receives a suggestion.
- No change to anonymous mobile/customer access boundaries.
- No direct OpenAI calls from iOS.

## Decisions

### Decision: Add an internal product classifier

Create a backend-only classifier that derives:

- `ProductDomain`: broad safety domain, for example `FOOD`, `DRINK`, `CLEANING`, `LAUNDRY`, `PAPER_HOUSEHOLD`, `HYGIENE`, `UNKNOWN`.
- `ProductFamily`: more specific family, for example `FRUIT`, `APPLE`, `BANANA`, `OATS_CEREAL`, `BUTTER`, `CHEESE`, `EGGS`, `FLOUR`, `SUGAR`, `RICE_RISOTTO`, `SOFT_DRINK`, `CLEANER`, `SOFTENER`, `PAPER_TOWEL`.
- `ProductClass`: normalized duplicate class, for example `apple`, `flour`, `butter`, `softener`, `bathroom_cleaner`.

Inputs:

- normalized product name with German-safe aliases
- first `layoutCode` category segment
- optional explicit keyword maps for known demo product names

Rationale: The server must know enough to say "this is impossible" before OpenAI sees the candidate. Product-class exclusion is also the only practical way to prevent apple-to-apple and flour-to-flour repetition.

Alternative considered: let OpenAI infer all classes from product names. Rejected because it is slower, less deterministic, harder to test, and still allows repeated or incompatible suggestions when the candidate pool is noisy.

### Decision: Use hard compatibility gates before scoring

Before candidate scoring, apply hard gates:

- incompatible domain gate: cleaning/laundry cannot receive food/drink candidates; food cannot receive cleaning/laundry candidates
- unknown-domain gate: unknown triggers return empty unless a reliable explicit rule exists
- same-class gate: current, completed, accepted-upsell, and trigger classes are excluded
- forbidden-family gate: specific observed bad pairs are blocked, for example `RICE_RISOTTO -> FRUIT`, `SOFT_DRINK -> FLOUR`, `CLEANER -> FOOD`

Rationale: Some pairs should not be "low score"; they should be impossible. This makes OpenAI cheaper and safer because it never receives those candidates.

Alternative considered: only adjust weights. Rejected because weak positives from layout/category can still leak through when the catalog pool is small.

### Decision: Split candidate decision into allowed, scored, and showable

Each candidate moves through stages:

1. `allowed`: passes hard domain/class/forbidden gates
2. `scored`: receives deterministic score from complement rules
3. `showable`: passes stricter display threshold and plan-level dedupe

Recommended defaults:

- AI candidate threshold: lower, because OpenAI can rerank among plausible candidates
- fallback show threshold: higher, because no language model judgment will repair weak matches
- minimum suggestions to show: at least two normal suggestions, or one very strong suggestion

Rationale: This keeps creativity possible for OpenAI while preventing fallback from filling weak prompts.

Alternative considered: one global score threshold. Rejected because AI and fallback need different risk tolerances.

### Decision: Build explicit complement groups for observed families

Initial explicit allowed/complement groups:

- oats/cereal -> milk, yogurt, banana, apple sauce, honey, fruit, breakfast
- butter -> flour, sugar, eggs, bread, baking, breakfast
- eggs -> flour, butter, bread, baking, breakfast, cooking staples
- risotto/rice -> parmesan, cheese, broth, mushrooms, onion, oil, cooking vegetables
- pasta -> sauce, tomato, pesto, parmesan, oil
- cola/soft drink -> chips, salty snacks, ice, or empty
- cleaner -> paper towels, cleaning cloths, sponge, trash bags, gloves, or empty
- softener/laundry -> detergent, stain remover, laundry products, or empty
- paper towel -> cleaner, cloths, trash bags, napkins, or empty

Rationale: These are the product families that appeared in logs or are common enough for the demo. This rule set should be small, inspectable, and easy to tune.

Alternative considered: embeddings first. Rejected for this fix because embeddings still need hard safety gates and would add storage/build complexity. Embeddings can be a later improvement.

### Decision: Dedupe across the full plan

After per-opportunity scoring, run a plan-level pass:

- keep a suggested product id only for its strongest opportunity
- keep a product class only once across unrelated opportunities unless explicitly repeatable
- prefer opportunities with stronger score margin and stronger trigger family
- never let a low-quality repeated candidate consume a session prompt

Rationale: The user sees the shopping session as one flow. Repeating flour across cola, eggs, and butter feels broken even if each opportunity is technically independent.

Alternative considered: dedupe only on iOS after decoding. Rejected because OpenAI and fallback should not waste tokens or show repeated candidates in the first place.

### Decision: Cache empty opportunities on iOS

Add a cache entry state instead of using "presence of suggestions" as the only loaded signal:

- `not_loaded`
- `loaded_empty`
- `loaded_with_suggestions`

When backend returns an empty suggestion list, iOS stores `loaded_empty`. Later `showOpportunity` logs `no_suggestions` and does not store a pending opportunity or claim a cache miss.

Rationale: Empty is a valid answer. Treating empty as cache-miss causes confusing logs and unnecessary retries.

Alternative considered: backend omits empty opportunities. Rejected because iOS needs to know the opportunity was evaluated and intentionally suppressed.

### Decision: Normalize cache lookup source for shopping-session display

For upsell plan cache lookup, use list + store + opportunity identity as primary. Either remove `source` from the key or add fallback lookup between `shopping_session` and `shopping_list` when list/store/opportunity match.

Rationale: Logs showed a valid cached risotto result under `shopping_session` and a false cache miss under `shopping_list`.

Alternative considered: enforce one source everywhere. This is ideal but riskier because call sites may have meaningful source labels. Source-normalized fallback lookup is safer.

### Decision: Do not send the full catalog to OpenAI

The backend continues to send only quality-gated per-opportunity candidates. The full catalog remains in OpenSearch and deterministic filters. OpenAI ranks and explains only plausible candidates.

Rationale: Sending all products increases tokens, latency, cost, and confusion. It also weakens server-side guarantees because OpenAI would need to do filtering that the backend can test deterministically.

Alternative considered: larger model or full catalog. Rejected as expensive and not reliable enough without hard gates.

## Risks / Trade-offs

- [Risk] Rules become too strict and suppress useful suggestions. -> Mitigation: log suppressed reasons, create fixtures, and allow explicit family rules to add back good pairs.
- [Risk] Product names are messy and classification misses products. -> Mitigation: unknown domain returns no suggestions; add aliases incrementally from observed logs.
- [Risk] Current layout-code categories are not true product categories. -> Mitigation: use layout code only as a secondary signal behind name/family rules for hard gates.
- [Risk] Fewer popups may look like the feature disappeared. -> Mitigation: debug logs distinguish no suggestions from no plan; manual QA should verify high-quality cases still show.
- [Risk] Plan-level dedupe might remove a suggestion from the station where the user expected it. -> Mitigation: prefer strongest score and keep deterministic logs for product/class assignment.
- [Risk] iOS cache state changes can affect popup timing. -> Mitigation: keep response shape unchanged and test PendingOpportunity with populated, empty, and absent opportunities.
- [Risk] OpenAI still writes plausible but wrong reasons. -> Mitigation: validate candidates before and after OpenAI; fallback reasons stay generic and product-safe.

## Migration Plan

1. Implement backend classifier and quality-gate helpers behind the existing `/api/mobile/upsell/plan` response contract.
2. Add tests for classifier, gates, duplicate classes, forbidden pairs, plan-level dedupe, fallback strictness, and OpenAI validation.
3. Update iOS cache state to distinguish loaded-empty from missing cache and add debug logs.
4. Preserve existing `UpsellPlanResponse` shape so deployed iOS remains decodable.
5. Bump backend plan cache context version if ranking/gating semantics change cached results.
6. Run backend upsell tests, OpenSpec validation, iOS simulator build, and targeted simulator manual flows.
7. Deploy backend to LeoCloud through the existing image/GitHub Actions/Kubernetes rollout path; deploy iOS only if Swift changes must be tested on device/simulator.
8. Rollback by redeploying the previous backend image and, if needed, reverting the Swift cache-state change; no database rollback is expected.

## Open Questions

- Should `source` be removed from the iOS upsell cache key, or should lookup try equivalent `shopping_session` and `shopping_list` keys?
- Should loaded-empty cache entries be persisted until `expiresAt`, or only for the current shopping session?
- What exact session prompt limit should apply after weak/empty opportunities stop counting?
- Which product families are present in the real demo catalog for cleaner, laundry, snack, broth, mushroom, onion, and parmesan complements?
- Should a later change add embeddings after the deterministic gates are stable?
