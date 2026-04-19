"use client";
import { useState } from "react";
import React from "react";
import API from "@/lib/api";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useLang } from "@/lib/lang";
import { Layout, useTheme, Input, Button, Card } from "@/components/Layout";

const LOGO = "https://play-lh.googleusercontent.com/UwdS4yhwiOTa5Uq_L2JdZb82iQoQbaKR-gJWUAp4Ri4SyXz_CdP0ei3BCdRF60h0SQ=w240-h480-rw";

export default function CustomerLogin() {
  const [form, setForm] = useState({ email: "", password: "" });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [successMessage, setSuccessMessage] = useState("");
  const [verificationRequired, setVerificationRequired] = useState(false);
  const router = useRouter();
  const { t } = useLang();
  const { colors } = useTheme();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    setSuccessMessage("");
    setVerificationRequired(false);
    try {
      const res = await API.post("/login", form);
      if (res.data.user.role !== "customer") {
        setError("This login is for customers only.");
        return;
      }
      localStorage.setItem("token", res.data.token);
      localStorage.setItem("user", JSON.stringify(res.data.user));
      router.push("/customer/dashboard");
    } catch (err) {
      const errorData = err.response?.data;
      if (errorData?.requires_verification) {
        setVerificationRequired(true);
        setError("Please verify your email address before logging in.");
      } else {
        setError(errorData?.message || "Login failed. Please check your credentials.");
      }
    } finally {
      setLoading(false);
    }
  };

  const resendVerification = async () => {
    if (!form.email) {
      setError("Enter your email to resend verification.");
      return;
    }

    setLoading(true);
    try {
      await API.post("/email/resend", { email: form.email });
      setSuccessMessage("Verification email sent. Please check your inbox.");
      setError("");
      setVerificationRequired(false);
    } catch (err) {
      setSuccessMessage("");
      setError(err.response?.data?.message || "Failed to send verification email.");
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

          {/* Login Card */}
          <Card>
            <div className="text-center mb-8">
              <h1 className="text-2xl font-bold mb-2" style={{ color: colors.text }}>
                {t("customer_login")}
              </h1>
              <p className="text-sm" style={{ color: colors.textSecondary }}>
                {t("customer_portal")}
              </p>
            </div>

            {error && (
              <div className="mb-6 px-4 py-3 rounded-lg text-sm font-medium"
                style={{ 
                  backgroundColor: verificationRequired ? "#FEF3C7" : (colors.text === "#F1F5F9" ? "#FEE2E2" : "#FEF2F2"), 
                  color: verificationRequired ? "#92400E" : "#B91C1C" 
                }}>
                <div className="flex items-start gap-2">
                  <svg className="w-5 h-5 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                  </svg>
                  <div className="flex-1">
                    <p>{error}</p>
                    {verificationRequired && (
                      <button
                        onClick={resendVerification}
                        disabled={loading}
                        className="mt-2 text-xs font-semibold underline hover:no-underline disabled:opacity-50"
                        style={{ color: "#92400E" }}
                      >
                        {loading ? "Sending..." : "Resend verification email"}
                      </button>
                    )}
                  </div>
                </div>
              </div>
            )}
            {successMessage && (
              <div className="mb-6 px-4 py-3 rounded-lg text-sm font-medium"
                style={{ backgroundColor: "#DCFCE7", color: "#166534" }}>
                <div className="flex items-start gap-2">
                  <svg className="w-5 h-5 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.707a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                  </svg>
                  <div className="flex-1">
                    <p>{successMessage}</p>
                  </div>
                </div>
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-5">
              <div>
                <label htmlFor="email" className="block text-sm font-semibold mb-2" style={{ color: colors.text }}>
                  {t("email")}
                </label>
                <input
                  id="email"
                  type="email"
                  className="w-full border rounded-lg px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-offset-2 transition-all"
                  style={{
                    backgroundColor: colors.bg,
                    borderColor: colors.border,
                    color: colors.text,
                    "--tw-ring-color": colors.accent,
                  } as React.CSSProperties}
                  placeholder="your@email.com"
                  value={form.email}
                  onChange={e => setForm({ ...form, email: e.target.value })}
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
                  className="w-full border rounded-lg px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-offset-2 transition-all"
                  style={{
                    backgroundColor: colors.bg,
                    borderColor: colors.border,
                    color: colors.text,
                    "--tw-ring-color": colors.accent,
                  } as React.CSSProperties}
                  placeholder="••••••••"
                  value={form.password}
                  onChange={e => setForm({ ...form, password: e.target.value })}
                  required
                />
              </div>
              
              <button
                type="submit"
                disabled={loading}
                className="w-full py-4 rounded-xl font-bold text-base transition-all hover:opacity-90 disabled:opacity-50"
                style={{ backgroundColor: loading ? "#B8860B" : colors.accent, color: "#FFFFFF" }}
              >
                {loading ? (
                  <span className="flex items-center justify-center gap-2">
                    <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                    </svg>
                    {t("logging_in")}
                  </span>
                ) : t("login")}
              </button>
            </form>

            <div className="mt-6 text-center space-y-2">
              <p className="text-sm" style={{ color: colors.textSecondary }}>
                {t("no_account")}{" "}
                <Link href="/customer/signup" className="font-semibold hover:opacity-80 transition" style={{ color: colors.accent }}>
                  {t("sign_up")}
                </Link>
              </p>
              <Link href="/" className="text-sm hover:opacity-80 transition inline-flex items-center gap-1" style={{ color: colors.textSecondary }}>
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                </svg>
                {t("back_home")}
              </Link>
            </div>
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