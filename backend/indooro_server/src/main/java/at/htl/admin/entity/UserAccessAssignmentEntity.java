package at.htl.admin.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "user_access_assignments")
public class UserAccessAssignmentEntity extends AuditableEntity {

    @Column(name = "keycloak_subject", nullable = false, length = 120)
    public String keycloakSubject;

    @Column(nullable = false, length = 120)
    public String username;

    @Column(length = 254)
    public String email;

    @Column(nullable = false, length = 40)
    public String role;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "region_id")
    public RegionEntity region;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "store_id")
    public StoreEntity store;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    public UserAccessStatus status = UserAccessStatus.ACTIVE;
}
