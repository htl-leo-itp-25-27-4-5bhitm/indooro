package at.htl.resource.mobile;

import at.htl.admin.dto.MobileDtos;
import at.htl.admin.service.MobileStoreService;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;

import java.util.List;
import java.util.UUID;

@Path("/api/mobile/stores")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class MobileStoreResource {

    @Inject
    MobileStoreService mobileStoreService;

    @GET
    public List<MobileDtos.MobileStoreSummary> listStores() {
        return mobileStoreService.listStores();
    }

    @GET
    @Path("/by-beacon")
    public MobileDtos.StoreByBeaconResponse findStoreByBeacon(@QueryParam("uuid") String uuid) {
        return mobileStoreService.findStoreByBeacon(uuid);
    }

    @GET
    @Path("/{storeId}/layout/current")
    public MobileDtos.MobileLayoutResponse getCurrentLayout(@PathParam("storeId") UUID storeId) {
        return mobileStoreService.getCurrentLayout(storeId);
    }
}
