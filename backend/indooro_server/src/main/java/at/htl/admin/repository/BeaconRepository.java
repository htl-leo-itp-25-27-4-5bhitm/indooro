package at.htl.admin.repository;

import at.htl.admin.entity.BeaconEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

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
}
