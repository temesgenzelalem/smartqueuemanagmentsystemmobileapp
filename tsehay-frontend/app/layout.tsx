import "./globals.css";
import { LangProvider } from "@/lib/lang";
import { ThemeProvider } from "@/components/Layout";

export const metadata = {
  title: "Tsehay Bank",
  description: "Smart Queue Management System",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>
        <LangProvider>
          <ThemeProvider>
            {children}
          </ThemeProvider>
        </LangProvider>
      </body>
    </html>
  );
}
