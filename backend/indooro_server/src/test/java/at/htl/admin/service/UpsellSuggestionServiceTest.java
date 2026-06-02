package at.htl.admin.service;

import at.htl.admin.dto.UpsellDtos;
import at.htl.model.Product;
import at.htl.service.OpenSearchService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class UpsellSuggestionServiceTest {

    UpsellSuggestionService service;

    @BeforeEach
    void setUp() {
        service = new UpsellSuggestionService();
        service.openSearchService = new FakeOpenSearchService();
        service.objectMapper = new ObjectMapper();
        service.upsellEnabled = true;
        service.openAiEnabled = false;
        service.maxCandidates = 10;
        service.maxSuggestions = 3;
        service.minConfidence = 0.45;
        service.cacheTtlMinutes = 60;
        service.openAiApiKey = java.util.Optional.empty();
        service.openAiModel = "test-model";
        service.openAiTimeoutMs = 1000;
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
        assertTrue(ids.contains(2));
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

    private static final class FakeOpenSearchService extends OpenSearchService {
        @Override
        public Product getProductById(Integer id) throws IOException {
            if (id == 1) {
                return new Product(1, "Spaghetti", 1.49, "430/1/1/1");
            }
            return null;
        }

        @Override
        public List<Product> findUpsellCandidates(Integer size, String storeId, String storeCode) throws IOException {
            return List.of(
                    new Product(1, "Spaghetti", 1.49, "430/1/1/1"),
                    new Product(2, "Parmesan", 2.99, "525/1/1/1"),
                    new Product(3, "Tomatensauce", 1.99, "420/1/1/1"),
                    new Product(4, "Basilikum", 1.29, "310/1/1/1"),
                    new Product(5, "Olivenoel", 4.99, "450/1/1/1")
            );
        }
    }
}
