import { supabase } from '../lib/supabase/client';
import { CartItem, Product } from '../types';

export const cartService = {
  /**
   * Get or create a cart row for the customer
   */
  async getOrCreateCartId(customerId: string): Promise<string | null> {
    if (!customerId) return null;

    try {
      // 1. Look for existing cart
      const { data: existing } = await supabase
        .from('carts')
        .select('id')
        .eq('customer_id', customerId)
        .maybeSingle();

      if (existing?.id) return existing.id;

      // 2. Create if not found
      const { data: created, error } = await supabase
        .from('carts')
        .insert({ customer_id: customerId })
        .select('id')
        .single();

      if (error) {
        console.warn('[cartService] create cart error:', error.message);
        return null;
      }

      return created.id;
    } catch (err: any) {
      console.warn('[cartService] getOrCreateCartId exception:', err?.message);
      return null;
    }
  },

  /**
   * Load items from the DB cart
   */
  async loadCartItems(cartId: string): Promise<CartItem[]> {
    if (!cartId) return [];

    try {
      const { data, error } = await supabase
        .from('cart_items')
        .select(`
          quantity,
          product_id,
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
        `)
        .eq('cart_id', cartId);

      if (error || !data) {
        console.warn('[cartService] loadCartItems error:', error?.message);
        return [];
      }

      const items: CartItem[] = [];

      for (const item of data) {
        const p: any = item.products;
        if (!p) continue;

        const discountPercent =
          p.mrp > p.selling_price
            ? Math.round(((p.mrp - p.selling_price) / p.mrp) * 100)
            : 0;

        const product: Product = {
          id: p.id,
          name: p.name,
          category: p.categories?.name || 'Groceries',
          weight: p.weight_unit || '1 unit',
          price: Number(p.selling_price),
          originalPrice: Number(p.mrp),
          discountPercent,
          rating: 4.5,
          reviewCount: 20,
          image: p.image_url || 'https://placehold.co/400x400?text=Product',
          inStock: true,
          stockCount: 50,
          badge: discountPercent > 0 ? `${discountPercent}% OFF` : undefined,
          brand: p.brand || 'K MART',
          deliveryTime: 'Delivery on time',
          description: p.description || p.name,
        };

        items.push({
          product,
          quantity: item.quantity,
        });
      }

      return items;
    } catch (err: any) {
      console.warn('[cartService] loadCartItems exception:', err?.message);
      return [];
    }
  },

  /**
   * Upsert a cart item in DB
   */
  async upsertCartItem(cartId: string, productId: string, quantity: number): Promise<void> {
    if (!cartId || !productId) return;

    try {
      if (quantity <= 0) {
        await supabase
          .from('cart_items')
          .delete()
          .eq('cart_id', cartId)
          .eq('product_id', productId);
        return;
      }

      const { error } = await supabase
        .from('cart_items')
        .upsert(
          {
            cart_id: cartId,
            product_id: productId,
            quantity,
          },
          { onConflict: 'cart_id,product_id' }
        );

      if (error) {
        console.warn('[cartService] upsertCartItem error:', error.message);
      }
    } catch (err: any) {
      console.warn('[cartService] upsertCartItem exception:', err?.message);
    }
  },

  /**
   * Clear all items from a customer cart in DB
   */
  async clearCart(cartId: string): Promise<void> {
    if (!cartId) return;

    try {
      await supabase.from('cart_items').delete().eq('cart_id', cartId);
    } catch (err: any) {
      console.warn('[cartService] clearCart error:', err?.message);
    }
  },
};
