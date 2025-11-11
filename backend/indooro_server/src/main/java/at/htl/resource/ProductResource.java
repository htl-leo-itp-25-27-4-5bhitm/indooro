package at.htl.resource;


import at.htl.model.Product;
import at.htl.service.OpenSearchService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.jboss.logging.Logger;

import java.io.IOException;
import java.util.List;

@Path("/api/products")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ProductResource {

    private static final Logger LOG = Logger.getLogger(ProductResource.class);

    @Inject
    OpenSearchService openSearchService;

    /**
     * Suche nach Produkten
     * GET /api/products/search?q=apfel&size=10
     */
    @GET
    @Path("/search")
    public Response searchProducts(
            @QueryParam("q") String query,
            @QueryParam("size") @DefaultValue("10") Integer size) {

        if (query == null || query.trim().isEmpty()) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"error\": \"Query parameter 'q' is required\"}")
                    .build();
        }

        try {
            List<Product> products = openSearchService.searchProducts(query, size);
            LOG.info("Search for '" + query + "' returned " + products.size() + " results");
            return Response.ok(products).build();
        } catch (IOException e) {
            LOG.error("Error searching products", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\": \"" + e.getMessage() + "\"}")
                    .build();
        }
    }

    /**
     * Holt alle Produkte
     * GET /api/products
     */
    @GET
    public Response getAllProducts(@QueryParam("size") @DefaultValue("100") Integer size) {
        try {
            List<Product> products = openSearchService.getAllProducts(size);
            return Response.ok(products).build();
        } catch (IOException e) {
            LOG.error("Error getting all products", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\": \"" + e.getMessage() + "\"}")
                    .build();
        }
    }

    /**
     * Holt ein Produkt anhand der ID
     * GET /api/products/1
     */
    @GET
    @Path("/{id}")
    public Response getProductById(@PathParam("id") Integer id) {
        try {
            Product product = openSearchService.getProductById(id);
            if (product != null) {
                return Response.ok(product).build();
            } else {
                return Response.status(Response.Status.NOT_FOUND)
                        .entity("{\"error\": \"Product not found\"}")
                        .build();
            }
        } catch (IOException e) {
            LOG.error("Error getting product by id", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\": \"" + e.getMessage() + "\"}")
                    .build();
        }
    }

    /**
     * Indexiert ein einzelnes Produkt
     * POST /api/products
     */
    @POST
    public Response indexProduct(Product product) {
        try {
            String result = openSearchService.indexProduct(product);
            return Response.ok("{\"result\": \"" + result + "\"}").build();
        } catch (IOException e) {
            LOG.error("Error indexing product", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\": \"" + e.getMessage() + "\"}")
                    .build();
        }
    }

    /**
     * Indexiert mehrere Produkte
     * POST /api/products/bulk
     */
    @POST
    @Path("/bulk")
    public Response indexProducts(List<Product> products) {
        try {
            openSearchService.indexProducts(products);
            return Response.ok("{\"message\": \"Successfully indexed " + products.size() + " products\"}").build();
        } catch (IOException e) {
            LOG.error("Error bulk indexing products", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\": \"" + e.getMessage() + "\"}")
                    .build();
        }
    }
}