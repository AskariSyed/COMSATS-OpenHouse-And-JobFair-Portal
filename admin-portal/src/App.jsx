import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';

// Import Pages
import Login from './pages/Login';

// Import Layouts
import AdminLayout from './layouts/AdminLayout';

// Import Admin Pages (Ensure these files exist, or comment them out for now)
import Dashboard from './pages/admin/dashboard';
import StudentsList from './pages/admin/StudentsList';
import AllStudentsList from './pages/admin/AllStudentsList';
import CompaniesList from './pages/admin/CompaniesList';
import CompanyRequests from './pages/admin/CompanyRequests';
import RoomsManagement from './pages/admin/RoomsManagement';
import JobFairSetup from './pages/admin/JobFairSetup';
import StudentDetail from './pages/admin/StudentDetail';
import JobFairAnalytics from './pages/admin/JobFairAnalytics';
import FeedbackStats from './pages/admin/FeedBackStats';
import NoticeBoard from './pages/admin/NoticeBoard';
import CompanyDetail from './pages/admin/CompanyDetail';
import AttendanceManagement from './pages/admin/AttendanceManagement';
import SurveyResponses from './pages/admin/SurveyResponses';
import CompanySurveyDetail from './pages/admin/CompanySurveyDetail';


// ----------------------------------------------------------------------
// Helper Component: Protected Route
// ----------------------------------------------------------------------
// This checks if a token exists and if the user has the correct role.
// If not, it kicks them back to the Login page.
const ProtectedRoute = ({ children, requiredRole }) => {
  const token = localStorage.getItem('token');
  const userRole = localStorage.getItem('role'); // e.g., "Admin", "Student"

  // 1. No Token? -> Go to Login
  if (!token) {
    return <Navigate to="/" replace />;
  }

  // 2. Wrong Role? -> Go to Login (or a "Not Authorized" page)
  if (requiredRole && userRole !== requiredRole) {
    return <Navigate to="/" replace />;
  }

  // 3. All good? Render the page
  return children;
};

// ----------------------------------------------------------------------
// Main App Component
// ----------------------------------------------------------------------
function App() {
  return (
    <BrowserRouter>
      {/* Global Toast Notifications */}
      <Toaster position="top-right" />

      <Routes>
        {/* Public Route: Login */}
        <Route path="/" element={<Login />} />

        {/* ----------------------- */}
        {/* Protected Admin Routes  */}
        {/* ----------------------- */}
        <Route 
          path="/admin" 
          element={
            <ProtectedRoute requiredRole="Admin">
              <AdminLayout />
            </ProtectedRoute>
          }
        >
          {/* Default to Dashboard when visiting /admin */}
          <Route index element={<Navigate to="dashboard" replace />} />
          
          <Route path="dashboard" element={<Dashboard />} />
          <Route path="students" element={<StudentsList />} />
          <Route path="all-students" element={<AllStudentsList />} />
          {/* 2. Add this line: */}
          <Route path="companies" element={<CompaniesList />} />
          <Route path="company-requests" element={<CompanyRequests />} />
          <Route path="rooms" element={<RoomsManagement />} />
          <Route path="setup" element={<JobFairSetup />} />
          <Route path="students/:studentId" element={<StudentDetail />} />
          <Route path="analytics" element={<JobFairAnalytics />} />
          <Route path="feedback" element={<FeedbackStats />} />
          <Route path="companies/:companyId" element={<CompanyDetail />} />
          <Route path="notices" element={<NoticeBoard />} />
          <Route path="attendance" element={<AttendanceManagement />} />
          <Route path="surveys" element={<SurveyResponses />} />
          <Route path="surveys/company/:companyId" element={<CompanySurveyDetail />} />
          
          {/* Add more admin routes here later (e.g., Companies, Rooms) */}
        </Route>

        {/* ----------------------- */}
        {/* Protected Student Routes (Placeholder) */}
        {/* ----------------------- */}
        {/* <Route 
          path="/student" 
          element={
            <ProtectedRoute requiredRole="Student">
              <StudentLayout />
            </ProtectedRoute>
          }
        >
           <Route path="dashboard" element={<StudentDashboard />} />
        </Route> 
        */}

        {/* Catch-all: Redirect unknown URLs to Login */}
        <Route path="*" element={<Navigate to="/" replace />} />

      </Routes>
    </BrowserRouter>
  );
}

export default App;