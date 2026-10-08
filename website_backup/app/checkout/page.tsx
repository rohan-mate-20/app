"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { 
  MapPin, 
  Clock, 
  CreditCard, 
  Banknote, 
  CheckCircle2, 
  ShieldCheck, 
  ArrowRight, 
  ChevronRight, 
  Plus, 
  Truck,
  ArrowLeft,
  Lock,
  AlertCircle,
  User
} from "lucide-react";
import { useApp } from "@/context/AppContext";
import { Address } from "@/types";
import { openRazorpayCheckout } from "@/lib/razorpay";
import { RazorpayPaymentModal } from "@/components/RazorpayPaymentModal";
import confetti from "canvas-confetti";

export default function CheckoutPage() {
  const router = useRouter();
  const {
    cart,
    cartCount,
    itemTotal,
    discount,
    deliveryFee,
    totalAmount,
    appliedCoupon,
    couponDiscount,
    selectedAddress,
    addresses,
    setSelectedAddress,
    addAddress,
    deliverySettings,
    deliverySlots,
    selectedSlot,
    setSelectedSlot,
    placeOrder,
    user,
    setIsAuthOpen
  } = useApp();

  const [paymentMethod, setPaymentMethod] = useState<"Cash on Delivery" | "Razorpay">("Razorpay");
  const [isPlacing, setIsPlacing] = useState(false);
  const [isRazorpayModalOpen, setIsRazorpayModalOpen] = useState(false);
  const [showNewAddressForm, setShowNewAddressForm] = useState(false);

  // New address form state matching DB schema
  const [newLabel, setNewLabel] = useState<"Home" | "Work" | "Other">("Home");
  const [newName, setNewName] = useState(user.name || "");
  const [newPhone, setNewPhone] = useState(user.phone || "");
  const [newLine1, setNewLine1] = useState("");
  const [newLine2, setNewLine2] = useState("");
  const [newCity, setNewCity] = useState("Pune");
  const [newState, setNewState] = useState("Maharashtra");
  const [newPincode, setNewPincode] = useState("411001");

  useEffect(() => {
    if (user.name && !newName) setNewName(user.name);
    if (user.phone && !newPhone) setNewPhone(user.phone);
  }, [user.name, user.phone]);

  const isBelowMinOrder = itemTotal < deliverySettings.min_order_value;

  const handleSaveAddress = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newLine1 || !newPhone) return;

    await addAddress({
      label: newLabel,
      fullName: newName || "Customer",
      phone: newPhone,
      line1: newLine1,
      line2: newLine2 || undefined,
      city: newCity,
      state: newState,
      pincode: newPincode,
      latitude: 0,
      longitude: 0,
      isDefault: addresses.length === 0,
    });

    setShowNewAddressForm(false);
  };

  const handlePlaceOrder = async () => {
    if (cart.length === 0 || isPlacing) return;

    if (!user.isVerified) {
      setIsAuthOpen(true);
      return;
    }

    if (!selectedAddress) {
      alert("Please add or select a delivery address before placing your order.");
      setShowNewAddressForm(true);
      return;
    }

    if (isBelowMinOrder) {
      alert(`Minimum order value for delivery is ₹${deliverySettings.min_order_value}. Please add more items.`);
      return;
    }

    if (paymentMethod === "Razorpay") {
      setIsPlacing(true);

      const customerName = selectedAddress.fullName || user.name || "Customer";
      const customerPhone = selectedAddress.phone || user.phone || "9876543210";
      const customerEmail = user.email || "";

      const rzpOpened = await openRazorpayCheckout({
        amount: totalAmount,
        customerName,
        customerPhone,
        customerEmail,
        description: "K MART Groceries Order",
        onSuccess: async (paymentId: string) => {
          try {
            confetti({ particleCount: 120, spread: 80, origin: { y: 0.6 } });
          } catch {}
          try {
            const order = await placeOrder("Razorpay", paymentId);
            router.push(`/orders/${order.id}`);
          } catch (err) {
            console.error("[Checkout] Order placement error:", err);
            setIsPlacing(false);
          }
        },
        onDismiss: () => {
          console.log("[Checkout] Razorpay gateway dismissed by user");
          setIsPlacing(false);
        },
      });

      if (!rzpOpened) {
        // Fallback to interactive in-app Razorpay modal (UPI QR, Google Pay, PhonePe, Cards)
        setIsRazorpayModalOpen(true);
      }
      return;
    }

    // Cash on Delivery flow
    setIsPlacing(true);
    try {
      try {
        confetti({ particleCount: 100, spread: 70, origin: { y: 0.6 } });
      } catch {}
      const order = await placeOrder("Cash on Delivery");
      router.push(`/orders/${order.id}`);
    } catch (err) {
      console.error("[Checkout] Order placement error:", err);
      setIsPlacing(false);
    }
  };

  if (cart.length === 0) {
    return (
      <div className="min-h-[75vh] bg-[#F8F9FA] flex flex-col items-center justify-center px-4 py-16 text-center">
        <h1 className="text-2xl sm:text-3xl font-black text-[#0A2540]">Your cart is empty</h1>
        <p className="mt-2 text-sm text-gray-500 max-w-md">
          Please add items to your cart before proceeding to checkout.
        </p>
        <Link
          href="/categories"
          className="mt-6 px-6 py-3 rounded-xl bg-[#E11A22] hover:bg-[#c8141b] text-white text-sm font-bold shadow-sm transition-all"
        >
          Explore Products
        </Link>
      </div>
    );
  }

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
            <Link href="/cart" className="hover:text-[#E11A22] transition-colors">
              Cart
            </Link>
            <ChevronRight className="w-3.5 h-3.5 text-gray-400" />
            <span className="font-semibold text-gray-900">Checkout</span>
          </div>

          <div className="flex items-center gap-1.5 text-xs text-emerald-700 font-bold bg-emerald-50 px-3 py-1 rounded-full">
            <Lock className="w-3.5 h-3.5" />
            <span>Secure 256-bit SSL Checkout</span>
          </div>
        </div>
      </div>

      <div className="max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 pt-6">
        <h1 className="text-2xl sm:text-3xl font-black text-[#0A2540] tracking-tight mb-6">
          Checkout & Order Confirmation
        </h1>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
          
          {/* Left Column: Delivery Address, Slot, Payment (8 cols) */}
          <div className="lg:col-span-8 space-y-6">

            {/* Min order value warning banner if applicable */}
            {isBelowMinOrder && (
              <div className="p-4 bg-amber-50 border border-amber-200 rounded-2xl flex items-center gap-3 text-amber-900 text-xs">
                <AlertCircle className="w-5 h-5 text-amber-600 shrink-0" />
                <div>
                  <p className="font-bold">Minimum order value is ₹{deliverySettings.min_order_value}</p>
                  <p className="text-amber-700 mt-0.5">
                    Add items worth ₹{deliverySettings.min_order_value - itemTotal} more to place this delivery order.
                  </p>
                </div>
              </div>
            )}

            {/* Account / Login Required Card */}
            {!user.isVerified ? (
              <div className="bg-gradient-to-r from-red-50/90 to-orange-50/90 rounded-2xl border-2 border-[#E11A22]/20 p-5 shadow-2xs flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div className="flex items-start gap-3">
                  <div className="w-10 h-10 rounded-full bg-[#E11A22] text-white flex items-center justify-center shrink-0 shadow-sm mt-0.5 sm:mt-0">
                    <User className="w-5 h-5" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <h3 className="font-black text-sm text-[#0A2540]">
                        Login Required to Confirm Order
                      </h3>
                      <span className="text-[10px] font-black uppercase tracking-wider bg-[#E11A22] text-white px-2 py-0.5 rounded-full">
                        Required
                      </span>
                    </div>
                    <p className="text-xs text-gray-600 mt-1 leading-relaxed">
                      Please log in with your mobile number via OTP. Your orders, delivery addresses, and tracking will be securely saved to your account.
                    </p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setIsAuthOpen(true)}
                  className="bg-[#0A2540] hover:bg-[#123154] text-white font-extrabold text-xs px-5 py-2.5 rounded-xl shadow-xs transition-all cursor-pointer shrink-0"
                >
                  Login with OTP
                </button>
              </div>
            ) : (
              <div className="bg-white rounded-2xl border border-gray-200/90 p-4 shadow-2xs flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
                    <CheckCircle2 className="w-5 h-5" />
                  </div>
                  <div>
                    <p className="text-[11px] text-gray-500 font-medium">Ordering as</p>
                    <p className="font-extrabold text-xs text-[#0A2540]">
                      {user.name || "Customer"} <span className="font-medium text-gray-500">({user.phone})</span>
                    </p>
                  </div>
                </div>
                <span className="text-[11px] font-bold text-emerald-700 bg-emerald-50 px-2.5 py-1 rounded-full border border-emerald-200">
                  Verified Account
                </span>
              </div>
            )}

            {/* 1. Delivery Address Card */}
            <div className="bg-white rounded-2xl border border-gray-200/90 p-5 sm:p-6 shadow-2xs">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-full bg-red-50 text-[#E11A22] font-black text-xs flex items-center justify-center">
                    1
                  </div>
                  <h2 className="text-base sm:text-lg font-black text-[#0A2540]">
                    Delivery Address
                  </h2>
                </div>

                {!showNewAddressForm && (
                  <button
                    onClick={() => setShowNewAddressForm(true)}
                    className="text-xs font-bold text-[#E11A22] hover:text-[#c8141b] flex items-center gap-1 cursor-pointer"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>Add New Address</span>
                  </button>
                )}
              </div>

              {/* Address List */}
              {addresses.length > 0 ? (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {addresses.map((addr) => {
                    const isSelected = selectedAddress?.id === addr.id;
                    return (
                      <div
                        key={addr.id}
                        onClick={() => setSelectedAddress(addr)}
                        className={`p-4 rounded-xl border-2 cursor-pointer transition-all ${
                          isSelected
                            ? "border-[#E11A22] bg-red-50/40 shadow-xs"
                            : "border-gray-200 hover:border-gray-300 bg-white"
                        }`}
                      >
                        <div className="flex items-center justify-between mb-2">
                          <span className={`text-[11px] font-black uppercase px-2 py-0.5 rounded ${
                            isSelected ? "bg-[#E11A22] text-white" : "bg-gray-100 text-gray-700"
                          }`}>
                            {addr.label}
                          </span>
                          {isSelected && (
                            <CheckCircle2 className="w-4 h-4 text-[#E11A22]" />
                          )}
                        </div>
                        <p className="text-xs font-bold text-gray-900">{addr.fullName} • {addr.phone}</p>
                        <p className="text-xs text-gray-600 mt-1 leading-relaxed">
                          {addr.line1}{addr.line2 ? `, ${addr.line2}` : ''}, {addr.city} - {addr.pincode}
                        </p>
                      </div>
                    );
                  })}
                </div>
              ) : (
                <div className="p-4 bg-amber-50 rounded-xl border border-amber-200 text-xs text-amber-900">
                  <p className="font-bold">No delivery address saved yet</p>
                  <p className="text-gray-600 mt-0.5">Please add your delivery address below to complete checkout.</p>
                </div>
              )}

              {/* New Address Form */}
              {(showNewAddressForm || addresses.length === 0) && (
                <form onSubmit={handleSaveAddress} className="mt-4 p-4 bg-gray-50 rounded-xl border border-gray-200 space-y-3">
                  <div className="flex items-center justify-between">
                    <h3 className="text-xs font-black text-[#0A2540] uppercase">Add New Delivery Location</h3>
                    {addresses.length > 0 && (
                      <button
                        type="button"
                        onClick={() => setShowNewAddressForm(false)}
                        className="text-xs text-gray-500 hover:text-gray-800 cursor-pointer"
                      >
                        Cancel
                      </button>
                    )}
                  </div>

                  <div className="flex gap-2">
                    {(["Home", "Work", "Other"] as const).map((t) => (
                      <button
                        key={t}
                        type="button"
                        onClick={() => setNewLabel(t)}
                        className={`text-xs font-bold px-3 py-1.5 rounded-lg border transition-all ${
                          newLabel === t
                            ? "border-[#E11A22] bg-[#E11A22] text-white"
                            : "border-gray-300 bg-white text-gray-700"
                        }`}
                      >
                        {t}
                      </button>
                    ))}
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <input
                      type="text"
                      placeholder="Receiver Full Name"
                      value={newName}
                      onChange={(e) => setNewName(e.target.value)}
                      required
                      className="p-2.5 text-xs bg-white border border-gray-300 rounded-lg"
                    />
                    <input
                      type="tel"
                      placeholder="10-digit Phone Number"
                      value={newPhone}
                      onChange={(e) => setNewPhone(e.target.value)}
                      required
                      className="p-2.5 text-xs bg-white border border-gray-300 rounded-lg"
                    />
                    <input
                      type="text"
                      placeholder="House / Flat / Block (Line 1)"
                      value={newLine1}
                      onChange={(e) => setNewLine1(e.target.value)}
                      required
                      className="p-2.5 text-xs bg-white border border-gray-300 rounded-lg"
                    />
                    <input
                      type="text"
                      placeholder="Colony / Area / Landmark (Line 2)"
                      value={newLine2}
                      onChange={(e) => setNewLine2(e.target.value)}
                      className="p-2.5 text-xs bg-white border border-gray-300 rounded-lg"
                    />
                    <input
                      type="text"
                      placeholder="City"
                      value={newCity}
                      onChange={(e) => setNewCity(e.target.value)}
                      required
                      className="p-2.5 text-xs bg-white border border-gray-300 rounded-lg"
                    />
                    <input
                      type="text"
                      placeholder="Pincode"
                      value={newPincode}
                      onChange={(e) => setNewPincode(e.target.value)}
                      required
                      className="p-2.5 text-xs bg-white border border-gray-300 rounded-lg"
                    />
                  </div>

                  <button
                    type="submit"
                    className="bg-[#0A2540] hover:bg-[#123154] text-white text-xs font-bold px-5 py-2.5 rounded-lg transition-colors cursor-pointer"
                  >
                    Save & Deliver Here
                  </button>
                </form>
              )}
            </div>

            {/* 2. Delivery Slot Card (from DB delivery_slots table) */}
            <div className="bg-white rounded-2xl border border-gray-200/90 p-5 sm:p-6 shadow-2xs">
              <div className="flex items-center gap-2.5 mb-4">
                <div className="w-8 h-8 rounded-full bg-red-50 text-[#E11A22] font-black text-xs flex items-center justify-center">
                  2
                </div>
                <div>
                  <h2 className="text-base sm:text-lg font-black text-[#0A2540]">
                    Select Delivery Slot
                  </h2>
                  <p className="text-xs text-gray-500">
                    Live schedule directly synced with our local dark store
                  </p>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {deliverySlots.map((slot) => {
                  const isSelected = selectedSlot.id === slot.id;
                  return (
                    <div
                      key={slot.id}
                      onClick={() => slot.isAvailable && setSelectedSlot(slot)}
                      className={`p-3.5 rounded-xl border-2 cursor-pointer transition-all flex items-center justify-between ${
                        !slot.isAvailable
                          ? "opacity-50 border-gray-200 bg-gray-50 cursor-not-allowed"
                          : isSelected
                          ? "border-[#E11A22] bg-red-50/40 shadow-xs"
                          : "border-gray-200 hover:border-gray-300 bg-white"
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <Clock className={`w-4 h-4 ${isSelected ? "text-[#E11A22]" : "text-gray-400"}`} />
                        <div>
                          <p className="text-xs font-bold text-gray-900">{slot.name} Slot</p>
                          <p className="text-xs text-gray-600">{slot.time} • {slot.fee}</p>
                        </div>
                      </div>

                      {isSelected && (
                        <CheckCircle2 className="w-4 h-4 text-[#E11A22]" />
                      )}
                    </div>
                  );
                })}
              </div>

              <div className="mt-3.5 p-3 bg-emerald-50 border border-emerald-100 rounded-xl flex items-center gap-2 text-xs text-emerald-800">
                <Truck className="w-4 h-4 text-emerald-600 shrink-0" />
                <span className="font-semibold">All orders are delivered with zero contact & temperature checks</span>
              </div>
            </div>

            {/* 3. Payment Method Card */}
            <div className="bg-white rounded-2xl border border-gray-200/90 p-5 sm:p-6 shadow-2xs">
              <div className="flex items-center gap-2.5 mb-4">
                <div className="w-8 h-8 rounded-full bg-red-50 text-[#E11A22] font-black text-xs flex items-center justify-center">
                  3
                </div>
                <div>
                  <h2 className="text-base sm:text-lg font-black text-[#0A2540]">
                    Payment Method
                  </h2>
                  <p className="text-xs text-gray-500">
                    Choose your preferred payment method
                  </p>
                </div>
              </div>

              <div className="space-y-3">
                {/* Cash on Delivery */}
                <div
                  onClick={() => setPaymentMethod("Cash on Delivery")}
                  className={`p-4 rounded-xl border-2 cursor-pointer transition-all flex items-center justify-between ${
                    paymentMethod === "Cash on Delivery"
                      ? "border-[#E11A22] bg-red-50/40 shadow-xs"
                      : "border-gray-200 hover:border-gray-300 bg-white"
                  }`}
                >
                  <div className="flex items-center gap-3.5">
                    <div className="w-9 h-9 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
                      <Banknote className="w-5 h-5" />
                    </div>
                    <div>
                      <p className="text-sm font-bold text-gray-900">Cash on Delivery (COD)</p>
                      <p className="text-xs text-gray-500">Pay via cash or UPI to delivery executive at doorstep</p>
                    </div>
                  </div>
                  {paymentMethod === "Cash on Delivery" && (
                    <CheckCircle2 className="w-5 h-5 text-[#E11A22]" />
                  )}
                </div>

                {/* Razorpay Online */}
                <div
                  onClick={() => setPaymentMethod("Razorpay")}
                  className={`p-4 rounded-xl border-2 cursor-pointer transition-all flex items-center justify-between ${
                    paymentMethod === "Razorpay"
                      ? "border-[#E11A22] bg-red-50/40 shadow-xs"
                      : "border-gray-200 hover:border-gray-300 bg-white"
                  }`}
                >
                  <div className="flex items-center gap-3.5">
                    <div className="w-9 h-9 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center">
                      <CreditCard className="w-5 h-5" />
                    </div>
                    <div>
                      <p className="text-sm font-bold text-gray-900">UPI / Cards / Net Banking</p>
                      <p className="text-xs text-gray-500">Instant online checkout via Razorpay Gateway</p>
                    </div>
                  </div>
                  {paymentMethod === "Razorpay" && (
                    <CheckCircle2 className="w-5 h-5 text-[#E11A22]" />
                  )}
                </div>
              </div>
            </div>

          </div>

          {/* Right Column: Order Summary (4 cols) */}
          <div className="lg:col-span-4 space-y-4">
            
            <div className="bg-white rounded-2xl border border-gray-200/90 p-5 shadow-2xs space-y-4">
              <h2 className="font-black text-sm text-[#0A2540] uppercase tracking-wider">
                Order Summary ({cartCount} Items)
              </h2>

              {/* Items scroll */}
              <div className="max-h-60 overflow-y-auto divide-y divide-gray-100 pr-1">
                {cart.map(({ product, quantity }) => (
                  <div key={product.id} className="py-2.5 flex items-center justify-between gap-3 text-xs">
                    <div className="flex items-center gap-2.5 min-w-0">
                      <img
                        src={product.image}
                        alt={product.name}
                        className="w-10 h-10 object-contain rounded-lg border border-gray-100 p-0.5 bg-gray-50 shrink-0"
                      />
                      <div className="min-w-0">
                        <p className="font-bold text-gray-900 truncate max-w-[170px]">
                          {product.name}
                        </p>
                        <p className="text-[11px] text-gray-500">
                          {product.weight} × {quantity}
                        </p>
                      </div>
                    </div>

                    <span className="font-black text-gray-900 shrink-0">
                      ₹{product.price * quantity}
                    </span>
                  </div>
                ))}
              </div>

              {/* Price Breakdown */}
              <div className="space-y-2 text-xs border-t border-gray-100 pt-3">
                <div className="flex justify-between text-gray-600">
                  <span>Item Total</span>
                  <span className="font-semibold text-gray-900">₹{itemTotal}</span>
                </div>

                {discount > 0 && (
                  <div className="flex justify-between text-emerald-700">
                    <span>Catalogue Discount</span>
                    <span className="font-bold">- ₹{discount}</span>
                  </div>
                )}

                <div className="flex justify-between text-gray-600">
                  <span>Delivery Fee</span>
                  <span className="font-bold text-emerald-700 uppercase">
                    {deliveryFee === 0 ? "FREE" : `₹${deliveryFee}`}
                  </span>
                </div>

                <div className="flex justify-between items-baseline pt-2 border-t border-gray-200 text-base text-[#0A2540]">
                  <span className="font-black">Total Payable</span>
                  <span className="font-black text-2xl">₹{totalAmount}</span>
                </div>
              </div>

              {/* Place Order CTA */}
              <button
                onClick={handlePlaceOrder}
                disabled={isPlacing || isBelowMinOrder}
                className="w-full bg-[#E11A22] hover:bg-[#c8141b] disabled:bg-gray-400 text-white font-black py-4 px-6 rounded-xl flex items-center justify-center gap-2 shadow-md hover:shadow-lg transition-all cursor-pointer"
              >
                {isPlacing ? (
                  <span className="flex items-center gap-2">
                    <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    {paymentMethod === "Razorpay" ? "Opening Razorpay Gateway..." : "Placing Your Order..."}
                  </span>
                ) : !user.isVerified ? (
                  <>
                    <Lock className="w-4 h-4" />
                    <span>Login to Place Order • ₹{totalAmount}</span>
                  </>
                ) : paymentMethod === "Razorpay" ? (
                  <>
                    <CreditCard className="w-4 h-4" />
                    <span>Pay ₹{totalAmount} with Razorpay</span>
                    <ArrowRight className="w-4 h-4" />
                  </>
                ) : (
                  <>
                    <Banknote className="w-4 h-4" />
                    <span>Confirm COD Order • ₹{totalAmount}</span>
                    <ArrowRight className="w-4 h-4" />
                  </>
                )}
              </button>

              <div className="flex items-center justify-center gap-1.5 text-[11px] text-gray-500 text-center">
                <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
                <span>Zero Cancellation Fees until dispatch</span>
              </div>
            </div>

          </div>

        </div>
      </div>

      {/* Razorpay Interactive Gateway Modal */}
      <RazorpayPaymentModal
        isOpen={isRazorpayModalOpen}
        amount={totalAmount}
        customerName={selectedAddress?.fullName || user.name || "Customer"}
        customerPhone={selectedAddress?.phone || user.phone || "9876543210"}
        customerEmail={user.email}
        onSuccess={async (paymentId: string) => {
          setIsRazorpayModalOpen(false);
          try {
            confetti({ particleCount: 120, spread: 80, origin: { y: 0.6 } });
          } catch {}
          try {
            const order = await placeOrder("Razorpay", paymentId);
            router.push(`/orders/${order.id}`);
          } catch (err) {
            console.error("[Checkout] Order placement error:", err);
            setIsPlacing(false);
          }
        }}
        onClose={() => {
          setIsRazorpayModalOpen(false);
          setIsPlacing(false);
        }}
      />
    </div>
  );
}
