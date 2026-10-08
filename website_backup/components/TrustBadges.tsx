import React from 'react';
import { Truck, ShieldCheck, Percent, Headphones } from 'lucide-react';

export const TrustBadges: React.FC = () => {
  const badges = [
    {
      icon: <Truck className="w-5 h-5 text-white" />,
      title: 'Delivery on time',
      subtitle: 'On-time, every time',
      bgColor: 'bg-[#E11A22]'
    },
    {
      icon: <ShieldCheck className="w-5 h-5 text-white" />,
      title: 'Quality Products',
      subtitle: 'Trusted brands',
      bgColor: 'bg-[#E11A22]'
    },
    {
      icon: <Percent className="w-5 h-5 text-white" />,
      title: 'Great Deals',
      subtitle: 'Save more everyday',
      bgColor: 'bg-[#E11A22]'
    },
    {
      icon: <Headphones className="w-5 h-5 text-white" />,
      title: 'Need Help?',
      subtitle: "We're here for you",
      bgColor: 'bg-[#E11A22]'
    }
  ];

  return (
    <section className="mt-6 sm:mt-7 bg-white rounded-xl border border-gray-200/80 p-4 sm:p-5 shadow-xs">
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 divide-y sm:divide-y-0 sm:divide-x divide-gray-100">
        {badges.map((item, idx) => (
          <div 
            key={idx} 
            className={`flex items-center gap-3.5 ${idx !== 0 ? 'sm:pl-6 pt-4 sm:pt-0' : ''}`}
          >
            <div className={`w-11 h-11 rounded-xl ${item.bgColor} flex items-center justify-center shrink-0 shadow-xs`}>
              {item.icon}
            </div>
            <div className="text-left">
              <h4 className="font-bold text-sm text-gray-900 leading-tight">
                {item.title}
              </h4>
              <p className="text-xs text-gray-500 font-medium mt-0.5">
                {item.subtitle}
              </p>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
};
