'use client';

import React, { useState } from 'react';
import { 
  X, 
  ChevronLeft, 
  Check, 
  ShieldCheck, 
  MapPin, 
  Clock, 
  CreditCard, 
  Banknote, 
  ArrowRight, 
  Edit2, 
  Phone, 
  Mail, 
  User, 
  Plus 
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import confetti from 'canvas-confetti';
import { openRazorpayCheckout } from '../lib/razorpay';
import { RazorpayPaymentModal } from './RazorpayPaymentModal';

export const CheckoutModal: React.FC = () => {
  const { 
    isCheckoutOpen, 
    setIsCheckoutOpen, 
    checkoutStep, 
    setCheckoutStep,
    user,
    setUser,
    addresses,
    selectedAddress,
    setSelectedAddress,
    deliverySlots,
    selectedSlot,
    setSelectedSlot,
    cart,
    itemTotal,
    discount,
    deliveryFee,
    totalAmount,
    appliedCoupon,
    couponDiscount,
    placeOrder,
    setIsLocationOpen,
    setIsAuthOpen
  } = useApp();

  const [paymentMethod, setPaymentMethod] = useState<'Razorpay' | 'Cash on Delivery'>('Cash on Delivery');
  const [isProcessingPayment, setIsProcessingPayment] = useState(false);
  const [isRazorpayModalOpen, setIsRazorpayModalOpen] = useState(false);

  if (!isCheckoutOpen) return null;

  const steps = [
    { num: 1, label: 'Cart' },
    { num: 2, label: 'Your Details' },
    { num: 3, label: 'Delivery' },
    { num: 4, label: 'Review' },
    { num: 5, label: 'Payment' }
  ];

  const handleFinishPayment = async () => {
    if (!user.isVerified) {
      setIsCheckoutOpen(false);
      setIsAuthOpen(true);
      return;
    }

    if (paymentMethod === 'Cash on Delivery') {
      setIsProcessingPayment(true);
      setTimeout(async () => {
        setIsProcessingPayment(false);
        try {
          confetti({ particleCount: 100, spread: 70, origin: { y: 0.6 } });
        } catch {}
        await placeOrder('Cash on Delivery');
      }, 700);
      return;
    }

    // Razorpay checkout
    const rzpOpened = await openRazorpayCheckout({
      amount: totalAmount,
      customerName: user.name || 'Customer',
      customerPhone: user.phone || '9876543210',
      customerEmail: user.email || '',
      description: 'K MART Groceries Order',
      onSuccess: async (paymentId) => {
        try {
          confetti({ particleCount: 120, spread: 80, origin: { y: 0.6 } });
        } catch {}
        await placeOrder('Razorpay', paymentId);
      },
      onDismiss: () => {
        console.log('Razorpay modal dismissed');
      },
    });

    if (!rzpOpened) {
      setIsRazorpayModalOpen(true);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
      <div className="bg-white rounded-2xl w-full max-w-xl max-h-[90vh] flex flex-col shadow-2xl overflow-hidden animate-in fade-in zoom-in duration-200">
        
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
          <div className="flex items-center gap-2">
            {checkoutStep > 1 && (
              <button
                onClick={() => setCheckoutStep(checkoutStep - 1)}
                className="p-1 hover:bg-gray-100 rounded-lg text-gray-500 cursor-pointer"
              >
                <ChevronLeft className="w-5 h-5" />
              </button>
            )}
            <h2 className="font-black text-lg text-[#0A2540]">Checkout</h2>
          </div>
          <button
            onClick={() => setIsCheckoutOpen(false)}
            className="p-1 hover:bg-gray-100 rounded-lg text-gray-400 hover:text-gray-600 cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Stepper */}
        <div className="px-6 py-3 bg-gray-50 border-b border-gray-100 flex items-center justify-between text-xs">
          {steps.map((s) => (
            <div key={s.num} className="flex items-center gap-1.5">
              <div
                className={`w-5 h-5 rounded-full flex items-center justify-center text-[11px] font-bold ${
                  checkoutStep === s.num
                    ? 'bg-[#E11A22] text-white'
                    : checkoutStep > s.num
                    ? 'bg-emerald-600 text-white'
                    : 'bg-gray-200 text-gray-600'
                }`}
              >
                {checkoutStep > s.num ? <Check className="w-3 h-3" /> : s.num}
              </div>
              <span className={`hidden sm:inline ${checkoutStep === s.num ? 'font-bold text-gray-900' : 'text-gray-500'}`}>
                {s.label}
              </span>
            </div>
          ))}
        </div>

        {/* Content Body */}
        <div className="p-6 overflow-y-auto flex-1 space-y-4">
          
          {/* STEP 1: Cart Items Review */}
          {checkoutStep === 1 && (
            <div className="space-y-3">
              <h3 className="font-bold text-sm text-gray-800">Your Basket ({cart.length} items)</h3>
              <div className="divide-y divide-gray-100">
                {cart.map(({ product, quantity }) => (
                  <div key={product.id} className="py-2.5 flex items-center justify-between gap-3 text-xs">
                    <div className="flex items-center gap-2.5 min-w-0">
                      <img src={product.image} alt={product.name} className="w-10 h-10 object-contain rounded-lg border border-gray-100 p-0.5 bg-gray-50 shrink-0" />
                      <div className="min-w-0">
                        <p className="font-bold text-gray-900 truncate">{product.name}</p>
                        <p className="text-[11px] text-gray-500">{product.weight} × {quantity}</p>
                      </div>
                    </div>
                    <span className="font-black text-gray-900 shrink-0">₹{product.price * quantity}</span>
                  </div>
                ))}
              </div>
              <button
                onClick={() => setCheckoutStep(2)}
                className="w-full mt-4 bg-[#E11A22] hover:bg-[#c8141b] text-white font-bold py-3.5 rounded-xl flex items-center justify-center gap-2 cursor-pointer shadow-sm"
              >
                <span>Proceed to Details</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          )}

          {/* STEP 2: Customer Details */}
          {checkoutStep === 2 && (
            <div className="space-y-4">
              <div className="bg-blue-50 border border-blue-100 rounded-xl p-3 flex items-center gap-3">
                <ShieldCheck className="w-5 h-5 text-blue-600 shrink-0" />
                <p className="text-xs text-blue-950 font-medium">
                  We use your details to share order dispatch and delivery status updates.
                </p>
              </div>

              <div className="space-y-3 text-xs">
                <div>
                  <label className="block font-bold text-gray-700 mb-1">Full Name</label>
                  <div className="relative">
                    <User className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      value={user.name}
                      onChange={(e) => setUser({ ...user, name: e.target.value })}
                      placeholder="Enter full name"
                      className="w-full pl-9 pr-3 py-2.5 bg-white border border-gray-300 rounded-lg"
                    />
                  </div>
                </div>

                <div>
                  <label className="block font-bold text-gray-700 mb-1">Phone Number</label>
                  <div className="relative">
                    <Phone className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      value={user.phone}
                      onChange={(e) => setUser({ ...user, phone: e.target.value })}
                      placeholder="Enter 10-digit phone"
                      className="w-full pl-9 pr-3 py-2.5 bg-white border border-gray-300 rounded-lg"
                    />
                  </div>
                </div>

                <div>
                  <label className="block font-bold text-gray-700 mb-1">Email (Optional)</label>
                  <div className="relative">
                    <Mail className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="email"
                      value={user.email || ''}
                      onChange={(e) => setUser({ ...user, email: e.target.value })}
                      placeholder="Enter email"
                      className="w-full pl-9 pr-3 py-2.5 bg-white border border-gray-300 rounded-lg"
                    />
                  </div>
                </div>
              </div>

              {!user.isVerified && (
                <div className="bg-red-50 border border-red-200 rounded-xl p-3.5 flex flex-col gap-2">
                  <div className="flex items-center gap-2 text-xs font-black text-[#E11A22]">
                    <ShieldCheck className="w-4 h-4" />
                    <span>Login Required to Place Order</span>
                  </div>
                  <p className="text-[11px] text-gray-600">
                    Please log in with OTP to verify your mobile number and confirm your order.
                  </p>
                  <button
                    type="button"
                    onClick={() => {
                      setIsCheckoutOpen(false);
                      setIsAuthOpen(true);
                    }}
                    className="w-full bg-[#0A2540] hover:bg-[#123154] text-white font-bold py-2 rounded-lg text-xs transition-colors cursor-pointer"
                  >
                    Login with Mobile OTP
                  </button>
                </div>
              )}

              <button
                onClick={() => {
                  if (!user.isVerified) {
                    setIsCheckoutOpen(false);
                    setIsAuthOpen(true);
                    return;
                  }
                  setCheckoutStep(3);
                }}
                className="w-full bg-[#E11A22] hover:bg-[#c8141b] text-white font-bold py-3.5 rounded-xl flex items-center justify-center gap-2 cursor-pointer shadow-sm"
              >
                <span>{!user.isVerified ? 'Login to Continue' : 'Proceed to Delivery Slot'}</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          )}

          {/* STEP 3: Delivery Address & Slot Selection */}
          {checkoutStep === 3 && (
            <div className="space-y-4">
              <div>
                <div className="flex items-center justify-between mb-2">
                  <h3 className="text-xs font-bold text-gray-800 uppercase tracking-wider">Delivery Address</h3>
                  <button
                    onClick={() => {
                      setIsCheckoutOpen(false);
                      setIsLocationOpen(true);
                    }}
                    className="text-xs font-bold text-[#E11A22] hover:underline flex items-center gap-1 cursor-pointer"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>Manage / Add</span>
                  </button>
                </div>

                <div className="space-y-2">
                  {addresses.length > 0 ? (
                    addresses.map((addr) => {
                      const isSelected = selectedAddress?.id === addr.id;
                      return (
                        <div
                          key={addr.id}
                          onClick={() => setSelectedAddress(addr)}
                          className={`p-3 rounded-xl border-2 transition-all cursor-pointer flex items-center justify-between text-xs ${
                            isSelected ? 'border-[#E11A22] bg-red-50/20 shadow-xs' : 'border-gray-200 bg-white'
                          }`}
                        >
                          <div>
                            <span className="font-bold text-gray-900 block">{addr.label} • {addr.fullName}</span>
                            <span className="text-gray-600">{addr.line1}{addr.line2 ? `, ${addr.line2}` : ''}, {addr.city} - {addr.pincode}</span>
                          </div>
                          {isSelected && <Check className="w-4 h-4 text-[#E11A22]" />}
                        </div>
                      );
                    })
                  ) : (
                    <div className="p-3 bg-amber-50 rounded-xl border border-amber-200 text-xs text-amber-900">
                      No saved addresses. Please click Manage / Add above.
                    </div>
                  )}
                </div>
              </div>

              {/* Delivery Slots from DB */}
              <div>
                <h3 className="text-xs font-bold text-gray-800 uppercase tracking-wider mb-2">Select Delivery Slot</h3>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                  {deliverySlots.map((slot) => {
                    const isSelected = selectedSlot?.id === slot.id;
                    return (
                      <div
                        key={slot.id}
                        onClick={() => slot.isAvailable && setSelectedSlot(slot)}
                        className={`p-3 rounded-xl border-2 transition-all cursor-pointer flex items-center justify-between text-xs ${
                          !slot.isAvailable
                            ? 'opacity-50 border-gray-200 bg-gray-50 cursor-not-allowed'
                            : isSelected
                            ? 'border-[#E11A22] bg-red-50/20 shadow-xs'
                            : 'border-gray-200 bg-white'
                        }`}
                      >
                        <div className="flex items-center gap-2">
                          <Clock className={`w-4 h-4 ${isSelected ? 'text-[#E11A22]' : 'text-gray-400'}`} />
                          <div>
                            <p className="font-bold text-gray-900">{slot.name} Slot</p>
                            <p className="text-[11px] text-gray-500">{slot.time}</p>
                          </div>
                        </div>
                        {isSelected && <Check className="w-4 h-4 text-[#E11A22]" />}
                      </div>
                    );
                  })}
                </div>
              </div>

              <button
                onClick={() => setCheckoutStep(4)}
                disabled={!selectedAddress}
                className="w-full bg-[#E11A22] hover:bg-[#c8141b] disabled:bg-gray-300 text-white font-bold py-3.5 rounded-xl flex items-center justify-center gap-2 cursor-pointer shadow-sm"
              >
                <span>Review Order</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          )}

          {/* STEP 4: Review Summary */}
          {checkoutStep === 4 && (
            <div className="space-y-4 text-xs">
              <div className="p-4 bg-gray-50 rounded-xl border border-gray-200 space-y-2">
                <div className="flex justify-between font-bold text-gray-900 pb-2 border-b border-gray-200">
                  <span>Deliver To:</span>
                  <span className="text-[#E11A22]">{selectedAddress?.label}</span>
                </div>
                <p className="text-gray-700">{selectedAddress?.fullName} • {selectedAddress?.phone}</p>
                <p className="text-gray-600">{selectedAddress?.line1}{selectedAddress?.line2 ? `, ${selectedAddress?.line2}` : ''}, {selectedAddress?.city} - {selectedAddress?.pincode}</p>
                <p className="text-gray-600 pt-1 border-t border-gray-200">
                  <strong>Slot:</strong> {selectedSlot.name} ({selectedSlot.time})
                </p>
              </div>

              <div className="p-4 bg-gray-50 rounded-xl border border-gray-200 space-y-2">
                <h4 className="font-bold text-gray-900 uppercase text-[11px]">Bill Details</h4>
                <div className="flex justify-between text-gray-600">
                  <span>Item Total</span>
                  <span>₹{itemTotal}</span>
                </div>
                <div className="flex justify-between text-emerald-700">
                  <span>Discount</span>
                  <span>- ₹{appliedCoupon ? couponDiscount : discount}</span>
                </div>
                <div className="flex justify-between text-gray-600">
                  <span>Delivery Fee</span>
                  <span className="font-bold text-emerald-700">{deliveryFee === 0 ? 'FREE' : `₹${deliveryFee}`}</span>
                </div>
                <div className="flex justify-between items-baseline pt-2 border-t border-gray-200 text-base text-[#0A2540] font-black">
                  <span>Total Payable</span>
                  <span>₹{totalAmount}</span>
                </div>
              </div>

              <button
                onClick={() => setCheckoutStep(5)}
                className="w-full bg-[#E11A22] hover:bg-[#c8141b] text-white font-bold py-3.5 rounded-xl flex items-center justify-center gap-2 cursor-pointer shadow-sm"
              >
                <span>Proceed to Payment</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          )}

          {/* STEP 5: Payment Method */}
          {checkoutStep === 5 && (
            <div className="space-y-4">
              <h3 className="font-bold text-sm text-gray-800">Select Payment Method</h3>
              
              <div className="space-y-2.5">
                <div
                  onClick={() => setPaymentMethod('Cash on Delivery')}
                  className={`p-4 rounded-xl border-2 transition-all cursor-pointer flex items-center justify-between ${
                    paymentMethod === 'Cash on Delivery' ? 'border-[#E11A22] bg-red-50/20' : 'border-gray-200 bg-white'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <Banknote className="w-5 h-5 text-emerald-600" />
                    <div>
                      <p className="text-xs font-bold text-gray-900">Cash on Delivery (COD)</p>
                      <p className="text-[11px] text-gray-500">Pay cash or UPI at delivery doorstep</p>
                    </div>
                  </div>
                  {paymentMethod === 'Cash on Delivery' && <Check className="w-4 h-4 text-[#E11A22]" />}
                </div>

                <div
                  onClick={() => setPaymentMethod('Razorpay')}
                  className={`p-4 rounded-xl border-2 transition-all cursor-pointer flex items-center justify-between ${
                    paymentMethod === 'Razorpay' ? 'border-[#E11A22] bg-red-50/20' : 'border-gray-200 bg-white'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <CreditCard className="w-5 h-5 text-blue-600" />
                    <div>
                      <p className="text-xs font-bold text-gray-900">Online Payment (Razorpay)</p>
                      <p className="text-[11px] text-gray-500">UPI, Cards, Netbanking</p>
                    </div>
                  </div>
                  {paymentMethod === 'Razorpay' && <Check className="w-4 h-4 text-[#E11A22]" />}
                </div>
              </div>

              <button
                onClick={handleFinishPayment}
                disabled={isProcessingPayment}
                className="w-full bg-[#E11A22] hover:bg-[#c8141b] text-white font-bold py-4 rounded-xl flex items-center justify-center gap-2 cursor-pointer shadow-md"
              >
                {isProcessingPayment ? (
                  <span>Processing...</span>
                ) : (
                  <span>Confirm & Place Order • ₹{totalAmount}</span>
                )}
              </button>
            </div>
          )}

        </div>

      </div>

      <RazorpayPaymentModal
        isOpen={isRazorpayModalOpen}
        onClose={() => setIsRazorpayModalOpen(false)}
        amount={totalAmount}
        customerName={user.name || 'Customer'}
        customerPhone={user.phone || '9876543210'}
        customerEmail={user.email}
        onSuccess={async (paymentId) => {
          setIsRazorpayModalOpen(false);
          try {
            confetti({ particleCount: 100, spread: 70, origin: { y: 0.6 } });
          } catch {}
          await placeOrder('Razorpay', paymentId);
        }}
      />
    </div>
  );
};
