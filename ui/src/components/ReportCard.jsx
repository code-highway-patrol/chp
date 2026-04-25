import { Link } from 'react-router-dom';

function ReportCard({ report }) {
  const date = new Date(report.timestamp);
  const formattedDate = date.toLocaleString();

  return (
    <div className="card">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h3>{formattedDate}</h3>
          <p style={{ color: '#666', fontSize: '0.875rem' }}>
            {report.files_checked || 0} files checked
          </p>
        </div>
        <div style={{ textAlign: 'right' }}>
          <div className={`badge ${report.total_block > 0 ? 'badge-error' : 'badge-success'}`}>
            {report.total_violations || 0} violations
          </div>
          {report.total_block > 0 && (
            <div style={{ marginTop: '0.5rem', color: '#721c24', fontSize: '0.875rem' }}>
              {report.total_block} blocked
            </div>
          )}
        </div>
      </div>
      {report.violations?.length > 0 && (
        <Link to={`/reports/${encodeURIComponent(report.timestamp)}`} className="btn btn-secondary btn-sm" style={{ marginTop: '1rem' }}>
          View Details
        </Link>
      )}
    </div>
  );
}

export default ReportCard;