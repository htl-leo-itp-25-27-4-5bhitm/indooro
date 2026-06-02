package at.htl.admin.repository;

import at.htl.admin.entity.UpsellEventEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.UUID;

@ApplicationScoped
public class UpsellEventRepository implements PanacheRepositoryBase<UpsellEventEntity, UUID> {
}
