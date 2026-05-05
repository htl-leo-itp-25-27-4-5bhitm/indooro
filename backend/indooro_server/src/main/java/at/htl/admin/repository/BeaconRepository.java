package at.htl.admin.repository;

import at.htl.admin.entity.BeaconEntity;
import at.htl.admin.entity.RecordStatus;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class BeaconRepository implements PanacheRepositoryBase<BeaconEntity, UUID> {

    public Optional<BeaconEntity> findByBeaconCode(String beaconCode) {
        return find("lower(beaconCode) = ?1", beaconCode.toLowerCase()).firstResultOptional();
    }

    public Optional<BeaconEntity> findByIdentityKey(String identityKey) {
        return find("identityKey", identityKey).firstResultOptional();
    }

    public List<BeaconEntity> listActiveByUuid(String uuid) {
        return list("uuid = ?1 and status = ?2", uuid, RecordStatus.ACTIVE);
    }

    public List<String> listActiveAssignedMobileUuids() {
        return getEntityManager()
                .createQuery("""
                        select distinct b.uuid
                        from BeaconAssignmentEntity assignment
                        join assignment.beacon b
                        join assignment.store s
                        where assignment.isActive = true
                          and b.status = :activeStatus
                          and s.status = :activeStatus
                          and b.uuid is not null
                        order by b.uuid
                        """, String.class)
                .setParameter("activeStatus", RecordStatus.ACTIVE)
                .getResultList();
    }
}
