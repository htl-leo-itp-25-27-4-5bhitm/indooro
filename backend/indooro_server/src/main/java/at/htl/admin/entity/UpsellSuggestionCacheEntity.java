package at.htl.admin.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "upsell_suggestion_cache")
public class UpsellSuggestionCacheEntity extends AuditableEntity {

    @Column(name = "checked_product_id", nullable = false)
    public Integer checkedProductId;

    @Column(name = "store_id")
    public UUID storeId;

    @Column(name = "store_code", length = 50)
    public String storeCode;

    @Column(name = "context_hash", nullable = false, length = 128, unique = true)
    public String contextHash;

    @Column(name = "response_json", nullable = false, columnDefinition = "TEXT")
    public String responseJson;

    @Column(nullable = false, length = 40)
    public String source;

    @Column(name = "expires_at", nullable = false)
    public Instant expiresAt;
}
