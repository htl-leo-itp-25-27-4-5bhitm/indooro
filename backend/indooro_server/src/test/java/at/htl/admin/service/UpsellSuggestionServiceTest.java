package at.htl.admin.service;

import at.htl.admin.dto.UpsellDtos;
import at.htl.admin.entity.UpsellSuggestionCacheEntity;
import at.htl.admin.repository.UpsellSuggestionCacheRepository;
import at.htl.model.Product;
import at.htl.service.OpenSearchService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.time.Instant;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class UpsellSuggestionServiceTest {

    UpsellSuggestionService service;
    FakeOpenSearchService openSearchService;

    @BeforeEach
    void setUp() {
        service = new UpsellSuggestionService();
        openSearchService = new FakeOpenSearchService();
        service.openSearchService = openSearchService;
        service.objectMapper = new ObjectMapper().findAndRegisterModules();
        service.cacheRepository = new FakeCacheRepository();
        service.upsellEnabled = true;
        service.openAiEnabled = false;
        service.maxCandidates = 50;
        service.maxSuggestions = 3;
        service.minConfidence = 0.45;
        service.cacheTtlMinutes = 60;
        service.openAiApiKey = java.util.Optional.empty();
        service.openAiModel = "test-model";
        service.openAiTimeoutMs = 1000;
        service.perOpportunityCandidates = 10;
        service.minDeterministicScore = 40;
    }

    @Test
    void fallbackSuggestionsExcludeCheckedCurrentAndCompletedProducts() {
        UpsellDtos.UpsellSuggestionResponse response = service.suggestions(new UpsellDtos.UpsellSuggestionRequest(
                null,
                null,
                1,
                "local-list",
                List.of(3),
                List.of(4),
                "shopping_session",
                null
        ));

        List<Integer> ids = response.suggestions().stream()
                .map(suggestion -> suggestion.product().id())
                .toList();

        assertFalse(ids.contains(1));
        assertFalse(ids.contains(3));
        assertFalse(ids.contains(4));
        assertFalse(ids.isEmpty());
        assertEquals("fallback", response.source());
    }

    @Test
    void fallbackSuggestionsExcludeAcceptedUpsellWhenItIsInCurrentListInput() {
        UpsellDtos.UpsellSuggestionResponse response = service.suggestions(new UpsellDtos.UpsellSuggestionRequest(
                null,
                null,
                1,
                "local-list",
                List.of(2),
                List.of(),
                "shopping_session",
                null
        ));

        List<Integer> ids = response.suggestions().stream()
                .map(suggestion -> suggestion.product().id())
                .toList();

        assertFalse(ids.contains(1));
        assertFalse(ids.contains(2));
        assertFalse(ids.isEmpty());
        assertEquals("fallback", response.source());
    }

    @Test
    void invalidCheckedProductReturnsNotFound() {
        jakarta.ws.rs.NotFoundException exception = assertThrows(
                jakarta.ws.rs.NotFoundException.class,
                () -> service.suggestions(new UpsellDtos.UpsellSuggestionRequest(
                        null,
                        null,
                        999,
                        "local-list",
                        List.of(),
                        List.of(),
                        "shopping_session",
                        null
                ))
        );

        assertEquals(404, exception.getResponse().getStatus());
    }

    @Test
    void disabledUpsellReturnsEmptyDisabledResponseWithoutOpenAiKey() {
        service.upsellEnabled = false;
        service.openAiEnabled = true;
        service.openAiApiKey = Optional.empty();

        UpsellDtos.UpsellSuggestionResponse response = service.suggestions(new UpsellDtos.UpsellSuggestionRequest(
                null,
                null,
                1,
                "local-list",
                List.of(),
                List.of(),
                "shopping_session",
                null
        ));

        assertEquals("disabled", response.source());
        assertTrue(response.suggestions().isEmpty());
    }

    @Test
    void emptyCandidatePoolReturnsEmptySuggestions() {
        openSearchService.emptyCandidates = true;

        UpsellDtos.UpsellSuggestionResponse response = service.suggestions(new UpsellDtos.UpsellSuggestionRequest(
                null,
                null,
                1,
                "local-list",
                List.of(),
                List.of(),
                "shopping_session",
                null
        ));

        assertEquals("none", response.source());
        assertTrue(response.suggestions().isEmpty());
    }

    @Test
    void suggestionResponsesAreReturnedFromCacheForMatchingContext() {
        UpsellDtos.UpsellSuggestionRequest request = new UpsellDtos.UpsellSuggestionRequest(
                null,
                null,
                1,
                "local-list",
                List.of(1, 3),
                List.of(4),
                "shopping_session",
                null
        );

        UpsellDtos.UpsellSuggestionResponse first = service.suggestions(request);
        int lookupsAfterFirstCall = openSearchService.productLookups;

        UpsellDtos.UpsellSuggestionResponse second = service.suggestions(request);

        assertEquals("fallback", first.source());
        assertEquals("cache", second.source());
        assertEquals(lookupsAfterFirstCall, openSearchService.productLookups);
        assertEquals(first.suggestions().stream().map(suggestion -> suggestion.product().id()).toList(),
                second.suggestions().stream().map(suggestion -> suggestion.product().id()).toList());
    }

    @Test
    void planResponsesGroupStationOpportunitiesAndExcludeListProducts() {
        UpsellDtos.UpsellPlanResponse response = service.plan(new UpsellDtos.UpsellPlanRequest(
                null,
                "SPAR",
                "local-list",
                List.of(1, 3),
                List.of(),
                "shopping_session",
                List.of(new UpsellDtos.UpsellOpportunityRequest(
                        "station:shelf-430",
                        List.of(1, 3),
                        List.of("Spaghetti", "Tomatensauce")
                ))
        ));

        assertEquals("fallback", response.source());
        assertEquals(1, response.opportunities().size());
        assertEquals("station:shelf-430", response.opportunities().get(0).opportunityId());

        List<Integer> ids = response.opportunities().get(0).suggestions().stream()
                .map(suggestion -> suggestion.product().id())
                .toList();

        assertFalse(ids.contains(1));
        assertFalse(ids.contains(3));
        assertTrue(ids.contains(2));
    }

    @Test
    void planResponsesIncludeMultipleOpportunities() {
        UpsellDtos.UpsellPlanResponse response = service.plan(new UpsellDtos.UpsellPlanRequest(
                null,
                "SPAR",
                "local-list",
                List.of(),
                List.of(),
                "shopping_session",
                List.of(
                        new UpsellDtos.UpsellOpportunityRequest(
                                "station:shelf-430",
                                List.of(1),
                                List.of("Spaghetti")
                        ),
                        new UpsellDtos.UpsellOpportunityRequest(
                                "station:shelf-525",
                                List.of(4),
                                List.of("Basilikum")
                        )
                )
        ));

        assertEquals("fallback", response.source());
        assertEquals(2, response.opportunities().size());
        assertEquals("station:shelf-430", response.opportunities().get(0).opportunityId());
        assertEquals("station:shelf-525", response.opportunities().get(1).opportunityId());
    }

    @Test
    void emptyPlanCandidatePoolReturnsEmptyOpportunitySuggestions() {
        openSearchService.emptyCandidates = true;

        UpsellDtos.UpsellPlanResponse response = service.plan(new UpsellDtos.UpsellPlanRequest(
                null,
                "SPAR",
                "local-list",
                List.of(),
                List.of(),
                "shopping_session",
                List.of(new UpsellDtos.UpsellOpportunityRequest(
                        "station:shelf-430",
                        List.of(1),
                        List.of("Spaghetti")
                ))
        ));

        assertEquals("none", response.source());
        assertEquals(1, response.opportunities().size());
        assertTrue(response.opportunities().get(0).suggestions().isEmpty());
        assertEquals("no_candidates", response.debug().fallbackReason());
    }

    @Test
    void invalidEmptyPlanRequestIsRejected() {
        jakarta.ws.rs.WebApplicationException exception = assertThrows(
                jakarta.ws.rs.WebApplicationException.class,
                () -> service.plan(new UpsellDtos.UpsellPlanRequest(
                        null,
                        "SPAR",
                        "local-list",
                        List.of(),
                        List.of(),
                        "shopping_session",
                        List.of()
                ))
        );

        assertEquals(400, exception.getResponse().getStatus());
    }

    @Test
    void planResponsesAreReturnedFromCacheForMatchingRouteContext() {
        UpsellDtos.UpsellPlanRequest request = new UpsellDtos.UpsellPlanRequest(
                null,
                "SPAR",
                "local-list",
                List.of(1, 3),
                List.of(),
                "shopping_session",
                List.of(new UpsellDtos.UpsellOpportunityRequest(
                        "station:shelf-430",
                        List.of(1, 3),
                        List.of("Spaghetti", "Tomatensauce")
                ))
        );

        UpsellDtos.UpsellPlanResponse first = service.plan(request);
        int lookupsAfterFirstCall = openSearchService.productLookups;

        UpsellDtos.UpsellPlanResponse second = service.plan(request);

        assertEquals("fallback", first.source());
        assertEquals("cache", second.source());
        assertEquals(lookupsAfterFirstCall, openSearchService.productLookups);
        assertEquals(
                first.opportunities().get(0).suggestions().stream().map(suggestion -> suggestion.product().id()).toList(),
                second.opportunities().get(0).suggestions().stream().map(suggestion -> suggestion.product().id()).toList()
        );
    }

    @Test
    void contextHashMatchesPreloadAndCompletedFormsForSameOpportunity() {
        UpsellDtos.UpsellSuggestionRequest preload = new UpsellDtos.UpsellSuggestionRequest(
                null,
                "SPAR",
                1,
                "local-list",
                List.of(1, 3),
                List.of(4),
                "shopping_session",
                null
        );
        UpsellDtos.UpsellSuggestionRequest completed = new UpsellDtos.UpsellSuggestionRequest(
                null,
                "spar",
                1,
                "local-list",
                List.of(3),
                List.of(1, 4),
                "shopping_session",
                null
        );

        assertEquals(service.contextHash(preload), service.contextHash(completed));
    }

    @Test
    void validatedSuggestionsDiscardUnknownAiProductIds() {
        Map<Integer, Product> candidateMap = Map.of(
                2, new Product(2, "Parmesan", 2.99, "525/1/1/1")
        );

        List<UpsellDtos.UpsellSuggestion> suggestions = service.validatedSuggestions(
                List.of(
                        new UpsellDtos.AiSuggestion(999, "Unbekannt", 0.99),
                        new UpsellDtos.AiSuggestion(2, "Passt gut dazu.", 0.90)
                ),
                candidateMap
        );

        assertEquals(1, suggestions.size());
        assertEquals(2, suggestions.get(0).product().id());
    }

    @Test
    void lowConfidenceSuggestionsAreDiscarded() {
        Map<Integer, Product> candidateMap = Map.of(
                2, new Product(2, "Parmesan", 2.99, "525/1/1/1")
        );

        List<UpsellDtos.UpsellSuggestion> suggestions = service.validatedSuggestions(
                List.of(new UpsellDtos.AiSuggestion(2, "Passt gut dazu.", 0.10)),
                candidateMap
        );

        assertTrue(suggestions.isEmpty());
    }

    @Test
    void categoryExtractionHandlesInvalidLayoutCodes() {
        assertEquals("525", service.categoryCode("525/1/1/1"));
        assertEquals("430", service.categoryCode(" 430 "));
        assertEquals("invalid", service.categoryCode("invalid"));
        assertEquals(null, service.categoryCode(null));
        assertEquals(null, service.categoryCode(" "));
    }

    @Test
    void productNameNormalizationAddsGermanSafeAliasTokens() {
        assertTrue(service.productNameTokens("Aepfel & Joghurt").contains("aepfel"));
        assertTrue(service.productNameTokens("Aepfel & Joghurt").contains("fruit"));
        assertTrue(service.productNameTokens("Aepfel & Joghurt").contains("dairy"));
        assertTrue(service.productNameTokens("Olivenoel").contains("oil"));
    }

    @Test
    void butterPlanFallbackPrefersBreadBreakfastAndBakingOverPastaSauce() {
        UpsellDtos.UpsellPlanResponse response = service.plan(new UpsellDtos.UpsellPlanRequest(
                null,
                "SPAR",
                "local-list",
                List.of(30),
                List.of(),
                "shopping_session",
                List.of(new UpsellDtos.UpsellOpportunityRequest(
                        "station:shelf-525",
                        List.of(30),
                        List.of("Butter 250g")
                ))
        ));

        List<Integer> ids = response.opportunities().get(0).suggestions().stream()
                .map(suggestion -> suggestion.product().id())
                .toList();

        assertEquals("fallback", response.source());
        assertFalse(ids.contains(1));
        assertFalse(ids.contains(3));
        assertTrue(ids.stream().anyMatch(id -> List.of(20, 21, 22, 23, 24).contains(id)));
    }

    @Test
    void planFallbackRanksEachOpportunitySeparately() {
        UpsellDtos.UpsellPlanResponse response = service.plan(new UpsellDtos.UpsellPlanRequest(
                null,
                "SPAR",
                "local-list",
                List.of(1, 30),
                List.of(),
                "shopping_session",
                List.of(
                        new UpsellDtos.UpsellOpportunityRequest(
                                "station:pasta",
                                List.of(1),
                                List.of("Spaghetti")
                        ),
                        new UpsellDtos.UpsellOpportunityRequest(
                                "station:butter",
                                List.of(30),
                                List.of("Butter")
                        )
                )
        ));

        List<Integer> pastaIds = response.opportunities().get(0).suggestions().stream()
                .map(suggestion -> suggestion.product().id())
                .toList();
        List<Integer> butterIds = response.opportunities().get(1).suggestions().stream()
                .map(suggestion -> suggestion.product().id())
                .toList();

        assertTrue(pastaIds.contains(3));
        assertFalse(butterIds.contains(3));
        assertTrue(butterIds.stream().anyMatch(id -> List.of(20, 21, 22, 23, 24).contains(id)));
    }

    @Test
    void fruitPlanFallbackPrefersYogurtOatsAndBreakfastCandidates() {
        UpsellDtos.UpsellPlanResponse response = service.plan(new UpsellDtos.UpsellPlanRequest(
                null,
                "SPAR",
                "local-list",
                List.of(40),
                List.of(),
                "shopping_session",
                List.of(new UpsellDtos.UpsellOpportunityRequest(
                        "station:fruit",
                        List.of(40),
                        List.of("Aepfel")
                ))
        ));

        List<Integer> ids = response.opportunities().get(0).suggestions().stream()
                .map(suggestion -> suggestion.product().id())
                .toList();

        assertTrue(ids.contains(41), ids::toString);
        assertTrue(ids.contains(42), ids::toString);
    }

    @Test
    void oatsPlanFallbackPrefersMilkYogurtAndFruitCandidates() {
        UpsellDtos.UpsellPlanResponse response = service.plan(new UpsellDtos.UpsellPlanRequest(
                null,
                "SPAR",
                "local-list",
                List.of(42),
                List.of(),
                "shopping_session",
                List.of(new UpsellDtos.UpsellOpportunityRequest(
                        "station:oats",
                        List.of(42),
                        List.of("Haferflocken")
                ))
        ));

        List<Integer> ids = response.opportunities().get(0).suggestions().stream()
                .map(suggestion -> suggestion.product().id())
                .toList();

        assertTrue(ids.contains(24), ids::toString);
        assertTrue(ids.contains(40) || ids.contains(41), ids::toString);
    }

    @Test
    void unknownCategoryCanReturnNoRankedCandidatesInsteadOfFabricatingProducts() {
        UpsellDtos.UpsellPlanResponse response = service.plan(new UpsellDtos.UpsellPlanRequest(
                null,
                "SPAR",
                "local-list",
                List.of(60),
                List.of(),
                "shopping_session",
                List.of(new UpsellDtos.UpsellOpportunityRequest(
                        "station:unknown",
                        List.of(60),
                        List.of("Batterie")
                ))
        ));

        assertEquals("none", response.source());
        assertTrue(response.opportunities().get(0).suggestions().isEmpty());
        assertEquals("no_ranked_candidates", response.debug().fallbackReason());
    }

    private static final class FakeOpenSearchService extends OpenSearchService {
        int productLookups = 0;
        boolean emptyCandidates = false;
        final Map<Integer, Product> products = new LinkedHashMap<>();

        FakeOpenSearchService() {
            products.put(1, new Product(1, "Spaghetti", 1.49, "430/1/1/1"));
            products.put(2, new Product(2, "Parmesan", 2.99, "525/1/1/1"));
            products.put(3, new Product(3, "Tomatensauce", 1.99, "420/1/1/1"));
            products.put(4, new Product(4, "Basilikum", 1.29, "310/1/1/1"));
            products.put(5, new Product(5, "Olivenoel", 4.99, "450/1/1/1"));
            products.put(20, new Product(20, "Toastbrot 500g", 1.79, "510/1/1/1"));
            products.put(21, new Product(21, "Marillenmarmelade 450g", 2.49, "470/1/1/1"));
            products.put(22, new Product(22, "Freilandeier 10 Stueck", 3.79, "445/1/1/1"));
            products.put(23, new Product(23, "Weizenmehl 1kg", 0.99, "445/1/1/1"));
            products.put(24, new Product(24, "Vollmilch 1L", 1.39, "520/1/1/1"));
            products.put(30, new Product(30, "Butter 250g", 2.39, "525/1/1/2"));
            products.put(40, new Product(40, "Aepfel 1kg", 2.99, "310/1/1/1"));
            products.put(41, new Product(41, "Naturjoghurt 500g", 1.49, "520/1/1/2"));
            products.put(42, new Product(42, "Haferflocken 500g", 1.19, "440/1/1/1"));
            products.put(60, new Product(60, "Batterie AA 4er", 3.99, "999/1/1/1"));
        }

        @Override
        public Product getProductById(Integer id) throws IOException {
            productLookups++;
            return products.get(id);
        }

        @Override
        public List<Product> findUpsellCandidates(Integer size, String storeId, String storeCode) throws IOException {
            if (emptyCandidates) {
                return List.of();
            }
            return products.values().stream()
                    .limit(size == null ? products.size() : size)
                    .toList();
        }
    }

    private static final class FakeCacheRepository extends UpsellSuggestionCacheRepository {
        private final Map<String, UpsellSuggestionCacheEntity> entries = new HashMap<>();

        @Override
        public Optional<UpsellSuggestionCacheEntity> findFreshByContextHash(String contextHash, Instant now) {
            return Optional.ofNullable(entries.get(contextHash))
                    .filter(entry -> entry.expiresAt.isAfter(now));
        }

        @Override
        public Optional<UpsellSuggestionCacheEntity> findByContextHash(String contextHash) {
            return Optional.ofNullable(entries.get(contextHash));
        }

        @Override
        public void upsert(UpsellSuggestionCacheEntity incoming) {
            entries.put(incoming.contextHash, incoming);
        }
    }
}
