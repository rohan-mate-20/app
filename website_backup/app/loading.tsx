export default function Loading() {
  return (
    <div className="max-w-[1440px] w-full mx-auto px-3 sm:px-4 lg:px-6 pt-4 pb-8 space-y-6 animate-pulse">
      {/* Hero skeleton */}
      <div className="h-64 sm:h-80 bg-gray-200 rounded-3xl w-full" />
      
      {/* Category pills skeleton */}
      <div className="flex gap-4 overflow-hidden py-2">
        {[...Array(6)].map((_, i) => (
          <div key={i} className="flex flex-col items-center gap-2 shrink-0">
            <div className="w-16 h-16 sm:w-20 sm:h-20 bg-gray-200 rounded-full" />
            <div className="w-12 h-3 bg-gray-200 rounded" />
          </div>
        ))}
      </div>

      {/* Products grid skeleton */}
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
        {[...Array(8)].map((_, i) => (
          <div key={i} className="h-64 bg-gray-200 rounded-xl" />
        ))}
      </div>
    </div>
  );
}
