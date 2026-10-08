"use client";

import React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { 
  Package, 
  Clock, 
  CheckCircle2, 
  Truck, 
  RotateCcw, 
  ChevronRight, 
  ShoppingBag,
  ArrowRight
} from "lucide-react";
import { useApp } from "@/context/AppContext";
import { Order } from "@/types";

export default function OrderHistoryPage() {
  const router = useRouter();
  const { orders, addToCart } = useApp();

  const handleReorder = (order: Order) => {
    order.items.forEach((it) => {
      addToCart(it.product, it.quantity);
    });
    router.push("/cart");
  };

  const getStatusBadge = (status: Order["status"] | string) => {
    const s = (status || "").toUpperCase().replace(/[\s-]+/g, "_");
    switch (s) {
      case "ORDER_CONFIRMED":
      case "CONFIRMED":
      case "PLACED":
      case "CREATED":
        return <span className="bg-blue-50 text-blue-700 border border-blue-200 px-2.5 py-0.5 rounded-full text-xs font-bold">Order Confirmed</span>;
      case "PREPARING":
        return <span className="bg-amber-50 text-amber-800 border border-amber-200 px-2.5 py-0.5 rounded-full text-xs font-bold">Preparing</span>;
      case "PACKED":
      case "PROCESSING":
        return <span className="bg-indigo-50 text-indigo-700 border border-indigo-200 px-2.5 py-0.5 rounded-full text-xs font-bold">Packed</span>;
      case "OUT_FOR_DELIVERY":
        return <span className="bg-purple-50 text-purple-700 border border-purple-200 px-2.5 py-0.5 rounded-full text-xs font-bold">Out for Delivery</span>;
      case "DELIVERED":
        return <span className="bg-emerald-50 text-emerald-700 border border-emerald-200 px-2.5 py-0.5 rounded-full text-xs font-bold">Delivered</span>;
      default:
        return <span className="bg-gray-100 text-gray-700 px-2.5 py-0.5 rounded-full text-xs font-bold">{status}</span>;
    }
  };

  if (orders.length === 0) {
    return (
      <div className="min-h-[75vh] bg-[#F8F9FA] flex flex-col items-center justify-center px-4 py-16 text-center">
        <div className="w-24 h-24 bg-red-50 text-[#E11A22] rounded-full flex items-center justify-center mb-5 shadow-inner">
          <Package className="w-12 h-12" />
        </div>
        <h1 className="text-2xl sm:text-3xl font-black text-[#0A2540]">No Orders Yet</h1>
        <p className="mt-2 text-sm text-gray-500 max-w-md">
          You haven't placed any orders with K MART yet. Start filling your cart with fresh daily essentials!
        </p>
        <Link
          href="/categories"
          className="mt-6 px-6 py-3 rounded-xl bg-[#E11A22] hover:bg-[#c8141b] text-white text-sm font-bold shadow-sm transition-all inline-flex items-center gap-2"
        >
          <span>Explore Grocery Items</span>
          <ChevronRight className="w-4 h-4" />
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
            <span className="font-semibold text-gray-900">My Orders</span>
          </div>

          <Link
            href="/categories"
            className="text-xs font-bold text-[#E11A22] hover:underline"
          >
            Shop More
          </Link>
        </div>
      </div>

      <div className="max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 pt-6">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-2xl sm:text-3xl font-black text-[#0A2540] tracking-tight">
              Order History & Tracking
            </h1>
            <p className="text-xs sm:text-sm text-gray-500 mt-0.5">
              Check delivery progress, invoices and reorder previous grocery baskets
            </p>
          </div>
        </div>

        <div className="space-y-4">
          {orders.map((order) => (
            <div
              key={order.id}
              className="bg-white rounded-2xl border border-gray-200/90 shadow-2xs p-5 sm:p-6 transition-all hover:border-gray-300"
            >
              {/* Order Header */}
              <div className="flex flex-wrap items-center justify-between gap-3 pb-4 border-b border-gray-100">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-red-50 text-[#E11A22] flex items-center justify-center font-bold">
                    <Package className="w-5 h-5" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-black text-sm text-[#0A2540]">
                        Order #{order.id}
                      </span>
                      {getStatusBadge(order.status)}
                    </div>
                    <p className="text-xs text-gray-500 mt-0.5">
                      Placed on {new Date(order.createdAt).toLocaleDateString("en-IN", {
                        day: "numeric",
                        month: "short",
                        year: "numeric",
                        hour: "2-digit",
                        minute: "2-digit",
                      })}
                    </p>
                  </div>
                </div>

                <div className="text-right">
                  <span className="text-xs text-gray-400 block">Total Amount</span>
                  <span className="font-black text-lg text-[#0A2540]">₹{order.totalAmount}</span>
                </div>
              </div>

              {/* Items Preview */}
              <div className="py-4 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div className="flex flex-wrap items-center gap-3">
                  {order.items.slice(0, 4).map((it) => (
                    <div
                      key={it.product.id}
                      className="flex items-center gap-2 p-1.5 bg-gray-50 border border-gray-100 rounded-xl"
                    >
                      <img
                        src={it.product.image}
                        alt={it.product.name}
                        className="w-10 h-10 object-contain rounded-lg bg-white p-0.5 border border-gray-100"
                      />
                      <div className="text-xs pr-1">
                        <p className="font-bold text-gray-800 line-clamp-1 max-w-[120px]">
                          {it.product.name}
                        </p>
                        <span className="text-[10px] text-gray-500">
                          Qty: {it.quantity}
                        </span>
                      </div>
                    </div>
                  ))}
                  {order.items.length > 4 && (
                    <span className="text-xs font-bold text-gray-500 bg-gray-100 px-3 py-2 rounded-xl">
                      +{order.items.length - 4} more
                    </span>
                  )}
                </div>

                {/* Actions */}
                <div className="flex items-center gap-2.5 shrink-0">
                  <button
                    onClick={() => handleReorder(order)}
                    className="flex items-center gap-1 text-xs font-bold text-gray-700 hover:text-[#0A2540] border border-gray-300 hover:border-gray-400 bg-white px-3.5 py-2 rounded-xl transition-all cursor-pointer"
                  >
                    <RotateCcw className="w-3.5 h-3.5" />
                    <span>Reorder</span>
                  </button>

                  <Link
                    href={`/orders/${order.id}`}
                    className="flex items-center gap-1 text-xs font-bold text-white bg-[#E11A22] hover:bg-[#c8141b] px-4 py-2 rounded-xl transition-all shadow-xs"
                  >
                    <span>Track / View</span>
                    <ChevronRight className="w-3.5 h-3.5" />
                  </Link>
                </div>
              </div>

              {/* Delivery Schedule Footer */}
              <div className="pt-3 border-t border-gray-100 flex items-center justify-between text-xs text-gray-500">
                <div className="flex items-center gap-2">
                  <Truck className="w-4 h-4 text-emerald-600" />
                  <span>
                    Delivery on time: <strong className="text-gray-800">{order.deliverySlot?.day || (order.deliverySlot as any)?.date || "Scheduled"} ({order.deliverySlot?.time})</strong>
                  </span>
                </div>
                <span>Payment: <strong className="text-gray-800">{order.paymentMethod}</strong></span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
