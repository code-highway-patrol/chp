import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import LawTable from '../components/LawTable';
import ConfirmDialog from '../components/ConfirmDialog';

function Laws() {
  const [laws, setLaws] = useState([]);
  const [loading, setLoading] = useState(true);
  const [deleteTarget, setDeleteTarget] = useState(null);

  const loadLaws = () => {
    fetch('/api/laws')
      .then(r => r.json())
      .then(data => {
        setLaws(data);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  };

  useEffect(() => {
    loadLaws();
  }, []);

  const handleDelete = (name) => {
    setDeleteTarget(name);
  };

  const confirmDelete = () => {
    if (!deleteTarget) return;
    fetch(`/api/laws/${deleteTarget}`, { method: 'DELETE' })
      .then(() => {
        setDeleteTarget(null);
        loadLaws();
      });
  };

  if (loading) return <div className="loading">Loading...</div>;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <h1>Laws</h1>
        <Link to="/laws/new" className="btn btn-primary">Create Law</Link>
      </div>

      <div className="card">
        <LawTable laws={laws} onDelete={handleDelete} />
      </div>

      <ConfirmDialog
        isOpen={!!deleteTarget}
        title="Delete Law"
        message={`Are you sure you want to delete "${deleteTarget}"? This action cannot be undone.`}
        onConfirm={confirmDelete}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  );
}

export default Laws;