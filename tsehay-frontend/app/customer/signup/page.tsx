"use client";
import { useState } from "react";
import API from "@/lib/api";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useLang } from "@/lib/lang";
import { Layout, useTheme, Card } from "@/components/Layout";

const LOGO = "https://play-lh.googleusercontent.com/UwdS4yhwiOTa5Uq_L2JdZb82iQoQbaKR-gJWUAp4Ri4SyXz_CdP0ei3BCdRF60h0SQ=w240-h480-rw";

export default function CustomerSignup() {
  const [form, setForm] = useState({ name: "", email: "", password: "" });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);
  const router = useRouter();
  const { t } = useLang();
  const { colors } = useTheme();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const response = await API.post("/register", form);
      if (response.data.requires_verification) {
        setSuccess(true);
      } else {
        router.push("/customer/login");
      }
    } catch (err) {
      setError(err.response?.data?.message || "Registration failed. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Layout hideNav>
      <div className="min-h-screen flex items-center justify-center p-4" style={{ background: `linear-gradient(135deg, ${colors.blue} 0%, ${colors.blueDark} 100%)` }}>
        <div className="w-full max-w-md">
          {/* Logo Header */}
          <div className="text-center mb-8">
            <div className="inline-flex items-center gap-3 mb-4">
              <img src={LOGO} alt="Tsehay Bank" className="h-14 w-14 rounded-xl shadow-lg" />
              <div className="text-left">
                <p className="text-white font-bold text-xl">Tsehay Bank</p>
                <p className="text-gray-400 text-sm">Smart Queue System</p>
              </div>
            </div>
          </div>

          {/* Signup Card */}
          <Card>
            <div className="text-center mb-8">
              <h1 className="text-2xl font-bold mb-2" style={{ color: colors.text }}>
                {success ? t("check_email") : t("create_account")}
              </h1>
              <p className="text-sm" style={{ color: colors.textSecondary }}>
                {success ? t("verification_sent") : "Tsehay Bank Customer Portal"}
              </p>
            </div>

            {success ? (
              <div className="text-center space-y-4">
                <div className="w-16 h-16 mx-auto rounded-full flex items-center justify-center" style={{ backgroundColor: "#DCFCE7" }}>
                  <svg className="w-8 h-8" style={{ color: "#166534" }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 4.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                </div>
                <div className="space-y-2">
                  <p className="text-sm" style={{ color: colors.textSecondary }}>
                    {t("verification_instructions")}
                  </p>
                  <p className="text-xs font-medium" style={{ color: colors.accent }}>
                    {form.email}
                  </p>
                </div>
                <div className="pt-4 space-y-3">
                  <button
                    onClick={() => router.push("/customer/login")}
                    className="w-full py-3 rounded-lg font-semibold text-sm transition hover:opacity-90"
                    style={{ backgroundColor: colors.accent, color: "#FFFFFF" }}
                  >
                    {t("proceed_login")}
                  </button>
                  <button
                    onClick={() => setSuccess(false)}
                    className="w-full py-2 text-sm font-medium transition hover:opacity-80"
                    style={{ color: colors.textSecondary }}
                  >
                    {t("back_signup")}
                  </button>
                </div>
              </div>
            ) : (
              <>
                {error && (
                  <div className="mb-6 px-4 py-3 rounded-lg text-sm font-medium flex items-center gap-2"
                    style={{ backgroundColor: "#FEE2E2", color: "#B91C1C" }}>
                    <svg className="w-5 h-5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                    </svg>
                    {error}
                  </div>
                )}

                <form onSubmit={handleSubmit} className="space-y-5">
                  <div>
                    <label htmlFor="name" className="block text-sm font-semibold mb-2" style={{ color: colors.text }}>
                      {t("full_name")}
                    </label>
                    <input
                      id="name"
                      type="text"
                      className="w-full border rounded-lg px-4 py-3 text-sm focus:outline-none focus:ring-2 transition-all"
                      placeholder="Your full name"
                      value={form.name}
                      onChange={e => setForm({ ...form, name: e.target.value })}
                      style={{ backgroundColor: colors.bg, borderColor: colors.border, color: colors.text }}
                      required
                    />
                  </div>
                  <div>
                    <label htmlFor="email" className="block text-sm font-semibold mb-2" style={{ color: colors.text }}>
                      {t("email")}
                    </label>
                    <input
                      id="email"
                      type="email"
                      className="w-full border rounded-lg px-4 py-3 text-sm focus:outline-none focus:ring-2 transition-all"
                      placeholder="your@email.com"
                      value={form.email}
                      onChange={e => setForm({ ...form, email: e.target.value })}
                      style={{ backgroundColor: colors.bg, borderColor: colors.border, color: colors.text }}
                      required
                    />
                  </div>
                  <div>
                    <label htmlFor="password" className="block text-sm font-semibold mb-2" style={{ color: colors.text }}>
                      {t("password")}
                    </label>
                    <input
                      id="password"
                      type="password"
                      className="w-full border rounded-lg px-4 py-3 text-sm focus:outline-none focus:ring-2 transition-all"
                      placeholder="Min. 6 characters"
                      value={form.password}
                      onChange={e => setForm({ ...form, password: e.target.value })}
                      style={{ backgroundColor: colors.bg, borderColor: colors.border, color: colors.text }}
                      required
                    />
                  </div>
                  
                  <button
                    type="submit"
                    disabled={loading}
                    className="w-full py-4 rounded-xl font-bold text-base transition-all hover:opacity-90 disabled:opacity-50"
                    style={{ backgroundColor: loading ? "#B8860B" : colors.accent, color: "#FFFFFF" }}
                  >
                    {loading ? t("creating") : t("create_account")}
                  </button>
                </form>

                <div className="mt-6 text-center space-y-2">
                  <p className="text-sm" style={{ color: colors.textSecondary }}>
                    {t("have_account")}{" "}
                    <Link href="/customer/login" className="font-semibold hover:opacity-80 transition" style={{ color: colors.accent }}>
                      {t("login")}
                    </Link>
                  </p>
                  <Link href="/" className="text-sm hover:opacity-80 transition inline-flex items-center gap-1" style={{ color: colors.textSecondary }}>
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                    </svg>
                    {t("back_home")}
                  </Link>
                </div>
              </>
            )}

          </Card>

          {/* Footer */}
          <p className="text-center text-xs text-gray-500 mt-8">
            © {new Date().getFullYear()} Tsehay Bank S.C. All rights reserved.
          </p>
        </div>
      </div>
    </Layout>
  );
}