package at.htl.resource;

import at.htl.service.OpenSearchService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.jboss.logging.Logger;

import java.io.IOException;

@Path("/api/admin")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AdminResource {

    private static final Logger LOG = Logger.getLogger(AdminResource.class);

    @Inject
    OpenSearchService openSearchService;

    /**
     * Erstellt den Index
     * POST /api/admin/index/create
     */
    @POST
    @Path("/index/create")
    public Response createIndex() {
        try {
            openSearchService.createIndex();
            return Response.ok("{\"message\": \"Index created successfully\"}").build();
        } catch (IOException e) {
            LOG.error("Error creating index", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\": \"" + e.getMessage() + "\"}")
                    .build();
        }
    }

    /**
     * Löscht den Index
     * DELETE /api/admin/index
     */
    @DELETE
    @Path("/index")
    public Response deleteIndex() {
        try {
            openSearchService.deleteIndex();
            return Response.ok("{\"message\": \"Index deleted successfully\"}").build();
        } catch (IOException e) {
            LOG.error("Error deleting index", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\": \"" + e.getMessage() + "\"}")
                    .build();
        }
    }

    /**
     * Health Check
     * GET /api/admin/health
     */
    @GET
    @Path("/health")
    public Response health() {
        return Response.ok("{\"status\": \"UP\"}").build();
    }
}