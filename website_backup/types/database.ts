export type UserRole = 'CUSTOMER' | 'PACKER' | 'DELIVERY' | 'ADMIN';

export type OrderType = 'DELIVERY' | 'PICKUP';

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

export type PaymentStatus = 'PENDING' | 'PAID' | 'FAILED' | 'REFUNDED';

export type PaymentMethod = 'COD' | 'ONLINE';

export interface DbStore {
  id: string;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  service_radius_km: number;
  gofrugal_account_id: string;
  active: boolean;
  created_at?: string;
}

export interface DbCustomer {
  id: string;
  phone: string;
  name: string | null;
  email: string | null;
  auth_user_id?: string | null;
  created_at?: string;
}

export interface DbStaff {
  id: string;
  auth_user_id: string | null;
  name: string;
  email: string;
  role: 'PACKER' | 'DELIVERY';
  store_id: string;
  employee_id: string | null;
  active: boolean;
  created_at?: string;
}

export interface DbAdmin {
  id: string;
  auth_user_id: string | null;
  name: string;
  email: string;
  created_at?: string;
}

export interface DbCategory {
  id: string;
  name: string;
  parent_id: string | null;
}

export interface DbProduct {
  id: string;
  sku: string | null;
  barcode: string | null;
  name: string;
  brand: string | null;
  category_id: string | null;
  description: string | null;
  mrp: number;
  selling_price: number;
  tax_percent: number;
  weight_unit: string | null;
  image_url: string | null;
  shopify_product_id: string | null;
  shopify_variant_id: string | null;
  active: boolean;
  created_at?: string;
  updated_at?: string;
  categories?: {
    id: string;
    name: string;
  } | null;
  inventory?: {
    store_id?: string;
    stock_quantity: number;
  }[] | {
    stock_quantity: number;
  } | null;
}

export interface DbInventory {
  id: string;
  product_id: string;
  store_id: string;
  gofrugal_item_id: string;
  stock_quantity: number;
  last_synced_at?: string | null;
}

export interface DbRelatedProduct {
  id: string;
  product_id: string;
  related_product_id: string;
}

export interface DbAddress {
  id: string;
  customer_id: string;
  label: string | null;
  full_name: string;
  phone: string;
  line1: string;
  line2: string | null;
  city: string;
  state: string;
  pincode: string;
  latitude: number;
  longitude: number;
  is_default: boolean;
  created_at?: string;
}

export interface DbCart {
  id: string;
  customer_id: string;
  updated_at?: string;
}

export interface DbCartItem {
  id: string;
  cart_id: string;
  product_id: string;
  quantity: number;
  products?: DbProduct;
}

export interface DbDeliverySlot {
  id: string;
  slot_date: string;
  slot_name: string; // e.g. "Morning", "Evening"
  start_time: string;
  end_time: string;
  order_cutoff_time: string;
  store_id: string;
  capacity: number;
  current_bookings: number;
}

export interface DbOrder {
  id: string;
  order_number: string;
  customer_id: string;
  store_id: string;
  order_type: OrderType;
  status: OrderStatus;
  payment_status: PaymentStatus;
  payment_method: PaymentMethod;
  subtotal: number;
  delivery_fee: number;
  total: number;
  delivery_slot_id: string | null;
  scheduled_delivery_date: string | null;
  delivery_address_snapshot: any;
  customer_snapshot: any;
  idempotency_key?: string | null;
  created_at: string;
  updated_at?: string;
  order_items?: DbOrderItem[];
}

export interface DbOrderItem {
  id: string;
  order_id: string;
  product_id: string;
  product_name: string;
  quantity: number;
  unit_mrp: number;
  unit_selling_price: number;
  tax?: number;
  line_total: number;
  is_available: boolean;
}

export interface DbDeliverySettings {
  id: number;
  min_order_value: number;
  tier1_max_value: number;
  tier1_fee: number;
  tier2_fee: number;
  free_delivery_order_count: number;
}
