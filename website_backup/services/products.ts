import { supabase } from '../lib/supabase/client';
import { Product } from '../types';

const PRODUCT_IMAGE_FALLBACKS: { keywords: string[]; url: string }[] = [
  { keywords: ['atta', 'flour', 'wheat', 'grain'], url: 'https://images.unsplash.com/photo-1586444248902-2f64eddc13df?auto=format&fit=crop&w=600&q=80' },
  { keywords: ['milk', 'dairy', 'amul'], url: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80' },
  { keywords: ['banana', 'fruit'], url: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=600&q=80' },
  { keywords: ['colgate', 'toothpaste', 'oral', 'brush'], url: 'https://images.unsplash.com/photo-1559591937-e1032b5087a9?auto=format&fit=crop&w=600&q=80' },
  { keywords: ['surf', 'detergent', 'washing', 'soap', 'clean'], url: 'https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?auto=format&fit=crop&w=600&q=80' },
  { keywords: ['oil', 'saffola', 'sunflower', 'cooking'], url: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=600&q=80' },
];

const GENERIC_FALLBACK = 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80';

function resolveImage(productName: string, imageUrl: string | null): string {
  if (imageUrl) return imageUrl;
  const lower = productName.toLowerCase();
  for (const entry of PRODUCT_IMAGE_FALLBACKS) {
    if (entry.keywords.some((kw) => lower.includes(kw))) {
      return entry.url;
    }
  }
  return GENERIC_FALLBACK;
}

export function categoryNameToSlug(name: string): string {
  return name
    .toLowerCase()
    .replace(/&/g, 'and')
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9-]/g, '')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

export const productService = {
  async fetchDbProducts(storeId?: string, client = supabase): Promise<Product[]> {
    try {
      let query = client
        .from('products')
        .select(`
          *,
          categories ( id, name ),
          inventory ( store_id, stock_quantity )
        `)
        .eq('active', true)
        .order('name');

      const { data: dbProducts, error } = await query;

      if (error) {
        console.warn('[productService] DB error:', error.message);
        return [];
      }

      if (!dbProducts || dbProducts.length === 0) {
        return [];
      }

      const mapped: Product[] = dbProducts.map((p: any) => {
        const discountPercent =
          p.mrp > p.selling_price
            ? Math.round(((p.mrp - p.selling_price) / p.mrp) * 100)
            : 0;

        const dbCategoryName: string = p.categories?.name || '';
        const categorySlug = dbCategoryName
          ? categoryNameToSlug(dbCategoryName)
          : 'groceries';

        // Calculate store-specific stock if storeId provided, or total across stores
        let stockQty = 0;
        if (Array.isArray(p.inventory) && p.inventory.length > 0) {
          if (storeId) {
            const storeInv = p.inventory.find((inv: any) => inv.store_id === storeId);
            stockQty = storeInv?.stock_quantity ?? 0;
          } else {
            stockQty = p.inventory.reduce(
              (sum: number, inv: any) => sum + (inv.stock_quantity || 0),
              0
            );
          }
        } else if (p.inventory?.stock_quantity != null) {
          stockQty = p.inventory.stock_quantity;
        } else {
          // If no inventory row synced yet, default to in-stock for active catalog items
          stockQty = 50;
        }

        return {
          id: p.id,
          name: p.name,
          category: categorySlug,
          weight: p.weight_unit || '1 unit',
          price: Number(p.selling_price),
          originalPrice: Number(p.mrp),
          discountPercent,
          rating: 4.6,
          reviewCount: 25,
          image: resolveImage(p.name, p.image_url),
          gallery: undefined,
          inStock: stockQty > 0,
          stockCount: stockQty,
          badge: discountPercent > 0 ? `${discountPercent}% OFF` : undefined,
          brand: p.brand || 'K MART',
          deliveryTime: 'Delivery on time',
          highlights: [
            '100% Genuine Branded Pack',
            'Quality Guaranteed',
            'Best Market Price',
          ],
          description:
            p.description ||
            `${p.name} — fresh daily essential available for guaranteed on-time doorstep delivery from K MART.`,
        };
      });

      return mapped;
    } catch (err: any) {
      console.warn('[productService] exception:', err?.message);
      return [];
    }
  },
};
