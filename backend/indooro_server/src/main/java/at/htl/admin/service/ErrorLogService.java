package at.htl.admin.service;

import at.htl.admin.dto.ErrorLogDtos;
import at.htl.admin.entity.ErrorLogEntity;
import at.htl.admin.repository.ErrorLogRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.List;

@ApplicationScoped
public class ErrorLogService {

    private static final int MAX_STACK_TRACE_LENGTH = 12000;

    @Inject
    ErrorLogRepository errorLogRepository;

    @Transactional
    public void logError(int statusCode, String method, String path, String message, Throwable throwable) {
        ErrorLogEntity entry = new ErrorLogEntity();
        entry.statusCode = statusCode;
        entry.method = truncate(method, 16);
        entry.path = truncate(path == null || path.isBlank() ? "unknown" : path, 300);
        entry.message = truncate(message, 8000);
        entry.errorType = throwable == null ? null : truncate(throwable.getClass().getName(), 200);
        entry.stackTrace = throwable == null ? null : truncate(toStackTrace(throwable), MAX_STACK_TRACE_LENGTH);
        errorLogRepository.persist(entry);
    }

    public ErrorLogDtos.ErrorLogResponse getRecentLogs(int limit) {
        int normalizedLimit = Math.min(Math.max(limit, 1), 100);
        List<ErrorLogDtos.ErrorLogEntry> entries = errorLogRepository.listRecent(normalizedLimit).stream()
                .map(this::toEntry)
                .toList();
        return new ErrorLogDtos.ErrorLogResponse(normalizedLimit, entries);
    }

    private ErrorLogDtos.ErrorLogEntry toEntry(ErrorLogEntity entry) {
        return new ErrorLogDtos.ErrorLogEntry(
                entry.id,
                entry.statusCode,
                entry.method,
                entry.path,
                entry.message,
                entry.errorType,
                entry.stackTrace,
                entry.createdAt
        );
    }

    private String toStackTrace(Throwable throwable) {
        StringWriter stringWriter = new StringWriter();
        throwable.printStackTrace(new PrintWriter(stringWriter));
        return stringWriter.toString();
    }

    private String truncate(String value, int maxLength) {
        if (value == null) {
            return null;
        }
        return value.length() <= maxLength ? value : value.substring(0, maxLength);
    }
}
