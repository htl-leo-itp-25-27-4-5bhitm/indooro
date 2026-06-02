package at.htl.admin.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public final class UpsellDtos {

    private UpsellDtos() {
    }

    public record UpsellSuggestionRequest(
            UUID storeId,
            @Size(max = 50) String storeCode,
            @NotNull Integer checkedProductId,
            @Size(max = 80) String shoppingListId,
            List<Integer> currentListProductIds,
            List<Integer> completedProductIds,
            @Size(max = 50) String source,
            UUID recipeId
    ) {
    }

    public record UpsellProductSummary(
            Integer id,
            String name,
            Double price,
            String layoutCode,
            String storeId,
            String storeCode,
            String brand,
            String category,
            String imageUrl,
            boolean hasLayoutPosition
    ) {
    }

    public record UpsellSuggestion(
            UpsellProductSummary product,
            String reason,
            @DecimalMin("0.0") @DecimalMax("1.0") double confidence
    ) {
    }

    public record UpsellSuggestionResponse(
            Integer checkedProductId,
            List<UpsellSuggestion> suggestions,
            String source,
            Instant expiresAt
    ) {
    }

    public record UpsellEventRequest(
            @NotBlank @Size(max = 40) String eventType,
            Integer checkedProductId,
            Integer suggestedProductId,
            UUID storeId,
            @Size(max = 50) String storeCode,
            @Size(max = 120) String sessionId,
            @Size(max = 40) String source,
            @Size(max = 4_000) String metadataJson
    ) {
    }

    public record UpsellDismissRequest(
            @NotNull Integer checkedProductId,
            Integer suggestedProductId,
            UUID storeId,
            @Size(max = 50) String storeCode,
            @Size(max = 120) String sessionId,
            @Min(1) @Max(30) Integer suppressMinutes
    ) {
    }

    public record AiSuggestion(
            @NotNull Integer productId,
            @Size(max = 180) String reason,
            @DecimalMin("0.0") @DecimalMax("1.0") Double confidence
    ) {
    }

    public record AiSuggestionResponse(
            List<AiSuggestion> suggestions
    ) {
    }
}
