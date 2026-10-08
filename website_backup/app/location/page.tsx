"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { 
  MapPin, 
  Crosshair, 
  Check, 
  Plus, 
  ChevronRight, 
  ArrowLeft,
  Truck,
  Building,
  Home as HomeIcon,
  Briefcase,
  AlertCircle,
  Loader2
} from "lucide-react";
import { useApp } from "@/context/AppContext";
import { Address } from "@/types";
import { getCurrentDeviceLocation } from "@/lib/geolocation";

export default function LocationPage() {
  const router = useRouter();
  const {
    addresses,
    selectedAddress,
    setSelectedAddress,
    addAddress,
    user
  } = useApp();

  const [addressType, setAddressType] = useState<"Home" | "Work" | "Other">("Home");
  const [fullName, setFullName] = useState(user.name || "");
  const [phone, setPhone] = useState(user.phone || "");
  const [line1, setLine1] = useState("");
  const [line2, setLine2] = useState("");
  const [city, setCity] = useState("Pune");
  const [state, setState] = useState("Maharashtra");
  const [pincode, setPincode] = useState("411001");
  const [latitude, setLatitude] = useState<number>(18.5204);
  const [longitude, setLongitude] = useState<number>(73.8567);
  const [isDetecting, setIsDetecting] = useState(false);
  const [showAddForm, setShowAddForm] = useState(false);
  const [detectionError, setDetectionError] = useState<string | null>(null);
  const [detectionSuccess, setDetectionSuccess] = useState<string | null>(null);

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
      setShowAddForm(true);
    } else {
      setDetectionError(
        result.error || 'Could not retrieve GPS coordinates. Please enter your address below.'
      );
      setShowAddForm(true);
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!line1 || !phone) return;

    await addAddress({
      label: addressType,
      fullName: fullName || user.name || "Customer",
      phone,
      line1,
      line2: line2 || undefined,
      city,
      state,
      pincode,
      latitude: latitude || 18.5204,
      longitude: longitude || 73.8567,
      isDefault: addresses.length === 0,
    });

    setShowAddForm(false);
    setLine1("");
    setLine2("");
  };

  return (
    <div className="min-h-screen bg-[#F8F9FA] pb-16">
      {/* Top Breadcrumb */}
      <div className="bg-white border-b border-gray-200/80 shadow-2xs">
        <div className="max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 py-3 sm:py-3.5 flex items-center justify-between">
          <div className="flex items-center gap-2 text-xs sm:text-sm text-gray-500">
            <Link href="/" className="hover:text-[#E11A22] transition-colors">
              Home
            </Link>
            <ChevronRight className="w-3.5 h-3.5 text-gray-400" />
            <span className="font-semibold text-gray-900">Delivery Location</span>
          </div>

          <button
            onClick={() => router.back()}
            className="flex items-center gap-1 text-xs font-bold text-gray-600 hover:text-[#E11A22] cursor-pointer"
          >
            <ArrowLeft className="w-3.5 h-3.5" />
            <span>Back</span>
          </button>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 sm:px-6 pt-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6">
          <div>
            <h1 className="text-2xl sm:text-3xl font-black text-[#0A2540] tracking-tight">
              Select Delivery Address
            </h1>
            <p className="text-xs sm:text-sm text-gray-500 mt-0.5">
              Choose your address to ensure guaranteed on-time delivery from nearest K MART hub
            </p>
          </div>

          <button
            onClick={handleUseCurrentLocation}
            disabled={isDetecting}
            className="flex items-center gap-2 bg-red-50 hover:bg-red-100 text-[#E11A22] text-xs font-bold px-4 py-2.5 rounded-xl border border-red-200 transition-colors cursor-pointer self-start sm:self-auto"
          >
            {isDetecting ? (
              <Loader2 className="w-4 h-4 animate-spin text-[#E11A22]" />
            ) : (
              <Crosshair className="w-4 h-4 text-[#E11A22]" />
            )}
            <span>{isDetecting ? "Detecting GPS..." : "Use Current Location"}</span>
          </button>
        </div>

        {/* Feedback alerts */}
        {detectionSuccess && (
          <div className="mb-4 p-3 rounded-xl bg-emerald-50 border border-emerald-200 text-xs text-emerald-800 flex items-center gap-2 font-medium">
            <Check className="w-4 h-4 text-emerald-600 shrink-0" />
            <span>{detectionSuccess}</span>
          </div>
        )}

        {detectionError && (
          <div className="mb-4 p-3 rounded-xl bg-amber-50 border border-amber-200 text-xs text-amber-800 flex items-start gap-2 font-medium">
            <AlertCircle className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
            <span>{detectionError}</span>
          </div>
        )}


        {/* Saved Addresses List */}
        <div className="space-y-4">
          {addresses.length > 0 ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {addresses.map((addr) => {
                const isSelected = selectedAddress?.id === addr.id;
                return (
                  <div
                    key={addr.id}
                    onClick={() => setSelectedAddress(addr)}
                    className={`p-5 rounded-2xl border-2 cursor-pointer transition-all bg-white ${
                      isSelected
                        ? "border-[#E11A22] shadow-sm ring-2 ring-red-100"
                        : "border-gray-200 hover:border-gray-300 shadow-2xs"
                    }`}
                  >
                    <div className="flex items-center justify-between mb-2.5">
                      <span className={`text-xs font-extrabold uppercase px-2.5 py-0.5 rounded-lg flex items-center gap-1.5 ${
                        isSelected ? "bg-[#E11A22] text-white" : "bg-gray-100 text-gray-700"
                      }`}>
                        {addr.label === "Home" && <HomeIcon className="w-3 h-3" />}
                        {addr.label === "Work" && <Briefcase className="w-3 h-3" />}
                        {addr.label === "Other" && <Building className="w-3 h-3" />}
                        <span>{addr.label}</span>
                      </span>

                      {isSelected && (
                        <span className="text-xs font-bold text-[#E11A22] flex items-center gap-1">
                          <Check className="w-4 h-4" />
                          <span>Active</span>
                        </span>
                      )}
                    </div>

                    <p className="font-bold text-sm text-gray-900">{addr.fullName} • {addr.phone}</p>
                    <p className="text-xs text-gray-600 mt-1 leading-relaxed">
                      {addr.line1}{addr.line2 ? `, ${addr.line2}` : ''}, {addr.city} - {addr.pincode}
                    </p>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="bg-white rounded-2xl border border-dashed border-gray-300 p-8 text-center">
              <MapPin className="w-8 h-8 text-gray-400 mx-auto mb-2" />
              <p className="text-sm font-bold text-gray-700">No saved addresses yet</p>
              <p className="text-xs text-gray-500 mt-1">Add your delivery location below or use current location to see delivery slots.</p>
            </div>
          )}

          {/* Add New Address Trigger & Form */}
          {!showAddForm ? (
            <button
              onClick={() => setShowAddForm(true)}
              className="w-full py-4 border-2 border-dashed border-gray-300 hover:border-[#E11A22] rounded-2xl text-xs font-bold text-gray-600 hover:text-[#E11A22] flex items-center justify-center gap-2 transition-all cursor-pointer bg-white"
            >
              <Plus className="w-4 h-4" />
              <span>Add New Address</span>
            </button>
          ) : (
            <div className="bg-white rounded-2xl border border-gray-200 p-6 shadow-2xs">
              <h2 className="text-base font-black text-[#0A2540] mb-4">Add New Delivery Address</h2>
              
              <form onSubmit={handleSave} className="space-y-4">
                <div className="flex gap-2">
                  {(["Home", "Work", "Other"] as const).map((t) => (
                    <button
                      key={t}
                      type="button"
                      onClick={() => setAddressType(t)}
                      className={`text-xs font-bold px-4 py-2 rounded-xl border transition-all cursor-pointer ${
                        addressType === t
                          ? "bg-[#0A2540] text-white border-[#0A2540]"
                          : "bg-gray-50 text-gray-600 border-gray-200 hover:bg-gray-100"
                      }`}
                    >
                      {t}
                    </button>
                  ))}
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-bold text-gray-700 mb-1">Full Name *</label>
                    <input
                      type="text"
                      required
                      value={fullName}
                      onChange={(e) => setFullName(e.target.value)}
                      placeholder="Receiver name"
                      className="w-full px-3.5 py-2.5 text-xs bg-white rounded-xl border border-gray-300 focus:outline-none focus:border-[#E11A22]"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-gray-700 mb-1">Phone Number *</label>
                    <input
                      type="tel"
                      required
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      placeholder="10-digit mobile"
                      className="w-full px-3.5 py-2.5 text-xs bg-white rounded-xl border border-gray-300 focus:outline-none focus:border-[#E11A22]"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">
                    House / Flat / Building No. (Line 1) *
                  </label>
                  <input
                    type="text"
                    required
                    value={line1}
                    onChange={(e) => setLine1(e.target.value)}
                    placeholder="e.g. Flat 402, Shivajinagar"
                    className="w-full px-3.5 py-2.5 text-xs bg-white rounded-xl border border-gray-300 focus:outline-none focus:border-[#E11A22]"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">
                    Area / Colony / Street (Line 2)
                  </label>
                  <input
                    type="text"
                    value={line2}
                    onChange={(e) => setLine2(e.target.value)}
                    placeholder="e.g. Near FC College, Shivajinagar"
                    className="w-full px-3.5 py-2.5 text-xs bg-white rounded-xl border border-gray-300 focus:outline-none focus:border-[#E11A22]"
                  />
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-bold text-gray-700 mb-1">City *</label>
                    <input
                      type="text"
                      required
                      value={city}
                      onChange={(e) => setCity(e.target.value)}
                      placeholder="Pune"
                      className="w-full px-3.5 py-2.5 text-xs bg-white rounded-xl border border-gray-300 focus:outline-none focus:border-[#E11A22]"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-gray-700 mb-1">Pincode *</label>
                    <input
                      type="text"
                      required
                      value={pincode}
                      onChange={(e) => setPincode(e.target.value)}
                      placeholder="411005"
                      className="w-full px-3.5 py-2.5 text-xs bg-white rounded-xl border border-gray-300 focus:outline-none focus:border-[#E11A22]"
                    />
                  </div>
                </div>

                <div className="pt-2 flex items-center justify-end gap-3">
                  <button
                    type="button"
                    onClick={() => setShowAddForm(false)}
                    className="px-4 py-2.5 rounded-xl border border-gray-300 text-xs font-bold text-gray-600 hover:bg-gray-50 cursor-pointer"
                  >
                    Cancel
                  </button>

                  <button
                    type="submit"
                    className="px-6 py-2.5 rounded-xl bg-[#E11A22] hover:bg-[#c8141b] text-white text-xs font-bold shadow-sm transition-all cursor-pointer"
                  >
                    Save Address
                  </button>
                </div>
              </form>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
