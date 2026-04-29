package at.htl.admin.service;

import jakarta.ws.rs.ForbiddenException;

public enum AdminRole {
    ADMIN("admin"),
    REGION_MANAGER("region-manager"),
    STORE_MANAGER("store-manager");

    private final String value;

    AdminRole(String value) {
        this.value = value;
    }

    public String value() {
        return value;
    }

    public static AdminRole fromValue(String value) {
        for (AdminRole role : values()) {
            if (role.value.equals(value)) {
                return role;
            }
        }
        throw new ForbiddenException("Unbekannte Indooro Admin-Rolle.");
    }
}
