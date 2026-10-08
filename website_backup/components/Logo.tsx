import React from 'react';

interface LogoProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  showTagline?: boolean;
  className?: string;
  white?: boolean;
}

export const Logo: React.FC<LogoProps> = ({ 
  size = 'md', 
  showTagline = true, 
  className = '',
  white = false
}) => {
  const textSize = {
    sm: 'text-lg',
    md: 'text-2xl',
    lg: 'text-3xl',
    xl: 'text-4xl'
  }[size];

  const taglineSize = {
    sm: 'text-[9px]',
    md: 'text-[10px]',
    lg: 'text-xs',
    xl: 'text-sm'
  }[size];

  return (
    <div className={`inline-flex flex-col select-none leading-none ${className}`}>
      <div className={`font-black tracking-tight flex items-baseline ${textSize}`}>
        <span className="text-[#E11A22] italic font-black text-[1.15em] transform -skew-x-6 mr-[1px]">
          K
        </span>
        <span className={white ? 'text-white tracking-wider' : 'text-[#0A2540] tracking-wider'}>
          MART
        </span>
      </div>
      {showTagline && (
        <span className={`${taglineSize} font-medium tracking-tight mt-0.5 ${white ? 'text-slate-300' : 'text-[#0A2540]/80'}`}>
          Daily Essentials, Delivered
        </span>
      )}
    </div>
  );
};
