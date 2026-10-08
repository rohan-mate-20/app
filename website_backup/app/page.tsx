'use client';

import React from 'react';
import Link from 'next/link';
import { useApp } from '../context/AppContext';
import { HeroCarousel } from '../components/HeroCarousel';
import { CategoryPills } from '../components/CategoryPills';
import { ProductCard } from '../components/ProductCard';
import { PromoCard } from '../components/PromoCard';
import { TrustBadges } from '../components/TrustBadges';
import { MobileAppPreview } from '../components/MobileAppPreview';
import { ChevronRight } from 'lucide-react';

export default function HomePage() {
  const { 
    products, 
    categories,
    selectedCategory, 
    setSelectedCategory, 
    searchQuery,
    viewMode,
    setViewMode,
    isLoadingProducts,
    setIsLocationOpen
  } = useApp();

  const activeCategoryObj = categories.find(c => c.slug === selectedCategory);
  const activeCategoryName = activeCategoryObj?.name || (selectedCategory === 'offers' ? 'Special Offers' : selectedCategory.replace(/-/g, ' ').toUpperCase());

  const filteredProducts = products.filter(p => {
    const matchesCat = selectedCategory === 'all' || 
      p.category?.toLowerCase() === selectedCategory.toLowerCase() || 
      (selectedCategory === 'offers' && p.discountPercent > 10);
    const matchesQuery = !searchQuery || 
      p.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
      p.brand.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCat && matchesQuery;
  });

  if (viewMode === 'mobile-preview') {
    return (
      <main className="flex-1">
        <div className="bg-slate-800 text-white py-2 px-4 text-center text-xs flex items-center justify-center gap-3">
          <span>📱 Interactive App Preview Mode (Simulating iOS / Android App Screens)</span>
          <button
            onClick={() => setViewMode('desktop')}
            className="bg-[#E11A22] text-white px-3 py-1 rounded-full font-bold hover:bg-[#c8141b] transition-colors cursor-pointer"
          >
            Switch to Desktop Web View
          </button>
        </div>
        <MobileAppPreview />
      </main>
    );
  }

  return (
    <main className="max-w-[1440px] w-full mx-auto px-3 sm:px-4 lg:px-6 pt-3 sm:pt-4 pb-8 space-y-5 sm:space-y-6">
      {/* Hero Banner Carousel */}
      <HeroCarousel />

      {/* Shop by Category Pills */}
      <CategoryPills />

      {/* Popular Products & Promo Banner Section */}
      <section id="products-section" className="pt-1">
        <div className="flex items-center justify-between mb-3 sm:mb-4">
          <div>
            <h2 className="text-xl sm:text-2xl font-black text-[#0A2540] tracking-tight">
              {selectedCategory === 'all' 
                ? 'Popular Products' 
                : activeCategoryName}
            </h2>
            <p className="text-xs text-gray-500 mt-0.5">
              {selectedCategory === 'all'
                ? 'Handpicked staples, dairy, fresh vegetables and household essentials'
                : `Showing ${filteredProducts.length} ${filteredProducts.length === 1 ? 'item' : 'items'} in ${activeCategoryName}`}
            </p>
          </div>

          <Link
            href="/categories"
            className="text-xs sm:text-sm font-bold text-[#E11A22] hover:text-[#c8141b] flex items-center gap-0.5 cursor-pointer group"
          >
            <span>View All</span>
            <ChevronRight className="w-4 h-4 transition-transform group-hover:translate-x-0.5" />
          </Link>
        </div>

        {/* Products Grid + Sticky Super Saver Promo Card */}
        <div className="grid grid-cols-1 lg:grid-cols-4 xl:grid-cols-5 gap-3.5 sm:gap-4 items-start">
          
          {/* Product Cards Grid */}
          <div className="lg:col-span-3 xl:col-span-4 grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3 sm:gap-3.5">
            {filteredProducts.map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}

            {filteredProducts.length === 0 && !isLoadingProducts && (
              <div className="col-span-full bg-white rounded-xl p-10 text-center border border-gray-200">
                <p className="text-base font-bold text-gray-700">No products found</p>
                <p className="text-xs text-gray-400 mt-1">Try selecting another category or clearing your search.</p>
                <button
                  onClick={() => setSelectedCategory('all')}
                  className="mt-4 bg-[#E11A22] text-white text-xs font-bold px-4 py-2 rounded-lg cursor-pointer"
                >
                  View All Products
                </button>
              </div>
            )}
          </div>

          {/* Sticky Super Saver Promo Card */}
          <div id="deals-section" className="lg:col-span-1 xl:col-span-1 sticky top-24 z-10">
            <PromoCard />
          </div>
        </div>
      </section>

      {/* 4 Trust Badges Banner */}
      <TrustBadges />
    </main>
  );
}
