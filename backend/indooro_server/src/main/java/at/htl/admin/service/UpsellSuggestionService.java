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
import java.util.LinkedHashSet;
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
    private static final String PLAN_CACHE_CONTEXT_VERSION = "upsell-plan-v2";

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

    @ConfigProperty(name = "upsell.per-opportunity-candidates", defaultValue = "10")
    int perOpportunityCandidates;

    @ConfigProperty(name = "upsell.min-deterministic-score", defaultValue = "40")
    int minDeterministicScore;

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

    @Transactional
    public UpsellDtos.UpsellPlanResponse plan(UpsellDtos.UpsellPlanRequest request) {
        String requestId = UUID.randomUUID().toString();
        long planStartedNanos = System.nanoTime();
        if (!upsellEnabled) {
            return emptyPlanResponse(List.of(), "disabled", planDebug(
                    requestId, "disabled", planStartedNanos, null, null, "upsell_disabled", 0, 0
            ));
        }
        if (request == null || request.opportunities() == null || request.opportunities().isEmpty()) {
            throw new WebApplicationException("Mindestens eine Upsell-Station ist erforderlich.", Response.Status.BAD_REQUEST);
        }

        List<UpsellDtos.UpsellOpportunityRequest> opportunities = normalizedOpportunities(request.opportunities());
        if (opportunities.isEmpty()) {
            return emptyPlanResponse(List.of(), "none", planDebug(
                    requestId, "none", planStartedNanos, null, null, "no_valid_opportunities", 0, 0
            ));
        }

        String contextHash = planContextHash(request, opportunities);
        Optional<UpsellDtos.UpsellPlanResponse> cached = findCachedPlanResponse(contextHash);
        if (cached.isPresent()) {
            UpsellDtos.UpsellPlanResponse response = cached.get();
            logPlanResult(response);
            return response;
        }

        List<Product> candidates = loadPlanCandidates(request, opportunities);
        if (candidates.isEmpty()) {
            UpsellDtos.UpsellPlanDebug debug = planDebug(
                    requestId, "none", planStartedNanos, null, null, "no_candidates", opportunities.size(), 0
            );
            UpsellDtos.UpsellPlanResponse response = emptyPlanResponse(opportunities, "none", debug);
            storeCachedPlanResponse(request, contextHash, response);
            logPlanResult(response);
            return response;
        }

        List<RankedOpportunity> rankedOpportunities = rankPlanCandidates(request, opportunities, candidates, requestId);
        int rankedCandidateCount = rankedOpportunities.stream()
                .mapToInt(opportunity -> opportunity.candidates().size())
                .sum();
        if (rankedOpportunities.stream().allMatch(opportunity -> opportunity.candidates().isEmpty())) {
            UpsellDtos.UpsellPlanDebug debug = planDebug(
                    requestId,
                    "none",
                    planStartedNanos,
                    null,
                    null,
                    "no_ranked_candidates",
                    opportunities.size(),
                    0
            );
            UpsellDtos.UpsellPlanResponse response = emptyPlanResponse(opportunities, "none", debug);
            storeCachedPlanResponse(request, contextHash, response);
            logPlanResult(response);
            return response;
        }

        Map<String, Map<Integer, Product>> candidateMapsByOpportunity = rankedOpportunities.stream()
                .collect(Collectors.toMap(
                        ranked -> ranked.opportunity().opportunityId(),
                        ranked -> ranked.candidates().stream()
                                .map(ScoredCandidate::product)
                                .filter(product -> product.getId() != null)
                                .collect(Collectors.toMap(Product::getId, product -> product, (first, ignored) -> first, LinkedHashMap::new)),
                        (first, ignored) -> first,
                        LinkedHashMap::new
                ));

        Optional<OpenAiPlanResult> openAiResult = rankPlanWithOpenAi(rankedOpportunities, requestId);
        PlanRankingResult ranking = openAiResult
                .map(result -> new PlanRankingResult(result.opportunities(), "openai"))
                .orElseGet(() -> new PlanRankingResult(fallbackPlanRank(rankedOpportunities), "fallback"));
        UpsellDtos.UpsellPlanDebug debug = openAiResult
                .map(OpenAiPlanResult::debug)
                .orElseGet(() -> planDebug(
                        requestId,
                        "fallback",
                        planStartedNanos,
                        null,
                        null,
                        "openai_unavailable_timeout_or_invalid",
                        opportunities.size(),
                        rankedCandidateCount
                ));

        Map<String, List<UpsellDtos.AiSuggestion>> rankedByOpportunity = ranking.opportunities().stream()
                .filter(opportunity -> opportunity != null && normalizeOptional(opportunity.opportunityId()) != null)
                .collect(Collectors.toMap(
                        opportunity -> normalizeOptional(opportunity.opportunityId()),
                        opportunity -> opportunity.suggestions() == null ? List.of() : opportunity.suggestions(),
                        (first, ignored) -> first,
                        LinkedHashMap::new
                ));

        List<UpsellDtos.UpsellOpportunityResponse> responses = new ArrayList<>();
        boolean hadRankedSuggestions = false;
        for (UpsellDtos.UpsellOpportunityRequest opportunity : opportunities) {
            List<UpsellDtos.AiSuggestion> ranked = rankedByOpportunity.getOrDefault(opportunity.opportunityId(), List.of());
            hadRankedSuggestions = hadRankedSuggestions || !ranked.isEmpty();
            responses.add(new UpsellDtos.UpsellOpportunityResponse(
                    opportunity.opportunityId(),
                    normalizedProductIds(opportunity.triggerProductIds(), null, false),
                    validatedSuggestions(
                            ranked,
                            candidateMapsByOpportunity.getOrDefault(opportunity.opportunityId(), Map.of())
                    )
            ));
        }

        String source = ranking.source();
        if (responses.stream().allMatch(response -> response.suggestions().isEmpty()) && hadRankedSuggestions) {
            source = "filtered";
        }

        UpsellDtos.UpsellPlanResponse response = new UpsellDtos.UpsellPlanResponse(
                responses,
                source,
                Instant.now().plus(Duration.ofMinutes(Math.max(1, cacheTtlMinutes))),
                withPlanElapsed(debug, source, planStartedNanos)
        );
        storeCachedPlanResponse(request, contextHash, response);
        logPlanResult(response);
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

    private Optional<UpsellDtos.UpsellPlanResponse> findCachedPlanResponse(String contextHash) {
        return cacheRepository.findFreshByContextHash(contextHash, Instant.now())
                .flatMap(entity -> {
                    try {
                        UpsellDtos.UpsellPlanResponse cached = objectMapper.readValue(
                                entity.responseJson,
                                UpsellDtos.UpsellPlanResponse.class
                        );
                        UpsellDtos.UpsellPlanDebug cachedDebug = cached.debug();
                        return Optional.of(new UpsellDtos.UpsellPlanResponse(
                                cached.opportunities(),
                                "cache",
                                entity.expiresAt,
                                cachedDebug == null
                                        ? null
                                        : new UpsellDtos.UpsellPlanDebug(
                                        cachedDebug.requestId(),
                                        cachedDebug.model(),
                                        "cache",
                                        cachedDebug.elapsedMs(),
                                        cachedDebug.openAiElapsedMs(),
                                        cachedDebug.inputTokens(),
                                        cachedDebug.outputTokens(),
                                        cachedDebug.totalTokens(),
                                        cachedDebug.cachedInputTokens(),
                                        cachedDebug.reasoningTokens(),
                                        cachedDebug.fallbackReason(),
                                        cachedDebug.opportunityCount(),
                                        cachedDebug.candidateCount()
                                )
                        ));
                    } catch (Exception exception) {
                        LOG.warn("Upsell plan cache entry could not be parsed", exception);
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

    private void storeCachedPlanResponse(
            UpsellDtos.UpsellPlanRequest request,
            String contextHash,
            UpsellDtos.UpsellPlanResponse response
    ) {
        try {
            UpsellSuggestionCacheEntity entity = new UpsellSuggestionCacheEntity();
            entity.checkedProductId = 0;
            entity.storeId = request.storeId();
            entity.storeCode = normalizeOptional(request.storeCode());
            entity.contextHash = contextHash;
            entity.responseJson = objectMapper.writeValueAsString(response);
            entity.source = normalizeOptional(response.source()) == null ? "unknown" : response.source();
            entity.expiresAt = response.expiresAt();
            cacheRepository.upsert(entity);
        } catch (Exception exception) {
            LOG.warn("Upsell plan cache write failed", exception);
        }
    }

    private record RankingResult(List<UpsellDtos.AiSuggestion> suggestions, String source) {
    }

    private record PlanRankingResult(List<UpsellDtos.AiOpportunitySuggestion> opportunities, String source) {
    }

    record OpportunityRankingInput(
            String opportunityId,
            List<Integer> triggerProductIds,
            List<String> triggerNames,
            List<Product> triggerProducts,
            Set<String> triggerCategories,
            Set<String> triggerTokens
    ) {
    }

    record ScoredCandidate(
            Product product,
            String categoryCode,
            int score,
            List<String> reasons,
            boolean storeMatched
    ) {
    }

    private record RankedOpportunity(
            UpsellDtos.UpsellOpportunityRequest opportunity,
            OpportunityRankingInput input,
            List<ScoredCandidate> candidates
    ) {
    }

    private record OpenAiPlanResult(
            List<UpsellDtos.AiOpportunitySuggestion> opportunities,
            UpsellDtos.UpsellPlanDebug debug
    ) {
    }

    private record OpenAiUsage(
            Integer inputTokens,
            Integer outputTokens,
            Integer totalTokens,
            Integer cachedInputTokens,
            Integer reasoningTokens
    ) {
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

    List<Product> loadPlanCandidates(
            UpsellDtos.UpsellPlanRequest request,
            List<UpsellDtos.UpsellOpportunityRequest> opportunities
    ) {
        try {
            List<Product> storeScoped = openSearchService.findUpsellCandidates(
                    Math.max(maxCandidates, maxSuggestions),
                    request.storeId() == null ? null : request.storeId().toString(),
                    request.storeCode()
            );
            List<Product> candidates = filterPlanCandidates(request, opportunities, storeScoped);

            if (candidates.size() < maxSuggestions && (request.storeId() != null || normalizeOptional(request.storeCode()) != null)) {
                List<Product> fallback = openSearchService.findUpsellCandidates(Math.max(maxCandidates, maxSuggestions), null, null);
                candidates = mergeCandidates(candidates, filterPlanCandidates(request, opportunities, fallback));
            }

            String storeId = request.storeId() == null ? null : request.storeId().toString();
            String storeCode = normalizeOptional(request.storeCode());
            return candidates.stream()
                    .sorted(Comparator
                            .comparingInt((Product product) -> storeScore(product, storeId, storeCode)).reversed()
                            .thenComparingInt(product -> hasLayoutPosition(product) ? 1 : 0).reversed()
                            .thenComparing(product -> product.getName() == null ? "" : product.getName(), String.CASE_INSENSITIVE_ORDER))
                    .limit(Math.max(1, maxCandidates))
                    .toList();
        } catch (IOException exception) {
            LOG.warn("Upsell plan candidate lookup failed", exception);
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

    List<Product> filterPlanCandidates(
            UpsellDtos.UpsellPlanRequest request,
            List<UpsellDtos.UpsellOpportunityRequest> opportunities,
            List<Product> rawCandidates
    ) {
        Set<Integer> excluded = new HashSet<>();
        if (request.currentListProductIds() != null) {
            excluded.addAll(request.currentListProductIds());
        }
        if (request.completedProductIds() != null) {
            excluded.addAll(request.completedProductIds());
        }
        for (UpsellDtos.UpsellOpportunityRequest opportunity : opportunities == null ? List.<UpsellDtos.UpsellOpportunityRequest>of() : opportunities) {
            if (opportunity.triggerProductIds() != null) {
                excluded.addAll(opportunity.triggerProductIds());
            }
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

    List<RankedOpportunity> rankPlanCandidates(
            UpsellDtos.UpsellPlanRequest request,
            List<UpsellDtos.UpsellOpportunityRequest> opportunities,
            List<Product> candidates,
            String requestId
    ) {
        String storeId = request.storeId() == null ? null : request.storeId().toString();
        String storeCode = normalizeOptional(request.storeCode());
        List<RankedOpportunity> ranked = new ArrayList<>();
        for (UpsellDtos.UpsellOpportunityRequest opportunity : opportunities) {
            OpportunityRankingInput input = rankingInput(opportunity);
            List<ScoredCandidate> scored = candidates.stream()
                    .map(candidate -> scoreCandidate(input, candidate, storeId, storeCode))
                    .filter(candidate -> candidate.score() >= Math.max(0, minDeterministicScore))
                    .sorted(scoredCandidateComparator())
                    .limit(Math.max(1, perOpportunityCandidates))
                    .toList();
            ranked.add(new RankedOpportunity(opportunity, input, scored));
        }
        logRankedCandidateCounts(requestId, candidates.size(), ranked);
        return ranked;
    }

    OpportunityRankingInput rankingInput(UpsellDtos.UpsellOpportunityRequest opportunity) {
        List<Integer> triggerProductIds = normalizedProductIds(opportunity.triggerProductIds(), null, false);
        List<Product> triggerProducts = triggerProductIds.stream()
                .map(this::resolveTriggerProduct)
                .flatMap(Optional::stream)
                .toList();

        Set<String> triggerCategories = triggerProducts.stream()
                .map(product -> categoryCode(product.getLayoutCode()))
                .filter(Objects::nonNull)
                .collect(Collectors.toCollection(LinkedHashSet::new));

        List<String> triggerNames = new ArrayList<>();
        if (opportunity.triggerProductNames() != null) {
            triggerNames.addAll(opportunity.triggerProductNames().stream()
                    .map(this::normalizeOptional)
                    .filter(Objects::nonNull)
                    .toList());
        }
        triggerNames.addAll(triggerProducts.stream()
                .map(Product::getName)
                .map(this::normalizeOptional)
                .filter(Objects::nonNull)
                .toList());

        Set<String> triggerTokens = triggerNames.stream()
                .flatMap(name -> productNameTokens(name).stream())
                .collect(Collectors.toCollection(LinkedHashSet::new));

        return new OpportunityRankingInput(
                opportunity.opportunityId(),
                triggerProductIds,
                triggerNames.stream().distinct().limit(20).toList(),
                triggerProducts,
                triggerCategories,
                triggerTokens
        );
    }

    private Optional<Product> resolveTriggerProduct(Integer productId) {
        try {
            Product product = openSearchService.getProductById(productId);
            if (product == null || product.getId() == null) {
                return Optional.empty();
            }
            return Optional.of(product);
        } catch (Exception exception) {
            LOG.debugf(exception, "Upsell trigger product lookup failed productId=%s", productId);
            return Optional.empty();
        }
    }

    ScoredCandidate scoreCandidate(
            OpportunityRankingInput input,
            Product candidate,
            String storeId,
            String storeCode
    ) {
        int score = 0;
        List<String> reasons = new ArrayList<>();

        int storeScore = storeScore(candidate, storeId, storeCode);
        boolean storeMatched = storeScore > 0;
        if (storeMatched) {
            score += 25 + (storeScore * 3);
            reasons.add("store");
        }

        if (hasLayoutPosition(candidate)) {
            score += 12;
            reasons.add("layout");
        }

        String category = categoryCode(candidate.getLayoutCode());
        if (category != null && input.triggerCategories().stream()
                .anyMatch(triggerCategory -> complementaryCategories(triggerCategory).contains(category))) {
            score += 55;
            reasons.add("category");
        }

        Set<String> candidateTokens = productNameTokens(candidate.getName());
        int keywordScore = keywordComplementScore(input.triggerTokens(), candidateTokens);
        if (keywordScore > 0) {
            score += keywordScore;
            reasons.add("keyword");
        }

        if (isAlternativeProduct(input.triggerTokens(), candidateTokens)) {
            score -= 35;
            reasons.add("alternative_penalty");
        }

        if (isWeakButterAssociation(input.triggerTokens(), candidateTokens, category)) {
            score -= 70;
            reasons.add("weak_butter_penalty");
        }

        return new ScoredCandidate(candidate, category, score, List.copyOf(reasons), storeMatched);
    }

    private Comparator<ScoredCandidate> scoredCandidateComparator() {
        return Comparator
                .comparingInt(ScoredCandidate::score).reversed()
                .thenComparing(candidate -> candidate.storeMatched() ? 0 : 1)
                .thenComparing(candidate -> hasLayoutPosition(candidate.product()) ? 0 : 1)
                .thenComparing(candidate -> candidate.product().getName() == null ? "" : candidate.product().getName(), String.CASE_INSENSITIVE_ORDER)
                .thenComparing(candidate -> candidate.product().getId() == null ? Integer.MAX_VALUE : candidate.product().getId());
    }

    Set<String> productNameTokens(String name) {
        String normalized = normalizeProductName(name);
        if (normalized == null) {
            return Set.of();
        }
        Set<String> tokens = new LinkedHashSet<>();
        for (String part : normalized.split("[^a-z0-9]+")) {
            if (part.length() >= 2) {
                tokens.add(part);
            }
        }
        addAliasTokens(normalized, tokens);
        return tokens;
    }

    String normalizeProductName(String name) {
        String normalized = normalizeOptional(name);
        if (normalized == null) {
            return null;
        }
        return normalized
                .toLowerCase(Locale.ROOT)
                .replace("ä", "ae")
                .replace("ö", "oe")
                .replace("ü", "ue")
                .replace("ß", "ss");
    }

    private void addAliasTokens(String normalized, Set<String> tokens) {
        if (containsAnyText(normalized, "butter")) {
            tokens.add("butter");
        }
        if (containsAnyText(normalized, "spaghetti", "nudel", "pasta", "penne", "fusilli", "farfalle")) {
            tokens.add("pasta");
        }
        if (containsAnyText(normalized, "tomatensauce", "tomatensosse", "tomatensosse", "sugo", "bolognese", "pesto")) {
            tokens.add("sauce");
        }
        if (containsAnyText(normalized, "hafer", "muesli", "cereal", "cornflakes", "flocken")) {
            tokens.add("cereal");
        }
        if (containsAnyText(normalized, "apfel", "aepfel", "banane", "beere", "erdbeer", "himbeer", "obst")) {
            tokens.add("fruit");
        }
        if (containsAnyText(normalized, "milch", "joghurt", "yoghurt", "topfen")) {
            tokens.add("dairy");
        }
        if (containsAnyText(normalized, "brot", "toast", "semmel", "weckerl", "baguette", "croissant", "gebaeck")) {
            tokens.add("bread");
        }
        if (containsAnyText(normalized, "kaffee", "espresso", "tee")) {
            tokens.add("drink_hot");
        }
        if (containsAnyText(normalized, "mehl", "zucker", "backpulver", "ei", "eier")) {
            tokens.add("baking");
        }
        if (containsAnyText(normalized, "marmelade", "honig", "aufstrich")) {
            tokens.add("spread");
        }
        if (containsAnyText(normalized, "parmesan", "kaese")) {
            tokens.add("cheese");
        }
        if (containsAnyText(normalized, "olivenoel", "oel")) {
            tokens.add("oil");
        }
    }

    private int keywordComplementScore(Set<String> triggerTokens, Set<String> candidateTokens) {
        int score = 0;
        for (String triggerToken : triggerTokens) {
            Set<String> complements = keywordComplements(triggerToken);
            for (String candidateToken : candidateTokens) {
                if (complements.contains(candidateToken)) {
                    score += 42;
                }
            }
        }
        return Math.min(score, 95);
    }

    private Set<String> keywordComplements(String token) {
        return switch (token) {
            case "butter" -> Set.of("bread", "toast", "brot", "marmelade", "honig", "spread", "baking", "mehl", "zucker", "eier", "ei", "milch", "dairy", "cereal");
            case "pasta", "spaghetti", "nudel", "penne", "fusilli" -> Set.of("sauce", "tomate", "tomatensauce", "pesto", "parmesan", "cheese", "kaese", "oil", "olivenoel");
            case "sauce", "tomatensauce", "sugo", "pesto", "bolognese" -> Set.of("pasta", "spaghetti", "nudel", "penne", "fusilli", "reis", "cheese");
            case "cereal", "hafer", "muesli", "cornflakes" -> Set.of("milch", "joghurt", "dairy", "fruit", "banane", "apfel", "aepfel", "honig", "spread");
            case "fruit", "apfel", "aepfel", "banane", "beere", "erdbeer" -> Set.of("joghurt", "dairy", "hafer", "cereal", "muesli", "honig", "spread");
            case "dairy", "milch", "joghurt" -> Set.of("cereal", "hafer", "muesli", "cornflakes", "fruit", "banane", "apfel", "aepfel", "baking");
            case "bread", "brot", "toast", "semmel", "weckerl" -> Set.of("butter", "kaese", "cheese", "wurst", "marmelade", "honig", "spread");
            case "drink_hot", "kaffee", "tee" -> Set.of("milch", "dairy", "zucker", "keks", "schokolade");
            case "baking", "mehl", "zucker", "backpulver", "ei", "eier" -> Set.of("butter", "milch", "dairy", "mehl", "zucker", "eier", "ei");
            default -> Set.of();
        };
    }

    private boolean isAlternativeProduct(Set<String> triggerTokens, Set<String> candidateTokens) {
        for (String productClass : Set.of("butter", "pasta", "sauce", "cereal", "fruit", "dairy", "bread", "drink_hot")) {
            if (triggerTokens.contains(productClass) && candidateTokens.contains(productClass)) {
                return true;
            }
        }
        return false;
    }

    private boolean isWeakButterAssociation(Set<String> triggerTokens, Set<String> candidateTokens, String category) {
        if (!triggerTokens.contains("butter")) {
            return false;
        }
        if ("430".equals(category) || "420".equals(category)) {
            return true;
        }
        return candidateTokens.contains("pasta") || candidateTokens.contains("sauce");
    }

    private boolean containsAnyText(String value, String... needles) {
        for (String needle : needles) {
            if (value.contains(needle)) {
                return true;
            }
        }
        return false;
    }

    private void logRankedCandidateCounts(
            String requestId,
            int broadCandidateCount,
            List<RankedOpportunity> rankedOpportunities
    ) {
        String counts = rankedOpportunities.stream()
                .map(opportunity -> opportunity.opportunity().opportunityId() + "=" + opportunity.candidates().size())
                .collect(Collectors.joining(","));
        LOG.infof(
                "Upsell plan candidate ranking requestId=%s broadCandidates=%d rankedCandidates=%d perOpportunity=%s",
                requestId,
                broadCandidateCount,
                rankedOpportunities.stream().mapToInt(opportunity -> opportunity.candidates().size()).sum(),
                counts
        );
    }

    List<UpsellDtos.AiSuggestion> fallbackRank(Product checkedProduct, List<Product> candidates) {
        return candidates.stream()
                .sorted(candidateComparator(checkedProduct, null))
                .limit(Math.max(1, maxSuggestions))
                .map(product -> new UpsellDtos.AiSuggestion(product.getId(), GENERIC_REASON, 0.62))
                .toList();
    }

    List<UpsellDtos.AiOpportunitySuggestion> fallbackPlanRank(List<RankedOpportunity> rankedOpportunities) {
        return rankedOpportunities.stream()
                .map(opportunity -> new UpsellDtos.AiOpportunitySuggestion(
                        opportunity.opportunity().opportunityId(),
                        opportunity.candidates().stream()
                                .limit(Math.max(1, maxSuggestions))
                                .map(candidate -> new UpsellDtos.AiSuggestion(
                                        candidate.product().getId(),
                                        fallbackReason(candidate),
                                        fallbackConfidence(candidate.score())
                                ))
                                .toList()
                ))
                .toList();
    }

    private String fallbackReason(ScoredCandidate candidate) {
        if (candidate.reasons().contains("keyword")) {
            return "Passt gut zum gerade erledigten Produkt.";
        }
        if (candidate.reasons().contains("category")) {
            return "Passt als praktische Ergaenzung zum gerade erledigten Produkt.";
        }
        return GENERIC_REASON;
    }

    private double fallbackConfidence(int score) {
        return clamp(0.55 + (Math.min(score, 160) / 400.0));
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

    Optional<OpenAiPlanResult> rankPlanWithOpenAi(List<RankedOpportunity> rankedOpportunities, String requestId) {
        Optional<String> apiKey = openAiApiKey.filter(key -> !key.isBlank());
        int candidateCount = rankedOpportunities.stream().mapToInt(opportunity -> opportunity.candidates().size()).sum();
        if (!openAiEnabled || apiKey.isEmpty() || candidateCount == 0 || rankedOpportunities.isEmpty()) {
            LOG.infof(
                    "Upsell plan OpenAI skipped requestId=%s enabled=%s hasApiKey=%s opportunities=%d candidates=%d",
                    requestId,
                    openAiEnabled,
                    apiKey.isPresent(),
                    rankedOpportunities.size(),
                    candidateCount
            );
            return Optional.empty();
        }

        long openAiStartedNanos = System.nanoTime();
        try {
            HttpClient client = HttpClient.newBuilder()
                    .connectTimeout(Duration.ofMillis(Math.max(500, openAiTimeoutMs)))
                    .build();
            String body = objectMapper.writeValueAsString(openAiPlanRequestBody(rankedOpportunities));
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create("https://api.openai.com/v1/responses"))
                    .timeout(Duration.ofMillis(Math.max(500, openAiTimeoutMs)))
                    .header("Authorization", "Bearer " + apiKey.get())
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(body, StandardCharsets.UTF_8))
                    .build();
            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            long openAiElapsedMs = elapsedMs(openAiStartedNanos);
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                LOG.warnf(
                        "OpenAI upsell plan ranking failed requestId=%s status=%d elapsedMs=%d response=%s",
                        requestId,
                        response.statusCode(),
                        openAiElapsedMs,
                        truncateForLog(response.body(), 500)
                );
                return Optional.empty();
            }

            String outputJson = extractResponsesText(response.body());
            if (outputJson == null || outputJson.isBlank()) {
                LOG.warnf(
                        "OpenAI upsell plan ranking returned empty output requestId=%s elapsedMs=%d",
                        requestId,
                        openAiElapsedMs
                );
                return Optional.empty();
            }

            UpsellDtos.AiPlanResponse parsed = objectMapper.readValue(outputJson, UpsellDtos.AiPlanResponse.class);
            OpenAiUsage usage = extractOpenAiUsage(response.body());
            LOG.infof(
                    "OpenAI upsell plan ranking succeeded requestId=%s model=%s elapsedMs=%d inputTokens=%s outputTokens=%s totalTokens=%s cachedInputTokens=%s reasoningTokens=%s opportunities=%d candidates=%d output=%s",
                    requestId,
                    openAiModel,
                    openAiElapsedMs,
                    usage.inputTokens(),
                    usage.outputTokens(),
                    usage.totalTokens(),
                    usage.cachedInputTokens(),
                    usage.reasoningTokens(),
                    rankedOpportunities.size(),
                    candidateCount,
                    truncateForLog(outputJson, 1200)
            );
            return Optional.ofNullable(parsed.opportunities())
                    .filter(list -> !list.isEmpty())
                    .map(list -> new OpenAiPlanResult(
                            list,
                            new UpsellDtos.UpsellPlanDebug(
                                    requestId,
                                    openAiModel,
                                    "openai",
                                    null,
                                    openAiElapsedMs,
                                    usage.inputTokens(),
                                    usage.outputTokens(),
                                    usage.totalTokens(),
                                    usage.cachedInputTokens(),
                                    usage.reasoningTokens(),
                                    null,
                                    rankedOpportunities.size(),
                                    candidateCount
                            )
                    ));
        } catch (Exception exception) {
            LOG.warnf(
                    exception,
                    "OpenAI upsell plan ranking failed; falling back requestId=%s elapsedMs=%d opportunities=%d candidates=%d",
                    requestId,
                    elapsedMs(openAiStartedNanos),
                    rankedOpportunities.size(),
                    candidateCount
            );
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

    Map<String, Object> openAiPlanRequestBody(List<RankedOpportunity> rankedOpportunities) throws IOException {
        Map<String, Object> suggestionSchema = Map.of(
                "type", "object",
                "additionalProperties", false,
                "required", List.of("productId", "reason", "confidence"),
                "properties", Map.of(
                        "productId", Map.of("type", "integer"),
                        "reason", Map.of("type", "string", "maxLength", 180),
                        "confidence", Map.of("type", "number", "minimum", 0, "maximum", 1)
                )
        );
        Map<String, Object> schema = Map.of(
                "type", "object",
                "additionalProperties", false,
                "required", List.of("opportunities"),
                "properties", Map.of(
                        "opportunities", Map.of(
                                "type", "array",
                                "maxItems", Math.max(1, rankedOpportunities.size()),
                                "items", Map.of(
                                        "type", "object",
                                        "additionalProperties", false,
                                        "required", List.of("opportunityId", "suggestions"),
                                        "properties", Map.of(
                                                "opportunityId", Map.of("type", "string"),
                                                "suggestions", Map.of(
                                                        "type", "array",
                                                        "maxItems", Math.max(1, maxSuggestions),
                                                        "items", suggestionSchema
                                                )
                                        )
                                )
                        )
                )
        );

        Map<String, Object> payload = Map.of(
                "opportunities", rankedOpportunities.stream().map(this::toAiOpportunity).toList(),
                "maxSuggestionsPerOpportunity", Math.max(1, maxSuggestions)
        );

        Map<String, Object> requestBody = new LinkedHashMap<>();
        requestBody.put("model", openAiModel);
        requestBody.put("input", List.of(
                Map.of(
                        "role", "system",
                        "content", "Rank supermarket add-on products for each shopping station. Select only productIds from the candidateProducts listed on the same opportunity and only opportunityIds from opportunities. Do not invent products or opportunityIds. Reasons must be concise German customer-facing text."
                ),
                Map.of(
                        "role", "user",
                        "content", objectMapper.writeValueAsString(payload)
                )
        ));
        requestBody.put("text", Map.of(
                "format", Map.of(
                        "type", "json_schema",
                        "name", "upsell_plan",
                        "strict", true,
                        "schema", schema
                )
        ));
        requestBody.put("max_output_tokens", Math.max(800, rankedOpportunities.size() * 220));

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

    private Map<String, Object> toAiOpportunity(UpsellDtos.UpsellOpportunityRequest opportunity) {
        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("opportunityId", opportunity.opportunityId());
        summary.put("triggerProductIds", normalizedProductIds(opportunity.triggerProductIds(), null, false));
        summary.put("triggerProductNames", opportunity.triggerProductNames() == null
                ? List.of()
                : opportunity.triggerProductNames().stream()
                .map(this::normalizeOptional)
                .filter(Objects::nonNull)
                .limit(20)
                .toList());
        return summary;
    }

    private Map<String, Object> toAiOpportunity(RankedOpportunity rankedOpportunity) {
        Map<String, Object> summary = toAiOpportunity(rankedOpportunity.opportunity());
        summary.put("candidateProducts", rankedOpportunity.candidates().stream()
                .map(this::toAiCandidateSummary)
                .toList());
        return summary;
    }

    private Map<String, Object> toAiCandidateSummary(ScoredCandidate candidate) {
        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("id", candidate.product().getId());
        summary.put("name", candidate.product().getName());
        summary.put("categoryCode", candidate.categoryCode());
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

    private OpenAiUsage extractOpenAiUsage(String body) {
        try {
            JsonNode root = objectMapper.readTree(body);
            JsonNode usage = root.get("usage");
            if (usage == null || !usage.isObject()) {
                return new OpenAiUsage(null, null, null, null, null);
            }
            JsonNode inputDetails = usage.get("input_tokens_details");
            JsonNode outputDetails = usage.get("output_tokens_details");
            return new OpenAiUsage(
                    intOrNull(usage.get("input_tokens")),
                    intOrNull(usage.get("output_tokens")),
                    intOrNull(usage.get("total_tokens")),
                    inputDetails == null ? null : intOrNull(inputDetails.get("cached_tokens")),
                    outputDetails == null ? null : intOrNull(outputDetails.get("reasoning_tokens"))
            );
        } catch (Exception exception) {
            return new OpenAiUsage(null, null, null, null, null);
        }
    }

    private Integer intOrNull(JsonNode node) {
        return node != null && node.canConvertToInt() ? node.asInt() : null;
    }

    private long elapsedMs(long startedNanos) {
        return Duration.ofNanos(System.nanoTime() - startedNanos).toMillis();
    }

    private String truncateForLog(String value, int maxLength) {
        if (value == null || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, Math.max(0, maxLength - 3)) + "...";
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
        groups.put("430", Set.of("420", "450", "525", "445"));
        groups.put("420", Set.of("430", "450", "445", "525"));
        groups.put("525", Set.of("510", "445", "440", "470", "520"));
        groups.put("310", Set.of("440", "520", "470"));
        groups.put("520", Set.of("440", "310", "445"));
        groups.put("440", Set.of("520", "310"));
        groups.put("445", Set.of("520", "525", "310"));
        groups.put("510", Set.of("470", "525", "445"));
        groups.put("470", Set.of("510", "440", "525"));
        groups.put("450", Set.of("430", "420", "445"));
        groups.put("530", Set.of("420", "430", "450"));
        return groups.getOrDefault(categoryCode, Set.of());
    }

    String categoryCode(String layoutCode) {
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

    private UpsellDtos.UpsellPlanResponse emptyPlanResponse(
            List<UpsellDtos.UpsellOpportunityRequest> opportunities,
            String source,
            UpsellDtos.UpsellPlanDebug debug
    ) {
        List<UpsellDtos.UpsellOpportunityResponse> responses = opportunities.stream()
                .map(opportunity -> new UpsellDtos.UpsellOpportunityResponse(
                        opportunity.opportunityId(),
                        normalizedProductIds(opportunity.triggerProductIds(), null, false),
                        List.of()
                ))
                .toList();
        return new UpsellDtos.UpsellPlanResponse(
                responses,
                source,
                Instant.now().plus(Duration.ofMinutes(Math.max(1, cacheTtlMinutes))),
                debug
        );
    }

    private UpsellDtos.UpsellPlanDebug planDebug(
            String requestId,
            String source,
            long planStartedNanos,
            Long openAiElapsedMs,
            OpenAiUsage usage,
            String fallbackReason,
            int opportunityCount,
            int candidateCount
    ) {
        return new UpsellDtos.UpsellPlanDebug(
                requestId,
                openAiModel,
                source,
                elapsedMs(planStartedNanos),
                openAiElapsedMs,
                usage == null ? null : usage.inputTokens(),
                usage == null ? null : usage.outputTokens(),
                usage == null ? null : usage.totalTokens(),
                usage == null ? null : usage.cachedInputTokens(),
                usage == null ? null : usage.reasoningTokens(),
                fallbackReason,
                opportunityCount,
                candidateCount
        );
    }

    private UpsellDtos.UpsellPlanDebug withPlanElapsed(
            UpsellDtos.UpsellPlanDebug debug,
            String source,
            long planStartedNanos
    ) {
        if (debug == null) {
            return null;
        }
        return new UpsellDtos.UpsellPlanDebug(
                debug.requestId(),
                debug.model(),
                source,
                elapsedMs(planStartedNanos),
                debug.openAiElapsedMs(),
                debug.inputTokens(),
                debug.outputTokens(),
                debug.totalTokens(),
                debug.cachedInputTokens(),
                debug.reasoningTokens(),
                debug.fallbackReason(),
                debug.opportunityCount(),
                debug.candidateCount()
        );
    }

    private void logPlanResult(UpsellDtos.UpsellPlanResponse response) {
        UpsellDtos.UpsellPlanDebug debug = response.debug();
        String requestId = debug == null ? "unknown" : debug.requestId();
        int suggestionCount = response.opportunities() == null
                ? 0
                : response.opportunities().stream().mapToInt(opportunity -> opportunity.suggestions().size()).sum();
        LOG.infof(
                "Upsell plan response requestId=%s source=%s elapsedMs=%s openAiElapsedMs=%s inputTokens=%s outputTokens=%s totalTokens=%s fallbackReason=%s opportunities=%d suggestions=%d",
                requestId,
                response.source(),
                debug == null ? null : debug.elapsedMs(),
                debug == null ? null : debug.openAiElapsedMs(),
                debug == null ? null : debug.inputTokens(),
                debug == null ? null : debug.outputTokens(),
                debug == null ? null : debug.totalTokens(),
                debug == null ? null : debug.fallbackReason(),
                response.opportunities() == null ? 0 : response.opportunities().size(),
                suggestionCount
        );
    }

    private List<UpsellDtos.UpsellOpportunityRequest> normalizedOpportunities(
            List<UpsellDtos.UpsellOpportunityRequest> rawOpportunities
    ) {
        Map<String, UpsellDtos.UpsellOpportunityRequest> unique = new LinkedHashMap<>();
        for (UpsellDtos.UpsellOpportunityRequest opportunity : rawOpportunities == null ? List.<UpsellDtos.UpsellOpportunityRequest>of() : rawOpportunities) {
            String id = opportunity == null ? null : normalizeOptional(opportunity.opportunityId());
            if (id == null || unique.containsKey(id)) {
                continue;
            }
            List<Integer> triggerProductIds = normalizedProductIds(opportunity.triggerProductIds(), null, false);
            List<String> triggerNames = opportunity.triggerProductNames() == null
                    ? List.of()
                    : opportunity.triggerProductNames().stream()
                    .map(this::normalizeOptional)
                    .filter(Objects::nonNull)
                    .limit(20)
                    .toList();
            if (triggerProductIds.isEmpty() && triggerNames.isEmpty()) {
                continue;
            }
            unique.put(id, new UpsellDtos.UpsellOpportunityRequest(id, triggerProductIds, triggerNames));
        }
        return new ArrayList<>(unique.values());
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

    String planContextHash(
            UpsellDtos.UpsellPlanRequest request,
            List<UpsellDtos.UpsellOpportunityRequest> opportunities
    ) {
        Map<String, Object> context = new LinkedHashMap<>();
        context.put("version", PLAN_CACHE_CONTEXT_VERSION);
        context.put("storeId", request.storeId() == null ? null : request.storeId().toString());
        context.put("storeCode", normalizeOptional(request.storeCode()) == null ? null : normalizeOptional(request.storeCode()).toLowerCase(Locale.ROOT));
        context.put("shoppingListId", normalizeOptional(request.shoppingListId()));
        context.put("currentListProductIds", normalizedProductIds(request.currentListProductIds(), null, false));
        context.put("completedProductIds", normalizedProductIds(request.completedProductIds(), null, false));
        context.put("opportunities", opportunities.stream()
                .map(opportunity -> Map.of(
                        "opportunityId", opportunity.opportunityId(),
                        "triggerProductIds", normalizedProductIds(opportunity.triggerProductIds(), null, false),
                        "triggerProductNames", opportunity.triggerProductNames() == null ? List.of() : opportunity.triggerProductNames()
                ))
                .toList());
        context.put("maxSuggestions", Math.max(1, maxSuggestions));
        context.put("minConfidence", minConfidence);
        context.put("perOpportunityCandidates", Math.max(1, perOpportunityCandidates));
        context.put("minDeterministicScore", Math.max(0, minDeterministicScore));
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
