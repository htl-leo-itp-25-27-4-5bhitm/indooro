package at.htl.admin.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "upsell_dismissals")
public class UpsellDismissalEntity extends AuditableEntity {

    @Column(name = "checked_product_id", nullable = false)
    public Integer checkedProductId;

    @Column(name = "suggested_product_id")
    public Integer suggestedProductId;

    @Column(name = "store_id")
    public UUID storeId;

    @Column(name = "store_code", length = 50)
    public String storeCode;

    @Column(name = "session_hash", length = 128)
    public String sessionHash;

    @Column(name = "dismissal_count", nullable = false)
    public int dismissalCount = 1;

    @Column(name = "suppressed_until")
    public Instant suppressedUntil;
}
