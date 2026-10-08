'use client';

import React, { useState } from 'react';
import { 
  X, 
  MapPin, 
  Crosshair, 
  Check, 
  Home as HomeIcon,
  Briefcase,
  Building,
  AlertCircle,
  Sparkles,
  Loader2
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { DeliveryMap, DeliveryLocationData } from './DeliveryMap';
import { getCurrentDeviceLocation } from '../lib/geolocation';

export const LocationModal: React.FC = () => {
  const { 
    isLocationOpen, 
    setIsLocationOpen, 
    addAddress, 
    selectedAddress, 
    setSelectedAddress, 
    addresses,
    user
  } = useApp();

  const [addressType, setAddressType] = useState<'Home' | 'Work' | 'Other'>('Home');
  const [fullName, setFullName] = useState(user.name || '');
  const [phone, setPhone] = useState(user.phone || '');
  const [line1, setLine1] = useState('');
  const [line2, setLine2] = useState('');
  const [pincode, setPincode] = useState('411001');
  const [city, setCity] = useState('Pune');
  const [state, setState] = useState('Maharashtra');
  const [latitude, setLatitude] = useState<number>(18.5204);
  const [longitude, setLongitude] = useState<number>(73.8567);
  const [isDefault, setIsDefault] = useState(true);
  const [isDetecting, setIsDetecting] = useState(false);
  const [detectionError, setDetectionError] = useState<string | null>(null);
  const [detectionSuccess, setDetectionSuccess] = useState<string | null>(null);

  if (!isLocationOpen) return null;

  const handleUseCurrentLocation = async () => {
    setIsDetecting(true);
    setDetectionError(null);
    setDetectionSuccess(null);

    const result = await getCurrentDeviceLocation();
    setIsDetecting(false);

    if (result.success && result.data) {
      const d = result.data;
      setLine1(d.line1);
      setLine2(d.line2 || '');
      setCity(d.city || 'Pune');
      setState(d.state || 'Maharashtra');
      setPincode(d.pincode || '411001');
      setLatitude(d.latitude);
      setLongitude(d.longitude);
      setDetectionSuccess(`Detected: ${d.line1}, ${d.city} (${d.pincode})`);
    } else {
      setDetectionError(
        result.error || 'Could not retrieve GPS coordinates. Please enter your address or select on the map.'
      );
    }
  };

  const handleMapLocationSelect = (loc: DeliveryLocationData) => {
    setLine2(loc.area);
    setPincode(loc.pincode);
    setCity(loc.city);
    setLatitude(loc.lat);
    setLongitude(loc.lng);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!line1 || !phone) {
      alert('Please fill Address line and Phone number');
      return;
    }

    await addAddress({
      label: addressType,
      fullName: fullName || user.name || 'Customer',
      phone: phone || user.phone || '9876543210',
      line1,
      line2: line2 || undefined,
      city,
      state,
      pincode,
      latitude: latitude || 18.5204,
      longitude: longitude || 73.8567,
      isDefault: addresses.length === 0 || isDefault,
    });

    setIsLocationOpen(false);
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-black/60 backdrop-blur-xs flex items-center justify-center p-3 sm:p-6 animate-fadeIn">
      <div className="bg-white w-full max-w-lg rounded-2xl shadow-2xl overflow-hidden border border-gray-100 relative my-6 text-left animate-modal-in">
        
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-100 flex items-center justify-between bg-gray-50/70">
          <div className="flex items-center gap-2">
            <MapPin className="w-5 h-5 text-[#E11A22]" />
            <h3 className="font-extrabold text-base text-[#0A2540]">
              Select Delivery Location
            </h3>
          </div>
          <button
            onClick={() => setIsLocationOpen(false)}
            className="w-8 h-8 rounded-full hover:bg-gray-200 text-gray-500 flex items-center justify-center cursor-pointer transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-6 space-y-5 max-h-[80vh] overflow-y-auto">
          
          {/* GPS Location Button */}
          <div className="space-y-2">
            <button
              onClick={handleUseCurrentLocation}
              disabled={isDetecting}
              className="w-full p-3.5 rounded-xl border-2 border-dashed border-[#E11A22]/50 hover:border-[#E11A22] bg-red-50/40 hover:bg-red-50/80 flex items-center justify-center gap-2.5 text-xs sm:text-sm font-black text-[#E11A22] transition-all cursor-pointer disabled:opacity-60 shadow-xs"
            >
              {isDetecting ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin text-[#E11A22]" />
                  <span>Detecting GPS Coordinates & Reverse Geocoding...</span>
                </>
              ) : (
                <>
                  <Crosshair className="w-4 h-4 text-[#E11A22]" />
                  <span>Use Current Location (GPS)</span>
                </>
              )}
            </button>

            {/* Success Feedback */}
            {detectionSuccess && (
              <div className="p-2.5 rounded-xl bg-emerald-50 border border-emerald-200 text-xs text-emerald-800 flex items-center gap-2 font-medium">
                <Check className="w-4 h-4 text-emerald-600 shrink-0" />
                <span className="truncate">{detectionSuccess}</span>
              </div>
            )}

            {/* Error Feedback */}
            {detectionError && (
              <div className="p-2.5 rounded-xl bg-amber-50 border border-amber-200 text-xs text-amber-800 flex items-start gap-2 font-medium">
                <AlertCircle className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
                <span className="leading-snug">{detectionError}</span>
              </div>
            )}
          </div>

          {/* Saved Addresses */}
          {addresses.length > 0 && (
            <div>
              <span className="text-xs font-bold text-gray-500 uppercase tracking-wider block mb-2">
                Saved Addresses
              </span>

              <div className="space-y-2.5">
                {addresses.map((addr) => {
                  const isSelected = selectedAddress?.id === addr.id;
                  return (
                    <div
                      key={addr.id}
                      onClick={() => {
                        setSelectedAddress(addr);
                        setIsLocationOpen(false);
                      }}
                      className={`p-3.5 rounded-xl border-2 transition-all cursor-pointer flex items-start justify-between gap-3 ${
                        isSelected
                          ? 'border-[#E11A22] bg-red-50/20 shadow-xs'
                          : 'border-gray-200 hover:border-gray-300 bg-white'
                      }`}
                    >
                      <div className="flex items-start gap-2.5">
                        <div className={`w-4 h-4 rounded-full border-2 flex items-center justify-center mt-0.5 ${
                          isSelected ? 'border-[#E11A22]' : 'border-gray-300'
                        }`}>
                          {isSelected && <div className="w-2 h-2 rounded-full bg-[#E11A22]" />}
                        </div>

                        <div className="text-xs">
                          <div className="flex items-center gap-2">
                            <span className="font-extrabold text-gray-900">{addr.label}</span>
                            {addr.isDefault && (
                              <span className="bg-gray-100 text-gray-600 text-[10px] font-bold px-1.5 rounded">
                                Default
                              </span>
                            )}
                          </div>
                          <p className="text-gray-600 mt-0.5">
                            {addr.line1}{addr.line2 ? `, ${addr.line2}` : ''}
                          </p>
                          <p className="text-gray-400 text-[11px]">
                            {addr.city} - {addr.pincode}
                          </p>
                        </div>
                      </div>

                      {isSelected && (
                        <span className="text-[11px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded flex items-center gap-1">
                          <Check className="w-3 h-3" />
                          Selected
                        </span>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Interactive Delivery Map */}
          <DeliveryMap
            height="240px"
            onLocationSelect={handleMapLocationSelect}
          />

          {/* Add New Address Form */}
          <form onSubmit={handleSave} className="space-y-3.5 pt-3 border-t border-gray-100">
            <span className="text-xs font-bold text-gray-900 uppercase tracking-wider block">
              Confirm & Save Address
            </span>

            {/* Address Type radio tabs */}
            <div className="flex gap-2">
              {(['Home', 'Work', 'Other'] as const).map((type) => (
                <button
                  type="button"
                  key={type}
                  onClick={() => setAddressType(type)}
                  className={`flex-1 py-1.5 rounded-lg text-xs font-bold transition-all border cursor-pointer ${
                    addressType === type
                      ? 'bg-[#0A2540] text-white border-[#0A2540]'
                      : 'bg-gray-50 text-gray-600 border-gray-200 hover:bg-gray-100'
                  }`}
                >
                  {type}
                </button>
              ))}
            </div>

            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-[11px] font-bold text-gray-700 mb-1">Full Name *</label>
                <input
                  type="text"
                  required
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="Full name"
                  className="w-full px-3 py-2 text-xs bg-white rounded-lg border border-gray-300 focus:outline-none focus:border-[#E11A22]"
                />
              </div>
              <div>
                <label className="block text-[11px] font-bold text-gray-700 mb-1">Phone Number *</label>
                <input
                  type="tel"
                  required
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="Phone"
                  className="w-full px-3 py-2 text-xs bg-white rounded-lg border border-gray-300 focus:outline-none focus:border-[#E11A22]"
                />
              </div>
            </div>

            <div>
              <label className="block text-[11px] font-bold text-gray-700 mb-1">
                House / Flat / Building No. (Line 1) *
              </label>
              <input
                type="text"
                required
                value={line1}
                onChange={(e) => setLine1(e.target.value)}
                placeholder="e.g. Flat 302, Royal Palms or Road Name"
                className="w-full px-3 py-2 text-xs bg-white rounded-lg border border-gray-300 focus:outline-none focus:border-[#E11A22]"
              />
            </div>

            <div>
              <label className="block text-[11px] font-bold text-gray-700 mb-1">
                Area / Colony / Street (Line 2)
              </label>
              <input
                type="text"
                value={line2}
                onChange={(e) => setLine2(e.target.value)}
                placeholder="e.g. Baner Road, Shivajinagar"
                className="w-full px-3 py-2 text-xs bg-white rounded-lg border border-gray-300 focus:outline-none focus:border-[#E11A22]"
              />
            </div>

            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-[11px] font-bold text-gray-700 mb-1">City *</label>
                <input
                  type="text"
                  required
                  value={city}
                  onChange={(e) => setCity(e.target.value)}
                  placeholder="City"
                  className="w-full px-3 py-2 text-xs bg-white rounded-lg border border-gray-300 focus:outline-none focus:border-[#E11A22]"
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-gray-700 mb-1">Pincode *</label>
                <input
                  type="text"
                  required
                  value={pincode}
                  onChange={(e) => setPincode(e.target.value)}
                  placeholder="411001"
                  className="w-full px-3 py-2 text-xs bg-white rounded-lg border border-gray-300 focus:outline-none focus:border-[#E11A22]"
                />
              </div>
            </div>

            <button
              type="submit"
              className="w-full bg-[#E11A22] hover:bg-[#c8141b] text-white font-bold py-3 rounded-xl text-xs sm:text-sm shadow-md transition-all cursor-pointer"
            >
              Save Address & Deliver Here
            </button>
          </form>

        </div>
      </div>
    </div>
  );
};
