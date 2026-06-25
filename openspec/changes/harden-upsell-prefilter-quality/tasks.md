## 1. Baseline And Evidence

- [x] 1.1 Re-read the current backend upsell flow in `UpsellSuggestionService`, `MobileUpsellResource`, DTOs, cache/event/dismissal repositories, and the related tests before changing behavior.
- [x] 1.2 Re-read the current iOS upsell flow in `UpsellSuggestionStore`, `UpsellModels`, `UpsellPromptSheet`, and the shopping-session call sites before changing behavior.
- [x] 1.3 Capture current runtime configuration values for OpenAI model, timeout, reasoning effort, candidate count, plan cache context version, cooldown, and iOS throttling.
- [x] 1.4 Convert the observed console logs into a small evidence table in the implementation notes: trigger product, returned suggestions, source, fallback reason, elapsed time, candidate count, and whether the popup appeared.
- [x] 1.5 Mark the known bad cases as regression fixtures: `Coca-Cola -> Mehl`, `Risotto -> apples/carrots/oranges`, repeated `Mehl` suggestions, and `Eier` hidden by session-limit exhaustion.
- [x] 1.6 Mark the known good no-suggestion cases as regression fixtures: `Bad-Reiniger` should not receive food suggestions, and `Weichspüler` may safely return no suggestions.
- [x] 1.7 Mark the known iOS cache-state bugs as regression fixtures: loaded-empty opportunities must not become `cache_miss`, and `shopping_session` vs `shopping_list` source mismatch must not lose cached data.
- [x] 1.8 Identify the demo catalog products and layout/category fields needed for oats, butter, eggs, risotto, cola, cleaner, softener, flour, pasta, sauces, fruit, paper towels, and common snacks.

## 2. Backend Product Classification

- [x] 2.1 Add an internal product classification model with at least `domain`, `family`, `classKey`, and `confidence`.
- [x] 2.2 Add internal product domains for `food`, `drink`, `cleaning`, `laundry`, `paper_household`, `personal_care`, `pet`, `non_food`, and `unknown`.
- [x] 2.3 Add internal product families for the tested shopping families, including oats/cereal, butter, eggs, rice/risotto, pasta, pasta sauce, flour, baking staples, cheese, broth, fruit, vegetables, cola/soft drinks, snacks, cleaning spray, laundry softener, and paper towels.
- [x] 2.4 Derive classification from product name, category fields, layout metadata, and existing catalog attributes without changing the public product API contract.
- [x] 2.5 Normalize German and common brand/product wording before classification, including plural/singular forms and terms such as `Eier`, `Butter`, `Risotto`, `Cola`, `Reiniger`, `Weichspüler`, `Küchenrolle`, `Mehl`, `Spaghetti`, and `Nudelsauce`.
- [x] 2.6 Generate a stable `classKey` that groups equivalent variants, for example apple variants together, flour variants together, spaghetti variants together, and cleaning-spray variants together.
- [x] 2.7 Keep classification conservative: ambiguous products should be `unknown` instead of guessed into an unsafe domain.
- [x] 2.8 Add backend unit tests for product classification using representative products from the demo catalog.
- [x] 2.9 Add tests proving classification is internal and does not add fields to existing public product responses unless a separate API change is made later.

## 3. Hard Quality Gates

- [x] 3.1 Add a hard domain compatibility matrix that runs before OpenAI payload construction and before fallback suggestion construction.
- [x] 3.2 Block incompatible cross-domain suggestions, especially `food/drink -> cleaning/laundry/personal_care/non_food` and `cleaning/laundry -> food/drink`.
- [x] 3.3 Allow only explicitly safe cross-domain suggestions, for example `cleaning -> paper_household` when the family relation supports it.
- [x] 3.4 Block same-class suggestions so that a product does not recommend near-duplicates of itself.
- [x] 3.5 Block products already on the shopping list, already completed in the current session, or already added from upsell.
- [x] 3.6 Treat accepted upsell products as consumed classes for future opportunities so a product added from upsell is not recommended again in the same plan/session.
- [x] 3.7 Reject candidates with `unknown` classification unless an explicit safe family rule exists.
- [x] 3.8 Add backend tests proving `Bad-Reiniger` cannot recommend food, pasta, sauce, fruit, or drinks.
- [x] 3.9 Add backend tests proving `Weichspüler` cannot recommend food, pasta, sauce, fruit, drinks, or unrelated cleaning products.
- [x] 3.10 Add backend tests proving `Coca-Cola` cannot recommend flour, pasta, sauce, butter, eggs, or random grocery staples.
- [x] 3.11 Add backend tests proving `Risotto` cannot recommend unrelated fruit as a fallback or OpenAI-ranked candidate.
- [x] 3.12 Add backend tests proving apple variants do not recommend other apple variants.

## 4. Complement Rules And Scoring

- [x] 4.1 Replace broad category proximity as the main upsell signal with explicit product-family complement rules.
- [x] 4.2 Define strong complement rules for oats/cereal: milk, yogurt, banana, apple sauce, honey, breakfast fruit, or safe breakfast add-ons.
- [x] 4.3 Define strong complement rules for butter: flour, sugar, eggs, bread, baking staples, breakfast bread products, or cooking basics.
- [x] 4.4 Define strong complement rules for eggs: flour, butter, bread, baking staples, breakfast products, or cooking basics.
- [x] 4.5 Define strong complement rules for risotto/rice: parmesan or cheese, broth, mushrooms, onions, olive oil, or cooking vegetables.
- [x] 4.6 Define strong complement rules for pasta: tomato sauce, pesto, parmesan or cheese, olive oil, or fitting pasta meal add-ons.
- [x] 4.7 Define limited complement rules for cola/soft drinks: salty snacks, chips, party snacks, ice, or no suggestion if none are available.
- [x] 4.8 Define limited complement rules for cleaning spray: paper towels, cleaning cloths, sponge, trash bags, gloves, or no suggestion if none are available.
- [x] 4.9 Define limited complement rules for laundry softener: detergent, stain remover, laundry products, or no suggestion if none are available.
- [x] 4.10 Define limited complement rules for paper towels: cleaner, cloths, trash bags, napkins, or no suggestion if none are available.
- [x] 4.11 Assign relation strengths such as `strong`, `medium`, and `weak`, and map them to deterministic score bands.
- [x] 4.12 Require a stricter minimum score for fallback suggestions than for OpenAI-ranked suggestions.
- [x] 4.13 Require fallback to return an empty list instead of filling weak suggestions when no safe candidate passes the fallback threshold.
- [x] 4.14 Keep OpenAI limited to ranking and wording among already quality-gated candidates; it must not rescue a bad candidate pool.
- [x] 4.15 Add tests for each explicit complement family using real or fixture catalog candidates.
- [x] 4.16 Add tests proving fallback returns empty suggestions for no-safe-match situations.

## 5. Plan-Level Deduplication

- [x] 5.1 Add plan-level product-ID deduplication so the same product cannot be suggested for multiple opportunities in the same plan.
- [x] 5.2 Add plan-level `classKey` deduplication so equivalent variants cannot dominate multiple opportunities.
- [x] 5.3 Assign duplicated candidates to the strongest matching opportunity and suppress them from weaker opportunities.
- [x] 5.4 Refill suppressed slots only with candidates that still pass all hard gates and thresholds.
- [x] 5.5 If a refill cannot pass the threshold, leave that opportunity with fewer or zero suggestions.
- [x] 5.6 Add debug metadata or logs for duplicate suppression reasons, including product ID, class key, winning opportunity, and suppressed opportunity.
- [x] 5.7 Add tests proving repeated `Mehl` or repeated near-equivalent flour suggestions do not appear across many opportunities.
- [x] 5.8 Add tests proving deduplication never reintroduces incompatible fallback candidates.

## 6. OpenAI Request And Response Contract

- [x] 6.1 Ensure the OpenAI request is built only after hard-gated candidates are selected.
- [x] 6.2 Ensure no full catalog dump is sent to OpenAI.
- [x] 6.3 Ensure each opportunity payload includes only the source product/station context and the bounded candidate list needed for ranking.
- [x] 6.4 Include classification-derived candidate context only when it helps ranking and does not expose unnecessary catalog data.
- [x] 6.5 Keep the expected OpenAI response as structured JSON mapped to known candidate IDs.
- [x] 6.6 Validate every returned OpenAI product ID against the candidate map.
- [x] 6.7 Re-run hard gates after OpenAI returns so model output cannot bypass server rules.
- [x] 6.8 If OpenAI times out or returns invalid JSON, use only strict fallback candidates that pass the fallback threshold.
- [x] 6.9 If strict fallback has no safe candidates, return an empty suggestion list with an explicit fallback reason.
- [x] 6.10 Add tests with fake OpenAI responses containing invalid IDs, duplicate classes, incompatible domains, and too many candidates.
- [x] 6.11 Add tests proving timeout fallback does not produce weak suggestions like `Coca-Cola -> Mehl` or `Risotto -> fruit`.
- [x] 6.12 Keep request/response debug logging redacted and avoid logging secrets.

## 7. iOS Cache And Popup Semantics

- [x] 7.1 Introduce an explicit local opportunity cache state: not loaded, loaded empty, and loaded with suggestions.
- [x] 7.2 Cache backend opportunities even when their suggestions array is empty.
- [x] 7.3 Change `showOpportunity` so loaded-empty opportunities log `no_suggestions` instead of `cache_miss`.
- [x] 7.4 Normalize or bridge source keys so a plan cached under `shopping_session` can be found when the later lookup uses `shopping_list`, if the list/store/opportunity identity matches.
- [x] 7.5 Keep populated opportunity behavior unchanged when a cache hit contains suggestions.
- [x] 7.6 Keep the existing pending opportunity retry behavior, but add explicit drop reasons when the returned plan has no matching opportunity or only a loaded-empty opportunity.
- [x] 7.7 Ensure completing an item before the plan response still retries display only when suggestions arrive for that exact opportunity.
- [x] 7.8 Ensure completing an item before the plan response does not show stale suggestions from a previous product.
- [x] 7.9 Ensure adding a suggested product still marks it as `addedFromUpsell` and prevents it from generating a later upsell.
- [x] 7.10 Add iOS unit tests if the current test target can cover `UpsellSuggestionStore`; otherwise add a focused manual simulator verification script with exact expected console lines.

## 8. Logging And Debuggability

- [x] 8.1 Add backend debug logs for each opportunity: candidate count before gates, candidate count after gates, candidates sent to OpenAI, fallback reason, and final suggestion count.
- [x] 8.2 Add backend debug logs for suppressed candidates with compact reason codes such as `incompatible_domain`, `same_class`, `already_in_list`, `already_added_from_upsell`, `below_threshold`, and `deduped_plan`.
- [x] 8.3 Add backend logs for OpenAI elapsed time, timeout, invalid JSON, validation rejection count, and strict fallback usage.
- [x] 8.4 Keep backend logs free of API keys and sensitive headers.
- [x] 8.5 Add iOS logs for `loaded_empty`, `no_suggestions`, `source_key_fallback`, `pending_retry`, and `pending_drop`.
- [x] 8.6 Keep iOS logs compact enough for simulator debugging without flooding every UI render.
- [x] 8.7 Document how to interpret the new debug fields for manual testing.

## 9. Regression And Evaluation Tests

- [x] 9.1 Add backend tests for `Coca-Cola` where no flour, pasta, sauce, butter, or eggs are returned.
- [x] 9.2 Add backend tests for `Risotto` where parmesan, broth, mushrooms, onions, oil, or cooking vegetables are preferred, and fruit is rejected.
- [x] 9.3 Add backend tests for `Butter` where suitable baking/bread/cooking complements are allowed and random pasta-sauce fallback is not used unless explicitly justified by a rule.
- [x] 9.4 Add backend tests for `Eier` where safe complements can appear but duplicate or already-completed classes are suppressed.
- [x] 9.5 Add backend tests for `Bad-Reiniger` where safe household-paper or cleaning-accessory suggestions may appear, otherwise empty suggestions are returned.
- [x] 9.6 Add backend tests for `Weichspüler` where laundry-only suggestions may appear, otherwise empty suggestions are returned.
- [x] 9.7 Add backend tests for no-safe-candidate behavior returning `source=none` or strict empty fallback instead of weak suggestions.
- [x] 9.8 Add backend tests for OpenAI timeout behavior with strict fallback.
- [x] 9.9 Add backend tests for OpenAI success behavior with post-model validation.
- [x] 9.10 Add backend tests for plan-level deduplication across multiple station and item opportunities.
- [x] 9.11 Add iOS/manual tests for first-product completion while plan request is still in flight.
- [x] 9.12 Add iOS/manual tests for loaded-empty opportunity display behavior.
- [x] 9.13 Add iOS/manual tests for source mismatch between `shopping_session` and `shopping_list`.

## 10. Documentation

- [x] 10.1 Update the upsell candidate-ranking documentation with the new classifier, gates, complement matrix, fallback thresholds, and deduplication rules.
- [x] 10.2 Document that the system intentionally prefers no prompt over weak prompts.
- [x] 10.3 Document that OpenAI receives only bounded, prefiltered candidates and never the full catalog.
- [x] 10.4 Document the iOS cache states and how they map to popup behavior.
- [x] 10.5 Document the manual simulator scenarios and expected debug lines.
- [x] 10.6 Document operational config values that may need tuning after deployment.

## 11. Verification

- [x] 11.1 Run backend upsell tests with `sh ./mvnw test -Dtest=UpsellSuggestionServiceTest,MobileUpsellResourceTest`.
- [x] 11.2 Run any newly added classifier/ranking tests explicitly if they are in separate test classes.
- [x] 11.3 Run the iOS simulator build with `xcodebuild -project swift/indooro-EinkaeuferFinal/MCindooroApp.xcodeproj -scheme MCindooroApp -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build`.
- [x] 11.4 Run `npx -y @fission-ai/openspec@1.3.1 validate --all --strict`.
- [x] 11.5 Inspect `git diff` to confirm no unrelated user changes were reverted.
- [x] 11.6 Check that no API keys, secrets, or `.env` values were added to tracked files.
- [ ] 11.7 Manually test a store-selected shopping session with oats, butter, eggs, risotto, cola, cleaner, and softener.
- [ ] 11.8 Confirm manual logs show no unexpected duplicate plan requests.
- [ ] 11.9 Confirm manual logs show weak opportunities becoming empty/no-prompt instead of bad prompts.
- [ ] 11.10 Confirm session-limit is not consumed by weak prompts that should now be empty.

## 12. Deployment And Rollback

- [ ] 12.1 Commit the completed implementation only after tests and OpenSpec validation pass.
- [ ] 12.2 Deploy to LeoCloud with `kubectl -n student-it220209 apply -f k8s/backend.yaml`.
- [ ] 12.3 Restart LeoCloud backend with `kubectl -n student-it220209 rollout restart deployment/indooro-backend`.
- [ ] 12.4 Wait for LeoCloud rollout with `kubectl -n student-it220209 rollout status deployment/indooro-backend`.
- [ ] 12.5 Verify live backend logs for the new quality-gate reason codes during a real simulator test.
- [ ] 12.6 Record the rollback command or previous deployment state before considering the feature fully done.
