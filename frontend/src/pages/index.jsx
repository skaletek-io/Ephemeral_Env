import { useState, useEffect } from 'react';

const API = '/api';

async function apiFetch(path, options = {}) {
  const res = await fetch(`${API}${path}`, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  });
  if (res.status === 204) return null;
  const data = await res.json();
  if (!res.ok) throw new Error(data.error || 'Request failed');
  return data;
}

export default function Home() {
  const [users, setUsers]       = useState([]);
  const [health, setHealth]     = useState(null);
  const [loading, setLoading]   = useState(true);
  const [error, setError]       = useState('');
  const [form, setForm]         = useState({ name: '', email: '' });
  const [submitting, setSubmitting] = useState(false);
  const [toast, setToast]       = useState('');
  const dbHealthy = health?.status === 'ok' || health?.status === 'healthy';
  const commitSha = (process.env.NEXT_PUBLIC_COMMIT_SHA || 'local').slice(0, 7);

  function showToast(msg) {
    setToast(msg);
    setTimeout(() => setToast(''), 3000);
  }

  async function loadData() {
    try {
      const [usersData, healthData] = await Promise.all([
        apiFetch('/users'),
        apiFetch('/health'),
      ]);
      setUsers(usersData || []);
      setHealth(healthData);
      setError('');
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { loadData(); }, []);

  async function handleCreate(e) {
    e.preventDefault();
    if (!form.name.trim() || !form.email.trim()) return;
    setSubmitting(true);
    try {
      const user = await apiFetch('/users', {
        method: 'POST',
        body: JSON.stringify(form),
      });
      setUsers(prev => [...prev, user]);
      setForm({ name: '', email: '' });
      showToast(`User "${user.name}" created`);
    } catch (e) {
      setError(e.message);
    } finally {
      setSubmitting(false);
    }
  }

  async function handleDelete(id, name) {
    if (!confirm(`Delete "${name}"?`)) return;
    try {
      await apiFetch(`/users/${id}`, { method: 'DELETE' });
      setUsers(prev => prev.filter(u => u.id !== id));
      showToast(`User "${name}" deleted`);
    } catch (e) {
      setError(e.message);
    }
  }

  return (
    <div style={styles.page}>

      {/* Toast */}
      {toast && <div style={styles.toast}>{toast}</div>}

      {/* Header */}
      <header style={styles.header}>
        <div style={styles.headerInner}>
          <h1 style={styles.title}>🚀 Simple App</h1>
          <div style={styles.healthBadge(dbHealthy)}>
            {health ? (dbHealthy ? '● DB connected' : '● DB error') : '○ checking...'}
          </div>
        </div>
      </header>

      <main style={styles.main}>

        {/* Error banner */}
        {error && (
          <div style={styles.errorBanner}>
            ⚠ {error}
            <button onClick={() => setError('')} style={styles.errorClose}>✕</button>
          </div>
        )}

        {/* Stats row */}
        <div style={styles.statsRow}>
          <StatCard label="Total Users" value={users.length} color="#6366f1" />
          <StatCard label="DB Status"   value={health?.status || '...'} color={dbHealthy ? '#10b981' : '#ef4444'} />
          <StatCard label="Environment" value={process.env.NEXT_PUBLIC_ENV_NAME || process.env.NODE_ENV || 'local'} color="#f59e0b" />
          <StatCard label="Commit"      value={commitSha} color="#19cae6" />
        </div>

        <div style={styles.grid}>

          {/* Create user form */}
          <section style={styles.card}>
            <h2 style={styles.cardTitle}>Add User</h2>
            <form onSubmit={handleCreate} style={styles.form}>
              <label style={styles.label}>Name</label>
              <input
                style={styles.input}
                placeholder="Alice Martin"
                value={form.name}
                onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                required
              />
              <label style={styles.label}>Email</label>
              <input
                style={styles.input}
                type="email"
                placeholder="alice@example.com"
                value={form.email}
                onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
                required
              />
              <button style={styles.btn(submitting)} type="submit" disabled={submitting}>
                {submitting ? 'Creating...' : '+ Create User'}
              </button>
            </form>
          </section>

          {/* Users table */}
          <section style={styles.card}>
            <div style={styles.cardHeader}>
              <h2 style={styles.cardTitle}>Users</h2>
              <button style={styles.refreshBtn} onClick={loadData}>↻ Refresh</button>
            </div>
            {loading ? (
              <p style={styles.muted}>Loading...</p>
            ) : users.length === 0 ? (
              <p style={styles.muted}>No users yet. Create one!</p>
            ) : (
              <table style={styles.table}>
                <thead>
                  <tr>
                    <th style={styles.th}>ID</th>
                    <th style={styles.th}>Name</th>
                    <th style={styles.th}>Email</th>
                    <th style={styles.th}>Created</th>
                    <th style={styles.th}></th>
                  </tr>
                </thead>
                <tbody>
                  {users.map(u => (
                    <tr key={u.id} style={styles.tr}>
                      <td style={styles.td}><span style={styles.idBadge}>#{u.id}</span></td>
                      <td style={styles.tdBold}>{u.name}</td>
                      <td style={styles.tdMuted}>{u.email}</td>
                      <td style={styles.tdMuted}>{new Date(u.created_at).toLocaleDateString()}</td>
                      <td style={styles.td}>
                        <button style={styles.deleteBtn} onClick={() => handleDelete(u.id, u.name)}>✕</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </section>

        </div>

        {/* API cheatsheet */}
        <section style={styles.card}>
          <h2 style={styles.cardTitle}>API Endpoints</h2>
          <div style={styles.endpoints}>
            {[
              { method: 'GET',    color: '#10b981', path: '/api/health',      desc: 'Health check' },
              { method: 'GET',    color: '#10b981', path: '/api/users',       desc: 'List all users' },
              { method: 'POST',   color: '#6366f1', path: '/api/users',       desc: 'Create user  { name, email }' },
              { method: 'DELETE', color: '#ef4444', path: '/api/users/:id',   desc: 'Delete user by ID' },
            ].map(e => (
              <div key={e.path + e.method} style={styles.endpoint}>
                <span style={styles.methodBadge(e.color)}>{e.method}</span>
                <code style={styles.path}>{e.path}</code>
                <span style={styles.desc}>{e.desc}</span>
              </div>
            ))}
          </div>
        </section>

      </main>
    </div>
  );
}

function StatCard({ label, value, color }) {
  return (
    <div style={styles.statCard(color)}>
      <div style={styles.statValue(color)}>{value}</div>
      <div style={styles.statLabel}>{label}</div>
    </div>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = {
  page: { minHeight: '100vh', background: '#0f172a', color: '#e2e8f0', fontFamily: 'system-ui, sans-serif' },
  toast: { position: 'fixed', bottom: 24, right: 24, background: '#10b981', color: '#fff', padding: '12px 20px', borderRadius: 8, zIndex: 1000, fontSize: 14, boxShadow: '0 4px 12px rgba(0,0,0,0.3)' },
  header: { background: '#1e293b', borderBottom: '1px solid #334155', padding: '0 24px' },
  headerInner: { maxWidth: 1100, margin: '0 auto', display: 'flex', alignItems: 'center', justifyContent: 'space-between', height: 60 },
  title: { margin: 0, fontSize: 20, fontWeight: 700, color: '#f1f5f9' },
  branchMarker: { marginTop: 4, fontSize: 12, color: '#93c5fd' },
  healthBadge: ok => ({ fontSize: 13, padding: '4px 12px', borderRadius: 20, background: ok ? '#064e3b' : '#450a0a', color: ok ? '#6ee7b7' : '#fca5a5' }),
  main: { maxWidth: 1100, margin: '0 auto', padding: '32px 24px' },
  errorBanner: { background: '#450a0a', border: '1px solid #991b1b', color: '#fca5a5', padding: '12px 16px', borderRadius: 8, marginBottom: 24, display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 14 },
  errorClose: { background: 'none', border: 'none', color: '#fca5a5', cursor: 'pointer', fontSize: 16 },
  statsRow: { display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 24 },
  statCard: color => ({ background: '#1e293b', border: `1px solid ${color}30`, borderRadius: 12, padding: '20px 24px' }),
  statValue: color => ({ fontSize: 28, fontWeight: 700, color, marginBottom: 4 }),
  statLabel: { fontSize: 13, color: '#94a3b8' },
  grid: { display: 'grid', gridTemplateColumns: '320px 1fr', gap: 20, marginBottom: 20, alignItems: 'start' },
  card: { background: '#1e293b', border: '1px solid #334155', borderRadius: 12, padding: 24 },
  cardHeader: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 },
  cardTitle: { margin: '0 0 16px', fontSize: 16, fontWeight: 600, color: '#f1f5f9' },
  form: { display: 'flex', flexDirection: 'column', gap: 12 },
  label: { fontSize: 13, color: '#94a3b8', marginBottom: -4 },
  input: { background: '#0f172a', border: '1px solid #334155', borderRadius: 8, padding: '10px 14px', color: '#e2e8f0', fontSize: 14, outline: 'none' },
  btn: disabled => ({ background: disabled ? '#374151' : '#6366f1', color: '#fff', border: 'none', borderRadius: 8, padding: '11px 0', fontSize: 14, fontWeight: 600, cursor: disabled ? 'not-allowed' : 'pointer', marginTop: 4 }),
  refreshBtn: { background: 'none', border: '1px solid #334155', color: '#94a3b8', borderRadius: 6, padding: '4px 12px', fontSize: 13, cursor: 'pointer' },
  muted: { color: '#64748b', fontSize: 14 },
  table: { width: '100%', borderCollapse: 'collapse', fontSize: 14 },
  th: { textAlign: 'left', padding: '8px 12px', color: '#64748b', fontSize: 12, fontWeight: 600, textTransform: 'uppercase', borderBottom: '1px solid #334155' },
  tr: { borderBottom: '1px solid #1e293b' },
  td: { padding: '10px 12px', color: '#94a3b8' },
  tdBold: { padding: '10px 12px', color: '#e2e8f0', fontWeight: 500 },
  tdMuted: { padding: '10px 12px', color: '#64748b' },
  idBadge: { background: '#1e293b', border: '1px solid #334155', borderRadius: 4, padding: '2px 6px', fontSize: 12 },
  deleteBtn: { background: 'none', border: 'none', color: '#64748b', cursor: 'pointer', fontSize: 14, padding: '2px 6px', borderRadius: 4 },
  endpoints: { display: 'flex', flexDirection: 'column', gap: 10 },
  endpoint: { display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0', borderBottom: '1px solid #1e293b' },
  methodBadge: color => ({ background: `${color}20`, color, border: `1px solid ${color}40`, borderRadius: 4, padding: '2px 8px', fontSize: 12, fontWeight: 700, minWidth: 64, textAlign: 'center' }),
  path: { background: '#0f172a', borderRadius: 4, padding: '2px 8px', fontSize: 13, color: '#7dd3fc', fontFamily: 'monospace' },
  desc: { color: '#64748b', fontSize: 13 },
};
