import { supabase } from '../lib/supabase/client';
import { Category } from '../types';
import { categoryNameToSlug } from './products';

const CATEGORY_ICONS: Record<string, string> = {
  groceries: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=150&q=80',
  'fruits-and-vegetables': 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=150&q=80',
  'dairy-and-eggs': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=150&q=80',
  'snacks-and-beverages': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&w=150&q=80',
  'personal-care': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=150&q=80',
  household: 'https://images.unsplash.com/photo-1583947215259-38e31be8751f?auto=format&fit=crop&w=150&q=80',
};

export const categoryService = {
  async fetchDbCategories(client = supabase): Promise<Category[]> {
    try {
      const { data, error } = await client
        .from('categories')
        .select('*')
        .order('name');

      if (error || !data || data.length === 0) {
        console.warn('[categoryService] No categories found in DB:', error?.message);
        return [];
      }

      const mapped: Category[] = data
        .filter((c: any) => !c.parent_id)
        .map((dbCat: any) => {
          const slug = categoryNameToSlug(dbCat.name);
          const icon = dbCat.icon_url || dbCat.image_url || CATEGORY_ICONS[slug] || 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=150&q=80';
          return {
            id: dbCat.id,
            name: dbCat.name,
            slug,
            icon,
            itemCount: dbCat.item_count ? `${dbCat.item_count}+ items` : undefined,
            subcategories: dbCat.subcategories || [],
          };
        });

      return mapped;
    } catch (err: any) {
      console.warn('[categoryService] exception:', err?.message);
      return [];
    }
  },
};
