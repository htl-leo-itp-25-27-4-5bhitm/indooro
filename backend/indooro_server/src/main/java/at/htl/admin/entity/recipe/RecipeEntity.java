package at.htl.admin.entity.recipe;

import at.htl.admin.entity.AuditableEntity;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "recipes")
public class RecipeEntity extends AuditableEntity {

    @Column(nullable = false, unique = true, length = 140)
    public String slug;

    @Column(nullable = false, length = 180)
    public String title;

    @Column(columnDefinition = "TEXT")
    public String summary;

    @Column(columnDefinition = "TEXT")
    public String description;

    @Column(name = "image_url", columnDefinition = "TEXT")
    public String imageUrl;

    @Column(name = "image_alt", length = 240)
    public String imageAlt;

    @Column(nullable = false)
    public Integer servings = 1;

    @Column(name = "prep_time_minutes")
    public Integer prepTimeMinutes;

    @Column(name = "cook_time_minutes")
    public Integer cookTimeMinutes;

    @Column(name = "total_time_minutes")
    public Integer totalTimeMinutes;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    public RecipeStatus status = RecipeStatus.DRAFT;

    @Column(name = "published_at")
    public Instant publishedAt;

    @Column(name = "archived_at")
    public Instant archivedAt;

    @Column(name = "created_by_role", length = 40)
    public String createdByRole;

    @Column(name = "created_by_label", length = 120)
    public String createdByLabel;

    @OneToMany(mappedBy = "recipe", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    public List<RecipeIngredientEntity> ingredients = new ArrayList<>();

    @OneToMany(mappedBy = "recipe", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    public List<RecipeStepEntity> steps = new ArrayList<>();

    @OneToMany(mappedBy = "recipe", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    public List<RecipeTagAssignmentEntity> tagAssignments = new ArrayList<>();
}
