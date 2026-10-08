'use client';

import React, { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { ChevronLeft, ChevronRight, ArrowRight } from 'lucide-react';
import { useApp } from '../context/AppContext';

export const HeroCarousel: React.FC = () => {
  const [currentSlide, setCurrentSlide] = useState(0);
  const [isPaused, setIsPaused] = useState(false);
  const { setSelectedCategory } = useApp();

  const slides = [
    {
      id: 1,
      badge: 'Best Quality Everyday',
      title: 'Daily Essentials',
      titleAccent: 'Delivered To Your Door.',
      subtitle: 'Branded pantry staples, packaged groceries, snacks, and home essentials.',
      btnText: 'Shop Essentials',
      ctaCategory: 'groceries',
      bgGradient: 'from-[#FDF4EB] via-[#FFF9F3] to-[#F5ECE1]',
      bagStamp: 'Fresh Daily!',
      quote: 'Top Brands. Best Prices.',
      image: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80'
    },
    {
      id: 2,
      badge: 'Special Weekly Savings',
      title: 'Snacks & Beverages',
      titleAccent: 'Up to 30% Off.',
      subtitle: 'Biscuits, noodles, breakfast cereals, tea, coffee & delicious packaged treats.',
      btnText: 'Explore Snacks',
      ctaCategory: 'snacks-and-beverages',
      bgGradient: 'from-[#EBF7EE] via-[#F4FCF6] to-[#E5F3E9]',
      bagStamp: 'Grab Munchies!',
      quote: '100% Genuine Branded Packs',
      image: 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&w=800&q=80'
    },
    {
      id: 3,
      badge: 'Home Care Festival',
      title: 'Household Essentials',
      titleAccent: 'Up to 50% Off.',
      subtitle: 'Top brand detergents, dishwashers, bath care, and oral hygiene.',
      btnText: 'Grab Deals',
      ctaCategory: 'household',
      bgGradient: 'from-[#EFF6FF] via-[#F5F9FF] to-[#E0EDFF]',
      bagStamp: 'Save More Everyday!',
      quote: 'Lowest Prices Guaranteed',
      image: 'https://images.unsplash.com/photo-1583947215259-38e31be8751f?auto=format&fit=crop&w=800&q=80'
    }
  ];

  const nextSlide = useCallback(() => {
    setCurrentSlide((prev) => (prev + 1) % slides.length);
  }, [slides.length]);

  const prevSlide = useCallback(() => {
    setCurrentSlide((prev) => (prev - 1 + slides.length) % slides.length);
  }, [slides.length]);

  // Auto advance slides every 5 seconds (paused on hover)
  useEffect(() => {
    if (isPaused) return;
    const timer = setInterval(() => {
      nextSlide();
    }, 5000);
    return () => clearInterval(timer);
  }, [isPaused, nextSlide]);

  return (
    <div 
      className="relative rounded-2xl sm:rounded-3xl overflow-hidden shadow-sm border border-gray-100 h-[280px] sm:h-[330px] md:h-[350px] w-full"
      onMouseEnter={() => setIsPaused(true)}
      onMouseLeave={() => setIsPaused(false)}
    >
      {/* Sliding Track (100% fixed height, smooth horizontal translation prevents vertical layout shift) */}
      <div 
        className="flex h-full w-full transition-transform duration-700 ease-out"
        style={{ transform: `translateX(-${currentSlide * 100}%)` }}
      >
        {slides.map((slide) => (
          <div
            key={slide.id}
            className={`w-full h-full shrink-0 bg-gradient-to-r ${slide.bgGradient} p-5 sm:p-8 lg:p-10 flex items-center justify-between gap-6`}
          >
            {/* Left Text content */}
            <div className="flex-1 max-w-xl text-left space-y-2.5 sm:space-y-3 z-10">
              <div className="inline-flex items-center gap-2 bg-white/80 backdrop-blur-sm border border-gray-200/60 px-3 py-1 rounded-full text-[11px] sm:text-xs font-black text-[#E11A22] shadow-2xs">
                <span className="w-2 h-2 rounded-full bg-[#E11A22] animate-pulse" />
                <span>{slide.badge}</span>
              </div>

              <h1 className="text-2xl sm:text-3xl lg:text-4xl font-black text-[#0A2540] tracking-tight leading-[1.15]">
                {slide.title} <br className="hidden sm:inline" />
                <span className="text-[#E11A22]">{slide.titleAccent}</span>
              </h1>

              <p className="text-xs sm:text-sm text-gray-600 font-medium max-w-md line-clamp-2">
                {slide.subtitle}
              </p>

              <div className="pt-1.5 flex items-center gap-3">
                <button
                  type="button"
                  onClick={() => {
                    setSelectedCategory(slide.ctaCategory);
                    const elem = document.getElementById('products-section');
                    if (elem) {
                      elem.scrollIntoView({ behavior: 'smooth', block: 'start' });
                    }
                  }}
                  className="bg-[#0A2540] hover:bg-[#E11A22] text-white px-5 sm:px-6 py-2 sm:py-2.5 rounded-xl font-black text-xs sm:text-sm flex items-center gap-2 shadow-md hover:shadow-lg transition-all cursor-pointer group"
                >
                  <span>{slide.btnText}</span>
                  <ArrowRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
                </button>
              </div>
            </div>

            {/* Right Image Container */}
            <div className="hidden md:flex relative shrink-0 w-60 lg:w-80 h-56 lg:h-64 items-center justify-center">
              <div className="absolute inset-0 bg-white/40 rounded-full blur-2xl transform scale-90" />
              <img
                src={slide.image}
                alt={slide.title}
                className="relative z-10 w-full h-full object-cover rounded-2xl shadow-xl"
              />
            </div>
          </div>
        ))}
      </div>

      {/* Slide Navigation Arrows */}
      <button
        type="button"
        onClick={prevSlide}
        className="absolute left-2.5 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-white/80 hover:bg-white text-gray-700 shadow-md flex items-center justify-center transition-all cursor-pointer opacity-70 hover:opacity-100 z-30"
        aria-label="Previous Slide"
      >
        <ChevronLeft className="w-4 h-4" />
      </button>

      <button
        type="button"
        onClick={nextSlide}
        className="absolute right-2.5 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-white/80 hover:bg-white text-gray-700 shadow-md flex items-center justify-center transition-all cursor-pointer opacity-70 hover:opacity-100 z-30"
        aria-label="Next Slide"
      >
        <ChevronRight className="w-4 h-4" />
      </button>

      {/* Bottom slide indicator dots */}
      <div className="absolute bottom-2.5 left-1/2 -translate-x-1/2 flex items-center gap-1.5 z-30">
        {slides.map((_, i) => (
          <button
            key={i}
            type="button"
            onClick={() => setCurrentSlide(i)}
            className={`h-1.5 rounded-full transition-all cursor-pointer ${
              i === currentSlide ? 'w-6 bg-[#E11A22]' : 'w-1.5 bg-gray-300'
            }`}
            aria-label={`Go to slide ${i + 1}`}
          />
        ))}
      </div>
    </div>
  );
};
