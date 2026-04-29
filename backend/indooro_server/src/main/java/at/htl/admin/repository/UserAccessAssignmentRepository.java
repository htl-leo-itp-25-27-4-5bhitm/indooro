package at.htl.admin.repository;

import at.htl.admin.entity.UserAccessAssignmentEntity;
import at.htl.admin.entity.UserAccessStatus;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class UserAccessAssignmentRepository implements PanacheRepositoryBase<UserAccessAssignmentEntity, UUID> {

    public Optional<UserAccessAssignmentEntity> findActiveBySubject(String subject) {
        return find("keycloakSubject = ?1 and status = ?2", subject, UserAccessStatus.ACTIVE).firstResultOptional();
    }
}
