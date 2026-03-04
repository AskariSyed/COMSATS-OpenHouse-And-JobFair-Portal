/* eslint-disable react-hooks/set-state-in-effect */
import React, { useEffect, useRef, useState } from 'react';
import LoginPage from './lib/pages/LoginPage';
import RegisterPage from './lib/pages/RegisterPage';
import ForgotPasswordPage from './lib/pages/ForgotPasswordPage';
import CompanyDashboard from './lib/pages/CompanyDashboard';
import DashboardLayout from './lib/layouts/DashboardLayout';
import { requestFcmToken } from './lib/firebase';
import { getCompanyProfile, registerFcmToken } from './lib/api';

export default function App() {
  const [user, setUser] = useState(null);
  const [currentView, setCurrentView] = useState('login');
  const [activeTab, setActiveTab] = useState('overview');
  const [notification, setNotification] = useState(null);
  const unauthorizedTimerRef = useRef(null);

  const registerTokenForSession = async () => {
    try {
      const token = await requestFcmToken();
      if (token) {
        await registerFcmToken(token);
        console.log('FCM token registered successfully');
      } else {
        showNotification('Push notifications unavailable: permission denied or token not available.', 'error');
      }
    } catch (error) {
      console.warn('FCM token registration failed:', error);
      showNotification('Push notifications blocked by network/firewall. Use localhost and allow notifications, then retry.', 'error');
    }
  };

  useEffect(() => {
    const bootstrapAuth = async () => {
      const savedUser = localStorage.getItem('user');
      const token = localStorage.getItem('token');

      if (!savedUser || !token) {
        setUser(null);
        setCurrentView('login');
        return;
      }

      try {
        await getCompanyProfile();
        setUser(JSON.parse(savedUser));
        setCurrentView('dashboard');
        await registerTokenForSession();
      } catch {
        localStorage.clear();
        setUser(null);
        setCurrentView('login');
      }
    };

    const onUnauthorized = () => {
      localStorage.clear();
      setUser(null);
      setActiveTab('overview');
      setCurrentView('session-expired');

      if (unauthorizedTimerRef.current) {
        clearTimeout(unauthorizedTimerRef.current);
      }

      unauthorizedTimerRef.current = setTimeout(() => {
        setCurrentView('login');
      }, 1400);
    };

    window.addEventListener('auth:unauthorized', onUnauthorized);
    bootstrapAuth();

    return () => {
      window.removeEventListener('auth:unauthorized', onUnauthorized);
      if (unauthorizedTimerRef.current) {
        clearTimeout(unauthorizedTimerRef.current);
      }
    };
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
    registerTokenForSession();
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

      {currentView === 'session-expired' && (
        <div className="min-h-screen flex items-center justify-center bg-gray-50 px-6">
          <div className="max-w-md w-full bg-white rounded-2xl shadow-lg border border-gray-200 p-8 text-center">
            <h2 className="text-2xl font-bold text-gray-900">Session Expired</h2>
            <p className="text-gray-600 mt-2">Your login session has expired. Redirecting to login...</p>
            <div className="mt-6 w-full bg-gray-200 rounded-full h-2 overflow-hidden">
              <div className="h-full bg-indigo-600 rounded-full animate-pulse" style={{ width: '100%' }}></div>
            </div>
          </div>
        </div>
      )}
      
      {currentView === 'dashboard' && user && (
        <DashboardLayout user={user} onLogout={handleLogout} activeTab={activeTab} onTabChange={setActiveTab}>
          <CompanyDashboard user={user} activeTab={activeTab} onTabChange={setActiveTab} onError={(m) => showNotification(m, 'error')} />
        </DashboardLayout>
      )}
    </div>
  );
}