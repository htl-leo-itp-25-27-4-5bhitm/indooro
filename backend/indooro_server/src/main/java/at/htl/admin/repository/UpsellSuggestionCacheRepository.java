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
}
