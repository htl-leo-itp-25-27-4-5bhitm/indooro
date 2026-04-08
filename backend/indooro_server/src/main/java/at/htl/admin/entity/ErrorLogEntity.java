package at.htl.admin.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "error_logs")
public class ErrorLogEntity extends AuditableEntity {

    @Column(name = "status_code", nullable = false)
    public int statusCode;

    @Column(length = 16)
    public String method;

    @Column(nullable = false, length = 300)
    public String path;

    @Column(columnDefinition = "TEXT")
    public String message;

    @Column(name = "error_type", length = 200)
    public String errorType;

    @Column(name = "stack_trace", columnDefinition = "TEXT")
    public String stackTrace;
}
