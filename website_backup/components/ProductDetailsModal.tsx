'use client';

import React, { useState } from 'react';
import { 
  X, 
  Star, 
  Heart, 
  Plus, 
  Minus, 
  Truck, 
  ShieldCheck, 
  ShoppingCart, 
  Check
} from 'lucide-react';
import { useApp } from '../context/AppContext';

export const ProductDetailsModal: React.FC = () => {
  const { 
    activeProductModal, 
    setActiveProductModal, 
    addToCart, 
    wishlist, 
    toggleWishlist, 
    products, 
    setIsCheckoutOpen, 
    setCheckoutStep 
  } = useApp();

  const [selectedQty, setSelectedQty] = useState(1);
  const [activeImgIdx, setActiveImgIdx] = useState(0);

  if (!activeProductModal) return null;

  const product = activeProductModal;
  const isWishlisted = wishlist.includes(product.id);
  const gallery = product.gallery && product.gallery.length > 0 ? product.gallery : [product.image];
  const relatedProducts = products.filter(p => p.id !== product.id).slice(0, 3);

  const handleAddToCart = () => {
    addToCart(product, selectedQty);
  };

  const handleBuyNow = () => {
    addToCart(product, selectedQty);
    setActiveProductModal(null);
    setCheckoutStep(1);
    setIsCheckoutOpen(true);
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-black/60 backdrop-blur-xs flex items-center justify-center p-3 sm:p-6 animate-fadeIn">
      <div className="bg-white w-full max-w-4xl rounded-2xl shadow-2xl overflow-hidden border border-gray-100 relative my-8 animate-modal-in text-left">
        
        {/* Modal Top Bar */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 bg-gray-50/70">
          <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">
            {product.brand} • {product.category}
          </span>
          <button
            onClick={() => setActiveProductModal(null)}
            className="w-8 h-8 rounded-full hover:bg-gray-200 text-gray-500 flex items-center justify-center cursor-pointer transition-colors"
            aria-label="Close modal"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Content Grid */}
        <div className="p-6 grid grid-cols-1 md:grid-cols-2 gap-8 items-start">
          
          {/* Left: Product Images & Gallery */}
          <div className="space-y-4">
            <div className="aspect-square bg-gray-50 rounded-2xl p-6 border border-gray-200/80 flex items-center justify-center relative overflow-hidden">
              {product.discountPercent > 0 && (
                <span className="absolute top-4 left-4 text-xs font-black text-[#E11A22] bg-red-50 border border-red-200 px-2.5 py-1 rounded-md">
                  {product.discountPercent}% OFF
                </span>
              )}
              <button
                onClick={() => toggleWishlist(product.id)}
                className="absolute top-4 right-4 w-9 h-9 rounded-full bg-white shadow-md flex items-center justify-center hover:bg-gray-50 text-gray-400 hover:text-[#E11A22] transition-colors cursor-pointer"
              >
                <Heart className={`w-5 h-5 ${isWishlisted ? 'fill-[#E11A22] text-[#E11A22]' : ''}`} />
              </button>

              <img
                src={gallery[activeImgIdx] || product.image}
                alt={product.name}
                className="max-h-full max-w-full object-contain"
              />
            </div>

            {/* Thumbnail Row */}
            {gallery.length > 1 && (
              <div className="flex gap-2 justify-center">
                {gallery.map((img, idx) => (
                  <button
                    key={idx}
                    onClick={() => setActiveImgIdx(idx)}
                    className={`w-14 h-14 rounded-xl border-2 overflow-hidden p-1 transition-all cursor-pointer ${
                      activeImgIdx === idx ? 'border-[#E11A22] shadow-xs' : 'border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    <img src={img} alt="" className="w-full h-full object-contain" />
                  </button>
                ))}
              </div>
            )}

            {/* Trust highlights */}
            <div className="bg-blue-50/60 rounded-xl p-3 border border-blue-100 flex items-center justify-around text-[11px] font-semibold text-blue-950">
              <span className="flex items-center gap-1">
                <Truck className="w-3.5 h-3.5 text-blue-600" />
                Delivery on time
              </span>
              <span className="flex items-center gap-1">
                <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
                100% Genuine
              </span>
            </div>
          </div>

          {/* Right: Info, Price & Actions */}
          <div className="space-y-4">
            <div>
              <span className="text-xs font-extrabold text-[#E11A22] tracking-wider uppercase">
                {product.brand}
              </span>
              <h2 className="text-xl sm:text-2xl font-black text-[#0A2540] tracking-tight mt-0.5">
                {product.name}
              </h2>
              <p className="text-xs text-gray-500 font-medium mt-1">
                Net Weight: <strong className="text-gray-800">{product.weight}</strong>
              </p>
            </div>

            {/* Rating */}
            <div className="flex items-center gap-3">
              <div className="inline-flex items-center gap-1 bg-emerald-700 text-white text-xs font-black px-2 py-0.5 rounded">
                <span>{product.rating}</span>
                <Star className="w-3 h-3 fill-current" />
              </div>
              <span className="text-xs text-gray-500">
                ({product.reviewCount.toLocaleString()} verified ratings)
              </span>
            </div>

            {/* Price Box */}
            <div className="p-4 bg-gray-50 rounded-xl border border-gray-200/80">
              <div className="flex items-baseline gap-3">
                <span className="text-2xl sm:text-3xl font-black text-[#0A2540]">
                  ₹{product.price}
                </span>
                {product.originalPrice > product.price && (
                  <>
                    <span className="text-sm text-gray-400 line-through">
                      MRP ₹{product.originalPrice}
                    </span>
                    <span className="text-xs font-black text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded">
                      Save ₹{product.originalPrice - product.price}
                    </span>
                  </>
                )}
              </div>
              <p className="text-[10px] text-gray-500 mt-1">
                Inclusive of all taxes. Free doorstep delivery on orders above ₹199.
              </p>
            </div>

            {/* Highlights */}
            {product.highlights && product.highlights.length > 0 && (
              <div className="space-y-2">
                <h4 className="font-bold text-xs text-gray-900 uppercase tracking-wider">Key Highlights</h4>
                <ul className="space-y-1.5 text-xs text-gray-600">
                  {product.highlights.map((h, i) => (
                    <li key={i} className="flex items-center gap-2">
                      <Check className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                      <span>{h}</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}

            {/* Description */}
            <div className="space-y-1 text-xs text-gray-600 leading-relaxed border-t border-gray-100 pt-3">
              <h4 className="font-bold text-xs text-gray-900 uppercase tracking-wider">Product Overview</h4>
              <p>{product.description}</p>
            </div>

            {/* Quantity Selector & Add to Cart */}
            <div className="pt-3 border-t border-gray-100 space-y-3">
              <div className="flex items-center gap-4">
                <span className="text-xs font-bold text-gray-700">Quantity:</span>
                <div className="flex items-center border-2 border-gray-200 rounded-lg overflow-hidden bg-white">
                  <button
                    onClick={() => setSelectedQty(Math.max(1, selectedQty - 1))}
                    className="w-8 h-8 flex items-center justify-center hover:bg-gray-100 text-gray-600 cursor-pointer"
                  >
                    <Minus className="w-3.5 h-3.5" />
                  </button>
                  <span className="w-10 text-center font-black text-xs">
                    {selectedQty}
                  </span>
                  <button
                    onClick={() => setSelectedQty(selectedQty + 1)}
                    className="w-8 h-8 flex items-center justify-center hover:bg-gray-100 text-gray-600 cursor-pointer"
                  >
                    <Plus className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <button
                  onClick={handleAddToCart}
                  className="bg-white hover:bg-gray-50 text-[#E11A22] border-2 border-[#E11A22] font-black py-3 rounded-xl flex items-center justify-center gap-2 text-xs sm:text-sm transition-all cursor-pointer shadow-xs"
                >
                  <ShoppingCart className="w-4 h-4" />
                  <span>Add to Cart</span>
                </button>
                <button
                  onClick={handleBuyNow}
                  className="bg-[#E11A22] hover:bg-[#c8141b] text-white font-black py-3 rounded-xl flex items-center justify-center gap-2 text-xs sm:text-sm transition-all cursor-pointer shadow-md"
                >
                  <span>Buy Now</span>
                </button>
              </div>
            </div>

          </div>

        </div>

        {/* Bottom Related Products bar */}
        {relatedProducts.length > 0 && (
          <div className="border-t border-gray-100 p-4 bg-gray-50/50">
            <h4 className="text-xs font-bold text-gray-700 uppercase tracking-wider mb-2">Customers Also Bought</h4>
            <div className="grid grid-cols-3 gap-3">
              {relatedProducts.map(rp => (
                <div
                  key={rp.id}
                  onClick={() => {
                    setActiveProductModal(rp);
                    setSelectedQty(1);
                    setActiveImgIdx(0);
                  }}
                  className="flex items-center gap-2 p-2 bg-white rounded-lg border border-gray-200 hover:border-[#E11A22] cursor-pointer transition-colors"
                >
                  <img src={rp.image} alt={rp.name} className="w-8 h-8 object-contain" />
                  <div className="min-w-0 text-left">
                    <p className="text-xs font-bold text-gray-800 truncate">{rp.name}</p>
                    <p className="text-[10px] text-gray-500">₹{rp.price}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

      </div>
    </div>
  );
};
