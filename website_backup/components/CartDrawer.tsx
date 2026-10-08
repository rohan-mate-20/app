'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { 
  X, 
  Trash2, 
  Plus, 
  Minus, 
  Tag, 
  ArrowRight, 
  Check, 
  Truck, 
  ShoppingBag,
  Percent,
  Lock 
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { COUPONS } from '../data/mockData';

export const CartDrawer: React.FC = () => {
  const router = useRouter();
  const { 
    isCartOpen, 
    setIsCartOpen, 
    cart, 
    cartCount, 
    updateQuantity, 
    removeFromCart, 
    clearCart,
    itemTotal,
    discount,
    deliveryFee,
    totalAmount,
    appliedCoupon,
    couponDiscount,
    applyCoupon,
    removeCoupon,
    setIsCheckoutOpen,
    setCheckoutStep,
    setIsLocationOpen,
    user,
    setIsAuthOpen
  } = useApp();

  const [couponInput, setCouponInput] = useState('');
  const [couponMessage, setCouponMessage] = useState<{ text: string; isError: boolean } | null>(null);

  // Close on Escape key press (called unconditionally before early return)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setIsCartOpen(false);
      }
    };
    if (isCartOpen) {
      window.addEventListener('keydown', handleKeyDown);
    }
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isCartOpen, setIsCartOpen]);

  if (!isCartOpen) return null;

  const handleApplyCoupon = (codeToApply?: string) => {
    const code = codeToApply || couponInput;
    if (!code) return;
    const res = applyCoupon(code);
    setCouponMessage({
      text: res.message,
      isError: !res.success
    });
    if (res.success) {
      setCouponInput('');
    }
    setTimeout(() => setCouponMessage(null), 4000);
  };

  const handleProceedToCheckout = () => {
    setIsCartOpen(false);
    if (!user.isVerified) {
      setIsAuthOpen(true);
    } else {
      router.push('/checkout');
    }
  };

  return (
    <div className="fixed inset-0 z-50 overflow-hidden flex justify-end animate-fadeIn">
      {/* Click outside backdrop to close */}
      <div 
        onClick={() => setIsCartOpen(false)}
        className="fixed inset-0 bg-black/60 backdrop-blur-xs transition-opacity cursor-pointer"
        aria-label="Close cart backdrop"
      />

      {/* Drawer Container */}
      <div 
        onClick={(e) => e.stopPropagation()}
        className="relative z-10 w-full max-w-md bg-white h-full shadow-2xl flex flex-col justify-between animate-slide-in-right text-left"
      >
        
        {/* Header */}
        <div className="px-5 py-4 border-b border-gray-100 flex items-center justify-between bg-gray-50/50">
          <div className="flex items-center gap-3">
            <button
              onClick={() => setIsCartOpen(false)}
              className="w-8 h-8 rounded-full hover:bg-gray-200 text-gray-600 flex items-center justify-center cursor-pointer transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
            <div>
              <h2 className="font-black text-lg text-[#0A2540] leading-none">
                My Cart
              </h2>
              <span className="text-xs text-gray-500 font-medium">
                {cartCount} {cartCount === 1 ? 'item' : 'items'}
              </span>
            </div>
          </div>

          {cart.length > 0 && (
            <button
              onClick={clearCart}
              className="text-xs font-bold text-gray-400 hover:text-red-600 flex items-center gap-1 transition-colors cursor-pointer"
            >
              <Trash2 className="w-3.5 h-3.5" />
              <span>Clear</span>
            </button>
          )}
        </div>

        {/* Scrollable Body */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          
          {/* Delivery threshold indicator */}
          <div className="p-3 bg-emerald-50 rounded-xl border border-emerald-100 flex items-center gap-2.5 text-xs text-emerald-900">
          </div>

          {/* Cart Empty State */}
          {cart.length === 0 ? (
            <div className="py-20 text-center space-y-3">
              <div className="w-16 h-16 rounded-full bg-red-50 text-[#E11A22] flex items-center justify-center mx-auto">
                <ShoppingBag className="w-8 h-8" />
              </div>
              <h3 className="font-extrabold text-base text-gray-900">Your cart is empty</h3>
              <p className="text-xs text-gray-500 max-w-xs mx-auto">
                Your basket looks a bit lonely! Explore staples, snacks, dairy and daily essentials.
              </p>
              <button
                onClick={() => setIsCartOpen(false)}
                className="bg-[#E11A22] text-white font-bold text-xs px-5 py-2.5 rounded-xl hover:bg-[#c8141b] transition-all cursor-pointer shadow-sm"
              >
                Start Shopping
              </button>
            </div>
          ) : (
            <>
              {/* Items List */}
              <div className="space-y-3">
                {cart.map(({ product, quantity }) => (
                  <div 
                    key={product.id}
                    className="p-3 bg-white rounded-xl border border-gray-200/90 shadow-2xs flex items-center justify-between gap-3"
                  >
                    <img
                      src={product.image}
                      alt={product.name}
                      className="w-14 h-14 object-contain bg-white rounded-lg border border-gray-100 p-1 shrink-0"
                    />

                    <div className="flex-1 min-w-0">
                      <h4 className="font-bold text-xs text-gray-900 truncate leading-snug">
                        {product.name}
                      </h4>
                      <p className="text-[11px] text-gray-500">{product.weight}</p>
                      
                      <div className="flex items-baseline gap-1.5 mt-1">
                        <span className="font-black text-xs text-[#0A2540]">
                          ₹{product.price * quantity}
                        </span>
                        {product.originalPrice > product.price && (
                          <span className="text-[10px] text-gray-400 line-through">
                            ₹{product.originalPrice * quantity}
                          </span>
                        )}
                      </div>
                    </div>

                    {/* Quantity controls */}
                    <div className="flex items-center bg-gray-100 rounded-lg px-1 py-1">
                      <button
                        onClick={() => updateQuantity(product.id, quantity - 1)}
                        className="w-5 h-5 flex items-center justify-center hover:bg-gray-200 rounded text-gray-700 cursor-pointer"
                        aria-label="Decrease"
                      >
                        <Minus className="w-3 h-3" />
                      </button>
                      <span className="w-6 text-center font-black text-xs text-gray-900 select-none">
                        {quantity}
                      </span>
                      <button
                        onClick={() => updateQuantity(product.id, quantity + 1)}
                        className="w-5 h-5 flex items-center justify-center hover:bg-gray-200 rounded text-gray-700 cursor-pointer"
                        aria-label="Increase"
                      >
                        <Plus className="w-3 h-3" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>

              {/* Apply Coupon Box */}
              <div className="p-3 bg-gray-50 rounded-xl border border-gray-200">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-1.5 text-xs font-bold text-gray-800">
                    <Tag className="w-3.5 h-3.5 text-[#E11A22]" />
                    <span>Apply Coupon</span>
                  </div>
                  {appliedCoupon && (
                    <button
                      onClick={removeCoupon}
                      className="text-[10px] font-bold text-red-600 hover:underline cursor-pointer"
                    >
                      Remove
                    </button>
                  )}
                </div>

                <div className="flex gap-2">
                  <input
                    type="text"
                    value={couponInput}
                    onChange={(e) => setCouponInput(e.target.value.toUpperCase())}
                    placeholder="Enter coupon code (e.g. KMART45)"
                    className="flex-1 px-3 py-2 text-xs bg-white rounded-lg border border-gray-300 focus:outline-none focus:border-[#E11A22]"
                  />
                  <button
                    onClick={() => handleApplyCoupon()}
                    className="bg-[#0A2540] hover:bg-[#123154] text-white px-3 py-2 rounded-lg font-bold text-xs cursor-pointer"
                  >
                    Apply
                  </button>
                </div>

                {/* Available quick coupon tags */}
                <div className="mt-2.5 flex flex-wrap gap-1.5">
                  {COUPONS.map((c) => (
                    <button
                      key={c.code}
                      onClick={() => handleApplyCoupon(c.code)}
                      className={`text-[10px] font-bold px-2 py-0.5 rounded-full border transition-all cursor-pointer flex items-center gap-1 ${
                        appliedCoupon === c.code
                          ? 'bg-red-50 border-red-300 text-[#E11A22]'
                          : 'bg-white border-gray-200 text-gray-600 hover:border-gray-300'
                      }`}
                    >
                      <Percent className="w-2.5 h-2.5" />
                      <span>{c.code}</span>
                    </button>
                  ))}
                </div>

                {couponMessage && (
                  <p className={`text-[11px] font-bold mt-2 ${couponMessage.isError ? 'text-red-600' : 'text-emerald-700'}`}>
                    {couponMessage.text}
                  </p>
                )}
              </div>

              {/* Bill Summary Details */}
              <div className="p-4 bg-gray-50/80 rounded-xl border border-gray-200/80 space-y-2 text-xs">
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
                  <span>{deliveryFee === 0 ? <strong className="text-emerald-700">FREE</strong> : `₹${deliveryFee}`}</span>
                </div>
                <div className="border-t border-gray-200 pt-2 flex justify-between font-black text-sm text-[#0A2540]">
                  <span>To Pay</span>
                  <span className="text-base">₹{totalAmount}</span>
                </div>
              </div>
            </>
          )}

        </div>

        {/* Bottom Checkout CTA */}
        {cart.length > 0 && (
          <div className="p-4 border-t border-gray-100 bg-white shadow-lg space-y-2">
            <div className="flex items-center justify-between text-xs font-bold text-gray-700">
              <span>Grand Total</span>
              <span className="text-base font-black text-[#0A2540]">₹{totalAmount}</span>
            </div>

            <button
              onClick={handleProceedToCheckout}
              className="w-full bg-[#E11A22] hover:bg-[#c8141b] text-white font-black py-3.5 rounded-xl flex items-center justify-center gap-2 shadow-md hover:shadow-lg transition-all cursor-pointer text-sm"
            >
              {!user.isVerified ? (
                <>
                  <Lock className="w-4 h-4" />
                  <span>Login to Checkout</span>
                </>
              ) : (
                <>
                  <span>Proceed to Checkout</span>
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>

            <button
              onClick={() => {
                setIsCartOpen(false);
                router.push('/cart');
              }}
              className="w-full text-center text-xs font-bold text-gray-600 hover:text-[#E11A22] py-1 cursor-pointer transition-colors"
            >
              View Full Cart Page &rarr;
            </button>
          </div>
        )}

      </div>
    </div>
  );
};
