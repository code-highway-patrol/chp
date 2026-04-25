import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import LawForm from '../components/LawForm';

function LawEdit() {
  const { name } = useParams();
  const navigate = useNavigate();
  const [law, setLaw] = useState(null);
  const [loading, setLoading] = useState(!!name);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (name) {
      fetch(`/api/laws/${name}`)
        .then(r => {
          if (!r.ok) throw new Error('Law not found');
          return r.json();
        })
        .then(data => {
          setLaw(data);
          setLoading(false);
        })
        .catch(err => {
          setError(err.message);
          setLoading(false);
        });
    }
  }, [name]);

  const handleSubmit = async (data) => {
    const url = name ? `/api/laws/${name}` : '/api/laws';
    const method = name ? 'PUT' : 'POST';

    const res = await fetch(url, {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });

    if (res.ok) {
      navigate('/laws');
    } else {
      const err = await res.json();
      setError(err.error || 'Failed to save law');
    }
  };

  if (loading) return <div className="loading">Loading...</div>;

  return (
    <div>
      <h1>{name ? 'Edit Law' : 'Create Law'}</h1>

      {error && <div className="error">{error}</div>}

      <LawForm law={law} onSubmit={handleSubmit} />
    </div>
  );
}

export default LawEdit;