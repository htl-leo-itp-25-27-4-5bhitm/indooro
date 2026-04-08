package at.htl.admin.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public final class ErrorLogDtos {

    private ErrorLogDtos() {
    }

    public record ErrorLogEntry(
            UUID id,
            int statusCode,
            String method,
            String path,
            String message,
            String errorType,
            String stackTrace,
            Instant createdAt
    ) {
    }

    public record ErrorLogResponse(
            int limit,
            List<ErrorLogEntry> entries
    ) {
    }

    public record ApiErrorResponse(
            int status,
            String error,
            String method,
            String path,
            Instant timestamp
    ) {
    }
}
