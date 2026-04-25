import { useState } from 'react';
import { useNavigate } from 'react-router-dom';

const HOOKS = ['pre-commit', 'pre-push', 'pre-tool'];

function LawForm({ law, onSubmit }) {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    name: law?.name || '',
    severity: law?.severity || 'error',
    hooks: law?.hooks || [],
    enabled: law?.enabled !== undefined ? law.enabled : true
  });

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const handleHookToggle = (hook) => {
    setFormData(prev => ({
      ...prev,
      hooks: prev.hooks.includes(hook)
        ? prev.hooks.filter(h => h !== hook)
        : [...prev.hooks, hook]
    }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit(formData);
  };

  return (
    <form onSubmit={handleSubmit} className="card">
      <div className="form-group">
        <label>Law Name</label>
        <input
          type="text"
          name="name"
          value={formData.name}
          onChange={handleChange}
          placeholder="e.g., no-console-log"
          disabled={!!law}
          required
        />
      </div>

      <div className="form-group">
        <label>Severity</label>
        <select name="severity" value={formData.severity} onChange={handleChange}>
          <option value="error">Error</option>
          <option value="warn">Warning</option>
          <option value="info">Info</option>
        </select>
      </div>

      <div className="form-group">
        <label>Hooks</label>
        <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
          {HOOKS.map(hook => (
            <label key={hook} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <input
                type="checkbox"
                checked={formData.hooks.includes(hook)}
                onChange={() => handleHookToggle(hook)}
              />
              {hook}
            </label>
          ))}
        </div>
      </div>

      <div className="form-group">
        <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <input
            type="checkbox"
            name="enabled"
            checked={formData.enabled}
            onChange={handleChange}
          />
          Enabled
        </label>
      </div>

      <div className="actions">
        <button type="submit" className="btn btn-primary">
          {law ? 'Update Law' : 'Create Law'}
        </button>
        <button type="button" className="btn btn-secondary" onClick={() => navigate('/laws')}>
          Cancel
        </button>
      </div>
    </form>
  );
}

export default LawForm;