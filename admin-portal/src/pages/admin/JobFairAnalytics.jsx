/* eslint-disable no-unused-vars */
import React, { useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';
import { 
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell 
} from 'recharts';
import { 
  Users, Building2, Briefcase, CheckCircle, Download, Loader2
} from 'lucide-react';
import api from '../../lib/api';
import toast from 'react-hot-toast';

// 👇 NEW IMPORTS FOR PDF GENERATION
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

const StatCard = ({ title, value, subtext, icon: Icon, color }) => (
  <div className="bg-white p-2.5 rounded-lg border border-gray-100 shadow-sm flex items-start justify-between">
    <div>
      <p className="text-xs font-medium text-gray-500">{title}</p>
      <h3 className="text-lg font-bold text-gray-900 mt-1">{value}</h3>
      {subtext && <p className="text-xs text-gray-400 mt-0.5">{subtext}</p>}
    </div>
    <div className={`p-2 rounded-lg ${color} bg-opacity-10`}>
      <Icon className={color.replace('bg-', 'text-')} size={18} />
    </div>
  </div>
);

const JobFairAnalytics = () => {
  const location = useLocation();
  const [fairs, setFairs] = useState([]);
  const [selectedFairId, setSelectedFairId] = useState(location?.state?.jobFairId || null);
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [downloading, setDownloading] = useState(false); // New state for download button

  // 1. Fetch Job Fairs
  useEffect(() => {
    const fetchFairs = async () => {
      try {
        const res = await api.get('/admin/jobfairs');
        setFairs(res.data.jobFairs);
        // If no jobFairId in state, use active or first one
        if (!selectedFairId) {
          const active = res.data.jobFairs.find(f => f.isActive) || res.data.jobFairs[0];
          if (active) setSelectedFairId(active.jobFairId);
        }
      } catch (error) {
        toast.error("Failed to load job fairs");
      }
    };
    fetchFairs();
  }, []);

  // 2. Fetch Analytics
  useEffect(() => {
    if (!selectedFairId) return;

    const fetchAnalytics = async () => {
      setLoading(true);
      try {
        const res = await api.get(`/admin/jobfairs/${selectedFairId}/analytics`);
        setData(res.data);
      } catch (error) {
        toast.error("Failed to load analytics data");
      } finally {
        setLoading(false);
      }
    };

    fetchAnalytics();
  }, [selectedFairId]);

  // ----------------------------------------------------------------------
  // 🖨️ PDF GENERATION LOGIC
  // ----------------------------------------------------------------------
  const handleDownloadReport = async () => {
    if (!data) {
      toast.error("No data available to generate report");
      return;
    }

    setDownloading(true);
    try {
      // Get current job fair info
      const currentFair = fairs.find(f => f.jobFairId === selectedFairId);
      
      // Initialize PDF
      const doc = new jsPDF();

      // --- Header ---
      doc.setFontSize(22);
      doc.setTextColor(79, 70, 229); // Indigo Color
      doc.text("Job Fair Impact Report", 14, 20);
      
      doc.setFontSize(12);
      doc.setTextColor(100);
      doc.text(`Event: ${currentFair?.semester || 'N/A'}`, 14, 30);
      doc.text(`Date: ${currentFair ? new Date(currentFair.date).toLocaleDateString() : 'N/A'}`, 14, 36);

      // --- Executive Summary Section ---
      doc.setFontSize(14);
      doc.setTextColor(0);
      doc.text("Executive Summary", 14, 50);
      
      const summaryData = [
        ['Total Students', data.overallStats.totalStudents],
        ['Participating Companies', data.overallStats.totalCompanies],
        ['Total Job Openings', data.overallStats.totalJobs],
        ['Interviews Conducted', data.overallStats.totalInterviews],
        ['Students Hired', data.interviewStats.hired],
        ['Students Shortlisted', data.interviewStats.shortlisted],
        ['Hiring Rate', `${data.interviewStats.hiringRate}%`]
      ];

      autoTable(doc, {
        startY: 55,
        head: [['Metric', 'Value']],
        body: summaryData,
        theme: 'striped',
        headStyles: { fillColor: [79, 70, 229] }, // Indigo header
        styles: { fontSize: 10 },
        columnStyles: { 0: { fontStyle: 'bold' } }
      });

      // --- Top Recruiters Table ---
      let finalY = doc.lastAutoTable.finalY + 15;
      doc.setFontSize(14);
      doc.text("Top Recruiters", 14, finalY);

      const recruiterData = (data?.companyParticipation || []).slice(0, 10).map(c => [
        c.companyName, 
        c.totalInterviews, 
        c.hiredCount
      ]);

      autoTable(doc, {
        startY: finalY + 5,
        head: [['Company', 'Interviews', 'Hires']],
        body: recruiterData,
        theme: 'grid',
        headStyles: { fillColor: [16, 185, 129] }, // Emerald header
      });

      // --- Department Performance Table ---
      finalY = doc.lastAutoTable.finalY + 15;
      doc.setFontSize(14);
      doc.text("Department Performance", 14, finalY);

      const deptData = (data?.studentsByDepartment || []).map(d => [
        d.department,
        d.count,
        d.hired
      ]);

      autoTable(doc, {
        startY: finalY + 5,
        head: [['Department', 'Total Students', 'Hired']],
        body: deptData,
        theme: 'grid',
        headStyles: { fillColor: [245, 158, 11] }, // Amber header
      });

      // --- Top Students Table ---
      finalY = doc.lastAutoTable.finalY + 15;
      doc.setFontSize(14);
      doc.text("Top Performing Students", 14, finalY);

      const studentData = (data?.topStudents || []).slice(0, 10).map(s => [
        s.name,
        s.department,
        s.cgpa.toFixed(2),
        s.hired ? 'Yes' : 'No'
      ]);

      autoTable(doc, {
        startY: finalY + 5,
        head: [['Name', 'Department', 'CGPA', 'Hired']],
        body: studentData,
        theme: 'grid',
        headStyles: { fillColor: [99, 102, 241] }, // Indigo header
      });

      // --- Footer ---
      const pageCount = doc.internal.getNumberOfPages();
      for (let i = 1; i <= pageCount; i++) {
        doc.setPage(i);
        doc.setFontSize(10);
        doc.setTextColor(150);
        doc.text(`Page ${i} of ${pageCount} - Generated by JobFair Portal`, 105, 290, { align: 'center' });
      }

      // Save File
      const fileName = `JobFair_Report_${currentFair?.semester.replace(/\s+/g, '_') || 'Export'}_${new Date().toLocaleDateString().replace(/\//g, '-')}.pdf`;
      doc.save(fileName);
      toast.success("Report downloaded successfully!");

    } catch (error) {
      console.error(error);
      toast.error("Failed to generate PDF");
    } finally {
      setDownloading(false);
    }
  };

  if (!selectedFairId && !loading) return <div className="p-10">Loading events...</div>;

  const COLORS = ['#10B981', '#6366F1', '#EF4444', '#F59E0B'];

  return (
    <div className="space-y-8 animate-fade-in pb-10">
      
      {/* Header & Selector */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Event Analytics</h1>
          <p className="text-gray-500 text-sm">Real-time insights and performance metrics.</p>
        </div>
        
        <div className="flex gap-3">
          <select 
            className="border-gray-300 border rounded-lg px-4 py-2 text-sm focus:ring-2 focus:ring-indigo-500 outline-none"
            value={selectedFairId || ''}
            onChange={(e) => setSelectedFairId(e.target.value)}
          >
            {fairs.map(f => (
              <option key={f.jobFairId} value={f.jobFairId}>
                {f.semester} ({new Date(f.date).toLocaleDateString()})
              </option>
            ))}
          </select>

          <button 
            onClick={handleDownloadReport}
            disabled={downloading}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 transition disabled:opacity-70 disabled:cursor-not-allowed"
          >
            {downloading ? (
              <Loader2 size={16} className="animate-spin" /> 
            ) : (
              <Download size={16} />
            )}
            {downloading ? 'Generating...' : 'Download PDF Report'}
          </button>
        </div>
      </div>

      {loading || !data ? (
        <div className="flex justify-center py-20">
          <Loader2 size={40} className="animate-spin text-indigo-600" />
        </div>
      ) : (
        <>
          {/* 1. KPI Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <StatCard 
              title="Registered Students" 
              value={data.overallStats.totalStudents} 
              icon={Users} 
              color="bg-blue-500" 
            />
            <StatCard 
              title="Participating Companies" 
              value={data.overallStats.totalCompanies} 
              icon={Building2} 
              color="bg-purple-500" 
            />
            <StatCard 
              title="Total Job Openings" 
              value={data.overallStats.totalJobs} 
              icon={Briefcase} 
              color="bg-orange-500" 
            />
            <StatCard 
              title="Interviews Conducted" 
              value={data.overallStats.totalInterviews} 
              subtext={`${data.interviewStats.hiringRate}% Hiring Rate`}
              icon={CheckCircle} 
              color="bg-emerald-500" 
            />
          </div>

          {/* 2. Charts Section */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            
            {/* Hiring Funnel */}
            <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
              <h3 className="font-bold text-gray-800 mb-4">Interview Outcomes</h3>
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={[
                        { name: 'Hired', value: data.interviewStats.hired },
                        { name: 'Shortlisted', value: data.interviewStats.shortlisted },
                        { name: 'Rejected', value: data.interviewStats.rejected },
                        { name: 'Pending', value: data.interviewStats.pending },
                      ]}
                      cx="50%" cy="50%"
                      innerRadius={60} outerRadius={80}
                      paddingAngle={5} dataKey="value"
                    >
                      {COLORS.map((color, index) => <Cell key={`cell-${index}`} fill={color} />)}
                    </Pie>
                    <Tooltip />
                    <Legend verticalAlign="bottom" height={36}/>
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </div>

            {/* Department Performance */}
            <div className="lg:col-span-2 bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
              <h3 className="font-bold text-gray-800 mb-4">Students Hired by Department</h3>
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={data.studentsByDepartment}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} />
                    <XAxis dataKey="department" tick={{fontSize: 12}} />
                    <YAxis />
                    <Tooltip cursor={{fill: '#f3f4f6'}} />
                    <Legend />
                    <Bar dataKey="count" name="Total Students" fill="#E5E7EB" radius={[4,4,0,0]} />
                    <Bar dataKey="hired" name="Hired" fill="#10B981" radius={[4,4,0,0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          </div>

          {/* 3. Tables Grid */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            
            {/* Top Recruiters */}
            <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
              <div className="p-5 border-b border-gray-100 flex justify-between items-center">
                <h3 className="font-bold text-gray-800">Top Recruiters</h3>
                <span className="text-xs bg-indigo-50 text-indigo-600 px-2 py-1 rounded font-medium">By Hires</span>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm">
                  <thead className="bg-gray-50 text-gray-500">
                    <tr>
                      <th className="px-5 py-3 font-medium">Company</th>
                      <th className="px-5 py-3 font-medium text-right">Interviews</th>
                      <th className="px-5 py-3 font-medium text-right">Hired</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {(data?.companyParticipation || []).slice(0, 5).map((company) => (
                      <tr key={company.companyId} className="hover:bg-gray-50">
                        <td className="px-5 py-3 font-medium text-gray-900">{company.companyName}</td>
                        <td className="px-5 py-3 text-right text-gray-600">{company.totalInterviews}</td>
                        <td className="px-5 py-3 text-right font-bold text-emerald-600">{company.hiredCount}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Top Students */}
            <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
              <div className="p-5 border-b border-gray-100 flex justify-between items-center">
                <h3 className="font-bold text-gray-800">Top Candidates</h3>
                <span className="text-xs bg-amber-50 text-amber-600 px-2 py-1 rounded font-medium">High CGPA</span>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm">
                  <thead className="bg-gray-50 text-gray-500">
                    <tr>
                      <th className="px-5 py-3 font-medium">Name</th>
                      <th className="px-5 py-3 font-medium">Dept</th>
                      <th className="px-5 py-3 font-medium text-right">CGPA</th>
                      <th className="px-5 py-3 font-medium text-center">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {(data?.topStudents || []).slice(0, 5).map((student) => (
                      <tr key={student.studentId} className="hover:bg-gray-50">
                        <td className="px-5 py-3 font-medium text-gray-900">{student.name}</td>
                        <td className="px-5 py-3 text-gray-600">{student.department}</td>
                        <td className="px-5 py-3 text-right font-bold">{student.cgpa.toFixed(2)}</td>
                        <td className="px-5 py-3 text-center">
                          {student.hired ? (
                            <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-emerald-100 text-emerald-800">
                              Hired
                            </span>
                          ) : (
                            <span className="text-gray-400 text-xs">-</span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

          </div>
        </>
      )}
    </div>
  );
};

export default JobFairAnalytics;