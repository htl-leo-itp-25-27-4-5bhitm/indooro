package at.htl.admin.repository.recipe;

import at.htl.admin.entity.recipe.RecipeIngredientEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class RecipeIngredientRepository implements PanacheRepositoryBase<RecipeIngredientEntity, UUID> {

    public List<RecipeIngredientEntity> listByRecipe(UUID recipeId) {
        return list("recipe.id = ?1 order by position", recipeId);
    }
}
