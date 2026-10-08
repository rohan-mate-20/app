'use client';

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { Product, CartItem, Address, UserProfile, Order, Category, DeliverySlotItem } from '../types';
import { productService } from '../services/products';
import { storeService, calculateDistanceKm } from '../services/stores';
import { categoryService } from '../services/categories';
import { orderService } from '../services/orders';
import { customerService } from '../services/customers';
import { addressService } from '../services/addresses';
import { deliveryService } from '../services/delivery';
import { cartService } from '../services/cart';
import { supabase } from '../lib/supabase/client';
import { DbStore, DbCustomer, DbDeliverySettings } from '../types/database';

interface AppContextType {
  products: Product[];
  isLoadingProducts: boolean;
  categories: Category[];
  cart: CartItem[];
  cartCount: number;
  itemTotal: number;
  discount: number;
  deliveryFee: number;
  totalAmount: number;
  appliedCoupon: string | null;
  couponDiscount: number;
  addToCart: (product: Product, quantity?: number) => void;
  updateQuantity: (productId: string, quantity: number) => void;
  removeFromCart: (productId: string) => void;
  clearCart: () => void;
  applyCoupon: (code: string) => { success: boolean; message: string };
  removeCoupon: () => void;

  // Customer / User & Address
  user: UserProfile;
  setUser: React.Dispatch<React.SetStateAction<UserProfile>>;
  currentCustomer: DbCustomer | null;
  addresses: Address[];
  selectedAddress: Address | null;
  setSelectedAddress: (addr: Address | null) => void;
  addAddress: (newAddr: Omit<Address, 'id'>) => Promise<Address | null>;

  // Store & Distance
  stores: DbStore[];
  activeStore: DbStore | null;
  setActiveStore: (store: DbStore | null) => void;
  storeDistanceKm: number;

  // Delivery settings & Slots
  deliverySettings: DbDeliverySettings;
  deliverySlots: DeliverySlotItem[];
  selectedSlot: DeliverySlotItem;
  setSelectedSlot: (slot: DeliverySlotItem) => void;

  // Modals & Navigation
  isAuthOpen: boolean;
  setIsAuthOpen: (open: boolean) => void;
  isLocationOpen: boolean;
  setIsLocationOpen: (open: boolean) => void;
  isCartOpen: boolean;
  setIsCartOpen: (open: boolean) => void;
  activeProductModal: Product | null;
  setActiveProductModal: (prod: Product | null) => void;
  isCheckoutOpen: boolean;
  setIsCheckoutOpen: (open: boolean) => void;
  checkoutStep: number;
  setCheckoutStep: (step: number) => void;

  // Orders
  orders: Order[];
  activeConfirmedOrder: Order | null;
  setActiveConfirmedOrder: (order: Order | null) => void;
  isOrdersModalOpen: boolean;
  setIsOrdersModalOpen: (open: boolean) => void;
  placeOrder: (paymentMethod: 'Cash on Delivery' | 'Razorpay', customPaymentId?: string) => Promise<Order>;

  // Filter & Search
  selectedCategory: string;
  setSelectedCategory: (cat: string) => void;
  searchQuery: string;
  setSearchQuery: (query: string) => void;
  wishlist: string[];
  toggleWishlist: (productId: string) => void;

  // Mobile preview view switch
  viewMode: 'desktop' | 'mobile-preview';
  setViewMode: (mode: 'desktop' | 'mobile-preview') => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

const BLANK_USER: UserProfile = {
  name: '',
  phone: '',
  email: '',
  isVerified: false,
  avatar: '/profile-avatar.png',
  whatsappOptIn: false,
};

const DEFAULT_DELIVERY_SETTINGS: DbDeliverySettings = {
  id: 1,
  min_order_value: 500,
  tier1_max_value: 999,
  tier1_fee: 40,
  tier2_fee: 30,
  free_delivery_order_count: 3,
};

const DEFAULT_SLOT: DeliverySlotItem = {
  id: 'slot-morning',
  name: 'Morning',
  time: '8:00 AM - 12:00 PM',
  date: new Date().toISOString().split('T')[0],
  fee: 'Free delivery',
  isAvailable: true,
};

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [isLoadingProducts, setIsLoadingProducts] = useState(true);
  const [stores, setStores] = useState<DbStore[]>([]);
  const [activeStore, setActiveStore] = useState<DbStore | null>(null);
  const [storeDistanceKm, setStoreDistanceKm] = useState<number>(0);

  // Customer & Auth state
  const [user, setUser] = useState<UserProfile>(BLANK_USER);
  const [currentCustomer, setCurrentCustomer] = useState<DbCustomer | null>(null);
  const [customerOrderCount, setCustomerOrderCount] = useState<number>(0);

  // Cart state
  const [cart, setCart] = useState<CartItem[]>([]);
  const [dbCartId, setDbCartId] = useState<string | null>(null);
  const [isCartLoaded, setIsCartLoaded] = useState(false);

  // Addresses state
  const [addresses, setAddresses] = useState<Address[]>([]);
  const [selectedAddress, setSelectedAddress] = useState<Address | null>(null);

  // Delivery settings & Slots
  const [deliverySettings, setDeliverySettings] = useState<DbDeliverySettings>(DEFAULT_DELIVERY_SETTINGS);
  const [deliverySlots, setDeliverySlots] = useState<DeliverySlotItem[]>([DEFAULT_SLOT]);
  const [selectedSlot, setSelectedSlot] = useState<DeliverySlotItem>(DEFAULT_SLOT);

  // Coupons & Wishlist
  const [appliedCoupon, setAppliedCoupon] = useState<string | null>(null);
  const [wishlist, setWishlist] = useState<string[]>([]);

  // Modals state
  const [isAuthOpen, setIsAuthOpen] = useState(false);
  const [isLocationOpen, setIsLocationOpen] = useState(false);
  const [isCartOpen, setIsCartOpen] = useState(false);
  const [activeProductModal, setActiveProductModal] = useState<Product | null>(null);
  const [isCheckoutOpen, setIsCheckoutOpen] = useState(false);
  const [checkoutStep, setCheckoutStep] = useState(1);
  const [isOrdersModalOpen, setIsOrdersModalOpen] = useState(false);
  const [activeConfirmedOrder, setActiveConfirmedOrder] = useState<Order | null>(null);

  // Search & Filters
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [viewMode, setViewMode] = useState<'desktop' | 'mobile-preview'>('desktop');

  // Orders list
  const [orders, setOrders] = useState<Order[]>([]);

  // ----------------------------------------------------
  // 1. Initial Load: Catalog, Stores, Delivery Settings
  // ----------------------------------------------------
  useEffect(() => {
    async function loadInitialData() {
      setIsLoadingProducts(true);
      try {
        const [dbStores, settings, dbCategories] = await Promise.all([
          storeService.getStores(),
          deliveryService.getDeliverySettings(),
          categoryService.fetchDbCategories(),
        ]);

        if (settings) {
          setDeliverySettings(settings);
        }

        let store: DbStore | null = null;
        if (dbStores && dbStores.length > 0) {
          setStores(dbStores);
          store = dbStores[0];
          setActiveStore(store);
          setStoreDistanceKm(store.service_radius_km ? 2.4 : 0);
        } else {
          setStores([]);
          setActiveStore(null);
          setStoreDistanceKm(0);
        }

        const [dbProducts, slots] = await Promise.all([
          productService.fetchDbProducts(store?.id),
          deliveryService.getAvailableSlots(store?.id),
        ]);

        setProducts(dbProducts ?? []);
        setCategories(dbCategories ?? []);
        if (slots && slots.length > 0) {
          setDeliverySlots(slots);
          setSelectedSlot(slots[0]);
        }
      } catch (err) {
        console.warn('[AppContext] Error loading catalog/stores from DB:', err);
      } finally {
        setIsLoadingProducts(false);
      }
    }

    loadInitialData();
  }, []);

  // ----------------------------------------------------
  // 2. Auth & Customer Sync (Phone-based customers table)
  // ----------------------------------------------------
  const syncCustomerProfile = useCallback(async (phone: string, name?: string, email?: string, authUserId?: string) => {
    if (!phone) return;
    try {
      const dbCust = await customerService.upsertCustomer(phone, name, email, authUserId);
      if (dbCust) {
        setCurrentCustomer(dbCust);
        setUser(prev => ({
          ...prev,
          id: dbCust.id,
          phone: dbCust.phone,
          name: dbCust.name || prev.name,
          email: dbCust.email || prev.email,
          isVerified: true,
        }));

        // Load customer past orders & order count
        const [count, custOrders, custAddresses, cartId] = await Promise.all([
          customerService.getCustomerOrderCount(dbCust.id),
          orderService.fetchUserOrders(dbCust.id),
          addressService.getAddresses(dbCust.id),
          cartService.getOrCreateCartId(dbCust.id),
        ]);

        setCustomerOrderCount(count);
        if (custOrders && custOrders.length > 0) {
          setOrders(prev => {
            const mergedMap = new Map<string, Order>();
            // Add DB orders
            custOrders.forEach(o => mergedMap.set(o.orderNumber || o.id, o));
            // Preserve any existing local orders not in DB
            prev.forEach(o => {
              const key = o.orderNumber || o.id;
              if (!mergedMap.has(key)) {
                mergedMap.set(key, o);
              }
            });
            const merged = Array.from(mergedMap.values());
            try {
              localStorage.setItem('kmart_orders', JSON.stringify(merged));
            } catch {}
            return merged;
          });
        }

        if (custAddresses.length > 0) {
          setAddresses(custAddresses);
          const def = custAddresses.find(a => a.isDefault) || custAddresses[0];
          setSelectedAddress(def);
        }

        if (cartId) {
          setDbCartId(cartId);
          // Sync DB cart items
          const dbCartItems = await cartService.loadCartItems(cartId);
          if (dbCartItems.length > 0) {
            setCart(dbCartItems);
          }
        }
      }
    } catch (err) {
      console.warn('[AppContext] syncCustomerProfile error:', err);
    }
  }, []);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session?.user) {
        const supaUser = session.user;
        const phone = supaUser.phone || supaUser.user_metadata?.phone || '';
        const name = supaUser.user_metadata?.full_name || supaUser.user_metadata?.name || '';
        const email = supaUser.email || '';
        if (phone) {
          syncCustomerProfile(phone, name, email, supaUser.id);
        }
      }
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      if (session?.user) {
        const supaUser = session.user;
        const phone = supaUser.phone || supaUser.user_metadata?.phone || '';
        const name = supaUser.user_metadata?.full_name || supaUser.user_metadata?.name || '';
        const email = supaUser.email || '';
        if (phone) {
          syncCustomerProfile(phone, name, email, supaUser.id);
        }
      } else {
        setUser(BLANK_USER);
        setCurrentCustomer(null);
        setOrders([]);
        setAddresses([]);
        setSelectedAddress(null);
        setDbCartId(null);
        try {
          localStorage.removeItem('kmart_orders');
        } catch {}
      }
    });

    return () => subscription.unsubscribe();
  }, [syncCustomerProfile]);

  // ----------------------------------------------------
  // 3. Fallback Local Storage for Addresses (when not logged in)
  // ----------------------------------------------------
  useEffect(() => {
    if (currentCustomer) return; // DB is source of truth for logged-in users

    try {
      const savedAddresses = localStorage.getItem('kmart_user_addresses');
      if (savedAddresses) {
        const parsed = JSON.parse(savedAddresses);
        if (Array.isArray(parsed) && parsed.length > 0) {
          setAddresses(parsed);
          const savedSelected = localStorage.getItem('kmart_selected_address');
          if (savedSelected) {
            setSelectedAddress(JSON.parse(savedSelected));
          } else {
            setSelectedAddress(parsed[0]);
          }
        }
      }
    } catch (e) {
      console.warn('Failed to load addresses from localStorage:', e);
    }
  }, [currentCustomer]);

  // ----------------------------------------------------
  // 3b. Order History Persistence (LocalStorage cache)
  // ----------------------------------------------------
  useEffect(() => {
    try {
      const savedOrders = localStorage.getItem('kmart_orders');
      if (savedOrders) {
        const parsed = JSON.parse(savedOrders);
        if (Array.isArray(parsed) && parsed.length > 0) {
          setOrders(prev => {
            const mergedMap = new Map<string, Order>();
            prev.forEach(o => mergedMap.set(o.orderNumber || o.id, o));
            parsed.forEach(o => {
              const key = o.orderNumber || o.id;
              if (!mergedMap.has(key)) {
                mergedMap.set(key, o);
              }
            });
            return Array.from(mergedMap.values());
          });
        }
      }
    } catch (e) {
      console.warn('Failed to load orders from localStorage:', e);
    }
  }, []);

  // ----------------------------------------------------
  // 4. Cart Persistence (DB-backed for logged in, localStorage fallback)
  // ----------------------------------------------------
  useEffect(() => {
    try {
      const savedCart = localStorage.getItem('kmart_cart_items');
      if (savedCart !== null) {
        const parsed = JSON.parse(savedCart);
        if (Array.isArray(parsed)) {
          setCart(parsed);
        }
      }
    } catch (e) {
      console.warn('Failed to load cart from localStorage:', e);
    } finally {
      setIsCartLoaded(true);
    }
  }, []);

  useEffect(() => {
    if (!isCartLoaded) return;
    try {
      localStorage.setItem('kmart_cart_items', JSON.stringify(cart));
    } catch (e) {
      console.warn('Failed to save cart to localStorage:', e);
    }
  }, [cart, isCartLoaded]);

  // ----------------------------------------------------
  // 5. Calculations: Subtotal, DB Delivery Fee, Total
  // ----------------------------------------------------
  const cartCount = cart.reduce((sum, item) => sum + item.quantity, 0);
  const originalTotal = cart.reduce((sum, item) => sum + (item.product.originalPrice * item.quantity), 0);
  const itemTotal = cart.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);
  const catalogDiscount = Math.max(0, originalTotal - itemTotal);

  // Delivery fee calculated from DB settings table
  const deliveryCalc = deliveryService.calculateDeliveryFee(
    itemTotal,
    deliverySettings,
    customerOrderCount
  );
  const deliveryFee = itemTotal === 0 ? 0 : deliveryCalc.fee;
  const couponDiscount = 0;
  const discount = catalogDiscount;
  const totalAmount = Math.max(0, itemTotal + deliveryFee);

  // ----------------------------------------------------
  // 6. Cart Actions (Syncs to DB if customer logged in)
  // ----------------------------------------------------
  const addToCart = (product: Product, quantity = 1) => {
    setCart(prev => {
      const existing = prev.find(item => item.product.id === product.id);
      let nextCart: CartItem[];
      if (existing) {
        nextCart = prev.map(item =>
          item.product.id === product.id ? { ...item, quantity: item.quantity + quantity } : item
        );
      } else {
        nextCart = [...prev, { product, quantity }];
      }

      if (dbCartId) {
        const targetQty = existing ? existing.quantity + quantity : quantity;
        cartService.upsertCartItem(dbCartId, product.id, targetQty);
      }

      return nextCart;
    });
  };

  const updateQuantity = (productId: string, quantity: number) => {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    setCart(prev => prev.map(item =>
      item.product.id === productId ? { ...item, quantity } : item
    ));

    if (dbCartId) {
      cartService.upsertCartItem(dbCartId, productId, quantity);
    }
  };

  const removeFromCart = (productId: string) => {
    setCart(prev => {
      const next = prev.filter(item => item.product.id !== productId);
      return next;
    });

    if (dbCartId) {
      cartService.upsertCartItem(dbCartId, productId, 0);
    }
  };

  const clearCart = () => {
    setCart([]);
    try {
      localStorage.setItem('kmart_cart_items', JSON.stringify([]));
    } catch {}

    if (dbCartId) {
      cartService.clearCart(dbCartId);
    }
  };

  const applyCoupon = (_code: string) => {
    return { success: false, message: 'Coupons will be enabled shortly.' };
  };

  const removeCoupon = () => {
    setAppliedCoupon(null);
  };

  // ----------------------------------------------------
  // 7. Address Management (DB for logged in + localStorage)
  // ----------------------------------------------------
  const handleSetSelectedAddress = (addr: Address | null) => {
    setSelectedAddress(addr);
    try {
      if (addr) {
        localStorage.setItem('kmart_selected_address', JSON.stringify(addr));
        if (activeStore && addr.latitude && addr.longitude) {
          const dist = calculateDistanceKm(
            activeStore.latitude,
            activeStore.longitude,
            addr.latitude,
            addr.longitude
          );
          setStoreDistanceKm(Number(dist.toFixed(2)));
        }
      } else {
        localStorage.removeItem('kmart_selected_address');
      }
    } catch {}
  };

  const addAddress = async (newAddr: Omit<Address, 'id'>): Promise<Address | null> => {
    let saved: Address | null = null;

    if (currentCustomer?.id) {
      saved = await addressService.addAddress(currentCustomer.id, newAddr);
    }

    const addr: Address = saved || {
      ...newAddr,
      id: `addr-${Date.now()}`,
      isDefault: addresses.length === 0,
    };

    setAddresses(prev => {
      const next = [addr, ...prev];
      try {
        localStorage.setItem('kmart_user_addresses', JSON.stringify(next));
      } catch {}
      return next;
    });

    handleSetSelectedAddress(addr);
    return addr;
  };

  const toggleWishlist = (productId: string) => {
    setWishlist(prev =>
      prev.includes(productId) ? prev.filter(id => id !== productId) : [...prev, productId]
    );
  };

  // ----------------------------------------------------
  // 8. Place Order (Real orders + order_items schema)
  // ----------------------------------------------------
  const placeOrder = async (
    paymentMethod: 'Cash on Delivery' | 'Razorpay',
    customPaymentId?: string
  ): Promise<Order> => {
    // Authentication guard: Orders require verified login
    if (!user.isVerified && !currentCustomer) {
      setIsAuthOpen(true);
      throw new Error('Please login to place your order.');
    }

    // Generate standard order number format: KM-001234
    const randomSeq = Math.floor(1000 + Math.random() * 900000);
    const orderNumber = `KM-${String(randomSeq).padStart(6, '0')}`;

    // Ensure customer row exists in DB
    let customerId = currentCustomer?.id;
    if (!customerId && (user.phone || selectedAddress?.phone)) {
      const phone = user.phone || selectedAddress?.phone || '';
      const name = user.name || selectedAddress?.fullName || 'Customer';
      let authUserId = user.id;
      if (!authUserId) {
        try {
          const authUser = (await supabase.auth.getUser()).data.user;
          authUserId = authUser?.id;
        } catch {}
      }
      const cust = await customerService.upsertCustomer(phone, name, user.email, authUserId);
      if (cust) {
        customerId = cust.id;
        setCurrentCustomer(cust);
      }
    }

    const deliveryAddressSnapshot = selectedAddress
      ? {
          label: selectedAddress.label,
          full_name: selectedAddress.fullName,
          phone: selectedAddress.phone,
          line1: selectedAddress.line1,
          line2: selectedAddress.line2,
          city: selectedAddress.city,
          state: selectedAddress.state,
          pincode: selectedAddress.pincode,
          latitude: selectedAddress.latitude,
          longitude: selectedAddress.longitude,
        }
      : {};

    const customerSnapshot = {
      name: selectedAddress?.fullName || user.name || 'Customer',
      phone: selectedAddress?.phone || user.phone || '',
      email: user.email || '',
    };

    const newOrder: Order = {
      id: orderNumber,
      orderNumber,
      items: [...cart],
      itemTotal,
      discount,
      deliveryFee,
      totalAmount,
      couponCode: appliedCoupon || undefined,
      deliveryAddress: selectedAddress,
      deliverySlot: {
        slotId: selectedSlot.id,
        time: selectedSlot.time,
        day: selectedSlot.date || 'Today',
        date: selectedSlot.date,
      },
      paymentMethod,
      paymentId: customPaymentId,
      status: 'Order Confirmed',
      createdAt: new Date().toISOString(),
    };

    const storeId = activeStore?.id || stores[0]?.id || '458cbfde-68fd-4e71-86c7-a12a4cecad4d';

    // Save to DB if we have a valid customer
    if (customerId) {
      try {
        const result = await orderService.saveOrderToDb({
          orderNumber,
          customerId,
          storeId,
          items: cart,
          subtotal: itemTotal,
          deliveryFee,
          total: totalAmount,
          deliverySlotId: selectedSlot.id.startsWith('slot-') ? null : selectedSlot.id,
          scheduledDeliveryDate: selectedSlot.date,
          deliveryAddressSnapshot,
          customerSnapshot,
          paymentMethod: paymentMethod === 'Cash on Delivery' ? 'COD' : 'ONLINE',
          paymentId: customPaymentId,
        });

        if (result.success && result.orderId) {
          newOrder.id = result.orderId;
        }
      } catch (saveErr) {
        console.warn('[AppContext] Failed to save order to DB:', saveErr);
      }
    }

    setOrders(prev => {
      const next = [newOrder, ...prev.filter(o => o.id !== newOrder.id && o.orderNumber !== newOrder.orderNumber)];
      try {
        localStorage.setItem('kmart_orders', JSON.stringify(next));
      } catch (e) {
        console.warn('Failed to save order to localStorage:', e);
      }
      return next;
    });
    setActiveConfirmedOrder(newOrder);
    clearCart();
    setIsCheckoutOpen(false);
    return newOrder;
  };

  return (
    <AppContext.Provider value={{
      products,
      isLoadingProducts,
      categories,
      cart,
      cartCount,
      itemTotal,
      discount,
      deliveryFee,
      totalAmount,
      appliedCoupon,
      couponDiscount,
      addToCart,
      updateQuantity,
      removeFromCart,
      clearCart,
      applyCoupon,
      removeCoupon,
      user,
      setUser,
      currentCustomer,
      addresses,
      selectedAddress,
      setSelectedAddress: handleSetSelectedAddress,
      addAddress,
      stores,
      activeStore,
      setActiveStore,
      storeDistanceKm,
      deliverySettings,
      deliverySlots,
      selectedSlot,
      setSelectedSlot,
      isAuthOpen,
      setIsAuthOpen,
      isLocationOpen,
      setIsLocationOpen,
      isCartOpen,
      setIsCartOpen,
      activeProductModal,
      setActiveProductModal,
      isCheckoutOpen,
      setIsCheckoutOpen,
      checkoutStep,
      setCheckoutStep,
      orders,
      activeConfirmedOrder,
      setActiveConfirmedOrder,
      isOrdersModalOpen,
      setIsOrdersModalOpen,
      placeOrder,
      selectedCategory,
      setSelectedCategory,
      searchQuery,
      setSearchQuery,
      wishlist,
      toggleWishlist,
      viewMode,
      setViewMode,
    }}>
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used within an AppProvider');
  return context;
};
