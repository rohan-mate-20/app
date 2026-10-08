'use client';

import React from 'react';
import { 
  X, 
  Package, 
  MapPin, 
  Check, 
  ChevronRight, 
  ShoppingBag 
} from 'lucide-react';
import { useRouter } from 'next/navigation';
import { useApp } from '../context/AppContext';

export const OrdersModal: React.FC = () => {
  const router = useRouter();

  const { 
    isOrdersModalOpen, 
    setIsOrdersModalOpen, 
    orders, 
    setActiveConfirmedOrder 
  } = useApp();

  if (!isOrdersModalOpen) return null;

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-black/60 backdrop-blur-xs flex items-center justify-center p-3 sm:p-6 animate-fadeIn">
      <div className="bg-white w-full max-w-2xl rounded-2xl shadow-2xl overflow-hidden border border-gray-100 relative my-6 text-left max-h-[90vh] flex flex-col animate-modal-in">
        
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-100 flex items-center justify-between bg-gray-50/70">
          <div className="flex items-center gap-2.5">
            <Package className="w-5 h-5 text-[#0A2540]" />
            <h2 className="font-black text-lg text-[#0A2540]">
              My Orders & Live Tracking
            </h2>
          </div>

          <button
            onClick={() => setIsOrdersModalOpen(false)}
            className="w-8 h-8 rounded-full hover:bg-gray-200 text-gray-500 flex items-center justify-center cursor-pointer transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Orders list */}
        <div className="p-6 overflow-y-auto space-y-4 flex-1">
          {orders.length === 0 ? (
            <div className="py-12 text-center">
              <div className="w-16 h-16 rounded-full bg-blue-50 text-[#0A2540] flex items-center justify-center mx-auto mb-3">
                <ShoppingBag className="w-8 h-8" />
              </div>

              <h3 className="font-bold text-base text-gray-800">
                No Orders Placed Yet
              </h3>

              <p className="text-xs text-gray-500 mt-1 max-w-sm mx-auto">
                Once you complete your order checkout, you can track delivery updates live right here!
              </p>
            </div>
          ) : (
            orders.map((ord) => (
              <div 
                key={ord.id}
                onClick={() => {
                  setActiveConfirmedOrder(ord);
                  setIsOrdersModalOpen(false);
                  router.push(`/orders/${ord.id}`);
                }}
                className="p-4 rounded-xl border border-gray-200 hover:border-[#E11A22] hover:shadow-md transition-all cursor-pointer bg-white"
              >
                <div className="flex items-center justify-between border-b border-gray-100 pb-3 mb-3">
                  <div>
                    <span className="font-extrabold text-sm text-[#0A2540]">
                      Order #{ord.id}
                    </span>

                    <p className="text-[11px] text-gray-500 mt-0.5">
                      Placed at {ord.createdAt} • {ord.paymentMethod}
                    </p>
                  </div>

                  <span className="bg-emerald-50 text-emerald-800 font-bold text-xs px-2.5 py-1 rounded-md border border-emerald-200 flex items-center gap-1">
                    <Check className="w-3 h-3" />
                    {ord.status}
                  </span>
                </div>

                <div className="flex items-center justify-between text-xs">
                  <div className="space-y-1">
                    <p className="text-gray-600">
                      <strong>
                        {ord.items.length} {ord.items.length === 1 ? 'item' : 'items'}
                      </strong>{' '}
                      ({ord.items.map(i => i.product.name.split(' ')[0]).join(', ')})
                    </p>

                    <p className="text-gray-500 text-[11px] flex items-center gap-1">
                      <MapPin className="w-3 h-3 text-blue-500" />
                      <span>
                        {ord.deliveryAddress?.label} ({ord.deliverySlot?.time})
                      </span>
                    </p>
                  </div>

                  <div className="text-right">
                    <span className="font-black text-base text-[#0A2540] block">
                      ₹{ord.totalAmount}
                    </span>

                    <span className="text-[#E11A22] font-bold text-xs flex items-center gap-0.5 mt-0.5">
                      <span>Track Status</span>
                      <ChevronRight className="w-3.5 h-3.5" />
                    </span>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>

      </div>
    </div>
  );
};