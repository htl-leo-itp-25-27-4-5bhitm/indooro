package at.htl.resource;

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
     * PDF rein -> ImportItems -> CSV raus
     */
    @POST
    @Path("/pdf-to-csv")
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    @Produces(MediaType.TEXT_PLAIN)
    public Response convertPdfToCsv(@RestForm("file") File file) {

        if (file == null || !file.exists()) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("Keine Datei hochgeladen")
                    .build();
        }

        try {
            List<PdfImportService.ImportItem> items = pdfImportService.parsePdf(file);

            StringBuilder csv = new StringBuilder();
            csv.append("Produktname;Regalcode;Kategorie;Meter;Pos\n");

            for (PdfImportService.ImportItem it : items) {
                csv.append(safe(it.name()))
                        .append(";")
                        .append(safe(it.layoutCode()))
                        .append(";")
                        .append(safe(it.category()))
                        .append(";")
                        .append(safe(it.meter()))
                        .append(";")
                        .append(safe(it.pos()))
                        .append("\n");
            }

            return Response.ok(csv.toString())
                    .header("Content-Disposition", "attachment; filename=\"regalplan_export.csv\"")
                    .build();

        } catch (IOException e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("Fehler beim Verarbeiten: " + e.getMessage())
                    .build();
        }
    }

    /**
     * PDF rein -> ImportItems -> JSON raus
     */
    @POST
    @Path("/pdf-to-json")
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    @Produces(MediaType.APPLICATION_JSON)
    public Response convertPdfToJson(@RestForm("file") File file) {

        if (file == null || !file.exists()) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("Keine Datei hochgeladen")
                    .build();
        }

        try {
            List<PdfImportService.ImportItem> items = pdfImportService.parsePdf(file);
            return Response.ok(items).build();

        } catch (IOException e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("Fehler beim Verarbeiten: " + e.getMessage())
                    .build();
        }
    }

    private static String safe(String s) {
        if (s == null) return "";
        return s.replace("\n", " ").replace("\r", " ").trim();
    }
}
