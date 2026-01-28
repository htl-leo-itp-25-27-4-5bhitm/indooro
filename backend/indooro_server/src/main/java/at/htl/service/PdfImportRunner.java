package at.htl.service;

import at.htl.service.PdfImportService;

import java.nio.file.Files;
import java.nio.file.Path;

public class PdfImportRunner {
    public static void main(String[] args) throws Exception {
        // Pfad anpassen
        Path pdfPath = Path.of("mein_plan.pdf");

        byte[] pdfBytes = Files.readAllBytes(pdfPath);

        PdfImportService svc = new PdfImportService();
        String json = svc.importFromPdfAsJson(pdfBytes);

        System.out.println(json);

        // optional: als Datei speichern
        Files.writeString(Path.of("import_result.json"), json);
        System.out.println("\n-> geschrieben: import_result.json");
    }
}
