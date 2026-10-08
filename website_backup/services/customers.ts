import { supabase } from '../lib/supabase/client';
import { DbCustomer } from '../types/database';

export const customerService = {
  /**
   * Look up or insert customer by phone number and auth_user_id
   */
  async upsertCustomer(
    phone: string,
    name?: string,
    email?: string,
    authUserId?: string
  ): Promise<DbCustomer | null> {
    if (!phone) return null;
    const cleanPhone = phone.trim();

    // If authUserId wasn't passed, try to get from current Supabase session
    let resolvedAuthId = authUserId;
    if (!resolvedAuthId) {
      try {
        const { data: { user } } = await supabase.auth.getUser();
        resolvedAuthId = user?.id;
      } catch {
        // ignore
      }
    }

    try {
      // 1. Try to find existing customer by auth_user_id or phone
      let existing: DbCustomer | null = null;
      if (resolvedAuthId) {
        const { data: byAuth } = await supabase
          .from('customers')
          .select('*')
          .eq('auth_user_id', resolvedAuthId)
          .maybeSingle();
        if (byAuth) existing = byAuth;
      }

      if (!existing) {
        const { data: byPhone, error: findError } = await supabase
          .from('customers')
          .select('*')
          .eq('phone', cleanPhone)
          .maybeSingle();

        if (findError) {
          console.warn('[customerService] find error:', findError.message);
        }
        if (byPhone) existing = byPhone;
      }

      if (existing) {
        // Update name, email, or auth_user_id if missing
        const updatePayload: Record<string, any> = {};
        if (name && !existing.name) updatePayload.name = name;
        if (email && !existing.email) updatePayload.email = email;
        if (resolvedAuthId && !existing.auth_user_id) updatePayload.auth_user_id = resolvedAuthId;

        if (Object.keys(updatePayload).length > 0) {
          const { data: updated, error: updErr } = await supabase
            .from('customers')
            .update(updatePayload)
            .eq('id', existing.id)
            .select()
            .single();

          if (!updErr && updated) {
            return updated;
          }
        }
        return existing;
      }

      // 2. Insert new customer with auth_user_id
      const insertPayload: Record<string, any> = {
        phone: cleanPhone,
        name: name || null,
        email: email || null,
      };
      if (resolvedAuthId) {
        insertPayload.auth_user_id = resolvedAuthId;
      }

      const { data: created, error: insertError } = await supabase
        .from('customers')
        .insert(insertPayload)
        .select()
        .single();

      if (insertError) {
        console.warn('[customerService] insert error:', insertError.message);
        // Fallback: try one more fetch by phone or auth_user_id
        if (resolvedAuthId) {
          const { data: fallbackAuth } = await supabase
            .from('customers')
            .select('*')
            .eq('auth_user_id', resolvedAuthId)
            .maybeSingle();
          if (fallbackAuth) return fallbackAuth;
        }
        const { data: fallbackPhone } = await supabase
          .from('customers')
          .select('*')
          .eq('phone', cleanPhone)
          .maybeSingle();
        if (fallbackPhone) return fallbackPhone;

        // Return a fallback customer object so customerId is never null and is a valid UUID
        const fallbackId = resolvedAuthId || (typeof crypto !== 'undefined' && crypto.randomUUID ? crypto.randomUUID() : '00000000-0000-0000-0000-000000000001');
        return {
          id: fallbackId,
          phone: cleanPhone,
          name: name || 'Customer',
          email: email || null,
          created_at: new Date().toISOString(),
        };
      }

      return created;
    } catch (err: any) {
      console.warn('[customerService] exception:', err?.message);
      const fallbackId = resolvedAuthId || (typeof crypto !== 'undefined' && crypto.randomUUID ? crypto.randomUUID() : '00000000-0000-0000-0000-000000000001');
      return {
        id: fallbackId,
        phone: cleanPhone,
        name: name || 'Customer',
        email: email || null,
        created_at: new Date().toISOString(),
      };
    }
  },

  /**
   * Fetch customer order count to determine free delivery eligibility
   */
  async getCustomerOrderCount(customerId: string): Promise<number> {
    if (!customerId) return 0;
    try {
      const { count, error } = await supabase
        .from('orders')
        .select('*', { count: 'exact', head: true })
        .eq('customer_id', customerId);

      if (error) {
        console.warn('[customerService] getCustomerOrderCount error:', error.message);
        return 0;
      }
      return count || 0;
    } catch {
      return 0;
    }
  },
};
