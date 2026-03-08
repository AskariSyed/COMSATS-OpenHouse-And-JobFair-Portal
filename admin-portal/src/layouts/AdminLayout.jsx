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
  FileText,
  KeyRound,
  Loader2
} from 'lucide-react';
import { useState } from 'react';
import { Settings } from 'lucide-react';
import { TrendingUp } from 'lucide-react';
import { MessageSquare } from 'lucide-react';
import { Bell } from 'lucide-react';
import CuiWahJobFairLogo from '../assets/CuiWahJobFairLogo.png';
import api from '../lib/api';
import { toast } from 'react-hot-toast';

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
  const [isChangePasswordOpen, setIsChangePasswordOpen] = useState(false);
  const [isChangingPassword, setIsChangingPassword] = useState(false);
  const [passwordForm, setPasswordForm] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: ''
  });

  const passwordRules = {
    minLength: passwordForm.newPassword.length >= 8,
    hasUppercase: /[A-Z]/.test(passwordForm.newPassword),
    hasLowercase: /[a-z]/.test(passwordForm.newPassword),
    hasNumber: /\d/.test(passwordForm.newPassword),
    hasSpecial: /[^A-Za-z0-9]/.test(passwordForm.newPassword),
  };

  const strongPasswordScore = Object.values(passwordRules).filter(Boolean).length;
  const passwordStrengthLabel =
    strongPasswordScore >= 5 ? 'Strong' : strongPasswordScore >= 3 ? 'Medium' : 'Weak';
  const passwordStrengthColor =
    strongPasswordScore >= 5 ? 'text-emerald-600' : strongPasswordScore >= 3 ? 'text-amber-600' : 'text-red-600';

  // Logout Logic
  const handleLogout = () => {
    if (window.confirm('Are you sure you want to logout?')) {
      localStorage.clear();
      navigate('/');
    }
  };

  const closeChangePasswordModal = () => {
    setIsChangePasswordOpen(false);
    setPasswordForm({ currentPassword: '', newPassword: '', confirmPassword: '' });
  };

  const handleChangePassword = async (e) => {
    e.preventDefault();

    if (!passwordForm.currentPassword || !passwordForm.newPassword || !passwordForm.confirmPassword) {
      toast.error('Please fill all password fields.');
      return;
    }

    if (passwordForm.newPassword.length < 8) {
      toast.error('New password must be at least 8 characters long.');
      return;
    }

    if (passwordForm.newPassword !== passwordForm.confirmPassword) {
      toast.error('New password and confirm password do not match.');
      return;
    }

    setIsChangingPassword(true);
    try {
      await api.post('/Auth/change-password', {
        currentPassword: passwordForm.currentPassword,
        newPassword: passwordForm.newPassword,
        confirmPassword: passwordForm.confirmPassword,
      });
      toast.success('Password changed successfully.');
      closeChangePasswordModal();
    } catch (error) {
      const message =
        error?.response?.data?.message ||
        error?.response?.data ||
        'Failed to change password. Please try again.';
      toast.error(String(message));
    } finally {
      setIsChangingPassword(false);
    }
  };

  return (
    <div className="flex h-screen w-full bg-gray-50 font-sans overflow-x-hidden">
      
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
          fixed lg:relative inset-y-0 left-0 z-30 w-[82vw] max-w-64 sm:w-64 lg:w-64 bg-slate-900 shadow-xl lg:shadow-none transform transition-transform duration-300 ease-in-out overflow-hidden flex flex-col lg:translate-x-0 lg:flex-shrink-0
          ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full'}
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
            onClick={() => setIsChangePasswordOpen(true)}
            className="mb-2 flex items-center space-x-3 px-4 py-3 w-full text-indigo-300 hover:bg-indigo-900/30 rounded-lg transition-colors"
          >
            <KeyRound size={20} />
            <span className="font-medium">Change Password</span>
          </button>
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
      <div className="flex-1 min-w-0 max-w-full flex flex-col overflow-hidden w-full">
        
        {/* Mobile Hamburger Menu - Only visible on mobile */}
        <div className="lg:hidden w-full bg-white shadow-sm p-4 flex items-center">
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
        <main className="flex-1 min-h-0 overflow-y-auto overflow-x-hidden bg-gray-50 scroll-smooth">
          <div className="p-4 lg:p-8">
            <div className="w-full max-w-7xl mx-auto">
              <Outlet />
            </div>
          </div>
        </main>
      </div>

      {isChangePasswordOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="w-full max-w-md rounded-xl bg-white shadow-2xl border border-gray-100 overflow-hidden">
            <div className="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
              <h3 className="text-lg font-bold text-gray-900">Change Password</h3>
              <button
                onClick={closeChangePasswordModal}
                className="text-gray-400 hover:text-gray-700"
                disabled={isChangingPassword}
              >
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleChangePassword} className="p-5 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Current Password</label>
                <input
                  type="password"
                  value={passwordForm.currentPassword}
                  onChange={(e) => setPasswordForm({ ...passwordForm, currentPassword: e.target.value })}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">New Password</label>
                <input
                  type="password"
                  value={passwordForm.newPassword}
                  onChange={(e) => setPasswordForm({ ...passwordForm, newPassword: e.target.value })}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
                  required
                />
                <div className="mt-2 space-y-1">
                  <p className={`text-xs font-semibold ${passwordStrengthColor}`}>
                    Strength: {passwordStrengthLabel}
                  </p>
                  <p className="text-xs text-gray-500">Use at least 8 characters and include uppercase, lowercase, number, and special character.</p>
                  <div className="flex flex-wrap gap-x-3 gap-y-1 text-xs">
                    <span className={passwordRules.minLength ? 'text-emerald-600' : 'text-gray-400'}>8+ chars</span>
                    <span className={passwordRules.hasUppercase ? 'text-emerald-600' : 'text-gray-400'}>Uppercase</span>
                    <span className={passwordRules.hasLowercase ? 'text-emerald-600' : 'text-gray-400'}>Lowercase</span>
                    <span className={passwordRules.hasNumber ? 'text-emerald-600' : 'text-gray-400'}>Number</span>
                    <span className={passwordRules.hasSpecial ? 'text-emerald-600' : 'text-gray-400'}>Special</span>
                  </div>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Confirm New Password</label>
                <input
                  type="password"
                  value={passwordForm.confirmPassword}
                  onChange={(e) => setPasswordForm({ ...passwordForm, confirmPassword: e.target.value })}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
                  required
                />
              </div>

              <div className="pt-2 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={closeChangePasswordModal}
                  disabled={isChangingPassword}
                  className="px-4 py-2 text-sm font-medium text-gray-600 rounded-lg hover:bg-gray-100"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isChangingPassword}
                  className="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg disabled:opacity-60 flex items-center gap-2"
                >
                  {isChangingPassword ? <Loader2 size={16} className="animate-spin" /> : null}
                  {isChangingPassword ? 'Updating...' : 'Update Password'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
    
  );
};

export default AdminLayout;