"use client";
import { useState, useEffect, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import API from "@/lib/api";
import { useLang } from "@/lib/lang";
import { Layout, useTheme, Card } from "@/components/Layout";

const LOGO = "https://play-lh.googleusercontent.com/UwdS4yhwiOTa5Uq_L2JdZb82iQoQbaKR-gJWUAp4Ri4SyXz_CdP0ei3BCdRF60h0SQ=w240-h480-rw";

function EmailVerificationContent() {
  const [status, setStatus] = useState<'loading' | 'success' | 'error'>('loading');
  const [message, setMessage] = useState('');
  const router = useRouter();
  const searchParams = useSearchParams();
  const { t } = useLang();
  const { colors } = useTheme();

  useEffect(() => {
    const verifyEmail = async () => {
      const id = searchParams.get('id');
      const hash = searchParams.get('hash');

      if (!id || !hash) {
        setStatus('error');
        setMessage('Invalid verification link.');
        return;
      }

      try {
        await API.get(`/email/verify/${id}/${hash}`);
        setStatus('success');
        setMessage('Email verified successfully! You can now log in.');
        setTimeout(() => {
          router.push('/customer/login');
        }, 3000);
      } catch (err) {
        setStatus('error');
        setMessage(err.response?.data?.message || 'Verification failed.');
      }
    };

    verifyEmail();
  }, [searchParams, router]);

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

          {/* Verification Card */}
          <Card>
            <div className="text-center">
              <div className="w-16 h-16 mx-auto mb-6 rounded-full flex items-center justify-center"
                style={{
                  backgroundColor: status === 'success' ? '#DCFCE7' :
                                   status === 'error' ? '#FEE2E2' : '#F3F4F6'
                }}>
                {status === 'loading' && (
                  <svg className="animate-spin w-8 h-8" style={{ color: colors.accent }} fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                )}
                {status === 'success' && (
                  <svg className="w-8 h-8" style={{ color: '#166534' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                )}
                {status === 'error' && (
                  <svg className="w-8 h-8" style={{ color: '#B91C1C' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                )}
              </div>

              <h1 className="text-2xl font-bold mb-4" style={{ color: colors.text }}>
                {status === 'loading' ? 'Verifying Email' :
                 status === 'success' ? 'Email Verified!' : 'Verification Failed'}
              </h1>

              <p className="text-sm mb-6" style={{ color: colors.textSecondary }}>
                {message}
              </p>

              {status === 'success' && (
                <p className="text-xs" style={{ color: colors.textSecondary }}>
                  Redirecting to login page...
                </p>
              )}

              {status === 'error' && (
                <div className="space-y-3">
                  <button
                    onClick={() => router.push('/customer/login')}
                    className="w-full py-3 rounded-lg font-semibold text-sm transition hover:opacity-90"
                    style={{ backgroundColor: colors.accent, color: "#FFFFFF" }}
                  >
                    Go to Login
                  </button>
                  <button
                    onClick={() => router.push('/customer/signup')}
                    className="w-full py-2 text-sm font-medium transition hover:opacity-80"
                    style={{ color: colors.textSecondary }}
                  >
                    Back to Signup
                  </button>
                </div>
              )}
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

export default function EmailVerification() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600"></div>
      </div>
    }>
      <EmailVerificationContent />
    </Suspense>
  );
}