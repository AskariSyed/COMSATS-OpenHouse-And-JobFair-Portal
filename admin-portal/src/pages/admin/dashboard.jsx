/* eslint-disable no-unused-vars */
import React, { useEffect, useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Users, 
  Building2, 
  DoorOpen, 
  Trophy, 
  FileText, 
  TrendingUp, 
  UserCheck,
  Maximize,
  Minimize
} from 'lucide-react';
import { 
  PieChart, 
  Pie, 
  Cell, 
  ResponsiveContainer, 
  Tooltip, 
  Legend, 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid 
} from 'recharts';
import api from '../../lib/api';

// ----------------------------------
// Helper Component: Stat Card
// ----------------------------------
const StatCard = ({ title, value, icon: Icon, color, bgColor, onClick }) => (
  <div 
    onClick={onClick}
    className={`bg-white p-4 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-all duration-200 ${onClick ? 'cursor-pointer hover:scale-[1.02]' : ''}`}
  >
    <div className="flex items-center justify-between">
      <div>
        <p className="text-xs font-medium text-gray-500 mb-1">{title}</p>
        <h3 className="text-2xl font-bold text-gray-900 leading-none">{value}</h3>
      </div>
      <div className={`p-2.5 rounded-lg ${bgColor}`}>
        <Icon className={`w-5 h-5 ${color}`} />
      </div>
    </div>
  </div>
);

// ----------------------------------
// Main Dashboard Component
// ----------------------------------
const Dashboard = () => {
  const navigate = useNavigate();
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [isPresenting, setIsPresenting] = useState(false);
  const dashboardRef = useRef(null);

  const togglePresentationMode = async () => {
    if (!document.fullscreenElement) {
      try {
        await dashboardRef.current?.requestFullscreen();
      } catch (err) {
        console.error("Error attempting to enable fullscreen:", err);
      }
    } else {
      if (document.exitFullscreen) {
        await document.exitFullscreen();
      }
    }
  };

  useEffect(() => {
    const handleFullscreenChange = () => {
      setIsPresenting(!!document.fullscreenElement);
    };

    document.addEventListener('fullscreenchange', handleFullscreenChange);
    return () => document.removeEventListener('fullscreenchange', handleFullscreenChange);
  }, []);

  const fetchDashboardData = async (silent = false) => {
    if (!silent) setLoading(true);
    try {
      const response = await api.get('/admin/dashboard/overview');
      setStats(response.data);
    } catch (error) {
      console.error("Error fetching dashboard stats:", error);
    } finally {
      if (!silent) setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, []);

  useEffect(() => {
    let interval;
    if (isPresenting) {
      // Refresh every 1.5 minutes in presentation mode
      interval = setInterval(() => {
        fetchDashboardData(true);
      }, 90000);
    }
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [isPresenting]);

  if (loading) {
    return (
      <div className="h-[80vh] flex flex-col items-center justify-center text-gray-400">
        <div className="w-10 h-10 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin mb-4"></div>
        <p>Loading Analytics...</p>
      </div>
    );
  }

  // Data for Pie Chart (Recruitment)
  const recruitmentData = [
    { name: 'Hired', value: stats?.studentsHired || 0 },
    { name: 'Shortlisted', value: stats?.studentsShortlisted || 0 },
  ];
  const PIE_COLORS = ['#10B981', '#6366F1']; // Emerald (Hired), Indigo (Shortlisted)

  // Data for Bar Chart (Surveys)
  const surveyData = [
    { name: 'CDC Surveys', count: stats?.cdcSurveysReceived || 0 },
    { name: 'Dept Surveys', count: stats?.departmentSurveysReceived || 0 },
  ];

  const totalRequests = stats?.totalInterviewRequests || 0;
  const acceptedRequests = stats?.totalAcceptedRequests || 0;
  const notAcceptedRequests = Math.max(0, totalRequests - acceptedRequests);
  const requestAcceptanceData = [
    { name: 'Accepted', value: acceptedRequests },
    { name: 'Not Accepted', value: notAcceptedRequests },
  ];
  const requestAcceptanceHasData = totalRequests > 0;
  const requestAcceptancePieData = requestAcceptanceHasData
    ? requestAcceptanceData
    : [{ name: 'No Data', value: 1 }];
  const REQUEST_RATIO_COLORS = ['#10B981', '#EF4444'];

  const requestAcceptanceRatio = stats?.requestAcceptanceRatio || 0;

  const interviewStageData = [
    { name: 'Total', count: stats?.totalInterviews || 0, color: '#0EA5E9' },
    { name: 'Scheduled', count: stats?.interviewsScheduled || 0, color: '#8B5CF6' },
    { name: 'Queued', count: stats?.interviewsQueued || 0, color: '#F59E0B' },
    { name: 'Did Not Appear', count: stats?.interviewsDidNotAppear || 0, color: '#6B7280' },
    { name: 'Hired', count: stats?.studentsHired || 0, color: '#10B981' },
    { name: 'Shortlisted', count: stats?.studentsShortlisted || 0, color: '#6366F1' },
    { name: 'Rejected', count: stats?.interviewsRejected || 0, color: '#EF4444' },
  ];

  const topRequestedCandidates = stats?.topRequestedCandidates?.length
    ? stats.topRequestedCandidates
    : (stats?.topRequestedCandidateId
      ? [{
          studentId: stats.topRequestedCandidateId,
          candidateName: stats.topRequestedCandidateName,
          count: stats.topRequestedCandidateRequestCount,
        }]
      : []);

  const topHiredCandidates = stats?.topHiredCandidates?.length
    ? stats.topHiredCandidates
    : (stats?.topHiredCandidateId
      ? [{
          studentId: stats.topHiredCandidateId,
          candidateName: stats.topHiredCandidateName,
          count: stats.topHiredCandidateHireCount,
        }]
      : []);

  const recruitmentHasData = (stats?.studentsHired || 0) + (stats?.studentsShortlisted || 0) > 0;
  const recruitmentPieData = recruitmentHasData
    ? recruitmentData
    : [{ name: 'No Data', value: 1 }];

  return (
    <div 
      ref={dashboardRef}
      className={`w-full max-w-full animate-fade-in ${
        isPresenting 
          ? 'h-screen w-screen bg-gray-50 flex flex-col p-4 gap-3 overflow-hidden text-sm' 
          : 'space-y-4 pb-2 overflow-x-hidden'
      }`}
    >
      
      {/* 1. Header */}
      <div className={`flex justify-between items-center ${isPresenting ? 'flex-shrink-0' : ''}`}>
        <div>
          <h1 className={`${isPresenting ? 'text-2xl' : 'text-xl'} font-bold text-gray-900`}>Admin Dashboard</h1>
          {!isPresenting && <p className="text-gray-500 text-sm mt-1">Overview of the current Job Fair statistics and activities.</p>}
        </div>
        <button 
          onClick={togglePresentationMode} 
          className="p-2 bg-indigo-50 text-indigo-600 rounded-lg hover:bg-indigo-100 flex items-center gap-2 font-medium"
          title={isPresenting ? "Exit Presentation Mode (ESC)" : "Enter Presentation Mode"}
        >
          {isPresenting ? <><Minimize className="w-5 h-5" /> <span className="hidden sm:inline">Exit Presentation</span></> : <><Maximize className="w-5 h-5" /> <span className="hidden sm:inline">Presentation Mode</span></>}
        </button>
      </div>

      {/* 2. Key Statistics Cards */}
      <div className={`grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 ${isPresenting ? 'gap-2 flex-shrink-0' : 'gap-3'}`}>
        <StatCard 
          title="Total Students" 
          value={stats?.totalStudents} 
          icon={Users} 
          color="text-blue-600" 
          bgColor="bg-blue-50"
          onClick={() => navigate('/admin/students')}
        />
        <StatCard 
          title="Companies" 
          value={stats?.totalCompanies} 
          icon={Building2} 
          color="text-purple-600" 
          bgColor="bg-purple-50"
          onClick={() => navigate('/admin/companies')}
        />
        <StatCard 
          title="Total Rooms" 
          value={stats?.totalRooms} 
          icon={DoorOpen} 
          color="text-orange-600" 
          bgColor="bg-orange-50"
          onClick={() => navigate('/admin/rooms')}
        />
        <StatCard 
          title="Success Rate (Hired)" 
          value={stats?.studentsHired} 
          icon={Trophy} 
          color="text-emerald-600" 
          bgColor="bg-emerald-50" 
        />
      </div>

      {/* 3. Charts Section */}
      <div className={`grid grid-cols-1 lg:grid-cols-2 ${isPresenting ? 'gap-2 flex-1 min-h-0' : 'gap-3'}`}>
        <div className={`bg-white rounded-xl shadow-sm border border-gray-100 flex flex-col ${isPresenting ? 'p-3' : 'p-4'}`}>
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-base font-bold text-gray-800">Request to Acceptance Ratio</h3>
            <span className="text-xs font-medium px-2 py-1 bg-indigo-100 text-indigo-700 rounded-full">
              {requestAcceptanceRatio}% Accepted
            </span>
          </div>

          <div className={`flex-1 min-h-0 ${isPresenting ? '' : 'h-44'}`}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={requestAcceptancePieData}
                  cx="50%"
                  cy="50%"
                  innerRadius={42}
                  outerRadius={62}
                  paddingAngle={4}
                  dataKey="value"
                >
                  {requestAcceptancePieData.map((entry, index) => (
                    <Cell
                      key={`request-ratio-cell-${index}`}
                      fill={requestAcceptanceHasData ? REQUEST_RATIO_COLORS[index % REQUEST_RATIO_COLORS.length] : '#D1D5DB'}
                    />
                  ))}
                </Pie>
                <Tooltip contentStyle={{ borderRadius: '8px' }} />
                <Legend verticalAlign="bottom" height={26} />
              </PieChart>
            </ResponsiveContainer>
          </div>
          {!requestAcceptanceHasData && (
            <p className="text-[11px] text-gray-400 text-center mt-1">No request data available</p>
          )}
        </div>

        <div className={`bg-white rounded-xl shadow-sm border border-gray-100 flex flex-col ${isPresenting ? 'p-3' : 'p-4'}`}>
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-base font-bold text-gray-800">Interview Stage Snapshot</h3>
            <span className="text-xs font-medium px-2 py-1 bg-slate-100 text-slate-700 rounded-full">Current Job Fair</span>
          </div>
          <div className={`flex-1 min-h-0 ${isPresenting ? '' : 'h-72'}`}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={interviewStageData} margin={{ bottom: 48 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis
                  dataKey="name"
                  axisLine={false}
                  tickLine={false}
                  angle={-30}
                  textAnchor="end"
                  height={60}
                  tick={{ fontSize: 11 }}
                />
                <YAxis allowDecimals={false} />
                <Tooltip cursor={{ fill: '#f3f4f6' }} />
                <Bar dataKey="count" radius={[6, 6, 0, 0]} barSize={34}>
                  {interviewStageData.map((entry, index) => (
                    <Cell key={`interview-stage-cell-${index}`} fill={entry.color} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      <div className={`grid grid-cols-1 lg:grid-cols-3 ${isPresenting ? 'gap-2 flex-1 min-h-0' : 'gap-3'}`}>
        
        {/* Recruitment Progress (Pie Chart) */}
        <div className={`lg:col-span-2 bg-white rounded-xl shadow-sm border border-gray-100 flex flex-col ${isPresenting ? 'p-3' : 'p-4'}`}>
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-base font-bold text-gray-800">Recruitment Impact</h3>
            <span className="text-xs font-medium px-2 py-1 bg-green-100 text-green-700 rounded-full">Live Data</span>
          </div>
          <div className={`flex-1 min-h-0 ${isPresenting ? '' : 'h-52'}`}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={recruitmentPieData}
                  cx="50%"
                  cy="50%"
                  innerRadius={52}
                  outerRadius={74}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {recruitmentPieData.map((entry, index) => (
                    <Cell
                      key={`cell-${index}`}
                      fill={recruitmentHasData ? PIE_COLORS[index % PIE_COLORS.length] : '#D1D5DB'}
                    />
                  ))}
                </Pie>
                <Tooltip contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }} />
                <Legend verticalAlign="bottom" height={36}/>
              </PieChart>
            </ResponsiveContainer>
          </div>
          {!recruitmentHasData && (
            <p className="text-[11px] text-gray-400 text-center mt-1">No recruitment data available</p>
          )}
          <div className="grid grid-cols-2 gap-2 mt-2 text-center">
            <div className="p-2 bg-gray-50 rounded-lg">
              <p className="text-xs text-gray-500">Total Shortlisted</p>
              <p className="text-lg font-bold text-indigo-600">{stats?.studentsShortlisted}</p>
            </div>
            <div className="p-2 bg-gray-50 rounded-lg">
              <p className="text-xs text-gray-500">Total Hired</p>
              <p className="text-lg font-bold text-emerald-600">{stats?.studentsHired}</p>
            </div>
          </div>
        </div>

        {/* Survey Feedback (Bar Chart or List) */}
        <div className={`bg-white rounded-xl shadow-sm border border-gray-100 flex flex-col ${isPresenting ? 'p-3' : 'p-4'}`}>
          <h3 className="text-base font-bold text-gray-800 mb-2">Feedback Received</h3>
          
          {/* Small Bar Chart for Surveys */}
          <div className={`flex-1 min-h-0 ${isPresenting ? '' : 'h-40'}`}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={surveyData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="name" tick={{fontSize: 12}} axisLine={false} tickLine={false} />
                <YAxis hide />
                <Tooltip cursor={{fill: '#f3f4f6'}} contentStyle={{ borderRadius: '8px' }} />
                <Bar dataKey="count" fill="#3B82F6" radius={[4, 4, 0, 0]} barSize={40} />
              </BarChart>
            </ResponsiveContainer>
          </div>

          {/* Text Summary */}
          <div className="mt-2 space-y-2">
            <div className="flex items-center p-2 bg-blue-50 rounded-lg border border-blue-100">
              <FileText className="w-5 h-5 text-blue-600 mr-3" />
              <div>
                <p className="text-xs text-blue-600 font-semibold uppercase">CDC Feedback</p>
                <p className="text-sm text-gray-600">{stats?.cdcSurveysReceived} forms submitted</p>
              </div>
            </div>
            <div className="flex items-center p-2 bg-purple-50 rounded-lg border border-purple-100">
              <UserCheck className="w-5 h-5 text-purple-600 mr-3" />
              <div>
                <p className="text-xs text-purple-600 font-semibold uppercase">Dept. Feedback</p>
                <p className="text-sm text-gray-600">{stats?.departmentSurveysReceived} forms submitted</p>
              </div>
            </div>
          </div>
        </div>

      </div>

      {/* Bottom Section: Top Candidates */}
      <div className={`grid grid-cols-1 lg:grid-cols-2 ${isPresenting ? 'gap-2 flex-1 min-h-0' : 'gap-3'}`}>
        <div className={`bg-white rounded-xl shadow-sm border border-gray-100 flex flex-col overflow-hidden ${isPresenting ? 'p-3' : 'p-4'}`}>
          <p className="text-xs font-semibold text-gray-500 uppercase">Top 5 Candidates By Company Requests</p>
          <div className="mt-2 space-y-1 overflow-y-auto flex-1 min-h-0">
            {topRequestedCandidates.length > 0 ? topRequestedCandidates.slice(0, 5).map((candidate, index) => (
              <div key={`top-requested-${candidate.studentId || index}`} className="flex items-center justify-between p-1.5 rounded-lg hover:bg-gray-50">
                <div>
                  <p className="text-xs font-semibold text-gray-900">{index + 1}. {candidate.candidateName || 'Unknown Candidate'}</p>
                  <p className="text-xs text-gray-500">{candidate.count || 0} company requests</p>
                </div>
                {candidate.studentId && (
                  <button
                    onClick={() => navigate(`/admin/students/${candidate.studentId}`)}
                    className="px-2.5 py-1 rounded-lg text-xs font-medium bg-indigo-50 text-indigo-700 hover:bg-indigo-100"
                  >
                    View Profile
                  </button>
                )}
              </div>
            )) : (
              <p className="text-sm text-gray-500">No data yet</p>
            )}
          </div>
        </div>

        <div className={`bg-white rounded-xl shadow-sm border border-gray-100 flex flex-col overflow-hidden ${isPresenting ? 'p-3' : 'p-4'}`}>
          <p className="text-xs font-semibold text-gray-500 uppercase">Top 5 Candidates By Hires</p>
          <div className="mt-2 space-y-1 overflow-y-auto flex-1 min-h-0">
            {topHiredCandidates.length > 0 ? topHiredCandidates.slice(0, 5).map((candidate, index) => (
              <div key={`top-hired-${candidate.studentId || index}`} className="flex items-center justify-between p-1.5 rounded-lg hover:bg-gray-50">
                <div>
                  <p className="text-xs font-semibold text-gray-900">{index + 1}. {candidate.candidateName || 'Unknown Candidate'}</p>
                  <p className="text-xs text-gray-500">{candidate.count || 0} hired outcomes</p>
                </div>
                {candidate.studentId && (
                  <button
                    onClick={() => navigate(`/admin/students/${candidate.studentId}`)}
                    className="px-2.5 py-1 rounded-lg text-xs font-medium bg-emerald-50 text-emerald-700 hover:bg-emerald-100"
                  >
                    View Profile
                  </button>
                )}
              </div>
            )) : (
              <p className="text-sm text-gray-500">No data yet</p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;