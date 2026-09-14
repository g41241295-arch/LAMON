import React from 'react';
import { ArrowRight } from 'lucide-react';

export default function PrimaryButton({
  children,
  onClick,
  type = 'button',
  disabled = false,
  showArrow = false,
  className = '',
}) {
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={`w-full bg-[#276F8F] hover:bg-[#1E5A74] active:scale-[0.98] text-white font-bold text-xl py-3 px-6 rounded-2xl shadow-sm transition-all duration-150 flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer ${className}`}
    >
      <span>{children}</span>
      {showArrow && <ArrowRight className="w-5 h-5 transition-transform group-hover:translate-x-1" strokeWidth={2.2} />}
    </button>
  );
}
