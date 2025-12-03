package at.htl.resource;

import at.htl.model.Product;
import at.htl.service.PdfImportService;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.jboss.resteasy.reactive.RestForm;

import java.io.File;
import java.io.IOException;
import java.util.List;

@Path("/api/convert")
public class ImportResource {

    @Inject
    PdfImportService pdfImportService;

    /**
     * PDF rein -> CSV raus
     */
    @POST
    @Path("/pdf-to-csv")
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    @Produces(MediaType.TEXT_PLAIN) // Wir geben Text (CSV) zurück
    public Response convertPdfToCsv(@RestForm("file") File file) {

        if (file == null || !file.exists()) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("Keine Datei hochgeladen")
                    .build();
        }

        try {
            // 1. PDF Parsen (nutzt deinen bestehenden Service)
            List<Product> products = pdfImportService.parsePdf(file);

            // 2. CSV String zusammenbauen
            StringBuilder csv = new StringBuilder();

            // Header
            csv.append("Produktname;Regalcode\n");

            // Zeilen
            for (Product p : products) {
                csv.append(p.getName())
                        .append(";")
                        .append(p.getLayoutCode())
                        .append("\n");
            }

            // 3. Als Datei-Download zurückgeben
            return Response.ok(csv.toString())
                    .header("Content-Disposition", "attachment; filename=\"regalplan_export.csv\"")
                    .build();

        } catch (IOException e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("Fehler beim Verarbeiten: " + e.getMessage())
                    .build();
        }
    }
}