package at.htl.admin.util;

import java.util.UUID;

public final class BeaconIdentityUtil {

    private BeaconIdentityUtil() {
    }

    public static String toIdentityKey(UUID uuid, Integer major, Integer minor) {
        if (uuid == null) {
            throw new IllegalArgumentException("Beacon UUID is required");
        }

        if (major != null && minor != null) {
            return uuid + ":" + major + ":" + minor;
        }

        return uuid.toString();
    }
}
