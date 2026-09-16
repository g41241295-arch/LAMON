import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import AppLayout from '../components/AppLayout';
import InputField from '../components/InputField';
import PrimaryButton from '../components/PrimaryButton';
import { useAuth } from '../context/AuthContext';
import lamonLogo from '../assets/lamon-logo.png';

export default function RegisterPage() {
  const navigate = useNavigate();
  const { registerWithEmail, isEmailRegistered } = useAuth();

  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
  });

  const [errors, setErrors] = useState({});
  const [globalError, setGlobalError] = useState(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const validate = () => {
    const errs = {};
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!formData.email.trim()) {
      errs.email = 'Email tidak boleh kosong';
    } else if (!emailRegex.test(formData.email.trim())) {
      errs.email = 'Format email tidak valid (contoh: nama@gmail.com)';
    }

    if (!formData.password) {
      errs.password = 'Kata sandi tidak boleh kosong';
    } else if (formData.password.length < 8) {
      errs.password = 'Kata sandi minimal harus 8 karakter';
    }

    if (!formData.confirmPassword) {
      errs.confirmPassword = 'Konfirmasi kata sandi tidak boleh kosong';
    } else if (formData.confirmPassword !== formData.password) {
      errs.confirmPassword = 'Konfirmasi kata sandi tidak cocok';
    }

    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: '' }));
    }
    if (globalError) {
      setGlobalError(null);
    }
  };

  const handleSubmit = (e) => {
    if (e) e.preventDefault();
    setGlobalError(null);

    if (!validate()) return;

    setIsSubmitting(true);

    setTimeout(() => {
      const email = formData.email.trim();
      const password = formData.password;

      // Check if already registered
      if (isEmailRegistered(email)) {
        setIsSubmitting(false);
        setErrors((prev) => ({
          ...prev,
          email: 'Email ini sudah terdaftar. Silakan masuk.',
        }));
        setGlobalError('Email sudah terdaftar. Silakan masuk menggunakan akun Anda.');
        return;
      }

      registerWithEmail(email, password);
      setIsSubmitting(false);
      navigate('/screening');
    }, 300);
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter') {
      handleSubmit();
    }
  };

  return (
    <AppLayout className="justify-between px-6 pt-8 pb-8">
      {/* Brand Header */}
      <div className="flex flex-col items-center text-center">
        {/* Logo LAMON */}
        <div className="w-32 h-32 mb-2 relative flex items-center justify-center">
          <img
            src={lamonLogo}
            alt="Logo LAMON"
            className="w-full h-full object-contain filter drop-shadow-sm"
          />
        </div>

        {/* Title & Subtitle */}
        <h1 className="text-3xl font-extrabold text-[#276F8F] tracking-wide leading-none">
          LAMON
        </h1>
        <p className="text-lg font-medium text-[#5B95AF] mt-0.5 tracking-tight">
          Lambung Awareness &amp; MONitoring
        </p>
      </div>

      {/* Main Register Card */}
      <div className="w-full bg-white rounded-[32px] p-6 shadow-md border border-[#F0E6CA]/60 my-auto">
        <div className="text-left mb-5">
          <h2 className="text-3xl font-extrabold text-[#276F8F] leading-tight">
            Buat akun Anda
          </h2>
          <p className="text-base font-medium text-[#7C8E97] mt-0.5">
            Sudah punya akun?{' '}
            <Link
              to="/login"
              className="text-[#E5983A] font-bold hover:underline transition-colors cursor-pointer"
            >
              Masuk
            </Link>
          </p>
        </div>

        {/* Global Error Banner */}
        {globalError && (
          <div className="mb-4 p-3.5 bg-red-50 border border-red-200 rounded-2xl flex items-start gap-3 text-red-700 animate-fadeIn">
            <svg
              className="w-5 h-5 flex-shrink-0 mt-0.5 text-red-500"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <circle cx="12" cy="12" r="10" strokeWidth="2" />
              <path strokeWidth="2" strokeLinecap="round" d="M12 8v4m0 4h.01" />
            </svg>
            <div className="flex-1 text-sm font-semibold leading-snug">
              <span>{globalError}</span>
              <div className="mt-1">
                <Link
                  to="/login"
                  className="inline-block text-xs font-bold text-[#E5983A] bg-amber-50 px-2.5 py-1 rounded-lg border border-amber-200 hover:bg-amber-100 transition-colors"
                >
                  Masuk Sekarang &rarr;
                </Link>
              </div>
            </div>
          </div>
        )}

        <form onSubmit={handleSubmit} noValidate className="space-y-4">
          {/* Email Input */}
          <InputField
            label="Email"
            name="email"
            type="email"
            value={formData.email}
            onChange={handleChange}
            placeholder="Masukkan email Anda"
            error={errors.email}
            autoComplete="email"
            inputMode="email"
          />

          {/* Kata Sandi Input */}
          <InputField
            label="Kata Sandi"
            name="password"
            type="password"
            value={formData.password}
            onChange={handleChange}
            placeholder="Masukkan kata sandi Anda"
            error={errors.password}
            autoComplete="new-password"
          />

          {/* Konfirmasi Kata Sandi Input */}
          <InputField
            label="Konfirmasi Kata Sandi"
            name="confirmPassword"
            type="password"
            value={formData.confirmPassword}
            onChange={handleChange}
            placeholder="Konfirmasi kata sandi Anda"
            error={errors.confirmPassword}
            autoComplete="new-password"
            onKeyDown={handleKeyDown}
          />

          {/* Submit Button (Daftar) */}
          <div className="pt-2">
            <PrimaryButton
              type="submit"
              disabled={isSubmitting}
              className="py-3.5"
            >
              {isSubmitting ? 'Mendaftarkan...' : 'Daftar'}
            </PrimaryButton>
          </div>

          {/* Divider "atau" */}
          <div className="relative flex py-1 items-center">
            <div className="flex-grow border-t border-[#C7D7E0]"></div>
            <span className="flex-shrink mx-3 text-sm font-semibold text-[#8DA6B5]">
              atau
            </span>
            <div className="flex-grow border-t border-[#C7D7E0]"></div>
          </div>

          {/* Google Pill Button (persis di bawah tombol Daftar) */}
          <button
            type="button"
            onClick={() => navigate('/google-auth')}
            aria-label="Daftar dengan Google"
            className="w-full flex items-center justify-center gap-2.5 px-4 py-3 rounded-2xl bg-white border border-gray-200 shadow-xs hover:bg-gray-50 active:scale-[0.98] transition-all cursor-pointer"
          >
            <svg className="w-5 h-5 flex-shrink-0" viewBox="0 0 24 24">
              <path
                fill="#4285F4"
                d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.82-2.4 3.68v3.05h3.88c2.27-2.09 3.665-5.17 3.665-9.17z"
              />
              <path
                fill="#34A853"
                d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.26 21.36 7.33 24 12 24z"
              />
              <path
                fill="#FBBC05"
                d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.14-1.55.38-2.27V6.58H1.25C.45 8.18 0 9.99 0 12s.45 3.82 1.25 5.42l4.03-3.15z"
              />
              <path
                fill="#EA4335"
                d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.33 0 3.26 2.64 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98z"
              />
            </svg>
            <span className="text-[15px] font-semibold text-[#3C4043] tracking-[0.01em]">
              Daftar dengan Google
            </span>
          </button>
        </form>
      </div>

      {/* Spacing / Footer balance */}
      <div className="h-4" />
    </AppLayout>
  );
}
