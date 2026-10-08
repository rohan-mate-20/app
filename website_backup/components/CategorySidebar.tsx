'use client';

import React from 'react';
import { useApp } from '../context/AppContext';

export const CategorySidebar: React.FC = () => {
  const { categories, selectedCategory, setSelectedCategory } = useApp();

  return (
    <aside className="w-64 shrink-0 bg-white rounded-2xl border border-gray-200/80 p-4 shadow-xs hidden lg:block text-left">
      <h3 className="font-black text-sm text-[#0A2540] uppercase tracking-wider mb-3 px-2">
        Categories
      </h3>
      <div className="space-y-1">
        <button
          onClick={() => setSelectedCategory('all')}
          className={`w-full text-left px-3 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center justify-between ${
            selectedCategory === 'all'
              ? 'bg-[#E11A22] text-white shadow-xs'
              : 'text-gray-700 hover:bg-gray-50'
          }`}
        >
          <span>All Products</span>
        </button>

        {categories.map((cat) => {
          const isSelected = selectedCategory === cat.slug;
          return (
            <button
              key={cat.id}
              onClick={() => setSelectedCategory(cat.slug)}
              className={`w-full text-left px-3 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center justify-between ${
                isSelected
                  ? 'bg-[#E11A22] text-white shadow-xs'
                  : 'text-gray-700 hover:bg-gray-50'
              }`}
            >
              <span>{cat.name}</span>
              {cat.itemCount && (
                <span className={`text-[10px] font-medium ${isSelected ? 'text-white/80' : 'text-gray-400'}`}>
                  {cat.itemCount}
                </span>
              )}
            </button>
          );
        })}
      </div>
    </aside>
  );
};
