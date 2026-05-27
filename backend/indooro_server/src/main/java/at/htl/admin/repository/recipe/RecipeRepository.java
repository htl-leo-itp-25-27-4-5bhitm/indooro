package at.htl.admin.repository.recipe;

import at.htl.admin.entity.recipe.RecipeEntity;
import at.htl.admin.entity.recipe.RecipeStatus;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class RecipeRepository implements PanacheRepositoryBase<RecipeEntity, UUID> {

    public Optional<RecipeEntity> findBySlug(String slug) {
        return find("lower(slug) = ?1", slug.toLowerCase()).firstResultOptional();
    }

    public Optional<RecipeEntity> findPublishedById(UUID recipeId) {
        return find("id = ?1 and status = ?2", recipeId, RecipeStatus.PUBLISHED).firstResultOptional();
    }
}
