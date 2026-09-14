import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Clock } from 'lucide-react';
import AppLayout from '../components/AppLayout';
import PrimaryButton from '../components/PrimaryButton';
import lamonLogo from '../assets/lamon-logo.png';

export default function PlaceholderPage({ title, description }) {
  const navigate = useNavigate();

  return (
    <AppLayout className="p-6 justify-between items-center text-center">
      {/* Top Bar */}
      <div className="w-full flex items-center justify-between pt-2">
        <button
          onClick={() => navigate('/beranda')}
          className="p-2 -ml-2 text-[#1C4E68] hover:bg-black/5 rounded-full transition-colors flex items-center gap-1 font-bold text-lg cursor-pointer"
        >
          <ArrowLeft className="w-6 h-6" />
          <span>Kembali</span>
        </button>
        <span className="font-bold text-xl text-[#276F8F]">LAMON</span>
        <div className="w-16" />
      </div>

      {/* Content */}
      <div className="flex flex-col items-center max-w-xs my-auto">
        <div className="w-28 h-28 mb-6 relative">
          <div className="absolute inset-0 bg-yellow-300/40 rounded-full blur-xl animate-pulse" />
          <img
            src={lamonLogo}
            alt="LAMON Logo"
            className="w-full h-full object-contain relative z-10"
          />
        </div>

        <div className="inline-flex items-center gap-1.5 px-3.5 py-1 rounded-full bg-[#FFF1B8] border border-[#DEC99B] text-[#7A4426] text-sm font-bold mb-3">
          <Clock className="w-4 h-4" />
          <span>Tahap Pengembangan</span>
        </div>

        <h1 className="text-3xl font-extrabold text-[#1C4E68] mb-2 leading-tight">
          {title || 'Halaman Menu'}
        </h1>

        <p className="text-lg text-[#5A7B8E] font-medium leading-relaxed mb-6">
          {description ||
            'Desain untuk halaman ini akan segera diimplementasikan sesuai alur desain berikutnya dari tim Anda.'}
        </p>

        <PrimaryButton onClick={() => navigate('/beranda')} className="w-full max-w-xs">
          Kembali ke Beranda
        </PrimaryButton>
      </div>

      {/* Footer Info */}
      <div className="pb-4 text-sm text-[#8C9EA8] font-semibold">
        Aplikasi LAMON &bull; Pemantauan Kesehatan Lambung
      </div>
    </AppLayout>
  );
}
