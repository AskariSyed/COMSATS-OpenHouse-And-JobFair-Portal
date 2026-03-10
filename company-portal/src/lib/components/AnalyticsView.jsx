/* eslint-disable no-unused-vars */
import React, { useEffect, useState } from 'react';
import { PieChart, Users, CheckCircle, BookOpen, Loader2, TrendingUp, Clock, AlertCircle, Calendar } from 'lucide-react';
import { getAnalytics, scheduleAllInterviews, setWalkInInterviewing } from '../api';

export default function AnalyticsView({ onError, onSuccess, onNavigateToInterviews, attendanceStatus = null }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [scheduling, setScheduling] = useState(false);
  const [togglingWalkIn, setTogglingWalkIn] = useState(false);
  const [isJobFairDay, setIsJobFairDay] = useState(false);

  const loadAnalytics = () => {
    setLoading(true);
    getAnalytics()
      .then((analyticsData) => {
        setData(analyticsData);
        // Check if today is job fair day and store date in localStorage
        if (analyticsData.jobFairDate) {
          localStorage.setItem('jobFairDate', analyticsData.jobFairDate);
          const jobFairDate = new Date(analyticsData.jobFairDate).toDateString();
          const today = new Date().toDateString();
          setIsJobFairDay(jobFairDate === today);
        }
      })
      .catch(err => onError(err.message))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadAnalytics();
  }, [onError]);

  const handleScheduleInterviews = async () => {
    setScheduling(true);
    console.debug('[AnalyticsView] Schedule interviews clicked');
    try {
      const result = await scheduleAllInterviews();
      console.debug('[AnalyticsView] Schedule interviews success', result);
      if (onSuccess) onSuccess(`✓ ${result.count || 0} interviews scheduled successfully!`);
    } catch (err) {
      console.error('[AnalyticsView] Schedule interviews failed', err);
      onError(`Failed to schedule interviews: ${err.message}`);
    } finally {
      setScheduling(false);
    }
  };

  const handleToggleWalkIn = async (isEnabled) => {
    setTogglingWalkIn(true);
    try {
      const result = await setWalkInInterviewing(isEnabled);
      if (onSuccess) onSuccess(result?.message || (isEnabled ? 'Walk-in interviewing started.' : 'Walk-in interviewing stopped.'));
      loadAnalytics();
    } catch (err) {
      onError(err.message || 'Failed to update walk-in interviewing status.');
    } finally {
      setTogglingWalkIn(false);
    }
  };

  if (loading) return <div className="p-20 text-center"><Loader2 className="animate-spin mx-auto w-10 h-10 text-blue-600" /></div>;
  if (!data) return <div className="text-center text-gray-500 p-12">No analytics data available.</div>;

  // Destructure based on C# Controller JSON structure (camelCase)
  const { summary, interviews } = data;
  const canToggleWalkIn = Boolean(data.canToggleWalkInInterviewing);
  const isWalkInInterviewing = Boolean(data.isWalkInInterviewing);
  const roomName = attendanceStatus?.roomDetails?.roomName || attendanceStatus?.RoomDetails?.RoomName;
  const unscheduledInterviewsCount =
    interviews?.unscheduledAcceptedCount ??
    interviews?.unscheduledCount ??
    Math.max((interviews?.acceptedRequestsCount || 0) - (interviews?.scheduledCount || 0), 0);
  const shouldShowScheduleAll = isJobFairDay && unscheduledInterviewsCount > 0;
  const shouldShowWalkInToggle = isJobFairDay || isWalkInInterviewing;

  return (
    <div className="space-y-8 pb-10">
      <div className="flex justify-between items-end">
        <div>
           <h2 className="text-2xl font-bold text-gray-900">Recruitment Dashboard</h2>
           <p className="text-gray-500">Overview for {data.companyName}</p>
           {roomName && <p className="text-xs text-blue-700 mt-1">Assigned Room: {roomName}</p>}
        </div>
        <div className="flex items-center gap-2">
          {shouldShowScheduleAll && (
            <button
              onClick={handleScheduleInterviews}
              disabled={scheduling}
              className="px-6 py-2.5 bg-gradient-to-r from-purple-600 to-blue-600 text-white font-bold rounded-lg hover:shadow-lg transition-all flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {scheduling ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  Scheduling...
                </>
              ) : (
                <>
                  <Calendar className="w-5 h-5" />
                  Schedule All Interviews
                </>
              )}
            </button>
          )}

          {shouldShowWalkInToggle && (
            <button
              onClick={() => handleToggleWalkIn(!isWalkInInterviewing)}
              disabled={togglingWalkIn || (!canToggleWalkIn && !isWalkInInterviewing)}
              className={`px-4 py-2.5 text-white font-bold rounded-lg transition-all flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed ${isWalkInInterviewing ? 'bg-rose-600 hover:bg-rose-700' : 'bg-emerald-600 hover:bg-emerald-700'}`}
              title={!canToggleWalkIn && !isWalkInInterviewing ? 'Walk-in interviewing can only be started on Job Fair day between 9:00 AM and 4:30 PM PKT and when marked present.' : undefined}
            >
              {togglingWalkIn ? <Loader2 className="w-4 h-4 animate-spin" /> : null}
              {isWalkInInterviewing ? 'Stop Walk-In Interviewing' : 'Start Walk-In Interviewing'}
            </button>
          )}
        </div>
      </div>
      
      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard 
          icon={TrendingUp} title="Hiring Rate" 
          value={`${summary.hiringRate}%`} 
          sub={`Conversion: ${summary.conversionRate}%`}
          color="blue" 
        />
        <StatCard 
          icon={Users} title="Candidates" 
          value={summary.totalStudentsCalled} 
          sub="Total reached out"
          color="purple" 
        />
        <StatCard 
          icon={CheckCircle} title="Hired" 
          value={summary.totalHired} 
          sub="Offers Accepted"
          color="green" 
        />
        <StatCard 
          icon={BookOpen} title="FYP Projects" 
          value={summary.totalFYPProjects} 
          sub="Projects Tracked"
          color="orange" 
        />
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Pipeline Chart */}
        <div className="lg:col-span-2 bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
          <h3 className="font-bold text-gray-900 mb-6">Recruitment Pipeline</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3 mb-6">
            <button
              onClick={() => onNavigateToInterviews && onNavigateToInterviews('pending', 'sent')}
              className="text-left rounded-xl border border-blue-200 bg-blue-50 px-4 py-3 hover:bg-blue-100"
            >
              <p className="text-xs text-blue-700 font-semibold">Requests Sent</p>
              <p className="text-xl font-bold text-blue-900">{interviews.requestsSentCount || 0}</p>
            </button>
            <button
              onClick={() => onNavigateToInterviews && onNavigateToInterviews('accepted')}
              className="text-left rounded-xl border border-green-200 bg-green-50 px-4 py-3 hover:bg-green-100"
            >
              <p className="text-xs text-green-700 font-semibold">Accepted Requests</p>
              <p className="text-xl font-bold text-green-900">{interviews.acceptedRequestsCount || 0}</p>
            </button>
            <button
              onClick={() => onNavigateToInterviews && onNavigateToInterviews('pending', 'inbox')}
              className="text-left rounded-xl border border-orange-200 bg-orange-50 px-4 py-3 hover:bg-orange-100"
            >
              <p className="text-xs text-orange-700 font-semibold">Pending Requests</p>
              <p className="text-xl font-bold text-orange-900">{interviews.pendingRequestsCount || 0}</p>
            </button>
          </div>
          <div className="space-y-6">
            <ProgressBar label="Shortlisted" value={interviews.shortlistedCount} total={summary.totalStudentsCalled} color="bg-blue-500" />
            <ProgressBar label="Scheduled Interviews" value={interviews.scheduledCount} total={summary.totalStudentsCalled} color="bg-yellow-500" />
            <ProgressBar label="Hired" value={interviews.hiredCount} total={summary.totalStudentsCalled} color="bg-green-500" />
            <ProgressBar label="Rejected" value={interviews.rejectedCount} total={summary.totalStudentsCalled} color="bg-red-400" />
          </div>
        </div>

        {/* Action Items */}
        <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200 flex flex-col">
           <h3 className="font-bold text-gray-900 mb-4">Upcoming</h3>
           <div className="space-y-4 flex-1">
             {interviews.scheduledInterviews && interviews.scheduledInterviews.length > 0 ? (
                interviews.scheduledInterviews.slice(0, 3).map((int, i) => (
                  <div key={i} className="flex gap-3 items-start p-3 bg-blue-50 rounded-xl">
                    <Clock className="w-5 h-5 text-blue-600 mt-0.5" />
                    <div>
                      <p className="text-sm font-bold text-gray-900">{int.studentName}</p>
                      <p className="text-xs text-blue-700">
                        {new Date(int.scheduledTime).toLocaleDateString()} at {new Date(int.scheduledTime).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}
                      </p>
                    </div>
                  </div>
                ))
             ) : (
                <div className="text-center text-gray-400 py-8">
                  <CheckCircle className="w-12 h-12 mx-auto mb-2 opacity-20" />
                  <p className="text-sm">No upcoming interviews.</p>
               </div>
             )}
           </div>
        </div>
      </div>
    </div>
  );
}

// Sub-components (StatCard, ProgressBar) remain the same as previous GoodUI version...
function StatCard({ icon: Icon, title, value, sub, color }) {
  const colors = {
    blue: 'bg-blue-50 text-blue-600', purple: 'bg-purple-50 text-purple-600',
    green: 'bg-green-50 text-green-600', orange: 'bg-orange-50 text-orange-600',
  };
  return (
    <div className="p-6 rounded-2xl border border-gray-100 bg-white shadow-sm hover:shadow-md transition-shadow">
      <div className="flex justify-between items-start mb-4">
        <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${colors[color]}`}>
           <Icon className="w-6 h-6" />
        </div>
      </div>
      <div>
        <h4 className="text-3xl font-bold text-gray-900">{value}</h4>
        <p className="text-xs font-bold uppercase tracking-wider text-gray-400 mt-1">{title}</p>
        <p className="text-xs text-gray-500 mt-1">{sub}</p>
      </div>
    </div>
  );
}

function ProgressBar({ label, value, total, color }) {
  const percent = total > 0 ? Math.round((value / total) * 100) : 0;
  return (
    <div>
      <div className="flex justify-between text-sm mb-1.5 font-medium">
        <span className="text-gray-700">{label}</span>
        <span className="text-gray-900">{value} <span className="text-gray-400 text-xs">({percent}%)</span></span>
      </div>
      <div className="w-full bg-gray-100 rounded-full h-2.5 overflow-hidden">
        <div className={`h-2.5 rounded-full ${color}`} style={{ width: `${percent}%` }}></div>
      </div>
    </div>
  );
}