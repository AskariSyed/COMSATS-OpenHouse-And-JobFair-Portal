import { Navigate, Route, Routes } from 'react-router-dom';
import { Layout } from './components/Layout';
import { HomePage } from './pages/HomePage';
import { StudentPage } from './pages/StudentPage';
import { CompanyPage } from './pages/CompanyPage';
import { AdminPage } from './pages/AdminPage';
import { HowToUsePage } from './pages/HowToUsePage';
import { TeamPage } from './pages/TeamPage';

export default function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route path="/" element={<HomePage />} />
        <Route path="/student" element={<StudentPage />} />
        <Route path="/company" element={<CompanyPage />} />
        <Route path="/admin" element={<AdminPage />} />
        <Route path="/how-to-use" element={<HowToUsePage />} />
        <Route path="/team" element={<TeamPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
