package at.htl.admin.repository.recipe;

import at.htl.admin.entity.recipe.IngredientSynonymEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.UUID;

@ApplicationScoped
public class IngredientSynonymRepository implements PanacheRepositoryBase<IngredientSynonymEntity, UUID> {
}
