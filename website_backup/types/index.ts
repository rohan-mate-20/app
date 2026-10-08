import { DbAddress, DbDeliverySlot, DbDeliverySettings, OrderStatus, PaymentMethod } from './database';

export interface Product {
  id: string;
  name: string;
  category: string;
  weight: string;
  price: number;
  originalPrice: number;
  discountPercent: number;
  rating: number;
  reviewCount: number;
  image: string;
  gallery?: string[];
  inStock: boolean;
  stockCount: number;
  badge?: string;
  description: string;
  highlights?: string[];
  brand: string;
  deliveryTime: string;
}

export interface CartItem {
  product: Product;
  quantity: number;
}

export interface Category {
  id: string;
  name: string;
  slug: string;
  icon: string; // url or icon name
  itemCount?: string;
  subcategories: string[];
}

export interface Address {
  id: string;
  customerId?: string;
  label: string; // 'Home' | 'Work' | 'Other'
  fullName: string;
  phone: string;
  line1: string;
  line2?: string;
  city: string;
  state: string;
  pincode: string;
  latitude: number;
  longitude: number;
  isDefault?: boolean;
}

export interface DeliverySlotItem {
  id: string;
  name: string;
  time: string;
  date: string;
  fee: string;
  isAvailable: boolean;
}

export interface Order {
  id: string; // DB UUID
  orderNumber: string; // KM-001234
  items: CartItem[];
  itemTotal: number; // Subtotal
  discount: number;
  deliveryFee: number;
  totalAmount: number; // Total
  couponCode?: string;
  deliveryAddress: Address | null;
  deliverySlot: {
    slotId?: string;
    time: string;
    day: string;
    date?: string;
  };
  paymentMethod: 'Cash on Delivery' | 'Razorpay' | 'COD' | 'ONLINE';
  paymentId?: string;
  status: OrderStatus | 'Order Confirmed' | 'Packed' | 'Out for Delivery' | 'Delivered';
  createdAt: string;
}

export interface UserProfile {
  id?: string;
  name: string;
  phone: string;
  email?: string;
  dob?: string;
  isVerified: boolean;
  avatar: string;
  whatsappOptIn: boolean;
}

export type { DbDeliverySettings, DbDeliverySlot };
