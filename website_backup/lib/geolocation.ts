/**
 * OpenStreetMap Nominatim Geocoding & Reverse Geocoding utility
 * Free, client-safe geocoding for Indian addresses, pincodes, and GPS coordinates
 */

export interface GeocodeResult {
  latitude: number;
  longitude: number;
  displayName?: string;
}

export interface ReverseGeocodeResult {
  latitude: number;
  longitude: number;
  line1: string;
  line2: string;
  city: string;
  state: string;
  pincode: string;
  displayName: string;
}

export interface PopularArea {
  name: string;
  area: string;
  city: string;
  state: string;
  pincode: string;
  latitude: number;
  longitude: number;
}

export const PUNE_POPULAR_AREAS: PopularArea[] = [
  {
    name: "Shivajinagar / FC Road",
    area: "Shivajinagar",
    city: "Pune",
    state: "Maharashtra",
    pincode: "411005",
    latitude: 18.5314,
    longitude: 73.8446,
  },
  {
    name: "Kothrud / Paud Road",
    area: "Kothrud",
    city: "Pune",
    state: "Maharashtra",
    pincode: "411038",
    latitude: 18.5074,
    longitude: 73.8077,
  },
  {
    name: "Viman Nagar / Airport Rd",
    area: "Viman Nagar",
    city: "Pune",
    state: "Maharashtra",
    pincode: "411014",
    latitude: 18.5679,
    longitude: 73.9143,
  },
  {
    name: "Baner / Balewadi",
    area: "Baner",
    city: "Pune",
    state: "Maharashtra",
    pincode: "411045",
    latitude: 18.5590,
    longitude: 73.7868,
  },
  {
    name: "Wakad / Hinjawadi",
    area: "Wakad",
    city: "Pune",
    state: "Maharashtra",
    pincode: "411057",
    latitude: 18.5987,
    longitude: 73.7684,
  },
  {
    name: "Aundh / University Road",
    area: "Aundh",
    city: "Pune",
    state: "Maharashtra",
    pincode: "411007",
    latitude: 18.5580,
    longitude: 73.8070,
  },
  {
    name: "Kalyani Nagar / KP",
    area: "Kalyani Nagar",
    city: "Pune",
    state: "Maharashtra",
    pincode: "411006",
    latitude: 18.5463,
    longitude: 73.9033,
  },
  {
    name: "Hadapsar / Magarpatta",
    area: "Hadapsar",
    city: "Pune",
    state: "Maharashtra",
    pincode: "411028",
    latitude: 18.5089,
    longitude: 73.9260,
  },
];

export async function geocodeAddress(query: {
  line1?: string;
  area?: string;
  city?: string;
  state?: string;
  pincode?: string;
}): Promise<GeocodeResult> {
  try {
    const parts = [query.line1, query.area, query.city, query.pincode, 'India']
      .filter(Boolean)
      .join(', ');

    const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(
      parts
    )}&limit=1`;

    const res = await fetch(url, {
      headers: {
        'Accept-Language': 'en',
      },
    });

    if (!res.ok) {
      return getFallbackCoords();
    }

    const data = await res.json();
    if (data && data.length > 0) {
      return {
        latitude: parseFloat(data[0].lat),
        longitude: parseFloat(data[0].lon),
        displayName: data[0].display_name,
      };
    }

    // Fallback: try just pincode + India
    if (query.pincode) {
      const pinUrl = `https://nominatim.openstreetmap.org/search?format=json&postalcode=${encodeURIComponent(
        query.pincode
      )}&country=India&limit=1`;
      const pinRes = await fetch(pinUrl);
      if (pinRes.ok) {
        const pinData = await pinRes.json();
        if (pinData && pinData.length > 0) {
          return {
            latitude: parseFloat(pinData[0].lat),
            longitude: parseFloat(pinData[0].lon),
            displayName: pinData[0].display_name,
          };
        }
      }
    }

    return getFallbackCoords();
  } catch (err) {
    console.warn('[geocodeAddress] error:', err);
    return getFallbackCoords();
  }
}

/**
 * Reverse geocode GPS coordinates to a structured Indian postal address
 */
export async function reverseGeocode(
  latitude: number,
  longitude: number
): Promise<ReverseGeocodeResult> {
  try {
    const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&zoom=18&addressdetails=1`;
    const res = await fetch(url, {
      headers: {
        'Accept-Language': 'en',
      },
    });

    if (res.ok) {
      const data = await res.json();
      if (data && data.address) {
        const addr = data.address;
        
        const road = addr.road || addr.pedestrian || addr.suburb || '';
        const area = addr.suburb || addr.neighbourhood || addr.residential || addr.city_district || '';
        const city = addr.city || addr.town || addr.village || addr.county || 'Pune';
        const state = addr.state || 'Maharashtra';
        const pincode = addr.postcode || '411001';

        const line1 = road ? (area && area !== road ? `${road}, ${area}` : road) : (area || data.display_name.split(',')[0]);
        const line2 = area && line1 !== area ? area : '';

        return {
          latitude,
          longitude,
          line1: line1 || 'Nearby Location',
          line2: line2 || undefined as any,
          city,
          state,
          pincode,
          displayName: data.display_name || `${line1}, ${city}`,
        };
      }
    }
  } catch (err) {
    console.warn('[reverseGeocode] error:', err);
  }

  // Find nearest Pune neighborhood fallback
  const nearest = findNearestPuneArea(latitude, longitude);
  return {
    latitude,
    longitude,
    line1: nearest.area,
    line2: nearest.name,
    city: nearest.city,
    state: nearest.state,
    pincode: nearest.pincode,
    displayName: `${nearest.name}, ${nearest.city}, ${nearest.state} ${nearest.pincode}`,
  };
}

/**
 * Request real device GPS coordinates with robust error handling and reverse geocoding
 */
export async function getCurrentDeviceLocation(): Promise<{
  success: boolean;
  data?: ReverseGeocodeResult;
  error?: string;
}> {
  if (typeof window === 'undefined' || !('geolocation' in navigator)) {
    return {
      success: false,
      error: 'Geolocation is not supported by your browser.',
    };
  }

  return new Promise((resolve) => {
    // First attempt with standard accuracy to avoid timeouts on laptops / WiFi
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        try {
          const lat = pos.coords.latitude;
          const lon = pos.coords.longitude;
          const address = await reverseGeocode(lat, lon);
          resolve({
            success: true,
            data: address,
          });
        } catch {
          resolve({
            success: true,
            data: {
              latitude: pos.coords.latitude,
              longitude: pos.coords.longitude,
              line1: 'Detected GPS Location',
              line2: 'Pune Area',
              city: 'Pune',
              state: 'Maharashtra',
              pincode: '411001',
              displayName: 'Detected GPS Location, Pune',
            },
          });
        }
      },
      (err) => {
        let msg = 'Unable to retrieve your location.';
        if (err.code === 1) {
          msg = 'Location permission was denied. Please allow location access in your browser or select your area below.';
        } else if (err.code === 2) {
          msg = 'Location information is currently unavailable. Please pick your area below.';
        } else if (err.code === 3) {
          msg = 'Location request timed out. Please try again or select your area below.';
        }
        resolve({
          success: false,
          error: msg,
        });
      },
      {
        enableHighAccuracy: false,
        timeout: 10000,
        maximumAge: 60000,
      }
    );
  });
}

function findNearestPuneArea(lat: number, lon: number): PopularArea {
  let minDistance = Infinity;
  let closest = PUNE_POPULAR_AREAS[0];

  for (const area of PUNE_POPULAR_AREAS) {
    const dLat = area.latitude - lat;
    const dLon = area.longitude - lon;
    const dist = dLat * dLat + dLon * dLon;
    if (dist < minDistance) {
      minDistance = dist;
      closest = area;
    }
  }

  return closest;
}

function getFallbackCoords(): GeocodeResult {
  return {
    latitude: 18.5204,
    longitude: 73.8567,
  };
}
