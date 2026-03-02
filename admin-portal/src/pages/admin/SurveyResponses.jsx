/* eslint-disable no-unused-vars */
import React, { useEffect, useState, useMemo, useRef } from 'react';
import {
  Download, Filter, Search, Calendar, Building2, FileText,
  ChevronDown, BarChart3, Eye, RotateCcw, MessageSquare, Coffee, Layout, Award
} from 'lucide-react';
import api from '../../lib/api';
import { toast } from 'react-hot-toast';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import html2canvas from 'html2canvas';
import { PieChart, Pie, Cell, Tooltip, Legend, ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid } from 'recharts';
import { useNavigate } from 'react-router-dom';

// Survey question labels
const SURVEY_QUESTIONS = {
  CDC: {
    FypQuality: 'FYP Quality',
    ArrangementQuality: 'Arrangement Quality',
    LunchQuality: 'Lunch Quality',
    FypComments: 'FYP Comments',
    ArrangementComments: 'Arrangement Comments',
    LunchComments: 'Lunch Comments',
  },
  Department: {
    PEO1_Q1: 'PEO-1 Q1: Technical Knowledge',
    PEO1_Q2: 'PEO-1 Q2: Analysis & Investigation',
    PEO1_Q3: 'PEO-1 Q3: Design & Implementation',
    PEO2_Q1: 'PEO-2 Q1: Desire to Learn',
    PEO2_Q2: 'PEO-2 Q2: Entrepreneurship',
    PEO3_Q1: 'PEO-3 Q1: Ethics Awareness',
    PEO3_Q2: 'PEO-3 Q2: Communication Skills',
    PEO4_Q1: 'PEO-4 Q1: Societal Contribution',
    PEO4_Q2: 'PEO-4 Q2: Economic Growth',
    PEO4_Q3: 'PEO-4 Q3: Innovation Support',
    TechnologiesSuggestion: 'Technologies Suggestion',
    GeneralFeedback: 'General Feedback',
    ImprovementSuggestions: 'Improvement Suggestions',
  }
};

const LIKERT_COLORS = {
  Exceptionally: '#10B981',
  ToAGreatExtent: '#3B82F6',
  Moderately: '#F59E0B',
  Somewhat: '#EF5350',
  NotAtAll: '#6B7280'
};

const CDC_COLORS = ['#10B981', '#F59E0B', '#EF4444']; // Good, Average, Bad

const normalizeResponses = (responses) => {
  if (!responses || typeof responses !== 'object') return responses;

  const normalized = { ...responses };

  Object.entries(responses).forEach(([key, value]) => {
    const pascalKey = key.charAt(0).toUpperCase() + key.slice(1);
    if (normalized[pascalKey] === undefined) {
      normalized[pascalKey] = value;
    }

    if (/^peO\d+_Q\d+$/i.test(key)) {
      const peoKey = key.replace(/^peO/i, 'PEO');
      if (normalized[peoKey] === undefined) {
        normalized[peoKey] = value;
      }
    }
  });

  return normalized;
};

// Survey Response Details Modal
const SurveyDetailsModal = ({ survey, onClose }) => {
  if (!survey) return null;

  const renderResponse = (key, value) => {
    if (!value) return <span className="text-gray-400">N/A</span>;
    if (typeof value === 'string') return <span className="break-words">{value}</span>;
    return <span className="text-gray-700">{String(value)}</span>;
  };

  const questionLabels = SURVEY_QUESTIONS[survey.type] || {};
  const responses = survey.responses || {};

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 animate-fade-in">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[90vh] overflow-auto">
        {/* Header */}
        <div className="sticky top-0 bg-gradient-to-r from-gray-800 to-gray-900 px-6 py-4 border-b flex justify-between items-center">
          <div>
            <h3 className="text-lg font-bold text-white">{survey.companyName}</h3>
            <p className="text-xs text-gray-400 mt-1">
              {survey.type} Survey • Submitted: {new Date(survey.submittedAt).toLocaleString()}
            </p>
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-white text-2xl transition"
          >
            ×
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6">
          {Object.entries(responses).map(([key, value]) => (
            <div key={key} className="border-b pb-4">
              <h4 className="font-semibold text-gray-900 mb-2">{questionLabels[key] || key}</h4>
              <div className="bg-gray-50 p-3 rounded-lg text-sm text-gray-700">
                {renderResponse(key, value)}
              </div>
            </div>
          ))}
        </div>

        {/* Footer */}
        <div className="sticky bottom-0 bg-gray-50 border-t px-6 py-4 flex justify-end">
          <button
            onClick={onClose}
            className="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
};

// Main Component
const SurveyResponses = () => {
  const navigate = useNavigate();
  const [surveys, setSurveys] = useState([]);
  const [companies, setCompanies] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedSurvey, setSelectedSurvey] = useState(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [activeView, setActiveView] = useState('list'); // list, cdc-stats, dept-stats
  const cdcChartsRef = useRef(null);
  const deptChartsRef = useRef(null);
  const cdcExportRef = useRef(null);
  const deptExportRef = useRef(null);

  const [filters, setFilters] = useState({
    surveyType: 'all', // all, CDC, Department
    companyId: 'all',
    search: ''
  });

  const fetchData = async () => {
    setLoading(true);
    try {
      const [surveysRes, companiesRes] = await Promise.all([
        api.get('/admin/surveys'),
        api.get('/admin/companies?pageSize=1000')
      ]);

      const mappedSurveys = (surveysRes.data || []).map((survey) => ({
        ...survey,
        responses: normalizeResponses(survey.responses)
      }));

      setSurveys(mappedSurveys);

      // Extract companies from paginated response
      const companiesData = Array.isArray(companiesRes.data)
        ? companiesRes.data
        : (companiesRes.data.companies || []);
      setCompanies(companiesData);
    } catch (error) {
      console.error(error);
      toast.error("Failed to load survey data");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  // Filter and Process Surveys
  const processedSurveys = useMemo(() => {
    let result = [...surveys];

    // Filter by survey type
    if (filters.surveyType !== 'all') {
      result = result.filter(s => s.type === filters.surveyType);
    }

    // Filter by company
    if (filters.companyId !== 'all') {
      result = result.filter(s => s.companyName === companies.find(c => c.companyId === parseInt(filters.companyId))?.name);
    }

    // Search by company name
    if (filters.search) {
      const term = filters.search.toLowerCase();
      result = result.filter(s => s.companyName?.toLowerCase().includes(term));
    }

    // Sort by date (newest first)
    result.sort((a, b) => new Date(b.submittedAt) - new Date(a.submittedAt));

    return result;
  }, [surveys, companies, filters]);

  // Statistics
  const stats = useMemo(() => {
    const cdcCount = surveys.filter(s => s.type === 'CDC').length;
    const deptCount = surveys.filter(s => s.type === 'Department').length;
    return {
      total: surveys.length,
      cdc: cdcCount,
      department: deptCount
    };
  }, [surveys]);

  // Download CSV Report
  const downloadCSVReport = () => {
    if (processedSurveys.length === 0) {
      toast.error("No surveys to download");
      return;
    }

    const surveyType = filters.surveyType === 'all' ? 'All' : filters.surveyType;
    const toCsvCell = (value) => `"${String(value ?? '').replace(/"/g, '""')}"`;

    const cdcKeys = Object.keys(SURVEY_QUESTIONS.CDC);
    const deptKeys = Object.keys(SURVEY_QUESTIONS.Department);
    const orderedKeys = [...cdcKeys, ...deptKeys];
    const questionColumns = orderedKeys.map((key) => SURVEY_QUESTIONS.CDC[key] || SURVEY_QUESTIONS.Department[key]);

    const header = ['Company Name', 'Survey Type', 'Submitted Date', ...questionColumns];

    const rows = processedSurveys.map((survey) => {
      const responses = survey.responses || {};
      const valuesByKey = orderedKeys.map((key) => {
        const value = responses[key];
        return value === null || value === undefined ? '' : value;
      });

      return [
        survey.companyName,
        survey.type,
        new Date(survey.submittedAt).toLocaleString(),
        ...valuesByKey
      ];
    });

    const csvContent = [
      header.map(toCsvCell).join(','),
      ...rows.map((row) => row.map(toCsvCell).join(','))
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `Survey_Responses_${surveyType}_${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    toast.success("CSV downloaded successfully!");
  };

  // Download PDF Report
  const downloadPDFReport = async () => {
    if (processedSurveys.length === 0) {
      toast.error("No surveys to download");
      return;
    }

    const doc = new jsPDF();
    doc.setFontSize(18);
    doc.setTextColor(79, 70, 229);
    doc.text("Survey Responses Report", 14, 20);

    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Generated on: ${new Date().toLocaleString()}`, 14, 28);

    const surveyType = filters.surveyType === 'all' ? 'All' : filters.surveyType;
    doc.text(`Survey Type: ${surveyType} | Total Responses: ${processedSurveys.length}`, 14, 35);

    // Create table
    const tableData = processedSurveys.map(survey => [
      survey.companyName,
      survey.type,
      new Date(survey.submittedAt).toLocaleDateString(),
      Object.keys(survey.responses || {}).length
    ]);

    autoTable(doc, {
      startY: 42,
      head: [['Company', 'Type', 'Submitted', 'Responses']],
      body: tableData,
      theme: 'striped',
      headStyles: { fillColor: [79, 70, 229] },
      styles: { fontSize: 9 },
      columnStyles: {
        0: { cellWidth: 50 },
        1: { cellWidth: 30 },
        2: { cellWidth: 40 },
        3: { cellWidth: 30 }
      }
    });

    const addChartSection = async (title, elementRef) => {
      if (!elementRef?.current) return;

      const canvas = await html2canvas(elementRef.current, {
        backgroundColor: '#ffffff',
        scale: 2,
        useCORS: true,
      });

      const imgData = canvas.toDataURL('image/png');
      const imgWidth = 180;
      const pageHeight = doc.internal.pageSize.getHeight();
      let y = doc.lastAutoTable?.finalY ? doc.lastAutoTable.finalY + 12 : 55;
      const imgHeight = (canvas.height * imgWidth) / canvas.width;

      if (y + imgHeight > pageHeight - 15) {
        doc.addPage();
        y = 20;
      }

      doc.setFontSize(12);
      doc.setTextColor(0);
      doc.text(title, 14, y - 4);
      doc.addImage(imgData, 'PNG', 14, y, imgWidth, imgHeight);
    };

    await addChartSection('CDC Feedback Graphs', cdcExportRef);
    await addChartSection('Department Analysis Graphs', deptExportRef);

    doc.save(`Survey_Responses_${surveyType}_${new Date().toISOString().split('T')[0]}.pdf`);
    toast.success("PDF downloaded successfully!");
  };

  const downloadAllCompanyReports = async () => {
    if (surveys.length === 0) {
      toast.error('No survey data available for bulk export');
      return;
    }

    const loadingToastId = toast.loading('Preparing bulk company reports...');

    try {
      const questionRowsByType = (surveyItems, surveyType) => {
        const labels = SURVEY_QUESTIONS[surveyType] || {};
        return surveyItems.flatMap((surveyItem) =>
          Object.entries(labels).map(([key, label]) => ([
            new Date(surveyItem.submittedAt).toLocaleString(),
            label,
            String(surveyItem.responses?.[key] ?? 'N/A')
          ]))
        );
      };

      const companyLookup = new Map(companies.map((company) => [company.name?.trim().toLowerCase(), company.companyId]));

      const uniqueCompanies = Array.from(
        surveys.reduce((map, surveyItem) => {
          const normalizedName = (surveyItem.companyName || '').trim();
          if (!normalizedName) return map;

          const fallbackCompanyId = companyLookup.get(normalizedName.toLowerCase());
          const resolvedCompanyId = surveyItem.companyId || fallbackCompanyId;
          const key = resolvedCompanyId ? `id-${resolvedCompanyId}` : `name-${normalizedName.toLowerCase()}`;

          if (!map.has(key)) {
            map.set(key, { companyId: resolvedCompanyId, companyName: normalizedName });
          }

          return map;
        }, new Map()).values()
      );

      if (uniqueCompanies.length === 0) {
        toast.dismiss(loadingToastId);
        toast.error('No companies found for bulk export');
        return;
      }

      const doc = new jsPDF();

      for (let index = 0; index < uniqueCompanies.length; index++) {
        const companyItem = uniqueCompanies[index];

        if (index > 0) {
          doc.addPage();
        }

        let details = null;
        if (companyItem.companyId) {
          try {
            const detailRes = await api.get(`/admin/companies/${companyItem.companyId}/details`);
            details = detailRes.data;
          } catch {
            details = null;
          }
        }

        const companySurveyItems = surveys.filter((surveyItem) => {
          if (companyItem.companyId && surveyItem.companyId) {
            return String(surveyItem.companyId) === String(companyItem.companyId);
          }
          return (surveyItem.companyName || '').trim().toLowerCase() === companyItem.companyName.toLowerCase();
        });

        const cdcItems = companySurveyItems.filter((s) => s.type === 'CDC');
        const deptItems = companySurveyItems.filter((s) => s.type === 'Department');

        doc.setFontSize(16);
        doc.setTextColor(37, 99, 235);
        doc.text(details?.name || companyItem.companyName || 'Company', 14, 16);

        doc.setFontSize(9);
        doc.setTextColor(90);
        doc.text(`Generated: ${new Date().toLocaleString()}`, 14, 22);

        autoTable(doc, {
          startY: 26,
          head: [['Field', 'Value']],
          body: [
            ['Company Name', details?.name || companyItem.companyName || 'N/A'],
            ['Contact', `${details?.contactDetails?.email || 'N/A'} | ${details?.contactDetails?.phone || 'N/A'}`],
            ['Focal Person', `${details?.focalPerson?.name || 'N/A'} | ${details?.focalPerson?.email || 'N/A'} | ${details?.focalPerson?.phone || 'N/A'}`],
            ['Room / Reps', `${details?.room?.roomName || 'Not Allocated'} | Reps: ${details?.repsCount ?? 0}`],
            ['Interview Summary', `Interviewed: ${details?.interviewStats?.totalInterviews ?? 0} | Called: ${details?.scheduledInterviews?.length ?? 0} | Hired: ${details?.interviewStats?.hired ?? 0} | Shortlisted: ${details?.interviewStats?.shortlisted ?? 0}`],
          ],
          theme: 'grid',
          headStyles: { fillColor: [37, 99, 235] },
          styles: { fontSize: 8, cellPadding: 2.5 },
          columnStyles: {
            0: { cellWidth: 42 },
            1: { cellWidth: 145 }
          }
        });

        autoTable(doc, {
          startY: (doc.lastAutoTable?.finalY || 30) + 8,
          head: [['CDC Submitted At', 'Question', 'Response']],
          body: questionRowsByType(cdcItems, 'CDC').length
            ? questionRowsByType(cdcItems, 'CDC')
            : [['-', 'No CDC response submitted', '-']],
          theme: 'striped',
          headStyles: { fillColor: [79, 70, 229] },
          styles: { fontSize: 7 }
        });

        autoTable(doc, {
          startY: (doc.lastAutoTable?.finalY || 30) + 8,
          head: [['Department Submitted At', 'Question', 'Response']],
          body: questionRowsByType(deptItems, 'Department').length
            ? questionRowsByType(deptItems, 'Department')
            : [['-', 'No Department response submitted', '-']],
          theme: 'striped',
          headStyles: { fillColor: [245, 158, 11] },
          styles: { fontSize: 7 }
        });
      }

      doc.save(`All_Company_Survey_Profile_Reports_${new Date().toISOString().split('T')[0]}.pdf`);
      toast.dismiss(loadingToastId);
      toast.success('Bulk company reports downloaded');
    } catch (error) {
      toast.dismiss(loadingToastId);
      toast.error('Failed to generate bulk company reports');
    }
  };

  const handleViewDetails = (survey) => {
    const resolvedCompanyId = survey.companyId || companies.find((c) => c.name === survey.companyName)?.companyId;

    if (!resolvedCompanyId) {
      toast.error('Company profile not found for this survey');
      return;
    }

    navigate(`/admin/surveys/company/${resolvedCompanyId}`);
  };

  const clearFilters = () => {
    setFilters({ surveyType: 'all', companyId: 'all', search: '' });
  };

  // Calculate CDC stats for charts
  const getCDCStats = (field) => {
    const counts = { Good: 0, Average: 0, Bad: 0 };
    surveys.filter(s => s.type === 'CDC').forEach(s => {
      const val = s.responses?.[field] || 'Average';
      if (counts[val] !== undefined) counts[val]++;
    });
    return [
      { name: 'Good', value: counts.Good },
      { name: 'Average', value: counts.Average },
      { name: 'Bad', value: counts.Bad },
    ];
  };

  // Calculate Department (Likert) stats for charts
  const getDeptStats = (field) => {
    const counts = { Exceptionally: 0, ToAGreatExtent: 0, Moderately: 0, Somewhat: 0, NotAtAll: 0 };
    surveys.filter(s => s.type === 'Department').forEach(s => {
      const val = s.responses?.[field];
      if (val && counts[val] !== undefined) counts[val]++;
    });
    return [
      { name: 'Exceptionally', value: counts.Exceptionally },
      { name: 'To A Great Extent', value: counts.ToAGreatExtent },
      { name: 'Moderately', value: counts.Moderately },
      { name: 'Somewhat', value: counts.Somewhat },
      { name: 'Not At All', value: counts.NotAtAll },
    ];
  };

  return (
    <div className="space-y-8 animate-fade-in pb-20">
      {/* Header */}
      <div className="flex flex-col gap-6">
        <div className="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Employer Feedback & Survey Analysis</h1>
            <p className="text-gray-500 mt-1">View, analyze, and download all survey responses and feedback from companies.</p>
          </div>
          <div className="flex gap-2 flex-wrap">
            <button
              onClick={downloadAllCompanyReports}
              className="px-4 py-2 bg-white border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 text-sm font-medium flex items-center transition shadow-sm"
            >
              <Download size={16} className="mr-2 text-blue-600" /> All Company Reports
            </button>
            <button
              onClick={downloadPDFReport}
              className="px-4 py-2 bg-white border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 text-sm font-medium flex items-center transition shadow-sm"
            >
              <Download size={16} className="mr-2 text-indigo-600" /> PDF
            </button>
            <button
              onClick={downloadCSVReport}
              className="px-4 py-2 bg-white border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 text-sm font-medium flex items-center transition shadow-sm"
            >
              <Download size={16} className="mr-2 text-green-600" /> CSV
            </button>
          </div>
        </div>

        {/* View Toggle Tabs */}
        <div className="flex gap-2 bg-white p-2 rounded-xl border border-gray-200 shadow-sm w-fit">
          <button
            onClick={() => setActiveView('list')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
              activeView === 'list'
                ? 'bg-indigo-600 text-white shadow-md'
                : 'text-gray-600 hover:bg-gray-100'
            }`}
          >
            <FileText size={16} className="inline mr-2" /> Survey List
          </button>
          <button
            onClick={() => setActiveView('cdc-stats')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
              activeView === 'cdc-stats'
                ? 'bg-indigo-600 text-white shadow-md'
                : 'text-gray-600 hover:bg-gray-100'
            }`}
          >
            <Award size={16} className="inline mr-2" /> CDC Feedback
          </button>
          <button
            onClick={() => setActiveView('dept-stats')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
              activeView === 'dept-stats'
                ? 'bg-indigo-600 text-white shadow-md'
                : 'text-gray-600 hover:bg-gray-100'
            }`}
          >
            <BarChart3 size={16} className="inline mr-2" /> Department Analysis
          </button>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500 font-medium">Total Responses</p>
                <h3 className="text-2xl font-bold text-gray-800 mt-1">{stats.total}</h3>
              </div>
              <FileText size={24} className="text-gray-400" />
            </div>
          </div>
          <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500 font-medium">CDC Surveys</p>
                <h3 className="text-2xl font-bold text-indigo-600 mt-1">{stats.cdc}</h3>
              </div>
              <BarChart3 size={24} className="text-indigo-400" />
            </div>
          </div>
          <div className="bg-white p-6 rounded-xl border border-gray-100 shadow-sm">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500 font-medium">Department Surveys</p>
                <h3 className="text-2xl font-bold text-amber-600 mt-1">{stats.department}</h3>
              </div>
              <BarChart3 size={24} className="text-amber-400" />
            </div>
          </div>
        </div>
      </div>

      {/* Toolbar & Filters - Only show when viewing list */}
      {activeView === 'list' && (
      <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm sticky top-0 z-10">
        <div className="flex flex-col lg:flex-row gap-4 items-end">
          {/* Search */}
          <div className="relative group flex-1">
            <Search className="w-4 h-4 absolute left-3 top-2.5 text-gray-400 group-focus-within:text-indigo-500 transition-colors" />
            <input
              type="text"
              placeholder="Search Company..."
              className="w-full pl-9 pr-3 py-2 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 focus:border-transparent outline-none transition-all"
              value={filters.search}
              onChange={(e) => setFilters({ ...filters, search: e.target.value })}
            />
          </div>

          {/* Filter by Type */}
          <select
            className="border border-gray-200 rounded-lg px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500 bg-white cursor-pointer hover:border-gray-300 transition-colors"
            value={filters.surveyType}
            onChange={(e) => setFilters({ ...filters, surveyType: e.target.value })}
          >
            <option value="all">All Types</option>
            <option value="CDC">CDC Only</option>
            <option value="Department">Department Only</option>
          </select>

          {/* Filter by Company */}
          <select
            className="border border-gray-200 rounded-lg px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500 bg-white cursor-pointer hover:border-gray-300 transition-colors"
            value={filters.companyId}
            onChange={(e) => setFilters({ ...filters, companyId: e.target.value })}
          >
            <option value="all">All Companies</option>
            {companies.map(c => (
              <option key={c.companyId} value={c.companyId}>{c.name}</option>
            ))}
          </select>

          {/* Clear Filters */}
          <button
            onClick={clearFilters}
            className="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg transition"
            title="Reset Filters"
          >
            <RotateCcw size={18} />
          </button>
        </div>
      </div>
      )}

      {/* VIEW 1: Surveys Table */}
      {activeView === 'list' && (
      <div className="bg-white rounded-xl border shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Company</th>
                <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Survey Type</th>
                <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Submitted</th>
                <th className="px-6 py-4 text-right text-xs font-bold text-gray-700 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {loading ? (
                [...Array(6)].map((_, i) => (
                  <tr key={i} className="animate-pulse bg-white hover:bg-gray-50">
                    <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-40"></div></td>
                    <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-20"></div></td>
                    <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-32"></div></td>
                    <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-20 ml-auto"></div></td>
                  </tr>
                ))
              ) : processedSurveys.length > 0 ? (
                processedSurveys.map((survey) => (
                  <tr key={survey.surveyId} className="bg-white hover:bg-gray-50 transition-colors group">
                    <td className="px-6 py-4">
                      <p className="font-semibold text-gray-900 group-hover:text-indigo-600 transition-colors">{survey.companyName}</p>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`px-2.5 py-0.5 rounded-full text-xs font-bold border ${
                        survey.type === 'CDC'
                          ? 'bg-indigo-100 text-indigo-700 border-indigo-200'
                          : 'bg-amber-100 text-amber-700 border-amber-200'
                      }`}>
                        {survey.type}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2 text-sm text-gray-600">
                        <Calendar size={14} className="text-gray-400" />
                        {new Date(survey.submittedAt).toLocaleDateString()}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button
                        onClick={() => handleViewDetails(survey)}
                        className="px-3 py-1.5 text-xs font-medium text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-lg transition-colors flex items-center gap-1 ml-auto"
                      >
                        <Eye size={14} /> Show
                      </button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="4" className="px-6 py-16 text-center">
                    <Search size={48} className="text-gray-300 mb-4 mx-auto" />
                    <p className="text-lg font-medium text-gray-600">No surveys found</p>
                    <p className="text-sm text-gray-400">Try adjusting your filters.</p>
                    <button onClick={clearFilters} className="mt-4 text-indigo-600 hover:text-indigo-800 font-medium text-sm">Clear Filters</button>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
      )}

      {/* VIEW 2: CDC Feedback Stats */}
      {activeView === 'cdc-stats' && (
      <div className="space-y-8" ref={cdcChartsRef}>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* FYP Quality */}
          <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
            <div className="flex items-center gap-2 mb-4 text-gray-800 font-bold">
              <Award className="text-indigo-600" size={20} /> FYP Quality
            </div>
            <div className="h-48">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={getCDCStats('FypQuality')} innerRadius={40} outerRadius={60} paddingAngle={5} dataKey="value">
                    {getCDCStats('FypQuality').map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={CDC_COLORS[index]} />
                    ))}
                  </Pie>
                  <Tooltip />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Arrangement Quality */}
          <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
            <div className="flex items-center gap-2 mb-4 text-gray-800 font-bold">
              <Layout className="text-blue-600" size={20} /> Arrangements
            </div>
            <div className="h-48">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={getCDCStats('ArrangementQuality')} innerRadius={40} outerRadius={60} paddingAngle={5} dataKey="value">
                    {getCDCStats('ArrangementQuality').map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={CDC_COLORS[index]} />
                    ))}
                  </Pie>
                  <Tooltip />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Lunch Quality */}
          <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
            <div className="flex items-center gap-2 mb-4 text-gray-800 font-bold">
              <Coffee className="text-amber-600" size={20} /> Refreshments
            </div>
            <div className="h-48">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={getCDCStats('LunchQuality')} innerRadius={40} outerRadius={60} paddingAngle={5} dataKey="value">
                    {getCDCStats('LunchQuality').map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={CDC_COLORS[index]} />
                    ))}
                  </Pie>
                  <Tooltip />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>

        {/* CDC Comments */}
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
          <div className="p-5 border-b border-gray-100 bg-gray-50">
            <h3 className="font-bold text-gray-800 flex items-center gap-2">
              <MessageSquare size={18} /> CDC Survey Comments
            </h3>
          </div>
          <div className="divide-y divide-gray-100">
            {surveys.filter(s => s.type === 'CDC').map((s) => (
              <div key={s.surveyId} className="p-6 hover:bg-gray-50 transition">
                <div className="flex justify-between items-start mb-2">
                  <span className="font-bold text-gray-900">{s.companyName || "Anonymous Company"}</span>
                  <span className="text-xs text-gray-400">{new Date(s.submittedAt).toLocaleDateString()}</span>
                </div>
                
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm mt-3">
                  <div className="bg-indigo-50 p-3 rounded-lg">
                    <span className="block text-xs font-bold text-indigo-400 uppercase mb-1">FYP Suggestions</span>
                    <p className="text-gray-700 italic">"{s.responses?.FypComments || 'No comments'}"</p>
                  </div>
                  <div className="bg-blue-50 p-3 rounded-lg">
                    <span className="block text-xs font-bold text-blue-400 uppercase mb-1">Arrangements</span>
                    <p className="text-gray-700 italic">"{s.responses?.ArrangementComments || 'No comments'}"</p>
                  </div>
                  <div className="bg-amber-50 p-3 rounded-lg">
                    <span className="block text-xs font-bold text-amber-500 uppercase mb-1">Food & Lunch</span>
                    <p className="text-gray-700 italic">"{s.responses?.LunchComments || 'No comments'}"</p>
                  </div>
                </div>
              </div>
            ))}
            {surveys.filter(s => s.type === 'CDC').length === 0 && (
              <div className="p-10 text-center text-gray-400 italic">No CDC surveys submitted yet.</div>
            )}
          </div>
        </div>
      </div>
      )}

      {/* VIEW 3: Department Feedback Stats */}
      {activeView === 'dept-stats' && (
      <div className="space-y-8" ref={deptChartsRef}>
        {/* PEO-1 Questions */}
        <div>
          <h2 className="text-xl font-bold text-gray-900 mb-4">PEO-1: Technical Knowledge & Creativity</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
              <h3 className="font-semibold text-gray-800 mb-4 text-sm">Q1: Technical Knowledge</h3>
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO1_Q1')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-45} textAnchor="end" height={80} interval={0} tick={{ fontSize: 12 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#3B82F6" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
              <h3 className="font-semibold text-gray-800 mb-4 text-sm">Q2: Analysis & Investigation</h3>
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO1_Q2')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-45} textAnchor="end" height={80} interval={0} tick={{ fontSize: 12 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#10B981" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
              <h3 className="font-semibold text-gray-800 mb-4 text-sm">Q3: Design & Implementation</h3>
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO1_Q3')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-45} textAnchor="end" height={80} interval={0} tick={{ fontSize: 12 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#F59E0B" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          </div>
        </div>

        {/* PEO-2 Questions */}
        <div>
          <h2 className="text-xl font-bold text-gray-900 mb-4">PEO-2: Adaptability & Entrepreneurship</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
              <h3 className="font-semibold text-gray-800 mb-4 text-sm">Q1: Desire to Learn & Adapt</h3>
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO2_Q1')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-45} textAnchor="end" height={80} interval={0} tick={{ fontSize: 12 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#EF5350" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
              <h3 className="font-semibold text-gray-800 mb-4 text-sm">Q2: Entrepreneurship Promotion</h3>
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO2_Q2')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-45} textAnchor="end" height={80} interval={0} tick={{ fontSize: 12 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#8B5CF6" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          </div>
        </div>

        {/* PEO-3 Questions */}
        <div>
          <h2 className="text-xl font-bold text-gray-900 mb-4">PEO-3: Ethics & Communication</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
              <h3 className="font-semibold text-gray-800 mb-4 text-sm">Q1: Ethics Awareness</h3>
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO3_Q1')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-45} textAnchor="end" height={80} interval={0} tick={{ fontSize: 12 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#06B6D4" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
              <h3 className="font-semibold text-gray-800 mb-4 text-sm">Q2: Communication Skills</h3>
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO3_Q2')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-45} textAnchor="end" height={80} interval={0} tick={{ fontSize: 12 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#EC4899" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          </div>
        </div>

        {/* PEO-4 Questions */}
        <div>
          <h2 className="text-xl font-bold text-gray-900 mb-4">PEO-4: Socio-Economic Contribution</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
              <h3 className="font-semibold text-gray-800 mb-4 text-sm">Q1: Societal Contribution</h3>
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO4_Q1')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-45} textAnchor="end" height={80} interval={0} tick={{ fontSize: 12 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#14B8A6" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
              <h3 className="font-semibold text-gray-800 mb-4 text-sm">Q2: Economic Growth</h3>
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO4_Q2')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-45} textAnchor="end" height={80} interval={0} tick={{ fontSize: 12 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#F97316" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
              <h3 className="font-semibold text-gray-800 mb-4 text-sm">Q3: Innovation Support</h3>
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO4_Q3')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-45} textAnchor="end" height={80} interval={0} tick={{ fontSize: 12 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#A855F7" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          </div>
        </div>

        {/* Open-Ended Feedback */}
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
          <div className="p-5 border-b border-gray-100 bg-gray-50">
            <h3 className="font-bold text-gray-800">Open-Ended Feedback</h3>
          </div>
          <div className="divide-y">
            {surveys.filter(s => s.type === 'Department').map((s) => (
              <div key={s.surveyId} className="p-6 hover:bg-gray-50 transition">
                <div className="mb-3">
                  <span className="font-bold text-gray-900">{s.companyName}</span>
                  <span className="text-xs text-gray-400 ml-2">{new Date(s.submittedAt).toLocaleDateString()}</span>
                </div>
                <div className="space-y-3 text-sm">
                  {s.responses?.TechnologiesSuggestion && (
                    <div className="bg-blue-50 p-3 rounded-lg">
                      <span className="block text-xs font-bold text-blue-600 mb-1">Technologies/Skills Suggestion</span>
                      <p className="text-gray-700">{s.responses.TechnologiesSuggestion}</p>
                    </div>
                  )}
                  {s.responses?.GeneralFeedback && (
                    <div className="bg-green-50 p-3 rounded-lg">
                      <span className="block text-xs font-bold text-green-600 mb-1">General Feedback</span>
                      <p className="text-gray-700">{s.responses.GeneralFeedback}</p>
                    </div>
                  )}
                  {s.responses?.ImprovementSuggestions && (
                    <div className="bg-amber-50 p-3 rounded-lg">
                      <span className="block text-xs font-bold text-amber-600 mb-1">Improvement Suggestions</span>
                      <p className="text-gray-700">{s.responses.ImprovementSuggestions}</p>
                    </div>
                  )}
                </div>
              </div>
            ))}
            {surveys.filter(s => s.type === 'Department').length === 0 && (
              <div className="p-10 text-center text-gray-400 italic">No Department surveys submitted yet.</div>
            )}
          </div>
        </div>
      </div>
      )}

      {/* Hidden export-only chart containers for PDF generation */}
      <div className="fixed -left-[99999px] top-0 w-[1400px] bg-white p-6 pointer-events-none" aria-hidden="true">
        <div ref={cdcExportRef} className="space-y-6">
          <h2 className="text-xl font-bold text-gray-900">CDC Feedback</h2>
          <div className="grid grid-cols-3 gap-6">
            <div className="bg-white p-6 rounded-xl border border-gray-200">
              <div className="font-bold mb-3">FYP Quality</div>
              <div className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={getCDCStats('FypQuality')} innerRadius={45} outerRadius={75} paddingAngle={5} dataKey="value">
                      {getCDCStats('FypQuality').map((entry, index) => (
                        <Cell key={`export-cdc-fyp-${index}`} fill={CDC_COLORS[index]} />
                      ))}
                    </Pie>
                    <Tooltip />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200">
              <div className="font-bold mb-3">Arrangement Quality</div>
              <div className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={getCDCStats('ArrangementQuality')} innerRadius={45} outerRadius={75} paddingAngle={5} dataKey="value">
                      {getCDCStats('ArrangementQuality').map((entry, index) => (
                        <Cell key={`export-cdc-arr-${index}`} fill={CDC_COLORS[index]} />
                      ))}
                    </Pie>
                    <Tooltip />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200">
              <div className="font-bold mb-3">Lunch Quality</div>
              <div className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={getCDCStats('LunchQuality')} innerRadius={45} outerRadius={75} paddingAngle={5} dataKey="value">
                      {getCDCStats('LunchQuality').map((entry, index) => (
                        <Cell key={`export-cdc-lunch-${index}`} fill={CDC_COLORS[index]} />
                      ))}
                    </Pie>
                    <Tooltip />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </div>
          </div>
        </div>

        <div ref={deptExportRef} className="space-y-6 mt-10">
          <h2 className="text-xl font-bold text-gray-900">Department Analysis</h2>
          <div className="grid grid-cols-2 gap-6">
            <div className="bg-white p-6 rounded-xl border border-gray-200">
              <h3 className="font-semibold text-gray-800 mb-3 text-sm">PEO-1 Q1: Technical Knowledge</h3>
              <div className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO1_Q1')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-30} textAnchor="end" height={70} interval={0} tick={{ fontSize: 11 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#3B82F6" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200">
              <h3 className="font-semibold text-gray-800 mb-3 text-sm">PEO-1 Q2: Analysis & Investigation</h3>
              <div className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO1_Q2')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-30} textAnchor="end" height={70} interval={0} tick={{ fontSize: 11 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#10B981" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200">
              <h3 className="font-semibold text-gray-800 mb-3 text-sm">PEO-1 Q3: Design & Implementation</h3>
              <div className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO1_Q3')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-30} textAnchor="end" height={70} interval={0} tick={{ fontSize: 11 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#F59E0B" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200">
              <h3 className="font-semibold text-gray-800 mb-3 text-sm">PEO-2 Q1: Desire to Learn</h3>
              <div className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO2_Q1')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-30} textAnchor="end" height={70} interval={0} tick={{ fontSize: 11 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#EF5350" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200">
              <h3 className="font-semibold text-gray-800 mb-3 text-sm">PEO-2 Q2: Entrepreneurship</h3>
              <div className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO2_Q2')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-30} textAnchor="end" height={70} interval={0} tick={{ fontSize: 11 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#8B5CF6" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200">
              <h3 className="font-semibold text-gray-800 mb-3 text-sm">PEO-3 Q1: Ethics Awareness</h3>
              <div className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO3_Q1')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-30} textAnchor="end" height={70} interval={0} tick={{ fontSize: 11 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#06B6D4" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200">
              <h3 className="font-semibold text-gray-800 mb-3 text-sm">PEO-3 Q2: Communication Skills</h3>
              <div className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO3_Q2')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-30} textAnchor="end" height={70} interval={0} tick={{ fontSize: 11 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#EC4899" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200">
              <h3 className="font-semibold text-gray-800 mb-3 text-sm">PEO-4 Q1: Societal Contribution</h3>
              <div className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO4_Q1')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-30} textAnchor="end" height={70} interval={0} tick={{ fontSize: 11 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#14B8A6" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200">
              <h3 className="font-semibold text-gray-800 mb-3 text-sm">PEO-4 Q2: Economic Growth</h3>
              <div className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO4_Q2')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-30} textAnchor="end" height={70} interval={0} tick={{ fontSize: 11 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#F97316" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200">
              <h3 className="font-semibold text-gray-800 mb-3 text-sm">PEO-4 Q3: Innovation Support</h3>
              <div className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={getDeptStats('PEO4_Q3')}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-30} textAnchor="end" height={70} interval={0} tick={{ fontSize: 11 }} />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#A855F7" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};


export default SurveyResponses;
