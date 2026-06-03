package at.htl.admin.service;

import at.htl.admin.dto.UpsellDtos;
import at.htl.admin.entity.UpsellDismissalEntity;
import at.htl.admin.entity.UpsellEventEntity;
import at.htl.admin.entity.UpsellSuggestionCacheEntity;
import at.htl.admin.repository.UpsellDismissalRepository;
import at.htl.admin.repository.UpsellEventRepository;
import at.htl.admin.repository.UpsellSuggestionCacheRepository;
import at.htl.model.Product;
import at.htl.service.OpenSearchService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@ApplicationScoped
public class UpsellSuggestionService {

    private static final Logger LOG = Logger.getLogger(UpsellSuggestionService.class);
    private static final String GENERIC_REASON = "Ergaenzt den gerade erledigten Artikel.";
    private static final String CACHE_CONTEXT_VERSION = "upsell-v2";

    @Inject
    OpenSearchService openSearchService;

    @Inject
    ObjectMapper objectMapper;

    @Inject
    UpsellEventRepository eventRepository;

    @Inject
    UpsellDismissalRepository dismissalRepository;

    @Inject
    UpsellSuggestionCacheRepository cacheRepository;

    @ConfigProperty(name = "upsell.enabled", defaultValue = "true")
    boolean upsellEnabled;

    @ConfigProperty(name = "upsell.max-candidates", defaultValue = "50")
    int maxCandidates;

    @ConfigProperty(name = "upsell.max-suggestions", defaultValue = "3")
    int maxSuggestions;

    @ConfigProperty(name = "upsell.min-confidence", defaultValue = "0.45")
    double minConfidence;

    @ConfigProperty(name = "upsell.cache-ttl-minutes", defaultValue = "60")
    long cacheTtlMinutes;

    @ConfigProperty(name = "openai.api-key")
    Optional<String> openAiApiKey;

    @ConfigProperty(name = "openai.upsell.enabled", defaultValue = "false")
    boolean openAiEnabled;

    @ConfigProperty(name = "openai.upsell.model", defaultValue = "gpt-5.4-mini")
    String openAiModel;

    @ConfigProperty(name = "openai.upsell.reasoning-effort", defaultValue = "none")
    String openAiReasoningEffort;

    @ConfigProperty(name = "openai.upsell.timeout-ms", defaultValue = "4500")
    long openAiTimeoutMs;

    @Transactional
    public UpsellDtos.UpsellSuggestionResponse suggestions(UpsellDtos.UpsellSuggestionRequest request) {
        if (!upsellEnabled) {
            return emptyResponse(request == null ? null : request.checkedProductId(), "disabled");
        }
        if (request == null || request.checkedProductId() == null) {
            throw new WebApplicationException("checkedProductId ist erforderlich.", Response.Status.BAD_REQUEST);
        }

        String contextHash = contextHash(request);
        Optional<UpsellDtos.UpsellSuggestionResponse> cached = findCachedResponse(contextHash);
        if (cached.isPresent()) {
            return cached.get();
        }

        Product checkedProduct = resolveProduct(request.checkedProductId());
        List<Product> candidates = loadCandidates(request, checkedProduct);
        if (candidates.isEmpty()) {
            UpsellDtos.UpsellSuggestionResponse response = emptyResponse(request.checkedProductId(), "none");
            storeCachedResponse(request, contextHash, response);
            return response;
        }

        Map<Integer, Product> candidateMap = candidates.stream()
                .filter(product -> product.getId() != null)
                .collect(Collectors.toMap(Product::getId, product -> product, (first, ignored) -> first, LinkedHashMap::new));

        RankingResult ranking = rankWithOpenAi(checkedProduct, candidates)
                .map(suggestions -> new RankingResult(suggestions, "openai"))
                .orElseGet(() -> new RankingResult(fallbackRank(checkedProduct, candidates), "fallback"));

        List<UpsellDtos.UpsellSuggestion> suggestions = validatedSuggestions(ranking.suggestions(), candidateMap);
        String source = ranking.source();
        if (suggestions.isEmpty() && !ranking.suggestions().isEmpty()) {
            source = "filtered";
        }

        UpsellDtos.UpsellSuggestionResponse response = new UpsellDtos.UpsellSuggestionResponse(
                request.checkedProductId(),
                suggestions,
                source,
                Instant.now().plus(Duration.ofMinutes(Math.max(1, cacheTtlMinutes)))
        );
        storeCachedResponse(request, contextHash, response);
        return response;
    }

    private Optional<UpsellDtos.UpsellSuggestionResponse> findCachedResponse(String contextHash) {
        return cacheRepository.findFreshByContextHash(contextHash, Instant.now())
                .flatMap(entity -> {
                    try {
                        UpsellDtos.UpsellSuggestionResponse cached = objectMapper.readValue(
                                entity.responseJson,
                                UpsellDtos.UpsellSuggestionResponse.class
                        );
                        return Optional.of(new UpsellDtos.UpsellSuggestionResponse(
                                cached.checkedProductId(),
                                cached.suggestions(),
                                "cache",
                                entity.expiresAt
                        ));
                    } catch (Exception exception) {
                        LOG.warn("Upsell cache entry could not be parsed", exception);
                        return Optional.empty();
                    }
                });
    }

    private void storeCachedResponse(
            UpsellDtos.UpsellSuggestionRequest request,
            String contextHash,
            UpsellDtos.UpsellSuggestionResponse response
    ) {
        try {
            UpsellSuggestionCacheEntity entity = new UpsellSuggestionCacheEntity();
            entity.checkedProductId = request.checkedProductId();
            entity.storeId = request.storeId();
            entity.storeCode = normalizeOptional(request.storeCode());
            entity.contextHash = contextHash;
            entity.responseJson = objectMapper.writeValueAsString(response);
            entity.source = normalizeOptional(response.source()) == null ? "unknown" : response.source();
            entity.expiresAt = response.expiresAt();
            cacheRepository.upsert(entity);
        } catch (Exception exception) {
            LOG.warn("Upsell cache write failed", exception);
        }
    }

    private record RankingResult(List<UpsellDtos.AiSuggestion> suggestions, String source) {
    }

    @Transactional
    public void recordEvent(UpsellDtos.UpsellEventRequest request) {
        if (request == null || request.eventType() == null || request.eventType().isBlank()) {
            throw new WebApplicationException("eventType ist erforderlich.", Response.Status.BAD_REQUEST);
        }

        UpsellEventEntity entity = new UpsellEventEntity();
        entity.eventType = request.eventType().trim().toUpperCase(Locale.ROOT);
        entity.checkedProductId = request.checkedProductId();
        entity.suggestedProductId = request.suggestedProductId();
        entity.storeId = request.storeId();
        entity.storeCode = normalizeOptional(request.storeCode());
        entity.sessionHash = hashOptional(request.sessionId());
        entity.source = normalizeOptional(request.source());
        entity.metadataJson = normalizeOptional(request.metadataJson());
        eventRepository.persist(entity);
    }

    @Transactional
    public void dismiss(UpsellDtos.UpsellDismissRequest request) {
        if (request == null || request.checkedProductId() == null) {
            throw new WebApplicationException("checkedProductId ist erforderlich.", Response.Status.BAD_REQUEST);
        }

        String sessionHash = hashOptional(request.sessionId());
        UpsellDismissalEntity entity = dismissalRepository
                .findMatching(request.checkedProductId(), request.suggestedProductId(), request.storeId(), sessionHash)
                .orElseGet(UpsellDismissalEntity::new);
        entity.checkedProductId = request.checkedProductId();
        entity.suggestedProductId = request.suggestedProductId();
        entity.storeId = request.storeId();
        entity.storeCode = normalizeOptional(request.storeCode());
        entity.sessionHash = sessionHash;
        entity.dismissalCount = entity.id == null ? 1 : entity.dismissalCount + 1;
        int suppressMinutes = request.suppressMinutes() == null ? 240 : Math.min(Math.max(request.suppressMinutes(), 1), 30 * 24 * 60);
        entity.suppressedUntil = Instant.now().plus(Duration.ofMinutes(suppressMinutes));
        if (entity.id == null) {
            dismissalRepository.persist(entity);
        }
    }

    Product resolveProduct(Integer productId) {
        try {
            Product product = openSearchService.getProductById(productId);
            if (product == null || product.getId() == null) {
                throw new NotFoundException("Produkt nicht gefunden.");
            }
            return product;
        } catch (IOException exception) {
            LOG.warn("Upsell checked product lookup failed", exception);
            throw new WebApplicationException("Produktkatalog ist nicht erreichbar.", Response.Status.SERVICE_UNAVAILABLE);
        }
    }

    List<Product> loadCandidates(UpsellDtos.UpsellSuggestionRequest request, Product checkedProduct) {
        try {
            List<Product> storeScoped = openSearchService.findUpsellCandidates(
                    Math.max(maxCandidates, maxSuggestions),
                    request.storeId() == null ? null : request.storeId().toString(),
                    request.storeCode()
            );
            List<Product> candidates = filterCandidates(request, checkedProduct, storeScoped);

            if (candidates.size() < maxSuggestions && (request.storeId() != null || normalizeOptional(request.storeCode()) != null)) {
                List<Product> fallback = openSearchService.findUpsellCandidates(Math.max(maxCandidates, maxSuggestions), null, null);
                candidates = mergeCandidates(candidates, filterCandidates(request, checkedProduct, fallback));
            }

            return candidates.stream()
                    .sorted(candidateComparator(checkedProduct, request))
                    .limit(Math.max(1, maxCandidates))
                    .toList();
        } catch (IOException exception) {
            LOG.warn("Upsell candidate lookup failed", exception);
            return List.of();
        }
    }

    List<Product> filterCandidates(UpsellDtos.UpsellSuggestionRequest request, Product checkedProduct, List<Product> rawCandidates) {
        Set<Integer> excluded = new HashSet<>();
        excluded.add(request.checkedProductId());
        if (request.currentListProductIds() != null) {
            excluded.addAll(request.currentListProductIds());
        }
        if (request.completedProductIds() != null) {
            excluded.addAll(request.completedProductIds());
        }

        Map<Integer, Product> unique = new LinkedHashMap<>();
        for (Product candidate : rawCandidates == null ? List.<Product>of() : rawCandidates) {
            if (candidate == null || candidate.getId() == null || candidate.getName() == null || candidate.getName().isBlank()) {
                continue;
            }
            if (excluded.contains(candidate.getId())) {
                continue;
            }
            unique.putIfAbsent(candidate.getId(), candidate);
        }

        return new ArrayList<>(unique.values());
    }

    List<UpsellDtos.AiSuggestion> fallbackRank(Product checkedProduct, List<Product> candidates) {
        return candidates.stream()
                .sorted(candidateComparator(checkedProduct, null))
                .limit(Math.max(1, maxSuggestions))
                .map(product -> new UpsellDtos.AiSuggestion(product.getId(), GENERIC_REASON, 0.62))
                .toList();
    }

    Optional<List<UpsellDtos.AiSuggestion>> rankWithOpenAi(Product checkedProduct, List<Product> candidates) {
        Optional<String> apiKey = openAiApiKey.filter(key -> !key.isBlank());
        if (!openAiEnabled || apiKey.isEmpty() || candidates.isEmpty()) {
            return Optional.empty();
        }

        try {
            HttpClient client = HttpClient.newBuilder()
                    .connectTimeout(Duration.ofMillis(Math.max(500, openAiTimeoutMs)))
                    .build();
            String body = objectMapper.writeValueAsString(openAiRequestBody(checkedProduct, candidates));
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create("https://api.openai.com/v1/responses"))
                    .timeout(Duration.ofMillis(Math.max(500, openAiTimeoutMs)))
                    .header("Authorization", "Bearer " + apiKey.get())
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(body, StandardCharsets.UTF_8))
                    .build();
            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                LOG.warn("OpenAI upsell ranking failed with status " + response.statusCode());
                return Optional.empty();
            }

            String outputJson = extractResponsesText(response.body());
            if (outputJson == null || outputJson.isBlank()) {
                return Optional.empty();
            }

            UpsellDtos.AiSuggestionResponse parsed = objectMapper.readValue(outputJson, UpsellDtos.AiSuggestionResponse.class);
            return Optional.ofNullable(parsed.suggestions()).filter(list -> !list.isEmpty());
        } catch (Exception exception) {
            LOG.warn("OpenAI upsell ranking failed; falling back", exception);
            return Optional.empty();
        }
    }

    List<UpsellDtos.UpsellSuggestion> validatedSuggestions(
            List<UpsellDtos.AiSuggestion> ranked,
            Map<Integer, Product> candidateMap
    ) {
        List<UpsellDtos.UpsellSuggestion> result = new ArrayList<>();
        Set<Integer> used = new HashSet<>();
        for (UpsellDtos.AiSuggestion suggestion : ranked == null ? List.<UpsellDtos.AiSuggestion>of() : ranked) {
            if (suggestion == null || suggestion.productId() == null || used.contains(suggestion.productId())) {
                continue;
            }
            Product product = candidateMap.get(suggestion.productId());
            if (product == null) {
                continue;
            }
            double confidence = clamp(suggestion.confidence() == null ? 0.5 : suggestion.confidence());
            if (confidence < minConfidence) {
                continue;
            }
            result.add(new UpsellDtos.UpsellSuggestion(
                    toSummary(product),
                    boundedReason(suggestion.reason()),
                    confidence
            ));
            used.add(suggestion.productId());
            if (result.size() >= Math.max(1, maxSuggestions)) {
                break;
            }
        }
        return result;
    }

    UpsellDtos.UpsellProductSummary toSummary(Product product) {
        return new UpsellDtos.UpsellProductSummary(
                product.getId(),
                product.getName(),
                product.getPrice(),
                normalizeOptional(product.getLayoutCode()),
                normalizeOptional(product.getStoreId()),
                normalizeOptional(product.getStoreCode()),
                null,
                categoryCode(product.getLayoutCode()),
                null,
                hasLayoutPosition(product)
        );
    }

    private Map<String, Object> openAiRequestBody(Product checkedProduct, List<Product> candidates) throws IOException {
        Map<String, Object> schema = Map.of(
                "type", "object",
                "additionalProperties", false,
                "required", List.of("suggestions"),
                "properties", Map.of(
                        "suggestions", Map.of(
                                "type", "array",
                                "maxItems", Math.max(1, maxSuggestions),
                                "items", Map.of(
                                        "type", "object",
                                        "additionalProperties", false,
                                        "required", List.of("productId", "reason", "confidence"),
                                        "properties", Map.of(
                                                "productId", Map.of("type", "integer"),
                                                "reason", Map.of("type", "string", "maxLength", 180),
                                                "confidence", Map.of("type", "number", "minimum", 0, "maximum", 1)
                                        )
                                )
                        )
                )
        );

        Map<String, Object> payload = Map.of(
                "checkedProduct", toAiSummary(checkedProduct),
                "candidateProducts", candidates.stream().limit(Math.max(1, maxCandidates)).map(this::toAiSummary).toList()
        );

        Map<String, Object> requestBody = new LinkedHashMap<>();
        requestBody.put("model", openAiModel);
        requestBody.put("input", List.of(
                Map.of(
                        "role", "system",
                        "content", "Rank supermarket add-on products. Select only productIds from the provided candidates. Do not invent products. Reasons must be concise German customer-facing text."
                ),
                Map.of(
                        "role", "user",
                        "content", objectMapper.writeValueAsString(payload)
                )
        ));
        requestBody.put("text", Map.of(
                "format", Map.of(
                        "type", "json_schema",
                        "name", "upsell_suggestions",
                        "strict", true,
                        "schema", schema
                )
        ));
        requestBody.put("max_output_tokens", 800);

        String reasoningEffort = normalizeOptional(openAiReasoningEffort);
        if (reasoningEffort != null && supportsReasoning(openAiModel)) {
            requestBody.put("reasoning", Map.of("effort", reasoningEffort));
        }

        return requestBody;
    }

    private boolean supportsReasoning(String model) {
        String normalized = normalizeOptional(model);
        if (normalized == null) {
            return false;
        }
        String lower = normalized.toLowerCase(Locale.ROOT);
        return lower.startsWith("gpt-5") || lower.startsWith("o1") || lower.startsWith("o3") || lower.startsWith("o4");
    }

    private Map<String, Object> toAiSummary(Product product) {
        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("id", product.getId());
        summary.put("name", product.getName());
        summary.put("categoryCode", categoryCode(product.getLayoutCode()));
        summary.put("layoutCode", normalizeOptional(product.getLayoutCode()));
        summary.put("hasLayoutPosition", hasLayoutPosition(product));
        return summary;
    }

    private String extractResponsesText(String body) throws IOException {
        JsonNode root = objectMapper.readTree(body);
        JsonNode outputText = root.get("output_text");
        if (outputText != null && outputText.isTextual()) {
            return outputText.asText();
        }
        JsonNode output = root.get("output");
        if (output != null && output.isArray()) {
            for (JsonNode item : output) {
                JsonNode content = item.get("content");
                if (content == null || !content.isArray()) {
                    continue;
                }
                for (JsonNode contentItem : content) {
                    JsonNode text = contentItem.get("text");
                    if (text != null && text.isTextual()) {
                        return text.asText();
                    }
                }
            }
        }
        return null;
    }

    private Comparator<Product> candidateComparator(Product checkedProduct, UpsellDtos.UpsellSuggestionRequest request) {
        String checkedCategory = categoryCode(checkedProduct == null ? null : checkedProduct.getLayoutCode());
        Set<String> complements = complementaryCategories(checkedCategory);
        String requestStoreId = request == null || request.storeId() == null ? null : request.storeId().toString();
        String requestStoreCode = request == null ? null : normalizeOptional(request.storeCode());

        return Comparator
                .comparingInt((Product product) -> storeScore(product, requestStoreId, requestStoreCode)).reversed()
                .thenComparingInt(product -> complements.contains(categoryCode(product.getLayoutCode())) ? 1 : 0).reversed()
                .thenComparingInt(product -> hasLayoutPosition(product) ? 1 : 0).reversed()
                .thenComparing(product -> product.getName() == null ? "" : product.getName(), String.CASE_INSENSITIVE_ORDER);
    }

    private int storeScore(Product product, String storeId, String storeCode) {
        int score = 0;
        if (storeId != null && storeId.equals(normalizeOptional(product.getStoreId()))) {
            score += 2;
        }
        if (storeCode != null && storeCode.equalsIgnoreCase(Objects.toString(normalizeOptional(product.getStoreCode()), ""))) {
            score += 2;
        }
        return score;
    }

    private List<Product> mergeCandidates(List<Product> first, List<Product> second) {
        Map<Integer, Product> merged = new LinkedHashMap<>();
        for (Product product : first) {
            if (product.getId() != null) {
                merged.put(product.getId(), product);
            }
        }
        for (Product product : second) {
            if (product.getId() != null) {
                merged.putIfAbsent(product.getId(), product);
            }
        }
        return new ArrayList<>(merged.values());
    }

    private Set<String> complementaryCategories(String categoryCode) {
        Map<String, Set<String>> groups = new HashMap<>();
        groups.put("430", Set.of("420", "450", "525", "310"));
        groups.put("420", Set.of("430", "450", "525", "310"));
        groups.put("525", Set.of("430", "420", "445"));
        groups.put("310", Set.of("420", "430", "440", "520"));
        groups.put("520", Set.of("440", "310", "445"));
        groups.put("440", Set.of("520", "310"));
        groups.put("445", Set.of("520", "525"));
        groups.put("510", Set.of("470", "445"));
        groups.put("470", Set.of("510"));
        groups.put("530", Set.of("420", "430"));
        return groups.getOrDefault(categoryCode, Set.of());
    }

    private String categoryCode(String layoutCode) {
        String normalized = normalizeOptional(layoutCode);
        if (normalized == null) {
            return null;
        }
        String first = normalized.split("/", 2)[0].trim();
        return first.isEmpty() ? null : first;
    }

    private boolean hasLayoutPosition(Product product) {
        return normalizeOptional(product.getLayoutCode()) != null;
    }

    private String boundedReason(String reason) {
        String normalized = normalizeOptional(reason);
        if (normalized == null) {
            return GENERIC_REASON;
        }
        if (normalized.length() <= 180) {
            return normalized;
        }
        return normalized.substring(0, 177) + "...";
    }

    private double clamp(double value) {
        return Math.max(0.0, Math.min(1.0, value));
    }

    private UpsellDtos.UpsellSuggestionResponse emptyResponse(Integer checkedProductId, String source) {
        return new UpsellDtos.UpsellSuggestionResponse(
                checkedProductId,
                List.of(),
                source,
                Instant.now().plus(Duration.ofMinutes(Math.max(1, cacheTtlMinutes)))
        );
    }

    private String normalizeOptional(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    String contextHash(UpsellDtos.UpsellSuggestionRequest request) {
        Map<String, Object> context = new LinkedHashMap<>();
        context.put("version", CACHE_CONTEXT_VERSION);
        context.put("checkedProductId", request.checkedProductId());
        context.put("storeId", request.storeId() == null ? null : request.storeId().toString());
        context.put("storeCode", normalizeOptional(request.storeCode()) == null ? null : normalizeOptional(request.storeCode()).toLowerCase(Locale.ROOT));
        context.put("shoppingListId", normalizeOptional(request.shoppingListId()));
        context.put("currentListProductIds", normalizedProductIds(request.currentListProductIds(), request.checkedProductId(), false));
        context.put("completedProductIds", normalizedProductIds(request.completedProductIds(), request.checkedProductId(), true));
        context.put("maxSuggestions", Math.max(1, maxSuggestions));
        context.put("minConfidence", minConfidence);
        try {
            return sha256(objectMapper.writeValueAsString(context));
        } catch (Exception exception) {
            return sha256(context.toString());
        }
    }

    private List<Integer> normalizedProductIds(List<Integer> productIds, Integer checkedProductId, boolean includeChecked) {
        Set<Integer> normalized = new HashSet<>();
        if (productIds != null) {
            for (Integer productId : productIds) {
                if (productId != null && !Objects.equals(productId, checkedProductId)) {
                    normalized.add(productId);
                }
            }
        }
        if (includeChecked && checkedProductId != null) {
            normalized.add(checkedProductId);
        }
        return normalized.stream().sorted().toList();
    }

    private String hashOptional(String value) {
        String normalized = normalizeOptional(value);
        if (normalized == null) {
            return null;
        }
        return sha256(normalized);
    }

    private String sha256(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            StringBuilder builder = new StringBuilder();
            for (byte b : hash) {
                builder.append(String.format("%02x", b));
            }
            return builder.toString();
        } catch (NoSuchAlgorithmException exception) {
            return null;
        }
    }
}
