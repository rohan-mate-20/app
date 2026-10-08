import { NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';
import { createClient as createServerClient } from '@/lib/supabase/server';

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const {
      orderNumber,
      customerId,
      storeId,
      items,
      subtotal,
      deliveryFee,
      total,
      deliverySlotId,
      scheduledDeliveryDate,
      deliveryAddressSnapshot,
      customerSnapshot,
      paymentMethod,
    } = body;

    // Use admin client if SUPABASE_SERVICE_ROLE_KEY is set, otherwise use server client
    const adminClient = createAdminClient();
    const client = adminClient || createServerClient();

    let resolvedCustomerId = customerId;
    const isUuid = (str?: string | null) =>
      Boolean(str && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str));

    // 1. Verify or create customer record to ensure foreign key constraint passes
    const customerPhone = customerSnapshot?.phone || '';
    if (customerPhone) {
      const { data: existingCust } = await client
        .from('customers')
        .select('id')
        .eq('phone', customerPhone)
        .maybeSingle();

      if (existingCust?.id) {
        resolvedCustomerId = existingCust.id;
      } else {
        const { data: newCust, error: custErr } = await client
          .from('customers')
          .insert({
            phone: customerPhone,
            name: customerSnapshot?.name || null,
            email: customerSnapshot?.email || null,
          })
          .select('id')
          .single();

        if (newCust?.id) {
          resolvedCustomerId = newCust.id;
        } else if (custErr) {
          console.warn('[API /api/orders] Customer upsert warning:', custErr.message);
        }
      }
    }

    if (!isUuid(resolvedCustomerId)) {
      // Find any existing customer as fallback if id is not valid UUID
      const { data: fallbackCust } = await client.from('customers').select('id').limit(1).maybeSingle();
      if (fallbackCust?.id) {
        resolvedCustomerId = fallbackCust.id;
      }
    }

    const paymentStatus = paymentMethod === 'COD' ? 'PENDING' : 'PAID';
    const slotId = isUuid(deliverySlotId) ? deliverySlotId : null;
    const validStoreId = isUuid(storeId) ? storeId : '458cbfde-68fd-4e71-86c7-a12a4cecad4d';

    // 2. Insert order
    const { data: orderData, error: orderError } = await client
      .from('orders')
      .insert({
        order_number: orderNumber,
        customer_id: resolvedCustomerId,
        store_id: validStoreId,
        order_type: 'DELIVERY',
        status: 'CONFIRMED',
        payment_status: paymentStatus,
        payment_method: paymentMethod || 'COD',
        subtotal: Number(subtotal) || 0,
        delivery_fee: Number(deliveryFee) || 0,
        total: Number(total) || 0,
        delivery_slot_id: slotId,
        scheduled_delivery_date: scheduledDeliveryDate || null,
        delivery_address_snapshot: deliveryAddressSnapshot || {},
        customer_snapshot: customerSnapshot || {},
      })
      .select()
      .single();

    if (orderError) {
      console.error('[API /api/orders] DB insert error on orders:', orderError);
      return NextResponse.json(
        {
          success: false,
          error: orderError.message,
          code: orderError.code,
        },
        { status: 400 }
      );
    }

    const newOrderId = orderData.id;

    // 3. Insert order status history
    try {
      await client.from('order_status_history').insert({
        order_id: newOrderId,
        status: 'CONFIRMED',
      });
    } catch (hErr) {
      console.warn('[API /api/orders] Warning recording history:', hErr);
    }

    // 4. Insert order items
    if (Array.isArray(items) && items.length > 0) {
      const orderItemsPayload = items.map((item: any) => ({
        order_id: newOrderId,
        product_id: item.product?.id,
        product_name: item.product?.name || 'Item',
        quantity: item.quantity || 1,
        unit_mrp: item.product?.mrp || item.product?.sellingPrice || 0,
        unit_selling_price: item.product?.sellingPrice || 0,
        tax: 0,
        line_total: (item.product?.sellingPrice || 0) * (item.quantity || 1),
        is_available: true,
      }));

      const { error: itemsErr } = await client.from('order_items').insert(orderItemsPayload);
      if (itemsErr) {
        console.warn('[API /api/orders] Warning inserting items:', itemsErr.message);
      }
    }

    return NextResponse.json({
      success: true,
      orderId: newOrderId,
      orderNumber: orderData.order_number,
    });
  } catch (error: any) {
    console.error('[API /api/orders] Unhandled error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error.message || 'Internal server error',
      },
      { status: 500 }
    );
  }
}
