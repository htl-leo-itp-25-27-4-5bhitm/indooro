package at.htl.admin.entity;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;

@Entity
@Table(name = "layout_versions")
public class LayoutVersionEntity extends AuditableEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "store_id", nullable = false)
    public StoreEntity store;

    @Column(name = "version_no", nullable = false)
    public int versionNo;

    @Column(name = "layout_name", length = 150)
    public String layoutName;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "layout_json", nullable = false, columnDefinition = "jsonb")
    public JsonNode layoutJson;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    public LayoutVersionStatus status = LayoutVersionStatus.DRAFT;

    @Column(name = "change_note", columnDefinition = "TEXT")
    public String changeNote;

    @Column(name = "created_by_role", length = 40)
    public String createdByRole;

    @Column(name = "created_by_label", length = 120)
    public String createdByLabel;

    @Column(name = "activated_at")
    public Instant activatedAt;
}
