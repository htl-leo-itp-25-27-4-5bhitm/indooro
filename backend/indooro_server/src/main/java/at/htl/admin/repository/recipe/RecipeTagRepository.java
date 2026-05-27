package at.htl.admin.repository.recipe;

import at.htl.admin.entity.RecordStatus;
import at.htl.admin.entity.recipe.RecipeTagEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class RecipeTagRepository implements PanacheRepositoryBase<RecipeTagEntity, UUID> {

    public Optional<RecipeTagEntity> findByCode(String code) {
        return find("lower(code) = ?1", code.toLowerCase()).firstResultOptional();
    }

    public List<RecipeTagEntity> listActive() {
        return list("status = ?1 order by name", RecordStatus.ACTIVE);
    }
}
