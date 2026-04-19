"use client";
import { useLang } from "@/lib/lang";

export function Footer({ colors }) {
  const { lang } = useLang();

  return (
    <footer className="border-t transition-colors duration-300" style={{ borderColor: colors.bgTertiary, backgroundColor: "#FFFFFF" }}>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          <div className="md:col-span-2">
            <div className="flex items-center gap-3 mb-4">
              <img src="https://play-lh.googleusercontent.com/UwdS4yhwiOTa5Uq_L2JdZb82iQoQbaKR-gJWUAp4Ri4SyXz_CdP0ei3BCdRF60h0SQ=w240-h480-rw" alt="Tsehay Bank" className="h-10 w-10 rounded-lg" />
              <div>
                <p className="font-bold text-lg text-black">Tsehay Bank</p>
                <p className="text-sm text-gray-600">Smart Queue System</p>
              </div>
            </div>
            <p className="text-sm text-gray-600 leading-relaxed max-w-md mb-6">
              {lang === "en"
                ? "Experience modern banking with our intelligent queue management system. Skip the lines, save time, and manage your banking needs digitally."
                : "በእኛ ዘመናዊ የወረፋ አስተዳደር ስርዓት ዘመናዊ የባንክ አገልግሎት ይለማመዱ። ወረፋዎችን ዘልለው፣ ጊዜ ይቆጥቡ እና የባንክ ፍላጎቶችዎን በዲጂታል መንገድ ያስተዳድሩ።"}
            </p>
            <div className="flex items-center gap-3">
              <a href="https://facebook.com/tsehaybank" target="_blank" rel="noopener noreferrer" className="p-2.5 rounded-lg bg-gray-100 hover:bg-gray-200 transition-colors" aria-label="Facebook">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
                </svg>
              </a>
              <a href="https://t.me/tsehaybank" target="_blank" rel="noopener noreferrer" className="p-2.5 rounded-lg bg-gray-100 hover:bg-gray-200 transition-colors" aria-label="Telegram">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z" />
                </svg>
              </a>
              <a href="https://twitter.com/tsehaybank" target="_blank" rel="noopener noreferrer" className="p-2.5 rounded-lg bg-gray-100 hover:bg-gray-200 transition-colors" aria-label="Twitter">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z" />
                </svg>
              </a>
            </div>
          </div>

          <div>
            <h3 className="font-bold text-sm mb-4 text-black">
              {lang === "en" ? "Quick Links" : "ፈጣን አገናኞች"}
            </h3>
            <ul className="space-y-2">
              <li>
                <a href="/customer/login" className="text-sm text-gray-600 hover:text-black transition-colors">
                  {lang === "en" ? "Customer Login" : "የደንበኛ መግቢያ"}
                </a>
              </li>
              <li>
                <a href="/manager/login" className="text-sm text-gray-600 hover:text-black transition-colors">
                  {lang === "en" ? "Manager Portal" : "የአስተዳዳሪ ፖርታል"}
                </a>
              </li>
              <li>
                <a href="/accountant/login" className="text-sm text-gray-600 hover:text-black transition-colors">
                  {lang === "en" ? "Staff Portal" : "የሰራተኛ ፖርታል"}
                </a>
              </li>
            </ul>
          </div>

          <div>
            <h3 className="font-bold text-sm mb-4 text-black">
              {lang === "en" ? "Contact Us" : "አግኙን"}
            </h3>
            <ul className="space-y-2 text-sm text-gray-600">
              <li className="flex items-center gap-2">
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M2 3a1 1 0 011-1h2.153a1 1 0 01.986.836l.74 4.435a1 1 0 01-.54 1.06l-1.548.773a11.035 11.035 0 006.451 6.451l.774-1.548a1 1 0 011.059-.54l4.435.74a1 1 0 01.836.986V17a1 1 0 01-1 1h-2C7.82 18 2 12.18 2 5V3z" />
                </svg>
                <span>+251 11 557 0000</span>
              </li>
              <li className="flex items-center gap-2">
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z" />
                  <path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z" />
                </svg>
                <span>info@tsehaybank.com.et</span>
              </li>
              <li className="flex items-start gap-2">
                <svg className="w-4 h-4 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18ha-1a1 1 0 01-1 1v-5.5a3.5 3.5 0 10-7 0V14a1 1 0 001 1h5.5a1 1 0 010 2h-5.5a1 1 0 010-2 3.5 3.5 0 007 0V14a1 1 0 01-1 1H5a1 1 0 01-1-1v-5.5a7 7 0 013-5.95zM12 16a2 2 0 100-4 2 2 0 000 4z" clipRule="evenodd" />
                </svg>
                <span>
                  {lang === "en" ? "Addis Ababa, Ethiopia\nHead Office" : "አዲስ አበባ፣ ኢትዮጵያ\nዋና መሥሪያ ቤት"}
                </span>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <div className="border-t border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex flex-col sm:flex-row justify-between items-center gap-2 text-sm text-gray-600">
            <p>© {new Date().getFullYear()} Tsehay Bank S.C. All rights reserved.</p>
            <div className="flex items-center gap-6">
              <a href="/privacy" className="hover:text-black transition-colors">Privacy Policy</a>
              <a href="/terms" className="hover:text-black transition-colors">Terms of Service</a>
              <a href="/help" className="hover:text-black transition-colors">Help Center</a>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
}
