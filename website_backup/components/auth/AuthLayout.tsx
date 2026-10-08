"use client";

import React from "react";
import Link from "next/link";
import { ShieldCheck, Zap, Award } from "lucide-react";

interface AuthLayoutProps {
  children: React.ReactNode;
  title?: string;
  subtitle?: string;
}

export default function AuthLayout({
  children,
  title = "India's Favorite FMCG Store",
  subtitle = "100% Genuine Branded Groceries & Essentials Delivered Daily"
}: AuthLayoutProps) {
  return (
    <div className="min-h-screen w-full flex bg-slate-950 relative overflow-hidden font-sans">
      {/* Background Fullscreen Real Image with Depth Gradients */}
      <div 
        className="absolute inset-0 bg-cover bg-center opacity-25 scale-105 filter blur-[1px] transition-transform duration-1000"
        style={{
          backgroundImage: `url('https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&w=1920&q=80')`
        }}
      />
      {/* Soft Dark Neutral Gradient Overlay (drastically reduced blue) */}
      <div className="absolute inset-0 bg-gradient-to-r from-slate-950/90 via-slate-900/75 to-black/85" />

      <div className="relative z-10 flex flex-col lg:flex-row w-full min-h-screen">
        
        {/* Left Visual Brand Story Panel (Desktop) */}
        <div className="hidden lg:flex lg:w-1/2 flex-col justify-between p-12 xl:p-16 text-white relative">
          
          {/* Top Brand Logo */}
          <div className="flex items-center justify-between">
            <Link href="/" className="flex items-center gap-2.5 group">
              <div className="bg-[#E11A22] text-white font-black text-2xl tracking-tighter w-11 h-11 rounded-xl flex items-center justify-center shadow-lg group-hover:scale-105 transition-transform">
                K
              </div>
              <span className="font-black text-2xl tracking-tight text-white">
                MART
              </span>
            </Link>
          </div>

          {/* Center Showcase Card - Large, Bold & Premium */}
          <div className="my-auto max-w-xl xl:max-w-2xl space-y-8">
            <div className="space-y-4">
              <h1 className="text-4xl sm:text-5xl xl:text-6xl font-black text-white tracking-tight leading-[1.12]">
                Fresh daily essentials, <br />
                <span className="text-[#E11A22]">delivered on time.</span>
              </h1>

              <p className="text-base sm:text-lg xl:text-xl text-gray-300 font-normal leading-relaxed">
                Pantry staples, dairy, snacks & household essentials from your favorite brands at wholesale prices.
              </p>
            </div>

            {/* Feature Points - Large & Clear */}
            <div className="space-y-4 pt-2">
              <div className="flex items-center gap-3.5 text-gray-100">
                <div className="w-10 h-10 rounded-xl bg-emerald-500/20 text-emerald-400 flex items-center justify-center shrink-0">
                  <ShieldCheck className="w-5 h-5" />
                </div>
                <span className="font-semibold text-sm sm:text-base xl:text-lg">100% genuine branded sealed packs</span>
              </div>

              <div className="flex items-center gap-3.5 text-gray-100">
                <div className="w-10 h-10 rounded-xl bg-amber-500/20 text-amber-400 flex items-center justify-center shrink-0">
                  <Zap className="w-5 h-5" />
                </div>
                <span className="font-semibold text-sm sm:text-base xl:text-lg">Scheduled on-time delivery to your door</span>
              </div>

              <div className="flex items-center gap-3.5 text-gray-100">
                <div className="w-10 h-10 rounded-xl bg-red-500/20 text-red-400 flex items-center justify-center shrink-0">
                  <Award className="w-5 h-5" />
                </div>
                <span className="font-semibold text-sm sm:text-base xl:text-lg">Direct wholesale rates & everyday savings</span>
              </div>
            </div>
          </div>

        </div>

        {/* Right Form Card Panel */}
        <div className="flex-1 flex flex-col justify-center items-center p-4 sm:p-8 lg:p-12 relative">
          
          {/* Mobile Top Header */}
          <div className="w-full max-w-md flex lg:hidden items-center justify-between mb-6">
            <Link href="/" className="flex items-center gap-2">
              <div className="bg-[#E11A22] text-white font-black text-xl w-9 h-9 rounded-lg flex items-center justify-center shadow-md">
                K
              </div>
              <span className="font-black text-xl text-white">
                MART
              </span>
            </Link>
          </div>

          {/* Form Card Container */}
          <div className="w-full max-w-md bg-white rounded-3xl p-6 sm:p-8 shadow-2xl border border-gray-100 relative">
            {children}
          </div>

        </div>

      </div>
    </div>
  );
}
