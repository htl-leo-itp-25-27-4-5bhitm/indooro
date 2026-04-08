package at.htl.admin.service;

import at.htl.admin.entity.AuditLogEntity;
import at.htl.admin.repository.AuditLogRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import java.util.UUID;

@ApplicationScoped
public class AuditLogService {

    @Inject
    AuditLogRepository auditLogRepository;

    @Inject
    ObjectMapper objectMapper;

    @Transactional
    public void log(String entityType,
                    UUID entityId,
                    String action,
                    String summary,
                    Object before,
                    Object after) {
        AuditLogEntity entry = new AuditLogEntity();
        entry.entityType = entityType;
        entry.entityId = entityId;
        entry.action = action;
        entry.actorRole = "SYSTEM";
        entry.actorLabel = "system";
        entry.summary = summary;
        entry.beforeJson = toJson(before);
        entry.afterJson = toJson(after);
        auditLogRepository.persist(entry);
    }

    private JsonNode toJson(Object value) {
        if (value == null) {
            return null;
        }
        return objectMapper.valueToTree(value);
    }
}
