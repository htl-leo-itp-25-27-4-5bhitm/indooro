package at.htl.resource.admin;

import at.htl.admin.dto.AdminUserDtos;
import at.htl.admin.service.AdminAccessService;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("/api/admin/me")
@RolesAllowed({"admin", "region-manager", "store-manager"})
@Produces(MediaType.APPLICATION_JSON)
public class AdminCurrentUserResource {

    @Inject
    AdminAccessService adminAccessService;

    @GET
    public AdminUserDtos.CurrentUserResponse me() {
        return adminAccessService.currentUserResponse();
    }
}
