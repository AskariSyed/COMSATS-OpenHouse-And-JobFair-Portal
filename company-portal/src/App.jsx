/* eslint-disable react-hooks/set-state-in-effect */
import React, { useEffect, useRef, useState } from 'react';
import LoginPage from './lib/pages/LoginPage';
import RegisterPage from './lib/pages/RegisterPage';
import ForgotPasswordPage from './lib/pages/ForgotPasswordPage';
import CompanyDashboard from './lib/pages/CompanyDashboard';
import DashboardLayout from './lib/layouts/DashboardLayout';
import { requestFcmToken, subscribeToForegroundMessages } from './lib/firebase';
import { getCompanyProfile, registerFcmToken, getCompanyParticipationPrompt, participateInActiveJobFair, getPendingInterviewRequests, getAnalytics } from './lib/api';

export default function App() {
  const [user, setUser] = useState(null);
  const [currentView, setCurrentView] = useState('login');
  const [activeTab, setActiveTab] = useState('overview');
  const [notification, setNotification] = useState(null);
  const [participationPrompt, setParticipationPrompt] = useState(null);
  const [participationLoading, setParticipationLoading] = useState(false);
  const [participationRepsCount, setParticipationRepsCount] = useState(1);
  const [studentProfileContext, setStudentProfileContext] = useState('current');
  const [surveySubmitted, setSurveySubmitted] = useState(false);
  const [notificationCounts, setNotificationCounts] = useState({ interviews: 0, overview: 0 });
  const [nextIncomingInterview, setNextIncomingInterview] = useState(null);
  const [fcmPopup, setFcmPopup] = useState(null);
  const unauthorizedTimerRef = useRef(null);

  const showBrowserNotification = async (title, body) => {
    if (typeof window === 'undefined' || !('Notification' in window)) {
      return;
    }

    if (Notification.permission !== 'granted') {
      return;
    }
// Try to show notification via Service Worker if available, otherwise fallback to standard Notification API
    try {
      if ('serviceWorker' in navigator) {
        const registration = await navigator.serviceWorker.ready;
        if (registration?.showNotification) {
          await registration.showNotification(title, {
            body: body || '',
            icon: '/icon-192.png',
            badge: '/icon-192.png'
          });
          return;
        }
      }

      new Notification(title, {
        body: body || '',
        icon: '/icon-192.png'
      });
    } catch (error) {
      console.warn('Unable to show browser notification:', error);
    }
  };

  const refreshNotificationStateFromPayload = (payload) => {
    const dataType = String(payload?.data?.type || payload?.data?.Type || '').toLowerCase();
    const studentName = payload?.data?.studentname || payload?.data?.StudentName || 'Candidate';

    const isQueueUpdate = [
      'studentarrivingsoon',
      'studentarrived',
      'studentrunninglate',
      'studentreschedulerequest'
    ].includes(dataType);

    if (!isQueueUpdate) {
      return;
    }

    setNotificationCounts((prev) => ({
      interviews: prev.interviews + 1,
      overview: prev.overview + 1
    }));

    setNextIncomingInterview({
      scheduledTime: payload?.data?.scheduledtime || payload?.data?.ScheduledTime || null,
      studentName
    });
  };

  const withCompanyAvatar = async (baseUser) => {
    try {
      const profile = await getCompanyProfile();
      const logoUrl = profile?.logoUrl || profile?.LogoUrl || null;
      return { ...baseUser, avatarUrl: logoUrl };
    } catch {
      return baseUser;
    }
  };

  const registerTokenForSession = async () => {
    try {
      const token = await requestFcmToken();
      if (token) {
        await registerFcmToken(token);
        console.log('FCM token registered successfully');
      }
    } catch (error) {
      console.warn('FCM token registration failed:', error);
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
        const hydratedUser = await withCompanyAvatar(JSON.parse(savedUser));
        localStorage.setItem('user', JSON.stringify(hydratedUser));
        setUser(hydratedUser);
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

  useEffect(() => {
    if (currentView !== 'dashboard' || !user) return;

    const checkParticipationPrompt = async () => {
      try {
        const prompt = await getCompanyParticipationPrompt();
        if (prompt?.shouldPrompt) {
          setParticipationPrompt(prompt);
          setParticipationRepsCount(1);
        }
      } catch (err) {
        console.warn('Participation prompt check failed:', err);
      }
    };

    checkParticipationPrompt();
  }, [currentView, user]);

  useEffect(() => {
    if (currentView !== 'dashboard' || !user) return;

    let unsubscribe = () => {};

    const setupForegroundFcm = async () => {
      unsubscribe = await subscribeToForegroundMessages((payload) => {
        const title = payload?.notification?.title || payload?.data?.title || 'Notification';
        const body = payload?.notification?.body || payload?.data?.body || '';
        const dataType = payload?.data?.type || '';
        const action = payload?.data?.action || '';

        setFcmPopup({ title, body, dataType, action });
        refreshNotificationStateFromPayload(payload);
        showBrowserNotification(title, body);
      });
    };

    setupForegroundFcm();
    return () => {
      if (unsubscribe) unsubscribe();
    };
  }, [currentView, user]);

  useEffect(() => {
    if (currentView !== 'dashboard' || !user) return;

    let intervalId;

    const INTERVIEW_OVERDUE_WINDOW_MS = 10 * 60 * 1000;

    const refreshCompanyNotifications = async () => {
      try {
        const [pendingData, analyticsData] = await Promise.all([
          getPendingInterviewRequests(),
          getAnalytics()
        ]);

        const pendingCount = (pendingData?.pendingRequests || []).length;
        const now = Date.now();
        const scheduled = (analyticsData?.interviews?.scheduledInterviews || []).filter((i) => {
          const t = i?.scheduledTime || i?.ScheduledTime;
          const status = String(i?.status || i?.Status || '').toLowerCase();
          if (!t || (status !== 'queued' && status !== 'accepted' && status !== 'inprogress' && status !== '')) return false;
          const ts = new Date(t).getTime();
          return !Number.isNaN(ts) && Math.abs(ts - now) <= INTERVIEW_OVERDUE_WINDOW_MS;
        }).sort((a, b) => {
          const ta = new Date(a.scheduledTime || a.ScheduledTime).getTime();
          const tb = new Date(b.scheduledTime || b.ScheduledTime).getTime();
          const taDelta = Math.abs(ta - now);
          const tbDelta = Math.abs(tb - now);
          return taDelta - tbDelta;
        });

        const next = scheduled.length > 0 ? scheduled[0] : null;
        const nextTime = next ? new Date(next.scheduledTime || next.ScheduledTime).getTime() : null;
        const deltaMs = nextTime != null && !Number.isNaN(nextTime) ? nextTime - now : null;
        const isOverdue = deltaMs != null && deltaMs < 0;
        const isVisible = deltaMs != null && Math.abs(deltaMs) <= INTERVIEW_OVERDUE_WINDOW_MS;

        setNotificationCounts({
          interviews: pendingCount + (isVisible ? 1 : 0),
          overview: pendingCount
        });
        setNextIncomingInterview(isVisible ? {
          scheduledTime: next.scheduledTime || next.ScheduledTime,
          studentName: next.studentName || next.StudentName || next.registrationNo || 'Candidate',
          isOverdue,
          overdueMinutes: isOverdue ? Math.floor(Math.abs(deltaMs) / 60000) : 0,
        } : null);
      } catch (err) {
        console.warn('Failed to refresh company notification badges', err);
      }
    };

    refreshCompanyNotifications();
    intervalId = setInterval(refreshCompanyNotifications, 30000);

    return () => {
      if (intervalId) clearInterval(intervalId);
    };
  }, [currentView, user]);

  const showNotification = (msg, type = 'success') => {
    setNotification({ msg, type });
    setTimeout(() => setNotification(null), 3000);
  };

  const handleLogin = async (authData) => {
    localStorage.setItem('token', authData.token);
    const baseUser = { name: authData.name, role: authData.role, id: authData.userId };
    const hydratedUser = await withCompanyAvatar(baseUser);
    localStorage.setItem('user', JSON.stringify(hydratedUser));
    setUser(hydratedUser);
    setCurrentView('dashboard');
    showNotification(`Welcome back, ${authData.name}!`);
    registerTokenForSession();
  };

  const handleLogout = () => {
    localStorage.clear();
    setUser(null);
    setParticipationPrompt(null);
    setCurrentView('login');
    setActiveTab('overview');
  };

  const handleParticipateYes = async () => {
    setParticipationLoading(true);
    try {
      await participateInActiveJobFair(participationRepsCount);
      setParticipationPrompt(null);
      showNotification('You are now participating in the active job fair.', 'success');
      setActiveTab('profile');
    } catch (err) {
      showNotification(err.message || 'Failed to join active job fair.', 'error');
    } finally {
      setParticipationLoading(false);
    }
  };

  const handleParticipateNo = () => {
    setParticipationPrompt(null);
  };

  return (
    <div className="min-h-screen bg-gray-50 font-sans text-slate-800">
      {notification && (
        <div className={`fixed top-4 right-4 z-50 px-6 py-3 rounded shadow-lg text-white animate-fade-in-down ${notification.type === 'error' ? 'bg-red-500' : 'bg-green-600'}`}>
          {notification.msg}
        </div>
      )}

      {participationPrompt && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
            <h3 className="text-lg font-bold text-gray-900">Join New Job Fair?</h3>
            <p className="mt-2 text-sm text-gray-600">
              You are not participating in the active job fair. Do you want to participate in
              <span className="font-semibold"> {participationPrompt.activeJobFair?.semester}</span>?
            </p>
            <p className="mt-1 text-xs text-gray-500">
              If you join, your jobs and analytics will switch to this active fair.
            </p>
            <div className="mt-4">
              <label className="block text-xs font-semibold text-gray-600 mb-1">Number of Representatives</label>
              <input
                type="number"
                min="1"
                max="100"
                value={participationRepsCount}
                onChange={(e) => setParticipationRepsCount(Math.max(1, Math.min(100, Number(e.target.value) || 1)))}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div className="mt-5 flex justify-end gap-3">
              <button
                onClick={handleParticipateNo}
                disabled={participationLoading}
                className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-60"
              >
                No
              </button>
              <button
                onClick={handleParticipateYes}
                disabled={participationLoading}
                className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-60"
              >
                {participationLoading ? 'Joining...' : 'Yes, Participate'}
              </button>
            </div>
          </div>
        </div>
      )}

      {fcmPopup && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-lg rounded-xl border border-indigo-200 bg-white shadow-2xl p-5">
            <p className="text-base font-bold text-indigo-900">{fcmPopup.title}</p>
            <p className="text-sm text-gray-700 mt-2">{fcmPopup.body || 'You have a new update from admin.'}</p>
            <div className="mt-5 flex flex-col sm:flex-row gap-2 sm:justify-end">
              {(fcmPopup.dataType === 'survey_reminder' || fcmPopup.action === 'open_surveys') && (
                <button
                  onClick={() => {
                    setActiveTab('surveys');
                    setFcmPopup(null);
                  }}
                  className="px-3 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-md text-sm font-semibold"
                >
                  Fill Survey Now
                </button>
              )}
              <button
                onClick={() => setFcmPopup(null)}
                className="px-3 py-2 border border-gray-300 hover:bg-gray-100 text-gray-800 rounded-md text-sm font-semibold"
              >
                Close
              </button>
            </div>
          </div>
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
        <DashboardLayout
          user={user}
          onLogout={handleLogout}
          activeTab={activeTab}
          onTabChange={setActiveTab}
          notificationCounts={notificationCounts}
          nextIncomingInterview={nextIncomingInterview}
          surveySubmitted={surveySubmitted}
        >
          <CompanyDashboard
            user={user}
            activeTab={activeTab}
            onTabChange={setActiveTab}
            profileContext={studentProfileContext}
            onProfileContextChange={setStudentProfileContext}
            onSuccess={(m) => showNotification(m, 'success')}
            onError={(m) => showNotification(m, 'error')}
            onSurveySubmittedChange={setSurveySubmitted}
          />
        </DashboardLayout>
      )}
    </div>
  );
}