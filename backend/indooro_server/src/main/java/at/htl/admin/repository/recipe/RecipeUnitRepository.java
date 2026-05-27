package at.htl.admin.repository.recipe;

import at.htl.admin.entity.recipe.RecipeUnitEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class RecipeUnitRepository implements PanacheRepositoryBase<RecipeUnitEntity, String> {
}
