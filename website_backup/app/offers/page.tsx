"use client";

import React, { useState, useMemo } from "react";
import Link from "next/link";
import { 
  Tag, 
  Percent, 
  Sparkles, 
  Copy, 
  Check, 
  CreditCard, 
  Clock, 
  ArrowRight, 
  ShoppingBag, 
  ChevronRight,
  Flame,
  Zap,
  Gift
} from "lucide-react";
import { useApp } from "@/context/AppContext";
import { ProductCard } from "@/components/ProductCard";

interface Coupon {
  code: string;
  title: string;
  description: string;
  discountText: string;
  minOrder: number;
  validUntil: string;
  badge: string;
  color: string;
}

export default function OffersPage() {
  const { products, categories, setSelectedCategory } = useApp();
  const [selectedOfferCategory, setSelectedOfferCategory] = useState<string>("all");
  const [copiedCode, setCopiedCode] = useState<string | null>(null);

  const coupons: Coupon[] = [
    {
      code: "KMART45",
      title: "Flat ₹45 OFF",
      description: "Valid on daily essentials, groceries & packaged foods",
      discountText: "Flat ₹45 OFF",
      minOrder: 250,
      validUntil: "Valid till end of month",
      badge: "MOST POPULAR",
      color: "from-red-600 to-rose-700",
    },
    {
      code: "SUPER100",
      title: "Flat ₹100 OFF",
      description: "Mega weekend savings on shopping baskets above ₹999",
      discountText: "Flat ₹100 OFF",
      minOrder: 999,
      validUntil: "Valid this weekend",
      badge: "MEGA SAVER",
      color: "from-[#0A2540] to-[#123154]",
    },
    {
      code: "FREEDEL",
      title: "Free Express Delivery",
      description: "Zero delivery fee on all orders across Pune city",
      discountText: "FREE DELIVERY",
      minOrder: 500,
      validUntil: "Valid for next 7 days",
      badge: "NO CODE CHARGE",
      color: "from-emerald-700 to-teal-800",
    },
    {
      code: "FIRST3",
      title: "New User Special",
      description: "Free delivery on your first 3 orders with K MART",
      discountText: "3x FREE DEL",
      minOrder: 300,
      validUntil: "Welcome offer",
      badge: "NEW CUSTOMER",
      color: "from-amber-600 to-orange-700",
    },
  ];

  const bankOffers = [
    {
      bank: "HDFC Bank Cards",
      offer: "10% Instant Discount up to ₹150",
      minSpend: "Min. spend ₹750",
      code: "HDFCDEAL",
      badge: "CREDIT & DEBIT",
    },
    {
      bank: "ICICI Bank NetBanking",
      offer: "Flat ₹75 Cashback on Grocery Orders",
      minSpend: "Min. spend ₹600",
      code: "ICICISAVE",
      badge: "NETBANKING",
    },
    {
      bank: "UPI Payments (GPay / PhonePe)",
      offer: "Up to ₹50 Scratch Card Cashback",
      minSpend: "Min. spend ₹200",
      code: "AUTO-APPLIED",
      badge: "UPI INSTANT",
    },
    {
      bank: "CRED Pay",
      offer: "Assured ₹30 - ₹100 Cashback on CRED UPI",
      minSpend: "No min order",
      code: "CRED-EXCLUSIVE",
      badge: "WALLET / UPI",
    },
  ];

  // Copy coupon code helper
  const handleCopyCode = (code: string) => {
    navigator.clipboard.writeText(code);
    setCopiedCode(code);
    setTimeout(() => {
      setCopiedCode(null);
    }, 2500);
  };

  // Filter products on offer (discountPercent > 0 or selling_price < mrp)
  const offerProducts = useMemo(() => {
    return products.filter((p) => {
      const hasDiscount = (p.discountPercent && p.discountPercent > 0) || (p.originalPrice && p.originalPrice > p.price);
      if (!hasDiscount) return false;

      if (selectedOfferCategory === "all") return true;
      return p.category?.toLowerCase() === selectedOfferCategory.toLowerCase();
    }).sort((a, b) => (b.discountPercent || 0) - (a.discountPercent || 0));
  }, [products, selectedOfferCategory]);

  return (
    <div className="min-h-screen bg-[#F8F9FA] pb-20">
      {/* Top Breadcrumb */}
      <div className="bg-white border-b border-gray-200/80 shadow-2xs">
        <div className="max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 py-3 flex items-center justify-between">
          <div className="flex items-center gap-2 text-xs sm:text-sm text-gray-500">
            <Link href="/" className="hover:text-[#E11A22] transition-colors">
              Home
            </Link>
            <ChevronRight className="w-3.5 h-3.5 text-gray-400" />
            <span className="font-semibold text-gray-900">Deals & Offers</span>
          </div>

          <Link
            href="/categories"
            className="text-xs font-bold text-[#E11A22] hover:underline"
          >
            Explore All Categories
          </Link>
        </div>
      </div>

      <div className="max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 pt-6 space-y-8">
        
        {/* Hero Banner */}
        <div className="relative rounded-3xl bg-gradient-to-r from-[#0A2540] via-[#123154] to-[#E11A22] text-white p-6 sm:p-10 lg:p-12 overflow-hidden shadow-lg">
          <div className="absolute right-0 top-0 bottom-0 w-1/2 opacity-10 bg-[radial-gradient(#fff_1px,transparent_1px)] [background-size:16px_16px]" />
          
          <div className="relative z-10 max-w-2xl space-y-3">
            <div className="inline-flex items-center gap-2 bg-white/15 backdrop-blur-md px-3.5 py-1 rounded-full text-xs font-black uppercase tracking-wider text-amber-300 border border-white/20">
              <Flame className="w-4 h-4 text-amber-400 fill-amber-400 animate-bounce" />
              <span>Mega Savings Zone</span>
            </div>

            <h1 className="text-3xl sm:text-4xl lg:text-5xl font-black tracking-tight leading-tight">
              Best Grocery Deals & <br className="hidden sm:inline" />
              <span className="text-amber-300">Discount Coupons</span>
            </h1>

            <p className="text-xs sm:text-sm text-gray-200 font-medium max-w-lg leading-relaxed">
              Save big on daily staples, dairy, snacks, and personal care. Copy coupons, unlock bank cashbacks, and get express doorstep delivery!
            </p>

            <div className="pt-2 flex flex-wrap items-center gap-3 text-xs font-bold">
              <span className="bg-white/20 px-3 py-1.5 rounded-lg flex items-center gap-1.5">
                <Check className="w-3.5 h-3.5 text-emerald-400" /> 100% Genuine Branded Products
              </span>
              <span className="bg-white/20 px-3 py-1.5 rounded-lg flex items-center gap-1.5">
                <Zap className="w-3.5 h-3.5 text-amber-300" /> Instant Coupon Redemption
              </span>
            </div>
          </div>
        </div>

        {/* Section 1: Coupons Grid */}
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-xl sm:text-2xl font-black text-[#0A2540] tracking-tight flex items-center gap-2">
                <Tag className="w-5 h-5 text-[#E11A22]" />
                <span>Coupon Codes for You</span>
              </h2>
              <p className="text-xs text-gray-500 mt-0.5">
                Copy coupon code and apply during checkout for instant discount
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {coupons.map((coupon) => {
              const isCopied = copiedCode === coupon.code;
              return (
                <div
                  key={coupon.code}
                  className="bg-white rounded-2xl border border-gray-200/90 shadow-2xs overflow-hidden flex flex-col justify-between hover:shadow-md transition-all group"
                >
                  {/* Coupon Header Band */}
                  <div className={`bg-gradient-to-r ${coupon.color} p-4 text-white relative`}>
                    <div className="flex items-center justify-between mb-1.5">
                      <span className="text-[10px] font-black uppercase bg-white/20 px-2 py-0.5 rounded-full tracking-wider">
                        {coupon.badge}
                      </span>
                      <span className="text-[10px] font-semibold opacity-80">
                        {coupon.validUntil}
                      </span>
                    </div>
                    <h3 className="text-xl font-black">{coupon.discountText}</h3>
                    <p className="text-xs opacity-90 mt-0.5 line-clamp-1">
                      Min. Order: ₹{coupon.minOrder}
                    </p>
                  </div>

                  {/* Coupon Body & Action */}
                  <div className="p-4 space-y-3 flex-1 flex flex-col justify-between">
                    <p className="text-xs text-gray-600 leading-snug">
                      {coupon.description}
                    </p>

                    <div className="pt-2 flex items-center justify-between gap-2 border-t border-dashed border-gray-200">
                      <div className="bg-gray-100/90 border border-gray-300/80 px-2.5 py-1 rounded-lg font-mono font-black text-xs text-[#0A2540] tracking-wider">
                        {coupon.code}
                      </div>

                      <button
                        onClick={() => handleCopyCode(coupon.code)}
                        className={`text-xs font-bold px-3 py-1.5 rounded-xl flex items-center gap-1.5 transition-all cursor-pointer ${
                          isCopied
                            ? "bg-emerald-600 text-white shadow-xs"
                            : "bg-[#0A2540] hover:bg-[#E11A22] text-white"
                        }`}
                      >
                        {isCopied ? (
                          <>
                            <Check className="w-3.5 h-3.5" />
                            <span>Copied!</span>
                          </>
                        ) : (
                          <>
                            <Copy className="w-3.5 h-3.5" />
                            <span>Copy Code</span>
                          </>
                        )}
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </section>

        {/* Section 2: Bank & Wallet Offers */}
        <section className="bg-white rounded-2xl border border-gray-200/90 p-5 sm:p-6 shadow-2xs space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg sm:text-xl font-black text-[#0A2540] tracking-tight flex items-center gap-2">
                <CreditCard className="w-5 h-5 text-indigo-600" />
                <span>Bank & Wallet Offers</span>
              </h2>
              <p className="text-xs text-gray-500 mt-0.5">
                Pay using eligible bank cards or UPI apps to receive instant cashback
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {bankOffers.map((bo, idx) => (
              <div
                key={idx}
                className="p-4 rounded-xl border border-gray-200/80 bg-gray-50/60 hover:bg-white hover:border-indigo-300 hover:shadow-xs transition-all space-y-2"
              >
                <div className="flex items-center justify-between">
                  <span className="text-[10px] font-bold text-indigo-700 bg-indigo-50 border border-indigo-200 px-2 py-0.5 rounded-full uppercase">
                    {bo.badge}
                  </span>
                  <span className="text-[11px] font-mono font-bold text-gray-500">
                    {bo.code}
                  </span>
                </div>
                <h3 className="font-extrabold text-sm text-[#0A2540] leading-snug">
                  {bo.offer}
                </h3>
                <p className="text-xs text-gray-500">{bo.bank}</p>
                <p className="text-[11px] text-emerald-700 font-bold">{bo.minSpend}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Section 3: Discounted Products Catalog */}
        <section className="space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div>
              <h2 className="text-xl sm:text-2xl font-black text-[#0A2540] tracking-tight flex items-center gap-2">
                <Percent className="w-5 h-5 text-[#E11A22]" />
                <span>Super Saver Products on Sale</span>
              </h2>
              <p className="text-xs text-gray-500 mt-0.5">
                Handpicked branded grocery items with direct price drops ({offerProducts.length} items available)
              </p>
            </div>

            {/* Category Filter Pills for Offers */}
            <div className="flex items-center gap-2 overflow-x-auto pb-1 [scrollbar-width:none]">
              <button
                onClick={() => setSelectedOfferCategory("all")}
                className={`text-xs font-bold px-3 py-1.5 rounded-full transition-all shrink-0 cursor-pointer ${
                  selectedOfferCategory === "all"
                    ? "bg-[#E11A22] text-white shadow-xs"
                    : "bg-white border border-gray-200 text-gray-700 hover:border-gray-400"
                }`}
              >
                All Offers
              </button>
              {categories.map((cat) => (
                <button
                  key={cat.id}
                  onClick={() => setSelectedOfferCategory(cat.slug)}
                  className={`text-xs font-bold px-3 py-1.5 rounded-full transition-all shrink-0 cursor-pointer ${
                    selectedOfferCategory === cat.slug
                      ? "bg-[#E11A22] text-white shadow-xs"
                      : "bg-white border border-gray-200 text-gray-700 hover:border-gray-400"
                  }`}
                >
                  {cat.name}
                </button>
              ))}
            </div>
          </div>

          {/* Products Grid */}
          {offerProducts.length === 0 ? (
            <div className="bg-white rounded-2xl border border-gray-200 p-12 text-center">
              <ShoppingBag className="w-12 h-12 text-gray-300 mx-auto mb-3" />
              <h3 className="font-bold text-base text-gray-800">No discounted items in this category</h3>
              <p className="text-xs text-gray-500 mt-1">Switch to "All Offers" to browse all discounted essentials.</p>
              <button
                onClick={() => setSelectedOfferCategory("all")}
                className="mt-4 px-4 py-2 bg-[#0A2540] text-white text-xs font-bold rounded-xl"
              >
                View All Offers
              </button>
            </div>
          ) : (
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-3.5 sm:gap-4">
              {offerProducts.map((product) => (
                <ProductCard key={product.id} product={product} />
              ))}
            </div>
          )}
        </section>

      </div>
    </div>
  );
}
