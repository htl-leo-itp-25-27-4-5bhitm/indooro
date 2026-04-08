package at.htl.resource.admin;

import at.htl.admin.dto.AdminLogDtos;
import at.htl.admin.service.AuditLogService;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;

@Path("/api/admin/logs")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AdminLogResource extends AdminApiSupport {

    @Inject
    AuditLogService auditLogService;

    @GET
    public AdminLogDtos.SystemLogResponse getRecentLogs(@QueryParam("limit") @DefaultValue("20") int limit) {
        return auditLogService.getRecentLogs(normalizeSize(limit));
    }
}
