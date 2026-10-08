"use client";

import React, { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { 
  ArrowLeft, 
  ChevronRight, 
  Sparkles, 
  Flame, 
  Layers
} from "lucide-react";
import { useApp } from "@/context/AppContext";
import { ProductCard } from "@/components/ProductCard";
import { Product } from "@/types";

function CategoriesContent() {
  const searchParams = useSearchParams();
  const urlCat = searchParams.get("cat") || searchParams.get("category") || "all";
  
  const { products, categories } = useApp();
  const [activeCategory, setActiveCategory] = useState<string>(urlCat);
  const [selectedSubcategory, setSelectedSubcategory] = useState<string | null>(null);

  useEffect(() => {
    if (urlCat) {
      setActiveCategory(urlCat);
    }
  }, [urlCat]);

  useEffect(() => {
    setSelectedSubcategory(null);
  }, [activeCategory]);

  // Helper to get products for any given category with optional subcategory and limit
  const getProductsForCategory = (
    catSlug: string,
    subCategory?: string | null,
    limit?: number
  ): Product[] => {
    let catProducts = products.filter((p) => {
      if (catSlug === "all") return true;
      if (catSlug === "offers") return p.category === "offers" || p.discountPercent >= 15;
      return p.category?.toLowerCase() === catSlug.toLowerCase();
    });

    if (subCategory) {
      const q = subCategory.toLowerCase();
      catProducts = catProducts.filter((p) =>
        p.name.toLowerCase().includes(q) ||
        p.description?.toLowerCase().includes(q) ||
        p.brand?.toLowerCase().includes(q)
      );
    }

    // Sort by reviewCount * rating + discount to get true top sellers
    const sorted = [...catProducts].sort((a, b) => {
      const scoreA = (a.rating || 4.5) * (a.reviewCount || 1000) + (a.discountPercent * 50);
      const scoreB = (b.rating || 4.5) * (b.reviewCount || 1000) + (b.discountPercent * 50);
      return scoreB - scoreA;
    });

    return limit ? sorted.slice(0, limit) : sorted;
  };

  const currentCategoryData = categories.find((c) => c.slug === activeCategory);

  return (
    <div className="min-h-screen bg-[#F8F9FA] pb-16">
      {/* Top Breadcrumb & Page Banner */}
      <div className="bg-white border-b border-gray-200/80 shadow-2xs">
        <div className="max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 py-3.5 sm:py-4">
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-center gap-3">
              <Link
                href="/"
                className="w-9 h-9 rounded-full border border-gray-200 hover:border-gray-300 bg-white flex items-center justify-center text-gray-700 hover:text-[#E11A22] transition-colors shadow-2xs group"
                title="Back to Home"
              >
                <ArrowLeft className="w-4 h-4 transition-transform group-hover:-translate-x-0.5" />
              </Link>
              <div>
                <div className="flex items-center gap-2">
                  <span className="text-xs font-bold text-gray-400">Home</span>
                  <span className="text-xs text-gray-300">/</span>
                  <span className="text-xs font-bold text-[#E11A22]">categories</span>
                </div>
                <h1 className="text-xl sm:text-2xl font-black text-[#0A2540] tracking-tight mt-0.5 flex items-center gap-2">
                  <span>Shop by Category</span>
                </h1>
              </div>
            </div>

            {/* Quick Filter Status */}
            <div className="hidden sm:flex items-center gap-2 text-xs font-semibold text-gray-500">
             
            </div>
          </div>
        </div>
      </div>

      {/* Main Content Layout with Sticky Sidebar & Middle Product Grid */}
      <div className="max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 pt-5 sm:pt-6">
        
        {/* Mobile Horizontal Category Pills (for small screens) */}
        <div className="md:hidden mb-4 overflow-x-auto pb-2 [scrollbar-width:none] flex items-center gap-2">
          <button
            onClick={() => setActiveCategory("all")}
            className={`shrink-0 px-3.5 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer ${
              activeCategory === "all"
                ? "bg-[#0A2540] text-white shadow-xs"
                : "bg-white text-gray-700 border border-gray-200 hover:border-gray-300"
            }`}
          >
            <Sparkles className="w-3.5 h-3.5 text-amber-400" />
            <span>All categories</span>
          </button>
          {categories.map((cat) => (
            <button
              key={cat.id}
              onClick={() => setActiveCategory(cat.slug)}
              className={`shrink-0 px-3.5 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 cursor-pointer ${
                activeCategory === cat.slug
                  ? "bg-[#E11A22] text-white shadow-xs"
                  : "bg-white text-gray-700 border border-gray-200 hover:border-gray-300"
              }`}
            >
              <img src={cat.icon} alt="" className="w-4 h-4 rounded-full object-cover" />
              <span>{cat.name}</span>
            </button>
          ))}
        </div>

        <div className="flex items-start gap-6 lg:gap-8">
          
          {/* LEFT SIDEBAR: Show All categories */}
          <aside className="hidden md:block w-64 lg:w-72 shrink-0 sticky top-24 self-start bg-white rounded-2xl border border-gray-200/90 shadow-2xs overflow-hidden">
            {/* Sidebar Header */}
            <div className="p-4 bg-gradient-to-r from-gray-50 to-white border-b border-gray-100 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-7 h-7 rounded-lg bg-red-50 flex items-center justify-center text-[#E11A22]">
                  <Layers className="w-4 h-4" />
                </div>
                <h3 className="font-black text-sm text-[#0A2540] uppercase tracking-wider">
                  All categories
                </h3>
              </div>
              <span className="text-[11px] font-bold text-gray-400">
                {categories.length}
              </span>
            </div>

            {/* Sidebar Items List */}
            <div className="p-2 space-y-1 max-h-[calc(100vh-160px)] overflow-y-auto [scrollbar-width:none]">
              {/* All categories Option */}
              <button
                onClick={() => setActiveCategory("all")}
                className={`w-full text-left px-3 py-2.5 rounded-xl transition-all flex items-center justify-between group cursor-pointer ${
                  activeCategory === "all"
                    ? "bg-[#0A2540] text-white shadow-xs"
                    : "text-gray-700 hover:bg-gray-50 hover:text-[#0A2540]"
                }`}
              >
                <div className="flex items-center gap-2.5 min-w-0">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 ${
                    activeCategory === "all" ? "bg-white/20 text-amber-300" : "bg-gray-100 text-gray-500"
                  }`}>
                    <Sparkles className="w-4 h-4" />
                  </div>
                  <div className="min-w-0">
                    <p className="text-xs font-bold truncate">All categories</p>
                    <p className={`text-[10px] ${activeCategory === "all" ? "text-gray-300" : "text-gray-400"}`}>
                      All top selling items
                    </p>
                  </div>
                </div>
                <ChevronRight className={`w-3.5 h-3.5 shrink-0 transition-transform ${
                  activeCategory === "all" ? "text-white" : "text-gray-400 group-hover:translate-x-0.5"
                }`} />
              </button>

              {/* Individual categories */}
              {categories.map((cat) => {
                const isActive = activeCategory === cat.slug;
                const isOffers = cat.slug === "offers";

                return (
                  <button
                    key={cat.id}
                    onClick={() => setActiveCategory(cat.slug)}
                    className={`w-full text-left px-3 py-2.5 rounded-xl transition-all flex items-center justify-between group cursor-pointer ${
                      isActive
                        ? "bg-red-50 text-[#E11A22] font-black border-l-4 border-[#E11A22] shadow-2xs"
                        : "text-gray-700 hover:bg-gray-50 hover:text-[#0A2540]"
                    }`}
                  >
                    <div className="flex items-center gap-2.5 min-w-0">
                      {/* Category Thumbnail */}
                      <div className={`w-8 h-8 rounded-full overflow-hidden shrink-0 border ${
                        isActive ? "border-[#E11A22] ring-2 ring-red-100" : "border-gray-200"
                      } flex items-center justify-center bg-gray-50`}>
                        {isOffers ? (
                          <div className="w-full h-full bg-[#E11A22] text-white flex items-center justify-center font-black text-xs">
                            %
                          </div>
                        ) : (
                          <img
                            src={cat.icon}
                            alt={cat.name}
                            className="w-full h-full object-cover"
                          />
                        )}
                      </div>

                      <div className="min-w-0">
                        <p className={`text-xs truncate ${isActive ? "font-black text-[#E11A22]" : "font-semibold"}`}>
                          {cat.name}
                        </p>
                        <p className="text-[10px] text-gray-400 truncate">
                          {cat.itemCount || "Top Picks"}
                        </p>
                      </div>
                    </div>

                    <ChevronRight className={`w-3.5 h-3.5 shrink-0 transition-transform ${
                      isActive ? "text-[#E11A22] translate-x-0.5" : "text-gray-400 group-hover:translate-x-0.5"
                    }`} />
                  </button>
                );
              })}
            </div>
          </aside>

          {/* MIDDLE: Category Name and 4 Top Selling Products */}
          <main className="flex-1 min-w-0">
            {activeCategory === "all" ? (
              // If "All categories" is selected: show each category name + 4 top selling products
              <div className="space-y-8 sm:space-y-10">
                {categories.map((cat) => {
                  const topProducts = getProductsForCategory(cat.slug, null, 4);
                  if (topProducts.length === 0) return null;

                  return (
                    <section key={cat.id} className="bg-white rounded-2xl border border-gray-200/90 p-4 sm:p-6 shadow-2xs">
                      {/* Category Header Row */}
                      <div className="flex items-center justify-between mb-4 sm:mb-5 pb-3 border-b border-gray-100">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-full overflow-hidden bg-gray-50 border border-gray-200 shrink-0 flex items-center justify-center">
                            {cat.slug === "offers" ? (
                              <div className="w-full h-full bg-[#E11A22] text-white flex items-center justify-center font-black text-sm">
                                %
                              </div>
                            ) : (
                              <img src={cat.icon} alt={cat.name} className="w-full h-full object-cover" />
                            )}
                          </div>
                          <div>
                            <div className="flex items-center gap-2">
                              <h2 className="text-lg sm:text-xl font-black text-[#0A2540]">
                                {cat.name}
                              </h2>
                             
                            </div>
                            <p className="text-xs text-gray-500 mt-0.5">
                              {cat.subcategories?.slice(0, 3).join(" • ") || "Most popular daily picks"}
                            </p>
                          </div>
                        </div>

                        <button
                          onClick={() => setActiveCategory(cat.slug)}
                          className="text-xs font-bold text-[#E11A22] hover:text-[#c8141b] flex items-center gap-1 transition-colors cursor-pointer group"
                        >
                          <span>View Category</span>
                          <ChevronRight className="w-3.5 h-3.5 transition-transform group-hover:translate-x-0.5" />
                        </button>
                      </div>

                      {/* 4 Top Selling Products Grid */}
                      <div className="grid grid-cols-2 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3 sm:gap-4">
                        {topProducts.map((product) => (
                          <ProductCard key={product.id} product={product} />
                        ))}
                      </div>
                    </section>
                  );
                })}
              </div>
            ) : (
              // Specific category selected in sidebar: show category name + 4 top selling products
              <div className="space-y-6">
                {currentCategoryData && (
                  <div className="bg-white rounded-2xl border border-gray-200/90 p-5 sm:p-6 shadow-2xs">
                    
                    {/* Category Header */}
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 mb-5 border-b border-gray-100">
                      <div className="flex items-center gap-3.5">
                        <div className="w-12 h-12 rounded-full overflow-hidden bg-gray-50 border-2 border-red-100 shrink-0 flex items-center justify-center p-0.5">
                          {currentCategoryData.slug === "offers" ? (
                            <div className="w-full h-full rounded-full bg-[#E11A22] text-white flex items-center justify-center font-black text-lg">
                              %
                            </div>
                          ) : (
                            <img
                              src={currentCategoryData.icon}
                              alt={currentCategoryData.name}
                              className="w-full h-full object-cover rounded-full"
                            />
                          )}
                        </div>
                        <div>
                          <div className="flex items-center gap-2 flex-wrap">
                            <h2 className="text-xl sm:text-2xl font-black text-[#0A2540]">
                              {currentCategoryData.name}
                            </h2>
                          </div>
                          <p className="text-xs text-gray-500 mt-1">
                            Verified daily essentials & highest rated items in this category
                          </p>
                        </div>
                      </div>

                      <button
                        onClick={() => setActiveCategory("all")}
                        className="text-xs font-bold text-gray-600 hover:text-[#0A2540] bg-gray-100 hover:bg-gray-200 px-3 py-1.5 rounded-xl transition-colors self-start sm:self-auto cursor-pointer"
                      >
                        Show All categories
                      </button>
                    </div>

                    {/* Subcategories Chips */}
                    {currentCategoryData.subcategories && currentCategoryData.subcategories.length > 0 && (
                      <div className="flex items-center gap-1.5 overflow-x-auto pb-3 mb-5 [scrollbar-width:none]">
                        <button
                          type="button"
                          onClick={() => setSelectedSubcategory(null)}
                          className={`shrink-0 text-xs font-semibold px-3 py-1 rounded-lg transition-colors cursor-pointer border ${
                            selectedSubcategory === null
                              ? "bg-[#0A2540] text-white border-[#0A2540]"
                              : "bg-gray-50 text-gray-600 border-gray-200/70 hover:bg-gray-100"
                          }`}
                        >
                          All ({getProductsForCategory(currentCategoryData.slug).length})
                        </button>
                        {currentCategoryData.subcategories.map((sub, i) => {
                          const isSubActive = selectedSubcategory === sub;
                          return (
                            <button
                              type="button"
                              key={i}
                              onClick={() => setSelectedSubcategory(isSubActive ? null : sub)}
                              className={`shrink-0 text-xs font-semibold px-2.5 py-1 rounded-lg transition-colors cursor-pointer border ${
                                isSubActive
                                  ? "bg-[#E11A22] text-white border-[#E11A22]"
                                  : "bg-gray-50 text-gray-600 hover:bg-red-50 hover:text-[#E11A22] border-gray-200/70"
                              }`}
                            >
                              {sub}
                            </button>
                          );
                        })}
                      </div>
                    )}

                    {/* Products Grid for Current Category */}
                    {(() => {
                      const categoryProducts = getProductsForCategory(currentCategoryData.slug, selectedSubcategory);
                      if (categoryProducts.length === 0) {
                        return (
                          <div className="p-8 text-center bg-gray-50 rounded-xl border border-gray-200">
                            <p className="text-sm font-bold text-gray-700">No products found in this selection</p>
                            <button
                              onClick={() => setSelectedSubcategory(null)}
                              className="mt-3 text-xs font-bold text-[#E11A22] hover:underline cursor-pointer"
                            >
                              Clear subcategory filter
                            </button>
                          </div>
                        );
                      }
                      return (
                        <div className="grid grid-cols-2 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3 sm:gap-4">
                          {categoryProducts.map((product) => (
                            <ProductCard key={product.id} product={product} />
                          ))}
                        </div>
                      );
                    })()}
                  </div>
                )}
              </div>
            )}
          </main>

        </div>
      </div>
    </div>
  );
}

export default function CategoriesPage() {
  return (
    <Suspense fallback={
      <div className="flex h-96 items-center justify-center">
        <div className="h-10 w-10 animate-spin rounded-full border-4 border-[#E11A22] border-t-transparent" />
      </div>
    }>
      <CategoriesContent />
    </Suspense>
  );
}
