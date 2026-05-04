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

import java.util.HashSet;
import java.util.List;
import java.util.Set;
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

    public MobileDtos.StoreByBeaconResponse findStoreByBeacon(String uuid, Integer major, Integer minor) {
        if (uuid == null || uuid.isBlank()) {
            throw new WebApplicationException("Beacon UUID ist erforderlich.", Response.Status.BAD_REQUEST);
        }
        if ((major == null) != (minor == null)) {
            throw new WebApplicationException("Major und Minor muessen entweder beide gesetzt oder beide leer sein.", Response.Status.BAD_REQUEST);
        }

        BeaconEntity beacon = resolveBeacon(uuid, major, minor);
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

    private BeaconEntity resolveBeacon(String uuid, Integer major, Integer minor) {
        String normalizedUuid;
        try {
            normalizedUuid = BeaconIdentityUtil.normalizeUuid(uuid);
        } catch (IllegalArgumentException e) {
            throw new WebApplicationException("Beacon UUID muss 32 hexadezimale Zeichen enthalten.", Response.Status.BAD_REQUEST);
        }

        if (major != null && minor != null) {
            String exactIdentityKey = BeaconIdentityUtil.toIdentityKey(normalizedUuid, major, minor);
            BeaconEntity exactMatch = beaconRepository.findByIdentityKey(exactIdentityKey).orElse(null);
            if (exactMatch != null && exactMatch.status == RecordStatus.ACTIVE) {
                return exactMatch;
            }
        }

        List<BeaconEntity> uuidMatches = beaconRepository.listActiveByUuid(normalizedUuid);
        if (uuidMatches.isEmpty()) {
            throw new NotFoundException("Kein passender Beacon gefunden.");
        }

        if (uuidMatches.size() == 1) {
            return uuidMatches.get(0);
        }

        List<BeaconAssignmentEntity> activeAssignments = uuidMatches.stream()
                .map(beacon -> beaconAssignmentRepository.findActiveByBeaconId(beacon.id).orElse(null))
                .filter(assignment -> assignment != null && assignment.store.status == RecordStatus.ACTIVE)
                .toList();

        if (activeAssignments.size() == 1) {
            return activeAssignments.get(0).beacon;
        }

        Set<UUID> distinctStoreIds = new HashSet<>();
        for (BeaconAssignmentEntity assignment : activeAssignments) {
            distinctStoreIds.add(assignment.store.id);
        }

        if (distinctStoreIds.size() == 1 && !activeAssignments.isEmpty()) {
            return activeAssignments.get(0).beacon;
        }

        throw new WebApplicationException(
                "Mehrere aktive Beacons mit dieser UUID gefunden. Bitte UUID, Major und Minor mitsenden.",
                Response.Status.CONFLICT
        );
    }

    private MobileDtos.MobileStoreSummary toStoreSummary(StoreEntity store) {
        return new MobileDtos.MobileStoreSummary(store.id, store.storeCode, store.name, store.city);
    }
}
