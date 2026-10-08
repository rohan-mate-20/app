// This file intentionally left empty.
// All data (products, categories, stores, user info) is loaded from Supabase (PostgreSQL).
// No mock or test data is used anywhere in this application.

import { Address, UserProfile } from '../types';

// Blank user — real data filled after Supabase auth login
export const INITIAL_USER: UserProfile = {
  name: '',
  phone: '',
  email: '',
  isVerified: false,
  avatar: '/profile-avatar.png',
  whatsappOptIn: false,
};

// No pre-filled addresses — user must add their real address
export const INITIAL_ADDRESSES: Address[] = [];

// Delivery slots — these are defined by business logic, not DB, kept minimal
export const DELIVERY_SLOTS = [
  {
    id: 'slot-morning',
    name: 'Morning',
    time: '8:00 AM - 12:00 PM',
    status: 'Available',
    fee: 'Free delivery',
    icon: 'sun',
  },
  {
    id: 'slot-evening',
    name: 'Evening',
    time: '4:00 PM - 8:00 PM',
    status: 'Available',
    fee: 'Free delivery',
    icon: 'moon',
  },
];

// No hardcoded coupons — coupons should come from DB or be disabled
export const COUPONS: { code: string; discount: number; minOrder: number; description: string }[] = [];

// No mock products or categories — all come from Supabase
export const PRODUCTS: import('../types').Product[] = [];
export const CATEGORIES: import('../types').Category[] = [];
