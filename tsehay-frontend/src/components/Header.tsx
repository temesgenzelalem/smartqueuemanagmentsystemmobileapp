"use client";
import Link from "next/link";
import { useLang } from "@/lib/lang";

const LOGO = "https://play-lh.googleusercontent.com/UwdS4yhwiOTa5Uq_L2JdZb82iQoQbaKR-gJWUAp4Ri4SyXz_CdP0ei3BCdRF60h0SQ=w240-h480-rw";

function LangSwitcher({ lang, switchLang, colors }) {
  return (
    <div className="flex items-center gap-1 rounded-lg overflow-hidden border" style={{ borderColor: colors.border }}>
      {["en", "am"].map((l) => (
        <button
          key={l}
          onClick={() => switchLang(l)}
          className="px-3 py-1.5 text-xs font-bold transition-all"
          style={lang === l
            ? { backgroundColor: colors.accent, color: "#FFFFFF" }
            : { backgroundColor: "transparent", color: colors.textSecondary }
          }
        >
          {l === "en" ? "EN" : "አማ"}
        </button>
      ))}
    </div>
  );
}

function ThemeToggle({ darkMode, toggleDarkMode, colors }) {
  return (
    <button
      onClick={toggleDarkMode}
      className="p-2.5 rounded-lg border transition-all hover:scale-105"
      style={{
        backgroundColor: colors.bgSecondary,
        borderColor: colors.border,
        color: colors.textSecondary,
      }}
      aria-label={darkMode ? "Switch to light mode" : "Switch to dark mode"}
    >
      {darkMode ? (
        <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20" style={{ color: colors.accentLight }}>
          <path fillRule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clipRule="evenodd" />
        </svg>
      ) : (
        <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
        </svg>
      )}
    </button>
  );
}

export function Header({ hideNav = false, colors, darkMode, toggleDarkMode }) {
  const { lang, switchLang } = useLang();

  if (hideNav) return null;

  return (
    <nav className="sticky top-0 z-50 border-b backdrop-blur-sm transition-all duration-300" 
      style={{ 
        backgroundColor: colors.bgSecondary + "F2", 
        borderColor: colors.border 
      }}>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <Link href="/" className="flex items-center gap-3">
            <div className="relative">
              <img src={LOGO} alt="Tsehay Bank" className="h-10 w-10 rounded-lg shadow-md" />
              <div className="absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full" style={{ backgroundColor: colors.accent }}></div>
            </div>
            <div className="hidden sm:block">
              <p className="font-bold text-lg leading-tight" style={{ color: colors.text }}>Tsehay Bank</p>
              <p className="text-xs leading-tight" style={{ color: colors.textSecondary }}>Smart Queue System</p>
            </div>
          </Link>

          <div className="hidden md:flex items-center gap-6">
          </div>

          <div className="flex items-center gap-3">
            <LangSwitcher lang={lang} switchLang={switchLang} colors={colors} />
            <ThemeToggle darkMode={darkMode} toggleDarkMode={toggleDarkMode} colors={colors} />
          </div>
        </div>
      </div>
    </nav>
  );
}
