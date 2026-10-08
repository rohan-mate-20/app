import { supabase } from '../lib/supabase/client';
import { Address } from '../types';
import { DbAddress } from '../types/database';
import { geocodeAddress } from '../lib/geolocation';

export const addressService = {
  /**
   * Fetch all addresses for a customer from DB
   */
  async getAddresses(customerId: string): Promise<Address[]> {
    if (!customerId) return [];

    try {
      const { data, error } = await supabase
        .from('addresses')
        .select('*')
        .eq('customer_id', customerId)
        .order('is_default', { ascending: false })
        .order('created_at', { ascending: false });

      if (error) {
        console.warn('[addressService] fetch error:', error.message);
        return [];
      }

      return (data || []).map((dbAddr: DbAddress): Address => ({
        id: dbAddr.id,
        customerId: dbAddr.customer_id,
        label: dbAddr.label || 'Home',
        fullName: dbAddr.full_name,
        phone: dbAddr.phone,
        line1: dbAddr.line1,
        line2: dbAddr.line2 || undefined,
        city: dbAddr.city,
        state: dbAddr.state,
        pincode: dbAddr.pincode,
        latitude: Number(dbAddr.latitude) || 18.5204,
        longitude: Number(dbAddr.longitude) || 73.8567,
        isDefault: dbAddr.is_default,
      }));
    } catch (err: any) {
      console.warn('[addressService] exception:', err?.message);
      return [];
    }
  },

  /**
   * Add new address to DB with geocoded lat/lng
   */
  async addAddress(customerId: string, addr: Omit<Address, 'id'>): Promise<Address | null> {
    try {
      // 1. Geocode address if coordinates are default
      let lat = addr.latitude;
      let lon = addr.longitude;

      if (!lat || !lon || (lat === 0 && lon === 0)) {
        const geo = await geocodeAddress({
          line1: addr.line1,
          area: addr.line2,
          city: addr.city,
          state: addr.state,
          pincode: addr.pincode,
        });
        lat = geo.latitude;
        lon = geo.longitude;
      }

      // If marked as default, clear other defaults first
      if (addr.isDefault && customerId) {
        await supabase
          .from('addresses')
          .update({ is_default: false })
          .eq('customer_id', customerId);
      }

      const { data, error } = await supabase
        .from('addresses')
        .insert({
          customer_id: customerId,
          label: addr.label || 'Home',
          full_name: addr.fullName,
          phone: addr.phone,
          line1: addr.line1,
          line2: addr.line2 || null,
          city: addr.city,
          state: addr.state,
          pincode: addr.pincode,
          latitude: lat,
          longitude: lon,
          is_default: addr.isDefault ?? false,
        })
        .select()
        .single();

      if (error) {
        console.warn('[addressService] insert error:', error.message);
        return null;
      }

      return {
        id: data.id,
        customerId: data.customer_id,
        label: data.label || 'Home',
        fullName: data.full_name,
        phone: data.phone,
        line1: data.line1,
        line2: data.line2 || undefined,
        city: data.city,
        state: data.state,
        pincode: data.pincode,
        latitude: Number(data.latitude),
        longitude: Number(data.longitude),
        isDefault: data.is_default,
      };
    } catch (err: any) {
      console.warn('[addressService] exception:', err?.message);
      return null;
    }
  },

  /**
   * Set address as default
   */
  async setDefault(addressId: string, customerId: string): Promise<boolean> {
    try {
      await supabase
        .from('addresses')
        .update({ is_default: false })
        .eq('customer_id', customerId);

      const { error } = await supabase
        .from('addresses')
        .update({ is_default: true })
        .eq('id', addressId);

      return !error;
    } catch {
      return false;
    }
  },
};
