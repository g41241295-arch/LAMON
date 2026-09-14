import React, { useState } from 'react';
import { Check, ChevronRight } from 'lucide-react';
import AppLayout from '../components/AppLayout';
import BottomNavbar from '../components/BottomNavbar';
import { useAuth } from '../context/AuthContext';
import { MAIN_MENUS, INFO_MENUS } from '../routes/menuRoutes';

// Asset imports
import mascotHeader from '../assets/mascot-header.png';
import clockCard from '../assets/clock-card.png';
import menuPengingat from '../assets/menu-pengingat.png';
import menuCatat from '../assets/menu-catat.png';
import menuKonsul from '../assets/menu-konsul.png';
import menuPrediksi from '../assets/menu-prediksi.png';
import menuRingkasan from '../assets/menu-ringkasan.png';
import infoGastro from '../assets/info-gastro.png';
import infoBerita from '../assets/info-berita.png';

export default function BerandaPage() {
  const { currentUser } = useAuth();
  const [lunchDone, setLunchDone] = useState(false);
  const [toastMessage, setToastMessage] = useState(null);

  // Map asset keys to actual image imports
  const menuImages = {
    'menu-pengingat': menuPengingat,
    'menu-catat': menuCatat,
    'menu-konsul': menuKonsul,
    'menu-prediksi': menuPrediksi,
    'menu-ringkasan': menuRingkasan,
    'info-gastro': infoGastro,
    'info-berita': infoBerita,
  };

  const handleMenuClick = (menuTitle) => {
    console.log(`[LAMON] Menu diklik: ${menuTitle}`);
    setToastMessage(`Fitur "${menuTitle.replace('\n', ' ')}" sedang disiapkan oleh tim kami.`);
    setTimeout(() => setToastMessage(null), 3500);
  };

  const handleToggleLunch = () => {
    setLunchDone((prev) => !prev);
    const newStatus = !lunchDone;
    setToastMessage(newStatus ? 'Jam makan siang telah ditandai selesai! Bagus!' : 'Status makan siang direset.');
    setTimeout(() => setToastMessage(null), 3000);
  };

  return (
    <AppLayout className="justify-between">
      {/* Toast Notification for Unimplemented Menus */}
      {toastMessage && (
        <div className="fixed top-4 left-1/2 -translate-x-1/2 z-50 max-w-[360px] w-[90%] bg-[#276F8F] text-white px-4 py-2.5 rounded-2xl shadow-xl flex items-center justify-between animate-bounce">
          <span className="text-base font-bold leading-tight">{toastMessage}</span>
          <button
            onClick={() => setToastMessage(null)}
            className="ml-2 text-white/80 hover:text-white font-black text-lg cursor-pointer"
          >
            &times;
          </button>
        </div>
      )}

      {/* Scrollable Page Content */}
      <div className="flex-1 px-5 pt-6 pb-6 space-y-4 overflow-y-auto no-scrollbar">
        {/* ========================================================= */}
        {/* A. HEADER SAPAAN & MASKOT BERANDA                         */}
        {/* ========================================================= */}
        <section className="relative flex items-center justify-between min-h-[135px]">
          {/* Sapaan Teks Kiri */}
          <div className="flex-1 pr-2 z-10">
            <span className="block text-xl font-bold text-[#9E652B] leading-none mb-1">
              Halo, {currentUser?.name || 'Hanabi'} !
            </span>
            <h1 className="text-2xl font-black text-[#276F8F] leading-[1.1] mb-1">
              Sehatkan Lambung,<br />Mulai dari Hari ini
            </h1>
            <p className="text-sm font-medium text-[#8F6C40] leading-tight max-w-[210px]">
              Yuk, jaga pola makan dan pantau kesehatan lambungmu setiap hari
            </p>
          </div>

          {/* Maskot Kanan dengan Radiant Glow Kuning */}
          <div className="relative w-32 h-32 shrink-0 flex items-center justify-center">
            {/* Lingkaran pendar cahaya radial */}
            <div className="absolute inset-0 bg-[#FFE566]/65 rounded-full blur-lg scale-110 pointer-events-none" />
            <img
              src={mascotHeader}
              alt="Maskot LAMON"
              className="w-full h-full object-contain relative z-10 filter drop-shadow-sm pointer-events-none"
            />
          </div>
        </section>

        {/* ========================================================= */}
        {/* B. CARD "JAM MAKAN SIANG"                                 */}
        {/* ========================================================= */}
        <section className="w-full bg-gradient-to-r from-[#639BC6] to-[#80B6DC] rounded-[28px] p-4 shadow-sm border border-[#76A8D0] flex items-center gap-3.5 text-white">
          {/* Ikon Jam Analog Klasik */}
          <div className="w-18 h-18 rounded-2xl bg-white/20 border border-white/25 flex items-center justify-center shrink-0 overflow-hidden shadow-xs">
            <img
              src={clockCard}
              alt="Jam Alarm"
              className="w-14 h-14 object-contain"
            />
          </div>

          {/* Konten Teks & Tombol Selesai */}
          <div className="flex-1 flex flex-col items-start justify-center">
            <h2 className="text-2xl font-black text-[#153E54] leading-tight">
              Jam makan siang
            </h2>
            <p className="text-base font-bold text-[#153E54] leading-tight">
              12.00 – 13.00 WIB
            </p>
            <p className="text-base font-bold text-[#153E54] leading-tight mb-2">
              Jangan lupa makan !
            </p>

            <button
              onClick={handleToggleLunch}
              className={`px-4 py-1 rounded-xl text-base font-bold transition-all shadow-xs cursor-pointer active:scale-95 ${
                lunchDone
                  ? 'bg-[#38B249] text-white'
                  : 'bg-white text-[#276F8F] hover:bg-gray-50'
              }`}
            >
              {lunchDone ? 'Telah Selesai ✓' : 'Tandai selesai'}
            </button>
          </div>
        </section>

        {/* ========================================================= */}
        {/* C. CARD "RINGKASAN HARI INI"                              */}
        {/* ========================================================= */}
        <section className="w-full bg-[#C6E6F8] rounded-[28px] p-4.5 shadow-xs border border-[#A5D5F0]">
          <h2 className="text-2xl font-black text-[#1E5D7D] mb-3 text-left">
            Ringkasan hari ini
          </h2>

          {/* Horizontal Timeline 3 Tahap */}
          <div className="flex items-start justify-between w-full px-2 pt-1 pb-1">
            {/* Tahap 1: Sarapan (Selesai) */}
            <div className="flex flex-col items-center flex-1">
              <div className="w-7 h-7 rounded-full bg-[#38B249] flex items-center justify-center text-white shadow-xs">
                <Check className="w-4 h-4 stroke-[3]" />
              </div>
              <span className="text-base font-bold text-[#1E5D7D] mt-1.5 leading-none">
                Sarapan
              </span>
              <span className="text-sm font-semibold text-[#527F97] mt-0.5 leading-none">
                08.00
              </span>
            </div>

            {/* Garis Penghubung 1 -> 2 (Hijau karena sarapan selesai) */}
            <div className="flex-1 h-0.5 bg-[#38B249] mt-3.5 mx-1" />

            {/* Tahap 2: Makan Siang (Sedang Berjalan) */}
            <div className="flex flex-col items-center flex-1">
              <div
                className={`w-7 h-7 rounded-full flex items-center justify-center shadow-xs transition-colors ${
                  lunchDone ? 'bg-[#38B249] text-white' : 'bg-[#F2B705]'
                }`}
              >
                {lunchDone && <Check className="w-4 h-4 stroke-[3]" />}
              </div>
              <span className="text-base font-bold text-[#1E5D7D] mt-1.5 leading-none">
                Makan siang
              </span>
              <span className="text-sm font-semibold text-[#527F97] mt-0.5 leading-none">
                12.30
              </span>
            </div>

            {/* Garis Penghubung 2 -> 3 (Kuning / Abu-abu belum selesai) */}
            <div className="flex-1 h-0.5 bg-[#D7BE7B] mt-3.5 mx-1" />

            {/* Tahap 3: Makan Malam (Belum Berjalan) */}
            <div className="flex flex-col items-center flex-1">
              <div className="w-7 h-7 rounded-full border-2 border-[#F2B705] bg-white flex items-center justify-center shadow-xs" />
              <span className="text-base font-bold text-[#1E5D7D] mt-1.5 leading-none">
                Makan malam
              </span>
              <span className="text-sm font-semibold text-[#527F97] mt-0.5 leading-none">
                19.00
              </span>
            </div>
          </div>
        </section>

        {/* ========================================================= */}
        {/* D. SECTION "MENU UTAMA" (HORIZONTAL SCROLL + PEEK EFFECT) */}
        {/* ========================================================= */}
        <section className="w-full text-left pt-1">
          {/* Badge Judul */}
          <div className="inline-block px-5 py-1 rounded-full bg-gradient-to-b from-[#FFFDF2] to-[#F7EAC4] border border-[#DEC99B] shadow-xs text-[#6F3F1E] font-extrabold text-xl mb-3">
            Menu utama
          </div>

          {/* Container Scroll Horizontal dengan Peek Effect dan Snap Scroll */}
          {/* Card width diatur agar kartu ke-1 dan ke-2 terlihat penuh, dan kartu ke-3 sedikit terpotong di tepi kanan */}
          <div className="flex gap-3 overflow-x-auto snap-x snap-mandatory no-scrollbar pb-2 pt-1 px-1 -mx-1">
            {MAIN_MENUS.map((menu) => (
              <div
                key={menu.id}
                onClick={() => handleMenuClick(menu.shortTitle)}
                className="w-[136px] shrink-0 snap-start bg-white border border-[#7FA4BA] rounded-2xl overflow-hidden shadow-xs hover:shadow-md hover:border-[#276F8F] active:scale-[0.97] transition-all cursor-pointer flex flex-col group"
              >
                {/* Ilustrasi Card Menu */}
                <div className="w-full h-[112px] bg-[#F2F7FA] overflow-hidden flex items-center justify-center border-b border-[#D2E2EC]">
                  <img
                    src={menuImages[menu.imageKey]}
                    alt={menu.shortTitle}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200"
                  />
                </div>

                {/* Judul Menu 2 Baris */}
                <div className="py-2 px-1 text-center bg-white min-h-[46px] flex items-center justify-center">
                  <span className="font-extrabold text-lg text-[#3E2818] leading-tight whitespace-pre-line text-center">
                    {menu.title}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* ========================================================= */}
        {/* E. SECTION "SEPUTAR INFORMASI" (VERTICAL STACK)           */}
        {/* ========================================================= */}
        <section className="w-full text-left pt-1 pb-4">
          {/* Badge Judul */}
          <div className="inline-block px-5 py-1 rounded-full bg-gradient-to-b from-[#FFFDF2] to-[#F7EAC4] border border-[#DEC99B] shadow-xs text-[#6F3F1E] font-extrabold text-xl mb-3">
            Seputar Informasi
          </div>

          {/* List Card Sederhana */}
          <div className="space-y-3">
            {INFO_MENUS.map((info) => (
              <div
                key={info.id}
                onClick={() => handleMenuClick(info.title)}
                className="w-full bg-white rounded-2xl p-2.5 flex items-center justify-between shadow-xs border border-[#E2ECF2] hover:border-[#276F8F] active:scale-[0.99] transition-all cursor-pointer group"
              >
                {/* Ilustrasi Kiri */}
                <div className="w-20 h-13 flex items-center justify-center shrink-0 overflow-hidden rounded-lg bg-gray-50">
                  <img
                    src={menuImages[info.imageKey]}
                    alt={info.title}
                    className="max-w-full max-h-full object-contain group-hover:scale-105 transition-transform duration-200"
                  />
                </div>

                {/* Judul Singkat */}
                <span className="flex-1 font-extrabold text-2xl text-black ml-3 text-left">
                  {info.title}
                </span>

                {/* Ikon Panah Kanan */}
                <div className="pr-1 text-black group-hover:translate-x-1 transition-transform">
                  <ChevronRight className="w-7 h-7 stroke-[3]" />
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>

      {/* ========================================================= */}
      {/* F. BOTTOM NAVIGATION BAR (FIXED DENGAN BLUR)              */}
      {/* ========================================================= */}
      <BottomNavbar onNotice={handleMenuClick} />
    </AppLayout>
  );
}
