package at.htl.admin.entity.recipe;

import at.htl.admin.entity.AuditableEntity;
import at.htl.admin.entity.RecordStatus;
import at.htl.admin.entity.StoreEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.math.BigDecimal;

@Entity
@Table(name = "ingredient_product_mappings")
public class IngredientProductMappingEntity extends AuditableEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_ingredient_id")
    public RecipeIngredientEntity recipeIngredient;

    @Column(name = "canonical_name", length = 180)
    public String canonicalName;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "store_id")
    public StoreEntity store;

    @Column(name = "store_code", length = 50)
    public String storeCode;

    @Column(name = "product_id", nullable = false)
    public Integer productId;

    @Column(name = "product_name_snapshot", length = 240)
    public String productNameSnapshot;

    @Column(name = "layout_code_snapshot", length = 80)
    public String layoutCodeSnapshot;

    @Enumerated(EnumType.STRING)
    @Column(name = "mapping_type", nullable = false, length = 30)
    public RecipeMappingType mappingType = RecipeMappingType.MANUAL;

    @Column(precision = 4, scale = 3)
    public BigDecimal confidence;

    @Column(name = "manually_confirmed", nullable = false)
    public boolean manuallyConfirmed = false;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    public RecordStatus status = RecordStatus.ACTIVE;
}
