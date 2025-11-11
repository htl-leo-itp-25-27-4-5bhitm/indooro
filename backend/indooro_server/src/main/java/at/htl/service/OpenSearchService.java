package at.htl.service;


import at.htl.model.Product;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.opensearch.client.opensearch.OpenSearchClient;
import org.opensearch.client.opensearch._types.query_dsl.Query;
import org.opensearch.client.opensearch.core.*;
import org.opensearch.client.opensearch.core.search.Hit;
import org.jboss.logging.Logger;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@ApplicationScoped
public class OpenSearchService {

    private static final Logger LOG = Logger.getLogger(OpenSearchService.class);

    @Inject
    OpenSearchClient client;

    @ConfigProperty(name = "opensearch.index")
    String indexName;

    /**
     * Sucht Produkte anhand eines Suchbegriffs
     */
    public List<Product> searchProducts(String query, Integer size) throws IOException {
        final Integer finalSize = (size == null) ? 10 : size;

        SearchRequest searchRequest = SearchRequest.of(s -> s
                .index(indexName)
                .query(q -> q
                        .multiMatch(m -> m
                                .query(query)
                                .fields("name^2", "layoutCode")
                                .fuzziness("AUTO")
                        )
                )
                .size(finalSize)
        );

        SearchResponse<Product> response = client.search(searchRequest, Product.class);

        return response.hits().hits().stream()
                .map(Hit::source)
                .collect(Collectors.toList());
    }

    /**
     * Holt ein Produkt anhand der ID
     */
    public Product getProductById(Integer id) throws IOException {
        GetRequest getRequest = GetRequest.of(g -> g
                .index(indexName)
                .id(String.valueOf(id))
        );

        GetResponse<Product> response = client.get(getRequest, Product.class);

        if (response.found()) {
            return response.source();
        }
        return null;
    }

    /**
     * Holt alle Produkte
     */
    public List<Product> getAllProducts(Integer size) throws IOException {
        final Integer finalSize = (size == null) ? 100 : size;

        SearchRequest searchRequest = SearchRequest.of(s -> s
                .index(indexName)
                .query(q -> q.matchAll(m -> m))
                .size(finalSize)
        );

        SearchResponse<Product> response = client.search(searchRequest, Product.class);

        return response.hits().hits().stream()
                .map(Hit::source)
                .collect(Collectors.toList());
    }

    /**
     * Indexiert ein einzelnes Produkt
     */
    public String indexProduct(Product product) throws IOException {
        IndexRequest<Product> request = IndexRequest.of(i -> i
                .index(indexName)
                .id(String.valueOf(product.getId()))
                .document(product)
        );

        IndexResponse response = client.index(request);
        LOG.info("Indexed product: " + product.getName() + " with result: " + response.result());

        return response.result().toString();
    }

    /**
     * Indexiert mehrere Produkte in einem Bulk-Request
     */
    public void indexProducts(List<Product> products) throws IOException {
        BulkRequest.Builder bulkBuilder = new BulkRequest.Builder();

        for (Product product : products) {
            bulkBuilder.operations(op -> op
                    .index(idx -> idx
                            .index(indexName)
                            .id(String.valueOf(product.getId()))
                            .document(product)
                    )
            );
        }

        BulkResponse response = client.bulk(bulkBuilder.build());

        if (response.errors()) {
            LOG.error("Bulk indexing had errors");
            response.items().forEach(item -> {
                if (item.error() != null) {
                    LOG.error("Error: " + item.error().reason());
                }
            });
        } else {
            LOG.info("Successfully indexed " + products.size() + " products");
        }
    }

    /**
     * Erstellt den Index mit Mapping
     */
    public void createIndex() throws IOException {
        try {
            client.indices().create(c -> c
                    .index(indexName)
                    .mappings(m -> m
                            .properties("id", p -> p.integer(i -> i))
                            .properties("name", p -> p.text(t -> t.analyzer("standard")))
                            .properties("price", p -> p.double_(d -> d))
                            .properties("layoutCode", p -> p.keyword(k -> k))
                    )
            );
            LOG.info("Index " + indexName + " created successfully");
        } catch (Exception e) {
            LOG.warn("Index might already exist: " + e.getMessage());
        }
    }

    /**
     * Löscht den Index
     */
    public void deleteIndex() throws IOException {
        try {
            client.indices().delete(d -> d.index(indexName));
            LOG.info("Index " + indexName + " deleted successfully");
        } catch (Exception e) {
            LOG.warn("Could not delete index: " + e.getMessage());
        }
    }
}