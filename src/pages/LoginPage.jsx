import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import AppLayout from '../components/AppLayout';
import InputField from '../components/InputField';
import PrimaryButton from '../components/PrimaryButton';
import { useAuth } from '../context/AuthContext';
import lamonLogo from '../assets/lamon-logo.png';

export default function LoginPage() {
  const navigate = useNavigate();
  const { loginWithEmail } = useAuth();

  const [formData, setFormData] = useState({
    email: '',
    password: '',
  });

  const [errors, setErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const validate = () => {
    const errs = {};
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!formData.email.trim()) {
      errs.email = 'Email tidak boleh kosong';
    } else if (!emailRegex.test(formData.email.trim())) {
      errs.email = 'Format email tidak valid (contoh: user@gmail.com)';
    }

    if (!formData.password) {
      errs.password = 'Kata sandi tidak boleh kosong';
    } else if (formData.password.length < 8) {
      errs.password = 'Kata sandi minimal harus 8 karakter';
    }

    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    // Clear error on edit
    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: '' }));
    }
  };

  const handleSubmit = (e) => {
    if (e) e.preventDefault();
    if (!validate()) return;

    setIsSubmitting(true);
    // Simulate brief login process
    setTimeout(() => {
      loginWithEmail(formData.email.trim(), formData.password);
      setIsSubmitting(false);
      navigate('/beranda');
    }, 250);
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
          Pemantauan Kesehatan Lambung
        </p>
      </div>

      {/* Main Login Card */}
      <div className="w-full bg-white rounded-[32px] p-6 shadow-md border border-[#F0E6CA]/60 my-auto">
        <div className="text-left mb-5">
          <h2 className="text-3xl font-extrabold text-[#276F8F] leading-tight">
            Selamat Datang
          </h2>
          <p className="text-base font-medium text-[#7C8E97] mt-0.5">
            Belum punya akun?{' '}
            <Link
              to="/register"
              className="text-[#E5983A] font-bold hover:underline transition-colors cursor-pointer"
            >
              Daftar Sekarang
            </Link>
          </p>
        </div>

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
            autoComplete="current-password"
            onKeyDown={handleKeyDown}
          />

          {/* Divider "Masuk dengan" */}
          <div className="relative flex py-2 items-center">
            <div className="flex-grow border-t border-[#C7D7E0]"></div>
            <span className="flex-shrink mx-3 text-sm font-semibold text-[#8DA6B5]">
              Masuk dengan
            </span>
            <div className="flex-grow border-t border-[#C7D7E0]"></div>
          </div>

          {/* Google Button */}
          <div className="flex justify-center">
            <button
              type="button"
              onClick={() => navigate('/google-auth')}
              aria-label="Masuk dengan Google"
              className="w-11 h-11 rounded-full flex items-center justify-center hover:bg-gray-50 active:scale-95 transition-all p-1.5 cursor-pointer shadow-xs border border-gray-100"
            >
              {/* Google Multicolor SVG */}
              <svg className="w-7 h-7" viewBox="0 0 24 24">
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
            </button>
          </div>

          {/* Submit Button */}
          <div className="pt-1">
            <PrimaryButton
              type="submit"
              disabled={isSubmitting}
              showArrow={true}
              className="py-3.5"
            >
              {isSubmitting ? 'Memproses...' : 'Masuk'}
            </PrimaryButton>
          </div>
        </form>
      </div>

      {/* Spacing / Footer balance */}
      <div className="h-4" />
    </AppLayout>
  );
}
