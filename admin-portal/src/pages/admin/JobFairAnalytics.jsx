/* eslint-disable no-unused-vars */
import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
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

const StatCard = ({ title, value, subtext, icon: Icon, color, onClick }) => (
  <button
    type="button"
    onClick={onClick}
    className="w-full text-left bg-white p-2.5 rounded-lg border border-gray-100 shadow-sm flex items-start justify-between hover:shadow-md hover:border-indigo-200 transition"
  >
    <div>
      <p className="text-xs font-medium text-gray-500">{title}</p>
      <h3 className="text-lg font-bold text-gray-900 mt-1">{value}</h3>
      {subtext && <p className="text-xs text-gray-400 mt-0.5">{subtext}</p>}
    </div>
    <div className={`p-2 rounded-lg ${color} bg-opacity-10`}>
      <Icon className={color.replace('bg-', 'text-')} size={18} />
    </div>
  </button>
);

const JobFairAnalytics = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const [fairs, setFairs] = useState([]);
  const [selectedFairId, setSelectedFairId] = useState(location?.state?.jobFairId || null);
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [downloading, setDownloading] = useState(false); // New state for download button
  const [detailModal, setDetailModal] = useState({
    open: false,
    type: null,
    title: '',
    rows: []
  });

  const openDetailModal = (type) => {
    if (!data?.detailedLists) {
      toast.error('Detailed data is not available for this event yet.');
      return;
    }

    const mapping = {
      students: {
        title: 'Students Participating In This Job Fair',
        rows: data.detailedLists.students || []
      },
      companies: {
        title: 'Participating Companies & Stats',
        rows: data.detailedLists.companies || []
      },
      jobs: {
        title: 'Job Openings In This Job Fair',
        rows: data.detailedLists.jobOpenings || []
      },
      interviews: {
        title: 'Interviews Conducted With Full Timeline',
        rows: data.detailedLists.interviews || []
      }
    };

    const selected = mapping[type];
    if (!selected || selected.rows.length === 0) {
      toast.error('No records found.');
      return;
    }

    setDetailModal({ open: true, type, title: selected.title, rows: selected.rows });
  };

  const downloadDetailCSV = () => {
    if (!detailModal.rows?.length) return;

    const toCsvCell = (value) => `"${String(value ?? '').replace(/"/g, '""')}"`;
    let headers = [];
    let rows = [];

    if (detailModal.type === 'students') {
      headers = ['Name', 'Registration', 'Department', 'CGPA', 'Interview Count', 'Hired', 'Shortlisted'];
      rows = detailModal.rows.map((s) => [
        s.name,
        s.registrationNo,
        s.department,
        s.cgpa,
        s.interviewCount,
        s.hired ? 'Yes' : 'No',
        s.shortlisted ? 'Yes' : 'No'
      ]);
    }

    if (detailModal.type === 'companies') {
      headers = ['Company', 'Industry', 'Present', 'Job Openings', 'Total Interviews', 'Hired', 'Shortlisted', 'Rejected', 'Pending'];
      rows = detailModal.rows.map((c) => [
        c.companyName,
        c.industry,
        c.isPresent ? 'Yes' : 'No',
        c.totalJobOpenings,
        c.totalInterviews,
        c.hiredCount,
        c.shortlistedCount,
        c.rejectedCount,
        c.pendingCount
      ]);
    }

    if (detailModal.type === 'jobs') {
      headers = ['Job Title', 'Company', 'Type', 'Location', 'Salary', 'Active'];
      rows = detailModal.rows.map((j) => [
        j.jobTitle,
        j.companyName,
        j.jobType,
        j.location,
        j.salaryRange,
        j.isActive ? 'Yes' : 'No'
      ]);
    }

    if (detailModal.type === 'interviews') {
      headers = ['Company', 'Student', 'Registration', 'Scheduled', 'Actual Start', 'End', 'Result', 'Room No', 'Duration (min)'];
      rows = detailModal.rows.map((i) => [
        i.companyName,
        i.studentName,
        i.studentRegistrationNo,
        i.scheduledTime ? new Date(i.scheduledTime).toLocaleString() : '',
        i.startedAt ? new Date(i.startedAt).toLocaleString() : '',
        i.endedAt ? new Date(i.endedAt).toLocaleString() : '',
        i.result,
        i.roomNo,
        i.durationMinutes ?? ''
      ]);
    }

    const csvContent = [
      headers.map(toCsvCell).join(','),
      ...rows.map((row) => row.map(toCsvCell).join(','))
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `${detailModal.type}_jobfair_${selectedFairId}.csv`);
    document.body.appendChild(link);
    link.click();
    link.remove();
    window.URL.revokeObjectURL(url);
  };

  const downloadDetailPDF = () => {
    if (!detailModal.rows?.length) return;

    const doc = new jsPDF({ orientation: 'landscape', unit: 'pt', format: 'a4' });
    const pageWidth = doc.internal.pageSize.getWidth();

    doc.setFontSize(16);
    doc.setTextColor(79, 70, 229);
    doc.text(detailModal.title, 40, 40);
    doc.setFontSize(10);
    doc.setTextColor(110);
    doc.text(`Generated: ${new Date().toLocaleString()}`, 40, 58);

    let head = [];
    let body = [];

    if (detailModal.type === 'students') {
      head = [['Name', 'Registration', 'Department', 'CGPA', 'Interviews', 'Hired', 'Shortlisted']];
      body = detailModal.rows.map((s) => [
        s.name || '-',
        s.registrationNo || '-',
        s.department || '-',
        Number(s.cgpa ?? 0).toFixed(2),
        s.interviewCount ?? 0,
        s.hired ? 'Yes' : 'No',
        s.shortlisted ? 'Yes' : 'No'
      ]);
    }

    if (detailModal.type === 'companies') {
      head = [['Company', 'Industry', 'Present', 'Jobs', 'Interviews', 'Hired', 'Shortlisted', 'Rejected', 'Pending']];
      body = detailModal.rows.map((c) => [
        c.companyName || '-',
        c.industry || '-',
        c.isPresent ? 'Yes' : 'No',
        c.totalJobOpenings ?? 0,
        c.totalInterviews ?? 0,
        c.hiredCount ?? 0,
        c.shortlistedCount ?? 0,
        c.rejectedCount ?? 0,
        c.pendingCount ?? 0
      ]);
    }

    if (detailModal.type === 'jobs') {
      head = [['Job Title', 'Company', 'Type', 'Location', 'Salary', 'Active']];
      body = detailModal.rows.map((j) => [
        j.jobTitle || '-',
        j.companyName || '-',
        j.jobType || '-',
        j.location || '-',
        j.salaryRange || '-',
        j.isActive ? 'Yes' : 'No'
      ]);
    }

    if (detailModal.type === 'interviews') {
      head = [['Company', 'Student', 'Registration', 'Scheduled', 'Start', 'End', 'Result', 'Room', 'Duration (min)']];
      body = detailModal.rows.map((i) => [
        i.companyName || '-',
        i.studentName || '-',
        i.studentRegistrationNo || '-',
        i.scheduledTime ? new Date(i.scheduledTime).toLocaleString() : '-',
        i.startedAt ? new Date(i.startedAt).toLocaleString() : '-',
        i.endedAt ? new Date(i.endedAt).toLocaleString() : '-',
        i.result || '-',
        i.roomNo || '-',
        i.durationMinutes ?? '-'
      ]);
    }

    autoTable(doc, {
      startY: 76,
      head,
      body,
      styles: { fontSize: 8, cellPadding: 4 },
      headStyles: { fillColor: [79, 70, 229] },
      margin: { left: 40, right: 40 }
    });

    const pageCount = doc.internal.getNumberOfPages();
    for (let i = 1; i <= pageCount; i++) {
      doc.setPage(i);
      doc.setFontSize(9);
      doc.setTextColor(140);
      doc.text(`Page ${i} of ${pageCount}`, pageWidth - 80, doc.internal.pageSize.getHeight() - 16);
    }

    doc.save(`${detailModal.type}_jobfair_${selectedFairId}.pdf`);
  };

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
      
      // Initialize PDF in landscape for large analytics tables
      const doc = new jsPDF({ orientation: 'landscape', unit: 'pt', format: 'a4' });
      const pageWidth = doc.internal.pageSize.getWidth();
      const pageHeight = doc.internal.pageSize.getHeight();

      const addSectionTitle = (title, y) => {
        doc.setFontSize(13);
        doc.setTextColor(31, 41, 55);
        doc.text(title, 40, y);
      };

      const ensureSpace = (currentY, needed = 130) => {
        if (currentY + needed > pageHeight - 40) {
          doc.addPage();
          return 40;
        }
        return currentY;
      };

      let y = 40;

      // --- Header ---
      doc.setFontSize(22);
      doc.setTextColor(79, 70, 229); // Indigo Color
      doc.text("Job Fair Comprehensive Impact Report", 40, y);
      
      doc.setFontSize(12);
      doc.setTextColor(100);
      doc.text(`Event: ${currentFair?.semester || 'N/A'}`, 40, y + 18);
      doc.text(`Date: ${currentFair ? new Date(currentFair.date).toLocaleDateString() : 'N/A'}`, 40, y + 34);
      doc.text(`Generated: ${new Date().toLocaleString()}`, 40, y + 50);

      // --- Executive Summary Section ---
      y = 112;
      addSectionTitle('Executive Summary', y);
      
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
        startY: y + 10,
        head: [['Metric', 'Value']],
        body: summaryData,
        theme: 'striped',
        headStyles: { fillColor: [79, 70, 229] }, // Indigo header
        styles: { fontSize: 10 },
        columnStyles: { 0: { fontStyle: 'bold' } },
        margin: { left: 40, right: 40 }
      });

      y = doc.lastAutoTable.finalY + 20;
      y = ensureSpace(y, 180);
      addSectionTitle('Top Recruiters', y);

      const recruiterData = (data?.companyParticipation || []).slice(0, 10).map(c => [
        c.companyName, 
        c.totalInterviews, 
        c.hiredCount
      ]);

      autoTable(doc, {
        startY: y + 8,
        head: [['Company', 'Interviews', 'Hires']],
        body: recruiterData,
        theme: 'grid',
        headStyles: { fillColor: [16, 185, 129] }, // Emerald header
        margin: { left: 40, right: 40 },
      });

      y = doc.lastAutoTable.finalY + 20;
      y = ensureSpace(y, 180);
      addSectionTitle('Department Hiring Performance', y);

      const deptData = (data?.studentsByDepartment || []).map(d => [
        d.department,
        d.count,
        d.hired
      ]);

      autoTable(doc, {
        startY: y + 8,
        head: [['Department', 'Total Students', 'Hired']],
        body: deptData,
        theme: 'grid',
        headStyles: { fillColor: [245, 158, 11] }, // Amber header
        margin: { left: 40, right: 40 },
      });

      y = doc.lastAutoTable.finalY + 20;
      y = ensureSpace(y, 220);
      addSectionTitle('Top Performing Students', y);

      const studentData = (data?.topStudents || []).slice(0, 10).map(s => [
        s.name,
        s.department,
        s.cgpa.toFixed(2),
        s.hired ? 'Yes' : 'No'
      ]);

      autoTable(doc, {
        startY: y + 8,
        head: [['Name', 'Department', 'CGPA', 'Hired']],
        body: studentData,
        theme: 'grid',
        headStyles: { fillColor: [99, 102, 241] }, // Indigo header
        margin: { left: 40, right: 40 },
      });

      const detailedLists = data?.detailedLists || {};

      const appendDetailedTable = (title, head, body, color) => {
        if (!body || body.length === 0) return;
        y = doc.lastAutoTable.finalY + 20;
        y = ensureSpace(y, 200);
        addSectionTitle(title, y);

        autoTable(doc, {
          startY: y + 8,
          head: [head],
          body,
          theme: 'striped',
          styles: { fontSize: 8, cellPadding: 4 },
          headStyles: { fillColor: color },
          margin: { left: 40, right: 40 }
        });
      };

      appendDetailedTable(
        'Detailed Student Participation',
        ['Name', 'Registration', 'Department', 'CGPA', 'Interviews', 'Hired', 'Shortlisted'],
        (detailedLists.students || []).map((s) => [
          s.name || '-',
          s.registrationNo || '-',
          s.department || '-',
          Number(s.cgpa ?? 0).toFixed(2),
          s.interviewCount ?? 0,
          s.hired ? 'Yes' : 'No',
          s.shortlisted ? 'Yes' : 'No'
        ]),
        [59, 130, 246]
      );

      appendDetailedTable(
        'Detailed Company Participation',
        ['Company', 'Industry', 'Present', 'Jobs', 'Interviews', 'Hired', 'Shortlisted', 'Rejected', 'Pending'],
        (detailedLists.companies || []).map((c) => [
          c.companyName || '-',
          c.industry || '-',
          c.isPresent ? 'Yes' : 'No',
          c.totalJobOpenings ?? 0,
          c.totalInterviews ?? 0,
          c.hiredCount ?? 0,
          c.shortlistedCount ?? 0,
          c.rejectedCount ?? 0,
          c.pendingCount ?? 0
        ]),
        [16, 185, 129]
      );

      appendDetailedTable(
        'Detailed Job Openings',
        ['Job Title', 'Company', 'Type', 'Location', 'Salary', 'Active'],
        (detailedLists.jobOpenings || []).map((j) => [
          j.jobTitle || '-',
          j.companyName || '-',
          j.jobType || '-',
          j.location || '-',
          j.salaryRange || '-',
          j.isActive ? 'Yes' : 'No'
        ]),
        [245, 158, 11]
      );

      appendDetailedTable(
        'Detailed Interview Outcomes',
        ['Company', 'Student', 'Registration', 'Scheduled', 'Start', 'End', 'Result', 'Room', 'Duration'],
        (detailedLists.interviews || []).map((i) => [
          i.companyName || '-',
          i.studentName || '-',
          i.studentRegistrationNo || '-',
          i.scheduledTime ? new Date(i.scheduledTime).toLocaleString() : '-',
          i.startedAt ? new Date(i.startedAt).toLocaleString() : '-',
          i.endedAt ? new Date(i.endedAt).toLocaleString() : '-',
          i.result || '-',
          i.roomNo || '-',
          i.durationMinutes ?? '-'
        ]),
        [99, 102, 241]
      );

      // --- Footer ---
      const pageCount = doc.internal.getNumberOfPages();
      for (let i = 1; i <= pageCount; i++) {
        doc.setPage(i);
        doc.setFontSize(10);
        doc.setTextColor(150);
        doc.text(`Page ${i} of ${pageCount} - Generated by JobFair Portal`, pageWidth / 2, pageHeight - 16, { align: 'center' });
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
              onClick={() => openDetailModal('students')}
            />
            <StatCard 
              title="Participating Companies" 
              value={data.overallStats.totalCompanies} 
              icon={Building2} 
              color="bg-purple-500" 
              onClick={() => openDetailModal('companies')}
            />
            <StatCard 
              title="Total Job Openings" 
              value={data.overallStats.totalJobs} 
              icon={Briefcase} 
              color="bg-orange-500" 
              onClick={() => openDetailModal('jobs')}
            />
            <StatCard 
              title="Interviews Conducted" 
              value={data.overallStats.totalInterviews} 
              subtext={`${data.interviewStats.hiringRate}% Hiring Rate`}
              icon={CheckCircle} 
              color="bg-emerald-500" 
              onClick={() => openDetailModal('interviews')}
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

      {detailModal.open && (
        <div className="fixed inset-0 z-50 bg-black/40 flex items-center justify-center p-4">
          <div className="bg-white w-full max-w-6xl max-h-[90vh] rounded-xl shadow-2xl overflow-hidden">
            <div className="px-5 py-4 border-b flex items-center justify-between">
              <div>
                <h3 className="font-bold text-gray-900">{detailModal.title}</h3>
                <p className="text-xs text-gray-500 mt-1">Click records to navigate and use CSV/PDF to download the list.</p>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={downloadDetailCSV}
                  className="px-3 py-2 text-sm bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 flex items-center gap-2"
                >
                  <Download size={14} /> Download CSV
                </button>
                <button
                  onClick={downloadDetailPDF}
                  className="px-3 py-2 text-sm bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 flex items-center gap-2"
                >
                  <Download size={14} /> Download PDF
                </button>
                <button
                  onClick={() => setDetailModal({ open: false, type: null, title: '', rows: [] })}
                  className="px-3 py-2 text-sm bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200"
                >
                  Close
                </button>
              </div>
            </div>

            <div className="overflow-auto max-h-[75vh]">
              {detailModal.type === 'students' && (
                <table className="w-full text-sm">
                  <thead className="bg-gray-50 text-gray-600">
                    <tr>
                      <th className="px-4 py-3 text-left">Name</th>
                      <th className="px-4 py-3 text-left">Registration</th>
                      <th className="px-4 py-3 text-left">Department</th>
                      <th className="px-4 py-3 text-right">CGPA</th>
                      <th className="px-4 py-3 text-right">Interviews</th>
                      <th className="px-4 py-3 text-center">Profile</th>
                    </tr>
                  </thead>
                  <tbody>
                    {detailModal.rows.map((s) => (
                      <tr key={s.studentId} className="border-t hover:bg-gray-50">
                        <td className="px-4 py-3">{s.name}</td>
                        <td className="px-4 py-3">{s.registrationNo}</td>
                        <td className="px-4 py-3">{s.department}</td>
                        <td className="px-4 py-3 text-right">{Number(s.cgpa ?? 0).toFixed(2)}</td>
                        <td className="px-4 py-3 text-right">{s.interviewCount}</td>
                        <td className="px-4 py-3 text-center">
                          <button
                            onClick={() => navigate(`/admin/students/${s.studentId}`)}
                            className="px-2 py-1 text-xs bg-blue-50 text-blue-700 rounded hover:bg-blue-100"
                          >
                            View Profile
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}

              {detailModal.type === 'companies' && (
                <table className="w-full text-sm">
                  <thead className="bg-gray-50 text-gray-600">
                    <tr>
                      <th className="px-4 py-3 text-left">Company</th>
                      <th className="px-4 py-3 text-left">Industry</th>
                      <th className="px-4 py-3 text-right">Jobs</th>
                      <th className="px-4 py-3 text-right">Interviews</th>
                      <th className="px-4 py-3 text-right">Hired</th>
                      <th className="px-4 py-3 text-center">Profile</th>
                    </tr>
                  </thead>
                  <tbody>
                    {detailModal.rows.map((c) => (
                      <tr key={c.companyId} className="border-t hover:bg-gray-50">
                        <td className="px-4 py-3">{c.companyName}</td>
                        <td className="px-4 py-3">{c.industry || '-'}</td>
                        <td className="px-4 py-3 text-right">{c.totalJobOpenings}</td>
                        <td className="px-4 py-3 text-right">{c.totalInterviews}</td>
                        <td className="px-4 py-3 text-right text-emerald-700 font-semibold">{c.hiredCount}</td>
                        <td className="px-4 py-3 text-center">
                          <button
                            onClick={() => navigate(`/admin/companies/${c.companyId}`)}
                            className="px-2 py-1 text-xs bg-blue-50 text-blue-700 rounded hover:bg-blue-100"
                          >
                            View Profile
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}

              {detailModal.type === 'jobs' && (
                <table className="w-full text-sm">
                  <thead className="bg-gray-50 text-gray-600">
                    <tr>
                      <th className="px-4 py-3 text-left">Job Title</th>
                      <th className="px-4 py-3 text-left">Company</th>
                      <th className="px-4 py-3 text-left">Type</th>
                      <th className="px-4 py-3 text-left">Location</th>
                      <th className="px-4 py-3 text-left">Salary</th>
                    </tr>
                  </thead>
                  <tbody>
                    {detailModal.rows.map((j) => (
                      <tr key={j.jobId} className="border-t hover:bg-gray-50">
                        <td className="px-4 py-3">{j.jobTitle}</td>
                        <td className="px-4 py-3">{j.companyName}</td>
                        <td className="px-4 py-3">{j.jobType}</td>
                        <td className="px-4 py-3">{j.location || '-'}</td>
                        <td className="px-4 py-3">{j.salaryRange || '-'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}

              {detailModal.type === 'interviews' && (
                <table className="w-full text-sm">
                  <thead className="bg-gray-50 text-gray-600">
                    <tr>
                      <th className="px-4 py-3 text-left">Company</th>
                      <th className="px-4 py-3 text-left">Student</th>
                      <th className="px-4 py-3 text-left">Registration</th>
                      <th className="px-4 py-3 text-left">Scheduled</th>
                      <th className="px-4 py-3 text-left">Actual Start</th>
                      <th className="px-4 py-3 text-left">End</th>
                      <th className="px-4 py-3 text-left">Result</th>
                      <th className="px-4 py-3 text-left">Room</th>
                    </tr>
                  </thead>
                  <tbody>
                    {detailModal.rows.map((i) => (
                      <tr key={i.interviewId} className="border-t hover:bg-gray-50">
                        <td className="px-4 py-3">{i.companyName || '-'}</td>
                        <td className="px-4 py-3">{i.studentName || '-'}</td>
                        <td className="px-4 py-3">{i.studentRegistrationNo || '-'}</td>
                        <td className="px-4 py-3">{i.scheduledTime ? new Date(i.scheduledTime).toLocaleString() : '-'}</td>
                        <td className="px-4 py-3">{i.startedAt ? new Date(i.startedAt).toLocaleString() : '-'}</td>
                        <td className="px-4 py-3">{i.endedAt ? new Date(i.endedAt).toLocaleString() : '-'}</td>
                        <td className="px-4 py-3">{i.result || '-'}</td>
                        <td className="px-4 py-3">{i.roomNo || '-'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default JobFairAnalytics;