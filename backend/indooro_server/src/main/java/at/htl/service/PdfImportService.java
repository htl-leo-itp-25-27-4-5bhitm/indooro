package at.htl;

import at.htl.model.Product;
import jakarta.enterprise.context.ApplicationScoped;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.jboss.logging.Logger;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@ApplicationScoped
public class PdfImportService {

    private static final Logger LOG = Logger.getLogger(PdfImportService.class);

    // Regex für das Format Zahl/Zahl/Zahl/Zahl
    private static final Pattern SHELF_CODE_PATTERN = Pattern.compile("(\\d+/\\d+/\\d+/\\d+)");

    public List<Product> parsePdf(File pdfFile) throws IOException {
        List<Product> products = new ArrayList<>();

        try (PDDocument document = Loader.loadPDF(pdfFile)) {

            // TextStripper konfigurieren
            PDFTextStripper stripper = new PDFTextStripper();

            // WICHTIG: Das ist das Java-Äquivalent zum "-sort" Flag!
            // Es sorgt dafür, dass Spalten logisch (links oben -> links unten -> rechts oben) gelesen werden.
            stripper.setSortByPosition(true);

            String text = stripper.getText(document);

            // Zeilenweise verarbeiten
            String[] lines = text.split("\\r?\\n");

            for (String line : lines) {
                if (line.trim().isEmpty()) continue;

                Matcher matcher = SHELF_CODE_PATTERN.matcher(line);
                if (matcher.find()) {
                    String code = matcher.group(1);

                    // Alles vor dem Code ist der Name
                    // matcher.start() gibt den Index zurück, wo der Code beginnt
                    String name = line.substring(0, matcher.start()).trim();

                    if (!name.isEmpty()) {
                        Product p = new Product();
                        // Wir generieren eine ID basierend auf dem HashCode,
                        // da das PDF keine ID liefert (oder du nimmst eine Sequence)
                        p.setId(Math.abs((name + code).hashCode()));
                        p.setName(name);
                        p.setLayoutCode(code);
                        p.setPrice(0.0); // Default, da nicht im PDF

                        products.add(p);
                    }
                }
            }
        } catch (IOException e) {
            LOG.error("Fehler beim Lesen des PDFs", e);
            throw e;
        }

        return products;
    }
}