"use client";

import React, { useState, useEffect, useCallback } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { 
  CheckCircle2, 
  Clock, 
  Truck, 
  MapPin, 
  ShieldCheck, 
  ArrowLeft, 
  Package, 
  ChevronRight, 
  RotateCcw, 
  Receipt, 
  PhoneCall,
  Loader2,
  Box,
  CheckCircle
} from "lucide-react";
import { useApp } from "@/context/AppContext";
import { orderService } from "@/services/orders";
import { supabase } from "@/lib/supabase/client";
import { Order, CartItem } from "@/types";

export default function OrderDetailPage({
  params,
}: {
  params: { id: string } | Promise<{ id: string }>;
}) {
  const router = useRouter();
  const [resolvedId, setResolvedId] = useState<string>(() => {
    if (params && typeof params === "object" && "id" in params && typeof (params as any).id === "string") {
      return (params as any).id;
    }
    return "";
  });

  useEffect(() => {
    if (!resolvedId) {
      Promise.resolve(params).then((p) => {
        if (p?.id) setResolvedId(p.id);
      });
    }
  }, [params, resolvedId]);

  const { orders, addToCart } = useApp();
  const [dbOrder, setDbOrder] = useState<Order | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isUpdatingStatus, setIsUpdatingStatus] = useState(false);

  // Find order in AppContext or state or localStorage
  let contextOrder = orders.find(
    (o) => o.id === resolvedId || o.orderNumber === resolvedId
  );
  if (!contextOrder && typeof window !== "undefined") {
    try {
      const local = localStorage.getItem("kmart_orders");
      if (local) {
        const parsed = JSON.parse(local);
        if (Array.isArray(parsed)) {
          contextOrder = parsed.find(
            (o: Order) => o.id === resolvedId || o.orderNumber === resolvedId
          );
        }
      }
    } catch {}
  }
  const order = dbOrder || contextOrder;

  // Fetch directly from DB if not in AppContext
  const fetchOrderFromDb = useCallback(async (targetId: string) => {
    if (!targetId) return;
    setIsLoading(true);
    try {
      const { data, error } = await supabase
        .from('orders')
        .select(`
          *,
          order_items (
            *,
            products (
              id, name, mrp, selling_price, weight_unit, image_url, brand, description,
              categories ( name )
            )
          )
        `)
        .or(`id.eq.${targetId},order_number.eq.${targetId}`)
        .maybeSingle();

      if (data && !error) {
        const items: CartItem[] = (data.order_items || []).map((it: any) => {
          const p = it.products || {};
          return {
            product: {
              id: it.product_id,
              name: it.product_name || p.name || 'Grocery Item',
              category: p.categories?.name || 'Groceries',
              weight: p.weight_unit || '1 unit',
              price: Number(it.unit_selling_price || it.price || 0),
              originalPrice: Number(it.unit_mrp || p.mrp || 0),
              discountPercent: 0,
              rating: 4.8,
              reviewCount: 24,
              image: p.image_url || 'https://placehold.co/400x400?text=K+MART',
              inStock: true,
              stockCount: 50,
              brand: p.brand || 'K MART',
              deliveryTime: 'Delivery on time',
              description: p.description || '',
            },
            quantity: it.quantity,
          };
        });

        const addressSnapshot = data.delivery_address_snapshot || {};

        setDbOrder({
          id: data.id,
          orderNumber: data.order_number || `KM-${data.id.slice(0, 6).toUpperCase()}`,
          items,
          itemTotal: Number(data.subtotal || 0),
          discount: 0,
          deliveryFee: Number(data.delivery_fee || 0),
          totalAmount: Number(data.total || 0),
          deliveryAddress: addressSnapshot.line1 ? {
            id: addressSnapshot.id || 'snapshot',
            label: addressSnapshot.label || 'Home',
            fullName: addressSnapshot.full_name || addressSnapshot.name || 'Customer',
            phone: addressSnapshot.phone || '',
            line1: addressSnapshot.line1,
            line2: addressSnapshot.line2,
            city: addressSnapshot.city || 'Pune',
            state: addressSnapshot.state || 'Maharashtra',
            pincode: addressSnapshot.pincode || '',
            latitude: addressSnapshot.latitude || 0,
            longitude: addressSnapshot.longitude || 0,
          } : null,
          deliverySlot: {
            slotId: data.delivery_slot_id,
            time: '8:00 AM - 12:00 PM',
            day: data.scheduled_delivery_date || 'Scheduled',
            date: data.scheduled_delivery_date,
          },
          paymentMethod: data.payment_method === 'ONLINE' ? 'Razorpay' : 'Cash on Delivery',
          status: data.status || 'Order Confirmed',
          createdAt: data.created_at,
        });
      }
    } catch (err: any) {
      console.warn('[OrderDetailPage] error fetching order:', err?.message);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    if (resolvedId && !contextOrder) {
      fetchOrderFromDb(resolvedId);
    }
  }, [resolvedId, contextOrder, fetchOrderFromDb]);

  // Subscribe to real-time status updates from Supabase
  useEffect(() => {
    if (!resolvedId) return;

    const channel = supabase
      .channel(`order-${resolvedId}`)
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'orders',
          filter: `id=eq.${resolvedId}`,
        },
        (payload: any) => {
          if (payload?.new?.status) {
            setDbOrder((prev) => prev ? { ...prev, status: payload.new.status as any } : null);
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [resolvedId]);

  // Handler to advance stage in DB
  const handleUpdateStatus = async (newStatus: string) => {
    if (!order) return;
    setIsUpdatingStatus(true);
    try {
      const ok = await orderService.updateOrderStatus(order.id, newStatus);
      if (ok) {
        setDbOrder((prev) => prev ? { ...prev, status: newStatus as any } : { ...order, status: newStatus as any });
      }
    } catch (err) {
      console.error(err);
    } finally {
      setIsUpdatingStatus(false);
    }
  };

  const handleReorder = () => {
    if (!order) return;
    order.items.forEach((it) => {
      addToCart(it.product, it.quantity);
    });
    router.push("/cart");
  };

  if (isLoading) {
    return (
      <div className="min-h-[75vh] bg-[#F8F9FA] flex flex-col items-center justify-center px-4 py-16 text-center">
        <Loader2 className="w-10 h-10 text-[#E11A22] animate-spin mb-4" />
        <p className="text-sm font-bold text-gray-700">Loading order details...</p>
      </div>
    );
  }

  if (!order) {
    return (
      <div className="min-h-[75vh] bg-[#F8F9FA] flex flex-col items-center justify-center px-4 py-16 text-center">
        <div className="w-20 h-20 bg-red-50 text-[#E11A22] rounded-full flex items-center justify-center mb-4">
          <Package className="w-10 h-10" />
        </div>
        <h1 className="text-2xl font-black text-[#0A2540]">Order Not Found</h1>
        <p className="mt-2 text-sm text-gray-500 max-w-md">
          We couldn't find an order with reference #{resolvedId}.
        </p>
        <Link
          href="/orders"
          className="mt-6 px-6 py-2.5 rounded-xl bg-[#0A2540] text-white text-sm font-bold shadow-sm"
        >
          View All Orders
        </Link>
      </div>
    );
  }

  // -------------------------------------------------------------------------
  // Order Status Stages: Preparing → Packed → Out for Delivery → Delivered
  // -------------------------------------------------------------------------
  const normalized = (order.status || "").toUpperCase().replace(/[\s-]+/g, "_");

  const isPreparingOrMore = [
    "CONFIRMED", "ORDER_CONFIRMED", "PLACED", "PREPARING", "PACKED", "OUT_FOR_DELIVERY", "DELIVERED"
  ].includes(normalized);

  const isPackedOrMore = [
    "PACKED", "OUT_FOR_DELIVERY", "DELIVERED"
  ].includes(normalized);

  const isOutOrMore = [
    "OUT_FOR_DELIVERY", "DELIVERED"
  ].includes(normalized);

  const isDelivered = normalized === "DELIVERED";

  const currentActiveIndex = isDelivered ? 3 : isOutOrMore ? 2 : isPackedOrMore ? 1 : 0;

  const steps = [
    {
      step: 1,
      title: "Preparing",
      statusValue: "PREPARING",
      desc: "Order confirmed & items being picked at K MART Hub",
      icon: Clock,
      done: isPreparingOrMore,
      active: currentActiveIndex === 0,
    },
    {
      step: 2,
      title: "Packed",
      statusValue: "PACKED",
      desc: "Carton sealed, quality checked & sanitized",
      icon: Box,
      done: isPackedOrMore,
      active: currentActiveIndex === 1,
    },
    {
      step: 3,
      title: "Out for Delivery",
      statusValue: "OUT_FOR_DELIVERY",
      desc: "Delivery executive is on the way to your address",
      icon: Truck,
      done: isOutOrMore,
      active: currentActiveIndex === 2,
    },
    {
      step: 4,
      title: "Delivered",
      statusValue: "DELIVERED",
      desc: "Order handed over safely at your doorstep",
      icon: CheckCircle,
      done: isDelivered,
      active: currentActiveIndex === 3,
    },
  ];

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
            <Link href="/orders" className="hover:text-[#E11A22] transition-colors">
              Orders
            </Link>
            <ChevronRight className="w-3.5 h-3.5 text-gray-400" />
            <span className="font-semibold text-gray-900">#{order.orderNumber || order.id}</span>
          </div>

          <Link
            href="/orders"
            className="flex items-center gap-1 text-xs font-bold text-gray-600 hover:text-[#E11A22] transition-colors"
          >
            <ArrowLeft className="w-3.5 h-3.5" />
            <span>All Orders</span>
          </Link>
        </div>
      </div>

      <div className="max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 pt-6">
        
        {/* Header Banner */}
        <div className="bg-gradient-to-r from-[#0A2540] to-[#123154] text-white p-6 sm:p-8 rounded-2xl shadow-sm mb-6 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="bg-[#E11A22] text-white text-[11px] font-extrabold px-2.5 py-0.5 rounded-full uppercase tracking-wider">
                {order.status}
              </span>
              <span className="text-xs text-gray-300">
                Order Reference #{order.orderNumber || order.id}
              </span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-black">
              {isDelivered ? "Delivered to Doorstep" : "Delivery on time"}
            </h1>
            <p className="text-xs sm:text-sm text-gray-300 mt-1">
              Slot: {order.deliverySlot?.day || (order.deliverySlot as any)?.date || "Scheduled"} ({order.deliverySlot?.time})
            </p>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={handleReorder}
              className="bg-white/10 hover:bg-white/20 text-white font-bold text-xs px-4 py-2.5 rounded-xl transition-colors flex items-center gap-1.5 cursor-pointer"
            >
              <RotateCcw className="w-3.5 h-3.5" />
              <span>Reorder Basket</span>
            </button>
            <button
              onClick={() => alert(`Invoice generated for Order #${order.orderNumber || order.id}. Receipt downloaded.`)}
              className="bg-white text-[#0A2540] font-black text-xs px-4 py-2.5 rounded-xl transition-colors hover:bg-gray-100 flex items-center gap-1.5 cursor-pointer"
            >
              <Receipt className="w-3.5 h-3.5 text-[#E11A22]" />
              <span>Invoice</span>
            </button>
          </div>
        </div>

        {/* 4-Step Tracking Flow: Preparing → Packed → Out for Delivery → Delivered */}
        <div className="bg-white rounded-2xl border border-gray-200/90 p-6 shadow-2xs mb-6">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h2 className="font-black text-sm text-[#0A2540] uppercase tracking-wider">
                Live Order Tracking
              </h2>
              <p className="text-xs text-gray-500 mt-0.5">
                Real-time fulfillment stages from K MART fulfillment center
              </p>
            </div>

            {/* Quick Simulation / Advance Stage Pill */}
            <div className="flex items-center gap-1.5 bg-gray-50 border border-gray-200/80 p-1.5 rounded-xl">
              <span className="text-[10px] font-bold text-gray-500 uppercase px-1">Simulate Stage:</span>
              {steps.map((st) => (
                <button
                  key={st.step}
                  onClick={() => handleUpdateStatus(st.statusValue)}
                  disabled={isUpdatingStatus}
                  className={`text-[11px] font-bold px-2.5 py-1 rounded-lg transition-all cursor-pointer ${
                    st.active 
                      ? "bg-[#E11A22] text-white shadow-xs" 
                      : "text-gray-600 hover:bg-gray-200"
                  }`}
                >
                  {st.title}
                </button>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-4 gap-4 relative">
            {steps.map((step) => {
              const Icon = step.icon;
              return (
                <div key={step.step} className="flex flex-col items-center text-center relative z-10">
                  <div
                    className={`w-12 h-12 rounded-full flex items-center justify-center font-bold text-sm mb-2.5 transition-all ${
                      step.active
                        ? "bg-[#E11A22] text-white ring-4 ring-red-100 shadow-md animate-pulse"
                        : step.done
                        ? "bg-emerald-600 text-white shadow-sm"
                        : "bg-gray-100 text-gray-400 border border-gray-200"
                    }`}
                  >
                    {step.done ? <CheckCircle2 className="w-6 h-6" /> : <Icon className="w-5 h-5" />}
                  </div>

                  <div className="flex items-center gap-1">
                    <h3 className={`font-bold text-xs ${step.active ? "text-[#E11A22] font-black" : step.done ? "text-gray-900" : "text-gray-400"}`}>
                      {step.title}
                    </h3>
                    {step.active && (
                      <span className="w-2 h-2 rounded-full bg-[#E11A22] animate-ping" />
                    )}
                  </div>
                  <p className="text-[11px] text-gray-500 mt-1 max-w-[150px] leading-snug">
                    {step.desc}
                  </p>
                </div>
              );
            })}
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
          {/* Left: Items Breakdown (8 cols) */}
          <div className="lg:col-span-8 bg-white rounded-2xl border border-gray-200/90 p-5 sm:p-6 shadow-2xs space-y-4">
            <h2 className="font-black text-base text-[#0A2540] border-b border-gray-100 pb-3">
              Items Ordered ({order.items.length})
            </h2>

            <div className="divide-y divide-gray-100">
              {order.items.map(({ product, quantity }) => (
                <div key={product.id} className="py-3 flex items-center justify-between gap-4">
                  <div className="flex items-center gap-3">
                    <Link
                      href={`/product/${product.id}`}
                      className="w-14 h-14 rounded-xl bg-gray-50 border border-gray-100 p-1 flex items-center justify-center shrink-0"
                    >
                      <img
                        src={product.image}
                        alt={product.name}
                        className="max-h-full max-w-full object-contain"
                      />
                    </Link>

                    <div>
                      <span className="text-[10px] font-bold text-gray-400 uppercase">
                        {product.brand}
                      </span>
                      <Link
                        href={`/product/${product.id}`}
                        className="font-bold text-xs sm:text-sm text-gray-900 hover:text-[#E11A22] block leading-snug"
                      >
                        {product.name}
                      </Link>
                      <p className="text-[11px] text-gray-500">
                        {product.weight} • Qty: {quantity}
                      </p>
                    </div>
                  </div>

                  <div className="text-right">
                    <span className="font-extrabold text-sm text-[#0A2540] block">
                      ₹{product.price * quantity}
                    </span>
                    <span className="text-[10px] text-gray-400">
                      ₹{product.price} each
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Right: Address & Summary (4 cols) */}
          <div className="lg:col-span-4 space-y-4">
            {/* Delivery address details */}
            <div className="bg-white rounded-2xl border border-gray-200/90 p-5 shadow-2xs">
              <div className="flex items-center gap-2 mb-3">
                <MapPin className="w-4 h-4 text-[#E11A22]" />
                <h3 className="font-black text-xs text-[#0A2540] uppercase tracking-wider">
                  Delivery Destination
                </h3>
              </div>
              {order.deliveryAddress ? (
                <>
                  <p className="text-xs font-bold text-gray-900">
                    {order.deliveryAddress.fullName} ({order.deliveryAddress.label})
                  </p>
                  <p className="text-xs text-gray-600 mt-1 leading-relaxed">
                    {order.deliveryAddress.line1}{order.deliveryAddress.line2 ? `, ${order.deliveryAddress.line2}` : ''}, {order.deliveryAddress.city} - {order.deliveryAddress.pincode}
                  </p>
                  <p className="text-xs text-gray-500 mt-2 flex items-center gap-1.5">
                    <PhoneCall className="w-3.5 h-3.5 text-gray-400" />
                    <span>{order.deliveryAddress.phone}</span>
                  </p>
                </>
              ) : (
                <p className="text-xs text-gray-500 italic">No delivery address recorded</p>
              )}
            </div>

            {/* Payment & Invoice summary */}
            <div className="bg-white rounded-2xl border border-gray-200/90 p-5 shadow-2xs space-y-2.5 text-xs">
              <h3 className="font-black text-xs text-[#0A2540] uppercase tracking-wider mb-2">
                Payment Summary
              </h3>

              <div className="flex justify-between text-gray-600 items-center">
                <span>Payment Method</span>
                <span className="font-bold text-gray-900">{order.paymentMethod}</span>
              </div>

              <div className="flex justify-between text-gray-600 items-center">
                <span>Payment Status</span>
                <span className={`font-bold text-xs px-2 py-0.5 rounded ${
                  order.paymentMethod === 'Razorpay' 
                    ? 'text-emerald-700 bg-emerald-50' 
                    : 'text-amber-700 bg-amber-50'
                }`}>
                  {order.paymentMethod === 'Razorpay' ? 'PAID (Online via Razorpay)' : 'PENDING (Pay on Delivery)'}
                </span>
              </div>

              {order.paymentId && (
                <div className="flex justify-between text-gray-600 items-center">
                  <span>Payment Ref ID</span>
                  <span className="font-mono text-xs font-bold text-blue-700 bg-blue-50 px-2 py-0.5 rounded">
                    {order.paymentId}
                  </span>
                </div>
              )}

              <div className="flex justify-between text-gray-600">
                <span>Item Total</span>
                <span className="font-semibold text-gray-900">₹{order.itemTotal}</span>
              </div>

              <div className="flex justify-between text-emerald-700">
                <span>Discount</span>
                <span className="font-bold">- ₹{order.discount}</span>
              </div>

              <div className="flex justify-between text-gray-600">
                <span>Delivery Fee</span>
                <span className="font-bold text-emerald-700 uppercase">
                  {order.deliveryFee === 0 ? "FREE" : `₹${order.deliveryFee}`}
                </span>
              </div>

              <div className="flex justify-between items-baseline pt-2.5 border-t border-gray-200 text-sm text-[#0A2540]">
                <span className="font-black">Total Paid</span>
                <span className="font-black text-xl">₹{order.totalAmount}</span>
              </div>
            </div>

            <div className="p-3 bg-emerald-50 rounded-xl border border-emerald-100 flex items-center gap-2 text-xs text-emerald-800">
              <ShieldCheck className="w-4 h-4 text-emerald-600 shrink-0" />
              <span>Verified genuine order from authorized fulfillment center</span>
            </div>

          </div>
        </div>

      </div>
    </div>
  );
}
