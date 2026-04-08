package at.htl.admin.repository;

import at.htl.admin.entity.RegionEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class RegionRepository implements PanacheRepositoryBase<RegionEntity, UUID> {

    public Optional<RegionEntity> findByCode(String code) {
        return find("lower(code) = ?1", code.toLowerCase()).firstResultOptional();
    }
}
