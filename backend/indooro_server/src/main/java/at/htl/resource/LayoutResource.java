package at.htl.resource;

import at.htl.service.LayoutService;
import com.fasterxml.jackson.databind.JsonNode;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.jboss.logging.Logger;

import java.io.IOException;
import java.util.Map;

@Path("/api/layout")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class LayoutResource {

    private static final Logger LOG = Logger.getLogger(LayoutResource.class);

    @Inject
    LayoutService layoutService;

    @GET
    @Path("/current")
    public Response getCurrentLayout() {
        try {
            return Response.ok(layoutService.getCurrentLayout()).build();
        } catch (IOException e) {
            LOG.error("Error loading current layout", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity(Map.of("error", "Current layout could not be loaded"))
                    .build();
        }
    }

    @POST
    @Path("/current")
    public Response saveCurrentLayout(JsonNode layout) {
        if (layout == null || layout.isNull() || layout.isEmpty()) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(Map.of("error", "Layout payload is required"))
                    .build();
        }

        try {
            layoutService.saveCurrentLayout(layout);
            return Response.ok(Map.of("message", "Layout saved successfully")).build();
        } catch (IOException e) {
            LOG.error("Error saving current layout", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity(Map.of("error", "Layout could not be saved"))
                    .build();
        }
    }
}
