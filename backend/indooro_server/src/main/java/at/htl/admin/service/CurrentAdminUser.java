package at.htl.admin.service;

import at.htl.admin.entity.UserAccessAssignmentEntity;

public record CurrentAdminUser(
        String subject,
        String username,
        String email,
        AdminRole role,
        UserAccessAssignmentEntity assignment
) {
}
