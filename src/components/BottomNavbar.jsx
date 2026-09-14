import React from 'react';
import { useLocation, useNavigate } from 'react-router-dom';

export default function BottomNavbar({ onNotice }) {
  const location = useLocation();
  const navigate = useNavigate();

  const handleNav = (target, name) => {
    if (target === '/beranda') {
      navigate('/beranda');
    } else {
      if (onNotice) {
        onNotice(name);
      } else {
        alert(`Halaman ${name} akan segera hadir pada update berikutnya.`);
      }
    }
  };

  const isHome = location.pathname === '/beranda' || location.pathname === '/';

  return (
    <div className="sticky bottom-0 left-0 right-0 z-40 w-full pointer-events-auto">
      <div className="relative mx-auto max-w-[420px] bg-[#9ABED4]/95 backdrop-blur-md shadow-lg border-t border-[#8CAEC3]">
        {/* Raised center dome cutout effect */}
        <div className="absolute left-1/2 -top-5 -translate-x-1/2 flex items-center justify-center">
          <button
            onClick={() => handleNav('/beranda', 'Beranda')}
            aria-label="Beranda"
            className="w-13 h-13 rounded-full bg-[#9ABED4] border-[3px] border-[#FAF4C8] shadow-md flex items-center justify-center hover:scale-105 active:scale-95 transition-transform"
          >
            {/* Home Icon */}
            <svg
              className="w-6 h-6 text-black fill-current"
              viewBox="0 0 24 24"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path d="M12 3L2 12h3v8h6v-6h2v6h6v-8h3L12 3z" />
            </svg>
          </button>
        </div>

        {/* 3 Nav Items Container */}
        <div className="flex items-center justify-between px-10 py-3.5 h-15">
          {/* Chat Icon (left) */}
          <button
            onClick={() => handleNav('/chat', 'Pesan / Konsultasi')}
            aria-label="Pesan"
            className="p-2 text-black hover:opacity-75 transition-opacity"
          >
            {/* Speech bubble with dots */}
            <svg
              className="w-6 h-6 text-black fill-current"
              viewBox="0 0 24 24"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-6 9c-.55 0-1-.45-1-1s.45-1 1-1 1 .45 1 1-.45 1-1 1zm-4 0c-.55 0-1-.45-1-1s.45-1 1-1 1 .45 1 1-.45 1-1 1zm-4 0c-.55 0-1-.45-1-1s.45-1 1-1 1 .45 1 1-.45 1-1 1z" />
            </svg>
          </button>

          {/* Spacer for center home button */}
          <div className="w-12 h-6" />

          {/* Profile Icon (right) */}
          <button
            onClick={() => handleNav('/profile', 'Profil Pengguna')}
            aria-label="Profil"
            className="p-2 text-black hover:opacity-75 transition-opacity"
          >
            {/* Person silhouette */}
            <svg
              className="w-6 h-6 text-black fill-current"
              viewBox="0 0 24 24"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z" />
            </svg>
          </button>
        </div>
      </div>
    </div>
  );
}
