import { useState, useEffect } from 'react';
import ReportCard from '../components/ReportCard';

function Reports() {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [scanning, setScanning] = useState(false);

  const loadReports = () => {
    fetch('/api/reports')
      .then(r => r.json())
      .then(data => {
        setReports(data);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  };

  useEffect(() => {
    loadReports();
  }, []);

  const handleScan = async () => {
    setScanning(true);
    try {
      await fetch('/api/scan', { method: 'POST' });
      loadReports();
    } finally {
      setScanning(false);
    }
  };

  if (loading) return <div className="loading">Loading...</div>;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <h1>Scan Reports</h1>
        <button className="btn btn-primary" onClick={handleScan} disabled={scanning}>
          {scanning ? 'Scanning...' : 'Run Scan'}
        </button>
      </div>

      {reports.length === 0 ? (
        <div className="card">
          <p>No scan reports yet. Run a scan to see results.</p>
        </div>
      ) : (
        <div>
          {reports.map((report, i) => (
            <ReportCard key={i} report={report} />
          ))}
        </div>
      )}
    </div>
  );
}

export default Reports;