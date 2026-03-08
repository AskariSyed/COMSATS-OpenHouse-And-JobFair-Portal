/* eslint-disable no-unused-vars */
import React, { useEffect, useState, useMemo, useRef } from 'react';
import {
  Download, Filter, Search, Calendar, Building2, FileText,
  ChevronDown, BarChart3, Eye, RotateCcw, MessageSquare, Coffee, Layout, Award, Bell, Mail
} from 'lucide-react';
import api from '../../lib/api';
import { toast } from 'react-hot-toast';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import html2canvas from 'html2canvas';
import { PieChart, Pie, Cell, Tooltip, Legend, ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid } from 'recharts';
import { useNavigate } from 'react-router-dom';
import LogoWithoutBg from '../../assets/LogoWithoutBg.png';

// Survey question labels
const SURVEY_QUESTIONS = {
  CDC: {
    FypQuality: 'FYP Quality (Good / Average / Bad)',
    ArrangementQuality: 'Arrangement Quality (Good / Average / Bad)',
    LunchQuality: 'Lunch Quality (Good / Average / Bad)',
    FypComments: 'FYP Quality Comments (Optional)',
    ArrangementComments: 'Arrangement Quality Comments (Optional)',
    LunchComments: 'Lunch Quality Comments (Optional)',
  },
  Department: {
    PEO1_Q1:
      'PEO-1 Q1: Students possess adequate technical knowledge to successfully perform in the professional computing environment.',
    PEO1_Q2:
      'PEO-1 Q2: Students have the ability to analyze / investigate computing problems.',
    PEO1_Q3:
      'PEO-1 Q3: Students have the ability to design and implement solutions to complex computing problems.',
    PEO2_Q1:
      'PEO-2 Q1: Students have the desire to learn and adapt to new technology trends.',
    PEO2_Q2:
      'PEO-2 Q2: Students are prepared to share and utilize acquired knowledge to promote entrepreneurship in society.',
    PEO3_Q1:
      'PEO-3 Q1: Students have awareness about ethical and moral concerns pertinent to the computing domain.',
    PEO3_Q2:
      'PEO-3 Q2: Students have effective oral and written communication skills.',
    PEO4_Q1:
      'PEO-4 Q1: Students are educated and trained well to contribute to society in general.',
    PEO4_Q2:
      'PEO-4 Q2: Students are trained to utilize their knowledge and skills for economic growth of the country.',
    PEO4_Q3:
      'PEO-4 Q3: Students have the ability to capitalize knowledge to support innovation.',
    TechnologiesSuggestion:
      'Technologies/Skills Suggestion: What additional technologies / programming languages / skills are currently in demand and should be taught to our computing students at CUI, Islamabad?',
    GeneralFeedback:
      'General Feedback: Please share your feedback about CUI graduates in terms of their professional attributes (specific strengths and weaknesses) that may be connected to their education before joining your organization.',
    ImprovementSuggestions:
      'Improvement Suggestions: Any comments or suggestions that you may have in the future to help us improve the quality of our educational program objectives and graduates.',
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
  const [activeView, setActiveView] = useState('list'); // list, pending, cdc-stats, dept-stats
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
        : (companiesRes.data.companies || companiesRes.data.Companies || []);
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

  const companyResponseRows = useMemo(() => {
    const map = new Map();

    processedSurveys.forEach((survey) => {
      const key = String(survey.companyId || survey.companyName || '').trim();
      if (!key) return;

      if (!map.has(key)) {
        map.set(key, {
          companyId: survey.companyId,
          companyName: survey.companyName,
          cdc: false,
          department: false,
          latestSubmittedAt: survey.submittedAt,
        });
      }

      const row = map.get(key);
      if (survey.type === 'CDC') row.cdc = true;
      if (survey.type === 'Department') row.department = true;

      const existingDate = new Date(row.latestSubmittedAt || 0).getTime();
      const nextDate = new Date(survey.submittedAt || 0).getTime();
      if (nextDate > existingDate) {
        row.latestSubmittedAt = survey.submittedAt;
      }
    });

    return Array.from(map.values()).sort(
      (a, b) =>
        new Date(b.latestSubmittedAt || 0).getTime() -
        new Date(a.latestSubmittedAt || 0).getTime()
    );
  }, [processedSurveys]);

  const pendingCompanies = useMemo(() => {
    const responseMap = new Map();

    surveys.forEach((survey) => {
      const idKey = survey.companyId ? `id-${survey.companyId}` : null;
      const nameKey = String(survey.companyName || '').trim().toLowerCase();
      const key = idKey || `name-${nameKey}`;
      if (!key || key === 'name-') return;

      if (!responseMap.has(key)) {
        responseMap.set(key, { hasCDC: false, hasDepartment: false });
      }

      const entry = responseMap.get(key);
      if (survey.type === 'CDC') entry.hasCDC = true;
      if (survey.type === 'Department') entry.hasDepartment = true;
    });

    let rows = companies.map((company) => {
      const companyId = company.companyId || company.CompanyId;
      const companyName = String(company.name || company.Name || company.companyName || '').trim();
      const directKey = companyId ? `id-${companyId}` : `name-${companyName.toLowerCase()}`;
      const fallbackKey = `name-${companyName.toLowerCase()}`;
      const responseEntry = responseMap.get(directKey) || responseMap.get(fallbackKey) || { hasCDC: false, hasDepartment: false };

      const missing = [];
      if (!responseEntry.hasCDC) missing.push('CDC');
      if (!responseEntry.hasDepartment) missing.push('Department');

      return {
        companyId,
        companyName,
        email:
          company.email ||
          company.Email ||
          company.contactEmail ||
          company.ContactEmail ||
          company.companyEmail ||
          company.CompanyEmail ||
          'N/A',
        room:
          company.roomName ||
          company.RoomName ||
          company.roomNo ||
          company.RoomNo ||
          company.room ||
          company.Room ||
          'Not Allocated',
        hasCDC: responseEntry.hasCDC,
        hasDepartment: responseEntry.hasDepartment,
        missing,
      };
    }).filter((row) => row.missing.length > 0);

    if (filters.search) {
      const term = filters.search.toLowerCase();
      rows = rows.filter((row) => row.companyName.toLowerCase().includes(term));
    }

    if (filters.companyId !== 'all') {
      rows = rows.filter((row) => String(row.companyId) === String(filters.companyId));
    }

    return rows.sort((a, b) => {
      if (b.missing.length !== a.missing.length) return b.missing.length - a.missing.length;
      return a.companyName.localeCompare(b.companyName);
    });
  }, [companies, surveys, filters.search, filters.companyId]);

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

    const loadingToastId = toast.loading('Preparing PDF report...');

    try {
      const doc = new jsPDF();
    doc.setFontSize(18);
    doc.setTextColor(79, 70, 229);
    doc.text("Survey Responses Report", 14, 20);

    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Generated on: ${new Date().toLocaleString()}`, 14, 28);

    const surveyType = filters.surveyType === 'all' ? 'All' : filters.surveyType;
    doc.text(`Survey Type: ${surveyType} | Total Responses: ${processedSurveys.length}`, 14, 35);

    const cdcSurveyItems = processedSurveys.filter((s) => s.type === 'CDC');
    const deptSurveyItems = processedSurveys.filter((s) => s.type === 'Department');

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

    const addChartSection = async (title, elementRef, startY) => {
      if (!elementRef?.current) return;

      const pageWidth = doc.internal.pageSize.getWidth();
      const pageHeight = doc.internal.pageSize.getHeight();
      const marginX = 14;
      const marginBottom = 15;

      const initialY = startY ?? 20;
      let y = initialY;
      if (y > pageHeight - 40) {
        doc.addPage();
        y = 20;
      }

      doc.setFontSize(12);
      doc.setTextColor(0);
      doc.text(title, marginX, y - 4);

      const chartCards = Array.from(
        elementRef.current.querySelectorAll(':scope .grid > div')
      );

      const renderCard = async (cardElement, targetWidth, targetX, targetY) => {
        const canvas = await html2canvas(cardElement, {
          backgroundColor: '#ffffff',
          scale: 2,
          useCORS: true,
        });

        const naturalHeight = (canvas.height * targetWidth) / canvas.width;
        const maxHeightPerPage = pageHeight - marginBottom - 20;
        const imageHeight = Math.min(naturalHeight, maxHeightPerPage);

        doc.addImage(canvas.toDataURL('image/png'), 'PNG', targetX, targetY, targetWidth, imageHeight);
        return imageHeight;
      };

      if (chartCards.length > 0) {
        const gap = 6;
        const cardWidth = (pageWidth - marginX * 2 - gap) / 2;
        let rowY = y + 4;
        let rowMaxHeight = 0;
        let colIndex = 0;

        for (const card of chartCards) {
          const cardX = marginX + colIndex * (cardWidth + gap);

          // If current row cannot fit next card, move to a fresh page/row first.
          if (rowY + 50 > pageHeight - marginBottom) {
            doc.addPage();
            rowY = 20;
            colIndex = 0;
            rowMaxHeight = 0;
          }

          const renderedHeight = await renderCard(card, cardWidth, cardX, rowY);
          rowMaxHeight = Math.max(rowMaxHeight, renderedHeight);

          if (colIndex === 1) {
            rowY += rowMaxHeight + 6;
            rowMaxHeight = 0;
            colIndex = 0;
          } else {
            colIndex = 1;
          }

          if (rowY > pageHeight - marginBottom && colIndex === 0) {
            doc.addPage();
            rowY = 20;
          }
        }

        if (colIndex === 1) {
          rowY += rowMaxHeight + 6;
        }

        y = rowY;
      } else {
        const canvas = await html2canvas(elementRef.current, {
          backgroundColor: '#ffffff',
          scale: 2,
          useCORS: true,
        });
        const imageMaxWidth = pageWidth - marginX * 2;
        const imageHeight = (canvas.height * imageMaxWidth) / canvas.width;
        if (y + imageHeight > pageHeight - marginBottom) {
          doc.addPage();
          y = 20;
        }
        doc.addImage(canvas.toDataURL('image/png'), 'PNG', marginX, y + 4, imageMaxWidth, imageHeight);
        y += imageHeight + 12;
      }

      return y;
    };

    let nextY = (doc.lastAutoTable?.finalY || 42) + 10;
    nextY = await addChartSection('CDC Feedback Graphs', cdcExportRef, nextY);

    if (deptSurveyItems.length > 0 && deptExportRef?.current) {
      doc.addPage();
      nextY = 20;
      nextY = await addChartSection('Department Analysis Graphs', deptExportRef, nextY);
    }

    if (nextY > doc.internal.pageSize.getHeight() - 80) {
      doc.addPage();
      nextY = 20;
    }
    doc.setFontSize(14);
    doc.setTextColor(0);
    doc.text('Numeric Summary', 14, nextY);

    autoTable(doc, {
      startY: nextY + 6,
      head: [['Metric', 'Value']],
      body: [
        ['Total Responses', String(processedSurveys.length)],
        ['CDC Responses', String(cdcSurveyItems.length)],
        ['Department Responses', String(deptSurveyItems.length)],
      ],
      theme: 'striped',
      headStyles: { fillColor: [79, 70, 229] },
      styles: { fontSize: 9 }
    });

    const getCDCStatsForItems = (items, field) => {
      const counts = { Good: 0, Average: 0, Bad: 0 };
      items.forEach((item) => {
        const value = item.responses?.[field] || 'Average';
        if (counts[value] !== undefined) counts[value] += 1;
      });
      return counts;
    };

    const getDeptStatsForItems = (items, field) => {
      const counts = { Exceptionally: 0, ToAGreatExtent: 0, Moderately: 0, Somewhat: 0, NotAtAll: 0 };
      items.forEach((item) => {
        const value = item.responses?.[field];
        if (value && counts[value] !== undefined) counts[value] += 1;
      });
      return counts;
    };

    const asCountWithPercentage = (value, total) => {
      const safeTotal = total > 0 ? total : 0;
      const percentage = safeTotal > 0 ? ((value / safeTotal) * 100).toFixed(1) : '0.0';
      return `${value} (${percentage}%)`;
    };

    const cdcSummaryRows = [
      ['FypQuality'],
      ['ArrangementQuality'],
      ['LunchQuality']
    ].map(([key]) => {
      const counts = getCDCStatsForItems(cdcSurveyItems, key);
      const total = counts.Good + counts.Average + counts.Bad;
      const fullQuestion = SURVEY_QUESTIONS.CDC[key] || key;
      return [
        fullQuestion,
        asCountWithPercentage(counts.Good, total),
        asCountWithPercentage(counts.Average, total),
        asCountWithPercentage(counts.Bad, total),
        String(total)
      ];
    });

    autoTable(doc, {
      startY: (doc.lastAutoTable?.finalY || 30) + 10,
      head: [['CDC Question', 'Good', 'Average', 'Bad', 'Total']],
      body: cdcSummaryRows,
      theme: 'grid',
      headStyles: { fillColor: [16, 185, 129] },
      styles: { fontSize: 8 },
      columnStyles: {
        0: { cellWidth: 95 }
      }
    });

    const deptSummaryRows = [
      ['PEO1_Q1'],
      ['PEO1_Q2'],
      ['PEO1_Q3'],
      ['PEO2_Q1'],
      ['PEO2_Q2'],
      ['PEO3_Q1'],
      ['PEO3_Q2'],
      ['PEO4_Q1'],
      ['PEO4_Q2'],
      ['PEO4_Q3']
    ].map(([key]) => {
      const counts = getDeptStatsForItems(deptSurveyItems, key);
      const total =
        counts.Exceptionally +
        counts.ToAGreatExtent +
        counts.Moderately +
        counts.Somewhat +
        counts.NotAtAll;

      return [
        SURVEY_QUESTIONS.Department[key] || key,
        asCountWithPercentage(counts.Exceptionally, total),
        asCountWithPercentage(counts.ToAGreatExtent, total),
        asCountWithPercentage(counts.Moderately, total),
        asCountWithPercentage(counts.Somewhat, total),
        asCountWithPercentage(counts.NotAtAll, total),
        String(total)
      ];
    });

    autoTable(doc, {
      startY: (doc.lastAutoTable?.finalY || 30) + 10,
      head: [['Dept Question', 'Exceptional', 'Great', 'Moderate', 'Somewhat', 'Not At All', 'Total']],
      body: deptSummaryRows,
      theme: 'grid',
      headStyles: { fillColor: [245, 158, 11] },
      styles: { fontSize: 7 },
      columnStyles: {
        0: { cellWidth: 65 }
      }
    });

      doc.save(`Survey_Responses_${surveyType}_${new Date().toISOString().split('T')[0]}.pdf`);
      toast.dismiss(loadingToastId);
      toast.success("PDF downloaded successfully!");
    } catch (error) {
      console.error('PDF generation failed:', error);
      toast.dismiss(loadingToastId);
      toast.error('Failed to generate PDF report');
    }
  };

  const getPdfBrandingAssets = async () => {
    let jobFairLabel = 'Semester of job Fair /Title';
    try {
      const jobFairRes = await api.get('/admin/jobfairs?page=1&pageSize=1000');
      const fairs = Array.isArray(jobFairRes.data)
        ? jobFairRes.data
        : (jobFairRes.data?.jobFairs || jobFairRes.data?.JobFairs || []);
      const activeFair = fairs.find((f) => (f.isActive ?? f.IsActive) === true) || fairs[0];
      const resolvedLabel =
        activeFair?.semester ||
        activeFair?.Semester ||
        activeFair?.title ||
        activeFair?.Title ||
        activeFair?.name ||
        activeFair?.Name;
      if (resolvedLabel) jobFairLabel = resolvedLabel;
    } catch {
      // fallback label is used
    }

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

    return { jobFairLabel, logoDataUrl };
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
      const pageWidth = doc.internal.pageSize.getWidth();
      const { jobFairLabel, logoDataUrl } = await getPdfBrandingAssets();

      for (let index = 0; index < uniqueCompanies.length; index++) {
        const companyItem = uniqueCompanies[index];

        if (index > 0) {
          doc.addPage();
        }

        if (logoDataUrl) {
          doc.addImage(logoDataUrl, 'PNG', 14, 8, 18, 18);
        }

        doc.setFontSize(11);
        doc.setTextColor(0);
        doc.setFont(undefined, 'bold');
        doc.text(`Job Fair/Open House (${jobFairLabel})`, pageWidth / 2, 14, { align: 'center' });
        doc.text('CDC CUI, Wah Campus (cdc@ciitwah.edu.pk)', pageWidth / 2, 20, { align: 'center' });

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
        doc.text(details?.name || companyItem.companyName || 'Company', 14, 30);

        doc.setFontSize(9);
        doc.setTextColor(90);
        doc.setFont(undefined, 'normal');
        doc.text(`Generated: ${new Date().toLocaleString()}`, 14, 36);

        autoTable(doc, {
          startY: 40,
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

  const downloadIndividualCompanyReport = async (row) => {
    const companyName = String(row?.companyName || '').trim();
    if (!companyName) {
      toast.error('Invalid company selection');
      return;
    }

    const loadingToastId = toast.loading(`Preparing report for ${companyName}...`);

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

      const companySurveyItems = surveys.filter((surveyItem) => {
        if (row?.companyId && surveyItem.companyId) {
          return String(surveyItem.companyId) === String(row.companyId);
        }
        return (surveyItem.companyName || '').trim().toLowerCase() === companyName.toLowerCase();
      });

      if (companySurveyItems.length === 0) {
        toast.dismiss(loadingToastId);
        toast.error('No survey responses found for this company');
        return;
      }

      const doc = new jsPDF();
      const pageWidth = doc.internal.pageSize.getWidth();
      const { jobFairLabel, logoDataUrl } = await getPdfBrandingAssets();

      let details = null;
      if (row?.companyId) {
        try {
          const detailRes = await api.get(`/admin/companies/${row.companyId}/details`);
          details = detailRes.data;
        } catch {
          details = null;
        }
      }

      const cdcItems = companySurveyItems.filter((s) => s.type === 'CDC');
      const deptItems = companySurveyItems.filter((s) => s.type === 'Department');

      if (logoDataUrl) {
        doc.addImage(logoDataUrl, 'PNG', 14, 8, 18, 18);
      }

      doc.setFontSize(11);
      doc.setTextColor(0);
      doc.setFont(undefined, 'bold');
      doc.text(`Job Fair/Open House (${jobFairLabel})`, pageWidth / 2, 14, { align: 'center' });
      doc.text('CDC CUI, Wah Campus (cdc@ciitwah.edu.pk)', pageWidth / 2, 20, { align: 'center' });

      doc.setFontSize(16);
      doc.setTextColor(37, 99, 235);
      doc.text(details?.name || companyName || 'Company', 14, 30);

      doc.setFontSize(9);
      doc.setTextColor(90);
      doc.setFont(undefined, 'normal');
      doc.text(`Generated: ${new Date().toLocaleString()}`, 14, 36);

      autoTable(doc, {
        startY: 40,
        head: [['Field', 'Value']],
        body: [
          ['Company Name', details?.name || companyName || 'N/A'],
          ['Contact', `${details?.contactDetails?.email || row?.email || 'N/A'} | ${details?.contactDetails?.phone || row?.phone || 'N/A'}`],
          ['Focal Person', `${details?.focalPerson?.name || 'N/A'} | ${details?.focalPerson?.email || 'N/A'} | ${details?.focalPerson?.phone || 'N/A'}`],
          ['Room / Reps', `${details?.room?.roomName || row?.room || 'Not Allocated'} | Reps: ${details?.repsCount ?? 0}`],
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

      doc.save(`Company_Survey_Profile_${companyName.replace(/\s+/g, '_')}_${new Date().toISOString().split('T')[0]}.pdf`);
      toast.dismiss(loadingToastId);
      toast.success(`Company report downloaded for ${companyName}`);
    } catch {
      toast.dismiss(loadingToastId);
      toast.error('Failed to generate company report');
    }
  };

  const remindPendingCompany = async (company) => {
    try {
      await api.post('/admin/surveys/reminders/company', {
        companyId: company.companyId,
        companyName: company.companyName,
        missingSurveyTypes: company.missing,
      });
      toast.success(`Reminder sent to ${company.companyName}`);
      return;
    } catch {
      const email = String(company.email || '').trim();
      if (email && email !== 'N/A') {
        const subject = encodeURIComponent('Survey Reminder - Job Fair Portal');
        const body = encodeURIComponent(`Dear ${company.companyName},\n\nPlease submit your pending survey(s): ${company.missing.join(', ')}.\n\nThank you.`);
        window.open(`mailto:${email}?subject=${subject}&body=${body}`);
        toast.success(`Reminder draft opened for ${company.companyName}`);
      } else {
        toast.error(`No email found for ${company.companyName}`);
      }
    }
  };

  const remindAllPendingCompanies = async () => {
    if (pendingCompanies.length === 0) {
      toast.error('No pending companies found');
      return;
    }

    try {
      await api.post('/admin/surveys/reminders/pending-all', {
        companies: pendingCompanies.map((company) => ({
          companyId: company.companyId,
          companyName: company.companyName,
          missingSurveyTypes: company.missing,
        })),
      });
      toast.success('Reminder sent to all pending companies');
      return;
    } catch {
      const emails = pendingCompanies
        .map((company) => String(company.email || '').trim())
        .filter((email) => email && email !== 'N/A');

      if (emails.length === 0) {
        toast.error('No email addresses available for pending companies');
        return;
      }

      const subject = encodeURIComponent('Survey Reminder - Pending Submissions');
      const body = encodeURIComponent('Please submit your pending survey response(s) in the Job Fair Portal. Thank you.');
      window.open(`mailto:?bcc=${encodeURIComponent(emails.join(';'))}&subject=${subject}&body=${body}`);
      toast.success('Reminder draft opened for all pending companies');
    }
  };

  const downloadAllCDCForms = async () => {
    const cdcSurveys = surveys.filter((s) => s.type === 'CDC');
    if (cdcSurveys.length === 0) {
      toast.error('No CDC survey responses available');
      return;
    }

    const loadingToastId = toast.loading('Preparing CDC survey forms PDF...');

    try {
      const doc = new jsPDF();
      const pageWidth = doc.internal.pageSize.getWidth();
      const { jobFairLabel, logoDataUrl } = await getPdfBrandingAssets();

      const groupedByCompany = cdcSurveys.reduce((map, surveyItem) => {
        const companyName = (surveyItem.companyName || 'Unknown Company').trim();
        if (!map.has(companyName)) map.set(companyName, []);
        map.get(companyName).push(surveyItem);
        return map;
      }, new Map());

      const companyDetailCache = new Map();

      const pickCompanyMeta = (companyName) => {
        const match = companies.find(
          (c) => String(c?.name || c?.Name || '').trim().toLowerCase() === companyName.toLowerCase()
        );

        return {
          employerName: match?.focalPersonName || match?.FocalPersonName || '_________________',
          organizationName: companyName || '_________________',
          email:
            match?.email ||
            match?.Email ||
            match?.contactEmail ||
            match?.ContactEmail ||
            match?.companyEmail ||
            match?.CompanyEmail ||
            '_________________',
          contactNo:
            match?.phone ||
            match?.Phone ||
            match?.contactNo ||
            match?.ContactNo ||
            match?.companyPhone ||
            match?.CompanyPhone ||
            '_________________',
          shortlistedCount: Number(
            match?.shortlistedCount ?? match?.ShortlistedCount ?? 0
          ),
          hiredCount: Number(match?.hiredCount ?? match?.HiredCount ?? 0),
          interviewedCount: Number(
            match?.totalInterviews ?? match?.TotalInterviews ?? 0
          ),
        };
      };

      const drawOptionBadges = (y, selected) => {
        const normalized = String(selected || '').trim().toLowerCase();
        const options = [
          { key: 'good', label: 'Good', color: [16, 185, 129] },
          { key: 'average', label: 'Average', color: [245, 158, 11] },
          { key: 'bad', label: 'Bad', color: [239, 68, 68] },
        ];

        let x = 16;
        options.forEach((opt) => {
          const isSelected = normalized === opt.key;
          doc.setDrawColor(160);
          if (isSelected) {
            doc.setFillColor(opt.color[0], opt.color[1], opt.color[2]);
            doc.roundedRect(x, y - 4, 30, 8, 1.5, 1.5, 'FD');
            doc.setTextColor(255);
            doc.setFont(undefined, 'bold');
            doc.text(`${opt.label}`, x + 15, y + 1, { align: 'center' });
          } else {
            doc.setFillColor(255, 255, 255);
            doc.roundedRect(x, y - 4, 30, 8, 1.5, 1.5, 'FD');
            doc.setTextColor(90);
            doc.setFont(undefined, 'normal');
            doc.text(`${opt.label}`, x + 15, y + 1, { align: 'center' });
          }
          x += 34;
        });
        doc.setTextColor(0);
      };

      let isFirstPage = true;

      for (const [companyName, companyForms] of groupedByCompany.entries()) {
        const companyRecord = companies.find(
          (c) => String(c?.name || c?.Name || '').trim().toLowerCase() === companyName.toLowerCase()
        );
        const companyId = companyRecord?.companyId || companyRecord?.CompanyId;

        let companyDetail = null;
        if (companyId) {
          if (companyDetailCache.has(companyId)) {
            companyDetail = companyDetailCache.get(companyId);
          } else {
            try {
              const detailRes = await api.get(`/admin/companies/${companyId}/details`);
              companyDetail = detailRes.data;
              companyDetailCache.set(companyId, companyDetail);
            } catch {
              companyDetail = null;
            }
          }
        }

        const hiredStudents = companyDetail?.hiredStudents || companyDetail?.HiredStudents || [];
        const shortlistedStudents = companyDetail?.shortlistedStudents || companyDetail?.ShortlistedStudents || [];
        const studentsForForm = [
          ...shortlistedStudents.map((s) => ({ ...s, decision: 'Shortlisted' })),
          ...hiredStudents.map((s) => ({ ...s, decision: 'Hired' })),
        ];

        const interviewStats = companyDetail?.interviewStats || companyDetail?.InterviewStats || {};

        const sortedForms = [...companyForms].sort(
          (a, b) => new Date(a.submittedAt).getTime() - new Date(b.submittedAt).getTime()
        );

        for (const surveyForm of sortedForms) {
          if (!isFirstPage) doc.addPage();
          isFirstPage = false;

          const responses = surveyForm.responses || {};
          const submittedAt = surveyForm.submittedAt
            ? new Date(surveyForm.submittedAt).toLocaleString()
            : 'N/A';
          const meta = pickCompanyMeta(companyName);
          const interviewedCount = Number(interviewStats.totalInterviews ?? interviewStats.TotalInterviews ?? meta.interviewedCount ?? 0);
          const shortlistedCount = Number(interviewStats.shortlisted ?? interviewStats.Shortlisted ?? meta.shortlistedCount ?? 0);
          const hiredCount = Number(interviewStats.hired ?? interviewStats.Hired ?? meta.hiredCount ?? 0);

          if (logoDataUrl) {
            doc.addImage(logoDataUrl, 'PNG', 14, 8, 20, 20);
          }

          doc.setFontSize(12);
          doc.setTextColor(0);
          doc.setFont(undefined, 'bold');
          doc.text(`Job Fair/Open House (${jobFairLabel})`, pageWidth / 2, 14, { align: 'center' });
          doc.text('CDC CUI, Wah Campus (cdc@ciitwah.edu.pk)', pageWidth / 2, 20, { align: 'center' });

          doc.setFont(undefined, 'normal');
          doc.setFontSize(9);
          doc.text(`Submitted At: ${submittedAt}`, 40, 28);

          doc.setFont(undefined, 'bold');
          doc.text('Contact Details:', 14, 35);
          doc.setFont(undefined, 'normal');

          autoTable(doc, {
            startY: 38,
            head: [['Field', 'Value']],
            body: [
              ['Employer\'s Name', meta.employerName],
              ['Organization\'s Name', meta.organizationName],
              ['Email', meta.email],
              ['Contact No.', meta.contactNo],
            ],
            theme: 'grid',
            styles: { fontSize: 9, cellPadding: 2.5 },
            headStyles: { fillColor: [243, 244, 246], textColor: 40 },
          });

          const afterContactY = (doc.lastAutoTable?.finalY || 58) + 6;

          let sectionY = afterContactY;

          if (shortlistedCount > 0 || hiredCount > 0) {
            doc.setFont(undefined, 'bold');
            doc.text('List of students being shortlisted / hired:', 14, sectionY);
            doc.setFont(undefined, 'normal');

            autoTable(doc, {
              startY: sectionY + 2,
              head: [['Sr. #', 'Name of Students', 'Registration #', 'Email', 'Contact No.']],
              body: (studentsForForm.length > 0
                ? studentsForForm.slice(0, 12).map((student, idx) => [
                    String(idx + 1),
                    `${student.StudentName || student.studentName || ''}${student.decision ? ` (${student.decision})` : ''}`,
                    student.StudentRegistration || student.studentRegistration || '',
                    student.StudentEmail || student.studentEmail || '',
                    student.StudentPhone || student.studentPhone || '',
                  ])
                : Array.from({ length: 5 }).map((_, idx) => [String(idx + 1), '', '', '', ''])),
              theme: 'grid',
              styles: { fontSize: 8.5, cellPadding: 2.5 },
              headStyles: { fillColor: [243, 244, 246], textColor: 40 },
            });

            sectionY = (doc.lastAutoTable?.finalY || sectionY + 20) + 6;
            doc.setFont(undefined, 'bold');
            doc.text('Summary of Students Interviewed/shortlisted/hired:', 14, sectionY);
            doc.setFont(undefined, 'normal');
            doc.text(`Number of students interviewed:  ${interviewedCount}`, 14, sectionY + 6);
            doc.text(`Number of students shortlisted: ${shortlistedCount}`, 14, sectionY + 12);
            doc.text(`Number of students hired:       ${hiredCount}`, 14, sectionY + 18);

            sectionY += 28;
          }

          doc.setFont(undefined, 'bold');
          doc.text('Employer\'s Observation:', 14, sectionY);
          sectionY += 6;

          const renderObservation = (title, selected, comments) => {
            doc.setFont(undefined, 'normal');
            doc.text(title, 14, sectionY);
            sectionY += 6;
            drawOptionBadges(sectionY, selected);
            sectionY += 6;

            const trimmedComment = String(comments || '').trim();
            if (trimmedComment.length > 0) {
              doc.text('Comments to improve (if any):', 14, sectionY);
              sectionY += 5;

              autoTable(doc, {
                startY: sectionY,
                body: [[trimmedComment]],
                theme: 'grid',
                styles: { fontSize: 8.5, minCellHeight: 14, cellPadding: 2.5 },
                margin: { left: 14, right: 14 },
              });

              sectionY = (doc.lastAutoTable?.finalY || sectionY + 14) + 5;
            } else {
              sectionY += 3;
            }
          };

          renderObservation(
            'Overall Student\'s FYP quality was:',
            responses.FypQuality,
            responses.FypComments
          );

          renderObservation(
            'Overall arrangements in this Job fair/Open house was.',
            responses.ArrangementQuality,
            responses.ArrangementComments
          );

          renderObservation(
            'Refreshment and Lunch quality and arrangement was.',
            responses.LunchQuality,
            responses.LunchComments
          );

          doc.setFontSize(8);
          doc.setTextColor(110);
          doc.text('Generated by Job Fair Portal', pageWidth - 14, 288, { align: 'right' });
        }
      }

      doc.save(`CDC_Survey_Forms_All_Companies_${new Date().toISOString().split('T')[0]}.pdf`);
      toast.dismiss(loadingToastId);
      toast.success('CDC survey forms PDF downloaded');
    } catch (error) {
      toast.dismiss(loadingToastId);
      toast.error('Failed to generate CDC forms PDF');
    }
  };

  const downloadCompanyCDCForms = async (row) => {
    const companyName = String(row?.companyName || '').trim();
    if (!companyName) {
      toast.error('Invalid company selection');
      return;
    }

    const companyCdcSurveys = surveys
      .filter((s) => s.type === 'CDC')
      .filter((s) => {
        if (row?.companyId && s?.companyId) {
          return String(s.companyId) === String(row.companyId);
        }
        return String(s.companyName || '').trim().toLowerCase() === companyName.toLowerCase();
      });

    if (companyCdcSurveys.length === 0) {
      toast.error('No CDC survey response found for this company');
      return;
    }

    const loadingToastId = toast.loading(`Preparing CDC report for ${companyName}...`);

    try {
      const doc = new jsPDF();
      const pageWidth = doc.internal.pageSize.getWidth();
      const { jobFairLabel, logoDataUrl } = await getPdfBrandingAssets();

      const sortedForms = [...companyCdcSurveys].sort(
        (a, b) => new Date(a.submittedAt).getTime() - new Date(b.submittedAt).getTime()
      );

      const companyId = row?.companyId;
      let companyDetail = null;
      if (companyId) {
        try {
          const detailRes = await api.get(`/admin/companies/${companyId}/details`);
          companyDetail = detailRes.data;
        } catch {
          companyDetail = null;
        }
      }

      const hiredStudents = companyDetail?.hiredStudents || companyDetail?.HiredStudents || [];
      const shortlistedStudents = companyDetail?.shortlistedStudents || companyDetail?.ShortlistedStudents || [];
      const studentsForForm = [
        ...shortlistedStudents.map((s) => ({ ...s, decision: 'Shortlisted' })),
        ...hiredStudents.map((s) => ({ ...s, decision: 'Hired' })),
      ];
      const interviewStats = companyDetail?.interviewStats || companyDetail?.InterviewStats || {};

      const match = companies.find(
        (c) => String(c?.name || c?.Name || '').trim().toLowerCase() === companyName.toLowerCase()
      );

      const meta = {
        employerName: match?.focalPersonName || match?.FocalPersonName || '_________________',
        organizationName: companyName,
        email:
          match?.email ||
          match?.Email ||
          match?.contactEmail ||
          match?.ContactEmail ||
          match?.companyEmail ||
          match?.CompanyEmail ||
          '_________________',
        contactNo:
          match?.phone ||
          match?.Phone ||
          match?.contactNo ||
          match?.ContactNo ||
          match?.companyPhone ||
          match?.CompanyPhone ||
          '_________________',
      };

      const drawOptionBadges = (y, selected) => {
        const normalized = String(selected || '').trim().toLowerCase();
        const options = [
          { key: 'good', label: 'Good', color: [16, 185, 129] },
          { key: 'average', label: 'Average', color: [245, 158, 11] },
          { key: 'bad', label: 'Bad', color: [239, 68, 68] },
        ];

        let x = 16;
        options.forEach((opt) => {
          const isSelected = normalized === opt.key;
          doc.setDrawColor(160);
          if (isSelected) {
            doc.setFillColor(opt.color[0], opt.color[1], opt.color[2]);
            doc.roundedRect(x, y - 4, 30, 8, 1.5, 1.5, 'FD');
            doc.setTextColor(255);
            doc.setFont(undefined, 'bold');
            doc.text(`${opt.label}`, x + 15, y + 1, { align: 'center' });
          } else {
            doc.setFillColor(255, 255, 255);
            doc.roundedRect(x, y - 4, 30, 8, 1.5, 1.5, 'FD');
            doc.setTextColor(90);
            doc.setFont(undefined, 'normal');
            doc.text(`${opt.label}`, x + 15, y + 1, { align: 'center' });
          }
          x += 34;
        });
        doc.setTextColor(0);
      };

      for (let idx = 0; idx < sortedForms.length; idx++) {
        if (idx > 0) doc.addPage();

        const surveyForm = sortedForms[idx];
        const responses = surveyForm.responses || {};
        const submittedAt = surveyForm.submittedAt
          ? new Date(surveyForm.submittedAt).toLocaleString()
          : 'N/A';

        const interviewedCount = Number(interviewStats.totalInterviews ?? interviewStats.TotalInterviews ?? 0);
        const shortlistedCount = Number(interviewStats.shortlisted ?? interviewStats.Shortlisted ?? 0);
        const hiredCount = Number(interviewStats.hired ?? interviewStats.Hired ?? 0);

        if (logoDataUrl) {
          doc.addImage(logoDataUrl, 'PNG', 14, 8, 20, 20);
        }

        doc.setFontSize(12);
        doc.setTextColor(0);
        doc.setFont(undefined, 'bold');
        doc.text(`Job Fair/Open House (${jobFairLabel})`, pageWidth / 2, 14, { align: 'center' });
        doc.text('CDC CUI, Wah Campus (cdc@ciitwah.edu.pk)', pageWidth / 2, 20, { align: 'center' });

        doc.setFont(undefined, 'normal');
        doc.setFontSize(9);
        doc.text(`Submitted At: ${submittedAt}`, 40, 28);

        doc.setFont(undefined, 'bold');
        doc.text('Contact Details:', 14, 35);
        doc.setFont(undefined, 'normal');

        autoTable(doc, {
          startY: 38,
          head: [['Field', 'Value']],
          body: [
            ['Employer\'s Name', meta.employerName],
            ['Organization\'s Name', meta.organizationName],
            ['Email', meta.email],
            ['Contact No.', meta.contactNo],
          ],
          theme: 'grid',
          styles: { fontSize: 9, cellPadding: 2.5 },
          headStyles: { fillColor: [243, 244, 246], textColor: 40 },
        });

        let sectionY = (doc.lastAutoTable?.finalY || 58) + 6;
        if (shortlistedCount > 0 || hiredCount > 0) {
          doc.setFont(undefined, 'bold');
          doc.text('List of students being shortlisted / hired:', 14, sectionY);
          doc.setFont(undefined, 'normal');

          autoTable(doc, {
            startY: sectionY + 2,
            head: [['Sr. #', 'Name of Students', 'Registration #', 'Email', 'Contact No.']],
            body: (studentsForForm.length > 0
              ? studentsForForm.slice(0, 12).map((student, i) => [
                  String(i + 1),
                  `${student.StudentName || student.studentName || ''}${student.decision ? ` (${student.decision})` : ''}`,
                  student.StudentRegistration || student.studentRegistration || '',
                  student.StudentEmail || student.studentEmail || '',
                  student.StudentPhone || student.studentPhone || '',
                ])
              : Array.from({ length: 5 }).map((_, i) => [String(i + 1), '', '', '', ''])),
            theme: 'grid',
            styles: { fontSize: 8.5, cellPadding: 2.5 },
            headStyles: { fillColor: [243, 244, 246], textColor: 40 },
          });

          sectionY = (doc.lastAutoTable?.finalY || sectionY + 20) + 6;
          doc.setFont(undefined, 'bold');
          doc.text('Summary of Students Interviewed/shortlisted/hired:', 14, sectionY);
          doc.setFont(undefined, 'normal');
          doc.text(`Number of students interviewed:  ${interviewedCount}`, 14, sectionY + 6);
          doc.text(`Number of students shortlisted: ${shortlistedCount}`, 14, sectionY + 12);
          doc.text(`Number of students hired:       ${hiredCount}`, 14, sectionY + 18);
          sectionY += 28;
        }

        doc.setFont(undefined, 'bold');
        doc.text('Employer\'s Observation:', 14, sectionY);
        sectionY += 6;

        const renderObs = (title, selected, comments) => {
          doc.setFont(undefined, 'normal');
          doc.text(title, 14, sectionY);
          sectionY += 6;
          drawOptionBadges(sectionY, selected);
          sectionY += 6;

          const trimmedComment = String(comments || '').trim();
          if (trimmedComment.length > 0) {
            doc.text('Comments to improve (if any):', 14, sectionY);
            sectionY += 5;
            autoTable(doc, {
              startY: sectionY,
              body: [[trimmedComment]],
              theme: 'grid',
              styles: { fontSize: 8.5, minCellHeight: 14, cellPadding: 2.5 },
              margin: { left: 14, right: 14 },
            });
            sectionY = (doc.lastAutoTable?.finalY || sectionY + 14) + 5;
          } else {
            sectionY += 3;
          }
        };

        renderObs('Overall Student\'s FYP quality was:', responses.FypQuality, responses.FypComments);
        renderObs('Overall arrangements in this Job fair/Open house was.', responses.ArrangementQuality, responses.ArrangementComments);
        renderObs('Refreshment and Lunch quality and arrangement was.', responses.LunchQuality, responses.LunchComments);
      }

      doc.save(`CDC_Survey_Forms_${companyName.replace(/\s+/g, '_')}_${new Date().toISOString().split('T')[0]}.pdf`);
      toast.dismiss(loadingToastId);
      toast.success(`CDC report downloaded for ${companyName}`);
    } catch {
      toast.dismiss(loadingToastId);
      toast.error('Failed to generate company CDC report');
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

  const pieLabelFormatter = ({ name, value, percent }) =>
    `${name} ${value} (${((percent || 0) * 100).toFixed(0)}%)`;

  const piePercentOnlyLabel = ({ percent }) => `${((percent || 0) * 100).toFixed(0)}%`;

  const getCountPct = (value, total) => {
    const pct = total > 0 ? ((value / total) * 100).toFixed(0) : '0';
    return `${value} (${pct}%)`;
  };

  const getCDCLegendPayload = (field) => {
    const stats = getCDCStats(field);
    const total = stats.reduce((sum, item) => sum + item.value, 0);

    return stats.map((item, index) => ({
      value: `${item.name} ${getCountPct(item.value, total)}`,
      type: 'square',
      color: CDC_COLORS[index],
      id: `${field}-${item.name}`,
    }));
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
              onClick={downloadAllCDCForms}
              className="px-4 py-2 bg-white border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 text-sm font-medium flex items-center transition shadow-sm"
            >
              <Download size={16} className="mr-2 text-purple-600" /> CDC Forms PDF
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
            onClick={() => setActiveView('pending')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
              activeView === 'pending'
                ? 'bg-indigo-600 text-white shadow-md'
                : 'text-gray-600 hover:bg-gray-100'
            }`}
          >
            <Building2 size={16} className="inline mr-2" /> Pending Surveys
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
      {(activeView === 'list' || activeView === 'pending') && (
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

          {activeView === 'list' && (
            <select
              className="border border-gray-200 rounded-lg px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500 bg-white cursor-pointer hover:border-gray-300 transition-colors"
              value={filters.surveyType}
              onChange={(e) => setFilters({ ...filters, surveyType: e.target.value })}
            >
              <option value="all">All Types</option>
              <option value="CDC">CDC Only</option>
              <option value="Department">Department Only</option>
            </select>
          )}

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
                <th className="px-6 py-4 text-center text-xs font-bold text-gray-700 uppercase tracking-wider">CDC</th>
                <th className="px-6 py-4 text-center text-xs font-bold text-gray-700 uppercase tracking-wider">Department</th>
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
              ) : companyResponseRows.length > 0 ? (
                companyResponseRows.map((row) => (
                  <tr key={`${row.companyId || row.companyName}`} className="bg-white hover:bg-gray-50 transition-colors group">
                    <td className="px-6 py-4">
                      <p className="font-semibold text-gray-900 group-hover:text-indigo-600 transition-colors">{row.companyName}</p>
                    </td>
                    <td className="px-6 py-4 text-center">
                      <span className={`inline-flex w-6 h-6 items-center justify-center rounded-full text-xs font-bold ${row.cdc ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-100 text-gray-400'}`}>
                        {row.cdc ? '✓' : '-'}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-center">
                      <span className={`inline-flex w-6 h-6 items-center justify-center rounded-full text-xs font-bold ${row.department ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-100 text-gray-400'}`}>
                        {row.department ? '✓' : '-'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2 text-sm text-gray-600">
                        <Calendar size={14} className="text-gray-400" />
                        {new Date(row.latestSubmittedAt).toLocaleDateString()}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => downloadIndividualCompanyReport(row)}
                          className="px-3 py-1.5 text-xs font-medium text-blue-700 bg-blue-50 hover:bg-blue-100 rounded-lg transition-colors flex items-center gap-1"
                        >
                          <Download size={14} /> Report PDF
                        </button>
                        <button
                          onClick={() => downloadCompanyCDCForms(row)}
                          className="px-3 py-1.5 text-xs font-medium text-purple-700 bg-purple-50 hover:bg-purple-100 rounded-lg transition-colors flex items-center gap-1"
                        >
                          <Download size={14} /> CDC PDF
                        </button>
                        <button
                          onClick={() => handleViewDetails(row)}
                          className="px-3 py-1.5 text-xs font-medium text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-lg transition-colors flex items-center gap-1"
                        >
                          <Eye size={14} /> Show
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="5" className="px-6 py-16 text-center">
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

      {/* VIEW: Pending Survey Submissions */}
      {activeView === 'pending' && (
      <div className="space-y-4">
        <div className="flex items-center justify-between bg-white p-4 rounded-xl border border-gray-200 shadow-sm">
          <div>
            <h3 className="text-base font-bold text-gray-900">Companies with Pending Survey Submission</h3>
            <p className="text-sm text-gray-500">Showing companies missing CDC and/or Department survey response.</p>
          </div>
          <button
            onClick={remindAllPendingCompanies}
            className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 text-sm font-medium flex items-center transition shadow-sm"
          >
            <Bell size={16} className="mr-2" /> Remind All
          </button>
        </div>

        <div className="bg-white rounded-xl border shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Company</th>
                  <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Email</th>
                  <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Room No</th>
                  <th className="px-6 py-4 text-center text-xs font-bold text-gray-700 uppercase tracking-wider">CDC</th>
                  <th className="px-6 py-4 text-center text-xs font-bold text-gray-700 uppercase tracking-wider">Department</th>
                  <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Missing</th>
                  <th className="px-6 py-4 text-right text-xs font-bold text-gray-700 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {loading ? (
                  [...Array(5)].map((_, i) => (
                    <tr key={i} className="animate-pulse bg-white hover:bg-gray-50">
                      <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-40"></div></td>
                      <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-40"></div></td>
                      <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-20"></div></td>
                      <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-8 mx-auto"></div></td>
                      <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-8 mx-auto"></div></td>
                      <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-28"></div></td>
                      <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-40 ml-auto"></div></td>
                    </tr>
                  ))
                ) : pendingCompanies.length > 0 ? (
                  pendingCompanies.map((company) => (
                    <tr key={`pending-${company.companyId || company.companyName}`} className="bg-white hover:bg-gray-50 transition-colors">
                      <td className="px-6 py-4 font-semibold text-gray-900">{company.companyName}</td>
                      <td className="px-6 py-4 text-sm text-gray-600">{company.email}</td>
                      <td className="px-6 py-4 text-sm text-gray-600">{company.room}</td>
                      <td className="px-6 py-4 text-center">
                        <span className={`inline-flex px-2 py-1 rounded-full text-xs font-bold ${company.hasCDC ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700'}`}>
                          {company.hasCDC ? 'Submitted' : 'Pending'}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-center">
                        <span className={`inline-flex px-2 py-1 rounded-full text-xs font-bold ${company.hasDepartment ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700'}`}>
                          {company.hasDepartment ? 'Submitted' : 'Pending'}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm text-amber-700 font-medium">{company.missing.join(', ')}</td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => remindPendingCompany(company)}
                            className="px-3 py-1.5 text-xs font-medium text-indigo-700 bg-indigo-50 hover:bg-indigo-100 rounded-lg transition-colors flex items-center gap-1"
                          >
                            <Bell size={14} /> Remind
                          </button>
                          <button
                            onClick={() => remindPendingCompany(company)}
                            className="px-3 py-1.5 text-xs font-medium text-blue-700 bg-blue-50 hover:bg-blue-100 rounded-lg transition-colors flex items-center gap-1"
                          >
                            <Mail size={14} /> Notify
                          </button>
                          <button
                            onClick={() => downloadIndividualCompanyReport(company)}
                            className="px-3 py-1.5 text-xs font-medium text-purple-700 bg-purple-50 hover:bg-purple-100 rounded-lg transition-colors flex items-center gap-1"
                          >
                            <Download size={14} /> Report
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan="7" className="px-6 py-16 text-center">
                      <Building2 size={44} className="text-gray-300 mb-4 mx-auto" />
                      <p className="text-lg font-medium text-gray-600">No pending companies</p>
                      <p className="text-sm text-gray-400">All companies have submitted CDC and Department surveys.</p>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
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
                  <Legend payload={getCDCLegendPayload('FypQuality')} wrapperStyle={{ fontSize: 11 }} />
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
                  <Legend payload={getCDCLegendPayload('ArrangementQuality')} wrapperStyle={{ fontSize: 11 }} />
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
                  <Legend payload={getCDCLegendPayload('LunchQuality')} wrapperStyle={{ fontSize: 11 }} />
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
      <div className="fixed -left-[99999px] top-0 w-[1100px] bg-white p-6 pointer-events-none" aria-hidden="true">
        <div ref={cdcExportRef} className="space-y-6">
          <h2 className="text-xl font-bold text-gray-900">CDC Feedback</h2>
          <div className="grid grid-cols-3 gap-6">
            <div className="bg-white p-6 rounded-xl border border-gray-200">
              <div className="font-bold mb-3">FYP Quality</div>
              <div className="h-44">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={getCDCStats('FypQuality')} innerRadius={30} outerRadius={52} paddingAngle={5} dataKey="value" label={piePercentOnlyLabel} labelLine={false}>
                      {getCDCStats('FypQuality').map((entry, index) => (
                        <Cell key={`export-cdc-fyp-${index}`} fill={CDC_COLORS[index]} />
                      ))}
                    </Pie>
                    <Tooltip />
                    <Legend payload={getCDCLegendPayload('FypQuality')} wrapperStyle={{ fontSize: 9 }} />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200">
              <div className="font-bold mb-3">Arrangement Quality</div>
              <div className="h-44">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={getCDCStats('ArrangementQuality')} innerRadius={30} outerRadius={52} paddingAngle={5} dataKey="value" label={piePercentOnlyLabel} labelLine={false}>
                      {getCDCStats('ArrangementQuality').map((entry, index) => (
                        <Cell key={`export-cdc-arr-${index}`} fill={CDC_COLORS[index]} />
                      ))}
                    </Pie>
                    <Tooltip />
                    <Legend payload={getCDCLegendPayload('ArrangementQuality')} wrapperStyle={{ fontSize: 9 }} />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl border border-gray-200">
              <div className="font-bold mb-3">Lunch Quality</div>
              <div className="h-44">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={getCDCStats('LunchQuality')} innerRadius={30} outerRadius={52} paddingAngle={5} dataKey="value" label={piePercentOnlyLabel} labelLine={false}>
                      {getCDCStats('LunchQuality').map((entry, index) => (
                        <Cell key={`export-cdc-lunch-${index}`} fill={CDC_COLORS[index]} />
                      ))}
                    </Pie>
                    <Tooltip />
                    <Legend payload={getCDCLegendPayload('LunchQuality')} wrapperStyle={{ fontSize: 9 }} />
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
