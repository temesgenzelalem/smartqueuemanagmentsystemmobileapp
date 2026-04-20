"use client";
import { useState, useEffect, useRef, useCallback } from "react";
import API from "@/lib/api";
import { useRouter } from "next/navigation";
import { useLang } from "@/lib/lang";
import { useTheme, Card, Badge, EmptyState, LoadingSpinner, Layout } from "@/components/Layout";

const LOGO = "https://play-lh.googleusercontent.com/UwdS4yhwiOTa5Uq_L2JdZb82iQoQbaKR-gJWUAp4Ri4SyXz_CdP0ei3BCdRF60h0SQ=w240-h480-rw";

const STATUS = {
  waiting:    { label: "Waiting",    bg: "#F1F5F9", text: "#64748B", border: "#E2E8F0" },
  pending:    { label: "Pending",    bg: "#FEF3C7", text: "#92400E", border: "#FCD34D" },
  processing: { label: "Processing", bg: "#FED7AA", text: "#C2410C", border: "#FB923C" },
  completed:  { label: "Completed",  bg: "#DCFCE7", text: "#166534", border: "#86EFAC" },
};

function Toast({ msg, type, onClose }) {
  const { colors } = useTheme();
  useEffect(() => { const t = setTimeout(onClose, 4000); return () => clearTimeout(t); }, [onClose]);
  const bg = type === "success" ? "#166534" : type === "error" ? "#B91C1C" : "#92400E";
  return (
    <div className="fixed top-20 right-5 z-50 text-white px-5 py-3 rounded-xl shadow-lg flex items-center gap-3 text-sm font-semibold animate-slide-in" style={{ backgroundColor: bg }}>
      <span>{msg}</span>
      <button onClick={onClose} className="opacity-70 hover:opacity-100 ml-2">✕</button>
    </div>
  );
}

function LangSwitcher() {
  const { lang, switchLang } = useLang();
  const { colors } = useTheme();
  return (
    <div className="flex items-center gap-1 rounded-lg overflow-hidden border" style={{ borderColor: colors.border }}>
      {["en", "am"].map((l) => (
        <button type="button" key={l} onClick={() => switchLang(l)}
          className="px-2.5 py-1.5 text-xs font-bold transition"
          style={lang === l ? { backgroundColor: colors.accent, color: "#FFFFFF" } : { backgroundColor: "transparent", color: colors.textSecondary }}>
          {l === "en" ? "EN" : "አማ"}
        </button>
      ))}
    </div>
  );
}

function printReceipt(receipt, transaction, user) {
  const w = window.open("", "_blank");
  w.document.write(`
    <html><head><title>Receipt</title>
    <style>
      body { font-family: Arial, sans-serif; padding: 40px; max-width: 500px; margin: auto; }
      .logo { text-align: center; margin-bottom: 20px; }
      .title { text-align: center; font-size: 20px; font-weight: bold; color: #D4AF37; margin-bottom: 4px; }
      .sub { text-align: center; font-size: 12px; color: #666; margin-bottom: 24px; }
      .divider { border-top: 1px dashed #ccc; margin: 16px 0; }
      .row { display: flex; justify-content: space-between; margin-bottom: 10px; font-size: 13px; }
      .label { color: #666; }
      .value { font-weight: bold; color: #222; }
      .footer { text-align: center; font-size: 11px; color: #999; margin-top: 24px; }
      img.receipt { width: 100%; border-radius: 8px; margin-top: 16px; }
    </style></head><body>
    <div class="logo"><img src="${LOGO}" height="50" /></div>
    <div class="title">Tsehay Bank</div>
    <div class="sub">Transaction Receipt</div>
    <div class="divider"></div>
    <div class="row"><span class="label">Customer</span><span class="value">${user?.name || ""}</span></div>
    <div class="row"><span class="label">Type</span><span class="value">${transaction?.type?.toUpperCase() || ""}</span></div>
    <div class="row"><span class="label">Amount</span><span class="value">${Number(transaction?.amount || 0).toLocaleString()} ETB</span></div>
    <div class="row"><span class="label">Account</span><span class="value">${transaction?.account_number || ""}</span></div>
    <div class="row"><span class="label">Queue No</span><span class="value">${transaction?.queue_number || ""}</span></div>
    <div class="row"><span class="label">Date</span><span class="value">${new Date(receipt.created_at).toLocaleString()}</span></div>
    <div class="divider"></div>
    <img class="receipt" src="${receipt.receipt_url}" />
    <div class="footer">Thank you for banking with Tsehay Bank<br/>tsehaybank.com.et</div>
    </body></html>
  `);
  w.document.close();
  w.focus();
  setTimeout(() => { w.print(); }, 500);
}

export default function CustomerDashboard() {
  const router = useRouter();
  const { t } = useLang();
  const { colors } = useTheme();
  const [user, setUser] = useState(null);
  const [transactions, setTransactions] = useState([]);
  const [receipts, setReceipts] = useState([]);
  const [view, setView] = useState("status");
  const [windows, setWindows] = useState([]);
  const [settings, setSettings] = useState({ withdraw_min: 100, withdraw_max: 50000 });
  const [form, setForm] = useState({
    type: "deposit", window_id: "", account_number: "", account_holder: "",
    amount: "", amount_words: "", deposited_by: "",
    date: new Date().toISOString().split("T")[0], to_account: ""
  });
  const [photo, setPhoto] = useState(null);
  const [preview, setPreview] = useState(null);
  const [signature, setSignature] = useState<File | null>(null);
  const [signaturePreview, setSignaturePreview] = useState<string | null>(null);
  const [signatureDataUrl, setSignatureDataUrl] = useState<string | null>(null);
  const [isDrawing, setIsDrawing] = useState(false);
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState(null);
  const [amountError, setAmountError] = useState("");
  const fileRef = useRef<HTMLInputElement>(null);
  const signatureCanvasRef = useRef<HTMLCanvasElement>(null);
  const prevStatuses = useRef<Record<number, string>>({});

  const showToast = (msg, type = "info") => setToast({ msg, type });

  const playBeep = useCallback(() => {
    try {
      const ctx = new (window.AudioContext || (window as any).webkitAudioContext)();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.connect(gain); gain.connect(ctx.destination);
      osc.type = "sine"; osc.frequency.value = 880;
      gain.gain.setValueAtTime(0.6, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 3);
      osc.start(ctx.currentTime); osc.stop(ctx.currentTime + 3);
    } catch {}
  }, []);

  const fetchStatus = useCallback(async () => {
    try {
      const res = await API.get("/my-transactions");
      res.data.forEach(tx => {
        const prev = prevStatuses.current[tx.id];
        if (prev && prev !== tx.status) {
          if (tx.status === "pending") { playBeep(); playBeep(); playBeep(); showToast(t("called_banner"), "info"); }
          if (tx.status === "completed") showToast(t("completed") + "!", "success");
        }
        prevStatuses.current[tx.id] = tx.status;
      });
      setTransactions(res.data);
    } catch { router.push("/customer/login"); }
  }, [router, playBeep, t]);

  const fetchReceipts = useCallback(async () => {
    try { const r = await API.get("/my-receipts"); setReceipts(r.data); } catch {}
  }, []);

  useEffect(() => {
    const u = localStorage.getItem("user");
    if (!u) { router.push("/customer/login"); return; }
    setUser(JSON.parse(u));
    fetchStatus();
    fetchReceipts();
    API.get("/available-windows").then(r => setWindows(r.data)).catch(() => {});
    API.get("/settings").then(r => setSettings(r.data)).catch(() => {});
    const interval = setInterval(() => { fetchStatus(); fetchReceipts(); }, 5000);
    return () => clearInterval(interval);
  }, [fetchStatus, fetchReceipts, router]);

  const validateAmount = (val) => {
    if (form.type === "withdraw") {
      if (val && Number(val) < settings.withdraw_min) {
        setAmountError(`${t("withdraw_min")} ${settings.withdraw_min} ETB`);
      } else if (val && Number(val) > settings.withdraw_max) {
        setAmountError(`${t("withdraw_max")} ${settings.withdraw_max} ETB`);
      } else {
        setAmountError("");
      }
    } else {
      setAmountError("");
    }
  };

  const handlePhoto = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    setPhoto(file); setPreview(URL.createObjectURL(file));
  };

  const initializeSignatureCanvas = useCallback(() => {
    const canvas = signatureCanvasRef.current;
    if (!canvas) return;
    const rect = canvas.getBoundingClientRect();
    const ratio = window.devicePixelRatio || 1;
    canvas.width = rect.width * ratio;
    canvas.height = rect.height * ratio;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
    ctx.fillStyle = colors.bgSecondary;
    ctx.fillRect(0, 0, rect.width, rect.height);
    ctx.strokeStyle = colors.text;
    ctx.lineWidth = 2;
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    if (signatureDataUrl) {
      const img = new Image();
      img.onload = () => ctx.drawImage(img, 0, 0, rect.width, rect.height);
      img.src = signatureDataUrl;
    }
  }, [colors.bgSecondary, colors.text, signatureDataUrl]);

  useEffect(() => {
    initializeSignatureCanvas();
    window.addEventListener("resize", initializeSignatureCanvas);
    return () => window.removeEventListener("resize", initializeSignatureCanvas);
  }, [initializeSignatureCanvas]);

  const getCanvasPos = (event) => {
    const canvas = signatureCanvasRef.current;
    if (!canvas) return { x: 0, y: 0 };
    const rect = canvas.getBoundingClientRect();
    return {
      x: event.clientX - rect.left,
      y: event.clientY - rect.top,
    };
  };

  const saveSignature = () => {
    const canvas = signatureCanvasRef.current;
    if (!canvas) return;
    canvas.toBlob((blob) => {
      if (!blob) return;
      const file = new File([blob], "signature.png", { type: "image/png" });
      const url = URL.createObjectURL(blob);
      setSignature(file);
      setSignaturePreview(url);
      setSignatureDataUrl(url);
    }, "image/png");
  };

  const startSignature = (event) => {
    const canvas = signatureCanvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    const pos = getCanvasPos(event);
    ctx.beginPath();
    ctx.moveTo(pos.x, pos.y);
    setIsDrawing(true);
  };

  const drawSignature = (event) => {
    if (!isDrawing) return;
    const canvas = signatureCanvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    const pos = getCanvasPos(event);
    ctx.lineTo(pos.x, pos.y);
    ctx.stroke();
  };

  const endSignature = () => {
    if (!isDrawing) return;
    setIsDrawing(false);
    saveSignature();
  };

  const clearSignature = () => {
    const canvas = signatureCanvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    const rect = canvas.getBoundingClientRect();
    ctx.clearRect(0, 0, rect.width, rect.height);
    ctx.fillStyle = colors.bgSecondary;
    ctx.fillRect(0, 0, rect.width, rect.height);
    setSignature(null);
    setSignaturePreview(null);
    setSignatureDataUrl(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!photo) { showToast(t("photo_required"), "error"); return; }
    if (!signature) { showToast(t("signature_required"), "error"); return; }
    if (!form.window_id) { showToast(t("select_window"), "error"); return; }
    if (amountError) { showToast(amountError, "error"); return; }
    setLoading(true);
    try {
      const data = new FormData();
      Object.entries(form).forEach(([k, v]) => { if (v) data.append(k, v); });
      data.append("photo", photo);
      data.append("signature", signature);
      await API.post("/transactions", data, { headers: { "Content-Type": "multipart/form-data" } });
      showToast("Transaction submitted! You are now in the queue.", "success");
      setView("status");
      setForm({ type: "deposit", window_id: "", account_number: "", account_holder: "", amount: "", amount_words: "", deposited_by: "", date: new Date().toISOString().split("T")[0], to_account: "" });
      setPhoto(null); setPreview(null); setSignature(null); setSignaturePreview(null); setAmountError("");
      fetchStatus();
    } catch (err) {
      const errors = err.response?.data?.errors;
      showToast(errors ? Object.values(errors)[0][0] : (err.response?.data?.message || "Submission failed"), "error");
    } finally { setLoading(false); }
  };

  const logout = () => { localStorage.clear(); router.push("/customer/login"); };
  const calledTx = transactions.find(tx => tx.status === "pending");

  const inputCls = "w-full border rounded-lg px-4 py-3 text-sm focus:outline-none focus:ring-2 transition-all";

  const tabs = [
    { id: "status", label: t("my_transactions"), icon: "📋" },
    { id: "new", label: t("new_request"), icon: "➕" },
    { id: "receipts", label: t("my_receipts"), icon: "🧾" },
  ];

  return (
    <Layout hideNav={true}>
      <div className="min-h-screen" style={{ backgroundColor: colors.bg }}>
        {toast && <Toast msg={toast.msg} type={toast.type} onClose={() => setToast(null)} />}

        {calledTx && (
          <div className="text-center py-4 px-4 font-bold text-base animate-pulse" style={{ backgroundColor: colors.accent, color: "#FFFFFF" }}>
            🔔 {t("called_banner")} — Please proceed to your window!
          </div>
        )}

        {/* Header */}
        <header className="border-b" style={{ backgroundColor: colors.bgSecondary, borderColor: colors.border }}>
          <div className="max-w-4xl mx-auto px-4 sm:px-6 py-4 flex justify-between items-center">
            <div className="flex items-center gap-3">
              <img src={LOGO} alt="Tsehay Bank" className="h-10 w-10 rounded-lg shadow" />
              <div>
                <span className="font-bold text-lg" style={{ color: colors.text }}>{t("bank_name")}</span>
                <p className="text-xs" style={{ color: colors.textSecondary }}>Customer Portal</p>
              </div>
            </div>
            <div className="flex items-center gap-3 ml-auto">
              <div className="hidden sm:block text-right">
                <p className="text-sm font-semibold" style={{ color: colors.text }}>{user?.name}</p>
                <p className="text-xs" style={{ color: colors.textSecondary }}>{user?.email}</p>
              </div>
              <LangSwitcher />
              <button onClick={logout} type="button" className="px-4 py-2 rounded-lg font-semibold text-sm border transition hover:opacity-80" style={{ borderColor: colors.border, color: colors.textSecondary }}>
                {t("logout")}
              </button>
            </div>
          </div>
        </header>

        <div className="max-w-4xl mx-auto px-4 sm:px-6 py-8">
        {/* Tabs */}
        <div className="flex gap-2 mb-8 p-1 rounded-xl" style={{ backgroundColor: colors.bgSecondary }}>
          {tabs.map(tab => (
            <button type="button" key={tab.id} onClick={() => setView(tab.id)}
              className="flex-1 py-3 px-4 rounded-lg font-semibold text-sm transition-all flex items-center justify-center gap-2"
              style={view === tab.id
                ? { backgroundColor: colors.accent, color: "#FFFFFF", boxShadow: "0 2px 8px rgba(212, 175, 55, 0.3)" }
                : { color: colors.textSecondary }
              }>
              <span>{tab.icon}</span>
              <span className="hidden sm:inline">{tab.label}</span>
            </button>
          ))}
        </div>

        {/* ── MY TRANSACTIONS ── */}
        {view === "status" && (
          <div className="space-y-4">
            {transactions.length === 0 && (
              <EmptyState 
                icon="🏦"
                title={t("no_transactions")}
                description="Start a new transaction to see it here."
              />
            )}
            {transactions.map((tx, idx) => {
              const s = STATUS[tx.status] || STATUS.waiting;
              const win = windows.find(w => w.id === tx.window_id);
              return (
                <Card key={tx.id || idx} className="hover:shadow-md transition-shadow">
                  <div className="flex flex-col sm:flex-row sm:justify-between sm:items-start gap-4">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <span className="capitalize font-bold text-lg" style={{ color: colors.text }}>{tx.type}</span>
                        {tx.queue_number && (
                          <Badge variant="gold">{tx.queue_number}</Badge>
                        )}
                      </div>
                      <p className="text-sm" style={{ color: colors.textSecondary }}>
                        {t("amount")}: <span className="font-bold" style={{ color: colors.text }}>{Number(tx.amount).toLocaleString()} ETB</span>
                      </p>
                      {tx.account_number && <p className="text-xs mt-1" style={{ color: colors.textSecondary }}>{t("account_number")}: {tx.account_number}</p>}
                      {win && <p className="text-xs mt-1" style={{ color: colors.textSecondary }}>Window: <span className="font-semibold" style={{ color: colors.accent }}>{win.name}</span></p>}
                      <p className="text-xs mt-1" style={{ color: colors.textSecondary, opacity: 0.7 }}>{new Date(tx.created_at).toLocaleString()}</p>
                    </div>
                    <div className="flex flex-col items-start sm:items-end gap-2">
                      <span className="px-3 py-1.5 rounded-full text-xs font-bold capitalize" style={{ backgroundColor: s.bg, color: s.text }}>
                        {t(tx.status) || tx.status}
                      </span>
                      {tx.status === "pending" && (
                        <span className="text-xs font-bold animate-pulse" style={{ color: colors.accent }}>Go to window!</span>
                      )}
                    </div>
                  </div>
                </Card>
              );
            })}
          </div>
        )}

        {/* ── NEW REQUEST ── */}
        {view === "new" && (
          <form onSubmit={handleSubmit}>
            <Card>
              <h2 className="text-xl font-bold mb-6" style={{ color: colors.text }}>{t("new_request")}</h2>

            {/* Step 1 */}
            <div className="mb-6">
              <label className="block text-xs font-bold uppercase mb-3" style={{ color: colors.textSecondary }}>
                Step 1 — {t("choose_service")}
              </label>
              <div className="grid grid-cols-3 gap-3">
                {["deposit", "withdraw", "transfer"].map(type => (
                  <button type="button" key={type} onClick={() => { setForm({ ...form, type }); setAmountError(""); }}
                    className="py-4 rounded-xl font-bold text-sm border-2 transition-all capitalize"
                    style={form.type === type 
                      ? { backgroundColor: colors.accent, color: "#FFFFFF", borderColor: colors.accent } 
                      : { backgroundColor: colors.bg, color: colors.textSecondary, borderColor: colors.border }
                    }>
                    {type === "deposit" && "💰"}
                    {type === "withdraw" && "🏧"}
                    {type === "transfer" && "🔄"}
                    <span className="ml-2">{t(type)}</span>
                  </button>
                ))}
              </div>

              <label className="block text-xs font-bold uppercase mt-6 mb-3" style={{ color: colors.textSecondary }}>{t("select_window")}</label>
              {windows.length === 0 ? (
                <p className="text-sm py-4" style={{ color: colors.textSecondary }}>No windows available.</p>
              ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {windows.map(w => (
                    <button type="button" key={w.id} onClick={() => setForm({ ...form, window_id: w.id })}
                      className="py-4 px-5 rounded-xl font-semibold text-sm border-2 transition-all flex flex-col items-start"
                      style={form.window_id === w.id 
                        ? { backgroundColor: "#FEF3C7", color: "#92400E", borderColor: colors.accent }
                        : { backgroundColor: colors.bg, color: colors.textSecondary, borderColor: colors.border }
                      }>
                      <span className="font-bold">{w.name}</span>
                      <span className="text-xs mt-1 opacity-70">
                        {w.waiting_count ?? 0} {t("customers_waiting")} · ~{(w.waiting_count ?? 0) * 4} {t("minutes")}
                      </span>
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Step 2 */}
            <div className="mb-6">
              <label className="block text-xs font-bold uppercase mb-3" style={{ color: colors.textSecondary }}>
                Step 2 — {t("fill_details")}
              </label>

              {form.type === "deposit" && (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {[
                    { key: "account_number", label: t("account_number"), placeholder: "e.g. 1000123456" },
                    { key: "account_holder", label: t("account_holder"), placeholder: "Full name on account" },
                    { key: "amount", label: t("amount"), placeholder: "0.00", type: "number" },
                    { key: "amount_words", label: t("amount_words"), placeholder: "e.g. Five Hundred Birr" },
                    { key: "deposited_by", label: t("deposited_by"), placeholder: "Your full name" },
                    { key: "date", label: t("date"), type: "date" },
                  ].map(f => (
                    <div key={f.key}>
                      <label className="block text-xs font-semibold mb-2" style={{ color: colors.text }}>{f.label}</label>
                      <input 
                        className={inputCls} 
                        type={f.type || "text"} 
                        placeholder={f.placeholder} 
                        value={form[f.key]} 
                        min={f.type === "number" ? "1" : undefined}
                        style={{ backgroundColor: colors.bgSecondary, borderColor: colors.border, color: colors.text }}
                        onChange={e => setForm({ ...form, [f.key]: e.target.value })} 
                        required 
                      />
                    </div>
                  ))}
                </div>
              )}

              {form.type === "withdraw" && (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {[
                    { key: "account_holder", label: t("account_holder"), placeholder: "Full name on account" },
                    { key: "amount_words", label: t("amount_words"), placeholder: "e.g. Five Hundred Birr" },
                    { key: "account_number", label: t("account_number"), placeholder: "e.g. 1000123456" },
                  ].map(f => (
                    <div key={f.key}>
                      <label className="block text-xs font-semibold mb-2" style={{ color: colors.text }}>{f.label}</label>
                      <input 
                        className={inputCls} 
                        type="text" 
                        placeholder={f.placeholder} 
                        value={form[f.key]}
                        style={{ backgroundColor: colors.bgSecondary, borderColor: colors.border, color: colors.text }}
                        onChange={e => setForm({ ...form, [f.key]: e.target.value })} 
                        required 
                      />
                    </div>
                  ))}
                  <div>
                    <label className="block text-xs font-semibold mb-2" style={{ color: colors.text }}>{t("amount")}</label>
                    <input 
                      className={inputCls} 
                      type="number" 
                      placeholder="0.00" 
                      value={form.amount} 
                      min="1"
                      style={{ backgroundColor: colors.bgSecondary, borderColor: colors.border, color: colors.text }}
                      onChange={e => { setForm({ ...form, amount: e.target.value }); validateAmount(e.target.value); }} 
                      required 
                    />
                    {amountError && <p className="text-xs mt-2 font-semibold" style={{ color: "#EF4444" }}>{amountError}</p>}
                    <p className="text-xs mt-2" style={{ color: colors.textSecondary }}>
                      Min: {settings.withdraw_min} ETB · Max: {settings.withdraw_max} ETB
                    </p>
                  </div>
                </div>
              )}

              {form.type === "transfer" && (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {[
                    { key: "account_number", label: t("account_number"), placeholder: "e.g. 1000123456" },
                    { key: "account_holder", label: t("account_holder"), placeholder: "Full name on account" },
                    { key: "amount", label: t("amount"), placeholder: "0.00", type: "number" },
                    { key: "amount_words", label: t("amount_words"), placeholder: "e.g. Five Hundred Birr" },
                    { key: "deposited_by", label: t("deposited_by"), placeholder: "Your full name" },
                    { key: "date", label: t("date"), type: "date" },
                  ].map(f => (
                    <div key={f.key}>
                      <label className="block text-xs font-semibold mb-2" style={{ color: colors.text }}>{f.label}</label>
                      <input 
                        className={inputCls} 
                        type={f.type || "text"} 
                        placeholder={f.placeholder} 
                        value={form[f.key]} 
                        min={f.type === "number" ? "1" : undefined}
                        style={{ backgroundColor: colors.bgSecondary, borderColor: colors.border, color: colors.text }}
                        onChange={e => setForm({ ...form, [f.key]: e.target.value })} 
                        required 
                      />
                    </div>
                  ))}
                  <div className="sm:col-span-2">
                    <label className="block text-xs font-semibold mb-2" style={{ color: colors.text }}>{t("recipient_account")}</label>
                    <input 
                      className={inputCls} 
                      placeholder="Recipient account number" 
                      value={form.to_account}
                      style={{ backgroundColor: colors.bgSecondary, borderColor: colors.border, color: colors.text }}
                      onChange={e => setForm({ ...form, to_account: e.target.value })} 
                      required 
                    />
                  </div>
                </div>
              )}
            </div>

            {/* Step 3: Photo */}
            <div className="mb-6">
              <label className="block text-xs font-bold uppercase mb-3" style={{ color: colors.textSecondary }}>
                Step 3 — {t("upload_photo")}
              </label>
              <div 
                onClick={() => fileRef.current.click()}
                className="border-2 border-dashed rounded-xl p-8 flex flex-col items-center cursor-pointer transition-all hover:border-opacity-80"
                style={{ borderColor: colors.accent, backgroundColor: preview ? "#FFFBEB" : colors.bgSecondary }}>
                {preview ? (
                  <div className="relative">
                    <img src={preview} alt="preview" className="h-40 object-cover rounded-xl shadow" />
                    <button type="button" onClick={(e) => { e.stopPropagation(); setPhoto(null); setPreview(null); }} className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm">✕</button>
                  </div>
                ) : (
                  <>
                    <span className="text-4xl mb-3">📷</span>
                    <span className="text-sm font-semibold" style={{ color: colors.accent }}>Click to upload photo</span>
                    <span className="text-xs mt-1" style={{ color: colors.textSecondary }}>JPG, PNG up to 4MB</span>
                  </>
                )}
              </div>
              <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={handlePhoto} />
            </div>

            {/* Step 4: Signature */}
            <div className="mb-6">
              <label className="block text-xs font-bold uppercase mb-3" style={{ color: colors.textSecondary }}>
                Step 4 — {t("draw_signature")}
              </label>
              <div className="rounded-2xl overflow-hidden border" style={{ borderColor: colors.accent, backgroundColor: colors.bgSecondary }}>
                <div className="flex items-center justify-between px-4 py-3 bg-opacity-90" style={{ backgroundColor: colors.bgSecondary }}>
                  <div>
                    <p className="text-sm font-semibold" style={{ color: colors.accent }}>{t("signature_instructions")}</p>
                    <p className="text-xs" style={{ color: colors.textSecondary }}>{t("signature_hint")}</p>
                  </div>
                  <button type="button" onClick={clearSignature} className="text-xs px-3 py-1 rounded-lg border transition" style={{ borderColor: colors.border, color: colors.textSecondary }}>
                    {t("clear")}
                  </button>
                </div>
                <div className="bg-white" style={{ backgroundColor: colors.bgSecondary }}>
                  <canvas
                    ref={signatureCanvasRef}
                    className="w-full h-48 touch-none"
                    onPointerDown={startSignature}
                    onPointerMove={drawSignature}
                    onPointerUp={endSignature}
                    onPointerCancel={endSignature}
                    onPointerLeave={endSignature}
                    style={{ display: "block", width: "100%", height: "12rem" }}
                  />
                </div>
              </div>
              {signaturePreview && (
                <p className="text-xs mt-3" style={{ color: colors.textSecondary }}>{t("signature_saved")}</p>
              )}
            </div>

            <button 
              type="submit"
              disabled={loading || !!amountError}
              className="w-full py-4 rounded-xl font-bold text-base transition-all hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed"
              style={{ backgroundColor: (loading || !!amountError) ? "#E5E5E5" : colors.accent, color: (loading || !!amountError) ? "#999999" : "#FFFFFF" }}>
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <LoadingSpinner size="sm" />
                  Submitting...
                </span>
              ) : t("submit")}
            </button>
          </Card>
          </form>
        )}

        {/* ── MY RECEIPTS ── */}
        {view === "receipts" && (
          <div className="space-y-4">
            {receipts.length === 0 && (
              <EmptyState 
                icon="🧾"
                title={t("no_receipts")}
                description="Receipts will appear here after your transaction is completed."
              />
            )}
            {receipts.map((r, idx) => {
              const tx = transactions.find(tx => tx.id === r.transaction_id) || r.transaction;
              return (
                <Card key={r.id || idx} noPadding>
                  <div className="p-4 border-b flex flex-col sm:flex-row sm:items-center justify-between gap-3" style={{ borderColor: colors.border }}>
                    <div>
                      <p className="font-bold text-sm capitalize" style={{ color: colors.text }}>{tx?.type} Receipt</p>
                      <p className="text-xs mt-1" style={{ color: colors.textSecondary }}>
                        {tx?.queue_number && <span className="font-semibold" style={{ color: colors.accent }}>{tx.queue_number} · </span>}
                        {Number(tx?.amount || 0).toLocaleString()} ETB · {new Date(r.created_at).toLocaleDateString()}
                      </p>
                    </div>
                    <button type="button" onClick={() => printReceipt(r, tx, user)}
                      className="px-4 py-2 rounded-lg font-semibold text-xs border transition hover:opacity-80"
                      style={{ borderColor: colors.accent, color: colors.accent }}>
                      🖨️ {t("print")} / PDF
                    </button>
                  </div>
                  <div className="p-4">
                    <img src={r.receipt_url} alt="Receipt" className="w-full rounded-lg border object-contain max-h-80" style={{ borderColor: colors.border }} />
                  </div>
                </Card>
              );
            })}
          </div>
        )}
      </div>
    </div>
    </Layout>
  );
}