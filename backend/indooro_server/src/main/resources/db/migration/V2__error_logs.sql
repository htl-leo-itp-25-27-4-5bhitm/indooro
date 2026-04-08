CREATE TABLE error_logs (
    id UUID PRIMARY KEY,
    status_code INTEGER NOT NULL,
    method VARCHAR(16),
    path VARCHAR(300) NOT NULL,
    message TEXT,
    error_type VARCHAR(200),
    stack_trace TEXT,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_error_logs_created_at ON error_logs(created_at DESC);
CREATE INDEX idx_error_logs_status_code ON error_logs(status_code, created_at DESC);
