package io.github.leexeo.cage.privacy;

import android.net.LinkProperties;
import android.os.Parcel;

/** Creates a presentation-only copy; never changes a network or the service's object. */
public final class LinkPropertiesPrivacy {
    private LinkPropertiesPrivacy() {}

    public static LinkProperties copyForGuest(LinkProperties original, boolean tunnel) {
        if (original == null) return null;
        // Nulling only interfaceName retains the tunnel's addresses, DNS servers,
        // route gateways, proxy, domains and stacked links. An empty presentation
        // avoids carrying any of that host VPN configuration into the guest.
        // The Network handle and real ConnectivityService configuration are untouched.
        if (tunnel) return new LinkProperties();
        Parcel parcel = Parcel.obtain();
        try {
            original.writeToParcel(parcel, 0);
            parcel.setDataPosition(0);
            return LinkProperties.CREATOR.createFromParcel(parcel);
        } finally {
            parcel.recycle();
        }
    }
}
