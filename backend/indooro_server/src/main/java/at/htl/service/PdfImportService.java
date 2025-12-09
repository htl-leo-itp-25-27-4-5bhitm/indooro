package at.htl.service;

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

    // Regex für Codes (Regalformat ODER 7-stellige Artikelnummern)
    private static final Pattern CODE_PATTERN = Pattern.compile("(\\d+/\\d+/\\d+/\\d+|\\b\\d{7}\\b)");

    public List<Product> parsePdf(File pdfFile) throws IOException {
        List<Product> products = new ArrayList<>();

        try (PDDocument document = Loader.loadPDF(pdfFile)) {
            PDFTextStripper stripper = new PDFTextStripper();
            stripper.setSortByPosition(true);

            String text = stripper.getText(document);
            String[] lines = text.split("\\r?\\n");

            String currentSection = "ALT_Bestand";

            for (String line : lines) {
                String cleanLine = line.trim();
                if (cleanLine.length() < 5) continue;

                String upperLine = cleanLine.toUpperCase();

                // Müll-Filter
                if (upperLine.contains("BELEGPLAN") || upperLine.contains("SEITE")) continue;

                // Sektions-Erkennung (ändert Status, läuft aber weiter)
                if (upperLine.contains("NEU IM SORTIMENT") || upperLine.contains("NEU:")) {
                    currentSection = "NEU_Bestand";
                } else if (upperLine.contains("SORTIMENT") && (upperLine.contains("AUS") || upperLine.contains("US ") || upperLine.contains("ALT"))) {
                    currentSection = "ALT_Bestand";
                }

                // CODE SUCHEN
                Matcher matcher = CODE_PATTERN.matcher(cleanLine);
                if (matcher.find()) {
                    String code = matcher.group(1);

                    // Strategie: Name steht oft DAHINTER bei dieser Art von Liste
                    String textBefore = cleanLine.substring(0, matcher.start()).trim();
                    String textAfter = cleanLine.substring(matcher.end()).trim();

                    // Bereinigung von Datum und Müll
                    textBefore = cleanText(textBefore);
                    textAfter = cleanText(textAfter);

                    String productName = "Unbekannt";

                    // ENTSCHEIDUNG: Wo steht der Name?
                    // Wenn "textBefore" nach einer Überschrift aussieht ("Neu im Sortiment"),
                    // dann muss der Name im "textAfter" stehen!
                    boolean beforeIsHeader = textBefore.toUpperCase().contains("SORTIMENT") || textBefore.toUpperCase().contains("NEU:");

                    if (!textAfter.isEmpty() && beforeIsHeader) {
                        productName = textAfter; // Nimm den Text DANACH (z.B. Koawach)
                    } else if (!textBefore.isEmpty() && !beforeIsHeader) {
                        productName = textBefore; // Nimm den Text DAVOR (Klassisch)
                    } else if (!textAfter.isEmpty()) {
                        productName = textAfter; // Fallback: Besser Text danach als gar nix
                    } else {
                        // Notfall: Wenn gar kein Name da ist, nehmen wir den bereinigten Header als Hinweis
                        productName = textBefore.isEmpty() ? "Artikel (" + currentSection + ")" : textBefore;
                    }

                    Product p = new Product();
                    p.setId(Math.abs((code + productName + currentSection).hashCode()));
                    p.setName(productName);
                    p.setLayoutCode(code);
                    p.setPrice(0.0);

                    // Status für CSV anhängen
                    if ("NEU_Bestand".equals(currentSection)) {
                        p.setName(productName + " [NEU]");
                    }

                    products.add(p);
                    LOG.info("-> TREFFER: " + code + " | Name: " + productName);
                }
            }
        } catch (IOException e) {
            LOG.error("Fehler beim Lesen des PDFs", e);
            throw e;
        }
        return products;
    }

    // Hilfsmethode zum Putzen
    private String cleanText(String input) {
        if (input == null) return "";
        // Entfernt "t-------l", "Neu im Sortiment:", Datum "02-12-2025" und Sonderzeichen am Rand
        String cleaned = input.replaceAll("(?i)(neu im sortiment|aus dem sortiment|us dem sortiment|t[-]+l)", "")
                .replaceAll("\\d{2}-\\d{2}-\\d{4}", "") // Datum weg
                .replaceAll("[:]", "") // Doppelpunkte weg
                .trim();
        // Entfernt führende/nachfolgende Sonderzeichen
        return cleaned.replaceAll("^[^a-zA-Z0-9]+|[^a-zA-Z0-9)]+$", "").trim();
    }
}