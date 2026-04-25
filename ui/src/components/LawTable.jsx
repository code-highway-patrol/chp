import { Link } from 'react-router-dom';

function LawTable({ laws, onDelete }) {
  if (!laws || laws.length === 0) {
    return <p>No laws found. Create your first law!</p>;
  }

  return (
    <table>
      <thead>
        <tr>
          <th>Name</th>
          <th>Severity</th>
          <th>Failures</th>
          <th>Hooks</th>
          <th>Status</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        {laws.map(law => (
          <tr key={law.name}>
            <td>{law.name}</td>
            <td>
              <span className={`badge badge-${law.severity === 'error' ? 'error' : law.severity === 'warn' ? 'warn' : 'success'}`}>
                {law.severity}
              </span>
            </td>
            <td>{law.failures || 0}</td>
            <td>{law.hooks?.join(', ') || 'none'}</td>
            <td>
              <span className={`badge ${law.enabled ? 'badge-success' : 'badge-disabled'}`}>
                {law.enabled ? 'active' : 'disabled'}
              </span>
            </td>
            <td>
              <div className="actions">
                <Link to={`/laws/${law.name}/edit`} className="btn btn-secondary btn-sm">
                  Edit
                </Link>
                <button
                  className="btn btn-danger btn-sm"
                  onClick={() => onDelete(law.name)}
                >
                  Delete
                </button>
              </div>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

export default LawTable;