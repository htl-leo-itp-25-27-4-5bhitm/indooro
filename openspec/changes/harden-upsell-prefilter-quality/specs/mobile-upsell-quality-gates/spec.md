## ADDED Requirements

### Requirement: Upsell must prefer no prompt over a weak prompt
The mobile upsell system SHALL suppress opportunities when the backend cannot produce sufficiently strong and compatible suggestions.

#### Scenario: Candidate quality is weak
- **WHEN** a completed opportunity has only weak, generic, or unrelated candidates
- **THEN** the backend returns an empty suggestion list for that opportunity instead of filling the response with low-quality products

#### Scenario: Empty opportunity reaches iOS
- **WHEN** iOS receives an opportunity with an empty suggestion list
- **THEN** iOS treats it as a loaded empty result and does not log or behave as if the plan was missing

#### Scenario: Empty result is displayed
- **WHEN** a customer completes an opportunity whose loaded plan has no suggestions
- **THEN** the app skips the upsell sheet without showing an error or retrying as a cache miss

### Requirement: Product domains must not cross incompatible boundaries
The backend SHALL enforce hard compatibility boundaries between product domains before OpenAI and fallback ranking.

#### Scenario: Cleaning trigger is ranked
- **WHEN** the trigger product is a cleaner, shower cleaner, bathroom cleaner, or surface cleaner
- **THEN** food, drink, fruit, dairy, cereal, baking, and cooking candidates are excluded

#### Scenario: Laundry trigger is ranked
- **WHEN** the trigger product is detergent, softener, or laundry-adjacent
- **THEN** food, drink, fruit, dairy, cereal, baking, and cooking candidates are excluded

#### Scenario: Food trigger is ranked
- **WHEN** the trigger product is food or cooking-adjacent
- **THEN** cleaning, laundry, paper-only, hygiene, and non-food household candidates are excluded unless an explicit rule allows the pair

#### Scenario: Unknown trigger domain has no safe rule
- **WHEN** the trigger domain is unknown and no explicit compatibility rule exists
- **THEN** the backend returns no suggestions for that opportunity

### Requirement: Product-class duplicates must be excluded
The backend SHALL exclude candidates that are the same normalized product class as any current-list, completed, accepted-upsell, or trigger product unless an explicit rule allows same-class alternatives.

#### Scenario: Apple variant already exists
- **WHEN** the shopping list or completed products include an apple-class product
- **THEN** the backend excludes other apple-class products such as loose apples, organic apples, and budget apples from upsell suggestions

#### Scenario: Flour variant already exists
- **WHEN** the shopping list or completed products include a flour-class product
- **THEN** the backend excludes other flour-class products from later opportunities

#### Scenario: Suggested product was accepted
- **WHEN** the customer accepts a suggested product and it is added with `addedFromUpsell=true`
- **THEN** later opportunity scoring treats its product class as already present and suppresses equivalent products

### Requirement: Plan suggestions must avoid repetition across opportunities
The backend SHALL reduce or remove repeated products and repeated product classes across one plan response.

#### Scenario: Same candidate fits multiple opportunities
- **WHEN** the same product is a candidate for multiple opportunities in one plan
- **THEN** the backend assigns it to the strongest opportunity and suppresses it for weaker unrelated opportunities

#### Scenario: Same class repeats across plan
- **WHEN** multiple products from the same normalized product class appear across opportunities
- **THEN** the backend suppresses lower-ranked duplicates unless the product class is explicitly allowed to appear more than once

#### Scenario: Session limit exists
- **WHEN** iOS limits the number of shown upsell sheets per shopping session
- **THEN** weak or empty opportunities do not consume the session prompt count

### Requirement: Explicit complement rules must cover tested product families
The backend SHALL include explicit compatibility rules for common supermarket product families observed in tests.

#### Scenario: Oats are completed
- **WHEN** the trigger is oats, cereal, cornflakes, or muesli
- **THEN** allowed complements include milk, yogurt, fruit, banana, apple sauce, honey, or breakfast-compatible products

#### Scenario: Butter is completed
- **WHEN** the trigger is butter or butter-adjacent dairy
- **THEN** allowed complements include flour, sugar, eggs, bread, breakfast, or baking products, and pasta or tomato sauce is suppressed unless no better rule exists and quality remains high

#### Scenario: Eggs are completed
- **WHEN** the trigger is eggs
- **THEN** allowed complements include flour, butter, bread, breakfast, baking, or cooking staples

#### Scenario: Risotto is completed
- **WHEN** the trigger is risotto or rice dish
- **THEN** allowed complements include parmesan, cheese, broth, mushrooms, onion, oil, or cooking vegetables, and fruit candidates are excluded

#### Scenario: Cola is completed
- **WHEN** the trigger is cola or soft drink
- **THEN** allowed complements include snacks, chips, salty snacks, ice, or no suggestions, and flour or baking staples are excluded

#### Scenario: Cleaner is completed
- **WHEN** the trigger is cleaner or bathroom cleaner
- **THEN** allowed complements include paper towels, cleaning cloths, sponges, trash bags, gloves, or no suggestions

#### Scenario: Softener is completed
- **WHEN** the trigger is fabric softener
- **THEN** allowed complements include detergent, stain remover, laundry products, or no suggestions

### Requirement: OpenAI must only rank quality-gated candidates
OpenAI SHALL receive only candidates that already pass backend domain, product-class, duplication, and minimum-quality gates.

#### Scenario: OpenAI is enabled
- **WHEN** a plan request is sent to OpenAI
- **THEN** every candidate in the payload has already passed hard compatibility and product-class filters

#### Scenario: OpenAI returns incompatible product
- **WHEN** OpenAI returns a product id that violates opportunity-specific quality gates
- **THEN** the backend discards that suggestion even if the product id exists in the catalog

#### Scenario: Candidate pool is empty
- **WHEN** an opportunity has no quality-gated candidates
- **THEN** the backend omits that opportunity from OpenAI or sends it with an empty candidate list and returns no suggestions for it

### Requirement: Fallback must be stricter than OpenAI ranking
The deterministic fallback SHALL only return suggestions when compatibility and score evidence are strong enough without language-model judgment.

#### Scenario: OpenAI times out
- **WHEN** OpenAI is unavailable or times out
- **THEN** fallback returns suggestions only for opportunities with strong deterministic candidates

#### Scenario: Fallback candidate is merely generic
- **WHEN** a fallback candidate is present only because of a broad category relation or layout availability
- **THEN** the backend suppresses it unless a product-family rule explicitly allows it

#### Scenario: Fallback would repeat one product everywhere
- **WHEN** fallback ranking would return the same product for unrelated opportunities
- **THEN** the backend suppresses the repeated weaker occurrences

### Requirement: iOS cache must distinguish missing, empty, and populated opportunities
iOS SHALL represent upsell plan cache entries with explicit states for not loaded, loaded empty, and loaded with suggestions.

#### Scenario: Empty response is cached
- **WHEN** the backend returns an opportunity with an empty suggestion list
- **THEN** iOS stores a loaded-empty cache entry for that opportunity until the plan expiration or session reset

#### Scenario: Loaded-empty opportunity is completed
- **WHEN** the customer completes an opportunity with a loaded-empty cache entry
- **THEN** iOS logs `no_suggestions` or equivalent and does not store a pending opportunity

#### Scenario: Cache entry source differs
- **WHEN** an otherwise matching opportunity is cached for `shopping_session` but later checked with `shopping_list` source
- **THEN** iOS either normalizes the source for cache lookup or checks the equivalent session/list cache key before declaring a cache miss

### Requirement: Pending opportunity retries must be explainable
iOS SHALL log and resolve pending opportunities clearly when a plan response arrives after the customer already completed a station.

#### Scenario: Pending opportunity receives suggestions
- **WHEN** a pending opportunity appears in the returned plan with suggestions
- **THEN** iOS retries showing that opportunity once using the cached plan entry

#### Scenario: Pending opportunity receives empty result
- **WHEN** a pending opportunity appears in the returned plan with an empty suggestion list
- **THEN** iOS logs that the pending opportunity resolved with no suggestions and does not retry a sheet

#### Scenario: Pending opportunity is absent from plan
- **WHEN** a pending opportunity is no longer part of the returned plan because it was completed before preloading
- **THEN** iOS drops the pending entry and logs `pendingOpportunity dropped reason=not_in_plan` or equivalent

### Requirement: Upsell quality must be covered by repeatable evaluation tests
The implementation SHALL include repeatable tests or fixtures for the product families and failure modes observed in simulator logs.

#### Scenario: Food and non-food separation is tested
- **WHEN** tests rank cleaner, softener, cola, risotto, oats, butter, eggs, and apples
- **THEN** incompatible domain suggestions are absent from the result

#### Scenario: Duplicate product classes are tested
- **WHEN** tests include apple variants or flour variants already on the list
- **THEN** equivalent variants are not returned as upsell suggestions

#### Scenario: Empty cache state is tested
- **WHEN** iOS or store-level tests decode a loaded opportunity with no suggestions
- **THEN** cache lookup returns loaded-empty rather than cache-miss behavior
