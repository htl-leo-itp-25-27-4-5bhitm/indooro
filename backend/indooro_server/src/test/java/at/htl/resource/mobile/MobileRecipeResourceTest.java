package at.htl.resource.mobile;

import at.htl.admin.dto.CommonDtos;
import at.htl.admin.dto.RecipeDtos;
import at.htl.admin.service.RecipeService;
import io.quarkus.test.InjectMock;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.hasItems;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@QuarkusTest
class MobileRecipeResourceTest {

    private static final UUID RECIPE_ID = UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    private static final UUID STORE_ID = UUID.fromString("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
    private static final UUID INGREDIENT_ID = UUID.fromString("cccccccc-cccc-cccc-cccc-cccccccccccc");

    @InjectMock
    RecipeService recipeService;

    @Test
    void listsPublishedRecipes() {
        when(recipeService.listMobileRecipes(eq(null), eq(null), eq(0), eq(20), eq(null)))
                .thenReturn(new CommonDtos.PageResponse<>(List.of(summary()), 0, 20, 1));

        given()
                .when().get("/api/mobile/recipes")
                .then()
                .statusCode(200)
                .body("content[0].id", equalTo(RECIPE_ID.toString()))
                .body("content[0].title", equalTo("Tomaten Pasta"))
                .body("content[0].mappedIngredientCount", equalTo(1));
    }

    @Test
    void searchesWithRequiredQuery() {
        when(recipeService.listMobileRecipes(eq("pasta"), eq(null), eq(0), eq(20), eq(null)))
                .thenReturn(new CommonDtos.PageResponse<>(List.of(summary()), 0, 20, 1));

        given()
                .queryParam("q", "pasta")
                .when().get("/api/mobile/recipes/search")
                .then()
                .statusCode(200)
                .body("content[0].slug", equalTo("tomaten-pasta"));

        given()
                .queryParam("q", "x")
                .when().get("/api/mobile/recipes/search")
                .then()
                .statusCode(400);
    }

    @Test
    void returnsRecipeDetail() {
        when(recipeService.getMobileRecipe(RECIPE_ID)).thenReturn(detail());

        given()
                .when().get("/api/mobile/recipes/{recipeId}", RECIPE_ID)
                .then()
                .statusCode(200)
                .body("ingredients[0].displayName", equalTo("Tomaten"))
                .body("steps[0].instruction", equalTo("Nudeln kochen."));
    }

    @Test
    void hidesUnpublishedRecipesThroughService404() {
        when(recipeService.getMobileRecipe(RECIPE_ID))
                .thenThrow(new WebApplicationException("Rezept nicht gefunden.", Response.Status.NOT_FOUND));

        given()
                .when().get("/api/mobile/recipes/{recipeId}", RECIPE_ID)
                .then()
                .statusCode(404);
    }

    @Test
    void returnsStoreAwareMappingStatuses() {
        when(recipeService.mappingStatus(RECIPE_ID, STORE_ID, "demo-store", true))
                .thenReturn(mapping());

        given()
                .queryParam("storeId", STORE_ID)
                .queryParam("storeCode", "demo-store")
                .when().get("/api/mobile/recipes/{recipeId}/product-mapping", RECIPE_ID)
                .then()
                .statusCode(200)
                .body("storeId", equalTo(STORE_ID.toString()))
                .body("ingredients.status", hasItems(
                        "MAPPED",
                        "UNMAPPED",
                        "MULTIPLE_CANDIDATES",
                        "UNAVAILABLE_IN_STORE",
                        "PRODUCT_WITHOUT_LAYOUT"
                ));
    }

    private RecipeDtos.RecipeSummaryResponse summary() {
        return new RecipeDtos.RecipeSummaryResponse(
                RECIPE_ID,
                "tomaten-pasta",
                "Tomaten Pasta",
                "Schnelle Pasta",
                null,
                2,
                10,
                15,
                25,
                "PUBLISHED",
                null,
                1,
                2,
                List.of(new RecipeDtos.RecipeTagResponse(UUID.randomUUID(), "quick", "Schnell", "category", "ACTIVE"))
        );
    }

    private RecipeDtos.RecipeDetailResponse detail() {
        return new RecipeDtos.RecipeDetailResponse(
                RECIPE_ID,
                "tomaten-pasta",
                "Tomaten Pasta",
                "Schnelle Pasta",
                "Eine einfache Tomatenpasta.",
                null,
                null,
                2,
                10,
                15,
                25,
                "PUBLISHED",
                null,
                null,
                null,
                null,
                List.of(),
                List.of(new RecipeDtos.RecipeIngredientResponse(
                        INGREDIENT_ID,
                        1,
                        "Tomaten",
                        "tomato",
                        BigDecimal.valueOf(250),
                        "250",
                        "g",
                        "Gramm",
                        null,
                        false
                )),
                List.of(new RecipeDtos.RecipeStepResponse(UUID.randomUUID(), 1, "Nudeln kochen.", 10))
        );
    }

    private RecipeDtos.RecipeProductMappingResponse mapping() {
        return new RecipeDtos.RecipeProductMappingResponse(
                RECIPE_ID,
                STORE_ID,
                "demo-store",
                List.of(
                        mappingStatus("MAPPED", new RecipeDtos.MappedRecipeProduct(1, "Tomaten", 1.99, "310/1", STORE_ID.toString(), "demo-store")),
                        mappingStatus("UNMAPPED", null),
                        mappingStatus("MULTIPLE_CANDIDATES", null),
                        mappingStatus("UNAVAILABLE_IN_STORE", null),
                        mappingStatus("PRODUCT_WITHOUT_LAYOUT", new RecipeDtos.MappedRecipeProduct(2, "Pasta", 2.49, null, STORE_ID.toString(), "demo-store"))
                )
        );
    }

    private RecipeDtos.IngredientMappingStatusResponse mappingStatus(
            String status,
            RecipeDtos.MappedRecipeProduct product
    ) {
        return new RecipeDtos.IngredientMappingStatusResponse(
                UUID.randomUUID(),
                "Zutat",
                status,
                product,
                List.of(),
                product == null ? null : BigDecimal.ONE,
                product != null,
                product == null ? "Keine sichere Zuordnung." : null
        );
    }
}
