import React, { useEffect, useRef, useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import lamonLogo from '../assets/lamon-logo.png';

/**
 * SplashPage — Animasi pembuka LAMON sebelum halaman Login.
 *
 * Urutan fase (Total ±13 detik):
 *   1. logo-slide  → Logo meluncur masuk dari atas layar ke tengah (1.8s + 0.3s)
 *   2. logo-scale  → Logo membesar (scale-up 1.0 → 1.35) di tengah sebagai penekanan (1.2s + 1.0s hold)
 *   3. logo-exit   → Logo memudar keluar (exit) tuntas sebelum teks muncul (0.8s + 0.3s)
 *   4. scramble    → Teks "LAMON" scramble-in berurutan setelah logo selesai (2.5s + 0.8s hold)
 *   5. subtitle    → Subtitle fade-in & slide-in di bawah teks LAMON (1.0s + 1.2s hold)
 *   6. welcome     → Crossfade ke teks "WELCOME" (hitam, bold) (0.8s + 1.6s hold)
 *   7. done        → Navigate ke /login (bisa klik/tap kapan saja untuk lewati)
 */

const TARGET = 'LAMON';
const CHARSET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

function randomChar() {
  return CHARSET[Math.floor(Math.random() * CHARSET.length)];
}

function scramble(progress) {
  const settled = Math.round(progress * TARGET.length);
  return TARGET.split('').map((ch, i) =>
    i < settled ? ch : randomChar()
  ).join('');
}

export default function SplashPage() {
  const navigate = useNavigate();
  // 'logo-slide' | 'logo-scale' | 'logo-exit' | 'scramble' | 'subtitle' | 'welcome' | 'done'
  const [phase, setPhase] = useState('logo-slide');
  const [scrambleText, setScrambleText] = useState(TARGET);
  const rafRef = useRef(null);
  const startRef = useRef(null);
  const navigatedRef = useRef(false);

  // Tap/click anywhere to skip
  const skip = useCallback(() => {
    if (navigatedRef.current) return;
    navigatedRef.current = true;
    if (rafRef.current) cancelAnimationFrame(rafRef.current);
    navigate('/login', { replace: true });
  }, [navigate]);

  useEffect(() => {
    let cancelled = false;
    const delay = (ms) => new Promise((res) => setTimeout(res, ms));

    async function run() {
      // ── Tahap 1: Logo meluncur dari luar batas atas ke tengah (1.8s + 0.3s)
      setPhase('logo-slide');
      await delay(2100);
      if (cancelled) return;

      // ── Tahap 2: Logo membesar di tengah sebagai penekanan (1.2s + 1.0s hold)
      setPhase('logo-scale');
      await delay(2200);
      if (cancelled) return;

      // ── Tahap 3: Logo fade-out keluar tuntas sebelum teks dimulai (0.8s + 0.3s)
      setPhase('logo-exit');
      await delay(1100);
      if (cancelled) return;

      // ── Tahap 4: Text scramble LAMON (2.5s)
      setPhase('scramble');
      await new Promise((resolve) => {
        const duration = 2500;
        startRef.current = performance.now();

        function tick(now) {
          if (cancelled) return resolve();
          const elapsed = now - startRef.current;
          const progress = Math.min(elapsed / duration, 1);
          setScrambleText(scramble(progress));
          if (progress < 1) {
            rafRef.current = requestAnimationFrame(tick);
          } else {
            setScrambleText(TARGET);
            resolve();
          }
        }
        rafRef.current = requestAnimationFrame(tick);
      });

      if (cancelled) return;
      await delay(800); // Hold setelah teks terkunci
      if (cancelled) return;

      // ── Tahap 5: Subtitle fade-in berurutan (1.0s + 1.2s hold)
      setPhase('subtitle');
      await delay(2200);
      if (cancelled) return;

      // ── Tahap 6: WELCOME crossfade (0.8s + 1.6s hold)
      setPhase('welcome');
      await delay(2400);
      if (cancelled) return;

      // ── Selesai: Masuk ke login
      if (!navigatedRef.current) {
        navigatedRef.current = true;
        navigate('/login', { replace: true });
      }
    }

    run();

    return () => {
      cancelled = true;
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
    };
  }, [navigate]);

  // ── Visual state calculation ─────────────────────────────────────────────
  const isLogoVisible = phase === 'logo-slide' || phase === 'logo-scale' || phase === 'logo-exit';
  const showTextPhase = phase === 'scramble' || phase === 'subtitle' || phase === 'welcome';
  const showSubtitle = phase === 'subtitle' || phase === 'welcome';
  const showWelcome = phase === 'welcome';

  // Logo transform & opacity styling
  let logoTransform = 'translateY(-220%) scale(1)';
  let logoOpacity = 0;
  let logoTransition = 'transform 1.8s cubic-bezier(0.22, 1, 0.36, 1), opacity 0.6s ease-out';

  if (phase === 'logo-slide') {
    // Settling at center
    logoTransform = 'translateY(0) scale(1)';
    logoOpacity = 1;
    logoTransition = 'transform 1.8s cubic-bezier(0.22, 1, 0.36, 1), opacity 0.6s ease-out';
  } else if (phase === 'logo-scale') {
    // Enlarged for emphasis
    logoTransform = 'translateY(0) scale(1.35)';
    logoOpacity = 1;
    logoTransition = 'transform 1.2s cubic-bezier(0.34, 1.56, 0.64, 1), opacity 0.3s ease-out';
  } else if (phase === 'logo-exit') {
    // Exiting
    logoTransform = 'translateY(0) scale(1.15)';
    logoOpacity = 0;
    logoTransition = 'transform 0.8s ease-in, opacity 0.8s ease-in';
  }

  return (
    <div
      onClick={skip}
      style={{ cursor: 'default' }}
      className="fixed inset-0 flex items-center justify-center overflow-hidden select-none"
    >
      {/* ── Base gradient background (kuning khas LAMON) ── */}
      <div
        className="absolute inset-0"
        style={{
          background: 'linear-gradient(to bottom, #FFF4A8, #FAF4C8, #FFFDE8)',
        }}
      />

      {/* ── TAHAP 1-2-3: LOGO ANIMASI ── */}
      {isLogoVisible && (
        <div
          className="absolute flex items-center justify-center pointer-events-none"
          style={{
            transform: logoTransform,
            opacity: logoOpacity,
            transition: logoTransition,
          }}
        >
          <img
            src={lamonLogo}
            alt="Logo LAMON"
            style={{ width: 150, height: 150, objectFit: 'contain' }}
          />
        </div>
      )}

      {/* ── TAHAP 4 & 5: LAMON SCRAMBLE & SUBTITLE (setelah logo tuntas) ── */}
      {showTextPhase && (
        <div className="absolute flex flex-col items-center gap-3.5 pointer-events-none">
          {/* Main LAMON scramble text (tanpa garis kuning/underline) */}
          <span
            style={{
              fontSize: 52,
              fontWeight: 900,
              color: '#B8630A',
              letterSpacing: 10,
              lineHeight: 1,
              opacity: showWelcome ? 0 : 1,
              transition: showWelcome ? 'opacity 0.5s ease-in' : 'opacity 0.4s ease-out',
              fontFamily: 'inherit',
              textDecoration: 'none',
              border: 'none',
            }}
          >
            {scrambleText}
          </span>

          {/* Subtitle "LAMBUNG AWARENESS & MONITORING" (tanpa garis) */}
          <span
            style={{
              fontSize: 11,
              fontWeight: 700,
              color: '#B8630A',
              letterSpacing: '0.24em',
              lineHeight: 1,
              textTransform: 'uppercase',
              opacity: showSubtitle && !showWelcome ? 1 : 0,
              transform: showSubtitle && !showWelcome ? 'translateY(0)' : 'translateY(8px)',
              transition: showWelcome
                ? 'opacity 0.5s ease-in'
                : 'opacity 0.8s ease-out, transform 0.8s ease-out',
              textAlign: 'center',
              textDecoration: 'none',
              border: 'none',
            }}
          >
            LAMBUNG AWARENESS &amp; MONITORING
          </span>
        </div>
      )}

      {/* ── TAHAP 6: WELCOME text (tanpa garis) ── */}
      <div
        className="absolute flex items-center justify-center pointer-events-none"
        style={{
          opacity: showWelcome ? 1 : 0,
          transform: showWelcome ? 'scale(1)' : 'scale(0.95)',
          transition: 'opacity 0.6s ease-out, transform 0.6s ease-out',
        }}
      >
        <span
          style={{
            fontSize: 42,
            fontWeight: 900,
            color: 'rgba(0,0,0,0.88)',
            letterSpacing: '0.18em',
            textDecoration: 'none',
            border: 'none',
          }}
        >
          WELCOME
        </span>
      </div>
    </div>
  );
}
