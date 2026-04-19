"use client";
import { useState, useEffect } from "react";
import Link from "next/link";
import { useLang } from "@/lib/lang";
import { Layout, useTheme } from "@/components/Layout";

const LOGO = "https://play-lh.googleusercontent.com/UwdS4yhwiOTa5Uq_L2JdZb82iQoQbaKR-gJWUAp4Ri4SyXz_CdP0ei3BCdRF60h0SQ=w240-h480-rw";

const HERO_SLIDES = [
  {
    title_en: "Welcome to Tsehay Bank",
    title_am: "እንኳን ወደ ጸሃይ ባንክ በደህና መጡ",
    subtitle_en: "Smart Queue Management System",
    subtitle_am: "ዘመናዊ የወረፋ አስተዳደር ስርዓት",
    desc_en: "Skip the long lines and manage your banking needs digitally with our smart queue system.",
    desc_am: "ረጅም ወረፋዎችን ዘልለው የባንክ ፍላጎቶችዎን በዲጂታል መንገድ በእኛ ዘመናዊ ስርዓት ያስተዳድሩ።"
  },
  {
    title_en: "Why Choose Us?",
    title_am: "ለምን እኛን ይመርጡ?",
    subtitle_en: "Fast, Secure & Reliable",
    subtitle_am: "ፈጣን፣ ደህንነቱ የተጠበቀ እና አስተማማኝ",
    desc_en: "Experience faster service, reduced waiting time, and seamless banking with real-time notifications.",
    desc_am: "ፈጣን አገልግሎት፣ የተቀነሰ የመጠበቂያ ጊዜ እና ወቅታዊ ማሳወቂያዎች ያለው ቀላል የባንክ አገልግሎት ይለማመዱ።"
  },
  {
    title_en: "Everything You Need",
    title_am: "የሚያስፈልጎት ሁሉ",
    subtitle_en: "Complete Banking Solutions",
    subtitle_am: "ሙሉ የባንክ መፍትሄዎች",
    desc_en: "Deposits, withdrawals, transfers, and more - all managed through our intelligent queue system.",
    desc_am: "ተቀማጭ፣ ማውጣት፣ ዝውውር እና ሌሎችም - ሁሉም በእኛ ዘመናዊ የወረፋ ስርዓት የሚተዳደሩ።"
  }
];

const STEPS = [
  {
    num: "01", icon: "👤", key_title: "step1",
    desc_en: "Create your account or sign in to access the portal.",
    desc_am: "መለያ ይፍጠሩ ወይም ወደ ፖርታሉ ለመግባት ይግቡ።",
  },
  {
    num: "02", icon: "🏦", key_title: "step2",
    desc_en: "Select Deposit, Withdraw, or Transfer and choose your window.",
    desc_am: "ተቀማጭ፣ ማውጣት ወይም ዝውውር ምረጥ እና መስኮህን ምረጥ።",
  },
  {
    num: "03", icon: "⏳", key_title: "step3",
    desc_en: "Submit your request and join the digital queue instantly.",
    desc_am: "ጥያቄዎን ያስገቡ እና ወዲያውኑ ወደ ዲጂታል ወረፋ ይቀላቀሉ።",
  },
  {
    num: "04", icon: "✅", key_title: "step4",
    desc_en: "Get notified when it's your turn and receive your receipt.",
    desc_am: "ተራዎ ሲደርስ ይነገርዎታል እና ደረሰኝዎን ይቀበሉ።",
    isLast: true,
  },
];

const SERVICES = [
  { icon: "💰", key: "deposit", color: "#10B981" },
  { icon: "🏧", key: "withdraw", color: "#3B82F6" },
  { icon: "🔄", key: "transfer", color: "#8B5CF6" },
];

const SERVICE_LABELS = {
  deposit: { en: "Deposit", am: "ተቀማጭ" },
  withdraw: { en: "Withdraw", am: "ማውጣት" },
  transfer: { en: "Account-to-Account Transfer", am: "ከመለያ ወደ መለያ ትራንስፈር" },
};

export default function Home() {
  const { t, lang } = useLang();
  const { colors } = useTheme();
  const [step, setStep] = useState(0);
  const [heroSlide, setHeroSlide] = useState(0);
  const [selectedService, setSelectedService] = useState<string | null>(null);

  useEffect(() => {
    const interval = setInterval(() => {
      setHeroSlide(prev => (prev + 1) % HERO_SLIDES.length);
    }, 4000);
    return () => clearInterval(interval);
  }, []);

  return (
    <Layout>
      <div className="relative overflow-hidden">
        {/* Hero Section */}
        <section className="relative flex flex-col items-center justify-center text-center px-6 py-16 md:py-24 min-h-screen">
          {/* Background decoration */}
          <div className="absolute inset-0 overflow-hidden pointer-events-none">
            <div className="absolute -top-40 -right-40 w-80 h-80 rounded-full opacity-10" style={{ backgroundColor: colors.accent, filter: "blur(60px)" }}></div>
            <div className="absolute -bottom-40 -left-40 w-80 h-80 rounded-full opacity-10" style={{ backgroundColor: colors.blue, filter: "blur(60px)" }}></div>
          </div>

          {/* Logo with animated border */}
          <div className="relative mb-8">
            <div className="relative">
              <img src={LOGO} alt="Tsehay Bank" className="h-20 md:h-24 rounded-2xl shadow-2xl" />
              <div className="absolute -inset-1 rounded-2xl border-2 border-dashed animate-spin" style={{ borderColor: colors.accent, animationDuration: "8s" }}></div>
            </div>
          </div>

          {/* Sliding Hero Content */}
          <div className="relative h-48 w-full max-w-2xl overflow-hidden mb-6">
            {HERO_SLIDES.map((slide, index) => (
              <div key={index} 
                className={`absolute inset-0 transition-all duration-1000 transform ${
                  index === heroSlide ? 'translate-x-0 opacity-100' : 
                  index < heroSlide ? '-translate-x-full opacity-0' : 'translate-x-full opacity-0'
                }`}>
                <p className="text-xs font-bold uppercase tracking-widest mb-3" style={{ color: colors.accent }}>
                  {lang === "en" ? slide.title_en : slide.title_am}
                </p>
                <h1 className="text-3xl md:text-4xl font-bold mb-4 leading-tight" style={{ color: colors.text }}>
                  {lang === "en" ? slide.subtitle_en : slide.subtitle_am}
                </h1>
                <p className="text-sm max-w-lg mx-auto leading-relaxed" style={{ color: colors.textSecondary }}>
                  {lang === "en" ? slide.desc_en : slide.desc_am}
                </p>
              </div>
            ))}
          </div>

          {/* Hero Slide Indicators */}
          <div className="flex gap-2 mb-8">
            {HERO_SLIDES.map((_, index) => (
              <button key={index} type="button"
                onClick={() => setHeroSlide(index)}
                className="w-2 h-2 rounded-full transition-all"
                style={{
                  backgroundColor: index === heroSlide ? colors.accent : colors.border,
                }} />
            ))}
          </div>
        </section>

        {/* Our Services Section */}
        <section className="relative flex flex-col items-center justify-center text-center px-6 py-16 md:py-24">
          <div className="max-w-6xl mx-auto w-full">
            <p className="text-center text-xs font-bold uppercase tracking-widest mb-3" style={{ color: colors.textSecondary }}>
              {lang === "en" ? "Our Services" : "አገልግሎታችን"}
            </p>
            <h2 className="text-3xl md:text-4xl font-bold mb-6" style={{ color: colors.text }}>
              {lang === "en" ? "Trusted Banking Services" : "የታመነ የባንክ አገልግሎቶች"}
            </h2>
            <p className="text-sm max-w-2xl mx-auto leading-relaxed mb-12" style={{ color: colors.textSecondary }}>
              {lang === "en"
                ? "Deposit, withdraw and transfer funds between accounts quickly and securely with our intelligent queue system."
                : "ተቀማጭ፣ ማውጣት እና ከመለያ ወደ መለያ ማሸነፍ በፍጥነትና በደህንነት እንዲሰራ ያስችላል።"}
            </p>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-8 h-full">
              {SERVICES.map((service) => (
                <button
                  key={service.key}
                  type="button"
                  onClick={() => setSelectedService(service.key)}
                  className="rounded-3xl border p-8 text-left transition-all hover:-translate-y-1 hover:shadow-xl h-full flex flex-col justify-between"
                  style={{
                    backgroundColor: colors.bgSecondary,
                    borderColor: selectedService === service.key ? colors.accent : colors.border,
                    color: colors.text,
                    boxShadow: selectedService === service.key ? `0 20px 45px rgba(16, 185, 129, 0.15)` : undefined,
                  }}>
                  <div>
                    <div className="inline-flex items-center justify-center w-20 h-20 rounded-3xl mb-8 text-3xl"
                      style={{ backgroundColor: `${service.color}20`, color: service.color }}>
                      {service.icon}
                    </div>
                    <h3 className="text-2xl font-bold mb-4" style={{ color: colors.text }}>
                      {SERVICE_LABELS[service.key][lang]}
                    </h3>
                    <p className="text-base leading-relaxed" style={{ color: colors.textSecondary }}>
                      {service.key === "deposit" && (lang === "en"
                        ? "Add funds to your account quickly, with real-time queue tracking."
                        : "በወቅታዊ የወረፋ ተከታታይ ስርዓት ገንዘብ ወደ መለያዎ ያክሉ።")}
                      {service.key === "withdraw" && (lang === "en"
                        ? "Withdraw cash securely at your selected window without waiting in line."
                        : "በተመረጠዎ መስኮት ላይ ደህንነት ሳይጒዞ ገንዘብ ያውጡ።")}
                      {service.key === "transfer" && (lang === "en"
                        ? "Move money between accounts with ease and complete transparency."
                        : "በቀላሉ ከመለያ ወደ መለያ ገንዘብ ይንቀሳቀሱ እና በግልፅነት ይጨርሱ።")}
                    </p>
                  </div>
                </button>
              ))}
            </div>

            {selectedService && (
              <div className="mt-12 rounded-3xl border p-8 text-center max-w-2xl mx-auto"
                style={{ backgroundColor: colors.bgSecondary, borderColor: colors.border }}>
                <p className="text-lg font-semibold mb-6" style={{ color: colors.text }}>
                  {lang === "en"
                    ? `You selected ${SERVICE_LABELS[selectedService].en}. Please login or sign up to continue.`
                    : `የምርጫዎ አገልግሎት ${SERVICE_LABELS[selectedService].am} ነው። መግባት ወይም ለመመዝገብ ይጀምሩ።`}
                </p>
                <div className="flex flex-col gap-4 sm:flex-row sm:justify-center">
                  <Link href={`/customer/login?service=${selectedService}`}
                    className="inline-flex items-center justify-center rounded-xl px-8 py-4 font-bold text-lg transition-all hover:opacity-90"
                    style={{ backgroundColor: colors.accent, color: "#FFFFFF" }}>
                    {lang === "en" ? "Customer Login" : "የደንበኛ መግቢያ"}
                  </Link>
                  <Link href={`/customer/signup?service=${selectedService}`}
                    className="inline-flex items-center justify-center rounded-xl px-8 py-4 font-bold text-lg transition-all hover:opacity-90"
                    style={{ backgroundColor: colors.bgTertiary, color: colors.text }}>
                    {lang === "en" ? "Sign Up" : "ይመዝገቡ"}
                  </Link>
                </div>
              </div>
            )}
          </div>
        </section>

        {/* How It Works Section */}
        <section className="relative flex flex-col items-center justify-center text-center px-6 py-16 md:py-24 min-h-screen">
          <div className="max-w-2xl mx-auto w-full">
            <p className="text-center text-xs font-bold uppercase tracking-widest mb-8" style={{ color: colors.textSecondary }}>
              {lang === "en" ? "How It Works" : "እንዴት ይሰራል"}
            </p>

            {/* Progress bar */}
            <div className="flex gap-1 mb-8">
              {STEPS.map((_, i) => (
                <div key={i} className="flex-1 h-1.5 rounded-full cursor-pointer transition-all"
                  style={{ backgroundColor: i <= step ? colors.accent : colors.border }}
                  onClick={() => setStep(i)}
                  role="button"
                  tabIndex={0}
                />
              ))}
            </div>

            {/* Card */}
            <div className="rounded-2xl p-8 md:p-10 border transition-all duration-300"
              style={{
                backgroundColor: colors.bgSecondary,
                borderColor: colors.border,
                boxShadow: "0 4px 24px rgba(0,0,0,0.08)"
              }}>
              <div className="inline-flex items-center justify-center w-14 h-14 rounded-full mb-5 text-xl font-bold"
                style={{
                  backgroundColor: colors.bgTertiary,
                  color: colors.accent,
                  border: `2px solid ${colors.accent}`
                }}>
                {STEPS[step].num}
              </div>

              <div className="text-5xl mb-5">{STEPS[step].icon}</div>

              <h2 className="text-xl font-bold mb-3" style={{ color: colors.text }}>
                {t(STEPS[step].key_title)}
              </h2>
              <p className="text-sm leading-relaxed mb-6" style={{ color: colors.textSecondary }}>
                {lang === "en" ? STEPS[step].desc_en : STEPS[step].desc_am}
              </p>

              {STEPS[step].isLast && (
                <Link href="/customer/signup"
                  className="inline-block py-4 px-8 rounded-xl font-bold text-lg transition-all hover:scale-105"
                  style={{ backgroundColor: colors.accent, color: "#FFFFFF" }}>
                  {t("get_started")} →
                </Link>
              )}
            </div>

            {/* Prev / Dots / Next */}
            <div className="flex items-center justify-between mt-8">
              <button type="button"
                onClick={() => setStep(s => Math.max(0, s - 1))}
                disabled={step === 0}
                className="w-14 h-14 rounded-full font-bold text-3xl transition-all border flex items-center justify-center disabled:opacity-30"
                style={{
                  borderColor: step === 0 ? colors.border : colors.accent,
                  color: step === 0 ? colors.textSecondary : colors.accent,
                  backgroundColor: colors.bgSecondary,
                }}>
                ‹
              </button>

              <div className="flex gap-2">
                {STEPS.map((_, i) => (
                  <button key={i} type="button" onClick={() => setStep(i)}
                    className="rounded-full transition-all"
                    style={{
                      width: step === i ? 28 : 10,
                      height: 10,
                      backgroundColor: step === i ? colors.accent : colors.border,
                    }} />
                ))}
              </div>

              <button type="button"
                onClick={() => setStep(s => Math.min(STEPS.length - 1, s + 1))}
                disabled={step === STEPS.length - 1}
                className="w-14 h-14 rounded-full font-bold text-3xl transition-all border flex items-center justify-center disabled:opacity-30"
                style={{
                  borderColor: step === STEPS.length - 1 ? colors.border : colors.accent,
                  color: step === STEPS.length - 1 ? colors.textSecondary : colors.accent,
                  backgroundColor: colors.bgSecondary,
                }}>
                ›
              </button>
            </div>
          </div>
        </section>

      </div>
    </Layout>
  );
}