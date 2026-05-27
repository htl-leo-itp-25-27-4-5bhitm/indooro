package at.htl.admin.entity.recipe;

import at.htl.admin.entity.AuditableEntity;
import at.htl.admin.entity.RecordStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;

@Entity
@Table(name = "ingredient_synonyms")
public class IngredientSynonymEntity extends AuditableEntity {

    @Column(name = "canonical_name", nullable = false, length = 180)
    public String canonicalName;

    @Column(nullable = false, length = 180)
    public String synonym;

    @Column(nullable = false, length = 12)
    public String locale;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    public RecordStatus status = RecordStatus.ACTIVE;
}
