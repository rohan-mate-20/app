'use client';

import React from 'react';
import { 
  Home, 
  Grid, 
  ShoppingCart, 
  User, 
  Search, 
  Bell, 
  MapPin, 
  ChevronDown
} from 'lucide-react';
import { Logo } from './Logo';
import { useApp } from '../context/AppContext';
import { ProductCard } from './ProductCard';
import { CategoryPills } from './CategoryPills';

export const MobileAppPreview: React.FC = () => {
  const { 
    products, 
    cartCount, 
    setIsCartOpen, 
    setIsLocationOpen, 
    setIsAuthOpen, 
    selectedAddress,
    searchQuery,
    setSearchQuery,
    selectedCategory,
    setSelectedCategory
  } = useApp();

  const filteredProducts = products.filter(p => {
    const matchesCat = selectedCategory === 'all' || p.category === selectedCategory || (selectedCategory === 'offers' && p.discountPercent > 10);
    const matchesQuery = !searchQuery || p.name.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCat && matchesQuery;
  });

  return (
    <div className="py-8 flex items-center justify-center bg-slate-900/90 min-h-[85vh]">
      {/* Mobile Frame Container */}
      <div className="w-[375px] h-[780px] bg-[#F8F9FA] rounded-[48px] shadow-[0_0_50px_rgba(0,0,0,0.8)] border-[10px] border-slate-800 flex flex-col relative overflow-hidden select-none">
        
        {/* Dynamic Island / Speaker cutout */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-36 h-5 bg-slate-800 rounded-b-2xl z-50 flex items-center justify-center">
          <div className="w-12 h-3.5 bg-black rounded-full" />
        </div>

        {/* Mobile Header */}
        <div className="pt-8 px-4 pb-3 bg-white border-b border-gray-100 shrink-0">
          <div className="flex items-center justify-between mb-2">
            <Logo size="sm" />
            
            <div className="flex items-center gap-2">
              <button 
                onClick={() => setIsAuthOpen(true)}
                className="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center text-gray-700 cursor-pointer"
              >
                <User className="w-4 h-4" />
              </button>
              <button 
                onClick={() => setIsCartOpen(true)}
                className="w-8 h-8 rounded-full bg-red-50 text-[#E11A22] flex items-center justify-center relative cursor-pointer"
              >
                <ShoppingCart className="w-4 h-4" />
                {cartCount > 0 && (
                  <span className="absolute -top-1 -right-1 bg-[#E11A22] text-white text-[9px] font-black w-4 h-4 rounded-full flex items-center justify-center">
                    {cartCount}
                  </span>
                )}
              </button>
            </div>
          </div>

          {/* Delivery Location bar */}
          <div 
            onClick={() => setIsLocationOpen(true)}
            className="flex items-center justify-between py-1 px-2 rounded-lg bg-gray-50 border border-gray-200/60 cursor-pointer text-xs"
          >
            <div className="flex items-center gap-1.5 truncate">
              <MapPin className="w-3.5 h-3.5 text-[#E11A22] shrink-0" />
              <span className="font-bold text-gray-800 truncate">
                {selectedAddress?.line1 || selectedAddress?.city || 'Select Location'}
              </span>
            </div>
            <div className="flex items-center gap-1 text-[10px] text-gray-500 font-bold shrink-0">
              <span className="text-emerald-700 bg-emerald-50 px-1 rounded">On Time</span>
              <ChevronDown className="w-3 h-3" />
            </div>
          </div>

          {/* Mobile Search input */}
          <div className="mt-2 relative">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search staples, milk, snacks..."
              className="w-full pl-8 pr-3 py-1.5 rounded-xl bg-gray-100 border-none text-xs outline-none"
            />
            <Search className="w-3.5 h-3.5 text-gray-400 absolute left-2.5 top-1/2 -translate-y-1/2" />
          </div>
        </div>

        {/* Scrollable Screen Content */}
        <div className="flex-1 overflow-y-auto p-3 space-y-4">
          
          {/* Mini Banner */}
          <div className="p-3 rounded-2xl bg-gradient-to-r from-red-600 to-[#0A2540] text-white text-left shadow-sm">
            <span className="text-[9px] font-black bg-white/20 px-2 py-0.5 rounded-full uppercase">
              App Only Deal
            </span>
            <h3 className="font-black text-sm mt-1">Get Flat ₹45 OFF</h3>
            <p className="text-[10px] text-white/80">Code: KMART45 on orders over ₹250</p>
          </div>

          {/* Category Chips */}
          <CategoryPills />

          {/* Products grid */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-black text-gray-800 uppercase">
                {selectedCategory === 'all' ? 'Popular Essentials' : selectedCategory}
              </span>
              <span className="text-[10px] text-gray-400 font-bold">
                {filteredProducts.length} items
              </span>
            </div>

            <div className="grid grid-cols-2 gap-2">
              {filteredProducts.map((p) => (
                <ProductCard key={p.id} product={p} />
              ))}
            </div>
          </div>

        </div>

        {/* Bottom Tab Bar */}
        <div className="h-14 bg-white border-t border-gray-200 flex items-center justify-around px-2 shrink-0">
          <button 
            onClick={() => setSelectedCategory('all')}
            className="flex flex-col items-center text-[#E11A22] text-[10px] font-bold cursor-pointer"
          >
            <Home className="w-4 h-4" />
            <span>Home</span>
          </button>
          
          <button 
            onClick={() => {
              const el = document.getElementById('products-section');
              if (el) el.scrollIntoView({ behavior: 'smooth' });
            }}
            className="flex flex-col items-center text-gray-400 hover:text-gray-700 text-[10px] font-bold cursor-pointer"
          >
            <Grid className="w-4 h-4" />
            <span>Categories</span>
          </button>

          <button 
            onClick={() => setIsCartOpen(true)}
            className="flex flex-col items-center text-gray-400 hover:text-gray-700 text-[10px] font-bold relative cursor-pointer"
          >
            <ShoppingCart className="w-4 h-4" />
            <span>Cart</span>
            {cartCount > 0 && (
              <span className="absolute -top-1 right-2 bg-[#E11A22] text-white text-[8px] font-black w-3.5 h-3.5 rounded-full flex items-center justify-center">
                {cartCount}
              </span>
            )}
          </button>

          <button 
            onClick={() => setIsAuthOpen(true)}
            className="flex flex-col items-center text-gray-400 hover:text-gray-700 text-[10px] font-bold cursor-pointer"
          >
            <User className="w-4 h-4" />
            <span>Account</span>
          </button>
        </div>

        {/* Home indicator bar */}
        <div className="absolute bottom-1 left-1/2 -translate-x-1/2 w-28 h-1 bg-slate-900 rounded-full" />

      </div>
    </div>
  );
};
