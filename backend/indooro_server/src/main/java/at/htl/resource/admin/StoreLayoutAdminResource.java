package at.htl.resource.admin;

import at.htl.admin.dto.LayoutDtos;
import at.htl.admin.service.StoreLayoutAdminService;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

import java.util.List;
import java.util.UUID;

@Path("/api/stores/{storeId}/layout")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class StoreLayoutAdminResource {

    @Inject
    StoreLayoutAdminService storeLayoutAdminService;

    @GET
    @Path("/current")
    public LayoutDtos.StoreLayoutResponse getCurrentLayout(@PathParam("storeId") UUID storeId) {
        return storeLayoutAdminService.getCurrentLayout(storeId);
    }

    @GET
    @Path("/versions")
    public List<LayoutDtos.LayoutVersionSummary> listLayoutVersions(@PathParam("storeId") UUID storeId) {
        return storeLayoutAdminService.listLayoutVersions(storeId);
    }

    @GET
    @Path("/versions/{layoutId}")
    public LayoutDtos.StoreLayoutResponse getLayoutVersion(@PathParam("storeId") UUID storeId,
                                                           @PathParam("layoutId") UUID layoutId) {
        return storeLayoutAdminService.getLayoutVersion(storeId, layoutId);
    }

    @POST
    @Path("/versions")
    public LayoutDtos.StoreLayoutResponse saveLayoutVersion(@PathParam("storeId") UUID storeId,
                                                            @Valid LayoutDtos.LayoutSaveRequest request) {
        return storeLayoutAdminService.saveLayoutVersion(storeId, request);
    }

    @POST
    @Path("/versions/{layoutId}/activate")
    public LayoutDtos.StoreLayoutResponse activateLayoutVersion(@PathParam("storeId") UUID storeId,
                                                                @PathParam("layoutId") UUID layoutId) {
        return storeLayoutAdminService.activateLayoutVersion(storeId, layoutId);
    }

    @GET
    @Path("/editor-context")
    public LayoutDtos.EditorContextResponse getEditorContext(@PathParam("storeId") UUID storeId) {
        return storeLayoutAdminService.getEditorContext(storeId);
    }
}
