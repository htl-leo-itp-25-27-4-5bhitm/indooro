package at.htl.admin.repository.recipe;

import at.htl.admin.entity.recipe.RecipeStepEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class RecipeStepRepository implements PanacheRepositoryBase<RecipeStepEntity, UUID> {

    public List<RecipeStepEntity> listByRecipe(UUID recipeId) {
        return list("recipe.id = ?1 order by position", recipeId);
    }
}
