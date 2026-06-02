package at.htl.resource.mobile;

import at.htl.admin.dto.UpsellDtos;
import at.htl.admin.service.UpsellSuggestionService;
import io.quarkus.test.InjectMock;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.equalTo;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;

@QuarkusTest
class MobileUpsellResourceTest {

    private static final UUID STORE_ID = UUID.fromString("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");

    @InjectMock
    UpsellSuggestionService upsellSuggestionService;

    @Test
    void returnsValidatedSuggestions() {
        when(upsellSuggestionService.suggestions(any()))
                .thenReturn(new UpsellDtos.UpsellSuggestionResponse(
                        1,
                        List.of(new UpsellDtos.UpsellSuggestion(
                                new UpsellDtos.UpsellProductSummary(
                                        2,
                                        "Parmesan",
                                        2.99,
                                        "525/1/1/1",
                                        STORE_ID.toString(),
                                        "demo-store",
                                        null,
                                        "525",
                                        null,
                                        true
                                ),
                                "Passt gut dazu.",
                                0.88
                        )),
                        "fallback",
                        Instant.parse("2026-06-02T12:00:00Z")
                ));

        given()
                .contentType("application/json")
                .body("""
                        {
                          "storeId": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                          "storeCode": "demo-store",
                          "checkedProductId": 1,
                          "shoppingListId": "local-list",
                          "currentListProductIds": [1],
                          "completedProductIds": [1],
                          "source": "shopping_session"
                        }
                        """)
                .when().post("/api/mobile/upsell/suggestions")
                .then()
                .statusCode(200)
                .body("checkedProductId", equalTo(1))
                .body("suggestions[0].product.id", equalTo(2))
                .body("suggestions[0].product.hasLayoutPosition", equalTo(true))
                .body("suggestions[0].reason", equalTo("Passt gut dazu."));
    }

    @Test
    void invalidCheckedProductReturnsNotFound() {
        when(upsellSuggestionService.suggestions(any()))
                .thenThrow(new WebApplicationException("Produkt nicht gefunden.", Response.Status.NOT_FOUND));

        given()
                .contentType("application/json")
                .body("{\"checkedProductId\":999}")
                .when().post("/api/mobile/upsell/suggestions")
                .then()
                .statusCode(404);
    }

    @Test
    void recordsEventsAndDismissals() {
        doNothing().when(upsellSuggestionService).recordEvent(any());
        doNothing().when(upsellSuggestionService).dismiss(any());

        given()
                .contentType("application/json")
                .body("{\"eventType\":\"dismissed\",\"checkedProductId\":1,\"suggestedProductId\":2}")
                .when().post("/api/mobile/upsell/events")
                .then()
                .statusCode(202);

        given()
                .contentType("application/json")
                .body("{\"checkedProductId\":1,\"suggestedProductId\":2}")
                .when().post("/api/mobile/upsell/dismiss")
                .then()
                .statusCode(202);
    }
}
