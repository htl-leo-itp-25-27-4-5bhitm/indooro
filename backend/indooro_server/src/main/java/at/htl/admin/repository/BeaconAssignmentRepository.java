package at.htl.admin.repository;

import at.htl.admin.entity.BeaconAssignmentEntity;
import at.htl.admin.entity.StoreEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class BeaconAssignmentRepository implements PanacheRepositoryBase<BeaconAssignmentEntity, UUID> {

    public Optional<BeaconAssignmentEntity> findActiveByBeaconId(UUID beaconId) {
        return find("beacon.id = ?1 and isActive = true", beaconId).firstResultOptional();
    }

    public List<BeaconAssignmentEntity> listActiveByStoreId(UUID storeId) {
        return list("store.id = ?1 and isActive = true order by assignedAt desc", storeId);
    }

    public long countActiveByStore(StoreEntity store) {
        return count("store = ?1 and isActive = true", store);
    }

    public List<BeaconAssignmentEntity> listActiveAssignments() {
        return list("isActive = true");
    }
}
