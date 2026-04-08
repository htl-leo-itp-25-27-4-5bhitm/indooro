package at.htl.admin.dto;

import java.util.List;

public final class CommonDtos {

    private CommonDtos() {
    }

    public record PageResponse<T>(List<T> content, int page, int size, long totalElements) {
    }
}
