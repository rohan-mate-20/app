'use client';
import Image from "next/image";
import React, { useState, useRef, useEffect } from 'react';
import Link from 'next/link';
import {
  MapPin,
  Search,
  Tag,
  Package,
  ShoppingCart,
  ChevronDown,
  Smartphone,
  Monitor,
  X,
  User,
  LogOut,
  LayoutGrid,
  Home,
  Flame,
  Layers
} from 'lucide-react';
import { Logo } from './Logo';
import { useApp } from '../context/AppContext';
import { supabase } from '../lib/supabase/client';
import { usePathname, useRouter } from 'next/navigation';

export const Navbar: React.FC = () => {
  const pathname = usePathname();
  const router = useRouter();

  const {
    cartCount,
    setIsCartOpen,
    setIsLocationOpen,
    selectedAddress,
    setIsOrdersModalOpen,
    setIsAuthOpen,
    user,
    products,
    setActiveProductModal,
    searchQuery,
    setSearchQuery,
    viewMode,
    setViewMode,
    categories
  } = useApp();

  const [isSearchFocused, setIsSearchFocused] = useState(false);
  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const searchRef = useRef<HTMLDivElement>(null);
  const profileRef = useRef<HTMLDivElement>(null);

  // Close search dropdown on click outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (searchRef.current && !searchRef.current.contains(e.target as Node)) {
        setIsSearchFocused(false);
      }
      if (profileRef.current && !profileRef.current.contains(e.target as Node)) {
        setIsProfileOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Hide header on login page and otp
  const isAuthPage =
    pathname === '/login' ||
    pathname === '/otp' ||
    pathname?.startsWith('/login') ||
    pathname?.startsWith('/otp');

  if (isAuthPage) {
    return null;
  }

  const searchResults = searchQuery.trim()
    ? products.filter(p =>
      p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.category.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.brand.toLowerCase().includes(searchQuery.toLowerCase())
    )
    : [];

  const handleSignOut = async () => {
    setIsProfileOpen(false);
    await supabase.auth.signOut();
    try {
      await fetch('/api/auth/logout', { method: 'POST' });
    } catch {
      // ignore
    }
  };

  return (
    <header className="sticky top-0 z-40 bg-white border-b border-gray-100 shadow-[0_2px_12px_-4px_rgba(0,0,0,0.06)]">
      {/* Top Banner alert */}
      <div className="bg-[#0A2540] text-white text-xs py-1 px-3 sm:px-4">
        <div className="max-w-[1440px] mx-auto flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="bg-[#E11A22] text-white font-bold text-[10px] px-2 py-0.5 rounded-full uppercase tracking-wider">
              Flash Deal
            </span>
            <Link href="/offers" className="text-gray-200 hover:text-white transition-colors">
              Get flat ₹45 OFF on orders above ₹250 with code <strong className="text-white underline">KMART45</strong>
            </Link>
          </div>

          <div className="flex items-center gap-4 text-gray-300">
            <button
              onClick={() => setViewMode(viewMode === 'desktop' ? 'mobile-preview' : 'desktop')}
              className="flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-white/10 hover:bg-white/20 transition-colors text-white font-medium text-xs cursor-pointer"
              title="Toggle between Desktop Website view and Mobile App Preview"
            >
              {viewMode === 'desktop' ? (
                <>
                  <Smartphone className="w-3.5 h-3.5 text-amber-300" />
                  <span>Switch to Mobile App View</span>
                </>
              ) : (
                <>
                  <Monitor className="w-3.5 h-3.5 text-blue-300" />
                  <span>Switch to Desktop View</span>
                </>
              )}
            </button>
            <span className="hidden md:inline text-gray-400">|</span>
            <span className="hidden md:inline text-gray-300">🚚 Delivery on time</span>
          </div>
        </div>
      </div>

      {/* Main Navbar */}
      <div className="max-w-[1440px] mx-auto px-3 sm:px-4 lg:px-6 py-2.5 sm:py-3">
        <div className="flex items-center justify-between gap-3 sm:gap-6">

          {/* Left: Brand Logo & Location selector */}
          <div className="flex items-center gap-4 sm:gap-8 shrink-0">
            <Link
              href="/"
              onClick={() => {
                setSearchQuery('');
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
              className="cursor-pointer transition-transform hover:scale-[1.02] block"
            >
              <Logo size="md" />
            </Link>

            {/* Location Selector Button */}
            <button
              onClick={() => setIsLocationOpen(true)}
              className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl border border-gray-200 hover:border-gray-300 hover:bg-gray-50/80 transition-all text-left group cursor-pointer"
            >
              <div className="w-8 h-8 rounded-lg bg-red-50 text-[#E11A22] flex items-center justify-center shrink-0">
                <MapPin className="w-4 h-4" />
              </div>
              <div className="flex flex-col">
                <div className="flex items-center gap-1">
                  <span className="text-[11px] font-bold text-gray-500 uppercase tracking-wider">
                    Delivering To
                  </span>

                </div>
                <div className="flex items-center gap-1">
                  <span className="text-xs sm:text-sm font-black text-[#0A2540] truncate max-w-[120px] sm:max-w-[180px]">
                    {selectedAddress?.line1 || selectedAddress?.city || 'Select Location'}
                  </span>
                  <ChevronDown className="w-3.5 h-3.5 text-gray-400 group-hover:text-gray-600 transition-transform group-hover:translate-y-0.5" />
                </div>
              </div>
            </button>
          </div>

          {/* Center: Search Bar with Autocomplete */}
          <div ref={searchRef} className="flex-1 max-w-xl relative hidden md:block">
            <form
              onSubmit={(e) => {
                e.preventDefault();
                if (searchQuery.trim()) {
                  router.push(`/search?q=${encodeURIComponent(searchQuery.trim())}`);
                  setIsSearchFocused(false);
                }
              }}
              className="relative"
            >
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onFocus={() => setIsSearchFocused(true)}
                placeholder="Search for atta, dal, milk, chips, surf excel..."
                className="w-full pl-10 pr-10 py-2.5 rounded-xl bg-gray-50 border border-gray-200 focus:bg-white focus:border-[#E11A22] focus:ring-2 focus:ring-red-100 text-xs sm:text-sm text-gray-800 placeholder:text-gray-400 outline-none transition-all"
              />
              <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              {searchQuery && (
                <button
                  type="button"
                  onClick={() => setSearchQuery('')}
                  className="w-5 h-5 rounded-full bg-gray-200 hover:bg-gray-300 text-gray-600 absolute right-3 top-1/2 -translate-y-1/2 flex items-center justify-center cursor-pointer"
                >
                  <X className="w-3 h-3" />
                </button>
              )}
            </form>

            {/* Search Autocomplete Dropdown */}
            {isSearchFocused && searchResults.length > 0 && (
              <div className="absolute top-full left-0 right-0 mt-1 bg-white border border-gray-200 rounded-xl shadow-xl overflow-hidden z-50 max-h-96 overflow-y-auto">
                <div className="p-2 border-b border-gray-100 bg-gray-50 text-[11px] font-bold text-gray-500 uppercase tracking-wider">
                  Products ({searchResults.length})
                </div>
                <div className="divide-y divide-gray-50">
                  {searchResults.map((item) => (
                    <div
                      key={item.id}
                      onClick={() => {
                        router.push(`/product/${item.id}`);
                        setIsSearchFocused(false);
                      }}
                      className="p-2.5 flex items-center gap-3 hover:bg-red-50/40 cursor-pointer transition-colors"
                    >


                      {item.image ? (
                        <img
                          src={item.image}
                          alt={item.name}
                          className="w-9 h-9 object-contain rounded-lg p-0.5 bg-gray-50 border border-gray-100 shrink-0"
                        />
                      ) : (
                        <div className="w-9 h-9 rounded-lg bg-gray-100 flex items-center justify-center text-gray-400 shrink-0 text-xs">
                          📦
                        </div>
                      )}
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-bold text-gray-800 truncate">{item.name}</p>
                        <p className="text-[11px] text-gray-500">{item.weight} • {item.brand}</p>
                      </div>
                      <div className="text-right">
                        <span className="text-xs font-black text-[#0A2540]">₹{item.price}</span>
                        {item.originalPrice > item.price && (
                          <span className="text-[10px] text-gray-400 line-through block">
                            ₹{item.originalPrice}
                          </span>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Right Action Icons: Categories, Offers, Orders, Account, Cart */}
          <div className="flex items-center gap-2 sm:gap-3">

            {/* Categories Navigation Link */}
            <Link
              href="/categories"
              className="hidden md:flex items-center gap-1.5 text-xs font-bold text-gray-700 hover:text-[#0A2540] transition-colors py-2 px-2.5 rounded-lg hover:bg-gray-100"
            >
              <LayoutGrid className="w-4 h-4 text-[#0A2540]" />
              <span>Categories</span>
            </Link>

            {/* Super Saver Deals anchor */}
            <Link
              href="/offers"
              className="hidden lg:flex items-center gap-1.5 text-xs font-bold text-gray-700 hover:text-[#E11A22] transition-colors py-2 px-2.5 rounded-lg hover:bg-gray-50"
            >
              <Tag className="w-4 h-4 text-[#E11A22]" />
              <span>Offers</span>
            </Link>

            {/* My Orders Button */}
            <Link
              href="/orders"
              className="flex items-center gap-1.5 text-xs font-bold text-gray-700 hover:text-[#0A2540] transition-colors py-2 px-2 sm:px-2.5 rounded-xl hover:bg-gray-100 cursor-pointer"
            >
              <Package className="w-4 h-4 text-[#0A2540]" />
              <span className="hidden sm:inline">Orders</span>
            </Link>

            {/* User Profile / Login Button */}
            <div ref={profileRef} className="relative">
              {user.isVerified ? (
                <button
                  onClick={() => setIsProfileOpen(!isProfileOpen)}
                  className="flex items-center gap-1.5 text-xs font-bold text-gray-800 py-1 px-1.5 sm:px-2 rounded-full sm:rounded-xl border border-gray-200 hover:border-gray-300 hover:bg-gray-50 transition-all cursor-pointer shadow-2xs"
                  aria-label="User profile menu"
                >
                  <div className="w-6 h-6 sm:w-6 sm:h-6 rounded-full overflow-hidden shrink-0 bg-blue-500 border border-blue-200 flex items-center justify-center">
                    <img
                      src={user.avatar || '/profile-avatar.png'}
                      alt={user.name || 'Profile'}
                      className="w-full h-full object-cover"
                    />
                  </div>
                  {user.name && (
                    <span className="hidden md:inline max-w-[80px] truncate">{user.name.split(' ')[0]}</span>
                  )}
                  <ChevronDown className="w-3.5 h-3.5 text-gray-400" />
                </button>
              ) : (
                <button
                  onClick={() => setIsAuthOpen(true)}
                  className="flex items-center gap-1.5 text-xs font-bold text-white bg-[#0A2540] hover:bg-[#123154] px-3.5 py-2 rounded-xl transition-all cursor-pointer shadow-xs"
                >
                  <User className="w-3.5 h-3.5" />
                  <span>Login</span>
                </button>
              )}

              {/* Profile Dropdown */}
              {isProfileOpen && (
                <div className="absolute right-0 mt-2 w-60 bg-white rounded-2xl shadow-xl border border-gray-100 p-2 z-50 text-left">
                  <div className="p-3 border-b border-gray-100 bg-gray-50/80 rounded-xl mb-1 flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full overflow-hidden shrink-0 bg-blue-500 border border-blue-200 shadow-2xs">
                      <img
                        src={user.avatar || '/profile-avatar.png'}
                        alt={user.name || 'Profile'}
                        className="w-full h-full object-cover"
                      />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="font-extrabold text-xs text-gray-900 truncate">{user.name || 'Customer'}</p>
                      <p className="text-[11px] text-gray-500 truncate">{user.phone || 'Logged in'}</p>
                      {user.email && <p className="text-[10px] text-gray-400 truncate">{user.email}</p>}
                    </div>
                  </div>
                  <button
                    onClick={() => {
                      setIsProfileOpen(false);
                      router.push('/orders');
                    }}
                    className="w-full flex items-center gap-2 px-3 py-2 text-xs font-semibold text-gray-700 hover:bg-gray-100 rounded-lg transition-colors cursor-pointer"
                  >
                    <Package className="w-4 h-4 text-gray-500" />
                    <span>My Orders</span>
                  </button>
                  <button
                    onClick={() => {
                      setIsProfileOpen(false);
                      setIsLocationOpen(true);
                    }}
                    className="w-full flex items-center gap-2 px-3 py-2 text-xs font-semibold text-gray-700 hover:bg-gray-100 rounded-lg transition-colors cursor-pointer"
                  >
                    <MapPin className="w-4 h-4 text-gray-500" />
                    <span>Manage Addresses</span>
                  </button>
                  <button
                    onClick={handleSignOut}
                    className="w-full flex items-center gap-2 px-3 py-2 text-xs font-semibold text-red-600 hover:bg-red-50 rounded-lg transition-colors cursor-pointer border-t border-gray-100 mt-1"
                  >
                    <LogOut className="w-4 h-4 text-red-500" />
                    <span>Sign Out</span>
                  </button>
                </div>
              )}
            </div>

            {/* Cart Button */}
            <button
              onClick={() => setIsCartOpen(true)}
              className="flex items-center gap-2 bg-[#E11A22] hover:bg-[#c8141b] text-white px-3 sm:px-4 py-2 rounded-xl font-black text-xs sm:text-sm shadow-md hover:shadow-lg transition-all cursor-pointer relative"
              aria-label="Open Cart"
            >
              <ShoppingCart className="w-4 h-4" />
              <span className="hidden sm:inline">My Cart</span>
              <span className="bg-white text-[#E11A22] text-xs font-black w-5 h-5 rounded-full flex items-center justify-center leading-none">
                {cartCount}
              </span>
            </button>
          </div>

        </div>

        {/* Mobile Search Input */}
        <div className="mt-2.5 md:hidden">
          <form
            onSubmit={(e) => {
              e.preventDefault();
              if (searchQuery.trim()) {
                router.push(`/search?q=${encodeURIComponent(searchQuery.trim())}`);
              }
            }}
            className="relative"
          >
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search atta, dal, milk, chips, household..."
              className="w-full pl-9 pr-8 py-2 rounded-xl bg-gray-50 border border-gray-200 text-xs text-gray-800 placeholder:text-gray-400 outline-none"
            />
            <Search className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
            {searchQuery && (
              <button
                type="button"
                onClick={() => setSearchQuery('')}
                className="w-4 h-4 rounded-full bg-gray-200 text-gray-600 absolute right-2.5 top-1/2 -translate-y-1/2 flex items-center justify-center"
              >
                <X className="w-2.5 h-2.5" />
              </button>
            )}
          </form>
        </div>
      </div>

      {/* Quick Category Navigation Sub-strip (Desktop) */}
      <div className="bg-gray-50/90 border-t border-gray-100 py-1.5 px-3 sm:px-4 hidden md:block">
        <div className="max-w-[1440px] mx-auto flex items-center justify-between text-xs">
          <div className="flex items-center gap-4 lg:gap-6 font-semibold text-gray-600 overflow-x-auto [scrollbar-width:none]">
            <Link 
              href="/categories" 
              className={`flex items-center gap-1 font-black transition-colors ${
                pathname === '/categories' ? 'text-[#E11A22]' : 'text-[#0A2540] hover:text-[#E11A22]'
              }`}
            >
              <Layers className="w-3.5 h-3.5 text-[#E11A22]" />
              <span>All Categories</span>
            </Link>
            {categories.slice(0, 6).map((cat) => (
              <Link
                key={cat.id}
                href={`/categories?cat=${cat.slug}`}
                className="hover:text-[#E11A22] transition-colors whitespace-nowrap"
              >
                {cat.name}
              </Link>
            ))}
          </div>

          <div className="flex items-center gap-4 shrink-0">
            <Link 
              href="/offers" 
              className={`flex items-center gap-1 font-black transition-colors ${
                pathname === '/offers' ? 'text-[#E11A22] underline' : 'text-[#E11A22] hover:underline'
              }`}
            >
              <Flame className="w-3.5 h-3.5 text-[#E11A22] fill-[#E11A22]" />
              <span>Today's Deals</span>
            </Link>
          </div>
        </div>
      </div>

      {/* Persistent Mobile Bottom Navigation Bar */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 z-40 bg-white/95 backdrop-blur-md border-t border-gray-200 flex items-center justify-around py-2 px-2 shadow-[0_-2px_10px_rgba(0,0,0,0.06)]">
        <Link
          href="/"
          className={`flex flex-col items-center gap-0.5 text-[10px] font-bold ${
            pathname === '/' ? 'text-[#E11A22]' : 'text-gray-500 hover:text-gray-900'
          }`}
        >
          <Home className="w-4 h-4" />
          <span>Home</span>
        </Link>

        <Link
          href="/categories"
          className={`flex flex-col items-center gap-0.5 text-[10px] font-bold ${
            pathname?.startsWith('/categories') ? 'text-[#E11A22]' : 'text-gray-500 hover:text-gray-900'
          }`}
        >
          <LayoutGrid className="w-4 h-4" />
          <span>Categories</span>
        </Link>

        <Link
          href="/offers"
          className={`flex flex-col items-center gap-0.5 text-[10px] font-bold relative ${
            pathname === '/offers' ? 'text-[#E11A22]' : 'text-gray-500 hover:text-gray-900'
          }`}
        >
          <Tag className="w-4 h-4" />
          <span>Offers</span>
          <span className="absolute -top-0.5 right-1 w-1.5 h-1.5 rounded-full bg-[#E11A22]" />
        </Link>

        <Link
          href="/orders"
          className={`flex flex-col items-center gap-0.5 text-[10px] font-bold ${
            pathname?.startsWith('/orders') ? 'text-[#E11A22]' : 'text-gray-500 hover:text-gray-900'
          }`}
        >
          <Package className="w-4 h-4" />
          <span>Orders</span>
        </Link>

        <button
          onClick={() => setIsCartOpen(true)}
          className="flex flex-col items-center gap-0.5 text-[10px] font-bold text-gray-500 hover:text-gray-900 relative cursor-pointer"
        >
          <ShoppingCart className="w-4 h-4" />
          <span>Cart</span>
          {cartCount > 0 && (
            <span className="absolute -top-1 -right-1 bg-[#E11A22] text-white text-[9px] font-black w-4 h-4 rounded-full flex items-center justify-center leading-none">
              {cartCount}
            </span>
          )}
        </button>
      </nav>
    </header>
  );
};
