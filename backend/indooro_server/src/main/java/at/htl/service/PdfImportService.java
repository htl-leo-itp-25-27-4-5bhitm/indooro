package at.htl.service;

import at.htl.model.Product;
import jakarta.enterprise.context.ApplicationScoped;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.text.PDFTextStripperByArea;
import org.jboss.logging.Logger;

import java.awt.geom.Rectangle2D;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@ApplicationScoped
public class PdfImportService {

    private static final Logger LOG = Logger.getLogger(PdfImportService.class);
    private static final Pattern SHELF_CODE_PATTERN = Pattern.compile("(\\d+/\\d+/\\d+/\\d+)");

    public List<Product> parsePdf(File pdfFile) throws IOException {
        List<Product> products = new ArrayList<>();

        try (PDDocument document = Loader.loadPDF(pdfFile)) {

            // Wir nutzen StripperByArea, um Bereiche zu definieren
            PDFTextStripperByArea stripper = new PDFTextStripperByArea();
            stripper.setSortByPosition(true);

            // Wir gehen jede Seite durch (falls der Plan mehrere Seiten hat)
            for (PDPage page : document.getPages()) {

                // 1. Maße der Seite holen
                PDRectangle pageSize = page.getMediaBox();
                float width = pageSize.getWidth();
                float height = pageSize.getHeight();

                // 2. Zwei Bereiche definieren: Links (0 bis 50%) und Rechts (50% bis 100%)
                // Rectangle2D.Float(x, y, width, height)
                Rectangle2D rectLeft = new Rectangle2D.Float(0, 0, width / 2, height);
                Rectangle2D rectRight = new Rectangle2D.Float(width / 2, 0, width / 2, height);

                // Regionen registrieren
                stripper.addRegion("leftColumn", rectLeft);
                stripper.addRegion("rightColumn", rectRight);

                // Text aus diesen Regionen extrahieren
                stripper.extractRegions(page);

                String textLeft = stripper.getTextForRegion("leftColumn");
                String textRight = stripper.getTextForRegion("rightColumn");

                // 3. Verarbeiten
                products.addAll(extractCodesFromText(textLeft, "ALT_Bestand"));
                products.addAll(extractCodesFromText(textRight, "NEU_Bestand"));

                // Regionen für nächste Seite löschen/resetten
                stripper.removeRegion("leftColumn");
                stripper.removeRegion("rightColumn");
            }

        } catch (IOException e) {
            LOG.error("Fehler beim Lesen des PDFs", e);
            throw e;
        }

        return products;
    }

    /**
     * Hilfsmethode: Sucht Codes in einem Textblock und weist ihnen den Bereichsnamen zu
     */
    private List<Product> extractCodesFromText(String text, String sectionName) {
        List<Product> list = new ArrayList<>();
        String[] lines = text.split("\\r?\\n");

        for (String line : lines) {
            Matcher matcher = SHELF_CODE_PATTERN.matcher(line);
            if (matcher.find()) {
                String code = matcher.group(1);

                // Optional: Falls Text vor dem Code steht (z.B. "Nutella 310/1..."), nehmen wir den
                String textBefore = line.substring(0, matcher.start()).trim();

                // Name bauen
                String productName;
                if (!textBefore.isEmpty() && !textBefore.equals("ALT:") && !textBefore.equals("NEU:")) {
                    productName = textBefore + " (" + sectionName + ")";
                } else {
                    productName = sectionName;
                }

                Product p = new Product();
                // Unique ID generieren
                p.setId(Math.abs((sectionName + code + productName).hashCode()));
                p.setName(productName);
                p.setLayoutCode(code);
                p.setPrice(0.0);

                list.add(p);
            }
        }
        return list;
    }
}