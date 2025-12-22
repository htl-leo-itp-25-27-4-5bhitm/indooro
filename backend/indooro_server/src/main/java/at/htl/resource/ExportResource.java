package at.htl.resource;

import at.htl.model.Product;
import at.htl.service.PdfExportService;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.List;

@Path("/api/export")
public class ExportResource {

    @Inject
    PdfExportService pdfExportService;

    @POST
    @Path("/pdf")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces("application/pdf")
    public Response exportBelegplanPdf(List<Product> products) {
        try {
            // 1. PDF generieren
            byte[] pdfBytes = pdfExportService.generatePdf(products);

            // 2. Als Datei zurückgeben
            return Response.ok(pdfBytes)
                    .header("Content-Disposition", "attachment; filename=\"belegplan_export.pdf\"")
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            return Response.serverError().entity("Fehler beim PDF Export: " + e.getMessage()).build();
        }
    }
}