import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import AppLayout from '../components/AppLayout';
import InputField from '../components/InputField';
import PrimaryButton from '../components/PrimaryButton';
import { useAuth } from '../context/AuthContext';
import lamonLogo from '../assets/lamon-logo.png';

export default function RegisterPage() {
  const navigate = useNavigate();
  const { registerWithEmail } = useAuth();

  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
  });

  const [errors, setErrors] = useState({});
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
  };

  const handleSubmit = (e) => {
    if (e) e.preventDefault();
    if (!validate()) return;

    setIsSubmitting(true);
    setTimeout(() => {
      registerWithEmail(formData.email.trim(), formData.password);
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

          {/* Submit Button */}
          <div className="pt-3">
            <PrimaryButton
              type="submit"
              disabled={isSubmitting}
              className="py-3.5"
            >
              {isSubmitting ? 'Mendaftarkan...' : 'Daftar'}
            </PrimaryButton>
          </div>
        </form>
      </div>

      {/* Spacing / Footer balance */}
      <div className="h-4" />
    </AppLayout>
  );
}
