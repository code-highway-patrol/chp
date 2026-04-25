import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';

function Dashboard() {
  const [stats, setStats] = useState({ laws: [], report: null });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      fetch('/api/laws').then(r => r.json()),
      fetch('/api/reports/latest').then(r => r.ok ? r.json() : null)
    ]).then(([laws, report]) => {
      setStats({ laws, report });
      setLoading(false);
    }).catch(() => setLoading(false));
  }, []);

  if (loading) return <div className="loading">Loading...</div>;

  const enabledCount = stats.laws.filter(l => l.enabled).length;
  const disabledCount = stats.laws.length - enabledCount;

  return (
    <div>
      <h1>Dashboard</h1>

      <div className="stats">
        <div className="stat-card">
          <div className="stat-value">{stats.laws.length}</div>
          <div className="stat-label">Total Laws</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{enabledCount}</div>
          <div className="stat-label">Enabled</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{disabledCount}</div>
          <div className="stat-label">Disabled</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{stats.report?.total_violations || 0}</div>
          <div className="stat-label">Latest Violations</div>
        </div>
      </div>

      {stats.report?.violations?.length > 0 && (
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <h2>Latest Scan Results</h2>
            <Link to="/reports" className="btn btn-secondary btn-sm">View All</Link>
          </div>
          {stats.report.violations.slice(0, 5).map((v, i) => (
            <div key={i} style={{ padding: '0.75rem', borderBottom: '1px solid #eee' }}>
              <strong>{v.law}</strong>
              <span style={{ color: '#666', marginLeft: '1rem' }}>{v.file}</span>
            </div>
          ))}
          {stats.report.violations.length > 5 && (
            <p style={{ color: '#666', marginTop: '0.5rem' }}>...and {stats.report.violations.length - 5} more</p>
          )}
        </div>
      )}

      <div className="card">
        <h2 style={{ marginBottom: '1rem' }}>Quick Actions</h2>
        <div className="actions">
          <Link to="/laws/new" className="btn btn-primary">Create Law</Link>
          <button
            className="btn btn-secondary"
            onClick={() => fetch('/api/scan', { method: 'POST' }).then(() => window.location.reload())}
          >
            Run Scan
          </button>
        </div>
      </div>
    </div>
  );
}

export default Dashboard;