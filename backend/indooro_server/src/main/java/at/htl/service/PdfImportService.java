package at.htl.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import jakarta.enterprise.context.ApplicationScoped;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@ApplicationScoped
public class PdfImportService {

    /**
     * ImportItem = das, was wir aus dem PDF zuverlässig extrahieren können.
     */
    public record ImportItem(
            String category,
            String meter,
            String pos,        // "B4-P2"
            Integer level,     // 4
            Integer position,  // 2
            String name,
            String layoutCode  // "800/2/4/2"
    ) {}

    // Header: nicht zeilen-gebunden! (kein ^ und $)
    private static final Pattern HEADER_ANYWHERE =
            Pattern.compile("BELEGPLAN:\\s*KATEGORIE\\s+(\\d+)\\s*-\\s*METER\\s+(\\d+)", Pattern.CASE_INSENSITIVE);

    // Eintrag: POS + Name (irgendwie dazwischen) + LayoutCode
    // DOTALL erlaubt, dass "Name" über Zeilen läuft.
    private static final Pattern ITEM_ANYWHERE =
            Pattern.compile("(B(\\d+)-P(\\d+))\\s+(.+?)\\s+((\\d+)/(\\d+)/(\\d+)/(\\d+))", Pattern.DOTALL);

    /**
     * Für deinen REST-Upload: File -> ImportItems
     */
    public List<ImportItem> parsePdf(File pdfFile) throws IOException {
        if (pdfFile == null || !pdfFile.exists()) return List.of();
        byte[] pdfBytes = Files.readAllBytes(pdfFile.toPath());
        return importFromPdf(pdfBytes);
    }

    public List<ImportItem> importFromPdf(byte[] pdfBytes) throws IOException {
        String text = extractText(pdfBytes);
        return parseExtractedText(text);
    }

    public String importFromPdfAsJson(byte[] pdfBytes) throws IOException {
        List<ImportItem> items = importFromPdf(pdfBytes);
        ObjectMapper om = new ObjectMapper().enable(SerializationFeature.INDENT_OUTPUT);
        return om.writeValueAsString(items);
    }

    /**
     * Debug-Helfer: zeigt dir genau den Text, den PDFBox sieht (nicht pdftotext).
     * Damit kannst du sofort vergleichen, warum der Parser evtl. 0 liefert.
     */
    public String extractTextForDebug(File pdfFile) throws IOException {
        byte[] pdfBytes = Files.readAllBytes(pdfFile.toPath());
        return extractText(pdfBytes);
    }

    // ---------------- intern ----------------

    private String extractText(byte[] pdfBytes) throws IOException {
        if (pdfBytes == null || pdfBytes.length == 0) return "";

        try (PDDocument doc = Loader.loadPDF(pdfBytes)) {
            PDFTextStripper stripper = new PDFTextStripper();

            // Wichtig: hilft oft bei Tabellen/2-Spalten Layouts
            stripper.setSortByPosition(true);

            // konsistente Line Separators
            stripper.setLineSeparator("\n");

            return stripper.getText(doc);
        }
    }

    /**
     * Robust:
     * 1) Split in Blöcke pro Header "BELEGPLAN: KATEGORIE X - METER Y"
     * 2) pro Block: finde alle Items via Regex, egal wie Zeilen umbrechen
     */
    private List<ImportItem> parseExtractedText(String text) {
        if (text == null || text.isBlank()) return List.of();

        // normalize whitespace ein wenig (macht Regex stabiler)
        String normalized = text
                .replace("\r", "\n")
                .replaceAll("[ \\t\\f\\u00A0]+", " ")      // multiple spaces -> one
                .replaceAll("\\n{2,}", "\n");              // multiple newlines -> one

        // Header-Funde mit Start-Indizes
        List<HeaderHit> headers = new ArrayList<>();
        Matcher mh = HEADER_ANYWHERE.matcher(normalized);
        while (mh.find()) {
            headers.add(new HeaderHit(mh.start(), mh.group(1), mh.group(2)));
        }

        // Falls keine Header gefunden werden, versuchen wir trotzdem global zu matchen (category/meter unknown)
        if (headers.isEmpty()) {
            return parseItemsInBlock(normalized, "?", "?");
        }

        // Blöcke schneiden: Header i bis Header i+1
        List<ImportItem> out = new ArrayList<>();
        for (int i = 0; i < headers.size(); i++) {
            HeaderHit h = headers.get(i);
            int start = h.start;
            int end = (i + 1 < headers.size()) ? headers.get(i + 1).start : normalized.length();

            String block = normalized.substring(start, end);
            out.addAll(parseItemsInBlock(block, h.category, h.meter));
        }

        // optional: Duplikate entfernen (kommt manchmal vor, wenn Visualisierung + Liste beide matchen)
        // Key = layoutCode ist stabil
        Map<String, ImportItem> dedup = new LinkedHashMap<>();
        for (ImportItem it : out) {
            if (it.layoutCode() != null && !it.layoutCode().isBlank()) {
                dedup.putIfAbsent(it.layoutCode(), it);
            }
        }

        return new ArrayList<>(dedup.values());
    }

    private List<ImportItem> parseItemsInBlock(String block, String category, String meter) {
        List<ImportItem> items = new ArrayList<>();

        Matcher mi = ITEM_ANYWHERE.matcher(block);
        while (mi.find()) {
            String pos = mi.group(1);
            int level = Integer.parseInt(mi.group(2));
            int position = Integer.parseInt(mi.group(3));

            String name = mi.group(4);
            String layoutCode = mi.group(5);

            name = cleanupName(name);

            // Filter: Tabellenüberschriften raus
            if (isGarbageName(name)) continue;

            items.add(new ImportItem(category, meter, pos, level, position, name, layoutCode));
        }

        return items;
    }

    private String cleanupName(String name) {
        if (name == null) return "";
        // Name kann durch PDFBox Zeilenumbrüche enthalten -> glätten
        return name
                .replace("\n", " ")
                .replaceAll("\\s{2,}", " ")
                .trim();
    }

    private boolean isGarbageName(String name) {
        if (name == null) return true;
        String n = name.trim().toUpperCase(Locale.ROOT);

        return n.isEmpty()
                || n.equals("POS")
                || n.equals("ARTIKELNAME")
                || n.equals("CODE")
                || n.equals("VISUALISIERUNG")
                || n.equals("BESTÜCKUNGSLISTE")
                || n.startsWith("ERSTELLT:");
    }

    private record HeaderHit(int start, String category, String meter) {}
}
