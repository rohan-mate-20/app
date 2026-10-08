'use client';

import React, { useEffect, useMemo, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft,
  Check,
  CheckCircle2,
  Clock3,
  CreditCard,
  MapPin,
  Package,
  RefreshCw,
  Truck,
  XCircle,
} from 'lucide-react';

import { orderService, OrderStatus, OrderTracking } from '@/services/orders';
import { supabase } from '@/lib/supabase/client';

const DELIVERY_STEPS: OrderStatus[] = [
  'CREATED',
  'CONFIRMED',
  'PREPARING',
  'PACKED',
  'DELIVERY_ASSIGNED',
  'OUT_FOR_DELIVERY',
  'DELIVERED',
];

const PICKUP_STEPS: OrderStatus[] = [
  'CREATED',
  'CONFIRMED',
  'PREPARING',
  'PACKED',
  'READY_FOR_PICKUP',
  'PICKED_UP',
];

const STATUS_LABELS: Record<OrderStatus, string> = {
  CREATED: 'Order Created',
  CONFIRMED: 'Order Confirmed',
  PREPARING: 'Preparing Your Order',
  PACKED: 'Order Packed',
  READY_FOR_PICKUP: 'Ready for Pickup',
  DELIVERY_ASSIGNED: 'Delivery Partner Assigned',
  OUT_FOR_DELIVERY: 'Out for Delivery',
  DELIVERED: 'Delivered',
  PICKED_UP: 'Picked Up',
  CANCELLED: 'Cancelled',
  FAILED: 'Order Failed',
  REFUND_PENDING: 'Refund Pending',
  REFUNDED: 'Refunded',
};

const STATUS_DESCRIPTIONS: Record<OrderStatus, string> = {
  CREATED: 'Your order has been received.',
  CONFIRMED: 'Your order has been confirmed by K Mart.',
  PREPARING: 'Our store team is preparing your items.',
  PACKED: 'Your items have been packed and are ready for the next step.',
  READY_FOR_PICKUP: 'Your order is ready to be collected from the store.',
  DELIVERY_ASSIGNED: 'A delivery partner has been assigned to your order.',
  OUT_FOR_DELIVERY: 'Your order is on the way to your delivery address.',
  DELIVERED: 'Your order has been delivered successfully.',
  PICKED_UP: 'Your order has been collected successfully.',
  CANCELLED: 'This order has been cancelled.',
  FAILED: 'There was a problem processing this order.',
  REFUND_PENDING: 'Your refund is being processed.',
  REFUNDED: 'Your refund has been completed.',
};

function formatDate(value: string | null | undefined) {
  if (!value) return '—';

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return date.toLocaleString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function formatMoney(value: number) {
  return `₹${value.toLocaleString('en-IN', {
    maximumFractionDigits: 2,
  })}`;
}

function getStatusLabel(status: OrderStatus) {
  return STATUS_LABELS[status] || status.replaceAll('_', ' ');
}

function isTerminalStatus(status: OrderStatus) {
  return [
    'CANCELLED',
    'FAILED',
    'REFUND_PENDING',
    'REFUNDED',
  ].includes(status);
}

export default function OrderTrackingPage() {
  const params = useParams();
  const router = useRouter();

  const orderId = Array.isArray(params.id)
    ? params.id[0]
    : params.id;

  const [tracking, setTracking] = useState<OrderTracking | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState('');

  async function loadTracking(showRefresh = false) {
    if (!orderId) return;

    try {
      if (showRefresh) {
        setRefreshing(true);
      } else {
        setLoading(true);
      }

      setError('');

      const {
        data: {
          user,
        },
      } = await supabase.auth.getUser();

      if (!user) {
        router.push(`/login?redirect=/order/${orderId}/tracking`);
        return;
      }

      const result = await orderService.fetchOrderTracking(
        orderId,
        user.id
      );

      if (!result.data) {
        setTracking(null);
        setError(
          result.error ||
            'Unable to load order tracking information.'
        );
        return;
      }

      setTracking(result.data);
    } catch (err: any) {
      console.error(
        '[OrderTrackingPage] load error:',
        err
      );

      setError(
        err?.message ||
          'Unable to load order tracking information.'
      );
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  useEffect(() => {
    loadTracking();
  }, [orderId]);

  const steps = useMemo(() => {
    if (!tracking) return DELIVERY_STEPS;

    return tracking.orderType === 'PICKUP'
      ? PICKUP_STEPS
      : DELIVERY_STEPS;
  }, [tracking]);

  const completedStatuses = useMemo(() => {
    if (!tracking) return new Set<OrderStatus>();

    return new Set(
      tracking.statusHistory.map(
        (history) => history.status
      )
    );
  }, [tracking]);

  function getHistoryForStatus(status: OrderStatus) {
    if (!tracking) return null;

    return (
      tracking.statusHistory.find(
        (history) => history.status === status
      ) || null
    );
  }

  if (loading) {
    return (
      <main className="min-h-screen bg-gray-50 flex items-center justify-center px-4">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-gray-200 border-t-[#E11A22] rounded-full animate-spin mx-auto" />

          <p className="mt-4 text-sm font-semibold text-gray-700">
            Loading your order...
          </p>

          <p className="mt-1 text-xs text-gray-500">
            Please wait while we fetch the latest tracking information.
          </p>
        </div>
      </main>
    );
  }

  if (error || !tracking) {
    return (
      <main className="min-h-screen bg-gray-50 px-4 py-8">
        <div className="max-w-3xl mx-auto">
          <button
            onClick={() => router.push('/orders')}
            className="inline-flex items-center gap-2 text-sm font-bold text-[#0A2540] hover:text-[#E11A22] transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
            Back to Orders
          </button>

          <div className="mt-8 bg-white rounded-2xl border border-red-100 shadow-sm p-8 text-center">
            <div className="w-14 h-14 mx-auto rounded-full bg-red-50 text-red-600 flex items-center justify-center">
              <XCircle className="w-7 h-7" />
            </div>

            <h1 className="mt-4 text-xl font-black text-gray-900">
              Unable to Load Order
            </h1>

            <p className="mt-2 text-sm text-gray-500">
              {error || 'The requested order could not be found.'}
            </p>

            <button
              onClick={() => loadTracking()}
              className="mt-6 inline-flex items-center justify-center gap-2 bg-[#0A2540] hover:bg-[#123154] text-white px-5 py-2.5 rounded-xl text-sm font-bold transition-colors"
            >
              <RefreshCw className="w-4 h-4" />
              Try Again
            </button>
          </div>
        </div>
      </main>
    );
  }

  const terminal = isTerminalStatus(tracking.status);

  return (
    <main className="min-h-screen bg-gray-50">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 py-6 sm:py-10">

        {/* Back + Refresh */}
        <div className="flex items-center justify-between gap-3 mb-6">
          <button
            onClick={() => router.push('/orders')}
            className="inline-flex items-center gap-2 text-sm font-bold text-[#0A2540] hover:text-[#E11A22] transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
            My Orders
          </button>

          <button
            onClick={() => loadTracking(true)}
            disabled={refreshing}
            className="inline-flex items-center gap-2 px-3 py-2 rounded-lg border border-gray-200 bg-white text-xs font-bold text-gray-700 hover:border-gray-300 disabled:opacity-60 transition-all"
          >
            <RefreshCw
              className={`w-3.5 h-3.5 ${
                refreshing ? 'animate-spin' : ''
              }`}
            />
            Refresh Status
          </button>
        </div>

        {/* Header */}
        <section className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
          <div className="p-5 sm:p-7 border-b border-gray-100">
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
              <div>
                <p className="text-xs font-bold uppercase tracking-wider text-gray-500">
                  Order Tracking
                </p>

                <h1 className="mt-1 text-2xl sm:text-3xl font-black text-[#0A2540]">
                  #{tracking.orderNumber}
                </h1>

                <p className="mt-1 text-xs text-gray-500">
                  Placed on {formatDate(tracking.createdAt)}
                </p>
              </div>

              <div
                className={`inline-flex items-center gap-2 self-start sm:self-center px-3 py-2 rounded-xl text-xs font-black ${
                  terminal
                    ? 'bg-red-50 text-red-700 border border-red-100'
                    : 'bg-emerald-50 text-emerald-700 border border-emerald-100'
                }`}
              >
                {terminal ? (
                  <XCircle className="w-4 h-4" />
                ) : (
                  <CheckCircle2 className="w-4 h-4" />
                )}

                {getStatusLabel(tracking.status)}
              </div>
            </div>
          </div>

          {/* Current status */}
          <div
            className={`p-5 sm:p-7 ${
              terminal
                ? 'bg-red-50/50'
                : 'bg-emerald-50/50'
            }`}
          >
            <div className="flex items-start gap-4">
              <div
                className={`w-11 h-11 rounded-full flex items-center justify-center shrink-0 ${
                  terminal
                    ? 'bg-red-100 text-red-600'
                    : 'bg-emerald-100 text-emerald-600'
                }`}
              >
                {terminal ? (
                  <XCircle className="w-6 h-6" />
                ) : (
                  <Truck className="w-6 h-6" />
                )}
              </div>

              <div>
                <p className="text-xs font-bold uppercase tracking-wide text-gray-500">
                  Current Status
                </p>

                <h2 className="mt-1 text-lg font-black text-gray-900">
                  {getStatusLabel(tracking.status)}
                </h2>

                <p className="mt-1 text-sm text-gray-600">
                  {STATUS_DESCRIPTIONS[tracking.status]}
                </p>

                <p className="mt-2 text-xs text-gray-500">
                  Last updated {formatDate(tracking.updatedAt)}
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Status Timeline */}
        {!terminal && (
          <section className="mt-5 bg-white rounded-2xl border border-gray-200 shadow-sm p-5 sm:p-7">
            <div className="flex items-center gap-2 mb-7">
              <Package className="w-5 h-5 text-[#0A2540]" />

              <div>
                <h2 className="font-black text-[#0A2540]">
                  {tracking.orderType === 'PICKUP'
                    ? 'Pickup Progress'
                    : 'Delivery Progress'}
                </h2>

                <p className="text-xs text-gray-500 mt-0.5">
                  Follow your order from confirmation to completion.
                </p>
              </div>
            </div>

            <div className="relative">
              {steps.map((status, index) => {
                const history = getHistoryForStatus(status);
                const completed =
                  completedStatuses.has(status);

                const current =
                  tracking.status === status;

                const isLast =
                  index === steps.length - 1;

                return (
                  <div
                    key={status}
                    className="relative flex gap-4"
                  >
                    {!isLast && (
                      <div
                        className={`absolute left-[15px] top-8 w-0.5 h-[calc(100%-8px)] ${
                          completed
                            ? 'bg-emerald-400'
                            : 'bg-gray-200'
                        }`}
                      />
                    )}

                    <div
                      className={`relative z-10 w-8 h-8 rounded-full flex items-center justify-center shrink-0 border-2 ${
                        current
                          ? 'bg-[#E11A22] border-[#E11A22] text-white'
                          : completed
                            ? 'bg-emerald-500 border-emerald-500 text-white'
                            : 'bg-white border-gray-200 text-gray-400'
                      }`}
                    >
                      {completed ? (
                        <Check className="w-4 h-4" />
                      ) : (
                        <span className="text-[10px] font-black">
                          {index + 1}
                        </span>
                      )}
                    </div>

                    <div
                      className={`pb-7 ${
                        isLast ? 'pb-0' : ''
                      }`}
                    >
                      <div className="flex flex-col sm:flex-row sm:items-center gap-1 sm:gap-3">
                        <h3
                          className={`text-sm font-black ${
                            current
                              ? 'text-[#E11A22]'
                              : completed
                                ? 'text-gray-900'
                                : 'text-gray-400'
                          }`}
                        >
                          {getStatusLabel(status)}
                        </h3>

                        {history && (
                          <span className="text-[11px] text-gray-400">
                            {formatDate(history.changedAt)}
                          </span>
                        )}
                      </div>

                      {completed && (
                        <p className="mt-1 text-xs text-gray-500">
                          {STATUS_DESCRIPTIONS[status]}
                        </p>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </section>
        )}

        {/* Terminal status details */}
        {terminal && (
          <section className="mt-5 bg-white rounded-2xl border border-red-100 shadow-sm p-5 sm:p-7">
            <div className="flex items-start gap-4">
              <div className="w-10 h-10 rounded-full bg-red-50 text-red-600 flex items-center justify-center shrink-0">
                <XCircle className="w-5 h-5" />
              </div>

              <div>
                <h2 className="font-black text-gray-900">
                  {getStatusLabel(tracking.status)}
                </h2>

                <p className="text-sm text-gray-600 mt-1">
                  {STATUS_DESCRIPTIONS[tracking.status]}
                </p>
              </div>
            </div>
          </section>
        )}

        {/* Delivery / Pickup Information */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5 mt-5">

          <section className="bg-white rounded-2xl border border-gray-200 shadow-sm p-5">
            <div className="flex items-center gap-2 mb-4">
              {tracking.orderType === 'PICKUP' ? (
                <Package className="w-5 h-5 text-[#0A2540]" />
              ) : (
                <MapPin className="w-5 h-5 text-[#0A2540]" />
              )}

              <h2 className="font-black text-[#0A2540]">
                {tracking.orderType === 'PICKUP'
                  ? 'Pickup Information'
                  : 'Delivery Information'}
              </h2>
            </div>

            {tracking.orderType === 'DELIVERY' &&
            tracking.deliveryAddressSnapshot ? (
              <div className="text-sm text-gray-600 space-y-1">
                <p className="font-black text-gray-900">
                  {tracking.deliveryAddressSnapshot.label ||
                    'Delivery Address'}
                </p>

                <p>
                  {tracking.deliveryAddressSnapshot.line1}
                </p>

                {tracking.deliveryAddressSnapshot.line2 && (
                  <p>
                    {tracking.deliveryAddressSnapshot.line2}
                  </p>
                )}

                <p>
                  {tracking.deliveryAddressSnapshot.city}
                  {tracking.deliveryAddressSnapshot.state
                    ? `, ${tracking.deliveryAddressSnapshot.state}`
                    : ''}
                  {tracking.deliveryAddressSnapshot.pincode
                    ? ` - ${tracking.deliveryAddressSnapshot.pincode}`
                    : ''}
                </p>

                {tracking.deliveryAddressSnapshot.phone && (
                  <p className="pt-2 text-xs text-gray-500">
                    Contact: {tracking.deliveryAddressSnapshot.phone}
                  </p>
                )}
              </div>
            ) : (
              <div className="text-sm text-gray-600">
                <p>
                  Your order is scheduled for pickup.
                </p>

                {tracking.scheduledDeliveryDate && (
                  <p className="mt-2 font-bold text-gray-900">
                    Scheduled date:{' '}
                    {tracking.scheduledDeliveryDate}
                  </p>
                )}
              </div>
            )}

            {tracking.deliverySlotId && (
              <div className="mt-4 pt-4 border-t border-gray-100 flex items-center gap-2 text-xs">
                <Clock3 className="w-4 h-4 text-[#E11A22]" />

                <span className="text-gray-500">
                  Delivery slot:
                </span>

                <span className="font-bold text-gray-900">
                  {tracking.scheduledDeliveryDate ||
                    'Scheduled'}
                </span>
              </div>
            )}
          </section>

          {/* Payment */}
          <section className="bg-white rounded-2xl border border-gray-200 shadow-sm p-5">
            <div className="flex items-center gap-2 mb-4">
              <CreditCard className="w-5 h-5 text-[#0A2540]" />

              <h2 className="font-black text-[#0A2540]">
                Payment Information
              </h2>
            </div>

            <div className="space-y-3 text-sm">
              <div className="flex items-center justify-between">
                <span className="text-gray-500">
                  Payment method
                </span>

                <span className="font-bold text-gray-900">
                  {tracking.paymentMethod === 'COD'
                    ? 'Cash on Delivery'
                    : 'Online Payment'}
                </span>
              </div>

              <div className="flex items-center justify-between">
                <span className="text-gray-500">
                  Payment status
                </span>

                <span
                  className={`font-bold ${
                    tracking.paymentStatus === 'PAID'
                      ? 'text-emerald-600'
                      : tracking.paymentStatus === 'FAILED'
                        ? 'text-red-600'
                        : 'text-amber-600'
                  }`}
                >
                  {tracking.paymentStatus}
                </span>
              </div>
            </div>
          </section>
        </div>

        {/* Order Items */}
        <section className="mt-5 bg-white rounded-2xl border border-gray-200 shadow-sm p-5 sm:p-7">
          <div className="flex items-center justify-between gap-3 mb-5">
            <div className="flex items-center gap-2">
              <ShoppingBagIcon />

              <div>
                <h2 className="font-black text-[#0A2540]">
                  Order Items
                </h2>

                <p className="text-xs text-gray-500">
                  {tracking.items.length}{' '}
                  {tracking.items.length === 1
                    ? 'item'
                    : 'items'}
                </p>
              </div>
            </div>
          </div>

          <div className="divide-y divide-gray-100">
            {tracking.items.map((item) => (
              <div
                key={item.id}
                className="py-3 first:pt-0 last:pb-0 flex items-center justify-between gap-4"
              >
                <div className="min-w-0">
                  <p className="font-bold text-sm text-gray-900 truncate">
                    {item.productName}
                  </p>

                  <p className="text-xs text-gray-500 mt-0.5">
                    Qty: {item.quantity} ×{' '}
                    {formatMoney(item.unitSellingPrice)}
                  </p>
                </div>

                <p className="font-black text-sm text-gray-900 shrink-0">
                  {formatMoney(item.lineTotal)}
                </p>
              </div>
            ))}
          </div>
        </section>

        {/* Price Summary */}
        <section className="mt-5 bg-white rounded-2xl border border-gray-200 shadow-sm p-5 sm:p-7">
          <h2 className="font-black text-[#0A2540] mb-4">
            Order Summary
          </h2>

          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-500">
                Subtotal
              </span>

              <span className="font-semibold text-gray-900">
                {formatMoney(tracking.subtotal)}
              </span>
            </div>

            <div className="flex justify-between">
              <span className="text-gray-500">
                Delivery Fee
              </span>

              <span className="font-semibold text-gray-900">
                {tracking.deliveryFee === 0
                  ? 'FREE'
                  : formatMoney(tracking.deliveryFee)}
              </span>
            </div>

            <div className="pt-3 mt-3 border-t border-gray-100 flex justify-between">
              <span className="font-black text-gray-900">
                Total
              </span>

              <span className="font-black text-lg text-[#0A2540]">
                {formatMoney(tracking.total)}
              </span>
            </div>
          </div>
        </section>

      </div>
    </main>
  );
}

function ShoppingBagIcon() {
  return (
    <div className="w-9 h-9 rounded-lg bg-gray-50 flex items-center justify-center">
      <Package className="w-5 h-5 text-[#0A2540]" />
    </div>
  );
}