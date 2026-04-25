import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import ViolationList from '../components/ViolationList';

function ReportDetail() {
  const { id } = useParams();
  const [report, setReport] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const decodedId = decodeURIComponent(id);
    fetch('/api/reports')
      .then(r => r.json())
      .then(data => {
        const found = data.find(r => r.timestamp === decodedId);
        setReport(found || data[data.length - 1]);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, [id]);

  if (loading) return <div className="loading">Loading...</div>;
  if (!report) return <div className="error">Report not found</div>;

  const date = new Date(report.timestamp);

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <h1>Scan Report</h1>
        <Link to="/reports" className="btn btn-secondary">Back</Link>
      </div>

      <div className="card">
        <p style={{ color: '#666' }}>Scanned on {date.toLocaleString()}</p>
        <p style={{ marginTop: '0.5rem' }}>{report.files_checked || 0} files checked</p>
      </div>

      <div className="stats" style={{ marginTop: '1.5rem' }}>
        <div className="stat-card">
          <div className="stat-value">{report.total_violations || 0}</div>
          <div className="stat-label">Total Violations</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{report.total_block || 0}</div>
          <div className="stat-label">Blocked</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{report.total_warn || 0}</div>
          <div className="stat-label">Warnings</div>
        </div>
      </div>

      <div className="card" style={{ marginTop: '1.5rem' }}>
        <h2 style={{ marginBottom: '1rem' }}>Violations</h2>
        <ViolationList violations={report.violations} />
      </div>
    </div>
  );
}

export default ReportDetail;