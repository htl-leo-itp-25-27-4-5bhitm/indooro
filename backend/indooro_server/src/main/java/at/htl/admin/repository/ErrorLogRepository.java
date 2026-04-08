package at.htl.admin.repository;

import at.htl.admin.entity.ErrorLogEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class ErrorLogRepository implements PanacheRepositoryBase<ErrorLogEntity, UUID> {

    public List<ErrorLogEntity> listRecent(int limit) {
        return find("order by createdAt desc").page(0, Math.max(1, limit)).list();
    }
}
