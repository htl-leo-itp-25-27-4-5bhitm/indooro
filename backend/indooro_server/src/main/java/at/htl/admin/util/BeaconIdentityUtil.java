package at.htl.admin.util;

import java.util.Locale;

public final class BeaconIdentityUtil {

    private BeaconIdentityUtil() {
    }

    public static String normalizeUuid(String uuid) {
        if (uuid == null) {
            throw new IllegalArgumentException("Beacon UUID is required");
        }

        String normalized = uuid.trim().replace("-", "").toLowerCase(Locale.ROOT);
        if (!normalized.matches("[0-9a-f]{32}")) {
            throw new IllegalArgumentException("Beacon UUID must contain exactly 32 hexadecimal characters.");
        }
        return normalized;
    }

    public static String toIdentityKey(String uuid, Integer major, Integer minor) {
        String normalizedUuid = normalizeUuid(uuid);

        if (major != null && minor != null) {
            return normalizedUuid + ":" + major + ":" + minor;
        }

        return normalizedUuid;
    }
}
