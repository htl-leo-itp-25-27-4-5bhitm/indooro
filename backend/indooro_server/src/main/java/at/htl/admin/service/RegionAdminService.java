package at.htl.admin.service;

import at.htl.admin.dto.RegionDtos;
import at.htl.admin.entity.RecordStatus;
import at.htl.admin.entity.RegionEntity;
import at.htl.admin.repository.RegionRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;

import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class RegionAdminService {

    @Inject
    RegionRepository regionRepository;

    @Inject
    AuditLogService auditLogService;

    public List<RegionDtos.RegionResponse> listRegions(RecordStatus status) {
        RecordStatus effectiveStatus = status == null ? RecordStatus.ACTIVE : status;
        return regionRepository.find("status", effectiveStatus)
                .list()
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public RegionDtos.RegionResponse getRegion(UUID regionId) {
        return toResponse(requireRegion(regionId));
    }

    @Transactional
    public RegionDtos.RegionResponse createRegion(RegionDtos.RegionUpsertRequest request) {
        String normalizedCode = request.code().trim();
        regionRepository.findByCode(normalizedCode).ifPresent(existing -> {
            throw conflict("Eine Region mit diesem Code existiert bereits.");
        });

        RegionEntity region = new RegionEntity();
        region.code = normalizedCode;
        region.name = request.name().trim();
        region.description = trimToNull(request.description());
        region.status = RecordStatus.ACTIVE;
        regionRepository.persist(region);

        RegionDtos.RegionResponse response = toResponse(region);
        auditLogService.log("REGION", region.id, "CREATE", "Region angelegt", null, response);
        return response;
    }

    @Transactional
    public RegionDtos.RegionResponse updateRegion(UUID regionId, RegionDtos.RegionUpsertRequest request) {
        RegionEntity region = requireRegion(regionId);
        RegionDtos.RegionResponse before = toResponse(region);

        String normalizedCode = request.code().trim();
        regionRepository.findByCode(normalizedCode)
                .filter(existing -> !existing.id.equals(regionId))
                .ifPresent(existing -> {
                    throw conflict("Eine Region mit diesem Code existiert bereits.");
                });

        region.code = normalizedCode;
        region.name = request.name().trim();
        region.description = trimToNull(request.description());

        RegionDtos.RegionResponse after = toResponse(region);
        auditLogService.log("REGION", region.id, "UPDATE", "Region aktualisiert", before, after);
        return after;
    }

    @Transactional
    public RegionDtos.RegionResponse archiveRegion(UUID regionId) {
        RegionEntity region = requireRegion(regionId);
        RegionDtos.RegionResponse before = toResponse(region);
        region.status = RecordStatus.ARCHIVED;
        RegionDtos.RegionResponse after = toResponse(region);
        auditLogService.log("REGION", region.id, "ARCHIVE", "Region archiviert", before, after);
        return after;
    }

    private RegionEntity requireRegion(UUID regionId) {
        return regionRepository.findByIdOptional(regionId)
                .orElseThrow(() -> new NotFoundException("Region nicht gefunden."));
    }

    private RegionDtos.RegionResponse toResponse(RegionEntity entity) {
        return new RegionDtos.RegionResponse(
                entity.id,
                entity.code,
                entity.name,
                entity.description,
                entity.status.name(),
                entity.createdAt,
                entity.updatedAt
        );
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private WebApplicationException conflict(String message) {
        return new WebApplicationException(message, Response.Status.CONFLICT);
    }
}
