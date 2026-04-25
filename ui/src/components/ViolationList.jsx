function ViolationList({ violations }) {
  if (!violations || violations.length === 0) {
    return <p>No violations found.</p>;
  }

  return (
    <div>
      {violations.map((v, i) => (
        <div key={i} className="violation-item">
          <div className="violation-law">{v.law}</div>
          <div className="violation-file">{v.file}:{v.line}</div>
          {v.intent && <p style={{ marginTop: '0.5rem' }}>{v.intent}</p>}
          {v.snippet && (
            <pre className="violation-snippet">{v.snippet}</pre>
          )}
          <div style={{ marginTop: '0.5rem' }}>
            <span className={`badge badge-${v.reaction === 'block' ? 'error' : 'warn'}`}>
              {v.reaction}
            </span>
          </div>
        </div>
      ))}
    </div>
  );
}

export default ViolationList;