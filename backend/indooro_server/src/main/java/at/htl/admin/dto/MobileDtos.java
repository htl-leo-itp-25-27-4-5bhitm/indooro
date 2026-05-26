package at.htl.admin.dto;

import com.fasterxml.jackson.databind.JsonNode;

import java.util.List;
import java.util.UUID;

public final class MobileDtos {

    private MobileDtos() {
    }

    public record MobileStoreSummary(
            UUID id,
            String storeCode,
            String name,
            String city,
            String address,
            Double latitude,
            Double longitude
    ) {
    }

    public record BeaconIdentitiesResponse(
            List<String> uuids
    ) {
    }

    public record MatchedBeaconSummary(
            UUID beaconId,
            String beaconCode,
            String identityKey
    ) {
    }

    public record StoreByBeaconResponse(
            MobileStoreSummary store,
            MatchedBeaconSummary matchedBeacon
    ) {
    }

    public record MobileLayoutResponse(
            UUID storeId,
            UUID layoutId,
            String source,
            boolean fallback,
            JsonNode layout
    ) {
    }
}
