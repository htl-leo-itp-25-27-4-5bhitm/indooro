package at.htl.admin.repository;

import at.htl.admin.entity.UpsellSuggestionCacheEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class UpsellSuggestionCacheRepository implements PanacheRepositoryBase<UpsellSuggestionCacheEntity, UUID> {

    public Optional<UpsellSuggestionCacheEntity> findFreshByContextHash(String contextHash, Instant now) {
        return find("contextHash = ?1 and expiresAt > ?2", contextHash, now).firstResultOptional();
    }

    public Optional<UpsellSuggestionCacheEntity> findByContextHash(String contextHash) {
        return find("contextHash", contextHash).firstResultOptional();
    }

    public void upsert(UpsellSuggestionCacheEntity incoming) {
        UpsellSuggestionCacheEntity entity = findByContextHash(incoming.contextHash).orElse(incoming);
        entity.checkedProductId = incoming.checkedProductId;
        entity.storeId = incoming.storeId;
        entity.storeCode = incoming.storeCode;
        entity.contextHash = incoming.contextHash;
        entity.responseJson = incoming.responseJson;
        entity.source = incoming.source;
        entity.expiresAt = incoming.expiresAt;
        if (entity.id == null) {
            persist(entity);
        }
    }
}
