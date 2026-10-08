'use client';

import React from 'react';
import Link from 'next/link';
import { Logo } from './Logo';
import { Shield, Smartphone, Heart, Phone, Mail, MapPin } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { usePathname } from 'next/navigation';

export const Footer: React.FC = () => {
  const pathname = usePathname();
  const { categories, activeStore } = useApp();

  // Hide footer on login and otp pages
  const isAuthPage = 
    pathname === '/login' || 
    pathname === '/otp' || 
    pathname?.startsWith('/login') || 
    pathname?.startsWith('/otp');

  if (isAuthPage) {
    return null;
  }

  return (
    <footer className="bg-[#0A2540] text-gray-300 mt-16 pt-12 pb-24 md:pb-8 border-t border-slate-800 text-left">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Top Footer Row */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-8 pb-10 border-b border-white/10">
          
          {/* Col 1: Brand & Bio */}
          <div className="lg:col-span-2 space-y-4">
            <Link href="/" className="inline-block">
              <Logo size="lg" white={true} />
            </Link>
            <p className="text-xs sm:text-sm text-gray-300 max-w-sm leading-relaxed mt-2">
              K MART brings branded pantry staples, packaged groceries, snacks, beverages, personal care, and daily household essentials straight to your doorstep with guaranteed delivery on time.
            </p>
            <div className="pt-2 text-xs space-y-1.5 text-gray-300">
              <p className="flex items-center gap-2">
                <Phone className="w-3.5 h-3.5 text-[#E11A22]" />
                <span>Customer Care: +91 1800-KMART-HELP</span>
              </p>
              <p className="flex items-center gap-2">
                <Mail className="w-3.5 h-3.5 text-[#E11A22]" />
                <span>Email: support@kmartgrocery.in</span>
              </p>
              {activeStore && (
                <p className="flex items-center gap-2 text-gray-400">
                  <MapPin className="w-3.5 h-3.5 text-emerald-400" />
                  <span>Fulfillment Store: {activeStore.name}, {activeStore.address}</span>
                </p>
              )}
            </div>
          </div>

          {/* Col 2: Categories Links */}
          <div>
            <h4 className="font-bold text-sm text-white uppercase tracking-wider mb-4">
              Categories
            </h4>
            <ul className="space-y-2 text-xs font-medium">
              <li>
                <Link
                  href="/categories"
                  className="hover:text-white transition-colors block text-[#E11A22] font-bold"
                >
                  All Categories &rarr;
                </Link>
              </li>
              {categories.slice(0, 6).map((cat) => (
                <li key={cat.id}>
                  <Link
                    href={`/categories?cat=${cat.slug}`}
                    className="hover:text-white transition-colors block"
                  >
                    {cat.name}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Col 3: Quick Navigation */}
          <div>
            <h4 className="font-bold text-sm text-white uppercase tracking-wider mb-4">
              Quick Navigation
            </h4>
            <ul className="space-y-2 text-xs font-medium text-gray-300">
              <li>
                <Link href="/" className="hover:text-white transition-colors block">
                  Home Page
                </Link>
              </li>
              <li>
                <Link href="/categories" className="hover:text-white transition-colors block">
                  Shop by Category
                </Link>
              </li>
              <li>
                <Link href="/offers" className="hover:text-white transition-colors block">
                  Deals & Coupons
                </Link>
              </li>
              <li>
                <Link href="/cart" className="hover:text-white transition-colors block">
                  My Shopping Cart
                </Link>
              </li>
              <li>
                <Link href="/orders" className="hover:text-white transition-colors block">
                  My Orders & Live Tracking
                </Link>
              </li>
              <li>
                <Link href="/location" className="hover:text-white transition-colors block">
                  Delivery Location
                </Link>
              </li>
            </ul>
          </div>

          {/* Col 4: Trust & Guarantee */}
          <div>
            <h4 className="font-bold text-sm text-white uppercase tracking-wider mb-4">
              100% Safe Shopping
            </h4>
            <div className="space-y-3 text-xs text-gray-300">
              <div className="flex items-start gap-2.5">
                <Shield className="w-4 h-4 text-emerald-400 mt-0.5 shrink-0" />
                <span>Genuine products directly sourced from authorized brand distributors.</span>
              </div>
              <div className="flex items-start gap-2.5">
                <Smartphone className="w-4 h-4 text-blue-400 mt-0.5 shrink-0" />
                <span>Instant order updates and SMS notifications on WhatsApp & SMS.</span>
              </div>
            </div>
          </div>

        </div>

        {/* Bottom copyright row */}
        <div className="pt-8 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-gray-400">
          <p>© {new Date().getFullYear()} K MART Retail Pvt Ltd. All rights reserved.</p>
          <div className="flex items-center gap-4">
            <Link href="/offers" className="hover:text-white transition-colors">Offers</Link>
            <span>•</span>
            <Link href="/categories" className="hover:text-white transition-colors">Categories</Link>
            <span>•</span>
            <Link href="/orders" className="hover:text-white transition-colors">Orders</Link>
          </div>
        </div>

      </div>
    </footer>
  );
};
