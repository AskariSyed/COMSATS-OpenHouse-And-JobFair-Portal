import React, { useEffect, useMemo, useState } from 'react';
import { LayoutDashboard, Users, Bell, LogOut, BookOpen, Calendar, Menu, X, ChevronRight, Building2, Package, ClipboardList } from 'lucide-react';
import logo from '../../assets/CuiWahJobFairLogo.png';

export default function DashboardLayout({ user, onLogout, activeTab, onTabChange, children, notificationCounts = {}, nextIncomingInterview = null }) {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(id);
  }, []);

  const upcomingSecondsLeft = useMemo(() => {
    if (!nextIncomingInterview?.scheduledTime) return null;
    const target = new Date(nextIncomingInterview.scheduledTime).getTime();
    const diff = Math.floor((target - now) / 1000);
    return diff >= 0 ? diff : null;
  }, [nextIncomingInterview, now]);

  const formatCountdown = (seconds) => {
    if (seconds == null) return '--:--';
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  };

  const navItems = [
    { id: 'overview', label: 'Dashboard', icon: LayoutDashboard, badge: notificationCounts.overview || 0 },
    { id: 'profile', label: 'Company Profile', icon: Building2 },
    { id: 'students', label: 'Student Directory', icon: Users },
    { id: 'fyps', label: 'FYP Gallery', icon: BookOpen },
    { id: 'interviews', label: 'Interviews', icon: Calendar, badge: notificationCounts.interviews || 0 },
    { id: 'requests', label: 'Supply Requests', icon: Package },
    { id: 'surveys', label: 'Surveys', icon: ClipboardList },
    { id: 'notices', label: 'Notices', icon: Bell },
    { id: 'history-analytics', label: 'Past Analytics', icon: LayoutDashboard },
  ];

  const NavItem = ({ item }) => {
    const isActive = activeTab === item.id;
    return (
      <button 
        onClick={() => { onTabChange(item.id); setIsMobileMenuOpen(false); }}
        className={`w-full flex items-center justify-between px-4 py-3.5 rounded-xl transition-all duration-200 group ${
          isActive 
            ? 'bg-blue-600 text-white shadow-lg shadow-blue-900/20' 
            : 'text-slate-400 hover:bg-slate-800 hover:text-white'
        }`}
      >
        <div className="flex items-center gap-3">
          <item.icon className={`w-5 h-5 ${isActive ? 'text-white' : 'text-slate-500 group-hover:text-white'}`} />
          <span className="font-medium text-sm">{item.label}</span>
          {item.badge > 0 && (
            <span className="ml-1 min-w-5 h-5 px-1 rounded-full bg-red-500 text-white text-[10px] flex items-center justify-center font-bold">
              {item.badge > 99 ? '99+' : item.badge}
            </span>
          )}
        </div>
        {isActive && <ChevronRight className="w-4 h-4 text-blue-300" />}
      </button>
    );
  };

  return (
    <div className="flex h-screen bg-gray-50 overflow-hidden">
      
      {/* MOBILE OVERLAY BACKDROP */}
      {isMobileMenuOpen && (
        <div 
          className="fixed inset-0 bg-black/50 z-40 md:hidden backdrop-blur-sm transition-opacity"
          onClick={() => setIsMobileMenuOpen(false)}
        />
      )}

      {/* SIDEBAR */}
      <aside 
        className={`fixed inset-y-0 left-0 z-50 w-72 bg-slate-900 text-white transform transition-transform duration-300 ease-in-out md:relative md:translate-x-0 flex flex-col shadow-2xl ${
          isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {/* Sidebar Header */}
        <div className="p-6 border-b border-slate-800 flex items-center gap-3">
          <img src={logo} alt="CUI Wah Job Fair" className="w-10 h-10 rounded-xl object-contain" />
          <div>
            <h1 className="font-bold text-lg tracking-tight">Company Portal</h1>
            <p className="text-xs text-slate-500 font-medium">Recruiter Dashboard</p>
          </div>
          <button onClick={() => setIsMobileMenuOpen(false)} className="md:hidden ml-auto text-slate-400 hover:text-white">
            <X className="w-6 h-6" />
          </button>
        </div>
        
        {/* Navigation Links */}
        <div className="flex-1 overflow-y-auto p-4 space-y-1">
          <div className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-4 px-4 mt-4">Main Menu</div>
          {navItems.map(item => (
            <NavItem key={item.id} item={item} />
          ))}
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-slate-800 bg-slate-900/50">
          <div className="flex items-center gap-3 mb-4 p-2 rounded-lg bg-slate-800/50 border border-slate-700/50">
            <div className="w-10 h-10 rounded-full bg-slate-700 flex items-center justify-center text-white font-bold border-2 border-slate-600 overflow-hidden">
              {user?.avatarUrl ? (
                <img
                  src={user.avatarUrl}
                  alt="Company"
                  className="w-full h-full object-cover"
                  onError={(e) => {
                    e.currentTarget.style.display = 'none';
                  }}
                />
              ) : (
                user?.name?.charAt(0) || 'U'
              )}
            </div>
            <div className="overflow-hidden">
              <p className="text-sm font-bold text-white truncate">{user?.name || 'User'}</p>
              <p className="text-xs text-slate-400 truncate">{user?.role || 'Company'}</p>
            </div>
          </div>
          <button 
            onClick={onLogout} 
            className="flex items-center justify-center gap-2 w-full px-4 py-2.5 text-sm font-medium text-red-400 hover:text-white hover:bg-red-500/10 rounded-lg transition-colors border border-transparent hover:border-red-500/20"
          >
            <LogOut className="w-4 h-4" /> Sign Out
          </button>
        </div>
      </aside>

      {/* MAIN CONTENT */}
      <main className="flex-1 flex flex-col min-w-0 overflow-hidden relative">
        {nextIncomingInterview && upcomingSecondsLeft != null && (
          <div className="hidden md:flex absolute top-4 left-4 z-30 bg-amber-100 border border-amber-300 text-amber-900 rounded-xl shadow px-4 py-3 items-center gap-3">
            <Calendar className="w-4 h-4" />
            <div className="text-xs">
              <div className="font-semibold">Incoming Interview</div>
              <div>{nextIncomingInterview.studentName || 'Candidate'} in {formatCountdown(upcomingSecondsLeft)} mins</div>
            </div>
          </div>
        )}

        <header className="md:hidden bg-white border-b border-gray-200 px-4 py-3 flex items-center justify-between sticky top-0 z-30">
          <div className="flex items-center gap-2 font-bold text-gray-900">
             <img src={logo} alt="CUI Wah Job Fair" className="w-8 h-8 rounded-lg object-contain" />
             JobFair
          </div>
          <button onClick={() => setIsMobileMenuOpen(true)} className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg">
            <Menu className="w-6 h-6" />
          </button>
        </header>

        <div className="flex-1 overflow-auto p-4 md:p-8 scroll-smooth">
          {children}
          
          {/* FYP Disclaimer */}
          <div className="mt-12 p-4 bg-blue-50 border border-blue-200 rounded-lg text-center max-w-2xl mx-auto">
            <p className="text-sm text-blue-700 font-medium">
              📚 <strong>Disclaimer:</strong> This is a Final Year Project by COMSATS Students (Class of 2026) and does not refer to any official COMSATS platform, policy, or communication.
            </p>
          </div>
        </div>
      </main>
    </div>
  );
}