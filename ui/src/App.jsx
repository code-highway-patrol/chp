import { Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import Dashboard from './pages/Dashboard';
import Laws from './pages/Laws';
import LawEdit from './pages/LawEdit';
import Reports from './pages/Reports';
import ReportDetail from './pages/ReportDetail';

function App() {
  return (
    <div className="app">
      <Navbar />
      <main className="main-content">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/laws" element={<Laws />} />
          <Route path="/laws/new" element={<LawEdit />} />
          <Route path="/laws/:name/edit" element={<LawEdit />} />
          <Route path="/reports" element={<Reports />} />
          <Route path="/reports/:id" element={<ReportDetail />} />
        </Routes>
      </main>
    </div>
  );
}

export default App;