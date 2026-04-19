"use client";
import { useState, useEffect } from "react";
import API from "@/lib/api";
import { useRouter } from "next/navigation";
import { useLang } from "@/lib/lang";
import { useTheme, Card, Badge, EmptyState, LoadingSpinner, Layout } from "@/components/Layout";

const LOGO = "https://play-lh.googleusercontent.com/UwdS4yhwiOTa5Uq_L2JdZb82iQoQbaKR-gJWUAp4Ri4SyXz_CdP0ei3BCdRF60h0SQ=w240-h480-rw";

const NAV = [
  { id: "overview", key: "dashboard", icon: "📊" },
  { id: "accountants", key: "staff", icon: "👥" },
  { id: "live_queue", key: "live_queue", icon: "📋" },
  { id: "transactions", key: "transactions", icon: "💱" },
  { id: "settings", key: "settings", icon: "⚙️" },
  { id: "profile", key: "profile", icon: "👤" },
];

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

function Field({ label, children }) {
  const { colors } = useTheme();
  return (
    <div>
      <label className="block text-xs font-bold uppercase mb-2" style={{ color: colors.textSecondary }}>{label}</label>
      {children}
    </div>
  );
}

const inputCls = "w-full border rounded-lg px-4 py-3 text-sm focus:outline-none focus:ring-2 transition-all";

export default function ManagerDashboard() {
  const router = useRouter();
  const { t } = useLang();
  const { colors } = useTheme();
  const [user, setUser] = useState(null);
  const [tab, setTab] = useState("overview");
  const [accountants, setAccountants] = useState([]);
  const [windows, setWindows] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [totals, setTotals] = useState<{ deposit?: number; withdraw?: number; transfer?: number; count?: number }>({});
  const [period, setPeriod] = useState("daily");
  const [txType, setTxType] = useState("all");
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState(null);
  const [accForm, setAccForm] = useState({ name: "", email: "", password: "", window: "" });
  const [profileForm, setProfileForm] = useState({ name: "", password: "" });
  const [settingsForm, setSettingsForm] = useState({ withdraw_min: "100", withdraw_max: "50000" });
  const [liveQueue, setLiveQueue] = useState([]);

  const showToast = (msg, type = "info") => setToast({ msg, type });

  useEffect(() => {
    const u = localStorage.getItem("user");
    if (!u) { router.push("/manager/login"); return; }
    const parsed = JSON.parse(u);
    if (parsed.role !== "admin") { router.push("/manager/login"); return; }
    setUser(parsed);
    setProfileForm({ name: parsed.name, password: "" });
    fetchAll();
    API.get("/admin/settings").then(r => setSettingsForm(r.data)).catch(() => {});
  }, []);

  useEffect(() => { if (user) fetchTransactions(); }, [period, txType]);

  const fetchAll = () => { fetchAccountants(); fetchWindows(); fetchTransactions(); fetchLiveQueue(); };

  const fetchLiveQueue = async () => {
    try { const r = await API.get("/admin/live-queue"); setLiveQueue(r.data); } catch {}
  };

  const fetchAccountants = async () => {
    try { const r = await API.get("/accountants"); setAccountants(r.data); } catch {}
  };
  const fetchWindows = async () => {
    try { const r = await API.get("/windows"); setWindows(r.data); } catch {}
  };
  const fetchTransactions = async () => {
    try {
      const r = await API.get(`/transactions/${period}?type=${txType}`);
      setTransactions(r.data.transactions || []);
      setTotals(r.data.totals || {});
    } catch {}
  };

  const addAccountant = async (e) => {
    e.preventDefault(); setLoading(true);
    try {
      await API.post("/accountants", accForm);
      showToast("Accountant added successfully!", "success");
      setAccForm({ name: "", email: "", password: "", window: "" });
      fetchAll();
    } catch (err) { showToast(err.response?.data?.message || "Error", "error"); }
    finally { setLoading(false); }
  };

  const deleteAccountant = async (id) => {
    if (!confirm("Delete this accountant?")) return;
    try { await API.delete(`/accountants/${id}`); showToast("Deleted.", "success"); fetchAll(); }
    catch { showToast("Error deleting.", "error"); }
  };

  const updateProfile = async (e) => {
    e.preventDefault(); setLoading(true);
    try {
      const r = await API.put("/admin/profile", profileForm);
      localStorage.setItem("user", JSON.stringify(r.data.user));
      setUser(r.data.user);
      showToast("Profile updated!", "success");
      setProfileForm({ name: r.data.user.name, password: "" });
    } catch (err) { showToast(err.response?.data?.message || "Error", "error"); }
    finally { setLoading(false); }
  };

  const saveSettings = async (e) => {
    e.preventDefault(); setLoading(true);
    try {
      await API.post("/admin/settings", settingsForm);
      showToast("Settings saved!", "success");
    } catch (err) { showToast(err.response?.data?.message || "Error", "error"); }
    finally { setLoading(false); }
  };

  const logout = () => { localStorage.clear(); router.push("/manager/login"); };

  const totalVolume = (totals.deposit || 0) + (totals.withdraw || 0) + (totals.transfer || 0);

  const StatCard = ({ label, value, sublabel }: { label: string; value: string; sublabel: string }) => (
    <Card className="hover:shadow-lg transition-shadow">
      <p className="text-xs font-bold uppercase mb-2" style={{ color: colors.textSecondary }}>{label}</p>
      <p className="text-2xl font-bold" style={{ color: colors.text }}>{value}</p>
      <p className="text-xs mt-1" style={{ color: colors.textSecondary }}>{sublabel}</p>
    </Card>
  );

  return (
    <Layout>
      <div className="min-h-screen flex" style={{ backgroundColor: colors.bg }}>
      {toast && <Toast msg={toast.msg} type={toast.type} onClose={() => setToast(null)} />}

      {/* Sidebar */}
      <aside className="w-64 flex flex-col border-r transition-all" style={{ backgroundColor: colors.bgSecondary, borderColor: colors.border }}>
        <div className="p-5 border-b flex items-center gap-3" style={{ borderColor: colors.border }}>
          <img src={LOGO} alt="Tsehay Bank" className="h-9 w-9 rounded-lg shadow" />
          <div>
            <span className="font-bold text-sm block" style={{ color: colors.text }}>{t("bank_name")}</span>
            <span className="text-xs" style={{ color: colors.textSecondary }}>Management</span>
          </div>
        </div>
        <nav className="flex-1 p-3 space-y-1">
          {NAV.map(n => (
            <button type="button" key={n.id} onClick={() => setTab(n.id)}
              className="w-full text-left px-4 py-3 rounded-xl text-sm font-medium transition-all flex items-center gap-3"
              style={tab === n.id
                ? { backgroundColor: colors.accent, color: "#FFFFFF", boxShadow: "0 2px 8px rgba(212, 175, 55, 0.3)" }
                : { color: colors.textSecondary }
              }>
              <span>{n.icon}</span>
              <span>{t(n.key)}</span>
            </button>
          ))}
        </nav>
        <div className="p-4 border-t" style={{ borderColor: colors.border }}>
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 rounded-full flex items-center justify-center text-white font-bold" style={{ backgroundColor: colors.accent }}>
              {user?.name?.charAt(0)?.toUpperCase()}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold truncate" style={{ color: colors.text }}>{user?.name}</p>
              <p className="text-xs truncate" style={{ color: colors.textSecondary }}>{user?.email}</p>
            </div>
          </div>
          <button type="button" onClick={logout} className="w-full py-2.5 rounded-lg text-sm font-semibold border transition hover:opacity-80" style={{ borderColor: colors.border, color: colors.textSecondary }}>
            {t("logout")}
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 p-8 overflow-auto">
        {/* OVERVIEW */}
        {tab === "overview" && (
          <div className="space-y-6">
            <h1 className="text-2xl font-bold" style={{ color: colors.text }}>Dashboard</h1>

            {/* 3 Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <StatCard label="Deposits" value={`${Number(totals.deposit || 0).toLocaleString()}`} sublabel="ETB — Today" />
              <StatCard label="Withdrawals" value={`${Number(totals.withdraw || 0).toLocaleString()}`} sublabel="ETB — Today" />
              <StatCard label="Transfers" value={`${Number(totals.transfer || 0).toLocaleString()}`} sublabel="ETB — Today" />
            </div>

            {/* Recent Transactions Table */}
            <Card noPadding>
              <div className="px-6 py-4 border-b" style={{ borderColor: colors.border }}>
                <h2 className="font-bold" style={{ color: colors.text }}>Recent Transactions</h2>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead style={{ backgroundColor: colors.bg }}>
                    <tr>
                      {["#", "Type", "Amount", "Account", "Status", "Date"].map(h => (
                        <th key={h} className="px-4 py-3 text-left text-xs font-bold uppercase" style={{ color: colors.textSecondary }}>{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="divide-y" style={{ "--tw-divide-color": colors.border } as React.CSSProperties}>
                    {transactions.slice(0, 10).length === 0 && (
                      <tr><td colSpan={6} className="text-center py-8 text-sm" style={{ color: colors.textSecondary }}>No transactions found.</td></tr>
                    )}
                    {transactions.slice(0, 10).map((t, i) => (
                      <tr key={t.id || i} className="hover:bg-gray-50">
                        <td className="px-4 py-3" style={{ color: colors.textSecondary }}>{i + 1}</td>
                        <td className="px-4 py-3 capitalize font-semibold" style={{ color: colors.text }}>{t.type}</td>
                        <td className="px-4 py-3 font-semibold" style={{ color: colors.text }}>{Number(t.amount).toLocaleString()} ETB</td>
                        <td className="px-4 py-3" style={{ color: colors.textSecondary }}>{t.account_number || "—"}</td>
                        <td className="px-4 py-3 capitalize" style={{ color: colors.textSecondary }}>{t.status}</td>
                        <td className="px-4 py-3" style={{ color: colors.textSecondary }}>{new Date(t.created_at).toLocaleDateString()}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </Card>
          </div>
        )}

        {/* ADD WINDOW / ACCOUNTANTS */}
        {tab === "accountants" && (
          <div className="space-y-6 max-w-2xl">
            <h1 className="text-2xl font-bold" style={{ color: colors.text }}>Add Window Staff</h1>

            <Card>
              <form onSubmit={addAccountant} className="space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <Field label="Full Name">
                    <input className={inputCls} placeholder="Full Name" value={accForm.name} onChange={e => setAccForm({ ...accForm, name: e.target.value })} required 
                      style={{ backgroundColor: colors.bg, borderColor: colors.border, color: colors.text }} />
                  </Field>
                  <Field label="Email">
                    <input className={inputCls} type="email" placeholder="Email" value={accForm.email} onChange={e => setAccForm({ ...accForm, email: e.target.value })} required 
                      style={{ backgroundColor: colors.bg, borderColor: colors.border, color: colors.text }} />
                  </Field>
                  <Field label="Password">
                    <input className={inputCls} type="password" placeholder="Password" value={accForm.password} onChange={e => setAccForm({ ...accForm, password: e.target.value })} required 
                      style={{ backgroundColor: colors.bg, borderColor: colors.border, color: colors.text }} />
                  </Field>
                  <Field label="Assign Window (optional)">
                    <input className={inputCls} placeholder="e.g. Window 1" value={accForm.window} onChange={e => setAccForm({ ...accForm, window: e.target.value })} 
                      style={{ backgroundColor: colors.bg, borderColor: colors.border, color: colors.text }} />
                  </Field>
                </div>
                <button type="submit" disabled={loading} className="w-full py-4 rounded-xl font-bold text-base transition-all hover:opacity-90 disabled:opacity-50"
                  style={{ backgroundColor: colors.accent, color: "#FFFFFF" }}>
                  {loading ? "Adding..." : "Add Staff Member"}
                </button>
              </form>
            </Card>

            <Card noPadding>
              <div className="px-6 py-4 border-b" style={{ borderColor: colors.border }}>
                <h2 className="font-bold" style={{ color: colors.text }}>All Window Staff ({accountants.length})</h2>
              </div>
              {accountants.length === 0 ? (
                <div className="p-8 text-center text-sm" style={{ color: colors.textSecondary }}>No staff members yet.</div>
              ) : (
                <table className="w-full text-sm">
                  <thead style={{ backgroundColor: colors.bg }}>
                    <tr>
                      {["#", "Name", "Email", "Window", "Action"].map(h => (
                        <th key={h} className="px-4 py-3 text-left text-xs font-bold uppercase" style={{ color: colors.textSecondary }}>{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="divide-y" style={{ "--tw-divide-color": colors.border } as React.CSSProperties}>
                    {accountants.map((a, i) => (
                      <tr key={a.id} className="hover:bg-gray-50">
                        <td className="px-4 py-3" style={{ color: colors.textSecondary }}>{i + 1}</td>
                        <td className="px-4 py-3 font-semibold" style={{ color: colors.text }}>{a.name}</td>
                        <td className="px-4 py-3" style={{ color: colors.textSecondary }}>{a.email}</td>
                        <td className="px-4 py-3">
                          {a.window
                            ? <Badge variant="gold">{a.window.name}</Badge>
                            : <span className="text-xs" style={{ color: colors.textSecondary }}>Unassigned</span>
                          }
                        </td>
                        <td className="px-4 py-3">
                          <button type="button" onClick={() => deleteAccountant(a.id)} className="text-xs font-semibold px-3 py-1.5 rounded-lg transition" style={{ backgroundColor: "#FEE2E2", color: "#B91C1C" }}>
                            Delete
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </Card>
          </div>
        )}

        {/* TRANSACTIONS */}
        {tab === "transactions" && (
          <div className="space-y-6">
            <h1 className="text-2xl font-bold" style={{ color: colors.text }}>Transactions</h1>

            {/* Filters */}
            <Card>
              <div className="flex flex-wrap gap-3 items-center">
                <div className="flex gap-2 flex-wrap">
                  {["daily", "weekly", "monthly", "yearly"].map(p => (
                    <button type="button" key={p} onClick={() => setPeriod(p)}
                      className="px-4 py-2 rounded-lg text-sm font-semibold capitalize transition-all"
                      style={period === p ? { backgroundColor: colors.accent, color: "#FFFFFF" } : { backgroundColor: colors.bg, color: colors.textSecondary }}>
                      {p}
                    </button>
                  ))}
                </div>
                <div className="flex gap-2 flex-wrap ml-auto">
                  {["all", "deposit", "withdraw", "transfer"].map(t => (
                    <button type="button" key={t} onClick={() => setTxType(t)}
                      className="px-4 py-2 rounded-lg text-sm font-semibold capitalize transition-all"
                      style={txType === t ? { backgroundColor: colors.blue, color: "#FFFFFF" } : { backgroundColor: colors.bg, color: colors.textSecondary }}>
                      {t}
                    </button>
                  ))}
                </div>
              </div>
            </Card>

            {/* Summary Cards */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {[
                { label: "Total Count", value: totals.count || 0 },
                { label: "Deposits", value: `${Number(totals.deposit || 0).toLocaleString()} ETB` },
                { label: "Withdrawals", value: `${Number(totals.withdraw || 0).toLocaleString()} ETB` },
                { label: "Transfers", value: `${Number(totals.transfer || 0).toLocaleString()} ETB` },
              ].map(c => (
                <Card key={c.label} className="text-center">
                  <p className="text-xl font-bold" style={{ color: colors.text }}>{c.value}</p>
                  <p className="text-xs font-semibold mt-1" style={{ color: colors.textSecondary }}>{c.label}</p>
                </Card>
              ))}
            </div>

            {/* Table */}
            <Card noPadding>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead style={{ backgroundColor: colors.bg }}>
                    <tr>
                      {["#", "Type", "Amount", "Account", "Status", "Date"].map(h => (
                        <th key={h} className="px-4 py-3 text-left text-xs font-bold uppercase" style={{ color: colors.textSecondary }}>{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="divide-y" style={{ "--tw-divide-color": colors.border } as React.CSSProperties}>
                    {transactions.length === 0 && (
                      <tr><td colSpan={6} className="text-center py-8 text-sm" style={{ color: colors.textSecondary }}>No transactions found.</td></tr>
                    )}
                    {transactions.map((t, i) => (
                      <tr key={t.id || i} className="hover:bg-gray-50">
                        <td className="px-4 py-3" style={{ color: colors.textSecondary }}>{i + 1}</td>
                        <td className="px-4 py-3 capitalize font-semibold" style={{ color: colors.text }}>{t.type}</td>
                        <td className="px-4 py-3 font-semibold" style={{ color: colors.text }}>{Number(t.amount).toLocaleString()} ETB</td>
                        <td className="px-4 py-3" style={{ color: colors.textSecondary }}>{t.account_number || "—"}</td>
                        <td className="px-4 py-3 capitalize" style={{ color: colors.textSecondary }}>{t.status}</td>
                        <td className="px-4 py-3" style={{ color: colors.textSecondary }}>{new Date(t.created_at).toLocaleString()}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </Card>
          </div>
        )}

        {/* LIVE QUEUE */}
        {tab === "live_queue" && (
          <div className="space-y-6">
            <div className="flex items-center justify-between">
              <h1 className="text-2xl font-bold" style={{ color: colors.text }}>Live Queue</h1>
              <button type="button" onClick={fetchLiveQueue} className="px-4 py-2 rounded-lg font-semibold text-sm border transition hover:opacity-80" style={{ borderColor: colors.accent, color: colors.accent }}>
                ↻ Refresh
              </button>
            </div>
            {liveQueue.length === 0 ? (
              <EmptyState icon="🎉" title="No active queues" description="All windows are free." />
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {liveQueue.map(w => (
                  <Card key={w.id} noPadding>
                    <div className="px-5 py-4 border-b flex items-center justify-between" style={{ borderColor: colors.border, backgroundColor: "#FEF3C7" }}>
                      <div>
                        <p className="font-bold" style={{ color: colors.text }}>{w.name}</p>
                        <p className="text-xs" style={{ color: colors.textSecondary }}>Staff: {w.accountant?.name || "Unassigned"}</p>
                      </div>
                      <Badge variant="gold">{w.transactions?.length || 0} in queue</Badge>
                    </div>
                    {(!w.transactions || w.transactions.length === 0) ? (
                      <p className="text-center py-6 text-sm" style={{ color: colors.textSecondary }}>Queue is empty</p>
                      ) : (
                      <ul className="divide-y" style={{ "--tw-divide-color": colors.border } as React.CSSProperties}>
                        {w.transactions.map((tx, i) => (
                          <li key={tx.id} className="flex items-center gap-3 px-5 py-3">
                            <span className="w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0" style={{ backgroundColor: colors.accent, color: "#FFFFFF" }}>{i + 1}</span>
                            <div className="flex-1 min-w-0">
                              <p className="text-sm font-semibold truncate" style={{ color: colors.text }}>{tx.user?.name || "Customer"}</p>
                              <p className="text-xs capitalize" style={{ color: colors.textSecondary }}>{tx.type} · {Number(tx.amount).toLocaleString()} ETB</p>
                            </div>
                            <span className="text-xs font-semibold" style={{ color: tx.status === "pending" ? colors.accent : colors.textSecondary }}>{tx.status}</span>
                          </li>
                        ))}
                      </ul>
                    )}
                  </Card>
                ))}
              </div>
            )}
          </div>
        )}

        {/* SETTINGS */}
        {tab === "settings" && (
          <div className="max-w-md">
            <h1 className="text-2xl font-bold mb-6" style={{ color: colors.text }}>{t("settings")}</h1>
            <Card>
              <h2 className="font-bold mb-4" style={{ color: colors.text }}>{t("withdraw_limits")}</h2>
              <form onSubmit={saveSettings} className="space-y-4">
                <Field label={t("min_amount")}>
                  <input className={inputCls} type="number" min="1" value={settingsForm.withdraw_min}
                    onChange={e => setSettingsForm({ ...settingsForm, withdraw_min: e.target.value })} required 
                    style={{ backgroundColor: colors.bg, borderColor: colors.border, color: colors.text }} />
                </Field>
                <Field label={t("max_amount")}>
                  <input className={inputCls} type="number" min="1" value={settingsForm.withdraw_max}
                    onChange={e => setSettingsForm({ ...settingsForm, withdraw_max: e.target.value })} required 
                    style={{ backgroundColor: colors.bg, borderColor: colors.border, color: colors.text }} />
                </Field>
                <button type="submit" disabled={loading} className="w-full py-4 rounded-xl font-bold text-base transition-all hover:opacity-90 disabled:opacity-50"
                  style={{ backgroundColor: colors.accent, color: "#FFFFFF" }}>
                  {loading ? "Saving..." : t("save")}
                </button>
              </form>
            </Card>
          </div>
        )}

        {/* PROFILE */}
        {tab === "profile" && (
          <div className="max-w-md">
            <h1 className="text-2xl font-bold mb-6" style={{ color: colors.text }}>Profile</h1>
            <Card>
              <div className="flex items-center gap-4 mb-6 pb-5 border-b" style={{ borderColor: colors.border }}>
                <div className="w-16 h-16 rounded-full flex items-center justify-center text-white text-xl font-bold" style={{ backgroundColor: colors.accent }}>
                  {user?.name?.charAt(0)?.toUpperCase()}
                </div>
                <div>
                  <p className="font-bold text-lg" style={{ color: colors.text }}>{user?.name}</p>
                  <p className="text-sm" style={{ color: colors.textSecondary }}>{user?.email}</p>
                  <Badge variant="gold">Super Admin</Badge>
                </div>
              </div>
              <form onSubmit={updateProfile} className="space-y-4">
                <Field label="Full Name">
                  <input className={inputCls} value={profileForm.name} onChange={e => setProfileForm({ ...profileForm, name: e.target.value })} 
                    style={{ backgroundColor: colors.bg, borderColor: colors.border, color: colors.text }} />
                </Field>
                <Field label="New Password">
                  <input className={inputCls} type="password" placeholder="Leave blank to keep current" value={profileForm.password} onChange={e => setProfileForm({ ...profileForm, password: e.target.value })} 
                    style={{ backgroundColor: colors.bg, borderColor: colors.border, color: colors.text }} />
                </Field>
                <button type="submit" disabled={loading} className="w-full py-4 rounded-xl font-bold text-base transition-all hover:opacity-90 disabled:opacity-50"
                  style={{ backgroundColor: colors.accent, color: "#FFFFFF" }}>
                  {loading ? "Saving..." : "Save Changes"}
                </button>
              </form>
            </Card>
          </div>
        )}
      </main>
    </div>
    </Layout>
  );
}