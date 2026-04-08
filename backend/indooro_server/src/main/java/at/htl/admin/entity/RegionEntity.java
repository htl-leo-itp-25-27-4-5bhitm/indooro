package at.htl.admin.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;

@Entity
@Table(name = "regions")
public class RegionEntity extends AuditableEntity {

    @Column(nullable = false, unique = true, length = 50)
    public String code;

    @Column(nullable = false, length = 120)
    public String name;

    @Column(columnDefinition = "TEXT")
    public String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    public RecordStatus status = RecordStatus.ACTIVE;
}
