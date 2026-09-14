import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import LoginPage from './pages/LoginPage';
import GoogleAuthPage from './pages/GoogleAuthPage';
import RegisterPage from './pages/RegisterPage';
import BerandaPage from './pages/BerandaPage';
import PlaceholderPage from './pages/PlaceholderPage';
import { MAIN_MENUS, INFO_MENUS, NAV_MENUS } from './routes/menuRoutes';

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* Default Route */}
          <Route path="/" element={<Navigate to="/login" replace />} />

          {/* Autentikasi */}
          <Route path="/login" element={<LoginPage />} />
          <Route path="/google-auth" element={<GoogleAuthPage />} />
          <Route path="/register" element={<RegisterPage />} />

          {/* Halaman Utama */}
          <Route path="/beranda" element={<BerandaPage />} />

          {/* 
            RUTE FLEKSIBEL & MODULAR UNTUK FITUR MENDATANG
            Semua rute menu berikut sudah siap menerima komponen halaman baru
            begitu desain Figma-nya selesai dibuat oleh tim Anda.
          */}
          {MAIN_MENUS.map((menu) => (
            <Route
              key={menu.id}
              path={menu.path}
              element={
                <PlaceholderPage
                  title={menu.shortTitle}
                  description={menu.description}
                />
              }
            />
          ))}

          {INFO_MENUS.map((info) => (
            <Route
              key={info.id}
              path={info.path}
              element={
                <PlaceholderPage
                  title={info.title}
                  description={info.description}
                />
              }
            />
          ))}

          {NAV_MENUS.filter((nav) => nav.path !== '/beranda').map((nav) => (
            <Route
              key={nav.id}
              path={nav.path}
              element={
                <PlaceholderPage
                  title={nav.title}
                  description={`Halaman ${nav.title} akan segera hadir sesuai spesifikasi antarmuka berikutnya.`}
                />
              }
            />
          ))}

          {/* Fallback 404 */}
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
