package at.htl.service;

import at.htl.model.Product;
import jakarta.enterprise.context.ApplicationScoped;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@ApplicationScoped
public class PdfExportService {

    // Hilfsklasse zum Parsen des Codes (310/1/6/1)
    private record ShelfPosition(String categoryId, String meterId, int level, int position) {}

    public byte[] generatePdf(List<Product> products) throws IOException {
        try (PDDocument document = new PDDocument()) {

            // 1. Gruppieren nach KATEGORIE
            Map<String, List<Product>> productsByCategory = products.stream()
                    .collect(Collectors.groupingBy(p -> parseCode(p.getLayoutCode()).categoryId()));

            // Sortieren (310, 420...)
            List<String> sortedCategories = new ArrayList<>(productsByCategory.keySet());
            Collections.sort(sortedCategories);

            for (String categoryId : sortedCategories) {
                List<Product> categoryProducts = productsByCategory.get(categoryId);

                // 2. Innerhalb der Kategorie nach METER gruppieren
                Map<String, List<Product>> productsByMeter = categoryProducts.stream()
                        .collect(Collectors.groupingBy(p -> parseCode(p.getLayoutCode()).meterId()));

                List<String> sortedMeters = new ArrayList<>(productsByMeter.keySet());
                // Sortieren numerisch (1, 2, 10...)
                sortedMeters.sort(Comparator.comparingInt(m -> {
                    try { return Integer.parseInt(m); } catch (Exception e) { return 0; }
                }));

                // 3. Für jeden METER eine Seite generieren
                for (String meterId : sortedMeters) {
                    List<Product> meterProducts = productsByMeter.get(meterId);
                    createPageForMeter(document, categoryId, meterId, meterProducts);
                }
            }

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            document.save(out);
            return out.toByteArray();
        }
    }

    private void createPageForMeter(PDDocument doc, String categoryId, String meterId, List<Product> products) throws IOException {
        // Querformat (Landscape) für mehr Platz
        PDPage page = new PDPage(new PDRectangle(PDRectangle.A4.getHeight(), PDRectangle.A4.getWidth()));
        doc.addPage(page);

        try (PDPageContentStream content = new PDPageContentStream(doc, page)) {
            // Header
            drawHeader(content, categoryId, meterId);

            // Layout Berechnung
            float pageWidth = page.getMediaBox().getWidth(); // ca. 842 pt (Landscape)
            float margin = 40;
            float spacing = 40;

            // Linker Bereich (Grafik): ca. 50% der Breite
            float graphicX = margin;
            float graphicWidth = (pageWidth - (2 * margin) - spacing) * 0.55f; // 55% für Grafik

            // Rechter Bereich (Liste): Rest
            float listX = graphicX + graphicWidth + spacing;
            float listWidth = (pageWidth - (2 * margin) - spacing) * 0.45f; // 45% für Liste

            float startY = 500; // Start unter dem Header

            // Zeichnen
            drawVisualShelf(content, products, graphicX, startY, graphicWidth);
            drawProductList(content, products, listX, startY, listWidth);
        }
    }

    /**
     * Linke Seite: Grafische Darstellung des Regals (Kästchen)
     */
    private void drawVisualShelf(PDPageContentStream content, List<Product> products, float x, float y, float width) throws IOException {
        // Titel
        content.beginText();
        content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 14);
        content.setNonStrokingColor(Color.BLACK);
        content.newLineAtOffset(x, y + 25);
        content.showText("VISUALISIERUNG");
        content.endText();

        int maxLevel = products.stream().mapToInt(p -> parseCode(p.getLayoutCode()).level()).max().orElse(1);
        float shelfHeight = 75; // Höhe pro Boden

        // Wir zeichnen von OBEN nach UNTEN
        for (int level = maxLevel; level >= 1; level--) {
            float currentY = y - ((maxLevel - level + 1) * shelfHeight);

            // Boden Rahmen
            content.setStrokingColor(Color.BLACK);
            content.setLineWidth(1.5f);
            content.addRect(x, currentY, width, shelfHeight);
            content.stroke();

            // Label links (Boden Nr)
            content.beginText();
            content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 10);
            content.newLineAtOffset(x - 25, currentY + (shelfHeight/2));
            content.showText("B" + level);
            content.endText();

            // Produkte
            int finalLevel = level;
            List<Product> levelProducts = products.stream()
                    .filter(p -> parseCode(p.getLayoutCode()).level() == finalLevel)
                    .sorted(Comparator.comparingInt(p -> parseCode(p.getLayoutCode()).position()))
                    .toList();

            if (!levelProducts.isEmpty()) {
                float productWidth = width / levelProducts.size();
                for (int i = 0; i < levelProducts.size(); i++) {
                    Product p = levelProducts.get(i);
                    float pX = x + (i * productWidth);

                    // Box
                    content.setStrokingColor(Color.GRAY);
                    content.setLineWidth(0.5f);
                    content.addRect(pX, currentY, productWidth, shelfHeight);
                    content.stroke();

                    // Text im Kästchen (Name & Code)
                    content.beginText();
                    content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 8);
                    content.setNonStrokingColor(Color.BLACK);

                    // Name (gekürzt)
                    content.newLineAtOffset(pX + 3, currentY + shelfHeight - 12);
                    String shortName = p.getName().length() > 12 ? p.getName().substring(0, 10) + ".." : p.getName();
                    content.showText(shortName);

                    // Code
                    content.newLineAtOffset(0, -12);
                    content.setFont(new PDType1Font(Standard14Fonts.FontName.COURIER), 7);
                    content.setNonStrokingColor(Color.BLUE);
                    content.showText(p.getLayoutCode());

                    content.endText();
                }
            }
        }
    }

    /**
     * Rechte Seite: Detaillierte Liste (Tabelle)
     */
    private void drawProductList(PDPageContentStream content, List<Product> products, float x, float y, float width) throws IOException {
        // Titel
        content.beginText();
        content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 14);
        content.setNonStrokingColor(Color.BLACK);
        content.newLineAtOffset(x, y + 25);
        content.showText("BESTÜCKUNGSLISTE");
        content.endText();

        // Tabellenkopf
        float currentY = y;
        float rowHeight = 18;

        content.setLineWidth(1f);
        content.moveTo(x, currentY + 5);
        content.lineTo(x + width, currentY + 5);
        content.stroke();

        content.beginText();
        content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 9);
        content.newLineAtOffset(x, currentY + 10);
        content.showText("POS");
        content.newLineAtOffset(40, 0);
        content.showText("ARTIKELNAME");
        content.newLineAtOffset(220, 0); // Abstand für Namen
        content.showText("CODE");
        content.endText();

        // Sortierung: Von Oben nach Unten (Level desc), dann von Links nach Rechts (Pos asc)
        List<Product> sortedList = products.stream()
                .sorted(Comparator.comparingInt((Product p) -> parseCode(p.getLayoutCode()).level()).reversed()
                        .thenComparingInt(p -> parseCode(p.getLayoutCode()).position()))
                .toList();

        // Liste drucken
        content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 9);

        for (Product p : sortedList) {
            currentY -= rowHeight;
            ShelfPosition pos = parseCode(p.getLayoutCode());

            // Linie (leicht)
            content.setStrokingColor(Color.LIGHT_GRAY);
            content.setLineWidth(0.5f);
            content.moveTo(x, currentY - 2);
            content.lineTo(x + width, currentY - 2);
            content.stroke();

            content.beginText();
            content.setNonStrokingColor(Color.BLACK);

            // Spalte 1: Position (Boden/Pos)
            content.newLineAtOffset(x, currentY + 3);
            content.showText("B" + pos.level + "-P" + pos.position);

            // Spalte 2: Name (Kürzen wenn zu lang für Zeile)
            content.newLineAtOffset(40, 0);
            String name = p.getName();
            if (name.length() > 35) name = name.substring(0, 32) + "...";
            content.showText(name);

            // Spalte 3: Code
            content.newLineAtOffset(220, 0);
            content.setFont(new PDType1Font(Standard14Fonts.FontName.COURIER), 9);
            content.showText(p.getLayoutCode());
            content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 9); // Reset Font

            content.endText();
        }
    }

    private void drawHeader(PDPageContentStream content, String categoryId, String meterId) throws IOException {
        content.beginText();
        content.setNonStrokingColor(Color.BLACK);
        content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 24);
        content.newLineAtOffset(40, 560);
        content.showText("BELEGPLAN: KATEGORIE " + categoryId + " - METER " + meterId);
        content.endText();

        content.beginText();
        content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 10);
        content.newLineAtOffset(40, 545);
        content.showText("Erstellt: " + LocalDate.now());
        content.endText();

        content.setStrokingColor(Color.BLACK);
        content.setLineWidth(2f);
        content.moveTo(40, 540);
        content.lineTo(800, 540);
        content.stroke();
    }

    private ShelfPosition parseCode(String code) {
        try {
            if (code == null) return new ShelfPosition("?", "?", 1, 1);
            String[] parts = code.split("/");
            if (parts.length < 4) return new ShelfPosition("Unknown", "1", 1, 1);
            return new ShelfPosition(parts[0], parts[1], Integer.parseInt(parts[2]), Integer.parseInt(parts[3]));
        } catch (Exception e) {
            return new ShelfPosition("Error", "1", 1, 1);
        }
    }
}