package at.htl.admin.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "beacon_assignments")
public class BeaconAssignmentEntity extends AuditableEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "beacon_id", nullable = false)
    public BeaconEntity beacon;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "store_id", nullable = false)
    public StoreEntity store;

    @Column(name = "assigned_at", nullable = false)
    public Instant assignedAt;

    @Column(name = "released_at")
    public Instant releasedAt;

    @Column(name = "is_active", nullable = false)
    public boolean isActive = true;

    @PrePersist
    void onAssignmentCreate() {
        if (assignedAt == null) {
            assignedAt = Instant.now();
        }
    }
}
