package at.htl.admin.repository;

import at.htl.admin.entity.UpsellDismissalEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class UpsellDismissalRepository implements PanacheRepositoryBase<UpsellDismissalEntity, UUID> {

    public Optional<UpsellDismissalEntity> findMatching(
            Integer checkedProductId,
            Integer suggestedProductId,
            UUID storeId,
            String sessionHash
    ) {
        return find(
                "checkedProductId = ?1 and suggestedProductId = ?2 and storeId = ?3 and sessionHash = ?4",
                checkedProductId,
                suggestedProductId,
                storeId,
                sessionHash
        ).firstResultOptional();
    }
}
