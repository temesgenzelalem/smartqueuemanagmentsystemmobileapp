"use client";
import { useState, useEffect, useRef } from "react";
import API from "@/lib/api";
import { useRouter } from "next/navigation";
import { useLang } from "@/lib/lang";
import { useTheme, Card, Badge, EmptyState, LoadingSpinner, Layout } from "@/components/Layout";

const LOGO = "https://play-lh.googleusercontent.com/UwdS4yhwiOTa5Uq_L2JdZb82iQoQbaKR-gJWUAp4Ri4SyXz_CdP0ei3BCdRF60h0SQ=w240-h480-rw";

const STATUS = {
  waiting:    { label: "Waiting",    bg: "#F1F5F9", text: "#64748B" },
  pending:    { label: "Pending",    bg: "#FEF3C7", text: "#92400E" },
  processing: { label: "Processing", bg: "#FED7AA", text: "#C2410C" },
  completed:  { label: "Completed",  bg: "#DCFCE7", text: "#166534" },
};

function Toast({ msg, type, onClose }) {
  useEffect(() => { const t = setTimeout(onClose, 3500); return () => clearTimeout(t); }, [onClose]);
  const bg = type === "success" ? "#166534" : type === "error" ? "#B91C1C" : "#92400E";
  return (
    <div className="fixed top-20 right-5 z-50 text-white px-5 py-3 rounded-xl shadow-lg flex items-center gap-3 text-sm font-semibold" style={{ backgroundColor: bg }}>
      <span>{msg}</span>
      <button onClick={onClose} className="opacity-70 hover:opacity-100 ml-2">✕</button>
    </div>
  );
}

function InfoRow({ label, value }) {
  const { colors } = useTheme();
  if (!value) return null;
  return (
    <div className="flex flex-col gap-0.5">
      <span className="text-xs font-bold uppercase tracking-wide" style={{ color: colors.textSecondary }}>{label}</span>
      <span className="text-sm font-semibold" style={{ color: colors.text }}>{value}</span>
    </div>
  );
}

export default function AccountantDashboard() {
  const router = useRouter();
  const { t } = useLang();
  const { colors } = useTheme();
  const [user, setUser] = useState(null);
  const [queue, setQueue] = useState([]);
  const [selected, setSelected] = useState(null);
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState(null);
  const [receiptFile, setReceiptFile] = useState(null);
  const [receiptPreview, setReceiptPreview] = useState(null);
  const [sendingReceipt, setSendingReceipt] = useState(false);
  const receiptRef = useRef(null);

  const showToast = (msg, type = "info") => setToast({ msg, type });

  useEffect(() => {
    const u = localStorage.getItem("user");
    if (!u) { router.push("/accountant/login"); return; }
    const parsed = JSON.parse(u);
    if (parsed.role !== "accountant") { router.push("/accountant/login"); return; }
    setUser(parsed);
    refresh();
    const interval = setInterval(refresh, 5000);
    return () => clearInterval(interval);
  }, []);

  const refresh = async () => {
    try {
      const q = await API.get("/queue");
      setQueue(q.data);
      setSelected(prev => {
        if (!prev) return null;
        const updated = q.data.find(tx => tx.id === prev.id);
        return updated || prev;
      });
    } catch {}
  };

  const selectCustomer = async (transaction) => {
    if (transaction.status !== "waiting") { setSelected(transaction); return; }
    setLoading(true);
    try {
      const res = await API.post(`/queue/select/${transaction.id}`);
      setSelected(res.data);
      showToast("Customer selected — status set to Pending", "info");
      refresh();
    } catch (err) {
      showToast(err.response?.data?.message || "Error selecting customer", "error");
    } finally { setLoading(false); }
  };

  const complete = async () => {
    if (!selected) return;
    setLoading(true);
    try {
      await API.post(`/queue/complete/${selected.id}`);
      showToast("Transaction completed!", "success");
      refresh();
    } catch { showToast("Error completing transaction", "error"); }
    finally { setLoading(false); }
  };

  const handleReceiptFile = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    setReceiptFile(file);
    setReceiptPreview(URL.createObjectURL(file));
  };

  const handlePaste = (e: React.ClipboardEvent) => {
    const item = Array.from(e.clipboardData.items).find((i: DataTransferItem) => i.type.startsWith("image/"));
    if (!item) return;
    const file = item.getAsFile();
    setReceiptFile(file);
    setReceiptPreview(URL.createObjectURL(file));
  };

  const sendReceipt = async () => {
    if (!receiptFile || !selected) return;
    setSendingReceipt(true);
    try {
      const fd = new FormData();
      fd.append("image", receiptFile);
      await API.post(`/receipts/${selected.id}`, fd, { headers: { "Content-Type": "multipart/form-data" } });
      showToast(t("receipt_sent"), "success");
      setReceiptFile(null);
      setReceiptPreview(null);
    } catch (err) {
      showToast(err.response?.data?.message || "Failed to send receipt", "error");
    } finally { setSendingReceipt(false); }
  };

  const logout = () => { localStorage.clear(); router.push("/accountant/login"); };

  const waiting = queue.filter(tx => tx.status === "waiting");
  const s = selected ? (STATUS[selected.status] || STATUS.waiting) : null;

  return (
    <Layout hideNav={true}>
      <div className="min-h-screen" style={{ backgroundColor: colors.bg }}>
      {toast && <Toast msg={toast.msg} type={toast.type} onClose={() => setToast(null)} />}

      {/* Header */}
      <header className="border-b shadow-sm" style={{ backgroundColor: colors.bgSecondary, borderColor: colors.border }}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 py-4 flex justify-between items-center">
          <div className="flex items-center gap-3">
            <img src={LOGO} alt="Tsehay Bank" className="h-10 w-10 rounded-lg shadow" />
            <div>
              <span className="font-bold text-base" style={{ color: colors.text }}>{t("bank_name")}</span>
              <p className="text-xs" style={{ color: colors.textSecondary }}>Window Staff Portal</p>
            </div>
          </div>
          <div className="flex items-center gap-4">
            <div className="hidden sm:block text-right">
              <p className="text-sm font-semibold" style={{ color: colors.text }}>{user?.name}</p>
              <p className="text-xs" style={{ color: colors.textSecondary }}>Window Staff</p>
            </div>
            <button type="button" onClick={logout} className="px-4 py-2 rounded-lg font-semibold text-sm border transition hover:opacity-80" style={{ borderColor: colors.border, color: colors.textSecondary }}>
              {t("logout")}
            </button>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 py-6 grid grid-cols-1 lg:grid-cols-5 gap-6">

        {/* LEFT: Queue */}
        <Card className="lg:col-span-2 flex flex-col" noPadding>
          <div className="px-5 py-4 border-b flex items-center justify-between" style={{ borderColor: colors.border }}>
            <h2 className="font-bold" style={{ color: colors.text }}>{t("queue")}</h2>
            <Badge variant="gold">{waiting.length} {t("customers_waiting")}</Badge>
          </div>

          {queue.length === 0 ? (
            <div className="flex-1 flex flex-col items-center justify-center py-16">
              <p className="text-4xl mb-4">🎉</p>
              <p className="text-sm" style={{ color: colors.textSecondary }}>{t("queue")} is empty</p>
            </div>
          ) : (
            <ul className="flex-1 divide-y overflow-y-auto" style={{ "--tw-divide-color": colors.border } as React.CSSProperties}>
              {queue.map((tx, i) => {
                const st = STATUS[tx.status] || STATUS.waiting;
                const isSelected = selected?.id === tx.id;
                return (
                  <li key={tx.id} onClick={() => selectCustomer(tx)}
                    className="flex items-center gap-3 px-5 py-4 cursor-pointer transition-all hover:bg-gray-50"
                    style={{ backgroundColor: isSelected ? "#FEF3C7" : "transparent", borderLeft: isSelected ? `3px solid ${colors.accent}` : "3px solid transparent" }}>
                    <div className="w-9 h-9 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0" style={{ backgroundColor: colors.accent, color: "#FFFFFF" }}>
                      {i + 1}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold truncate" style={{ color: colors.text }}>{tx.user?.name || "Customer"}</p>
                      <p className="text-xs capitalize mt-0.5" style={{ color: colors.textSecondary }}>{tx.type} — {Number(tx.amount).toLocaleString()} ETB</p>
                      {tx.queue_number && <p className="text-xs font-bold mt-0.5" style={{ color: colors.accent }}>{tx.queue_number}</p>}
                    </div>
                    <span className="text-xs font-bold px-2 py-1 rounded-full flex-shrink-0" style={{ backgroundColor: st.bg, color: st.text }}>
                      {st.label}
                    </span>
                  </li>
                );
              })}
            </ul>
          )}
        </Card>

        {/* RIGHT: Detail + Receipt */}
        <div className="lg:col-span-3 flex flex-col gap-4">

          {/* Customer Detail */}
          <Card noPadding>
            <div className="px-6 py-4 border-b" style={{ borderColor: colors.border }}>
              <h2 className="font-bold" style={{ color: colors.text }}>Customer Details</h2>
              <p className="text-xs mt-1" style={{ color: colors.textSecondary }}>Click a customer from the queue to view their info</p>
            </div>

            {!selected ? (
              <div className="flex flex-col items-center justify-center py-16">
                <p className="text-5xl mb-4">👈</p>
                <p className="font-semibold text-sm" style={{ color: colors.textSecondary }}>No customer selected</p>
              </div>
            ) : (
              <div className="p-6 flex flex-col gap-5">
                {/* Photo + Status */}
                <div className="flex items-start gap-5">
                  {selected.photo_url ? (
                    <img src={selected.photo_url} alt="Customer" className="w-28 h-28 object-cover rounded-xl border-2 shadow-sm flex-shrink-0" style={{ borderColor: colors.border }} />
                  ) : (
                    <div className="w-28 h-28 rounded-xl flex items-center justify-center border-2 border-dashed border-gray-200 flex-shrink-0" style={{ backgroundColor: colors.bg }}>
                      <span className="text-4xl">👤</span>
                    </div>
                  )}
                  <div className="flex flex-col gap-2">
                    <p className="text-lg font-bold" style={{ color: colors.text }}>{selected.user?.name || "Customer"}</p>
                    {selected.queue_number && (
                      <Badge variant="gold">{t("queue_number")}: {selected.queue_number}</Badge>
                    )}
                    <span className="self-start px-3 py-1 rounded-full text-xs font-bold capitalize" style={{ backgroundColor: s.bg, color: s.text }}>
                      {s.label}
                    </span>
                    <p className="text-xs" style={{ color: colors.textSecondary }}>Submitted: {new Date(selected.created_at).toLocaleString()}</p>
                  </div>
                </div>

                {/* Signature */}
                {selected.signature_url && (
                  <div className="rounded-xl p-4 border" style={{ backgroundColor: colors.bg, borderColor: colors.border }}>
                    <p className="text-xs font-bold uppercase mb-3" style={{ color: colors.textSecondary }}>Customer Signature</p>
                    <img src={selected.signature_url} alt="Signature" className="h-20 object-contain rounded-lg border" style={{ borderColor: colors.border }} />
                  </div>
                )}

                {/* Info Grid */}
                <div className="rounded-xl p-4 border" style={{ backgroundColor: colors.bg, borderColor: colors.border }}>
                  <p className="text-xs font-bold uppercase mb-3" style={{ color: colors.textSecondary }}>{selected.type?.toUpperCase()} Details</p>
                  <div className="grid grid-cols-2 gap-x-6 gap-y-4">
                    <InfoRow label={t("account_holder")} value={selected.account_holder} />
                    <InfoRow label={t("account_number")} value={selected.account_number} />
                    <InfoRow label={t("amount")} value={`${Number(selected.amount).toLocaleString()} ETB`} />
                    <InfoRow label={t("amount_words")} value={selected.amount_words} />
                    <InfoRow label={t("deposited_by")} value={selected.deposited_by} />
                    <InfoRow label={t("date")} value={selected.date} />
                    {selected.to_account && <div className="col-span-2"><InfoRow label={t("recipient_account")} value={selected.to_account} /></div>}
                  </div>
                </div>

                {/* Action Buttons */}
                {(selected.status === "pending" || selected.status === "processing") && (
                  <button type="button" onClick={complete} disabled={loading}
                    className="w-full py-4 rounded-xl font-bold text-base transition-all hover:opacity-90 disabled:opacity-50"
                    style={{ backgroundColor: loading ? "#B8860B" : colors.accent, color: "#FFFFFF" }}>
                    {loading ? "Completing..." : t("complete")}
                  </button>
                )}
                {selected.status === "completed" && (
                  <div className="w-full py-4 rounded-xl font-bold text-sm text-center" style={{ backgroundColor: "#DCFCE7", color: "#166534", border: "1px solid #86EFAC" }}>
                    ✓ Transaction Completed
                  </div>
                )}
              </div>
            )}
          </Card>

          {/* Receipt Upload Panel */}
          {selected && (
            <Card>
              <h3 className="font-bold mb-4" style={{ color: colors.text }}>{t("send_receipt")}</h3>

              <div
                onClick={() => receiptRef.current?.click()}
                onPaste={handlePaste}
                className="border-2 border-dashed rounded-xl p-6 flex flex-col items-center cursor-pointer transition-all hover:border-opacity-80 mb-4"
                style={{ borderColor: colors.accent, backgroundColor: receiptPreview ? "#FFFBEB" : colors.bg }}>
                {receiptPreview ? (
                  <img src={receiptPreview} alt="receipt" className="h-44 object-contain rounded-xl" />
                ) : (
                  <>
                    <span className="text-4xl mb-3">🧾</span>
                    <span className="text-sm font-semibold" style={{ color: colors.accent }}>{t("upload_receipt")}</span>
                    <span className="text-xs mt-1" style={{ color: colors.textSecondary }}>Click to browse or paste from clipboard</span>
                  </>
                )}
              </div>
              <input ref={receiptRef} type="file" accept="image/*" className="hidden" onChange={handleReceiptFile} />

              <button
                type="button"
                onClick={sendReceipt}
                disabled={!receiptFile || sendingReceipt}
                className="w-full py-4 rounded-xl font-bold text-base transition-all hover:opacity-90 disabled:opacity-50"
                style={{ backgroundColor: (!receiptFile || sendingReceipt) ? "#E5E5E5" : colors.accent, color: (!receiptFile || sendingReceipt) ? "#999999" : "#FFFFFF" }}>
                {sendingReceipt ? (
                  <span className="flex items-center justify-center gap-2">
                    <LoadingSpinner size="sm" />
                    Sending...
                  </span>
                ) : t("send_receipt")}
              </button>
            </Card>
          )}
        </div>
      </div>
    </div>
    </Layout>
  );
}