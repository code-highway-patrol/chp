import { useEffect, useRef } from 'react';

function ConfirmDialog({ isOpen, title, message, onConfirm, onCancel }) {
  const dialogRef = useRef(null);

  useEffect(() => {
    if (isOpen) {
      dialogRef.current?.showModal();
    } else {
      dialogRef.current?.close();
    }
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <dialog ref={dialogRef} className="card" style={{ padding: '1.5rem', minWidth: '300px' }}>
      <h3 style={{ marginBottom: '1rem' }}>{title}</h3>
      <p style={{ marginBottom: '1.5rem', color: '#666' }}>{message}</p>
      <div className="actions">
        <button className="btn btn-danger" onClick={onConfirm}>Delete</button>
        <button className="btn btn-secondary" onClick={onCancel}>Cancel</button>
      </div>
    </dialog>
  );
}

export default ConfirmDialog;