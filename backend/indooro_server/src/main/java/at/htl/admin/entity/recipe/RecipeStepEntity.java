package at.htl.admin.entity.recipe;

import at.htl.admin.entity.AuditableEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "recipe_steps")
public class RecipeStepEntity extends AuditableEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "recipe_id", nullable = false)
    public RecipeEntity recipe;

    @Column(nullable = false)
    public Integer position;

    @Column(nullable = false, columnDefinition = "TEXT")
    public String instruction;

    @Column(name = "duration_minutes")
    public Integer durationMinutes;
}
