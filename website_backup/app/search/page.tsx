"use client";

import React, { useState, useEffect, Suspense } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Search, ChevronRight, ShoppingBag, X } from "lucide-react";
import { useApp } from "@/context/AppContext";
import { ProductCard } from "@/components/ProductCard";

function SearchPageContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const initialQuery = searchParams.get("q") || "";

  const { products, searchQuery, setSearchQuery } = useApp();
  const [localQuery, setLocalQuery] = useState(initialQuery);

  useEffect(() => {
    if (initialQuery) {
      setLocalQuery(initialQuery);
      setSearchQuery(initialQuery);
    }
  }, [initialQuery, setSearchQuery]);

  const queryToUse = localQuery.trim().toLowerCase();

  const searchResults = queryToUse
    ? products.filter(
        (p) =>
          p.name.toLowerCase().includes(queryToUse) ||
          p.brand.toLowerCase().includes(queryToUse) ||
          p.category.toLowerCase().includes(queryToUse)
      )
    : products;

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (localQuery.trim()) {
      router.push(`/search?q=${encodeURIComponent(localQuery.trim())}`);
    }
  };

  const quickPicks = ["Milk", "Atta", "Rice", "Oil", "Maggi", "Tea", "Soap", "Surf"];

  return (
    <div className="min-h-screen bg-[#F8F9FA] pb-16">
      {/* Top Breadcrumb */}
      <div className="bg-white border-b border-gray-200/80 shadow-2xs">
        <div className="max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 py-3 sm:py-3.5 flex items-center justify-between">
          <div className="flex items-center gap-2 text-xs sm:text-sm text-gray-500">
            <Link href="/" className="hover:text-[#E11A22] transition-colors">
              Home
            </Link>
            <ChevronRight className="w-3.5 h-3.5 text-gray-400" />
            <span className="font-semibold text-gray-900">Search Results</span>
          </div>

          <Link
            href="/categories"
            className="text-xs font-bold text-[#E11A22] hover:underline"
          >
            All Categories
          </Link>
        </div>
      </div>

      <div className="max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 pt-6">
        
        {/* Search Header & Input Bar */}
        <div className="bg-white rounded-2xl border border-gray-200/90 p-5 sm:p-6 shadow-2xs mb-6">
          <form onSubmit={handleSearchSubmit} className="max-w-2xl">
            <label className="block text-xs font-bold uppercase tracking-wider text-gray-400 mb-2">
              Search Grocery Catalog
            </label>
            <div className="flex items-center rounded-xl border-2 border-gray-300 focus-within:border-[#E11A22] overflow-hidden bg-white shadow-2xs">
              <div className="pl-3.5 text-gray-400">
                <Search className="w-5 h-5" />
              </div>
              <input
                type="text"
                value={localQuery}
                onChange={(e) => setLocalQuery(e.target.value)}
                placeholder="Search by product name, brand (e.g. Amul, Aashirvaad, Tata)..."
                className="w-full py-3 px-3 text-sm text-gray-800 placeholder-gray-400 bg-transparent focus:outline-none"
              />
              {localQuery && (
                <button
                  type="button"
                  onClick={() => {
                    setLocalQuery("");
                    router.push("/search");
                  }}
                  className="p-2 text-gray-400 hover:text-gray-600"
                >
                  <X className="w-4 h-4" />
                </button>
              )}
              <button
                type="submit"
                className="bg-[#E11A22] hover:bg-[#c8141b] text-white font-bold text-sm px-6 py-3 transition-colors cursor-pointer"
              >
                Search
              </button>
            </div>
          </form>

          {/* Quick Filter Tags */}
          <div className="mt-4 flex flex-wrap items-center gap-2">
            <span className="text-xs text-gray-500 font-medium">Popular:</span>
            {quickPicks.map((pick) => (
              <button
                key={pick}
                onClick={() => {
                  setLocalQuery(pick);
                  router.push(`/search?q=${encodeURIComponent(pick)}`);
                }}
                className="text-xs font-semibold bg-gray-100 hover:bg-red-50 hover:text-[#E11A22] text-gray-700 px-3 py-1 rounded-full transition-colors cursor-pointer"
              >
                {pick}
              </button>
            ))}
          </div>
        </div>

        {/* Results title */}
        <div className="flex items-center justify-between mb-4">
          <div>
            <h1 className="text-xl sm:text-2xl font-black text-[#0A2540] tracking-tight">
              {queryToUse ? `Results for "${queryToUse}"` : "All Products"}
            </h1>
            <p className="text-xs text-gray-500 mt-0.5">
              Showing {searchResults.length} {searchResults.length === 1 ? "item" : "items"} available for delivery on time
            </p>
          </div>
        </div>

        {/* Results Grid */}
        {searchResults.length > 0 ? (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-3.5 sm:gap-4">
            {searchResults.map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        ) : (
          <div className="bg-white rounded-2xl border border-gray-200/90 p-12 text-center shadow-2xs">
            <div className="w-16 h-16 bg-red-50 text-[#E11A22] rounded-full flex items-center justify-center mx-auto mb-4">
              <ShoppingBag className="w-8 h-8" />
            </div>
            <h2 className="text-lg font-bold text-gray-900">
              No products found matching "{localQuery}"
            </h2>
            <p className="text-xs text-gray-500 mt-1 max-w-sm mx-auto">
              Please check your spelling, try simpler search terms or browse our department categories.
            </p>
            <div className="mt-6 flex justify-center gap-3">
              <Link
                href="/categories"
                className="px-5 py-2.5 rounded-xl bg-[#E11A22] hover:bg-[#c8141b] text-white text-xs font-bold transition-all"
              >
                Browse All Categories
              </Link>
              <button
                onClick={() => {
                  setLocalQuery("");
                  router.push("/search");
                }}
                className="px-5 py-2.5 rounded-xl border border-gray-300 text-gray-700 hover:bg-gray-50 text-xs font-bold transition-all cursor-pointer"
              >
                Clear Search
              </button>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}

export default function SearchPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-[60vh] flex items-center justify-center">
          <div className="w-8 h-8 border-4 border-[#E11A22] border-t-transparent rounded-full animate-spin" />
        </div>
      }
    >
      <SearchPageContent />
    </Suspense>
  );
}
