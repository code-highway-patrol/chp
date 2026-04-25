import { Link } from 'react-router-dom';

function Navbar() {
  return (
    <nav className="navbar">
      <Link to="/" className="navbar-brand">CHP</Link>
      <div className="navbar-links">
        <Link to="/">Dashboard</Link>
        <Link to="/laws">Laws</Link>
        <Link to="/reports">Reports</Link>
      </div>
    </nav>
  );
}

export default Navbar;