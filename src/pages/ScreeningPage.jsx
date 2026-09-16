import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Check, ChevronLeft, ChevronRight } from 'lucide-react';

export default function ScreeningPage() {
  const navigate = useNavigate();
  const { completeScreening } = useAuth();

  // step: 1 (Gender) | 2 (Birthdate) | 3 (History) | 4 (Success)
  const [step, setStep] = useState(1);
  const [gender, setGender] = useState(null);
  const [day, setDay] = useState(1);
  const [month, setMonth] = useState(1);
  const [year, setYear] = useState(1990);
  const [hasHistory, setHasHistory] = useState(null);

  const maxDays = (m, y) => {
    if (m === 2) {
      const isLeap = (y % 4 === 0 && y % 100 !== 0) || y % 400 === 0;
      return isLeap ? 29 : 28;
    }
    if ([4, 6, 9, 11].includes(m)) return 30;
    return 31;
  };

  const handleDayChange = (delta) => {
    const limit = maxDays(month, year);
    setDay((prev) => {
      const next = prev + delta;
      if (next < 1) return limit;
      if (next > limit) return 1;
      return next;
    });
  };

  const handleMonthChange = (delta) => {
    setMonth((prev) => {
      let next = prev + delta;
      if (next < 1) next = 12;
      if (next > 12) next = 1;
      const limit = maxDays(next, year);
      if (day > limit) setDay(limit);
      return next;
    });
  };

  const handleYearChange = (delta) => {
    const currentYear = new Date().getFullYear();
    setYear((prev) => {
      const next = prev + delta;
      return Math.max(1920, Math.min(currentYear, next));
    });
  };

  const handleStep1Next = () => {
    if (gender) setStep(2);
  };

  const handleStep2Next = () => {
    setStep(3);
  };

  const handleStep3Next = () => {
    if (hasHistory === null) return;
    completeScreening({
      gender,
      birthDate: `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`,
      hasHistory,
      completedAt: new Date().toISOString(),
    });
    setStep(4);
    setTimeout(() => {
      navigate('/beranda', { replace: true });
    }, 2200);
  };

  return (
    <div className="fixed inset-0 flex items-center justify-center bg-[#ECE7BE] select-none">
      {/* Mobile container on desktop */}
      <div className="relative w-full h-full sm:max-w-[420px] sm:max-h-[860px] sm:rounded-[36px] sm:border-[3px] sm:border-black/12 sm:shadow-2xl overflow-hidden flex flex-col bg-gradient-to-b from-[#FFF4A8] via-[#FAF4C8] to-[#FFFDE8]">
        {step < 4 ? (
          <div className="flex-1 flex flex-col justify-between p-6 pt-10">
            {/* Title Header */}
            <div>
              {step === 1 && (
                <h2 className="text-xl font-extrabold text-center text-[#1E5A74]">
                  Apa jenis kelamin Anda?
                </h2>
              )}
              {step === 2 && (
                <h2 className="text-xl font-extrabold text-center text-[#1E5A74]">
                  Kapan Tanggal Lahir Anda?
                </h2>
              )}
              {step === 3 && (
                <h2 className="text-xl font-extrabold text-center text-[#1E5A74] leading-snug">
                  Apakah Anda punya riwayat
                  <br />
                  penyakit lambung?
                </h2>
              )}
            </div>

            {/* Content Area */}
            <div className="my-auto w-full">
              {/* Step 1: Gender */}
              {step === 1 && (
                <div className="space-y-4">
                  <button
                    type="button"
                    onClick={() => setGender('Pria')}
                    className={`w-full flex items-center justify-between p-4 rounded-2xl border transition-all ${
                      gender === 'Pria'
                        ? 'bg-[#DCEDF7] border-[#5B95AF] shadow-md'
                        : 'bg-white border-slate-200 hover:bg-slate-50'
                    }`}
                  >
                    <div className="flex items-center gap-3.5">
                      <div className="w-11 h-11 rounded-full bg-[#FFECC8] border border-[#E2B483] flex items-center justify-center overflow-hidden">
                        <span className="text-2xl" role="img" aria-label="boy">👦</span>
                      </div>
                      <span className="text-base font-bold text-[#153E54]">Pria</span>
                    </div>
                    {gender === 'Pria' && (
                      <div className="w-6 h-6 rounded-full bg-[#276F8F] flex items-center justify-center text-white">
                        <Check size={16} strokeWidth={3} />
                      </div>
                    )}
                  </button>

                  <button
                    type="button"
                    onClick={() => setGender('Wanita')}
                    className={`w-full flex items-center justify-between p-4 rounded-2xl border transition-all ${
                      gender === 'Wanita'
                        ? 'bg-[#DCEDF7] border-[#5B95AF] shadow-md'
                        : 'bg-white border-slate-200 hover:bg-slate-50'
                    }`}
                  >
                    <div className="flex items-center gap-3.5">
                      <div className="w-11 h-11 rounded-full bg-[#FFE8E8] border border-[#E4AEAE] flex items-center justify-center overflow-hidden">
                        <span className="text-2xl" role="img" aria-label="girl">👧</span>
                      </div>
                      <span className="text-base font-bold text-[#153E54]">Wanita</span>
                    </div>
                    {gender === 'Wanita' && (
                      <div className="w-6 h-6 rounded-full bg-[#276F8F] flex items-center justify-center text-white">
                        <Check size={16} strokeWidth={3} />
                      </div>
                    )}
                  </button>
                </div>
              )}

              {/* Step 2: Birthdate */}
              {step === 2 && (
                <div className="flex items-center justify-center gap-2.5">
                  {/* Tanggal */}
                  <div className="flex flex-col items-center">
                    <span className="text-xs font-semibold text-slate-500 mb-2">Tanggal</span>
                    <div className="flex items-center bg-white rounded-xl border border-slate-200 px-1 py-1.5 shadow-sm">
                      <button
                        type="button"
                        onClick={() => handleDayChange(-1)}
                        className="p-1 hover:bg-slate-100 rounded text-slate-600"
                      >
                        <ChevronLeft size={18} />
                      </button>
                      <span className="w-8 text-center font-bold text-slate-800 text-sm">
                        {String(day).padStart(2, '0')}
                      </span>
                      <button
                        type="button"
                        onClick={() => handleDayChange(1)}
                        className="p-1 hover:bg-slate-100 rounded text-slate-600"
                      >
                        <ChevronRight size={18} />
                      </button>
                    </div>
                  </div>

                  {/* Bulan */}
                  <div className="flex flex-col items-center">
                    <span className="text-xs font-semibold text-slate-500 mb-2">Bulan</span>
                    <div className="flex items-center bg-white rounded-xl border border-slate-200 px-1 py-1.5 shadow-sm">
                      <button
                        type="button"
                        onClick={() => handleMonthChange(-1)}
                        className="p-1 hover:bg-slate-100 rounded text-slate-600"
                      >
                        <ChevronLeft size={18} />
                      </button>
                      <span className="w-8 text-center font-bold text-slate-800 text-sm">
                        {String(month).padStart(2, '0')}
                      </span>
                      <button
                        type="button"
                        onClick={() => handleMonthChange(1)}
                        className="p-1 hover:bg-slate-100 rounded text-slate-600"
                      >
                        <ChevronRight size={18} />
                      </button>
                    </div>
                  </div>

                  {/* Tahun */}
                  <div className="flex flex-col items-center">
                    <span className="text-xs font-semibold text-slate-500 mb-2">Tahun</span>
                    <div className="flex items-center bg-white rounded-xl border border-slate-200 px-1 py-1.5 shadow-sm">
                      <button
                        type="button"
                        onClick={() => handleYearChange(-1)}
                        className="p-1 hover:bg-slate-100 rounded text-slate-600"
                      >
                        <ChevronLeft size={18} />
                      </button>
                      <span className="w-12 text-center font-bold text-slate-800 text-sm">
                        {year}
                      </span>
                      <button
                        type="button"
                        onClick={() => handleYearChange(1)}
                        className="p-1 hover:bg-slate-100 rounded text-slate-600"
                      >
                        <ChevronRight size={18} />
                      </button>
                    </div>
                  </div>
                </div>
              )}

              {/* Step 3: History */}
              {step === 3 && (
                <div className="space-y-4">
                  <button
                    type="button"
                    onClick={() => setHasHistory(true)}
                    className={`w-full flex items-center justify-between p-4 rounded-2xl border transition-all ${
                      hasHistory === true
                        ? 'bg-[#DCEDF7] border-[#5B95AF] shadow-md'
                        : 'bg-white border-slate-200 hover:bg-slate-50'
                    }`}
                  >
                    <div className="flex items-center gap-3.5">
                      <div className="w-11 h-11 rounded-full bg-[#E0F2FE] border border-[#7DD3FC] flex items-center justify-center overflow-hidden">
                        <span className="text-2xl" role="img" aria-label="doctor">👨‍⚕️</span>
                      </div>
                      <span className="text-base font-bold text-[#153E54]">Iya</span>
                    </div>
                    {hasHistory === true && (
                      <div className="w-6 h-6 rounded-full bg-[#276F8F] flex items-center justify-center text-white">
                        <Check size={16} strokeWidth={3} />
                      </div>
                    )}
                  </button>

                  <button
                    type="button"
                    onClick={() => setHasHistory(false)}
                    className={`w-full flex items-center justify-between p-4 rounded-2xl border transition-all ${
                      hasHistory === false
                        ? 'bg-[#DCEDF7] border-[#5B95AF] shadow-md'
                        : 'bg-white border-slate-200 hover:bg-slate-50'
                    }`}
                  >
                    <div className="flex items-center gap-3.5">
                      <div className="w-11 h-11 rounded-full bg-[#F3E8FF] border border-[#D8B4FE] flex items-center justify-center overflow-hidden">
                        <span className="text-2xl" role="img" aria-label="person">🙋</span>
                      </div>
                      <span className="text-base font-bold text-[#153E54]">Tidak</span>
                    </div>
                    {hasHistory === false && (
                      <div className="w-6 h-6 rounded-full bg-[#276F8F] flex items-center justify-center text-white">
                        <Check size={16} strokeWidth={3} />
                      </div>
                    )}
                  </button>
                </div>
              )}
            </div>

            {/* Bottom Section */}
            <div className="w-full space-y-3 pt-4">
              <p className="text-[11px] text-center text-[#5D7B8C] font-medium leading-tight">
                Kami tidak akan pernah menjual atau membagikan data pribadi Anda secara tidak tepat.
              </p>

              {step === 1 && (
                <button
                  type="button"
                  disabled={!gender}
                  onClick={handleStep1Next}
                  className="w-full h-12 bg-[#276F8F] hover:bg-[#1E5A74] disabled:opacity-50 text-white font-bold rounded-2xl transition-all shadow-sm"
                >
                  Berikutnya
                </button>
              )}

              {step === 2 && (
                <button
                  type="button"
                  onClick={handleStep2Next}
                  className="w-full h-12 bg-[#276F8F] hover:bg-[#1E5A74] text-white font-bold rounded-2xl transition-all shadow-sm"
                >
                  Berikutnya
                </button>
              )}

              {step === 3 && (
                <button
                  type="button"
                  disabled={hasHistory === null}
                  onClick={handleStep3Next}
                  className="w-full h-12 bg-[#276F8F] hover:bg-[#1E5A74] disabled:opacity-50 text-white font-bold rounded-2xl transition-all shadow-sm"
                >
                  Berikutnya
                </button>
              )}
            </div>
          </div>
        ) : (
          /* Step 4: Success */
          <div className="flex-1 flex flex-col items-center justify-center p-6 text-center animate-fadeIn">
            {/* 3D Green sphere checkmark badge */}
            <div
              className="w-32 h-32 rounded-full flex items-center justify-center shadow-xl mb-7"
              style={{
                background: 'radial-gradient(circle at 35% 30%, #8CE93D 0%, #58C822 45%, #389F12 80%, #267509 100%)',
                boxShadow: '0 12px 28px rgba(53, 148, 16, 0.45)',
              }}
            >
              <Check size={64} color="white" strokeWidth={3.5} />
            </div>

            <h2 className="text-2xl font-black text-[#389F12] tracking-wider leading-snug">
              SKRINING
              <br />
              BERHASIL
            </h2>
          </div>
        )}
      </div>
    </div>
  );
}
