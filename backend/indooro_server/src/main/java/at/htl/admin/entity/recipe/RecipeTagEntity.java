package at.htl.admin.entity.recipe;

import at.htl.admin.entity.AuditableEntity;
import at.htl.admin.entity.RecordStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;

@Entity
@Table(name = "recipe_tags")
public class RecipeTagEntity extends AuditableEntity {

    @Column(nullable = false, unique = true, length = 80)
    public String code;

    @Column(nullable = false, length = 120)
    public String name;

    @Column(length = 40)
    public String kind;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    public RecordStatus status = RecordStatus.ACTIVE;
}
