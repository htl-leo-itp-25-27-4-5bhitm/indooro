package at.htl.resource.admin;

import at.htl.admin.dto.RegionDtos;
import at.htl.admin.service.RegionAdminService;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;

@Path("/api/regions")
@RolesAllowed({"admin", "region-manager", "store-manager"})
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class RegionAdminResource extends AdminApiSupport {

    @Inject
    RegionAdminService regionAdminService;

    @GET
    public Object listRegions(@QueryParam("status") String status) {
        return regionAdminService.listRegions(parseStatus(status));
    }

    @POST
    @RolesAllowed("admin")
    public RegionDtos.RegionResponse createRegion(@Valid RegionDtos.RegionUpsertRequest request) {
        return regionAdminService.createRegion(request);
    }

    @GET
    @Path("/{regionId}")
    public RegionDtos.RegionResponse getRegion(@PathParam("regionId") java.util.UUID regionId) {
        return regionAdminService.getRegion(regionId);
    }

    @PUT
    @Path("/{regionId}")
    @RolesAllowed("admin")
    public RegionDtos.RegionResponse updateRegion(@PathParam("regionId") java.util.UUID regionId,
                                                  @Valid RegionDtos.RegionUpsertRequest request) {
        return regionAdminService.updateRegion(regionId, request);
    }

    @PATCH
    @Path("/{regionId}/archive")
    @RolesAllowed("admin")
    public RegionDtos.RegionResponse archiveRegion(@PathParam("regionId") java.util.UUID regionId) {
        return regionAdminService.archiveRegion(regionId);
    }
}
