package at.htl.admin.service;

import at.htl.admin.dto.MobileDtos;
import at.htl.admin.dto.LayoutDtos;
import at.htl.admin.entity.BeaconAssignmentEntity;
import at.htl.admin.entity.BeaconEntity;
import at.htl.admin.entity.RecordStatus;
import at.htl.admin.entity.StoreEntity;
import at.htl.admin.repository.BeaconAssignmentRepository;
import at.htl.admin.repository.BeaconRepository;
import at.htl.admin.repository.StoreRepository;
import at.htl.admin.util.BeaconIdentityUtil;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;

import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class MobileStoreService {

    @Inject
    BeaconRepository beaconRepository;

    @Inject
    BeaconAssignmentRepository beaconAssignmentRepository;

    @Inject
    StoreRepository storeRepository;

    @Inject
    StoreLayoutAdminService storeLayoutAdminService;

    public List<MobileDtos.MobileStoreSummary> listStores() {
        return storeRepository.find("status = ?1 order by name", RecordStatus.ACTIVE)
                .list()
                .stream()
                .map(this::toStoreSummary)
                .toList();
    }

    public MobileDtos.StoreByBeaconResponse findStoreByBeacon(String uuid) {
        if (uuid == null || uuid.isBlank()) {
            throw new WebApplicationException("Beacon UUID ist erforderlich.", Response.Status.BAD_REQUEST);
        }

        BeaconEntity beacon = resolveBeacon(uuid);
        BeaconAssignmentEntity assignment = beaconAssignmentRepository.findActiveByBeaconId(beacon.id)
                .orElseThrow(() -> new NotFoundException("Keiner aktiven Filiale ist dieser Beacon zugeordnet."));

        if (assignment.store.status != RecordStatus.ACTIVE) {
            throw new NotFoundException("Die zugeordnete Filiale ist nicht aktiv.");
        }

        return new MobileDtos.StoreByBeaconResponse(
                toStoreSummary(assignment.store),
                new MobileDtos.MatchedBeaconSummary(beacon.id, beacon.beaconCode, beacon.identityKey)
        );
    }

    public MobileDtos.MobileLayoutResponse getCurrentLayout(UUID storeId) {
        StoreEntity store = storeRepository.findByIdOptional(storeId)
                .orElseThrow(() -> new NotFoundException("Filiale nicht gefunden."));
        if (store.status != RecordStatus.ACTIVE) {
            throw new NotFoundException("Filiale ist nicht aktiv.");
        }

        LayoutDtos.StoreLayoutResponse layout = storeLayoutAdminService.getCurrentLayout(storeId);
        return new MobileDtos.MobileLayoutResponse(store.id, layout.layoutId(), layout.layout());
    }

    private BeaconEntity resolveBeacon(String uuid) {
        String normalizedUuid;
        try {
            normalizedUuid = BeaconIdentityUtil.normalizeUuid(uuid);
        } catch (IllegalArgumentException e) {
            throw new WebApplicationException("Beacon UUID muss 32 hexadezimale Zeichen enthalten.", Response.Status.BAD_REQUEST);
        }

        String uuidOnlyIdentityKey = BeaconIdentityUtil.toIdentityKey(normalizedUuid, null, null);
        return beaconRepository.findByIdentityKey(uuidOnlyIdentityKey)
                .filter(beacon -> beacon.status == RecordStatus.ACTIVE)
                .orElseThrow(() -> new NotFoundException("Kein passender Beacon gefunden."));
    }

    private MobileDtos.MobileStoreSummary toStoreSummary(StoreEntity store) {
        return new MobileDtos.MobileStoreSummary(store.id, store.storeCode, store.name, store.city);
    }
}
