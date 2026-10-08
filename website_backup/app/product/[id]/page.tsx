"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { 
  ArrowLeft, 
  Star, 
  ShieldCheck, 
  Truck, 
  Heart, 
  Plus, 
  Minus, 
  Check, 
  ShoppingBag,
  RotateCcw,
  Sparkles,
  ChevronRight,
  Share2
} from "lucide-react";
import { useApp } from "@/context/AppContext";
import { PRODUCTS } from "@/data/mockData";
import { ProductCard } from "@/components/ProductCard";

export default function ProductDetailPage({
  params,
}: {
  params: { id: string } | Promise<{ id: string }>;
}) {
  const router = useRouter();
  const [resolvedId, setResolvedId] = useState<string>(() => {
    if (params && typeof params === "object" && "id" in params && typeof (params as any).id === "string") {
      return (params as any).id;
    }
    return "";
  });

  useEffect(() => {
    if (!resolvedId) {
      Promise.resolve(params).then((p) => {
        if (p?.id) setResolvedId(p.id);
      });
    }
  }, [params, resolvedId]);

  const { 
    products, 
    cart, 
    addToCart, 
    updateQuantity, 
    wishlist, 
    toggleWishlist,
    setIsCartOpen
  } = useApp();

  const [localQty, setLocalQty] = useState(1);
  const [copied, setCopied] = useState(false);

  // Find product from context or mock data fallback
  const product = 
    products.find((p) => p.id === resolvedId) ||
    PRODUCTS.find((p) => p.id === resolvedId);

  if (!product) {
    return (
      <div className="min-h-[70vh] flex flex-col items-center justify-center px-4 py-16 text-center">
        <div className="w-20 h-20 bg-red-50 text-[#E11A22] rounded-full flex items-center justify-center mb-4">
          <ShoppingBag className="w-10 h-10" />
        </div>
        <h2 className="text-2xl font-black text-[#0A2540]">Product Not Found</h2>
        <p className="mt-2 text-sm text-gray-500 max-w-md">
          The product you are looking for might have been moved, updated or is temporarily out of stock.
        </p>
        <div className="mt-6 flex items-center gap-3">
          <Link
            href="/"
            className="rounded-xl bg-[#0A2540] hover:bg-[#123154] px-6 py-2.5 text-sm font-bold text-white shadow-sm transition-all"
          >
            Back to Home
          </Link>
          <Link
            href="/categories"
            className="rounded-xl bg-[#E11A22] hover:bg-[#c8141b] px-6 py-2.5 text-sm font-bold text-white shadow-sm transition-all"
          >
            Browse Categories
          </Link>
        </div>
      </div>
    );
  }

  const cartItem = cart.find((item) => item.product.id === product.id);
  const inCartQuantity = cartItem ? cartItem.quantity : 0;
  const isWishlisted = wishlist.includes(product.id);

  // Related products from the same category
  const relatedProducts = products
    .filter((p) => p.category === product.category && p.id !== product.id)
    .slice(0, 4);

  const handleShare = () => {
    if (typeof window !== "undefined") {
      navigator.clipboard.writeText(window.location.href);
      setCopied(true);
      setTimeout(() => setCopied(false), 2500);
    }
  };

  const handleBuyNow = () => {
    if (inCartQuantity === 0) {
      addToCart(product, localQty);
    }
    router.push("/checkout");
  };

  return (
    <div className="min-h-screen bg-[#F8F9FA] pb-16">
      {/* Breadcrumbs Navigation */}
      <div className="bg-white border-b border-gray-200/80 shadow-2xs">
        <div className="max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 py-3 sm:py-3.5">
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-center gap-2 text-xs sm:text-sm text-gray-500 overflow-hidden">
              <Link href="/" className="hover:text-[#E11A22] transition-colors shrink-0">
                Home
              </Link>
              <ChevronRight className="w-3.5 h-3.5 shrink-0 text-gray-400" />
              <Link 
                href={`/categories?cat=${product.category}`} 
                className="hover:text-[#E11A22] transition-colors shrink-0 capitalize"
              >
                {product.category.replace("-", " ")}
              </Link>
              <ChevronRight className="w-3.5 h-3.5 shrink-0 text-gray-400" />
              <span className="font-semibold text-gray-900 truncate">
                {product.name}
              </span>
            </div>

            <button
              onClick={() => router.back()}
              className="flex items-center gap-1 text-xs font-bold text-gray-600 hover:text-[#E11A22] transition-colors shrink-0"
            >
              <ArrowLeft className="w-3.5 h-3.5" />
              <span>Back</span>
            </button>
          </div>
        </div>
      </div>

      {/* Main Product Container */}
      <div className="max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 pt-6">
        <div className="bg-white rounded-2xl border border-gray-200/90 shadow-xs p-5 sm:p-8 lg:p-10">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-12">
            
            {/* Left Column: Product Image & Badges (5 cols) */}
            <div className="lg:col-span-5 flex flex-col">
              <div className="relative aspect-square w-full rounded-2xl border border-gray-100 bg-gray-50/50 flex items-center justify-center p-6 overflow-hidden group">
                {/* Discount Badge */}
                {product.discountPercent > 0 && (
                  <span className="absolute top-4 left-4 rounded-lg bg-[#E11A22] text-white text-xs font-extrabold px-3 py-1 shadow-sm uppercase tracking-wider">
                    {product.discountPercent}% OFF
                  </span>
                )}

                {/* Wishlist & Share buttons */}
                <div className="absolute top-4 right-4 flex items-center gap-2">
                  <button
                    onClick={handleShare}
                    className="w-9 h-9 rounded-full bg-white border border-gray-200 shadow-2xs flex items-center justify-center text-gray-500 hover:text-[#0A2540] hover:border-gray-300 transition-colors cursor-pointer"
                    title="Copy Link"
                  >
                    {copied ? <Check className="w-4 h-4 text-emerald-600" /> : <Share2 className="w-4 h-4" />}
                  </button>

                  <button
                    onClick={() => toggleWishlist(product.id)}
                    className="w-9 h-9 rounded-full bg-white border border-gray-200 shadow-2xs flex items-center justify-center text-gray-400 hover:text-[#E11A22] hover:border-red-200 transition-colors cursor-pointer"
                    aria-label="Wishlist"
                  >
                    <Heart 
                      className={`w-4 h-4 transition-colors ${
                        isWishlisted ? "fill-[#E11A22] text-[#E11A22]" : "text-gray-400"
                      }`} 
                    />
                  </button>
                </div>

                {/* Main Product Image */}
                <img
                  src={product.image}
                  alt={product.name}
                  className="max-h-full max-w-full object-contain group-hover:scale-105 transition-transform duration-300"
                />

                {/* Delivery Badge */}
                <div className="absolute bottom-4 left-4 bg-[#0A2540]/90 backdrop-blur-xs text-white text-xs font-bold px-3 py-1 rounded-full flex items-center gap-1.5 shadow-sm">
                  <Truck className="w-3.5 h-3.5 text-amber-300" />
                  <span>Delivery on time</span>
                </div>
              </div>

              {/* Quality Guarantee Callout */}
              <div className="mt-4 p-3 bg-emerald-50/80 border border-emerald-100 rounded-xl flex items-center gap-3">
                <ShieldCheck className="w-5 h-5 text-emerald-600 shrink-0" />
                <div className="text-xs">
                  <p className="font-bold text-emerald-900">100% Genuine Branded Product</p>
                  <p className="text-emerald-700 text-[11px]">Sourced directly from verified authorized brand distributors</p>
                </div>
              </div>
            </div>

            {/* Right Column: Details & Actions (7 cols) */}
            <div className="lg:col-span-7 flex flex-col justify-between">
              <div>
                {/* Brand & Stock Status */}
                <div className="flex items-center justify-between gap-2 mb-2">
                  <span className="text-xs font-black uppercase tracking-wider text-[#E11A22] bg-red-50 border border-red-100 px-2.5 py-0.5 rounded-md">
                    {product.brand}
                  </span>
                  <span className="text-xs font-bold text-emerald-700 bg-emerald-50 px-2.5 py-0.5 rounded-full flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                    In Stock
                  </span>
                </div>

                {/* Product Title */}
                <h1 className="text-2xl sm:text-3xl font-black text-[#0A2540] leading-tight tracking-tight">
                  {product.name}
                </h1>

                {/* Pack size & Rating */}
                <div className="mt-3 flex flex-wrap items-center gap-4 text-xs">
                  <span className="text-gray-600 font-semibold bg-gray-100 px-2.5 py-1 rounded-md">
                    Net Weight: {product.weight}
                  </span>

                  <div className="flex items-center gap-1 bg-amber-50 border border-amber-200/80 px-2.5 py-0.5 rounded-md text-amber-900 font-bold">
                    <span>{product.rating || 4.7}</span>
                    <Star className="w-3.5 h-3.5 fill-amber-400 text-amber-400" />
                    <span className="text-gray-400 font-normal">({product.reviewCount || 120}+ reviews)</span>
                  </div>
                </div>

                {/* Pricing Block */}
                <div className="mt-6 p-4 sm:p-5 bg-gray-50/80 rounded-2xl border border-gray-200/80 flex items-baseline gap-3">
                  <div className="flex items-baseline gap-2">
                    <span className="text-3xl sm:text-4xl font-black text-[#0A2540]">
                      ₹{product.price}
                    </span>
                    {product.originalPrice > product.price && (
                      <span className="text-base text-gray-400 line-through">
                        ₹{product.originalPrice}
                      </span>
                    )}
                  </div>
                  {product.discountPercent > 0 && (
                    <span className="text-xs font-extrabold text-[#E11A22] bg-red-100/70 border border-red-200 px-2.5 py-1 rounded-lg">
                      Save ₹{product.originalPrice - product.price} ({product.discountPercent}% OFF)
                    </span>
                  )}
                  <span className="text-[11px] text-gray-500 block sm:inline">Inclusive of all taxes</span>
                </div>

                {/* Quantity & CTA Buttons */}
                <div className="mt-6 space-y-3">
                  <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
                    {inCartQuantity === 0 ? (
                      <div className="flex items-center gap-3">
                        {/* Stepper for first addition */}
                        <div className="flex items-center border border-gray-300 rounded-xl bg-white shadow-2xs overflow-hidden h-12">
                          <button
                            onClick={() => setLocalQty((q) => Math.max(1, q - 1))}
                            className="w-10 h-full flex items-center justify-center hover:bg-gray-100 text-gray-600 transition-colors cursor-pointer"
                          >
                            <Minus className="w-4 h-4" />
                          </button>
                          <span className="w-10 text-center font-bold text-sm text-gray-800">
                            {localQty}
                          </span>
                          <button
                            onClick={() => setLocalQty((q) => q + 1)}
                            className="w-10 h-full flex items-center justify-center hover:bg-gray-100 text-gray-600 transition-colors cursor-pointer"
                          >
                            <Plus className="w-4 h-4" />
                          </button>
                        </div>

                        {/* Add to Cart Button */}
                        <button
                          onClick={() => {
                            addToCart(product, localQty);
                            setIsCartOpen(true);
                          }}
                          className="flex-1 h-12 bg-[#E11A22] hover:bg-[#c8141b] text-white font-bold text-sm px-6 rounded-xl flex items-center justify-center gap-2 shadow-sm hover:shadow-md transition-all cursor-pointer"
                        >
                          <ShoppingBag className="w-4 h-4" />
                          <span>Add to Cart</span>
                        </button>
                      </div>
                    ) : (
                      <div className="flex items-center gap-3">
                        {/* Already in cart controller */}
                        <div className="flex items-center border-2 border-[#E11A22] rounded-xl bg-red-50 text-[#E11A22] overflow-hidden h-12">
                          <button
                            onClick={() => updateQuantity(product.id, inCartQuantity - 1)}
                            className="w-11 h-full flex items-center justify-center hover:bg-red-100 transition-colors cursor-pointer"
                          >
                            <Minus className="w-4 h-4" />
                          </button>
                          <span className="w-12 text-center font-black text-sm">
                            {inCartQuantity} in Cart
                          </span>
                          <button
                            onClick={() => updateQuantity(product.id, inCartQuantity + 1)}
                            className="w-11 h-full flex items-center justify-center hover:bg-red-100 transition-colors cursor-pointer"
                          >
                            <Plus className="w-4 h-4" />
                          </button>
                        </div>

                        <Link
                          href="/cart"
                          className="flex-1 h-12 border border-[#0A2540] text-[#0A2540] hover:bg-[#0A2540] hover:text-white font-bold text-sm px-6 rounded-xl flex items-center justify-center gap-2 transition-all"
                        >
                          <span>View in Cart</span>
                          <ChevronRight className="w-4 h-4" />
                        </Link>
                      </div>
                    )}

                    {/* Buy Now Button */}
                    <button
                      onClick={handleBuyNow}
                      className="h-12 bg-[#0A2540] hover:bg-[#123154] text-white font-bold text-sm px-8 rounded-xl flex items-center justify-center gap-2 shadow-sm hover:shadow-md transition-all cursor-pointer"
                    >
                      <span>Buy Now</span>
                      <ChevronRight className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {/* Highlights */}
                {product.highlights && product.highlights.length > 0 && (
                  <div className="mt-8 border-t border-gray-100 pt-6">
                    <h3 className="text-sm font-black text-[#0A2540] uppercase tracking-wider mb-3">
                      Key Highlights
                    </h3>
                    <ul className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs text-gray-700">
                      {product.highlights.map((item, idx) => (
                        <li key={idx} className="flex items-center gap-2">
                          <Check className="w-4 h-4 text-emerald-600 shrink-0" />
                          <span>{item}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}

                {/* Description */}
                <div className="mt-6 border-t border-gray-100 pt-6">
                  <h3 className="text-sm font-black text-[#0A2540] uppercase tracking-wider mb-2">
                    Product Description
                  </h3>
                  <p className="text-xs sm:text-sm text-gray-600 leading-relaxed">
                    {product.description || "Fresh and authentic product delivered directly to your doorstep with guaranteed quality and timely delivery from K MART."}
                  </p>
                </div>

                {/* Store Promises Badges */}
                <div className="mt-8 grid grid-cols-3 gap-3 border-t border-gray-100 pt-6">
                  <div className="flex flex-col items-center text-center p-3 rounded-xl bg-gray-50/70 border border-gray-100">
                    <Truck className="w-5 h-5 text-[#E11A22] mb-1.5" />
                    <span className="font-bold text-xs text-gray-900">Delivery on time</span>
                    <span className="text-[10px] text-gray-500 mt-0.5">Prompt & reliable</span>
                  </div>

                  <div className="flex flex-col items-center text-center p-3 rounded-xl bg-gray-50/70 border border-gray-100">
                    <RotateCcw className="w-5 h-5 text-[#0A2540] mb-1.5" />
                    <span className="font-bold text-xs text-gray-900">Easy Returns</span>
                    <span className="text-[10px] text-gray-500 mt-0.5">At doorstep</span>
                  </div>

                  <div className="flex flex-col items-center text-center p-3 rounded-xl bg-gray-50/70 border border-gray-100">
                    <ShieldCheck className="w-5 h-5 text-emerald-600 mb-1.5" />
                    <span className="font-bold text-xs text-gray-900">100% Genuine</span>
                    <span className="text-[10px] text-gray-500 mt-0.5">Branded quality</span>
                  </div>
                </div>

              </div>
            </div>

          </div>
        </div>

        {/* Related Products Section */}
        {relatedProducts.length > 0 && (
          <section className="mt-12">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h2 className="text-xl sm:text-2xl font-black text-[#0A2540] tracking-tight">
                  Similar Products You May Like
                </h2>
                <p className="text-xs text-gray-500 mt-0.5">
                  Handpicked favorites from the {product.category.replace("-", " ")} collection
                </p>
              </div>

              <Link
                href={`/categories?cat=${product.category}`}
                className="text-xs sm:text-sm font-bold text-[#E11A22] hover:text-[#c8141b] flex items-center gap-0.5 transition-colors"
              >
                <span>View All</span>
                <ChevronRight className="w-4 h-4" />
              </Link>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3.5 sm:gap-4">
              {relatedProducts.map((p) => (
                <ProductCard key={p.id} product={p} />
              ))}
            </div>
          </section>
        )}
      </div>
    </div>
  );
}
