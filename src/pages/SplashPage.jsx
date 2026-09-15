import React, { useEffect, useRef, useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import lamonLogo from '../assets/lamon-logo.png';

/**
 * SplashPage — Animasi pembuka LAMON sebelum halaman Login.
 *
 * Urutan fase:
 *   logo     → logo fade/scale-in di background gradient kuning
 *   orange   → crossfade ke background oranye solid
 *   scramble → teks "LAMON" letter-scramble di atas background kuning
 *   subtitle → subtitle fade-in di bawah teks LAMON
 *   welcome  → crossfade ke teks "WELCOME" (hitam, bold)
 *   done     → navigate ke /login
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

// ── Phases ─────────────────────────────────────────────────────────────────
// 'logo' | 'orange' | 'scramble' | 'subtitle' | 'welcome' | 'done'

export default function SplashPage() {
  const navigate = useNavigate();
  const [phase, setPhase] = useState('logo');
  const [scrambleText, setScrambleText] = useState(TARGET);
  const rafRef = useRef(null);
  const startRef = useRef(null);

  // Tap/click anywhere to skip
  const skip = useCallback(() => {
    if (rafRef.current) cancelAnimationFrame(rafRef.current);
    navigate('/login', { replace: true });
  }, [navigate]);

  useEffect(() => {
    let cancelled = false;

    const delay = (ms) => new Promise((res) => setTimeout(res, ms));

    async function run() {
      // Phase: logo (900ms fade-in is CSS, just wait)
      await delay(1200);
      if (cancelled) return;

      // Phase: orange crossfade
      setPhase('orange');
      await delay(600);
      if (cancelled) return;

      // Phase: scramble — animate over 900ms
      setPhase('scramble');
      await new Promise((resolve) => {
        const duration = 900;
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
      await delay(100);

      // Phase: subtitle
      setPhase('subtitle');
      await delay(800);
      if (cancelled) return;

      // Hold with LAMON + subtitle
      await delay(900);
      if (cancelled) return;

      // Phase: welcome
      setPhase('welcome');
      await delay(1100);
      if (cancelled) return;

      // Navigate
      navigate('/login', { replace: true });
    }

    run();

    return () => {
      cancelled = true;
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
    };
  }, [navigate]);

  // ── Derived display state ────────────────────────────────────────────────
  const showLogo = phase === 'logo' || phase === 'orange';
  const logoVisible = phase !== 'orange'; // logo starts fading when orange comes in
  const showOrangeOverlay = phase === 'orange';
  const showScramble = phase === 'scramble' || phase === 'subtitle' || phase === 'welcome';
  const showSubtitle = phase === 'subtitle' || phase === 'welcome';
  const showWelcome = phase === 'welcome';

  return (
    <div
      onClick={skip}
      style={{ cursor: 'default' }}
      className="fixed inset-0 flex items-center justify-center overflow-hidden select-none"
    >
      {/* ── Base gradient background (always visible) ── */}
      <div
        className="absolute inset-0"
        style={{
          background: 'linear-gradient(to bottom, #FFF4A8, #FAF4C8, #FFFDE8)',
        }}
      />

      {/* ── Orange overlay (crossfade in then out) ── */}
      <div
        className="absolute inset-0 transition-opacity duration-500"
        style={{
          backgroundColor: '#F5A623',
          opacity: showOrangeOverlay ? 1 : 0,
          pointerEvents: 'none',
        }}
      />

      {/* ── Logo (phase: logo, starts fading during orange) ── */}
      {showLogo && (
        <div
          className="absolute flex items-center justify-center"
          style={{
            opacity: logoVisible ? 1 : 0,
            transform: logoVisible ? 'scale(1)' : 'scale(0.7)',
            transition: 'opacity 0.9s ease-out, transform 0.9s cubic-bezier(0.34, 1.56, 0.64, 1)',
          }}
        >
          <img
            src={lamonLogo}
            alt="Logo LAMON"
            style={{ width: 160, height: 160, objectFit: 'contain' }}
          />
        </div>
      )}

      {/* ── LAMON text + subtitle (scramble → subtitle → hidden at welcome) ── */}
      {showScramble && (
        <div className="absolute flex flex-col items-center gap-3">
          {/* Main LAMON scramble text */}
          <span
            style={{
              fontSize: 52,
              fontWeight: 900,
              color: '#B8630A',
              letterSpacing: 10,
              lineHeight: 1,
              opacity: showWelcome ? 0 : 1,
              transition: showWelcome ? 'opacity 0.4s ease-in' : 'opacity 0.35s ease-out',
              fontFamily: 'inherit',
            }}
          >
            {scrambleText}
          </span>

          {/* Subtitle */}
          <span
            style={{
              fontSize: 10,
              fontWeight: 600,
              color: '#B8630A',
              letterSpacing: '0.22em',
              lineHeight: 1,
              textTransform: 'uppercase',
              opacity: showSubtitle && !showWelcome ? 1 : 0,
              transition: showWelcome
                ? 'opacity 0.4s ease-in'
                : 'opacity 0.5s ease-out',
              textAlign: 'center',
            }}
          >
            LAMBUNG AWARENESS &amp; MONITORING
          </span>
        </div>
      )}

      {/* ── WELCOME text ── */}
      <div
        className="absolute flex items-center justify-center"
        style={{
          opacity: showWelcome ? 1 : 0,
          transition: 'opacity 0.5s ease-out',
          pointerEvents: 'none',
        }}
      >
        <span
          style={{
            fontSize: 40,
            fontWeight: 900,
            color: 'rgba(0,0,0,0.87)',
            letterSpacing: '0.18em',
          }}
        >
          WELCOME
        </span>
      </div>
    </div>
  );
}
