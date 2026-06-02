package at.htl.admin.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "upsell_events")
public class UpsellEventEntity extends AuditableEntity {

    @Column(name = "event_type", nullable = false, length = 40)
    public String eventType;

    @Column(name = "checked_product_id")
    public Integer checkedProductId;

    @Column(name = "suggested_product_id")
    public Integer suggestedProductId;

    @Column(name = "store_id")
    public UUID storeId;

    @Column(name = "store_code", length = 50)
    public String storeCode;

    @Column(name = "session_hash", length = 128)
    public String sessionHash;

    @Column(length = 40)
    public String source;

    @Column(name = "metadata_json", columnDefinition = "TEXT")
    public String metadataJson;
}
