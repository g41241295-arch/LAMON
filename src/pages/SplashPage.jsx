import React, { useEffect, useRef, useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import lamonLogo from '../assets/lamon-logo.png';

/**
 * SplashPage — Animasi pembuka LAMON 8 Frame berurutan (Total ±13 detik).
 *
 * Frame 1 (0.0s – 1.1s)  : Halaman kosong background gradient kuning lembut.
 * Frame 2 (1.1s – 3.8s)  : Logo meluncur turun dari atas ke tengah + circular halo (tanpa frame kotak).
 * Frame 3 (3.8s – 4.9s)  : Logo zoom dramatis (scale 1.0 -> 3.8x) + crossfade ke oranye pekat solid.
 * Frame 4 (4.9s – 6.2s)  : Teks "NOMAL" muncul warna oranye tua/gelap di tengah.
 * Frame 5 (6.2s – 7.3s)  : Transisi cepat per-huruf "NOMAL" -> "OMALN" efek flip digital 3D.
 * Frame 6 (7.3s – 8.4s)  : Transisi cepat per-huruf "OMALN" -> "LAMON" efek flip digital 3D.
 * Frame 7 (8.4s – 10.5s) : Subtitle "LAMBUNG AWARENESS & MONITORING" fade-in di bawah "LAMON".
 * Frame 8 (10.5s – 12.8s): Crossfade ke teks "WELCOME" (hitam, bold, tanpa logo, tanpa underline).
 * Selesai                : Transisi halus ke /login.
 */

export default function SplashPage() {
  const navigate = useNavigate();
  // frame: 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8
  const [frame, setFrame] = useState(1);
  const [flipOmalnProgress, setFlipOmalnProgress] = useState(0);
  const [flipLamonProgress, setFlipLamonProgress] = useState(0);
  const navigatedRef = useRef(false);

  const skip = useCallback(() => {
    if (navigatedRef.current) return;
    navigatedRef.current = true;
    navigate('/login', { replace: true });
  }, [navigate]);

  useEffect(() => {
    let cancelled = false;
    const delay = (ms) => new Promise((res) => setTimeout(res, ms));

    async function runSequence() {
      // Frame 1: Halaman kosong kuning lembut (1.1s)
      setFrame(1);
      await delay(1100);
      if (cancelled) return;

      // Frame 2: Logo meluncur turun ke tengah + halo glow (2.7s)
      setFrame(2);
      await delay(2700);
      if (cancelled) return;

      // Frame 3: Logo zoom dramatis & background oranye (1.1s)
      setFrame(3);
      await delay(1100);
      if (cancelled) return;

      // Frame 4: Teks "NOMAL" muncul (1.3s)
      setFrame(4);
      await delay(1300);
      if (cancelled) return;

      // Frame 5: Flip per-huruf "NOMAL" -> "OMALN" (1.1s)
      setFrame(5);
      const startFlip1 = performance.now();
      await new Promise((resolve) => {
        function tick1(now) {
          if (cancelled) return resolve();
          const p = Math.min((now - startFlip1) / 900, 1);
          setFlipOmalnProgress(p);
          if (p < 1) requestAnimationFrame(tick1);
          else resolve();
        }
        requestAnimationFrame(tick1);
      });
      await delay(300);
      if (cancelled) return;

      // Frame 6: Flip per-huruf "OMALN" -> "LAMON" (1.1s)
      setFrame(6);
      const startFlip2 = performance.now();
      await new Promise((resolve) => {
        function tick2(now) {
          if (cancelled) return resolve();
          const p = Math.min((now - startFlip2) / 900, 1);
          setFlipLamonProgress(p);
          if (p < 1) requestAnimationFrame(tick2);
          else resolve();
        }
        requestAnimationFrame(tick2);
      });
      await delay(300);
      if (cancelled) return;

      // Frame 7: Subtitle muncul di bawah LAMON (2.1s)
      setFrame(7);
      await delay(2100);
      if (cancelled) return;

      // Frame 8: WELCOME (2.3s)
      setFrame(8);
      await delay(2300);
      if (cancelled) return;

      // Selesai -> masuk login
      skip();
    }

    runSequence();

    return () => {
      cancelled = true;
    };
  }, [skip]);

  // Status visual
  const showLogo = frame === 2 || frame === 3;
  const isLogoZooming = frame === 3;
  const showOrangeBg = frame === 3;
  const showWordPhase = frame >= 4 && frame <= 7;
  const showSubtitle = frame >= 7 && frame <= 7;
  const showWelcome = frame === 8;

  // Render flip characters
  const renderWord = () => {
    const w1 = 'NOMAL';
    const w2 = 'OMALN';
    const w3 = 'LAMON';

    return (
      <div className="flex items-center justify-center gap-2">
        {[0, 1, 2, 3, 4].map((i) => {
          let fromChar = w1[i];
          let toChar = w1[i];
          let p = 0;

          if (frame === 6 || frame === 7) {
            fromChar = w2[i];
            toChar = w3[i];
            const start = Math.min(i * 0.08, 0.4);
            const end = Math.min(start + 0.6, 1.0);
            p = Math.max(0, Math.min((flipLamonProgress - start) / (end - start), 1));
          } else if (frame === 5) {
            fromChar = w1[i];
            toChar = w2[i];
            const start = Math.min(i * 0.08, 0.4);
            const end = Math.min(start + 0.6, 1.0);
            p = Math.max(0, Math.min((flipOmalnProgress - start) / (end - start), 1));
          }

          const isFirstHalf = p < 0.5;
          const displayChar = isFirstHalf ? fromChar : toChar;
          const angle = isFirstHalf ? -p * 180 : (1 - p) * 180;

          return (
            <div
              key={i}
              style={{
                perspective: '400px',
              }}
            >
              <span
                style={{
                  display: 'inline-block',
                  transform: p > 0 && p < 1 ? `rotateX(${angle}deg)` : 'none',
                  fontSize: '52px',
                  fontWeight: 900,
                  color: '#B8630A',
                  lineHeight: 1,
                  fontFamily: 'inherit',
                  textDecoration: 'none',
                  border: 'none',
                  letterSpacing: '2px',
                }}
              >
                {displayChar}
              </span>
            </div>
          );
        })}
      </div>
    );
  };

  return (
    <div
      onClick={skip}
      className="fixed inset-0 flex items-center justify-center overflow-hidden select-none cursor-pointer"
    >
      {/* ── Background Kuning Khas LAMON ── */}
      <div
        className="absolute inset-0"
        style={{
          background: 'linear-gradient(to bottom, #FFF4A8, #FAF4C8, #FFFDE8)',
        }}
      />

      {/* ── Background Oranye Solid Transition (Frame 3) ── */}
      <div
        className="absolute inset-0 transition-opacity duration-700 pointer-events-none"
        style={{
          backgroundColor: '#FFA827',
          opacity: showOrangeBg ? 1 : 0,
        }}
      />

      {/* ── FRAME 2 & 3: LOGO DENGAN HALO BULAT LEMBUT ── */}
      {showLogo && (
        <div
          className="absolute flex items-center justify-center pointer-events-none transition-all"
          style={{
            transform: isLogoZooming
              ? 'translateY(0) scale(3.8)'
              : frame === 2
              ? 'translateY(0) scale(1)'
              : 'translateY(-240%) scale(1)',
            opacity: isLogoZooming ? 0 : 1,
            transitionDuration: isLogoZooming ? '1100ms' : '1800ms',
            transitionTimingFunction: isLogoZooming
              ? 'cubic-bezier(0.65, 0, 0.35, 1)'
              : 'cubic-bezier(0.22, 1, 0.36, 1)',
          }}
        >
          {/* Circular halo glow bulat tanpa frame kotak */}
          <div
            className="absolute rounded-full pointer-events-none"
            style={{
              width: '240px',
              height: '240px',
              background: 'radial-gradient(circle, rgba(255,255,255,0.7) 0%, rgba(255,247,178,0.4) 45%, transparent 70%)',
            }}
          />
          <img
            src={lamonLogo}
            alt="Logo LAMON"
            style={{ width: 155, height: 155, objectFit: 'contain' }}
          />
        </div>
      )}

      {/* ── FRAME 4, 5, 6, 7: TEKS "NOMAL" -> "OMALN" -> "LAMON" + SUBTITLE ── */}
      {showWordPhase && (
        <div className="absolute flex flex-col items-center gap-4 pointer-events-none animate-fadeIn">
          {/* Word Flip Row */}
          {renderWord()}

          {/* Subtitle "LAMBUNG AWARENESS & MONITORING" */}
          <span
            style={{
              fontSize: '11px',
              fontWeight: 700,
              color: '#B8630A',
              letterSpacing: '0.24em',
              lineHeight: 1,
              textTransform: 'uppercase',
              opacity: showSubtitle ? 1 : 0,
              transform: showSubtitle ? 'translateY(0)' : 'translateY(8px)',
              transition: 'opacity 0.7s ease-out, transform 0.7s ease-out',
              textAlign: 'center',
              textDecoration: 'none',
              border: 'none',
            }}
          >
            LAMBUNG AWARENESS &amp; MONITORING
          </span>
        </div>
      )}

      {/* ── FRAME 8: "WELCOME" TEXT (HITAM, BOLD, TANPA UNDERLINE, TANPA LOGO) ── */}
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
            fontSize: '42px',
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
