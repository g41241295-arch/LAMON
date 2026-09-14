import React from 'react';
import { useNavigate } from 'react-router-dom';
import { UserPlus, ArrowLeft } from 'lucide-react';
import AppLayout from '../components/AppLayout';
import { useAuth } from '../context/AuthContext';
import lamonLogo from '../assets/lamon-logo.png';

export default function GoogleAuthPage() {
  const navigate = useNavigate();
  const { loginWithGoogle } = useAuth();

  const googleAccounts = [
    {
      id: 1,
      name: 'Hanabi',
      email: 'Hanabi00@gmail.com',
      avatarInitial: 'H',
    },
    {
      id: 2,
      name: 'Hanabi',
      email: 'h4nab1@gmail.com',
      avatarInitial: 'H',
    },
  ];

  const handleSelectAccount = (account) => {
    loginWithGoogle(account);
    navigate('/beranda');
  };

  const handleAddAccount = () => {
    const customEmail = window.prompt('Masukkan email Google baru:', 'user.baru@gmail.com');
    if (customEmail) {
      const name = customEmail.split('@')[0];
      const capitalized = name.charAt(0).toUpperCase() + name.slice(1);
      loginWithGoogle({ name: capitalized, email: customEmail });
      navigate('/beranda');
    }
  };

  return (
    <AppLayout className="justify-center px-6 py-8">
      {/* Back button */}
      <div className="w-full flex items-center justify-between mb-4">
        <button
          onClick={() => navigate('/login')}
          className="p-2 -ml-2 text-[#1C4E68] hover:bg-black/5 rounded-full transition-colors flex items-center gap-1 font-bold text-lg cursor-pointer"
        >
          <ArrowLeft className="w-6 h-6" />
          <span>Kembali</span>
        </button>
      </div>

      {/* Main Google Auth Card */}
      <div className="w-full bg-white rounded-[32px] p-7 shadow-md border border-[#F0E6CA]/60 flex flex-col items-center my-auto">
        {/* Mascot Logo */}
        <div className="w-28 h-28 mb-3 relative flex items-center justify-center">
          <img
            src={lamonLogo}
            alt="Logo LAMON"
            className="w-full h-full object-contain filter drop-shadow-sm"
          />
        </div>

        {/* Title & Subtitle */}
        <h2 className="text-3xl font-extrabold text-[#276F8F] text-center leading-tight">
          Pilih Akun
        </h2>
        <p className="text-xl font-bold text-[#276F8F] text-center mb-6 leading-tight">
          Untuk Melanjutkan ke LAMON
        </p>

        {/* Account List */}
        <div className="w-full space-y-1">
          {googleAccounts.map((account) => (
            <div key={account.id}>
              <button
                onClick={() => handleSelectAccount(account)}
                className="w-full py-3 px-2 flex items-center gap-3.5 hover:bg-gray-50 active:bg-gray-100 rounded-xl transition-colors cursor-pointer text-left"
              >
                {/* Gray Avatar Circle matching Figma */}
                <div className="w-11 h-11 rounded-full bg-[#CCCCCC] flex items-center justify-center text-gray-500 font-bold text-lg shrink-0" />
                <div className="flex flex-col overflow-hidden">
                  <span className="text-xl font-bold text-[#276F8F] leading-tight">
                    {account.name}
                  </span>
                  <span className="text-base font-medium text-[#5B89A0] leading-tight truncate">
                    {account.email}
                  </span>
                </div>
              </button>
              <div className="w-full border-b border-[#E3EDF2]" />
            </div>
          ))}

          {/* Add another account button */}
          <button
            onClick={handleAddAccount}
            className="w-full py-3.5 px-2 flex items-center gap-3.5 hover:bg-gray-50 active:bg-gray-100 rounded-xl transition-colors cursor-pointer text-left group"
          >
            <div className="w-11 h-11 flex items-center justify-center text-[#276F8F] shrink-0">
              <UserPlus className="w-6 h-6 stroke-[2.3]" />
            </div>
            <span className="text-xl font-bold text-[#276F8F] leading-tight">
              Tambahkan akun lain
            </span>
          </button>
        </div>

        {/* Google Privacy Policy Disclaimer */}
        <div className="w-full mt-8 pt-4">
          <p className="text-sm text-[#4A5568] leading-relaxed text-justify">
            Untuk melanjutkan, Google akan membagikan nama, alamat email, dan foto profil Anda ke LAMON. Sebelum menggunakan aplikasi ini, tinjau kebijakan privasi dan persyaratan layanan-nya
          </p>
        </div>
      </div>
    </AppLayout>
  );
}
