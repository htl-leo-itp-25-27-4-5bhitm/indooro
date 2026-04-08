package at.htl.admin.repository;

import at.htl.admin.entity.LayoutVersionEntity;
import at.htl.admin.entity.LayoutVersionStatus;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class LayoutVersionRepository implements PanacheRepositoryBase<LayoutVersionEntity, UUID> {

    public Optional<LayoutVersionEntity> findActiveByStoreId(UUID storeId) {
        return find("store.id = ?1 and status = ?2", storeId, LayoutVersionStatus.ACTIVE).firstResultOptional();
    }

    public List<LayoutVersionEntity> listByStoreId(UUID storeId) {
        return list("store.id = ?1 order by versionNo desc", storeId);
    }

    public Optional<LayoutVersionEntity> findByStoreAndId(UUID storeId, UUID layoutId) {
        return find("store.id = ?1 and id = ?2", storeId, layoutId).firstResultOptional();
    }

    public int nextVersionNo(UUID storeId) {
        Integer maxVersion = getEntityManager()
                .createQuery("select max(l.versionNo) from LayoutVersionEntity l where l.store.id = :storeId", Integer.class)
                .setParameter("storeId", storeId)
                .getSingleResult();
        return maxVersion == null ? 1 : maxVersion + 1;
    }
}
