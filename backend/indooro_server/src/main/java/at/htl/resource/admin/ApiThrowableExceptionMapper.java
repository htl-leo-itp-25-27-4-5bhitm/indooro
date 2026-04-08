package at.htl.resource.admin;

import at.htl.admin.dto.ErrorLogDtos;
import at.htl.admin.service.ErrorLogService;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Request;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;

import java.time.Instant;

@Provider
@Priority(Priorities.USER + 1)
public class ApiThrowableExceptionMapper implements ExceptionMapper<Throwable> {

    @Inject
    ErrorLogService errorLogService;

    @Context
    UriInfo uriInfo;

    @Context
    Request request;

    @Override
    public Response toResponse(Throwable exception) {
        int status = Response.Status.INTERNAL_SERVER_ERROR.getStatusCode();
        String method = request == null ? "UNKNOWN" : request.getMethod();
        String path = uriInfo == null ? "unknown" : uriInfo.getPath();
        String message = exception == null || exception.getMessage() == null || exception.getMessage().isBlank()
                ? "Interner Serverfehler"
                : exception.getMessage();

        errorLogService.logError(status, method, path, message, exception);

        ErrorLogDtos.ApiErrorResponse payload = new ErrorLogDtos.ApiErrorResponse(
                status,
                message,
                method,
                path,
                Instant.now()
        );

        return Response.status(status)
                .type(MediaType.APPLICATION_JSON)
                .entity(payload)
                .build();
    }
}
