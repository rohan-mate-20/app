import { supabase } from '../lib/supabase/client';
import { DbDeliverySettings, DbDeliverySlot } from '../types/database';
import { DeliverySlotItem } from '../types';

export const deliveryService = {
  /**
   * Fetch delivery pricing configuration from delivery_settings table
   */
  async getDeliverySettings(): Promise<DbDeliverySettings | null> {
    try {
      const { data, error } = await supabase
        .from('delivery_settings')
        .select('*')
        .eq('id', 1)
        .maybeSingle();

      if (error || !data) {
        console.warn('[deliveryService] could not load delivery_settings:', error?.message);
        return {
          id: 1,
          min_order_value: 500,
          tier1_max_value: 999,
          tier1_fee: 40,
          tier2_fee: 30,
          free_delivery_order_count: 3,
        };
      }

      return data;
    } catch {
      return {
        id: 1,
        min_order_value: 500,
        tier1_max_value: 999,
        tier1_fee: 40,
        tier2_fee: 30,
        free_delivery_order_count: 3,
      };
    }
  },

  /**
   * Calculate delivery fee based on DB settings and user's order history
   */
  calculateDeliveryFee(
    subtotal: number,
    settings: DbDeliverySettings,
    pastOrderCount = 0
  ): { fee: number; isFreeDelivery: boolean; isBelowMin: boolean } {
    // If user is within their first N orders, delivery is free
    if (pastOrderCount < settings.free_delivery_order_count) {
      return {
        fee: 0,
        isFreeDelivery: true,
        isBelowMin: subtotal < settings.min_order_value,
      };
    }

    if (subtotal <= settings.tier1_max_value) {
      return {
        fee: Number(settings.tier1_fee),
        isFreeDelivery: false,
        isBelowMin: subtotal < settings.min_order_value,
      };
    }

    return {
      fee: Number(settings.tier2_fee),
      isFreeDelivery: false,
      isBelowMin: false,
    };
  },

  /**
   * Fetch available delivery slots for a store from delivery_slots table
   */
  async getAvailableSlots(storeId?: string): Promise<DeliverySlotItem[]> {
    try {
      let query = supabase
        .from('delivery_slots')
        .select('*')
        .order('slot_date', { ascending: true })
        .order('start_time', { ascending: true });

      if (storeId) {
        query = query.eq('store_id', storeId);
      }

      const { data, error } = await query;

      if (error || !data || data.length === 0) {
        // If DB has no delivery_slots rows yet, return standard morning/evening defaults
        const today = new Date().toISOString().split('T')[0];
        return [
          {
            id: 'slot-morning',
            name: 'Morning',
            time: '8:00 AM - 12:00 PM',
            date: today,
            fee: 'Free delivery',
            isAvailable: true,
          },
          {
            id: 'slot-evening',
            name: 'Evening',
            time: '4:00 PM - 8:00 PM',
            date: today,
            fee: 'Free delivery',
            isAvailable: true,
          },
        ];
      }

      return data.map((slot: DbDeliverySlot): DeliverySlotItem => {
        const isAvailable = (slot.capacity - slot.current_bookings) > 0;
        return {
          id: slot.id,
          name: slot.slot_name,
          time: `${slot.start_time.slice(0, 5)} - ${slot.end_time.slice(0, 5)}`,
          date: slot.slot_date,
          fee: 'Guaranteed On Time',
          isAvailable,
        };
      });
    } catch (err: any) {
      console.warn('[deliveryService] exception loading slots:', err?.message);
      return [];
    }
  },
};
