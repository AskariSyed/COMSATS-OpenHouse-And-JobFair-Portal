/* eslint-disable no-unused-vars */
import React from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { 
  LayoutDashboard, 
  Users, 
  Building2, 
  DoorOpen, 
  LogOut, 
  Menu, 
  X,
  BookOpen,
  QrCode,
  FileText
} from 'lucide-react';
import { useState } from 'react';
import { Settings } from 'lucide-react';
import { TrendingUp } from 'lucide-react';
import { MessageSquare } from 'lucide-react';
import { Bell } from 'lucide-react';
import CuiWahJobFairLogo from '../assets/CuiWahJobFairLogo.png';

// ----------------------------------
// Helper: Sidebar Item Component
// ----------------------------------
const SidebarItem = ({ to, icon: Icon, label, onClick }) => (
  <NavLink
    to={to}
    onClick={onClick}
    className={({ isActive }) =>
      `flex items-center space-x-3 px-6 py-3.5 transition-all duration-200 group ${
        isActive 
          ? 'bg-indigo-600 text-white border-r-4 border-indigo-400' 
          : 'text-gray-300 hover:bg-slate-800 hover:text-white'
      }`
    }
  >
    <Icon size={20} className="transition-colors group-hover:text-indigo-400" />
    <span className="font-medium">{label}</span>
  </NavLink>
);

// ----------------------------------
// Main Layout Component
// ----------------------------------
const AdminLayout = () => {
  const navigate = useNavigate();
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  // Logout Logic
  const handleLogout = () => {
    if (window.confirm('Are you sure you want to logout?')) {
      localStorage.clear();
      navigate('/');
    }
  };

  return (
    <div className="flex h-screen bg-gray-50 font-sans overflow-hidden">
      
      {/* 1. Mobile Sidebar Overlay */}
      {isSidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/50 z-20 lg:hidden backdrop-blur-sm transition-opacity"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* 2. Sidebar Navigation */}
      <aside 
        className={`
          fixed lg:static inset-y-0 left-0 z-30 w-64 bg-slate-900 shadow-xl lg:shadow-none transform transition-transform duration-300 ease-in-out relative overflow-hidden flex flex-col
          ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
        `}
      >
        {/* Background gradient effects */}
        <div className="absolute inset-0 opacity-20 pointer-events-none">
          <div className="absolute top-0 left-0 w-96 h-96 bg-indigo-600 rounded-full mix-blend-multiply filter blur-3xl animate-blob"></div>
          <div className="absolute bottom-0 right-0 w-96 h-96 bg-blue-600 rounded-full mix-blend-multiply filter blur-3xl animate-blob animation-delay-2000"></div>
        </div>

        {/* Logo Area */}
        <div className="h-20 flex items-center px-8 border-b border-slate-700 relative z-10 flex-shrink-0">
          <div className="flex items-center gap-3">
            <img 
              src={CuiWahJobFairLogo} 
              alt="CUI Wah Job Fair Logo" 
              className="h-12 w-auto"
            />
            <span className="text-lg font-bold text-white">Admin <span className="text-indigo-400">Portal</span></span>
          </div>
          {/* Close Button (Mobile) */}
          <button 
            onClick={() => setIsSidebarOpen(false)}
            className="ml-auto lg:hidden text-gray-300 hover:text-white"
          >
            <X size={24} />
          </button>
        </div>
        
        {/* Navigation Links */}
        <nav className="flex-1 py-6 space-y-1 overflow-y-auto relative z-10 min-h-0">
          <div className="px-6 mb-2 text-xs font-semibold text-gray-400 uppercase tracking-wider">Overview</div>
          
          <SidebarItem 
            to="/admin/dashboard" 
            icon={LayoutDashboard} 
            label="Dashboard" 
            onClick={() => setIsSidebarOpen(false)}
          />
          
          <div className="px-6 mt-8 mb-2 text-xs font-semibold text-slate-400 uppercase tracking-wider">Management</div>
          
          <SidebarItem 
            to="/admin/all-students" 
            icon={BookOpen} 
            label="Student Directory" 
            onClick={() => setIsSidebarOpen(false)}
          />
          <SidebarItem 
            to="/admin/students" 
            icon={Users} 
            label="Active Students" 
            onClick={() => setIsSidebarOpen(false)}
          />
          <SidebarItem 
            to="/admin/companies" 
            icon={Building2} 
            label="Companies" 
            onClick={() => setIsSidebarOpen(false)}
          />
          <SidebarItem 
            to="/admin/company-requests" 
            icon={MessageSquare} 
            label="Company Requests" 
            onClick={() => setIsSidebarOpen(false)}
          />
          <SidebarItem 
            to="/admin/rooms" 
            icon={DoorOpen} 
            label="Rooms & Allocation" 
            onClick={() => setIsSidebarOpen(false)}
          />
          <SidebarItem 
            to="/admin/attendance" 
            icon={QrCode} 
            label="Attendance (QR)" 
            onClick={() => setIsSidebarOpen(false)}
          />
          <SidebarItem 
            to="/admin/surveys" 
            icon={FileText} 
            label="Survey Responses" 
            onClick={() => setIsSidebarOpen(false)}
          />
          <SidebarItem 
  to="/admin/analytics" 
  icon={TrendingUp} 
  label="Analytics" 
  onClick={() => setIsSidebarOpen(false)}
/>
<SidebarItem 
  to="/admin/setup" 
  icon={Settings} 
  label="Job Fair Setup" 
  onClick={() => setIsSidebarOpen(false)}
/>
<SidebarItem 
  to="/admin/notices" 
  icon={Bell} 
  label="Notice Board" 
  onClick={() => setIsSidebarOpen(false)}
/>
        </nav>
        

        {/* Logout Button */}
        <div className="p-4 border-t border-slate-700 relative z-10 flex-shrink-0">
          <button 
            onClick={handleLogout}
            className="flex items-center space-x-3 px-4 py-3 w-full text-red-400 hover:bg-red-900/30 rounded-lg transition-colors"
          >
            <LogOut size={20} />
            <span className="font-medium">Sign Out</span>
          </button>
        </div>
      </aside>

      {/* 3. Main Content Area */}
      <div className="flex-1 flex flex-col overflow-hidden w-full">
        
        {/* Mobile Hamburger Menu - Only visible on mobile */}
        <div className="lg:hidden bg-white shadow-sm p-4 flex items-center">
          <button 
            onClick={() => setIsSidebarOpen(true)}
            className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg"
          >
            <Menu size={24} />
          </button>
          <h2 className="ml-4 text-lg font-semibold text-gray-800">
            Administrator Portal
          </h2>
        </div>

        {/* Page Content (Dynamic) */}
        <main className="flex-1 overflow-y-auto bg-gray-50 scroll-smooth">
          <div className="p-4 lg:p-8">
            <div className="max-w-7xl mx-auto">
              <Outlet />
            </div>
          </div>
        </main>
      </div>
    </div>
    
  );
};

export default AdminLayout;