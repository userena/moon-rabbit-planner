# Services and data

Reviewed 2026-09-12. The application has no third-party Swift package dependencies.
It uses Apple system frameworks and system fonts; Apple fonts are not bundled.

## Weather

Weather data: [Open-Meteo](https://open-meteo.com/), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
The app formats current values and translates weather-code labels.
[Data licence](https://open-meteo.com/en/licence).

The default hosted API is for **non-commercial use**, within its published
limits (under 600 requests/minute, 5,000/hour and 10,000/day; see current terms).
An advertisement-free, subscription-free personal/non-profit distribution is
compatible with the examples in the terms. Code licensing does not override
service restrictions. Commercial forks must arrange an appropriate service,
paid plan or self-hosting. No payment account or API key is bundled, and this
app cannot automatically upgrade to a paid plan.
[Service terms and privacy](https://open-meteo.com/en/terms).

## Place lookup

Neighborhood lookup: [Photon](https://github.com/komoot/photon), using
[© OpenStreetMap contributors](https://www.openstreetmap.org/copyright).
The public Photon demo permits reasonable request volumes, may throttle or
block heavy use, and offers no availability guarantee. Large deployments
should use their own instance or an appropriately licensed provider.

Fallback city lookup: Open-Meteo geocoding, based on
[GeoNames](https://www.geonames.org/), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
The app displays selected location names and coordinates, not a bundled map database.
