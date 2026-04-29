package at.htl.admin.dto;

import java.util.UUID;

public final class AdminUserDtos {

    private AdminUserDtos() {
    }

    public record CurrentUserResponse(
            String subject,
            String username,
            String email,
            String role,
            ScopeResponse scope
    ) {
    }

    public record ScopeResponse(
            UUID regionId,
            String regionName,
            UUID storeId,
            String storeName
    ) {
    }
}
