'use client';
import React from 'react';
import Link from 'next/link';
import { Heart, Plus, Minus } from 'lucide-react';
import { Product } from '../types';
import { useApp } from '../context/AppContext';

interface ProductCardProps {
  product: Product;
}

export const ProductCard: React.FC<ProductCardProps> = ({ product }) => {
  const { 
    cart, 
    addToCart, 
    updateQuantity, 
    removeFromCart, 
    setActiveProductModal, 
    wishlist, 
    toggleWishlist 
  } = useApp();

  const cartItem = cart.find(item => item.product.id === product.id);
  const quantity = cartItem ? cartItem.quantity : 0;
  const isWishlisted = wishlist.includes(product.id);

  return (
    <div className="bg-white rounded-xl border border-gray-200/90 hover:border-gray-300 shadow-xs hover:shadow-md transition-all duration-200 flex flex-col justify-between p-3 sm:p-4 group relative">
      
      {/* Top action row: Discount badge (if any) & Wishlist heart */}
      <div className="flex items-center justify-between gap-1 mb-2">
        {product.discountPercent > 0 ? (
          <span className="text-[11px] font-extrabold text-[#E11A22] bg-red-50 border border-red-100 px-2 py-0.5 rounded-md">
            {product.discountPercent}% OFF
          </span>
        ) : <div />}
        
        <button
          onClick={(e) => {
            e.stopPropagation();
            toggleWishlist(product.id);
          }}
          className="w-7 h-7 rounded-full flex items-center justify-center hover:bg-gray-100 transition-colors text-gray-400 hover:text-[#E11A22] cursor-pointer"
          aria-label="Add to Wishlist"
        >
          <Heart 
            className={`w-4 h-4 transition-colors ${
              isWishlisted ? 'fill-[#E11A22] text-[#E11A22]' : 'text-gray-400'
            }`} 
          />
        </button>
      </div>

      {/* Product Image Clickable Link */}
      <Link 
        href={`/product/${product.id}`}
        className="w-full aspect-square relative flex items-center justify-center p-2 mb-2 cursor-pointer bg-white rounded-lg overflow-hidden block"
      >
        <img
          src={product.image}
          alt={product.name}
          className="max-h-full max-w-full object-contain transform group-hover:scale-105 transition-transform duration-300"
          loading="lazy"
        />
      </Link>

      {/* Product Details */}
      <div className="text-left space-y-1">
        <span className="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">
          {product.brand}
        </span>

        <Link
          href={`/product/${product.id}`}
          className="font-bold text-xs sm:text-sm text-gray-900 hover:text-[#E11A22] transition-colors line-clamp-2 leading-snug cursor-pointer h-9 block"
          title={product.name}
        >
          {product.name}
        </Link>

        <p className="text-[11px] font-medium text-gray-500">
          {product.weight}
        </p>
      </div>

      {/* Pricing & Add to Cart button */}
      <div className="mt-3 pt-2.5 border-t border-gray-100 flex items-center justify-between gap-2">
        <div className="text-left">
          <div className="flex items-baseline gap-1.5">
            <span className="font-black text-sm sm:text-base text-[#0A2540]">
              ₹{product.price}
            </span>
            {product.originalPrice > product.price && (
              <span className="text-[11px] text-gray-400 line-through">
                ₹{product.originalPrice}
              </span>
            )}
          </div>
        </div>

        {/* Dynamic Quantity or ADD Button */}
        <div>
          {quantity > 0 ? (
            <div className="flex items-center bg-[#E11A22] text-white rounded-lg px-1 py-1 shadow-xs">
              <button
                onClick={() => updateQuantity(product.id, quantity - 1)}
                className="w-6 h-6 flex items-center justify-center hover:bg-black/20 rounded transition-colors cursor-pointer"
                aria-label="Decrease quantity"
              >
                <Minus className="w-3.5 h-3.5" />
              </button>
              <span className="font-black text-xs px-2 select-none">
                {quantity}
              </span>
              <button
                onClick={() => updateQuantity(product.id, quantity + 1)}
                className="w-6 h-6 flex items-center justify-center hover:bg-black/20 rounded transition-colors cursor-pointer"
                aria-label="Increase quantity"
              >
                <Plus className="w-3.5 h-3.5" />
              </button>
            </div>
          ) : (
            <button
              onClick={() => addToCart(product)}
              className="bg-white hover:bg-[#E11A22] text-[#E11A22] hover:text-white border border-[#E11A22] font-black text-xs px-3.5 py-1.5 rounded-lg shadow-2xs hover:shadow-xs transition-all cursor-pointer"
            >
              ADD
            </button>
          )}
        </div>
      </div>

    </div>
  );
};
