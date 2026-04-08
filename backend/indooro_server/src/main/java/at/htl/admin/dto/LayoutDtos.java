package at.htl.admin.dto;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public final class LayoutDtos {

    private LayoutDtos() {
    }

    public record LayoutSaveRequest(
            @Size(max = 150) String layoutName,
            @Size(max = 2_000) String changeNote,
            Boolean activate,
            @NotNull JsonNode layout
    ) {
    }

    public record StoreLayoutResponse(
            UUID layoutId,
            UUID storeId,
            Integer versionNo,
            String status,
            Instant createdAt,
            Instant activatedAt,
            JsonNode layout
    ) {
    }

    public record LayoutVersionSummary(
            UUID layoutId,
            Integer versionNo,
            String layoutName,
            String status,
            Instant createdAt,
            Instant activatedAt
    ) {
    }

    public record StoreEditorReference(
            UUID id,
            String storeCode,
            String name
    ) {
    }

    public record EditorBeaconResponse(
            UUID beaconId,
            String beaconCode,
            String identityKey,
            UUID uuid,
            Integer major,
            Integer minor
    ) {
    }

    public record EditorContextResponse(
            StoreEditorReference store,
            StoreLayoutResponse currentLayout,
            List<EditorBeaconResponse> assignedBeacons
    ) {
    }
}
