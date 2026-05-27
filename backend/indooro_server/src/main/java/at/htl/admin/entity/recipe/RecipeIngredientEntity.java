package at.htl.admin.entity.recipe;

import at.htl.admin.entity.AuditableEntity;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "recipe_ingredients")
public class RecipeIngredientEntity extends AuditableEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "recipe_id", nullable = false)
    public RecipeEntity recipe;

    @Column(nullable = false)
    public Integer position;

    @Column(name = "display_name", nullable = false, length = 180)
    public String displayName;

    @Column(name = "canonical_name", length = 180)
    public String canonicalName;

    @Column(precision = 12, scale = 3)
    public BigDecimal quantity;

    @Column(name = "quantity_text", length = 80)
    public String quantityText;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "unit_code")
    public RecipeUnitEntity unit;

    @Column(name = "preparation_note", columnDefinition = "TEXT")
    public String preparationNote;

    @Column(name = "is_optional", nullable = false)
    public boolean optional = false;

    @OneToMany(mappedBy = "recipeIngredient", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    public List<IngredientProductMappingEntity> mappings = new ArrayList<>();
}
