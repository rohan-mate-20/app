"use client";

import React, { useEffect, useRef, useState, useCallback } from "react";
import { 
  MapPin, 
  Navigation, 
  Plus, 
  Minus, 
  Maximize2, 
  Minimize2, 
  RotateCcw,
  CheckCircle2,
  AlertCircle,
  Layers,
  Sparkles
} from "lucide-react";
import { reverseGeocode } from "../lib/geolocation";

// Known Pune K MART store hub
const KMART_STORE = {
  lat: 18.5590,
  lng: 73.7868,
  name: "K MART Superstore • Baner",
  address: "Baner Road, Pune, Maharashtra 411045",
  serviceRadiusKm: 6.0
};


// Calculate Haversine distance in km
function calculateDistanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371; // Radius of earth in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Number((R * c).toFixed(2));
}

export interface DeliveryLocationData {
  lat: number;
  lng: number;
  area: string;
  pincode: string;
  city: string;
  distanceKm: number;
  isDeliverable: boolean;
}

export interface DeliveryMapProps {
  initialLat?: number;
  initialLng?: number;
  height?: string;
  showStorePin?: boolean;
  showRadius?: boolean;
  showRoute?: boolean;
  showAreaChips?: boolean;
  interactive?: boolean;
  onLocationSelect?: (location: DeliveryLocationData) => void;
  className?: string;
}

export const DeliveryMap: React.FC<DeliveryMapProps> = ({
  initialLat = 18.5530,
  initialLng = 73.7920,
  height = "260px",
  showStorePin = true,
  showRadius = true,
  showRoute = true,
  showAreaChips = true,
  interactive = true,
  onLocationSelect,
  className = ""
}) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<any>(null);
  const userMarkerRef = useRef<any>(null);
  const storeMarkerRef = useRef<any>(null);
  const routeLineRef = useRef<any>(null);
  const radiusCircleRef = useRef<any>(null);
  const tileLayerRef = useRef<any>(null);

  const [currentLat, setCurrentLat] = useState(initialLat);
  const [currentLng, setCurrentLng] = useState(initialLng);
  const [distanceKm, setDistanceKm] = useState(
    calculateDistanceKm(KMART_STORE.lat, KMART_STORE.lng, initialLat, initialLng)
  );
  const [detectedArea, setDetectedArea] = useState("Baner / Aundh Link Rd");
  const [detectedPincode, setDetectedPincode] = useState("411045");
  const [isLocating, setIsLocating] = useState(false);
  const [isExpanded, setIsExpanded] = useState(false);
  const [mapStyle, setMapStyle] = useState<"standard" | "satellite">("standard");
  const [isMapReady, setIsMapReady] = useState(false);

  const isDeliverable = distanceKm <= KMART_STORE.serviceRadiusKm;

  // Handle location update callback
  const triggerLocationChange = useCallback(
    (lat: number, lng: number, areaName?: string, pin?: string) => {
      const dist = calculateDistanceKm(KMART_STORE.lat, KMART_STORE.lng, lat, lng);
      setDistanceKm(dist);
      setCurrentLat(lat);
      setCurrentLng(lng);

      const area = areaName || "Selected Map Location";
      const pincode = pin || "411045";

      setDetectedArea(area);
      setDetectedPincode(pincode);

      if (onLocationSelect) {
        onLocationSelect({
          lat,
          lng,
          area,
          pincode,
          city: "Pune",
          distanceKm: dist,
          isDeliverable: dist <= KMART_STORE.serviceRadiusKm
        });
      }
    },
    [onLocationSelect]
  );

  // Load Leaflet library dynamically via CDN
  useEffect(() => {
    let isMounted = true;

    const loadLeaflet = async () => {
      if (typeof window === "undefined") return;

      // Check if Leaflet CSS is loaded
      if (!document.getElementById("leaflet-css")) {
        const link = document.createElement("link");
        link.id = "leaflet-css";
        link.rel = "stylesheet";
        link.href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css";
        link.crossOrigin = "";
        document.head.appendChild(link);
      }

      // Check if Leaflet JS is loaded
      if (!(window as any).L) {
        await new Promise<void>((resolve, reject) => {
          const script = document.createElement("script");
          script.id = "leaflet-js";
          script.src = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js";
          script.crossOrigin = "";
          script.onload = () => resolve();
          script.onerror = (e) => reject(e);
          document.body.appendChild(script);
        }).catch((err) => {
          console.warn("Leaflet script load error:", err);
        });
      }

      if (!isMounted || !mapContainerRef.current) return;

      const L = (window as any).L;
      if (!L) return;

      // Destroy existing map instance if any
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }

      try {
        const map = L.map(mapContainerRef.current, {
          center: [currentLat, currentLng],
          zoom: 14,
          zoomControl: false,
          attributionControl: false
        });

        mapInstanceRef.current = map;

        // Base Tile Layer (OpenStreetMap)
        const tileUrl =
          mapStyle === "satellite"
            ? "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
            : "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";

        tileLayerRef.current = L.tileLayer(tileUrl, {
          maxZoom: 19
        }).addTo(map);

        // Store Pin (Red K MART Badge)
        if (showStorePin) {
          const storeIcon = L.divIcon({
            className: "kmart-store-pin",
            html: `
              <div style="position: relative; display: flex; flex-direction: column; align-items: center; transform: translate(-50%, -100%); pointer-events: auto;">
                <div style="background: #E11A22; color: white; padding: 4px 8px; border-radius: 9999px; font-weight: 900; font-size: 11px; white-space: nowrap; box-shadow: 0 4px 12px rgba(225,26,34,0.45); display: flex; align-items: center; gap: 5px; border: 2px solid white;">
                  <span style="display: inline-block; width: 7px; height: 7px; border-radius: 50%; background: #4ade80;"></span>
                  🏪 K MART Store
                </div>
                <div style="width: 0; height: 0; border-left: 5px solid transparent; border-right: 5px solid transparent; border-top: 7px solid #E11A22;"></div>
              </div>
            `,
            iconSize: [0, 0],
            iconAnchor: [0, 0]
          });

          storeMarkerRef.current = L.marker([KMART_STORE.lat, KMART_STORE.lng], {
            icon: storeIcon
          }).addTo(map);

          storeMarkerRef.current.bindPopup(
            `<strong>${KMART_STORE.name}</strong><br/><small>${KMART_STORE.address}</small>`
          );
        }

        // Delivery Radius Coverage Circle
        if (showRadius) {
          radiusCircleRef.current = L.circle([KMART_STORE.lat, KMART_STORE.lng], {
            color: "#E11A22",
            weight: 1.5,
            fillColor: "#E11A22",
            fillOpacity: 0.08,
            dashArray: "5, 5",
            radius: KMART_STORE.serviceRadiusKm * 1000
          }).addTo(map);
        }

        // User Delivery Marker (Draggable)
        const userIcon = L.divIcon({
          className: "kmart-user-pin",
          html: `
            <div style="position: relative; display: flex; flex-direction: column; align-items: center; transform: translate(-50%, -100%); cursor: grab; pointer-events: auto;">
              <div style="background: #0A2540; color: white; padding: 5px 9px; border-radius: 9999px; font-weight: 800; font-size: 11px; white-space: nowrap; box-shadow: 0 4px 14px rgba(10,37,64,0.45); display: flex; align-items: center; gap: 4px; border: 2px solid white;">
                📍 Deliver Here
              </div>
              <div style="width: 0; height: 0; border-left: 6px solid transparent; border-right: 6px solid transparent; border-top: 8px solid #0A2540;"></div>
            </div>
          `,
          iconSize: [0, 0],
          iconAnchor: [0, 0]
        });

        const userMarker = L.marker([currentLat, currentLng], {
          icon: userIcon,
          draggable: interactive
        }).addTo(map);

        userMarkerRef.current = userMarker;

        // Route Line (Dashed)
        if (showRoute) {
          routeLineRef.current = L.polyline(
            [
              [KMART_STORE.lat, KMART_STORE.lng],
              [currentLat, currentLng]
            ],
            {
              color: "#E11A22",
              weight: 2.5,
              opacity: 0.8,
              dashArray: "6, 8"
            }
          ).addTo(map);
        }

        // Update markers & line on drag
        userMarker.on("dragend", (e: any) => {
          const pos = e.target.getLatLng();
          if (routeLineRef.current) {
            routeLineRef.current.setLatLngs([
              [KMART_STORE.lat, KMART_STORE.lng],
              [pos.lat, pos.lng]
            ]);
          }
          triggerLocationChange(pos.lat, pos.lng);
        });

        // Click anywhere to place user pin
        if (interactive) {
          map.on("click", (e: any) => {
            const { lat, lng } = e.latlng;
            userMarker.setLatLng([lat, lng]);
            if (routeLineRef.current) {
              routeLineRef.current.setLatLngs([
                [KMART_STORE.lat, KMART_STORE.lng],
                [lat, lng]
              ]);
            }
            triggerLocationChange(lat, lng);
          });
        }

        setIsMapReady(true);
      } catch (err) {
        console.warn("Failed to initialize Leaflet map:", err);
      }
    };

    loadLeaflet();

    return () => {
      isMounted = false;
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, []);

  // Update tile layer when style changes
  useEffect(() => {
    const L = (window as any).L;
    if (!L || !mapInstanceRef.current || !tileLayerRef.current) return;

    tileLayerRef.current.remove();
    const tileUrl =
      mapStyle === "satellite"
        ? "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
        : "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";

    tileLayerRef.current = L.tileLayer(tileUrl, { maxZoom: 19 }).addTo(
      mapInstanceRef.current
    );
  }, [mapStyle]);

  // Zoom controls
  const handleZoomIn = () => {
    if (mapInstanceRef.current) mapInstanceRef.current.zoomIn();
  };

  const handleZoomOut = () => {
    if (mapInstanceRef.current) mapInstanceRef.current.zoomOut();
  };

  // Reset view to fit both store and user pin
  const handleResetView = () => {
    const L = (window as any).L;
    if (!mapInstanceRef.current || !L) return;

    const bounds = L.latLngBounds([
      [KMART_STORE.lat, KMART_STORE.lng],
      [currentLat, currentLng]
    ]);
    mapInstanceRef.current.fitBounds(bounds, { padding: [40, 40] });
  };


  // Use Browser GPS
  const handleLocateMe = () => {
    if (!navigator.geolocation) {
      alert("Geolocation is not supported by your browser");
      return;
    }

    setIsLocating(true);
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        setIsLocating(false);
        const { latitude, longitude } = pos.coords;

        if (mapInstanceRef.current) {
          mapInstanceRef.current.flyTo([latitude, longitude], 16, { duration: 1.2 });
        }
        if (userMarkerRef.current) {
          userMarkerRef.current.setLatLng([latitude, longitude]);
        }
        if (routeLineRef.current) {
          routeLineRef.current.setLatLngs([
            [KMART_STORE.lat, KMART_STORE.lng],
            [latitude, longitude]
          ]);
        }

        try {
          const rev = await reverseGeocode(latitude, longitude);
          triggerLocationChange(latitude, longitude, `${rev.line1}, ${rev.city}`);
        } catch {
          triggerLocationChange(latitude, longitude, "Current Detected Location");
        }
      },
      (_err) => {
        setIsLocating(false);
        // Fallback to Pune Baner hub
        if (mapInstanceRef.current) {
          mapInstanceRef.current.flyTo([KMART_STORE.lat, KMART_STORE.lng], 15, {
            duration: 0.8
          });
        }
        if (userMarkerRef.current) {
          userMarkerRef.current.setLatLng([KMART_STORE.lat, KMART_STORE.lng]);
        }
        if (routeLineRef.current) {
          routeLineRef.current.setLatLngs([
            [KMART_STORE.lat, KMART_STORE.lng],
            [KMART_STORE.lat, KMART_STORE.lng]
          ]);
        }
        triggerLocationChange(
          KMART_STORE.lat,
          KMART_STORE.lng,
          KMART_STORE.name,
          "411045"
        );
      },
      { enableHighAccuracy: false, timeout: 10000, maximumAge: 60000 }
    );
  };

  return (
    <div
      className={`rounded-2xl border border-gray-200 overflow-hidden bg-slate-50 flex flex-col shadow-xs transition-all duration-300 ${
        isExpanded ? "fixed inset-4 z-[9999] h-auto shadow-2xl bg-white" : ""
      } ${className}`}
    >
      {/* Top Map Action Bar */}
      <div className="px-3.5 py-2.5 bg-white border-b border-gray-100 flex items-center justify-between gap-2 text-xs">
        <div className="flex items-center gap-1.5 font-bold text-gray-800">
          <MapPin className="w-4 h-4 text-[#E11A22]" />
          <span>Interactive Delivery Map</span>
        </div>

        <div className="flex items-center gap-1.5">
          {/* Map style toggle */}
          <button
            type="button"
            onClick={() => setMapStyle(mapStyle === "standard" ? "satellite" : "standard")}
            className="p-1.5 rounded-lg hover:bg-gray-100 text-gray-600 font-semibold text-[11px] flex items-center gap-1 border border-gray-200 transition-colors cursor-pointer"
            title="Toggle Satellite / Street Map"
          >
            <Layers className="w-3.5 h-3.5" />
            <span className="hidden sm:inline capitalize">{mapStyle}</span>
          </button>

          {/* Reset View */}
          <button
            type="button"
            onClick={handleResetView}
            className="p-1.5 rounded-lg hover:bg-gray-100 text-gray-600 border border-gray-200 transition-colors cursor-pointer"
            title="Reset View"
          >
            <RotateCcw className="w-3.5 h-3.5" />
          </button>

          {/* Expand Toggle */}
          <button
            type="button"
            onClick={() => setIsExpanded(!isExpanded)}
            className="p-1.5 rounded-lg hover:bg-gray-100 text-gray-600 border border-gray-200 transition-colors cursor-pointer"
            title={isExpanded ? "Collapse Map" : "Expand Map"}
          >
            {isExpanded ? <Minimize2 className="w-3.5 h-3.5" /> : <Maximize2 className="w-3.5 h-3.5" />}
          </button>
        </div>
      </div>

      {/* Map Canvas with Overlays */}
      <div
        className="relative w-full overflow-hidden bg-slate-100"
        style={{ height: isExpanded ? "calc(100vh - 170px)" : height }}
      >
        {/* Leaflet DOM container */}
        <div ref={mapContainerRef} className="w-full h-full z-0" />

        {/* Loading placeholder before leaflet initializes */}
        {!isMapReady && (
          <div className="absolute inset-0 bg-slate-50 flex flex-col items-center justify-center gap-2 z-10">
            <div className="w-8 h-8 rounded-full border-3 border-[#E11A22] border-t-transparent animate-spin" />
            <span className="text-xs font-bold text-gray-600">Loading Map tiles...</span>
          </div>
        )}

        {/* Floating Zoom & Locate Controls (Right side) */}
        <div className="absolute right-3 top-3 flex flex-col gap-1.5 z-20">
          <button
            type="button"
            onClick={handleLocateMe}
            disabled={isLocating}
            className="w-8 h-8 rounded-xl bg-white shadow-md border border-gray-200 flex items-center justify-center text-[#0A2540] hover:bg-gray-50 active:scale-95 transition-all cursor-pointer"
            title="Locate my position (GPS)"
          >
            <Navigation className={`w-4 h-4 ${isLocating ? "animate-spin text-[#E11A22]" : ""}`} />
          </button>

          <button
            type="button"
            onClick={handleZoomIn}
            className="w-8 h-8 rounded-xl bg-white shadow-md border border-gray-200 flex items-center justify-center text-gray-700 hover:bg-gray-50 active:scale-95 transition-all cursor-pointer"
            title="Zoom In"
          >
            <Plus className="w-4 h-4" />
          </button>

          <button
            type="button"
            onClick={handleZoomOut}
            className="w-8 h-8 rounded-xl bg-white shadow-md border border-gray-200 flex items-center justify-center text-gray-700 hover:bg-gray-50 active:scale-95 transition-all cursor-pointer"
            title="Zoom Out"
          >
            <Minus className="w-4 h-4" />
          </button>
        </div>

        {/* Floating Delivery Status Badge (Top Left) */}
        <div className="absolute left-3 top-3 z-20 pointer-events-none">
          <div
            className={`px-3 py-1.5 rounded-xl shadow-md border flex items-center gap-2 backdrop-blur-md ${
              isDeliverable
                ? "bg-white/95 border-emerald-200 text-emerald-950"
                : "bg-white/95 border-amber-200 text-amber-950"
            }`}
          >
            {isDeliverable ? (
              <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
            ) : (
              <AlertCircle className="w-4 h-4 text-amber-600 shrink-0" />
            )}
            <div className="text-[11px] leading-tight">
              <span className="font-extrabold block">
                {isDeliverable ? "Delivery Available" : "Outside standard 6km radius"}
              </span>
              <span className="text-[10px] text-gray-500 font-medium">
                {distanceKm} km from K MART Store
              </span>
            </div>
          </div>
        </div>

        {/* Instruction Tagline (Bottom Left) */}
        <div className="absolute left-3 bottom-2.5 z-20 pointer-events-none hidden sm:block">
          <span className="bg-[#0A2540]/80 text-white text-[10px] font-semibold px-2 py-1 rounded-md backdrop-blur-xs">
            👉 Drag the pin or click anywhere on the map to set delivery location
          </span>
        </div>
      </div>



      {/* Bottom Summary Bar */}
      <div className="px-4 py-2.5 bg-white border-t border-gray-100 flex items-center justify-between text-xs">
        <div className="flex items-center gap-2 truncate pr-2">
          <div
            className={`w-2 h-2 rounded-full shrink-0 ${
              isDeliverable ? "bg-emerald-500 animate-pulse" : "bg-amber-500"
            }`}
          />
          <span className="font-bold text-gray-800 truncate">
            {detectedArea}, {detectedPincode}
          </span>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          <span className="text-[11px] font-bold text-[#E11A22] bg-red-50 px-2 py-0.5 rounded-full border border-red-100">
            {distanceKm} km away
          </span>
        </div>
      </div>
    </div>
  );
};
