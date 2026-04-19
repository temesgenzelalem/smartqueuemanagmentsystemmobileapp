"use client";
import { createContext, useContext, useState, useEffect } from "react";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";

const COLORS = {
  gold: "#D4AF37",
  goldLight: "#EDBA10",
  goldLighter: "#FDF8E7",
  blue: "#1E3A5F",
  blueDark: "#0F2942",
  blueLight: "#2D4A6F",
};

const LOGO = "https://play-lh.googleusercontent.com/UwdS4yhwiOTa5Uq_L2JdZb82iQoQbaKR-gJWUAp4Ri4SyXz_CdP0ei3BCdRF60h0SQ=w240-h480-rw";

export function ThemeProvider({ children }) {
  const [darkMode, setDarkMode] = useState(false);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const saved = localStorage.getItem("darkMode");
    if (saved !== null) {
      setDarkMode(saved === "true");
    } else if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
      setDarkMode(true);
    }
  }, []);

  useEffect(() => {
    if (!mounted) return;
    localStorage.setItem("darkMode", String(darkMode));
  }, [darkMode, mounted]);

  const colors = {
    bg: darkMode ? "#0F172A" : "#F8FAFC",
    bgSecondary: darkMode ? "#1E293B" : "#FFFFFF",
    bgTertiary: darkMode ? "#334155" : "#F1F5F9",
    text: darkMode ? "#F1F5F9" : "#1E293B",
    textSecondary: darkMode ? "#94A3B8" : "#64748B",
    border: darkMode ? "#334155" : "#E2E8F0",
    accent: COLORS.gold,
    accentLight: COLORS.goldLight,
    blue: COLORS.blue,
  };

  const toggleDarkMode = () => setDarkMode(!darkMode);

  return (
    <ThemeContext.Provider value={{ darkMode, setDarkMode, toggleDarkMode, colors }}>
      <div className="min-h-screen transition-colors duration-300" style={{ backgroundColor: colors.bg, color: colors.text }}>
        {children}
      </div>
    </ThemeContext.Provider>
  );
}

const ThemeContext = createContext(null);

export function useTheme() {
  return useContext(ThemeContext);
}

export function Layout({ children, hideNav = false }) {
  const { darkMode, toggleDarkMode, colors } = useTheme();

  return (
    <div className="min-h-screen flex flex-col">
      <Header hideNav={hideNav} colors={colors} darkMode={darkMode} toggleDarkMode={toggleDarkMode} />
      <main className="flex-1">{children}</main>
      <Footer colors={colors} />
    </div>
  );
}

export function Logo({ size = "md" }) {
  const sizes = { sm: "h-8 w-8", md: "h-10 w-10", lg: "h-14 w-14", xl: "h-20 w-20" };
  const textSizes = { sm: "text-sm", md: "text-base", lg: "text-xl", xl: "text-2xl" };
  
  return (
    <div className="flex items-center gap-3">
      <img src={LOGO} alt="Tsehay Bank" className={`${sizes[size]} rounded-lg shadow-md`} />
      <div className="hidden sm:block">
        <p className={`${textSizes[size]} font-bold`}>Tsehay Bank</p>
        <p className="text-xs text-gray-500">Smart Queue System</p>
      </div>
    </div>
  );
}

export function PageHeader({ title, description, actions }) {
  const { colors } = useTheme();
  
  return (
    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
      <div>
        <h1 className="text-2xl font-bold" style={{ color: colors.text }}>{title}</h1>
        {description && <p className="text-sm mt-1" style={{ color: colors.textSecondary }}>{description}</p>}
      </div>
      {actions && <div className="flex items-center gap-3">{actions}</div>}
    </div>
  );
}

export function Card({ children, className = "", noPadding = false }) {
  const { colors } = useTheme();
  
  return (
    <div 
      className={`rounded-xl border shadow-sm transition-all ${className}`}
      style={{ 
        backgroundColor: colors.bgSecondary, 
        borderColor: colors.border 
      }}
    >
      {!noPadding && <div className="p-6">{children}</div>}
      {noPadding && children}
    </div>
  );
}

export function Button({ children, variant = "primary", size = "md", disabled = false, className = "", ...props }) {
  const { colors } = useTheme();
  
  const variants = {
    primary: { bg: colors.accent, color: "#FFFFFF" },
    secondary: { bg: colors.bgTertiary, color: colors.text },
    outline: { bg: "transparent", color: colors.text, border: colors.border },
    ghost: { bg: "transparent", color: colors.textSecondary },
  };
  
  const sizes = {
    sm: "px-3 py-1.5 text-sm",
    md: "px-4 py-2.5 text-base",
    lg: "px-6 py-3 text-lg",
  };
  
  const v = variants[variant];
  const s = sizes[size];
  
  return (
    <button 
      disabled={disabled}
      className={`rounded-lg font-semibold transition-all hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed ${s} ${className}`}
      style={{ 
        backgroundColor: v.bg, 
        color: v.color,
        border: variant === "outline" ? `1px solid ${v.border}` : "none"
      }}
      {...props}
    >
      {children}
    </button>
  );
}

export function Input({ label, error, className = "", ...props }) {
  const { colors } = useTheme();
  
  return (
    <div className={className}>
      {label && (
        <label className="block text-sm font-semibold mb-2" style={{ color: colors.text }}>
          {label}
        </label>
      )}
      <input
        className="w-full border rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-offset-2 transition-all"
        style={{
          backgroundColor: colors.bgSecondary,
          borderColor: error ? "#EF4444" : colors.border,
          color: colors.text,
          "--tw-ring-color": colors.accent,
        } as React.CSSProperties}
        {...props}
      />
      {error && <p className="text-sm mt-1" style={{ color: "#EF4444" }}>{error}</p>}
    </div>
  );
}

export function Badge({ children, variant = "default" }) {
  const { colors } = useTheme();
  
  const variants = {
    default: { bg: colors.bgTertiary, color: colors.textSecondary },
    success: { bg: "#DCFCE7", color: "#166534" },
    warning: { bg: "#FEF3C7", color: "#92400E" },
    error: { bg: "#FEE2E2", color: "#B91C1C" },
    gold: { bg: "#FDF8E7", color: "#8B6F2F" },
  };
  
  const v = variants[variant];
  
  return (
    <span 
      className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold"
      style={{ backgroundColor: v.bg, color: v.color }}
    >
      {children}
    </span>
  );
}

export function EmptyState({ icon, title, description, action = null }) {
  const { colors } = useTheme();
  
  return (
    <div className="flex flex-col items-center justify-center py-12 px-4 text-center">
      {icon && <div className="text-5xl mb-4">{icon}</div>}
      <h3 className="text-lg font-semibold mb-2" style={{ color: colors.text }}>{title}</h3>
      {description && <p className="text-sm max-w-md mb-6" style={{ color: colors.textSecondary }}>{description}</p>}
      {action !== null && <div>{action}</div>}
    </div>
  );
}

export function LoadingSpinner({ size = "md" }) {
  const { colors } = useTheme();
  
  const sizes = {
    sm: "w-5 h-5",
    md: "w-8 h-8",
    lg: "w-12 h-12",
  };
  
  return (
    <div className="flex items-center justify-center">
      <div 
        className={`${sizes[size]} border-2 rounded-full animate-spin`}
        style={{ borderColor: colors.border, borderTopColor: colors.accent }}
      />
    </div>
  );
}

export function Skeleton({ className = "" }) {
  const { colors } = useTheme();
  
  return (
    <div 
      className={`animate-pulse rounded ${className}`}
      style={{ backgroundColor: colors.bgTertiary }}
    />
  );
}