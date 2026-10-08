'use client';

import React from 'react';
import { useRouter } from 'next/navigation';
import { 
  CheckCircle2, 
  MapPin, 
  Clock, 
  Package, 
  Truck, 
  ArrowRight,
  ShieldCheck
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Logo } from './Logo';

export const OrderSuccessModal: React.FC = () => {
  const router = useRouter();
  const { 
    activeConfirmedOrder, 
    setActiveConfirmedOrder, 
    setIsOrdersModalOpen 
  } = useApp();

  if (!activeConfirmedOrder) return null;

  const order = activeConfirmedOrder;

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-black/60 backdrop-blur-xs flex items-center justify-center p-3 sm:p-6 animate-fadeIn">
      <div className="bg-white w-full max-w-2xl rounded-2xl shadow-2xl overflow-hidden border border-gray-100 relative my-6 text-left flex flex-col max-h-[90vh] animate-modal-in">
        
        {/* Top Header */}
        <div className="px-6 py-4 border-b border-gray-100 flex items-center justify-between bg-white">
          <Logo size="md" />
          <span className="text-xs text-gray-500 font-medium">Order Confirmed</span>
        </div>

        {/* Modal Body */}
        <div className="p-6 overflow-y-auto space-y-6">
          <div className="text-center sm:text-left flex flex-col sm:flex-row items-center sm:items-start gap-4">
            <div className="w-14 h-14 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center shrink-0 shadow-xs">
              <CheckCircle2 className="w-8 h-8" />
            </div>
            <div>
              <h2 className="text-2xl font-black text-emerald-700 tracking-tight">
                Order Confirmed!
              </h2>
              <p className="text-xs sm:text-sm text-gray-600 mt-0.5">
                Thank you! Your order <strong className="text-gray-900">#{order.id}</strong> has been successfully placed.
              </p>
            </div>
          </div>

          {/* Delivery Status Card */}
          <div className="p-4 bg-emerald-50/70 border border-emerald-200/80 rounded-2xl space-y-3">
            <div className="flex items-center justify-between text-xs">
              <div className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-emerald-700" />
                <span className="font-extrabold text-emerald-900">
                  Estimated Delivery: Tomorrow, {order.deliverySlot.time}
                </span>
              </div>
              <span className="bg-emerald-200/70 text-emerald-900 font-bold px-2 py-0.5 rounded text-[10px]">
                ON SCHEDULE
              </span>
            </div>

            {order.deliveryAddress && (
              <div className="flex items-start gap-2.5 text-xs text-gray-700 pt-1">
                <MapPin className="w-4 h-4 text-[#E11A22] mt-0.5 shrink-0" />
                <div>
                  <span className="font-bold text-gray-900">{order.deliveryAddress.label}: </span>
                  <span>{order.deliveryAddress.line1}{order.deliveryAddress.line2 ? `, ${order.deliveryAddress.line2}` : ''}, {order.deliveryAddress.city} - {order.deliveryAddress.pincode}</span>
                </div>
              </div>
            )}
          </div>

          {/* Items Summary */}
          <div className="border border-gray-200 rounded-xl p-4 bg-gray-50/50 space-y-3">
            <div className="flex items-center justify-between text-xs font-bold text-gray-900 border-b border-gray-200 pb-2">
              <div className="flex items-center gap-1.5">
                <Package className="w-4 h-4 text-[#0A2540]" />
                <span>Ordered Items ({order.items.length})</span>
              </div>
              <span>Total Paid: ₹{order.totalAmount}</span>
            </div>

            <div className="space-y-2 max-h-48 overflow-y-auto pr-1">
              {order.items.map(({ product, quantity }) => (
                <div key={product.id} className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2.5 truncate">
                    <img src={product.image} alt={product.name} className="w-8 h-8 object-contain bg-white rounded border border-gray-200 p-0.5 shrink-0" />
                    <span className="font-medium text-gray-800 truncate max-w-[280px]">
                      {product.name} <span className="text-gray-400">× {quantity}</span>
                    </span>
                  </div>
                  <span className="font-bold text-gray-900 shrink-0">
                    ₹{product.price * quantity}
                  </span>
                </div>
              ))}
            </div>

            <div className="pt-2 border-t border-gray-200 flex items-center justify-between text-[11px] text-gray-500">
              <span>Payment Mode: <strong>{order.paymentMethod}</strong></span>
              {order.paymentId && <span>Ref: <code className="text-gray-700">{order.paymentId}</code></span>}
            </div>
          </div>

          {/* Security Banner */}
          <div className="p-3 bg-blue-50/80 border border-blue-100 rounded-xl flex items-center gap-2.5 text-xs text-blue-950">
            <ShieldCheck className="w-4 h-4 text-blue-600 shrink-0" />
            <span>We have sent your invoice and live delivery link to your registered mobile.</span>
          </div>

          {/* Buttons */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2">
            <button
              onClick={() => {
                const targetId = order.id;
                setActiveConfirmedOrder(null);
                router.push(`/orders/${targetId}`);
              }}
              className="bg-[#0A2540] hover:bg-[#123154] text-white font-bold py-3 rounded-xl flex items-center justify-center gap-2 text-xs sm:text-sm cursor-pointer shadow-sm transition-all"
            >
              <Truck className="w-4 h-4" />
              <span>Track Live Delivery</span>
            </button>

            <button
              onClick={() => setActiveConfirmedOrder(null)}
              className="bg-[#E11A22] hover:bg-[#c8141b] text-white font-bold py-3 rounded-xl flex items-center justify-center gap-2 text-xs sm:text-sm cursor-pointer shadow-md transition-all"
            >
              <span>Continue Shopping</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>

        </div>
      </div>
    </div>
  );
};
