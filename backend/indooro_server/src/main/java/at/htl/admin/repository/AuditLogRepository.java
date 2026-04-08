package at.htl.admin.repository;

import at.htl.admin.entity.AuditLogEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class AuditLogRepository implements PanacheRepositoryBase<AuditLogEntity, UUID> {

    public List<AuditLogEntity> listByEntity(String entityType, UUID entityId) {
        return list("entityType = ?1 and entityId = ?2 order by createdAt desc", entityType, entityId);
    }

    public List<AuditLogEntity> listRecent(int limit) {
        return find("order by createdAt desc").page(0, Math.max(1, limit)).list();
    }
}
