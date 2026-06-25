## Why

The current upsell flow is technically stable enough to preload and show station suggestions, but recent simulator tests show that weak server-side prefiltering still produces poor or repetitive suggestions when OpenAI falls back or receives a noisy candidate pool. This needs to be fixed now because bad prompts such as cola to flour, repeated flour suggestions, or fruit for risotto reduce trust more than showing no upsell at all.

## What Changes

- Add strict server-side upsell quality gates before OpenAI and fallback suggestions are returned.
- Introduce product-domain and product-class classification for the demo catalog, including food, drinks, cleaning, laundry, paper/household, dairy, grains, fruit, baking staples, and unknown.
- Add hard compatibility rules so unrelated domains do not cross, for example cleaning products do not receive food suggestions and food products do not receive cleaning suggestions.
- Add same-product-class exclusions so products already on the list suppress equivalent variants, for example Gala apples suppress other apple products.
- Add plan-level deduplication so the same suggested product or product class is not shown repeatedly across unrelated stations.
- Make deterministic fallback stricter: return empty opportunities when only weak candidates exist.
- Ensure empty suggestion results are represented distinctly from missing/unloaded cache entries in iOS debug and display behavior.
- Normalize or bridge upsell cache lookup between shopping-session and shopping-list source where the opportunity/list/store identity is otherwise the same.
- Keep OpenAI server-side and grounded in backend-provided candidates; do not send the whole catalog to OpenAI.

## Capabilities

### New Capabilities

- `mobile-upsell-quality-gates`: Defines quality gates, compatibility rules, negative/empty result behavior, repetition control, and mobile display expectations for upsell prompts.

### Modified Capabilities

- `product-catalog-search`: Adds backend product classification and normalized product-class signals required by upsell candidate filtering without exposing a new public catalog endpoint.

## Impact

- Backend: `UpsellSuggestionService` candidate scoring, fallback ranking, OpenAI payload construction, validation, cache context, and tests.
- Backend/catalog: internal helpers for deriving product domain and product class from product name and layout code.
- iOS: `UpsellSuggestionStore` cache semantics and debug logging for loaded-empty opportunities and source-normalized lookup.
- OpenSpec/docs: update upsell ranking documentation with quality-gate rules, examples, and manual QA expectations.
- Deployment: backend-only behavior change unless iOS cache semantics require a mobile app update; LeoCloud rollout remains the existing backend Kubernetes process.
