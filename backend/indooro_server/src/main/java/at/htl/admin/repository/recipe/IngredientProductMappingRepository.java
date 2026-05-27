package at.htl.admin.repository.recipe;

import at.htl.admin.entity.RecordStatus;
import at.htl.admin.entity.recipe.IngredientProductMappingEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class IngredientProductMappingRepository implements PanacheRepositoryBase<IngredientProductMappingEntity, UUID> {

    public List<IngredientProductMappingEntity> listActiveByIngredient(UUID ingredientId) {
        return list("recipeIngredient.id = ?1 and status = ?2 order by manuallyConfirmed desc, confidence desc nulls last",
                ingredientId,
                RecordStatus.ACTIVE);
    }

    public Optional<IngredientProductMappingEntity> findActiveByIngredientAndProduct(UUID ingredientId, Integer productId, UUID storeId) {
        if (storeId == null) {
            return find("recipeIngredient.id = ?1 and productId = ?2 and store is null and status = ?3",
                    ingredientId,
                    productId,
                    RecordStatus.ACTIVE).firstResultOptional();
        }
        return find("recipeIngredient.id = ?1 and productId = ?2 and store.id = ?3 and status = ?4",
                ingredientId,
                productId,
                storeId,
                RecordStatus.ACTIVE).firstResultOptional();
    }
}
