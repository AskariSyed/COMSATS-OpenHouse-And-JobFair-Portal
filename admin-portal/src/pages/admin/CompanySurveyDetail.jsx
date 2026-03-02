import React, { useEffect, useMemo, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, Download, Building2, Mail, Phone, Users, ClipboardList, UserCheck, Award, User, MapPin } from 'lucide-react';
import api from '../../lib/api';
import { toast } from 'react-hot-toast';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

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

const CompanySurveyDetail = () => {
  const { companyId } = useParams();
  const navigate = useNavigate();

  const [loading, setLoading] = useState(true);
  const [exporting, setExporting] = useState(false);
  const [company, setCompany] = useState(null);
  const [surveys, setSurveys] = useState([]);

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const [companyRes, surveyRes] = await Promise.all([
          api.get(`/admin/companies/${companyId}/details`),
          api.get('/admin/surveys')
        ]);

        const companyData = companyRes.data;
        const normalizedSurveys = (surveyRes.data || []).map((s) => ({
          ...s,
          responses: normalizeResponses(s.responses)
        }));

        const companySurveys = normalizedSurveys.filter((s) => {
          const sameCompanyId = String(s.companyId || '') === String(companyId);
          const sameName = (s.companyName || '').trim().toLowerCase() === (companyData?.name || '').trim().toLowerCase();
          return sameCompanyId || sameName;
        });

        setCompany(companyData);
        setSurveys(companySurveys);
      } catch {
        toast.error('Failed to load company survey details');
        navigate('/admin/surveys');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [companyId, navigate]);

  const cdcSurveys = useMemo(() => surveys.filter((s) => s.type === 'CDC'), [surveys]);
  const deptSurveys = useMemo(() => surveys.filter((s) => s.type === 'Department'), [surveys]);

  const buildQuestionRows = (surveyType, surveyItems) => {
    const labels = SURVEY_QUESTIONS[surveyType] || {};
    return surveyItems.flatMap((surveyItem) => {
      const responses = surveyItem.responses || {};

      return Object.entries(labels).map(([key, label]) => {
        const fallbackKey = key.charAt(0).toLowerCase() + key.slice(1);
        const value = responses[key] ?? responses[fallbackKey] ?? 'N/A';

        return [
          new Date(surveyItem.submittedAt).toLocaleString(),
          label,
          String(value)
        ];
      });
    });
  };

  const downloadIndividualReport = () => {
    if (!company) return;

    setExporting(true);
    try {
      const doc = new jsPDF();
      doc.setFontSize(18);
      doc.setTextColor(37, 99, 235);
      doc.text('Company Survey & Profile Report', 14, 18);

      doc.setFontSize(11);
      doc.setTextColor(60);
      doc.text(`Generated: ${new Date().toLocaleString()}`, 14, 25);

      autoTable(doc, {
        startY: 32,
        head: [['Field', 'Value']],
        body: [
          ['Company Name', company.name || 'N/A'],
          ['Contact', `${company.contactDetails?.email || 'N/A'} | ${company.contactDetails?.phone || 'N/A'}`],
          ['Focal Person', `${company.focalPerson?.name || 'N/A'} | ${company.focalPerson?.email || 'N/A'} | ${company.focalPerson?.phone || 'N/A'}`],
          ['Room / Reps', `${company.room?.roomName || 'Not Allocated'} | Reps: ${company.repsCount ?? 0}`],
          ['Interview Summary', `Interviewed: ${company.interviewStats?.totalInterviews ?? 0} | Called: ${company.scheduledInterviews?.length ?? 0} | Hired: ${company.interviewStats?.hired ?? 0} | Shortlisted: ${company.interviewStats?.shortlisted ?? 0}`],
        ],
        theme: 'grid',
        headStyles: { fillColor: [37, 99, 235] },
        styles: { fontSize: 8, cellPadding: 2.5 },
        columnStyles: {
          0: { cellWidth: 42 },
          1: { cellWidth: 145 }
        }
      });

      const cdcRows = buildQuestionRows('CDC', cdcSurveys);
      autoTable(doc, {
        startY: (doc.lastAutoTable?.finalY || 40) + 10,
        head: [['CDC Submitted At', 'Question', 'Response']],
        body: cdcRows.length ? cdcRows : [['-', 'No CDC response submitted', '-']],
        theme: 'striped',
        headStyles: { fillColor: [79, 70, 229] },
        styles: { fontSize: 8 }
      });

      const deptRows = buildQuestionRows('Department', deptSurveys);
      autoTable(doc, {
        startY: (doc.lastAutoTable?.finalY || 40) + 10,
        head: [['Department Submitted At', 'Question', 'Response']],
        body: deptRows.length ? deptRows : [['-', 'No Department response submitted', '-']],
        theme: 'striped',
        headStyles: { fillColor: [245, 158, 11] },
        styles: { fontSize: 8 }
      });

      const safeName = (company.name || 'company').replace(/[^a-zA-Z0-9-_ ]/g, '').trim().replace(/\s+/g, '_');
      doc.save(`Company_Survey_Profile_${safeName}_${new Date().toISOString().split('T')[0]}.pdf`);
      toast.success('Individual report downloaded');
    } catch {
      toast.error('Failed to generate individual report');
    } finally {
      setExporting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="w-10 h-10 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!company) {
    return null;
  }

  return (
    <div className="space-y-6 animate-fade-in pb-12">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <button
          onClick={() => navigate('/admin/surveys')}
          className="inline-flex items-center gap-2 text-gray-600 hover:text-indigo-600 font-medium"
        >
          <ArrowLeft size={18} /> Back to Surveys
        </button>

        <button
          onClick={downloadIndividualReport}
          disabled={exporting}
          className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 inline-flex items-center gap-2 text-sm font-medium"
        >
          <Download size={16} /> {exporting ? 'Preparing...' : 'Download Company Report'}
        </button>
      </div>

      <div className="bg-white border border-gray-200 rounded-2xl p-6 shadow-sm">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
            <Building2 size={20} />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">{company.name}</h1>
            <p className="text-sm text-gray-500">Complete company profile and survey responses</p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-gray-50 border border-gray-100 rounded-xl p-4">
            <p className="text-xs text-gray-500">Email</p>
            <p className="font-semibold text-gray-900 mt-1 break-words inline-flex items-center gap-2"><Mail size={14} /> {company.contactDetails?.email || 'N/A'}</p>
          </div>
          <div className="bg-gray-50 border border-gray-100 rounded-xl p-4">
            <p className="text-xs text-gray-500">Phone</p>
            <p className="font-semibold text-gray-900 mt-1 inline-flex items-center gap-2"><Phone size={14} /> {company.contactDetails?.phone || 'N/A'}</p>
          </div>
          <div className="bg-gray-50 border border-gray-100 rounded-xl p-4">
            <p className="text-xs text-gray-500">Focal Person</p>
            <p className="font-semibold text-gray-900 mt-1 inline-flex items-center gap-2"><User size={14} /> {company.focalPerson?.name || 'N/A'}</p>
            <p className="text-xs text-gray-500 mt-1 break-words">{company.focalPerson?.email || 'N/A'} • {company.focalPerson?.phone || 'N/A'}</p>
          </div>
          <div className="bg-gray-50 border border-gray-100 rounded-xl p-4">
            <p className="text-xs text-gray-500">Allocated Room</p>
            <p className="font-semibold text-gray-900 mt-1 inline-flex items-center gap-2"><MapPin size={14} /> {company.room?.roomName || 'Not Allocated'}</p>
          </div>
          <div className="bg-gray-50 border border-gray-100 rounded-xl p-4">
            <p className="text-xs text-gray-500">Representatives</p>
            <p className="font-semibold text-gray-900 mt-1 inline-flex items-center gap-2"><Users size={14} /> {company.repsCount ?? 0}</p>
          </div>
          <div className="bg-gray-50 border border-gray-100 rounded-xl p-4">
            <p className="text-xs text-gray-500">Students Interviewed</p>
            <p className="font-semibold text-gray-900 mt-1 inline-flex items-center gap-2"><ClipboardList size={14} /> {company.interviewStats?.totalInterviews ?? 0}</p>
          </div>
          <div className="bg-gray-50 border border-gray-100 rounded-xl p-4">
            <p className="text-xs text-gray-500">Students Called</p>
            <p className="font-semibold text-gray-900 mt-1 inline-flex items-center gap-2"><UserCheck size={14} /> {company.scheduledInterviews?.length ?? 0}</p>
          </div>
          <div className="bg-gray-50 border border-gray-100 rounded-xl p-4">
            <p className="text-xs text-gray-500">Students Hired</p>
            <p className="font-semibold text-green-700 mt-1 inline-flex items-center gap-2"><Award size={14} /> {company.interviewStats?.hired ?? 0}</p>
          </div>
          <div className="bg-gray-50 border border-gray-100 rounded-xl p-4">
            <p className="text-xs text-gray-500">Students Shortlisted</p>
            <p className="font-semibold text-indigo-700 mt-1 inline-flex items-center gap-2"><Award size={14} /> {company.interviewStats?.shortlisted ?? 0}</p>
          </div>
        </div>
      </div>

      <div className="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-100 bg-indigo-50">
          <h2 className="text-lg font-bold text-indigo-900">CDC Survey Responses</h2>
        </div>
        <div className="p-6 space-y-6">
          {cdcSurveys.length === 0 ? (
            <p className="text-sm text-gray-500">No CDC survey submitted by this company.</p>
          ) : cdcSurveys.map((survey) => (
            <div key={survey.surveyId} className="border border-gray-200 rounded-xl overflow-hidden">
              <div className="px-4 py-3 bg-gray-50 border-b text-sm text-gray-600">
                Submitted: {new Date(survey.submittedAt).toLocaleString()}
              </div>
              <div className="divide-y">
                {Object.entries(SURVEY_QUESTIONS.CDC).map(([key, label]) => (
                  <div key={`${survey.surveyId}-${key}`} className="p-4 grid grid-cols-1 md:grid-cols-3 gap-2">
                    <p className="text-sm font-semibold text-gray-800 md:col-span-1">{label}</p>
                    <p className="text-sm text-gray-700 md:col-span-2">{String(survey.responses?.[key] ?? 'N/A')}</p>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-100 bg-amber-50">
          <h2 className="text-lg font-bold text-amber-900">Department Survey Responses</h2>
        </div>
        <div className="p-6 space-y-6">
          {deptSurveys.length === 0 ? (
            <p className="text-sm text-gray-500">No Department survey submitted by this company.</p>
          ) : deptSurveys.map((survey) => (
            <div key={survey.surveyId} className="border border-gray-200 rounded-xl overflow-hidden">
              <div className="px-4 py-3 bg-gray-50 border-b text-sm text-gray-600">
                Submitted: {new Date(survey.submittedAt).toLocaleString()}
              </div>
              <div className="divide-y">
                {Object.entries(SURVEY_QUESTIONS.Department).map(([key, label]) => (
                  <div key={`${survey.surveyId}-${key}`} className="p-4 grid grid-cols-1 md:grid-cols-3 gap-2">
                    <p className="text-sm font-semibold text-gray-800 md:col-span-1">{label}</p>
                    <p className="text-sm text-gray-700 md:col-span-2">{String(survey.responses?.[key] ?? 'N/A')}</p>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default CompanySurveyDetail;
