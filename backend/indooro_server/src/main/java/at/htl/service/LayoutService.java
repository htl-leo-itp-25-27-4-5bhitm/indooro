package at.htl.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;
import org.opensearch.client.opensearch.OpenSearchClient;
import org.opensearch.client.opensearch._types.Refresh;
import org.opensearch.client.opensearch.core.GetResponse;

import java.io.IOException;
import java.io.InputStream;

@ApplicationScoped
public class LayoutService {

    private static final Logger LOG = Logger.getLogger(LayoutService.class);
    private static final String CURRENT_LAYOUT_ID = "current";

    @Inject
    OpenSearchClient client;

    @Inject
    ObjectMapper objectMapper;

    @ConfigProperty(name = "opensearch.layout-index")
    String layoutIndexName;

    public JsonNode getCurrentLayout() throws IOException {
        ensureLayoutIndex();

        GetResponse<JsonNode> response = client.get(
                g -> g.index(layoutIndexName).id(CURRENT_LAYOUT_ID),
                JsonNode.class
        );

        if (response.found() && response.source() != null) {
            return response.source();
        }

        LOG.info("No saved layout found in OpenSearch, falling back to bundled default layout");
        return loadDefaultLayout();
    }

    public void saveCurrentLayout(JsonNode layout) throws IOException {
        ensureLayoutIndex();

        client.index(i -> i
                .index(layoutIndexName)
                .id(CURRENT_LAYOUT_ID)
                .document(layout)
                .refresh(Refresh.True)
        );

        LOG.info("Saved current layout to OpenSearch index " + layoutIndexName);
    }

    private void ensureLayoutIndex() throws IOException {
        try {
            client.indices().create(c -> c.index(layoutIndexName));
            LOG.info("Created layout index " + layoutIndexName);
        } catch (Exception e) {
            LOG.debug("Layout index already exists or could not be created again: " + e.getMessage());
        }
    }

    private JsonNode loadDefaultLayout() throws IOException {
        try (InputStream input = Thread.currentThread()
                .getContextClassLoader()
                .getResourceAsStream("default-layout.json")) {
            if (input == null) {
                return objectMapper.createObjectNode();
            }
            return objectMapper.readTree(input);
        }
    }
}
