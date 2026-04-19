"use client";
import { createContext, useContext, useState, useEffect } from "react";
import en from "@/i18n/en.json";
import am from "@/i18n/am.json";

const LANGS = { en, am };
const LangContext = createContext(null);

export function LangProvider({ children }) {
  const [lang, setLang] = useState("en");

  useEffect(() => {
    const saved = localStorage.getItem("lang");
    if (saved && LANGS[saved]) setLang(saved);
  }, []);

  const switchLang = (l) => {
    setLang(l);
    localStorage.setItem("lang", l);
  };

  const t = (key) => LANGS[lang][key] || key;

  return (
    <LangContext.Provider value={{ lang, switchLang, t }}>
      {children}
    </LangContext.Provider>
  );
}

export function useLang() {
  return useContext(LangContext);
}
