/* eslint-disable no-unused-vars */
import React, { useEffect, useRef, useState } from 'react';
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
import LogoWithoutBg from '../../assets/LogoWithoutBg.png';

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
  const [selectedDetail, setSelectedDetail] = useState({
    type: null,
    title: '',
    rows: []
  });
  const [detailPage, setDetailPage] = useState(1);
  const detailPageSize = 10;
  const detailSectionRef = useRef(null);
  const restoredDetailRef = useRef(false);

  const getCurrentFair = () => fairs.find((f) => String(f.jobFairId) === String(selectedFairId));

  const getAnalyticsReturnState = () => ({
    jobFairId: selectedFairId,
    detailType: selectedDetail.type,
    detailPage
  });

  const navigateToStudent = (studentId) => {
    navigate(`/admin/students/${studentId}`, {
      state: { fromAnalytics: getAnalyticsReturnState() }
    });
  };

  const navigateToCompany = (companyId) => {
    navigate(`/admin/companies/${companyId}`, {
      state: { fromAnalytics: getAnalyticsReturnState() }
    });
  };

  const getPdfBrandingAssets = async () => {
    const fair = getCurrentFair();
    const fairLabel = fair?.semester || data?.semester || 'Job Fair';

    const logoDataUrl = await new Promise((resolve) => {
      const img = new Image();
      img.crossOrigin = 'anonymous';
      img.onload = () => {
        try {
          const canvas = document.createElement('canvas');
          canvas.width = img.naturalWidth;
          canvas.height = img.naturalHeight;
          const ctx = canvas.getContext('2d');
          if (!ctx) return resolve(null);
          ctx.drawImage(img, 0, 0);
          resolve(canvas.toDataURL('image/png'));
        } catch {
          resolve(null);
        }
      };
      img.onerror = () => resolve(null);
      img.src = LogoWithoutBg;
    });

    return { fairLabel, logoDataUrl };
  };

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
      rooms: {
        title: 'Rooms In This Job Fair',
        rows: data.detailedLists.rooms || []
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

    setSelectedDetail({ type, title: selected.title, rows: selected.rows });
    setDetailPage(1);
    setTimeout(() => {
      detailSectionRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }, 0);
  };

  const downloadDetailCSV = () => {
    if (!selectedDetail.rows?.length) return;

    const toCsvCell = (value) => `"${String(value ?? '').replace(/"/g, '""')}"`;
    let headers = [];
    let rows = [];

    if (selectedDetail.type === 'students') {
      headers = ['Name', 'Registration', 'Department', 'CGPA', 'Interview Count', 'Hired', 'Shortlisted'];
      rows = selectedDetail.rows.map((s) => [
        s.name,
        s.registrationNo,
        s.department,
        s.cgpa,
        s.interviewCount,
        s.hired ? 'Yes' : 'No',
        s.shortlisted ? 'Yes' : 'No'
      ]);
    }

    if (selectedDetail.type === 'companies') {
      headers = ['Company', 'Industry', 'Present', 'Job Openings', 'Total Interviews', 'Hired', 'Shortlisted', 'Rejected', 'Pending'];
      rows = selectedDetail.rows.map((c) => [
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

    if (selectedDetail.type === 'jobs') {
      headers = ['Job Title', 'Company', 'Type', 'Positions', 'Active'];
      rows = selectedDetail.rows.map((j) => [
        j.jobTitle,
        j.companyName,
        j.jobType,
        j.numberOfJobs,
        j.isActive ? 'Yes' : 'No'
      ]);
    }

    if (selectedDetail.type === 'rooms') {
      headers = ['Room', 'Capacity', 'Status', 'Assigned Company', 'Interviews'];
      rows = selectedDetail.rows.map((r) => [
        r.roomName,
        r.capacity,
        r.status,
        r.companyName || '-',
        r.interviewCount ?? 0
      ]);
    }

    if (selectedDetail.type === 'interviews') {
      headers = ['Company', 'Student', 'Registration', 'Scheduled', 'Actual Start', 'End', 'Result', 'Room No', 'Duration (min)'];
      rows = selectedDetail.rows.map((i) => [
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
    link.setAttribute('download', `${selectedDetail.type}_jobfair_${selectedFairId}.csv`);
    document.body.appendChild(link);
    link.click();
    link.remove();
    window.URL.revokeObjectURL(url);
  };

  const downloadDetailPDF = () => {
    if (!selectedDetail.rows?.length) return;

    const buildPdf = async () => {
      const { fairLabel, logoDataUrl } = await getPdfBrandingAssets();

      const doc = new jsPDF({ orientation: 'landscape', unit: 'pt', format: 'a4' });
      const pageWidth = doc.internal.pageSize.getWidth();

      if (logoDataUrl) {
        doc.addImage(logoDataUrl, 'PNG', 14, 10, 20, 20);
      }

      doc.setFontSize(14);
      doc.setTextColor(79, 70, 229);
      doc.text(`${fairLabel} - ${selectedDetail.title}`, 40, 24);
      doc.setFontSize(10);
      doc.setTextColor(110);
      doc.text(`Generated: ${new Date().toLocaleString()}`, 40, 42);

      let head = [];
      let body = [];

    if (selectedDetail.type === 'students') {
      head = [['Name', 'Registration', 'Department', 'CGPA', 'Interviews', 'Hired', 'Shortlisted']];
      body = selectedDetail.rows.map((s) => [
        s.name || '-',
        s.registrationNo || '-',
        s.department || '-',
        Number(s.cgpa ?? 0).toFixed(2),
        s.interviewCount ?? 0,
        s.hired ? 'Yes' : 'No',
        s.shortlisted ? 'Yes' : 'No'
      ]);
    }

    if (selectedDetail.type === 'companies') {
      head = [['Company', 'Industry', 'Present', 'Jobs', 'Interviews', 'Hired', 'Shortlisted', 'Rejected', 'Pending']];
      body = selectedDetail.rows.map((c) => [
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

    if (selectedDetail.type === 'jobs') {
      head = [['Job Title', 'Company', 'Type', 'Positions', 'Active']];
      body = selectedDetail.rows.map((j) => [
        j.jobTitle || '-',
        j.companyName || '-',
        j.jobType || '-',
        j.numberOfJobs ?? 0,
        j.isActive ? 'Yes' : 'No'
      ]);
    }

    if (selectedDetail.type === 'rooms') {
      head = [['Room', 'Capacity', 'Status', 'Assigned Company', 'Interviews']];
      body = selectedDetail.rows.map((r) => [
        r.roomName || '-',
        r.capacity ?? 0,
        r.status || '-',
        r.companyName || '-',
        r.interviewCount ?? 0
      ]);
    }

    if (selectedDetail.type === 'interviews') {
      head = [['Company', 'Student', 'Registration', 'Scheduled', 'Start', 'End', 'Result', 'Room', 'Duration (min)']];
      body = selectedDetail.rows.map((i) => [
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
        startY: 58,
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

      doc.save(`${selectedDetail.type}_jobfair_${selectedFairId}.pdf`);
    };

    buildPdf();
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
    setSelectedDetail({ type: null, title: '', rows: [] });
    setDetailPage(1);
    restoredDetailRef.current = false;

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

  useEffect(() => {
    if (!data?.detailedLists || restoredDetailRef.current) return;

    const restoreType = location?.state?.detailType;
    if (!restoreType) {
      restoredDetailRef.current = true;
      return;
    }

    const mapping = {
      students: { title: 'Students Participating In This Job Fair', rows: data.detailedLists.students || [] },
      companies: { title: 'Participating Companies & Stats', rows: data.detailedLists.companies || [] },
      jobs: { title: 'Job Openings In This Job Fair', rows: data.detailedLists.jobOpenings || [] },
      rooms: { title: 'Rooms In This Job Fair', rows: data.detailedLists.rooms || [] },
      interviews: { title: 'Interviews Conducted With Full Timeline', rows: data.detailedLists.interviews || [] }
    };

    const restored = mapping[restoreType];
    if (restored && restored.rows.length > 0) {
      setSelectedDetail({ type: restoreType, title: restored.title, rows: restored.rows });
      const requestedPage = Number(location?.state?.detailPage || 1);
      const totalPages = Math.max(1, Math.ceil(restored.rows.length / detailPageSize));
      setDetailPage(Math.min(totalPages, Math.max(1, requestedPage)));
      setTimeout(() => {
        detailSectionRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }, 0);
    }

    restoredDetailRef.current = true;
  }, [data, location?.state, detailPageSize]);

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
      const currentFair = getCurrentFair();
      const { fairLabel, logoDataUrl } = await getPdfBrandingAssets();
      
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
      if (logoDataUrl) {
        doc.addImage(logoDataUrl, 'PNG', 14, 12, 24, 24);
      }

      doc.setFontSize(22);
      doc.setTextColor(79, 70, 229); // Indigo Color
      doc.text(`${fairLabel} - Comprehensive Impact Report`, 46, y);
      
      doc.setFontSize(12);
      doc.setTextColor(100);
      doc.text(`Event: ${currentFair?.semester || data?.semester || 'N/A'}`, 40, y + 18);
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
        ['Interview Requests', data.overallStats.totalInterviewRequests],
        ['Accepted Requests', data.overallStats.totalAcceptedRequests],
        ['Request Acceptance Ratio', `${data.overallStats.requestAcceptanceRatio}%`],
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
        ['Job Title', 'Company', 'Type', 'Positions', 'Active'],
        (detailedLists.jobOpenings || []).map((j) => [
          j.jobTitle || '-',
          j.companyName || '-',
          j.jobType || '-',
          j.numberOfJobs ?? 0,
          j.isActive ? 'Yes' : 'No'
        ]),
        [245, 158, 11]
      );

      appendDetailedTable(
        'Detailed Room Allocation',
        ['Room', 'Capacity', 'Status', 'Assigned Company', 'Interviews'],
        (detailedLists.rooms || []).map((r) => [
          r.roomName || '-',
          r.capacity ?? 0,
          r.status || '-',
          r.companyName || '-',
          r.interviewCount ?? 0
        ]),
        [14, 116, 144]
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
  const detailRows = selectedDetail.rows || [];
  const totalDetailPages = Math.max(1, Math.ceil(detailRows.length / detailPageSize));
  const paginatedDetailRows = detailRows.slice(
    (detailPage - 1) * detailPageSize,
    detailPage * detailPageSize
  );
  const requestAcceptanceChartData = [
    { name: 'Requests', count: data?.overallStats?.totalInterviewRequests || 0 },
    { name: 'Accepted', count: data?.overallStats?.totalAcceptedRequests || 0 }
  ];
  const interviewStageChartData = [
    { name: 'Total', count: data?.overallStats?.totalInterviews || 0, color: '#0EA5E9' },
    { name: 'Scheduled', count: data?.interviewStats?.scheduled || 0, color: '#8B5CF6' },
    { name: 'Queued', count: (data?.interviewStats?.queued ?? data?.interviewStats?.pending) || 0, color: '#F59E0B' },
    { name: 'Hired', count: data?.interviewStats?.hired || 0, color: '#10B981' },
    { name: 'Shortlisted', count: data?.interviewStats?.shortlisted || 0, color: '#6366F1' },
    { name: 'Rejected', count: data?.interviewStats?.rejected || 0, color: '#EF4444' }
  ];

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
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6">
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
            <StatCard
              title="Rooms (Allotted)"
              value={`${data.roomUtilization.allottedRooms}/${data.roomUtilization.totalRooms}`}
              subtext={`${data.roomUtilization.allocationRate}% Allocated`}
              icon={Building2}
              color="bg-cyan-600"
              onClick={() => openDetailModal('rooms')}
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

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-bold text-gray-800">Interview Request to Acceptance Ratio</h3>
                <span className="text-xs font-medium px-2 py-1 bg-indigo-100 text-indigo-700 rounded-full">
                  {data.overallStats.requestAcceptanceRatio}% Accepted
                </span>
              </div>
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={requestAcceptanceChartData}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} />
                    <XAxis dataKey="name" />
                    <YAxis allowDecimals={false} />
                    <Tooltip cursor={{ fill: '#f3f4f6' }} />
                    <Bar dataKey="count" fill="#4F46E5" radius={[6, 6, 0, 0]} barSize={70} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>

            <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-bold text-gray-800">Interview Stage Snapshot</h3>
                <span className="text-xs font-medium px-2 py-1 bg-slate-100 text-slate-700 rounded-full">Selected Job Fair</span>
              </div>
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={interviewStageChartData}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} />
                    <XAxis dataKey="name" />
                    <YAxis allowDecimals={false} />
                    <Tooltip cursor={{ fill: '#f3f4f6' }} />
                    <Bar dataKey="count" radius={[6, 6, 0, 0]} barSize={52}>
                      {interviewStageChartData.map((entry, index) => (
                        <Cell key={`interview-stage-cell-${index}`} fill={entry.color} />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          </div>

          {/* 2.5 Room Utilization Section */}
          <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
            <div className="flex items-center justify-between gap-3 flex-wrap mb-4">
              <div>
                <h3 className="font-bold text-gray-800">Room Utilization</h3>
                <p className="text-xs text-gray-500 mt-1">Allocation and usage status for this job fair.</p>
              </div>
              <button
                type="button"
                onClick={() => openDetailModal('rooms')}
                className="px-3 py-2 text-sm bg-cyan-600 text-white rounded-lg hover:bg-cyan-700"
              >
                View Rooms List
              </button>
            </div>

            <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
              <div className="rounded-lg border border-gray-100 bg-gray-50 p-3">
                <p className="text-xs text-gray-500">Total Rooms</p>
                <p className="text-lg font-bold text-gray-900">{data.roomUtilization.totalRooms}</p>
              </div>
              <div className="rounded-lg border border-gray-100 bg-emerald-50 p-3">
                <p className="text-xs text-emerald-700">Allotted</p>
                <p className="text-lg font-bold text-emerald-800">{data.roomUtilization.allottedRooms}</p>
              </div>
              <div className="rounded-lg border border-gray-100 bg-amber-50 p-3">
                <p className="text-xs text-amber-700">Tentative</p>
                <p className="text-lg font-bold text-amber-800">{data.roomUtilization.tentativeRooms}</p>
              </div>
              <div className="rounded-lg border border-gray-100 bg-slate-100 p-3">
                <p className="text-xs text-slate-700">Vacant</p>
                <p className="text-lg font-bold text-slate-800">{data.roomUtilization.vacantRooms}</p>
              </div>
              <div className="rounded-lg border border-gray-100 bg-cyan-50 p-3">
                <p className="text-xs text-cyan-700">Allocation Rate</p>
                <p className="text-lg font-bold text-cyan-800">{data.roomUtilization.allocationRate}%</p>
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
                      <tr
                        key={company.companyId}
                        className="hover:bg-gray-50 cursor-pointer"
                        onClick={() => navigateToCompany(company.companyId)}
                      >
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
                      <tr
                        key={student.studentId}
                        className="hover:bg-gray-50 cursor-pointer"
                        onClick={() => navigateToStudent(student.studentId)}
                      >
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

      {selectedDetail.type && (
        <div ref={detailSectionRef} className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
          <div className="px-5 py-4 border-b flex items-center justify-between gap-3 flex-wrap">
            <div>
              <h3 className="font-bold text-gray-900">{selectedDetail.title}</h3>
              <p className="text-xs text-gray-500 mt-1">
                Showing page {detailPage} of {totalDetailPages} ({detailRows.length} records)
              </p>
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
                onClick={() => setSelectedDetail({ type: null, title: '', rows: [] })}
                className="px-3 py-2 text-sm bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200"
              >
                Hide List
              </button>
            </div>
          </div>

          <div className="overflow-auto">
            {selectedDetail.type === 'students' && (
              <table className="w-full text-sm">
                <thead className="bg-gray-50 text-gray-600">
                  <tr>
                    <th className="px-4 py-3 text-left">Name</th>
                    <th className="px-4 py-3 text-left">Registration</th>
                    <th className="px-4 py-3 text-left">Department</th>
                    <th className="px-4 py-3 text-right">CGPA</th>
                    <th className="px-4 py-3 text-right">Interviews</th>
                  </tr>
                </thead>
                <tbody>
                  {paginatedDetailRows.map((s) => (
                    <tr
                      key={s.studentId}
                      className="border-t hover:bg-gray-50 cursor-pointer"
                      onClick={() => navigateToStudent(s.studentId)}
                    >
                      <td className="px-4 py-3">{s.name}</td>
                      <td className="px-4 py-3">{s.registrationNo}</td>
                      <td className="px-4 py-3">{s.department}</td>
                      <td className="px-4 py-3 text-right">{Number(s.cgpa ?? 0).toFixed(2)}</td>
                      <td className="px-4 py-3 text-right">{s.interviewCount}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}

            {selectedDetail.type === 'companies' && (
              <table className="w-full text-sm">
                <thead className="bg-gray-50 text-gray-600">
                  <tr>
                    <th className="px-4 py-3 text-left">Company</th>
                    <th className="px-4 py-3 text-left">Industry</th>
                    <th className="px-4 py-3 text-right">Jobs</th>
                    <th className="px-4 py-3 text-right">Interviews</th>
                    <th className="px-4 py-3 text-right">Hired</th>
                  </tr>
                </thead>
                <tbody>
                  {paginatedDetailRows.map((c) => (
                    <tr
                      key={c.companyId}
                      className="border-t hover:bg-gray-50 cursor-pointer"
                      onClick={() => navigateToCompany(c.companyId)}
                    >
                      <td className="px-4 py-3">{c.companyName}</td>
                      <td className="px-4 py-3">{c.industry || '-'}</td>
                      <td className="px-4 py-3 text-right">{c.totalJobOpenings}</td>
                      <td className="px-4 py-3 text-right">{c.totalInterviews}</td>
                      <td className="px-4 py-3 text-right text-emerald-700 font-semibold">{c.hiredCount}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}

            {selectedDetail.type === 'jobs' && (
              <table className="w-full text-sm">
                <thead className="bg-gray-50 text-gray-600">
                  <tr>
                    <th className="px-4 py-3 text-left">Job Title</th>
                    <th className="px-4 py-3 text-left">Company</th>
                    <th className="px-4 py-3 text-left">Type</th>
                    <th className="px-4 py-3 text-right">Positions</th>
                  </tr>
                </thead>
                <tbody>
                  {paginatedDetailRows.map((j) => (
                    <tr
                      key={j.jobId}
                      className="border-t hover:bg-gray-50 cursor-pointer"
                      onClick={() => navigateToCompany(j.companyId)}
                    >
                      <td className="px-4 py-3">{j.jobTitle}</td>
                      <td className="px-4 py-3">{j.companyName}</td>
                      <td className="px-4 py-3">{j.jobType}</td>
                      <td className="px-4 py-3 text-right font-semibold">{j.numberOfJobs ?? 0}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}

            {selectedDetail.type === 'rooms' && (
              <table className="w-full text-sm">
                <thead className="bg-gray-50 text-gray-600">
                  <tr>
                    <th className="px-4 py-3 text-left">Room</th>
                    <th className="px-4 py-3 text-right">Capacity</th>
                    <th className="px-4 py-3 text-left">Status</th>
                    <th className="px-4 py-3 text-left">Assigned Company</th>
                    <th className="px-4 py-3 text-right">Interviews</th>
                  </tr>
                </thead>
                <tbody>
                  {paginatedDetailRows.map((r) => (
                    <tr key={r.roomId} className="border-t hover:bg-gray-50">
                      <td className="px-4 py-3">{r.roomName}</td>
                      <td className="px-4 py-3 text-right">{r.capacity ?? '-'}</td>
                      <td className="px-4 py-3">{r.status || '-'}</td>
                      <td className="px-4 py-3">{r.companyName || '-'}</td>
                      <td className="px-4 py-3 text-right">{r.interviewCount ?? 0}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}

            {selectedDetail.type === 'interviews' && (
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
                    <th className="px-4 py-3 text-center">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {paginatedDetailRows.map((i) => (
                    <tr key={i.interviewId} className="border-t hover:bg-gray-50">
                      <td className="px-4 py-3">
                        <button
                          type="button"
                          onClick={() => navigateToCompany(i.companyId)}
                          className="text-indigo-700 hover:text-indigo-900 hover:underline"
                        >
                          {i.companyName || '-'}
                        </button>
                      </td>
                      <td className="px-4 py-3">
                        <button
                          type="button"
                          onClick={() => navigateToStudent(i.studentId)}
                          className="text-indigo-700 hover:text-indigo-900 hover:underline"
                        >
                          {i.studentName || '-'}
                        </button>
                      </td>
                      <td className="px-4 py-3">{i.studentRegistrationNo || '-'}</td>
                      <td className="px-4 py-3">{i.scheduledTime ? new Date(i.scheduledTime).toLocaleString() : '-'}</td>
                      <td className="px-4 py-3">{i.startedAt ? new Date(i.startedAt).toLocaleString() : '-'}</td>
                      <td className="px-4 py-3">{i.endedAt ? new Date(i.endedAt).toLocaleString() : '-'}</td>
                      <td className="px-4 py-3">{i.result || '-'}</td>
                      <td className="px-4 py-3">{i.roomNo || '-'}</td>
                      <td className="px-4 py-3">
                        <div className="flex items-center justify-center gap-2">
                          <button
                            type="button"
                            onClick={() => navigateToCompany(i.companyId)}
                            className="px-2 py-1 text-xs bg-blue-50 text-blue-700 rounded hover:bg-blue-100"
                            title="View company profile"
                            aria-label="View company profile"
                          >
                            <Building2 size={14} />
                          </button>
                          <button
                            type="button"
                            onClick={() => navigateToStudent(i.studentId)}
                            className="px-2 py-1 text-xs bg-emerald-50 text-emerald-700 rounded hover:bg-emerald-100"
                            title="View student profile"
                            aria-label="View student profile"
                          >
                            <Users size={14} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          <div className="px-5 py-3 border-t bg-gray-50 flex items-center justify-between">
            <span className="text-xs text-gray-500">
              Showing {(detailPage - 1) * detailPageSize + 1}
              {' '}-{' '}
              {Math.min(detailPage * detailPageSize, detailRows.length)}
              {' '}of {detailRows.length}
            </span>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setDetailPage((p) => Math.max(1, p - 1))}
                disabled={detailPage <= 1}
                className="px-3 py-1.5 text-sm rounded bg-white border text-gray-700 disabled:opacity-50"
              >
                Prev
              </button>
              <span className="text-sm text-gray-700">{detailPage} / {totalDetailPages}</span>
              <button
                onClick={() => setDetailPage((p) => Math.min(totalDetailPages, p + 1))}
                disabled={detailPage >= totalDetailPages}
                className="px-3 py-1.5 text-sm rounded bg-white border text-gray-700 disabled:opacity-50"
              >
                Next
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default JobFairAnalytics;