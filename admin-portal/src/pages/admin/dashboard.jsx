/* eslint-disable no-unused-vars */
import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Users, 
  Building2, 
  DoorOpen, 
  Trophy, 
  FileText, 
  TrendingUp, 
  UserCheck 
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
    className={`bg-white p-6 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-all duration-200 ${onClick ? 'cursor-pointer hover:scale-105' : ''}`}
  >
    <div className="flex items-center justify-between">
      <div>
        <p className="text-sm font-medium text-gray-500 mb-1">{title}</p>
        <h3 className="text-3xl font-bold text-gray-900">{value}</h3>
      </div>
      <div className={`p-3 rounded-lg ${bgColor}`}>
        <Icon className={`w-6 h-6 ${color}`} />
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

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        // Connects to AdminController.cs -> GetDashboardOverview()
        const response = await api.get('/admin/dashboard/overview');
        setStats(response.data);
      } catch (error) {
        console.error("Error fetching dashboard stats:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

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

  return (
    <div className="space-y-8 animate-fade-in">
      
      {/* 1. Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Admin Dashboard</h1>
        <p className="text-gray-500 mt-1">Overview of the current Job Fair statistics and activities.</p>
      </div>

      {/* 2. Key Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
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
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Recruitment Progress (Pie Chart) */}
        <div className="lg:col-span-2 bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-bold text-gray-800">Recruitment Impact</h3>
            <span className="text-xs font-medium px-2 py-1 bg-green-100 text-green-700 rounded-full">Live Data</span>
          </div>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={recruitmentData}
                  cx="50%"
                  cy="50%"
                  innerRadius={80}
                  outerRadius={110}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {recruitmentData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={PIE_COLORS[index % PIE_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }} />
                <Legend verticalAlign="bottom" height={36}/>
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="grid grid-cols-2 gap-4 mt-4 text-center">
            <div className="p-3 bg-gray-50 rounded-lg">
              <p className="text-xs text-gray-500">Total Shortlisted</p>
              <p className="text-xl font-bold text-indigo-600">{stats?.studentsShortlisted}</p>
            </div>
            <div className="p-3 bg-gray-50 rounded-lg">
              <p className="text-xs text-gray-500">Total Hired</p>
              <p className="text-xl font-bold text-emerald-600">{stats?.studentsHired}</p>
            </div>
          </div>
        </div>

        {/* Survey Feedback (Bar Chart or List) */}
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 flex flex-col">
          <h3 className="text-lg font-bold text-gray-800 mb-6">Feedback Received</h3>
          
          {/* Small Bar Chart for Surveys */}
          <div className="flex-1 min-h-[200px]">
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
          <div className="mt-6 space-y-4">
            <div className="flex items-center p-3 bg-blue-50 rounded-lg border border-blue-100">
              <FileText className="w-5 h-5 text-blue-600 mr-3" />
              <div>
                <p className="text-xs text-blue-600 font-semibold uppercase">CDC Feedback</p>
                <p className="text-sm text-gray-600">{stats?.cdcSurveysReceived} forms submitted</p>
              </div>
            </div>
            <div className="flex items-center p-3 bg-purple-50 rounded-lg border border-purple-100">
              <UserCheck className="w-5 h-5 text-purple-600 mr-3" />
              <div>
                <p className="text-xs text-purple-600 font-semibold uppercase">Dept. Feedback</p>
                <p className="text-sm text-gray-600">{stats?.departmentSurveysReceived} forms submitted</p>
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
};

export default Dashboard;