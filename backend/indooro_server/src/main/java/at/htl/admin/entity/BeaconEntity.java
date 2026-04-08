package at.htl.admin.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "beacons")
public class BeaconEntity extends AuditableEntity {

    @Column(name = "beacon_code", nullable = false, unique = true, length = 60)
    public String beaconCode;

    @Column(name = "identity_key", nullable = false, unique = true, length = 140)
    public String identityKey;

    @Column(nullable = false)
    public UUID uuid;

    public Integer major;

    public Integer minor;

    @Column(columnDefinition = "TEXT")
    public String notes;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    public RecordStatus status = RecordStatus.ACTIVE;
}
