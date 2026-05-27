package at.htl.admin.entity.recipe;

import at.htl.admin.entity.RecordStatus;
import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;

@Entity
@Table(name = "units")
public class RecipeUnitEntity extends PanacheEntityBase {

    @Id
    @Column(length = 20, nullable = false)
    public String code;

    @Column(name = "display_name", length = 60, nullable = false)
    public String displayName;

    @Column(name = "unit_kind", length = 20, nullable = false)
    public String unitKind;

    @Column(name = "gram_factor")
    public BigDecimal gramFactor;

    @Column(name = "milliliter_factor")
    public BigDecimal milliliterFactor;

    @Enumerated(EnumType.STRING)
    @Column(length = 20, nullable = false)
    public RecordStatus status = RecordStatus.ACTIVE;
}
