package at.htl.admin.repository;

import at.htl.admin.entity.StoreEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class StoreRepository implements PanacheRepositoryBase<StoreEntity, UUID> {

    public Optional<StoreEntity> findByStoreCode(String storeCode) {
        return find("lower(storeCode) = ?1", storeCode.toLowerCase()).firstResultOptional();
    }
}
