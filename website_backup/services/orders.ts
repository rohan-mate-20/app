import { supabase } from '../lib/supabase/client';
import { Order, CartItem } from '../types';

export type OrderStatus =
  | 'CREATED'
  | 'CONFIRMED'
  | 'PREPARING'
  | 'PACKED'
  | 'READY_FOR_PICKUP'
  | 'DELIVERY_ASSIGNED'
  | 'OUT_FOR_DELIVERY'
  | 'DELIVERED'
  | 'PICKED_UP'
  | 'CANCELLED'
  | 'FAILED'
  | 'REFUND_PENDING'
  | 'REFUNDED';

export type OrderStatusHistory = {
  id: string;
  orderId: string;
  status: OrderStatus;
  changedBy: string | null;
  changedAt: string;
};

export type OrderTracking = {
  id: string;
  orderNumber: string;
  orderType: 'DELIVERY' | 'PICKUP';
  status: OrderStatus;
  paymentStatus: 'PENDING' | 'PAID' | 'FAILED' | 'REFUNDED';
  paymentMethod: 'COD' | 'ONLINE';
  subtotal: number;
  deliveryFee: number;
  total: number;
  deliverySlotId: string | null;
  scheduledDeliveryDate: string | null;
  deliveryAddressSnapshot: any;
  customerSnapshot: any;
  createdAt: string;
  updatedAt: string;
  items: {
    id: string;
    productId: string;
    productName: string;
    quantity: number;
    unitMrp: number;
    unitSellingPrice: number;
    tax: number;
    lineTotal: number;
    isAvailable: boolean;
  }[];
  statusHistory: OrderStatusHistory[];
};

export const orderService = {
  /**
   * Save a newly placed order to:
   * - orders
   * - order_items
   * - order_status_history
   * - payments (when required)
   */
  async saveOrderToDb(
    order: {
      orderNumber: string;
      customerId: string;
      storeId: string;
      items: CartItem[];
      subtotal: number;
      deliveryFee: number;
      total: number;
      deliverySlotId?: string | null;
      scheduledDeliveryDate?: string | null;
      deliveryAddressSnapshot: any;
      customerSnapshot: any;
      paymentMethod: 'COD' | 'ONLINE';
      paymentId?: string | null;
    },
    client = supabase
  ): Promise<{
    success: boolean;
    orderId?: string;
    orderNumber?: string;
    error?: string;
  }> {
    try {
      // 1. Try server-side API endpoint first (handles service role bypass and customer creation)
      try {
        if (typeof window !== 'undefined') {
          const response = await fetch('/api/orders', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(order),
          });
          const resJson = await response.json();
          if (response.ok && resJson.success && resJson.orderId) {
            return {
              success: true,
              orderId: resJson.orderId,
              orderNumber: resJson.orderNumber || order.orderNumber,
            };
          }
        }
      } catch (apiErr) {
        console.warn('[orderService] /api/orders failed, falling back to direct Supabase client:', apiErr);
      }

      const paymentStatus =
        order.paymentMethod === 'COD' ? 'PENDING' : 'PAID';

      const isUuid = (str?: string | null) =>
        Boolean(str && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str));

      const slotId = isUuid(order.deliverySlotId) ? order.deliverySlotId : null;

      const { data: orderData, error: orderError } = await client
        .from('orders')
        .insert({
          order_number: order.orderNumber,
          customer_id: order.customerId,
          store_id: order.storeId,
          order_type: 'DELIVERY',
          status: 'CONFIRMED',
          payment_status: paymentStatus,
          payment_method: order.paymentMethod,
          subtotal: order.subtotal,
          delivery_fee: order.deliveryFee,
          total: order.total,
          delivery_slot_id: slotId,
          scheduled_delivery_date:
            order.scheduledDeliveryDate || null,
          delivery_address_snapshot:
            order.deliveryAddressSnapshot,
          customer_snapshot:
            order.customerSnapshot,
        })
        .select()
        .single();

      if (orderError) {
        console.error(
          '[orderService] DB error creating order:',
          orderError.message,
          '(Code:', orderError.code, ')'
        );

        return {
          success: false,
          error: orderError.message,
        };
      }

      const orderId = orderData.id;

      // --------------------------------------------------
      // 2. Record initial order status
      // --------------------------------------------------

      const { error: historyError } = await client
        .from('order_status_history')
        .insert({
          order_id: orderId,
          status: 'CONFIRMED',
        });

      if (historyError) {
        console.warn(
          '[orderService] Error recording initial order status:',
          historyError.message
        );
      }

      // --------------------------------------------------
      // 3. Insert order items
      // --------------------------------------------------

      if (order.items.length > 0) {
        const orderItemsPayload = order.items.map((item) => ({
          order_id: orderId,
          product_id: item.product.id,
          product_name: item.product.name,
          quantity: item.quantity,
          unit_mrp:
            item.product.originalPrice ||
            item.product.price,
          unit_selling_price: item.product.price,
          line_total:
            item.product.price * item.quantity,
          is_available: true,
        }));

        const { error: itemsError } = await client
          .from('order_items')
          .insert(orderItemsPayload);

        if (itemsError) {
          console.warn(
            '[orderService] Error inserting order_items:',
            itemsError.message
          );
        }
      }

      // --------------------------------------------------
      // 4. Record payment
      // --------------------------------------------------

      if (
        order.paymentMethod === 'ONLINE' ||
        order.paymentId
      ) {
        const { error: paymentError } = await client
          .from('payments')
          .insert({
            order_id: orderId,
            razorpay_payment_id:
              order.paymentId || null,
            amount: order.total,
            status: paymentStatus,
          });

        if (paymentError) {
          console.warn(
            '[orderService] Error recording payment:',
            paymentError.message
          );
        }
      }

      // --------------------------------------------------
      // 5. Return success
      // --------------------------------------------------

      return {
        success: true,
        orderId,
        orderNumber: order.orderNumber,
      };
    } catch (err: any) {
      console.warn(
        '[orderService] exception saving order:',
        err?.message
      );

      return {
        success: false,
        error:
          err?.message ||
          'Unable to save order.',
      };
    }
  },

  /**
   * Fetch all customer orders.
   */
  async fetchUserOrders(
    customerId: string,
    client = supabase
  ): Promise<Order[]> {
    if (!customerId) return [];

    try {
      const isUuid = (str?: string | null) =>
        Boolean(str && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str));

      let query = client
        .from('orders')
        .select(`
          *,
          order_items (
            *,
            products (
              id,
              name,
              mrp,
              selling_price,
              weight_unit,
              image_url,
              brand,
              description,
              categories ( name )
            )
          )
        `);

      if (isUuid(customerId)) {
        query = query.eq('customer_id', customerId);
      } else {
        query = query.or(`customer_snapshot->>phone.eq.${customerId},order_number.eq.${customerId}`);
      }

      const { data, error } = await query.order('created_at', {
        ascending: false,
      });

      if (error || !data) {
        console.warn(
          '[orderService] fetchUserOrders error:',
          error?.message
        );

        return [];
      }

      return data.map((dbOrd: any): Order => {
        const items: CartItem[] =
          (dbOrd.order_items || []).map(
            (it: any) => {
              const p = it.products || {};

              return {
                product: {
                  id: it.product_id,
                  name:
                    it.product_name ||
                    p.name ||
                    'Grocery Item',
                  category:
                    p.categories?.name ||
                    'Groceries',
                  weight:
                    p.weight_unit ||
                    '1 unit',
                  price: Number(
                    it.unit_selling_price ||
                    it.price ||
                    0
                  ),
                  originalPrice: Number(
                    it.unit_mrp ||
                    p.mrp ||
                    it.unit_selling_price ||
                    0
                  ),
                  discountPercent: 0,
                  rating: 4.6,
                  reviewCount: 15,
                  image:
                    p.image_url ||
                    'https://placehold.co/400x400?text=Product',
                  inStock: true,
                  stockCount: 50,
                  brand:
                    p.brand ||
                    'K MART',
                  deliveryTime:
                    'Delivery on time',
                  description:
                    p.description ||
                    '',
                },
                quantity: it.quantity,
              };
            }
          );

        const addressSnapshot =
          dbOrd.delivery_address_snapshot ||
          {};

        return {
          id: dbOrd.id,

          orderNumber:
            dbOrd.order_number ||
            `KM-${dbOrd.id
              .slice(0, 6)
              .toUpperCase()}`,

          items,

          itemTotal: Number(
            dbOrd.subtotal ||
            dbOrd.total_amount ||
            0
          ),

          discount: 0,

          deliveryFee: Number(
            dbOrd.delivery_fee || 0
          ),

          totalAmount: Number(
            dbOrd.total ||
            dbOrd.total_amount ||
            0
          ),

          deliveryAddress:
            addressSnapshot.line1
              ? {
                  id:
                    addressSnapshot.id ||
                    'snapshot',

                  label:
                    addressSnapshot.label ||
                    'Home',

                  fullName:
                    addressSnapshot.full_name ||
                    addressSnapshot.name ||
                    'Customer',

                  phone:
                    addressSnapshot.phone ||
                    '',

                  line1:
                    addressSnapshot.line1,

                  line2:
                    addressSnapshot.line2,

                  city:
                    addressSnapshot.city ||
                    'Pune',

                  state:
                    addressSnapshot.state ||
                    'Maharashtra',

                  pincode:
                    addressSnapshot.pincode ||
                    '',

                  latitude:
                    addressSnapshot.latitude ||
                    0,

                  longitude:
                    addressSnapshot.longitude ||
                    0,
                }
              : null,

          deliverySlot: {
            slotId:
              dbOrd.delivery_slot_id,

            time:
              '8:00 AM - 12:00 PM',

            day:
              dbOrd.scheduled_delivery_date ||
              'Scheduled',

            date:
              dbOrd.scheduled_delivery_date,
          },

          paymentMethod:
            dbOrd.payment_method === 'ONLINE'
              ? 'Razorpay'
              : 'Cash on Delivery',

          status:
            dbOrd.status ||
            'CONFIRMED',

          createdAt:
            dbOrd.created_at,
        };
      });
    } catch (err: any) {
      console.warn(
        '[orderService] fetchUserOrders exception:',
        err?.message
      );

      return [];
    }
  },

  /**
   * Update the status of an order in the database and append to history.
   */
  async updateOrderStatus(
    orderId: string,
    newStatus: string,
    changedBy = 'K MART Operations',
    client = supabase
  ): Promise<boolean> {
    if (!orderId || !newStatus) return false;

    try {
      const { error: updErr } = await client
        .from('orders')
        .update({ status: newStatus, updated_at: new Date().toISOString() })
        .or(`id.eq.${orderId},order_number.eq.${orderId}`);

      if (updErr) {
        console.warn('[orderService] updateOrderStatus error:', updErr.message);
        return false;
      }

      await client.from('order_status_history').insert({
        order_id: orderId,
        status: newStatus,
        changed_by: changedBy,
      });

      return true;
    } catch (err: any) {
      console.warn('[orderService] updateOrderStatus exception:', err?.message);
      return false;
    }
  },

  /**
   * Fetch a single order for customer tracking.
   *
   * IMPORTANT:
   * The customerId check ensures a customer can
   * only retrieve their own order.
   */
  async fetchOrderTracking(
    orderId: string,
    customerId: string,
    client = supabase
  ): Promise<{
    data: OrderTracking | null;
    error?: string;
  }> {
    if (!orderId) {
      return {
        data: null,
        error: 'Order ID is required.',
      };
    }

    if (!customerId) {
      return {
        data: null,
        error: 'Customer authentication is required.',
      };
    }

    try {
      // --------------------------------------------------
      // 1. Fetch order
      // --------------------------------------------------

      const { data: orderData, error: orderError } =
        await client
          .from('orders')
          .select(`
            id,
            order_number,
            customer_id,
            order_type,
            status,
            payment_status,
            payment_method,
            subtotal,
            delivery_fee,
            total,
            delivery_slot_id,
            scheduled_delivery_date,
            delivery_address_snapshot,
            customer_snapshot,
            created_at,
            updated_at,
            order_items (
              id,
              product_id,
              product_name,
              quantity,
              unit_mrp,
              unit_selling_price,
              tax,
              line_total,
              is_available
            )
          `)
          .eq('id', orderId)
          .eq('customer_id', customerId)
          .single();

      if (orderError || !orderData) {
        console.warn(
          '[orderService] fetchOrderTracking error:',
          orderError?.message
        );

        return {
          data: null,
          error:
            'Order not found or you do not have permission to view this order.',
        };
      }

      // --------------------------------------------------
      // 2. Fetch status history
      // --------------------------------------------------

      const {
        data: historyData,
        error: historyError,
      } = await client
        .from('order_status_history')
        .select(`
          id,
          order_id,
          status,
          changed_by,
          changed_at
        `)
        .eq('order_id', orderId)
        .order('changed_at', {
          ascending: true,
        });

      if (historyError) {
        console.warn(
          '[orderService] fetchOrderTracking history error:',
          historyError.message
        );
      }

      // --------------------------------------------------
      // 3. Build tracking response
      // --------------------------------------------------

      const trackingData: OrderTracking = {
        id: orderData.id,

        orderNumber:
          orderData.order_number,

        orderType:
          orderData.order_type,

        status:
          orderData.status,

        paymentStatus:
          orderData.payment_status,

        paymentMethod:
          orderData.payment_method,

        subtotal:
          Number(orderData.subtotal || 0),

        deliveryFee:
          Number(orderData.delivery_fee || 0),

        total:
          Number(orderData.total || 0),

        deliverySlotId:
          orderData.delivery_slot_id,

        scheduledDeliveryDate:
          orderData.scheduled_delivery_date,

        deliveryAddressSnapshot:
          orderData.delivery_address_snapshot,

        customerSnapshot:
          orderData.customer_snapshot,

        createdAt:
          orderData.created_at,

        updatedAt:
          orderData.updated_at,

        items:
          (orderData.order_items || []).map(
            (item: any) => ({
              id: item.id,

              productId:
                item.product_id,

              productName:
                item.product_name,

              quantity:
                item.quantity,

              unitMrp:
                Number(item.unit_mrp || 0),

              unitSellingPrice:
                Number(
                  item.unit_selling_price || 0
                ),

              tax:
                Number(item.tax || 0),

              lineTotal:
                Number(item.line_total || 0),

              isAvailable:
                item.is_available,
            })
          ),

        statusHistory:
          (historyData || []).map(
            (history: any) => ({
              id: history.id,

              orderId:
                history.order_id,

              status:
                history.status,

              changedBy:
                history.changed_by,

              changedAt:
                history.changed_at,
            })
          ),
      };

      return {
        data: trackingData,
      };
    } catch (err: any) {
      console.warn(
        '[orderService] fetchOrderTracking exception:',
        err?.message
      );

      return {
        data: null,
        error:
          err?.message ||
          'Unable to load order tracking information.',
      };
    }
  },

  /**
   * Fetch status history for an order.
   */
  async fetchOrderStatusHistory(
    orderId: string,
    customerId: string,
    client = supabase
  ): Promise<OrderStatusHistory[]> {
    if (!orderId || !customerId) {
      return [];
    }

    try {
      // First verify that this order belongs
      // to the authenticated customer.
      const { data: orderData, error: orderError } =
        await client
          .from('orders')
          .select('id')
          .eq('id', orderId)
          .eq('customer_id', customerId)
          .single();

      if (orderError || !orderData) {
        return [];
      }

      const {
        data,
        error,
      } = await client
        .from('order_status_history')
        .select(`
          id,
          order_id,
          status,
          changed_by,
          changed_at
        `)
        .eq('order_id', orderId)
        .order('changed_at', {
          ascending: true,
        });

      if (error || !data) {
        console.warn(
          '[orderService] fetchOrderStatusHistory error:',
          error?.message
        );

        return [];
      }

      return data.map(
        (history: any): OrderStatusHistory => ({
          id: history.id,
          orderId: history.order_id,
          status: history.status,
          changedBy: history.changed_by,
          changedAt: history.changed_at,
        })
      );
    } catch (err: any) {
      console.warn(
        '[orderService] fetchOrderStatusHistory exception:',
        err?.message
      );

      return [];
    }
  },
};