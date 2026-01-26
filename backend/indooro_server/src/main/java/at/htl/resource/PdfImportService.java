package at.htl.service;

import at.htl.model.Product;
import jakarta.enterprise.context.ApplicationScoped;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@ApplicationScoped
public class PdfImportService {

    public List<Product> parsePdf(File file) throws IOException {
        String text = extractText(file);

        if (text == null || text.trim().isEmpty()) {
            return List.of();
        }

        return parseProductsFromText(text);
    }

    private String extractText(File file) throws IOException {
        try (PDDocument document = PDDocument.load(file)) {
            PDFTextStripper stripper = new PDFTextStripper();

            stripper.setSortByPosition(true);

            return stripper.getText(document);
        }
    }

    private List<Product> parseProductsFromText(String text) {
        List<Product> products = new ArrayList<>();

        String[] lines = text.split("\\R"); // alle Zeilen

        for (String line : lines) {
            line = line.trim();
            if (line.isEmpty()) continue;

            String name = null;
            String layout = null;

            if (line.contains(";")) {
                String[] parts = line.split(";", 2);
                name = parts[0].trim();
                layout = parts[1].trim();
            } else if (line.contains(" - ")) {
                String[] parts = line.split("\\s-\\s", 2);
                name = parts[0].trim();
                layout = parts[1].trim();
            }

            if (name != null && layout != null) {
                Product p = new Product();
                p.setName(name);
                p.setLayoutCode(layout);
                products.add(p);
            }
        }
        return products;
    }
}
