package at.htl.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.UUID;

public final class RegionDtos {

    private RegionDtos() {
    }

    public record RegionUpsertRequest(
            @NotBlank @Size(max = 50) String code,
            @NotBlank @Size(max = 120) String name,
            @Size(max = 2_000) String description
    ) {
    }

    public record RegionResponse(
            UUID id,
            String code,
            String name,
            String description,
            String status,
            Instant createdAt,
            Instant updatedAt
    ) {
    }
}
