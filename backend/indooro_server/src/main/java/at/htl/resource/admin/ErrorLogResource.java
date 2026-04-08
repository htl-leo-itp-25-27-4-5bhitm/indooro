package at.htl.resource.admin;

import at.htl.admin.dto.ErrorLogDtos;
import at.htl.admin.service.ErrorLogService;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;

@Path("/api/admin/error-logs")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ErrorLogResource extends AdminApiSupport {

    @Inject
    ErrorLogService errorLogService;

    @GET
    public ErrorLogDtos.ErrorLogResponse getRecentErrorLogs(@QueryParam("limit") @DefaultValue("50") int limit) {
        return errorLogService.getRecentLogs(limit);
    }
}
