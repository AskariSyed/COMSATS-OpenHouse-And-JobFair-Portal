/* eslint-disable react-hooks/set-state-in-effect */
import React, { useState, useEffect } from 'react';
import LoginPage from './lib/pages/LoginPage';
import RegisterPage from './lib/pages/RegisterPage';
import ForgotPasswordPage from './lib/pages/ForgotPasswordPage';
import CompanyDashboard from './lib/pages/CompanyDashboard';
import DashboardLayout from './lib/layouts/DashboardLayout';
import { requestFcmToken } from './lib/firebase';
import { registerFcmToken } from './lib/api';

export default function App() {
  const [user, setUser] = useState(null);
  const [currentView, setCurrentView] = useState('login');
  const [activeTab, setActiveTab] = useState('overview');
  const [notification, setNotification] = useState(null);

  useEffect(() => {
    const savedUser = localStorage.getItem('user');
    if (savedUser) {
      setUser(JSON.parse(savedUser));
      setCurrentView('dashboard');
      
      // Register FCM token when user is already logged in
      const registerToken = async () => {
        try {
          const token = await requestFcmToken();
          if (token) {
            await registerFcmToken(token);
            console.log('FCM token registered successfully');
          } else {
            // Soft warning if token not available
            showNotification('Push notifications unavailable: permission denied or token not available.', 'error');
          }
        } catch (error) {
          console.warn('FCM token registration failed:', error);
          showNotification('Push notifications blocked by network/firewall. Use localhost and allow notifications, then retry.', 'error');
        }
      };
      
      registerToken();
    }
  }, []);

  const showNotification = (msg, type = 'success') => {
    setNotification({ msg, type });
    setTimeout(() => setNotification(null), 3000);
  };

  const handleLogin = (authData) => {
    localStorage.setItem('token', authData.token);
    localStorage.setItem('user', JSON.stringify({ name: authData.name, role: authData.role, id: authData.userId }));
    setUser({ name: authData.name, role: authData.role, id: authData.userId });
    setCurrentView('dashboard');
    showNotification(`Welcome back, ${authData.name}!`);
  };

  const handleLogout = () => {
    localStorage.clear();
    setUser(null);
    setCurrentView('login');
    setActiveTab('overview');
  };

  return (
    <div className="min-h-screen bg-gray-50 font-sans text-slate-800">
      {notification && (
        <div className={`fixed top-4 right-4 z-50 px-6 py-3 rounded shadow-lg text-white animate-fade-in-down ${notification.type === 'error' ? 'bg-red-500' : 'bg-green-600'}`}>
          {notification.msg}
        </div>
      )}

      {currentView === 'login' && <LoginPage onLogin={handleLogin} onNavigate={setCurrentView} onError={(m) => showNotification(m, 'error')} />}
      {currentView === 'register' && <RegisterPage onNavigate={setCurrentView} onSuccess={(m) => showNotification(m, 'success')} onError={(m) => showNotification(m, 'error')} />}
      {currentView === 'forgot-password' && <ForgotPasswordPage onNavigate={setCurrentView} />}
      
      {currentView === 'dashboard' && user && (
        <DashboardLayout user={user} onLogout={handleLogout} activeTab={activeTab} onTabChange={setActiveTab}>
          <CompanyDashboard user={user} activeTab={activeTab} onError={(m) => showNotification(m, 'error')} />
        </DashboardLayout>
      )}
    </div>
  );
}