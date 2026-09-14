import React from 'react';

export default function AppLayout({ children, className = '' }) {
  return (
    <div className="min-h-screen bg-[#ECE7BE] flex justify-center items-center sm:py-6 selection:bg-[#2D7A9E] selection:text-white">
      {/* Mobile container simulating smartphone screen */}
      <main
        className={`w-full max-w-[420px] min-h-screen sm:min-h-[844px] sm:max-h-[920px] sm:rounded-[36px] bg-gradient-to-b from-[#FFF4A8] via-[#FAF4C8] to-[#FFFDE8] shadow-2xl overflow-y-auto overflow-x-hidden relative flex flex-col no-scrollbar border-0 sm:border-4 sm:border-[#333333]/15 ${className}`}
      >
        {children}
      </main>
    </div>
  );
}
