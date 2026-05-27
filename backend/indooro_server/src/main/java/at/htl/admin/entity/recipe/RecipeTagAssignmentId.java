package at.htl.admin.entity.recipe;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

public class RecipeTagAssignmentId implements Serializable {
    public UUID recipe;
    public UUID tag;

    public RecipeTagAssignmentId() {
    }

    public RecipeTagAssignmentId(UUID recipe, UUID tag) {
        this.recipe = recipe;
        this.tag = tag;
    }

    @Override
    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (!(other instanceof RecipeTagAssignmentId that)) {
            return false;
        }
        return Objects.equals(recipe, that.recipe) && Objects.equals(tag, that.tag);
    }

    @Override
    public int hashCode() {
        return Objects.hash(recipe, tag);
    }
}
