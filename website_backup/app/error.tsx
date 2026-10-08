'use client';

import React, { useEffect } from 'react';
import { AlertCircle } from 'lucide-react';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="min-h-[60vh] flex flex-col items-center justify-center p-6 text-center">
      <div className="w-14 h-14 rounded-full bg-red-50 text-[#E11A22] flex items-center justify-center mb-4">
        <AlertCircle className="w-8 h-8" />
      </div>
      <h2 className="text-xl font-black text-[#0A2540]">Something went wrong!</h2>
      <p className="text-xs text-gray-500 mt-1 max-w-sm">
        We encountered an error loading the storefront. Please try refreshing.
      </p>
      <button
        onClick={() => reset()}
        className="mt-4 bg-[#E11A22] hover:bg-[#c8141b] text-white text-xs font-bold px-4 py-2.5 rounded-xl transition-all cursor-pointer"
      >
        Try Again
      </button>
    </div>
  );
}
