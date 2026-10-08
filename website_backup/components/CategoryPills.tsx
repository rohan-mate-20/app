'use client';

import React, { useRef, useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { ChevronRight, ChevronLeft, LayoutGrid } from 'lucide-react';
import { useApp } from '../context/AppContext';

export const CategoryPills: React.FC = () => {
  const { selectedCategory, setSelectedCategory, categories } = useApp();
  const scrollRef = useRef<HTMLDivElement>(null);
  const [canScrollLeft, setCanScrollLeft] = useState(false);
  const [canScrollRight, setCanScrollRight] = useState(false);

  const checkScroll = useCallback(() => {
    if (scrollRef.current) {
      const { scrollLeft, scrollWidth, clientWidth } = scrollRef.current;
      setCanScrollLeft(scrollLeft > 5);
      setCanScrollRight(scrollLeft + clientWidth < scrollWidth - 5);
    }
  }, []);

  useEffect(() => {
    checkScroll();
    window.addEventListener('resize', checkScroll);
    return () => window.removeEventListener('resize', checkScroll);
  }, [checkScroll, categories]);

  const scroll = (direction: 'left' | 'right') => {
    if (scrollRef.current) {
      const scrollAmount = direction === 'left' ? -280 : 280;
      scrollRef.current.scrollBy({ left: scrollAmount, behavior: 'smooth' });
      setTimeout(checkScroll, 350);
    }
  };

  const handleCategoryClick = (slug: string) => {
    if (selectedCategory === slug) {
      setSelectedCategory('all');
    } else {
      setSelectedCategory(slug);
    }

    // Scroll smoothly to products section without getting hidden under the sticky navbar
    const elem = document.getElementById('products-section');
    if (elem) {
      const navOffset = -100;
      const y = elem.getBoundingClientRect().top + window.pageYOffset + navOffset;
      window.scrollTo({ top: y, behavior: 'smooth' });
    }
  };

  return (
    <section className="bg-white rounded-2xl border border-gray-200/80 p-3 sm:p-4 md:p-5 shadow-2xs mt-2 sm:mt-3 relative w-full overflow-hidden">
      {/* Section Header */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <h2 className="text-base sm:text-lg font-black text-[#0A2540] tracking-tight">
            Shop by Category
          </h2>
          {selectedCategory !== 'all' && (
            <button
              onClick={() => setSelectedCategory('all')}
              className="text-[11px] font-bold text-[#E11A22] bg-red-50 hover:bg-red-100 px-2.5 py-0.5 rounded-full transition-colors cursor-pointer flex items-center gap-1"
            >
              <span>Clear Filter</span>
              <span>✕</span>
            </button>
          )}
        </div>

        <div className="flex items-center gap-2">
          {/* Scroll Navigation Arrows */}
          <div className="hidden sm:flex items-center gap-1">
            <button
              type="button"
              onClick={() => scroll('left')}
              disabled={!canScrollLeft}
              className="w-7 h-7 rounded-full border border-gray-200 bg-white flex items-center justify-center text-gray-600 hover:text-[#0A2540] hover:border-gray-400 disabled:opacity-30 disabled:pointer-events-none transition-all cursor-pointer shadow-2xs"
              aria-label="Scroll left"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <button
              type="button"
              onClick={() => scroll('right')}
              disabled={!canScrollRight}
              className="w-7 h-7 rounded-full border border-gray-200 bg-white flex items-center justify-center text-gray-600 hover:text-[#0A2540] hover:border-gray-400 disabled:opacity-30 disabled:pointer-events-none transition-all cursor-pointer shadow-2xs"
              aria-label="Scroll right"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>

          <Link
            href="/categories"
            className="text-xs sm:text-sm font-bold text-[#E11A22] hover:text-[#c8141b] flex items-center gap-0.5 cursor-pointer group ml-1"
          >
            <span>See All</span>
            <ChevronRight className="w-3.5 h-3.5 transition-transform group-hover:translate-x-0.5" />
          </Link>
        </div>
      </div>

      {/* Horizontal Scroll Track with touch, trackpad, and button support */}
      <div className="relative w-full">
        <div
          ref={scrollRef}
          onScroll={checkScroll}
          className="flex items-start gap-4 sm:gap-6 md:gap-8 overflow-x-auto scroll-smooth py-1 px-1 [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden w-full select-none"
        >
          {/* "All" Category Pill */}
          <button
            type="button"
            onClick={() => setSelectedCategory('all')}
            className="flex flex-col items-center gap-1.5 sm:gap-2 shrink-0 group cursor-pointer focus:outline-none w-18 sm:w-22"
          >
            <div
              className={`relative w-16 h-16 sm:w-18 sm:h-18 md:w-20 md:h-20 rounded-full flex items-center justify-center p-1 transition-all duration-200 transform group-hover:scale-105 ${
                selectedCategory === 'all'
                  ? 'ring-2 sm:ring-3 ring-[#E11A22] ring-offset-2 bg-red-50 shadow-md'
                  : 'bg-white border border-gray-200 shadow-2xs hover:border-red-200 hover:shadow-xs'
              }`}
            >
              <div className="w-full h-full rounded-full bg-gradient-to-br from-[#0A2540] to-[#1e3a5f] text-white flex flex-col items-center justify-center shadow-inner group-hover:from-[#E11A22] group-hover:to-[#c8141b] transition-colors">
                <LayoutGrid className="w-5 h-5 sm:w-6 sm:h-6 text-white mb-0.5" />
                <span className="text-[9px] sm:text-[10px] font-black uppercase tracking-wider">ALL</span>
              </div>

              {selectedCategory === 'all' && (
                <span className="absolute top-0 right-0 bg-[#E11A22] text-white text-[9px] font-black w-4 h-4 rounded-full flex items-center justify-center shadow-xs border border-white">
                  ✓
                </span>
              )}
            </div>
            <span
              className={`text-[11px] sm:text-xs font-bold text-center leading-tight line-clamp-2 w-full transition-colors ${
                selectedCategory === 'all'
                  ? 'text-[#E11A22] font-black'
                  : 'text-gray-700 group-hover:text-[#0A2540]'
              }`}
            >
              All Items
            </span>
          </button>

          {/* Dynamic DB Categories */}
          {categories.map((cat) => {
            const isSelected = selectedCategory === cat.slug;
            const isOffers = cat.slug === 'offers';

            return (
              <button
                key={cat.id}
                type="button"
                onClick={() => handleCategoryClick(cat.slug)}
                className="flex flex-col items-center gap-1.5 sm:gap-2 shrink-0 group cursor-pointer focus:outline-none w-18 sm:w-22"
              >
                {/* Circle Container */}
                <div 
                  className={`relative w-16 h-16 sm:w-18 sm:h-18 md:w-20 md:h-20 rounded-full flex items-center justify-center p-1 transition-all duration-200 transform group-hover:scale-105 ${
                    isSelected
                      ? 'ring-2 sm:ring-3 ring-[#E11A22] ring-offset-2 bg-red-50 shadow-md'
                      : isOffers
                      ? 'bg-gradient-to-br from-red-50 to-red-100 border border-red-200 shadow-2xs hover:border-[#E11A22] hover:shadow-xs'
                      : 'bg-white border border-gray-200 shadow-2xs hover:border-red-200 hover:shadow-xs'
                  }`}
                >
                  {/* Circular image or icon */}
                  {isOffers ? (
                    <div className="w-full h-full rounded-full bg-[#E11A22] text-white flex items-center justify-center text-xl sm:text-2xl font-black shadow-inner">
                      %
                    </div>
                  ) : (
                    <div className="w-full h-full rounded-full overflow-hidden bg-gray-50 flex items-center justify-center">
                      <img
                        src={cat.icon}
                        alt={cat.name}
                        className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                        loading="lazy"
                      />
                    </div>
                  )}

                  {/* Active check badge */}
                  {isSelected && (
                    <span className="absolute top-0 right-0 bg-[#E11A22] text-white text-[9px] font-black w-4 h-4 rounded-full flex items-center justify-center shadow-xs border border-white">
                      ✓
                    </span>
                  )}

                  {/* Micro badge for offers */}
                  {isOffers && !isSelected && (
                    <span className="absolute top-0 right-0 bg-amber-400 text-slate-900 text-[8px] sm:text-[9px] font-black px-1.5 py-0.2 rounded-full shadow-xs">
                      SAVE
                    </span>
                  )}
                </div>

                {/* Category Label */}
                <span 
                  className={`text-[11px] sm:text-xs font-bold text-center leading-tight line-clamp-2 w-full transition-colors ${
                    isSelected
                      ? 'text-[#E11A22] font-black'
                      : 'text-gray-700 group-hover:text-[#0A2540]'
                  }`}
                >
                  {cat.name}
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </section>
  );
};
