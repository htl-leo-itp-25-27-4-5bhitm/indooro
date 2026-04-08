package at.htl.admin.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public final class AdminLogDtos {

    private AdminLogDtos() {
    }

    public record SystemLogEntry(
            UUID id,
            String entityType,
            UUID entityId,
            String action,
            String summary,
            String actorRole,
            String actorLabel,
            Instant createdAt
    ) {
    }

    public record SystemLogResponse(
            int limit,
            List<SystemLogEntry> entries
    ) {
    }
}
