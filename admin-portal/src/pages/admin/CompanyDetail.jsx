/* eslint-disable no-unused-vars */
import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import { 
  ArrowLeft, Building2, MapPin, Mail, Phone, Globe, User, 
  Briefcase, CheckCircle, XCircle, Clock, Calendar, 
  Users, Layout, Link as LinkIcon, FileText, Eye, Edit2, Save, X
} from 'lucide-react';
import api, { getFileUrl } from '../../lib/api';
import { toast } from 'react-hot-toast';
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import LogoWithoutBg from '../../assets/LogoWithoutBg.png';

const getApiErrorMessage = (error, fallback) => {
  const payload = error?.response?.data;
  if (typeof payload === 'string' && payload.trim()) return payload;
  if (payload?.message) return payload.message;
  if (payload?.Message) return payload.Message;
  if (error?.message) return error.message;
  return fallback;
};

const isCapacityWarning = (error) => {
  const payload = error?.response?.data;
  const message = getApiErrorMessage(error, '');
  return payload?.code === 'CAPACITY_WARNING' || message.toLowerCase().includes('capacity warning');
};

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
    PEO1_Q1: 'PEO-1 Q1: Students possess adequate technical knowledge to perform in a professional computing environment.',
    PEO1_Q2: 'PEO-1 Q2: Students can analyze/investigate computing problems.',
    PEO1_Q3: 'PEO-1 Q3: Students can design and implement solutions to complex computing problems.',
    PEO2_Q1: 'PEO-2 Q1: Students have the desire to learn and adapt to new technology trends.',
    PEO2_Q2: 'PEO-2 Q2: Students can use acquired knowledge to promote entrepreneurship.',
    PEO3_Q1: 'PEO-3 Q1: Students are aware of ethical and moral concerns in computing.',
    PEO3_Q2: 'PEO-3 Q2: Students have effective oral and written communication skills.',
    PEO4_Q1: 'PEO-4 Q1: Students are trained to contribute to society.',
    PEO4_Q2: 'PEO-4 Q2: Students can use skills for economic growth of the country.',
    PEO4_Q3: 'PEO-4 Q3: Students can capitalize knowledge to support innovation.',
    TechnologiesSuggestion: 'Technologies/Skills Suggestion',
    GeneralFeedback: 'General Feedback',
    ImprovementSuggestions: 'Improvement Suggestions',
  }
};

const getResponseValue = (responses, key) => {
  if (!responses || typeof responses !== 'object') return '';

  // Direct hit first
  if (responses[key] !== undefined && responses[key] !== null) {
    return responses[key];
  }

  // Case-insensitive + format-insensitive fallback (handles keys like peO1_Q1 vs PEO1_Q1)
  const normalize = (value) =>
    String(value || '')
      .replace(/[^a-zA-Z0-9]/g, '')
      .toLowerCase();

  const target = normalize(key);
  const matchedEntry = Object.entries(responses).find(([responseKey]) => normalize(responseKey) === target);

  if (!matchedEntry) return '';
  return matchedEntry[1] ?? '';
};

const getSurveyQuestionAnswerRows = (survey) => {
  const type = String(survey?.type || survey?.Type || '');
  const responseObj = survey?.responses || survey?.Responses || {};
  const questionMap = SURVEY_QUESTIONS[type] || {};

  return Object.entries(questionMap).map(([key, question]) => ({
    question,
    answer: String(getResponseValue(responseObj, key) || 'N/A')
  }));
};

// ----------------------------------------------------------------------
// Modal: Assign Room
// ----------------------------------------------------------------------
const AssignRoomModal = ({ companyId, companyName, onClose, onSuccess }) => {
  const [rooms, setRooms] = useState([]);
  const [selectedRoomId, setSelectedRoomId] = useState('');
  const [isTentative, setIsTentative] = useState(false); // New State
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const fetchRooms = async () => {
      try {
        const res = await api.get('/admin/rooms?status=0'); // Fetch vacant rooms
        setRooms(res.data.filter(r => r.status === 0));
      } catch (error) {
        toast.error("Failed to load rooms");
      }
    };
    fetchRooms();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!selectedRoomId) return;
    
    setLoading(true);
    try {
      if (isTentative) {
        await api.put(`/admin/rooms/tentatively-assign?companyId=${companyId}&roomId=${selectedRoomId}`);
        toast.success(`Room tentatively assigned to ${companyName}`);
      } else {
        await api.put(`/admin/rooms/assign-company?companyId=${companyId}&roomId=${selectedRoomId}`);
        toast.success(`Room assigned to ${companyName}`);
      }
      onSuccess();
      onClose();
    } catch (error) {
      const errorMessage = getApiErrorMessage(error, "Failed to assign room");
      if (isCapacityWarning(error)) {
        const confirmHardAllot = window.confirm(`${errorMessage}\n\nDo you want to hard allot this room anyway?`);
        if (confirmHardAllot) {
          try {
            if (isTentative) {
              await api.put(`/admin/rooms/tentatively-assign?companyId=${companyId}&roomId=${selectedRoomId}&force=true`);
              toast.success(`Room tentatively assigned to ${companyName} (hard override)`);
            } else {
              await api.put(`/admin/rooms/assign-company?companyId=${companyId}&roomId=${selectedRoomId}&force=true`);
              toast.success(`Room assigned to ${companyName} (hard override)`);
            }
            onSuccess();
            onClose();
            return;
          } catch (forceError) {
            toast.error(getApiErrorMessage(forceError, "Failed to hard allot room"));
            return;
          }
        }
      }
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden animate-fade-in">
        <div className="px-6 py-4 border-b flex justify-between items-center bg-gray-50">
          <h3 className="font-bold text-gray-800">Assign Room to {companyName}</h3>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
            <XCircle size={20} />
          </button>
        </div>
        
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Select Room</label>
            <select 
              className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-indigo-500 focus:outline-none bg-white"
              value={selectedRoomId}
              onChange={(e) => setSelectedRoomId(e.target.value)}
              required
            >
              <option value="">Select a vacant room...</option>
              {rooms.map(room => (
                <option key={room.roomId} value={room.roomId}>
                  {room.roomName} (Capacity: {room.capacity})
                </option>
              ))}
            </select>
          </div>

          <div className="flex items-center gap-2">
            <input 
              type="checkbox" 
              id="tentative" 
              className="w-4 h-4 text-indigo-600 rounded border-gray-300 focus:ring-indigo-500"
              checked={isTentative}
              onChange={(e) => setIsTentative(e.target.checked)}
            />
            <label htmlFor="tentative" className="text-sm text-gray-700 select-none">
              Tentative Assignment (Pending Confirmation)
            </label>
          </div>

          <div className="pt-2 flex justify-end gap-3">
            <button 
              type="button" 
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded-lg"
            >
              Cancel
            </button>
            <button 
              type="submit" 
              disabled={loading || !selectedRoomId}
              className={`px-4 py-2 text-sm font-medium text-white rounded-lg disabled:opacity-50 ${isTentative ? 'bg-amber-500 hover:bg-amber-600' : 'bg-indigo-600 hover:bg-indigo-700'}`}
            >
              {loading ? 'Assigning...' : isTentative ? 'Assign Tentatively' : 'Assign Room'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

const CompanyDetail = () => {
  const { companyId } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('overview'); // overview | pipeline | results | surveys
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [surveysData, setSurveysData] = useState(null);
  const [selectedSurvey, setSelectedSurvey] = useState(null);
  const [isEditingProfile, setIsEditingProfile] = useState(false);
  const [profileSaving, setProfileSaving] = useState(false);
  const [profileFormData, setProfileFormData] = useState({
    name: '',
    industry: '',
    description: '',
    website: '',
    address: '',
    companyEmail: '',
    companyPhone: '',
    focalPersonName: '',
    focalPersonEmail: '',
    focalPersonPhone: '',
    repsCount: '',
    interviewDurationMinutes: ''
  });

  const handleBack = () => {
    const fromAnalytics = location?.state?.fromAnalytics;
    if (fromAnalytics?.jobFairId) {
      navigate('/admin/analytics', { state: fromAnalytics });
      return;
    }
    navigate(-1);
  };

  const fetchDetails = async () => {
    try {
      // Matches AdminController [HttpGet("companies/{companyId}/details")]
      const res = await api.get(`/admin/companies/${companyId}/details`);
      setData(res.data);
      const contact = res.data.contactDetails || res.data.ContactDetails || {};
      const focal = res.data.focalPerson || res.data.FocalPerson || {};
      setProfileFormData({
        name: res.data.name || '',
        industry: res.data.industry || '',
        description: res.data.description || '',
        website: res.data.website || '',
        address: res.data.address || '',
        companyEmail: contact.email || contact.Email || '',
        companyPhone: contact.phone || contact.Phone || '',
        focalPersonName: focal.name || focal.Name || '',
        focalPersonEmail: focal.email || focal.Email || '',
        focalPersonPhone: focal.phone || focal.Phone || '',
        repsCount: res.data.repsCount ?? '',
        interviewDurationMinutes: res.data.interviewDurationMinutes ?? ''
      });

      const editMode = new URLSearchParams(location.search).get('edit');
      if (editMode === 'profile') {
        setIsEditingProfile(true);
      }
    } catch (err) {
      toast.error("Failed to load company details");
      navigate('/admin/companies');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDetails();
  }, [companyId, navigate, location.search]);

  const handleSaveCompanyProfile = async () => {
    try {
      setProfileSaving(true);
      const repsCount = Number(profileFormData.repsCount);
      const interviewDurationMinutes = Number(profileFormData.interviewDurationMinutes);

      await api.put(`/admin/companies/${companyId}/profile`, {
        name: profileFormData.name,
        industry: profileFormData.industry,
        description: profileFormData.description,
        website: profileFormData.website,
        address: profileFormData.address,
        companyEmail: profileFormData.companyEmail,
        companyPhone: profileFormData.companyPhone,
        focalPersonName: profileFormData.focalPersonName,
        focalPersonEmail: profileFormData.focalPersonEmail,
        focalPersonPhone: profileFormData.focalPersonPhone,
        repsCount: Number.isFinite(repsCount) && repsCount > 0 ? repsCount : undefined,
        interviewDurationMinutes: Number.isFinite(interviewDurationMinutes) && interviewDurationMinutes > 0 ? interviewDurationMinutes : undefined,
      });

      toast.success('Company profile updated successfully');
      setIsEditingProfile(false);
      await fetchDetails();
    } catch (error) {
      toast.error(getApiErrorMessage(error, 'Failed to update company profile'));
    } finally {
      setProfileSaving(false);
    }
  };

  if (loading) return (
    <div className="flex flex-col items-center justify-center h-[80vh]">
      <div className="w-12 h-12 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin mb-4"></div>
      <p className="text-gray-500 font-medium">Loading Company Profile...</p>
    </div>
  );

  if (!data) return null;

  const contactDetails = data.contactDetails || data.ContactDetails || {};
  const focalPerson = data.focalPerson || data.FocalPerson || {};
  const interviewStatsRaw = data.interviewStats || data.InterviewStats || {};
  const interviewStats = {
    hired: Number(interviewStatsRaw.hired ?? interviewStatsRaw.Hired ?? 0),
    shortlisted: Number(interviewStatsRaw.shortlisted ?? interviewStatsRaw.Shortlisted ?? 0),
    rejected: Number(interviewStatsRaw.rejected ?? interviewStatsRaw.Rejected ?? 0),
    pending: Number(interviewStatsRaw.pending ?? interviewStatsRaw.Pending ?? 0),
    totalInterviews: Number(interviewStatsRaw.totalInterviews ?? interviewStatsRaw.TotalInterviews ?? 0),
  };
  const jobs = data.jobs || data.Jobs || [];
  const scheduledInterviews = data.scheduledInterviews || data.ScheduledInterviews || [];
  const hiredStudents = data.hiredStudents || data.HiredStudents || [];
  const shortlistedStudents = data.shortlistedStudents || data.ShortlistedStudents || [];
  const totalJobs = Number(data.totalJobs ?? data.TotalJobs ?? jobs.length);
  const surveySummary = surveysData
    ? {
        totalSurveys: Number(surveysData.totalSurveys ?? surveysData.TotalSurveys ?? 0),
        cdcSurveys: Number(surveysData.cdcSurveys ?? surveysData.CDCSurveys ?? 0),
        departmentSurveys: Number(surveysData.departmentSurveys ?? surveysData.DepartmentSurveys ?? 0),
        surveys: surveysData.surveys || surveysData.Surveys || []
      }
    : null;

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

  const handleDownloadSurveyPdf = async (mode) => {
    if (!surveySummary || !Array.isArray(surveySummary.surveys) || surveySummary.surveys.length === 0) {
      toast.error('No survey data available to download');
      return;
    }

    const loadingToastId = toast.loading('Preparing survey PDF...');

    try {
      const selectedSurveys = mode === 'Combined'
        ? surveySummary.surveys
        : surveySummary.surveys.filter((s) => String(s.type || s.Type || '') === mode);

      if (selectedSurveys.length === 0) {
        toast.dismiss(loadingToastId);
        toast.error(`No ${mode} survey responses found`);
        return;
      }

      const doc = new jsPDF();
      const pageWidth = doc.internal.pageSize.getWidth();
      const title = mode === 'Combined' ? 'Combined Survey Report' : `${mode} Survey Report`;
      const companyName = data?.name || 'Company';
      const { jobFairLabel, logoDataUrl } = await getPdfBrandingAssets();

      const drawHeader = () => {
        if (logoDataUrl) {
          doc.addImage(logoDataUrl, 'PNG', 14, 8, 18, 18);
        }
        doc.setFontSize(11);
        doc.setTextColor(0);
        doc.setFont(undefined, 'bold');
        doc.text(`Job Fair/Open House (${jobFairLabel})`, pageWidth / 2, 14, { align: 'center' });
        doc.text('CDC CUI, Wah Campus (cdc@ciitwah.edu.pk)', pageWidth / 2, 20, { align: 'center' });

        doc.setFontSize(15);
        doc.setTextColor(37, 99, 235);
        doc.text(`${companyName} - ${title}`, 14, 30);
        doc.setFontSize(9);
        doc.setTextColor(90);
        doc.setFont(undefined, 'normal');
        doc.text(`Generated: ${new Date().toLocaleString()}`, 14, 36);
      };

      drawHeader();

      selectedSurveys.forEach((survey, index) => {
        if (index > 0) {
          doc.addPage();
          drawHeader();
        }

        const rows = getSurveyQuestionAnswerRows(survey).map((item) => [item.question, item.answer]);
        const surveyType = String(survey.type || survey.Type || 'Unknown');
        const submittedAt = survey.submittedAt || survey.SubmittedAt;

        doc.setFontSize(12);
        doc.setTextColor(0);
        doc.text(`Type: ${surveyType}`, 14, 46);
        doc.setFontSize(9);
        doc.setTextColor(90);
        doc.text(`Submitted: ${submittedAt ? new Date(submittedAt).toLocaleString() : 'N/A'}`, 14, 52);

        autoTable(doc, {
          startY: 57,
          head: [['Question', 'Answer']],
          body: rows.length ? rows : [['No questions found', 'N/A']],
          theme: 'striped',
          headStyles: { fillColor: surveyType === 'CDC' ? [79, 70, 229] : [245, 158, 11] },
          styles: { fontSize: 8, cellPadding: 2.5 },
          columnStyles: {
            0: { cellWidth: 95 },
            1: { cellWidth: 90 }
          }
        });
      });

      const date = new Date().toISOString().split('T')[0];
      const fileSuffix = mode === 'Combined' ? 'Combined' : mode;
      doc.save(`${companyName.replace(/\s+/g, '_')}_${fileSuffix}_Survey_${date}.pdf`);
      toast.dismiss(loadingToastId);
      toast.success('Survey PDF downloaded');
    } catch {
      toast.dismiss(loadingToastId);
      toast.error('Failed to generate survey PDF');
    }
  };

  // Chart Data
  const statData = [
    { name: 'Hired', value: interviewStats.hired, color: '#10B981' },
    { name: 'Shortlisted', value: interviewStats.shortlisted, color: '#6366F1' },
    { name: 'Rejected', value: interviewStats.rejected, color: '#EF4444' },
    { name: 'Pending', value: interviewStats.pending, color: '#F59E0B' },
  ].filter(d => d.value > 0);

  return (
    <div className="max-w-7xl mx-auto pb-10 px-4 sm:px-6 animate-fade-in">
      
      {/* Back Button */}
      <button 
        onClick={handleBack}
        className="flex items-center gap-2 text-gray-600 hover:text-indigo-600 transition font-medium mt-6 mb-6"
      >
        <ArrowLeft size={20} /> Back to Directory
      </button>

      <div className="flex flex-col lg:flex-row gap-8 items-start">
        
        {/* -------------------------------------------------- */}
        {/* LEFT SIDEBAR: Identity & Contact Info              */}
        {/* -------------------------------------------------- */}
        <div className="w-full lg:w-1/3 space-y-6 lg:sticky lg:top-8">
          
          {/* Main Card */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden">
            <div className="h-24 bg-gradient-to-r from-gray-800 to-gray-900"></div>
            <div className="px-6 pb-6 relative">
              <div className="w-24 h-24 rounded-xl border-4 border-white shadow-lg bg-white -mt-12 flex items-center justify-center overflow-hidden">
                {data.logoUrl ? (
                  <img src={getFileUrl(data.logoUrl)} alt={data.name} className="w-full h-full object-contain p-1" />
                ) : (
                  <Building2 size={40} className="text-gray-300" />
                )}
              </div>
              
              <div className="mt-4">
                <h1 className="text-2xl font-bold text-gray-900">{data.name}</h1>
                <p className="text-gray-500 font-medium">{data.industry}</p>
                
                {/* Status Badges */}
                <div className="flex gap-2 mt-3">
                  <span className={`px-3 py-1 rounded-full text-xs font-bold border ${
                    data.isPresent ? 'bg-green-50 text-green-700 border-green-200' : 'bg-gray-50 text-gray-600 border-gray-200'
                  }`}>
                    {data.isPresent ? 'Checked In' : 'Not Present'}
                  </span>
                  <span className="px-3 py-1 rounded-full text-xs font-bold bg-blue-50 text-blue-700 border border-blue-200">
                    {data.arrivalStatus}
                  </span>
                  {typeof data.repsCount === 'number' && (
                    <span className="px-3 py-1 rounded-full text-xs font-bold bg-gray-100 text-gray-700 border border-gray-200">
                      Reps: {data.repsCount}
                    </span>
                  )}
                </div>
              </div>

              <div className="mt-6 space-y-3 border-t pt-4">
                <button
                  onClick={() => setIsEditingProfile(true)}
                  className="w-full flex items-center justify-center gap-2 py-2.5 bg-indigo-600 text-white rounded-lg text-sm font-semibold hover:bg-indigo-700 transition"
                >
                  <Edit2 size={16} /> Edit Company Profile
                </button>

                {/* Room */}
                <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg border border-gray-100">
                   <div className="flex items-center gap-2 text-gray-700">
                     <MapPin size={18} className="text-indigo-500" />
                     <span className="text-sm font-semibold">Allocated Room</span>
                   </div>
                   {data.room ? (
                     <span className="text-sm font-bold text-gray-900">{data.room.roomName}</span>
                   ) : (
                     <button 
                       onClick={() => setShowAssignModal(true)}
                       className="text-xs font-bold text-indigo-600 hover:text-indigo-800 hover:underline"
                     >
                       Assign Room
                     </button>
                   )}
                </div>

                {/* Website */}
                {data.website && (
                  <a href={data.website} target="_blank" rel="noreferrer" className="flex items-center gap-3 text-sm text-gray-600 hover:text-indigo-600 transition p-2">
                    <Globe size={18} /> {data.website.replace(/^https?:\/\//, '')}
                  </a>
                )}
                {/* Email */}
                <div className="flex items-center gap-3 text-sm text-gray-600 p-2">
                  <Mail size={18} /> {contactDetails.email || contactDetails.Email || 'N/A'}
                </div>
                {/* Phone */}
                <div className="flex items-center gap-3 text-sm text-gray-600 p-2">
                  <Phone size={18} /> {contactDetails.phone || contactDetails.Phone || 'N/A'}
                </div>
              </div>
            </div>
          </div>

          {/* Focal Person Card */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
            <h3 className="text-xs font-bold text-gray-400 uppercase mb-4">Focal Person</h3>
            <div className="flex items-start gap-4">
              <div className="p-3 bg-indigo-50 text-indigo-600 rounded-full">
                <User size={20} />
              </div>
              <div>
                <p className="font-bold text-gray-900">{focalPerson.name || focalPerson.Name || 'N/A'}</p>
                <p className="text-sm text-gray-500">{focalPerson.email || focalPerson.Email || 'N/A'}</p>
                <p className="text-sm text-gray-500">{focalPerson.phone || focalPerson.Phone || 'N/A'}</p>
                <button
                  onClick={() => setIsEditingProfile(true)}
                  className="mt-2 text-xs font-semibold text-indigo-600 hover:text-indigo-800"
                >
                  Edit Focal Person
                </button>
              </div>
            </div>
          </div>

        </div>

        {/* -------------------------------------------------- */}
        {/* RIGHT CONTENT: Tabs & Tables                       */}
        {/* -------------------------------------------------- */}
        <div className="w-full lg:w-2/3 space-y-6">
          
          {/* Tabs */}
          <div className="flex border-b border-gray-200">
            {['overview', 'pipeline', 'results', 'surveys'].map((tab) => (
              <button
                key={tab}
                onClick={() => {
                  setActiveTab(tab);
                  // Fetch surveys when switching to surveys tab
                  if (tab === 'surveys' && !surveysData) {
                    const fetchSurveys = async () => {
                      try {
                        const res = await api.get(`/survey/company/${companyId}`);
                        setSurveysData(res.data || {});
                      } catch (error) {
                        toast.error("Failed to load survey data");
                      }
                    };
                    fetchSurveys();
                  }
                }}
                className={`px-6 py-4 text-sm font-medium capitalize transition-colors border-b-2 ${
                  activeTab === tab 
                    ? 'border-indigo-600 text-indigo-600' 
                    : 'border-transparent text-gray-500 hover:text-gray-700'
                }`}
              >
                {tab}
              </button>
            ))}
          </div>

          {/* TAB 1: OVERVIEW */}
          {activeTab === 'overview' && (
            <div className="space-y-6 animate-fade-in">
              {/* Description */}
              {data.description && (
                <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
                  <h3 className="font-bold text-gray-900 mb-2">About Company</h3>
                  <p className="text-gray-600 leading-relaxed text-sm">{data.description}</p>
                </div>
              )}

              {/* Job Openings */}
              <div>
                <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
                  <Briefcase className="text-gray-400" size={20} /> Job Openings ({totalJobs})
                </h3>
                <div className="grid gap-4">
                  {jobs.length > 0 ? jobs.map(job => (
                    <div key={job.jobId} className="bg-white p-5 rounded-xl border border-gray-200 shadow-sm hover:border-indigo-200 transition">
                      <div className="flex justify-between items-start">
                         <div>
                           <h4 className="font-bold text-gray-900">{job.jobTitle}</h4>
                           <span className="inline-block px-2 py-0.5 mt-1 text-xs font-semibold bg-gray-100 text-gray-600 rounded">
                             {job.jobType}
                           </span>
                         </div>
                         <span className="text-sm font-bold bg-indigo-50 text-indigo-700 px-3 py-1 rounded-full">
                           {job.numberOfJobs} Positions
                         </span>
                      </div>
                      <p className="text-sm text-gray-600 mt-2 line-clamp-2">{job.jobDescription}</p>
                      <div className="mt-3 flex flex-wrap gap-2">
                        {job.requiredSkills?.map(s => (
                          <span key={s} className="text-xs bg-gray-50 text-gray-500 px-2 py-1 rounded border">
                            {s}
                          </span>
                        ))}
                      </div>
                    </div>
                  )) : (
                    <p className="text-gray-500 italic">No jobs posted yet.</p>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: PIPELINE */}
          {activeTab === 'pipeline' && (
            <div className="space-y-6 animate-fade-in">
              
              {/* Stats & Chart Row */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
                   <h3 className="font-bold text-gray-900 mb-4">Interview Breakdown</h3>
                   <div className="h-48">
                      {statData.length > 0 ? (
                        <ResponsiveContainer width="100%" height="100%">
                          <PieChart>
                            <Pie data={statData} innerRadius={50} outerRadius={70} paddingAngle={5} dataKey="value">
                              {statData.map((entry, index) => <Cell key={index} fill={entry.color} />)}
                            </Pie>
                            <Tooltip />
                            <Legend />
                          </PieChart>
                        </ResponsiveContainer>
                      ) : (
                        <div className="h-full flex items-center justify-center text-gray-400 text-sm">No interviews yet</div>
                      )}
                   </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="bg-green-50 p-4 rounded-xl flex flex-col justify-center items-center text-center">
                    <span className="text-3xl font-bold text-green-600">{interviewStats.hired}</span>
                    <span className="text-sm font-medium text-green-800">Total Hired</span>
                  </div>
                  <div className="bg-indigo-50 p-4 rounded-xl flex flex-col justify-center items-center text-center">
                    <span className="text-3xl font-bold text-indigo-600">{interviewStats.shortlisted}</span>
                    <span className="text-sm font-medium text-indigo-800">Shortlisted</span>
                  </div>
                  <div className="bg-amber-50 p-4 rounded-xl flex flex-col justify-center items-center text-center">
                    <span className="text-3xl font-bold text-amber-600">{interviewStats.pending}</span>
                    <span className="text-sm font-medium text-amber-800">In Queue</span>
                  </div>
                  <div className="bg-gray-50 p-4 rounded-xl flex flex-col justify-center items-center text-center">
                    <span className="text-3xl font-bold text-gray-600">{interviewStats.totalInterviews}</span>
                    <span className="text-sm font-medium text-gray-800">Total Conducted</span>
                  </div>
                </div>
              </div>

              {/* Scheduled Interviews Table */}
              <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
                <div className="p-4 border-b bg-gray-50 font-bold text-gray-800 flex items-center gap-2">
                   <Calendar size={18} /> Upcoming / Scheduled Interviews
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm text-left">
                    <thead className="text-gray-500 bg-white border-b">
                      <tr>
                        <th className="px-4 py-3">Student</th>
                        <th className="px-4 py-3">Reg No</th>
                        <th className="px-4 py-3">Time</th>
                        <th className="px-4 py-3">Status</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100">
                      {scheduledInterviews.length > 0 ? scheduledInterviews.map((int) => (
                        <tr key={int.interviewId} className="hover:bg-gray-50">
                          <td className="px-4 py-3 font-medium text-gray-900">
                            {int.studentId ? (
                              <button
                                onClick={() => navigate(`/admin/students/${int.studentId}`)}
                                className="text-indigo-700 hover:underline"
                              >
                                {int.studentName}
                              </button>
                            ) : int.studentName}
                          </td>
                          <td className="px-4 py-3 text-gray-500">{int.studentRegistration}</td>
                          <td className="px-4 py-3 text-indigo-600 font-medium">
                            {int.interviewDate ? new Date(int.interviewDate).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : 'TBD'}
                          </td>
                          <td className="px-4 py-3">
                            <span className="px-2 py-1 bg-gray-100 text-gray-600 rounded text-xs font-bold">{int.status}</span>
                          </td>
                        </tr>
                      )) : (
                        <tr><td colSpan="4" className="p-4 text-center text-gray-500 italic">No scheduled interviews.</td></tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>

            </div>
          )}

          {/* TAB 3: RESULTS (Hired/Shortlisted) */}
          {activeTab === 'results' && (
            <div className="space-y-8 animate-fade-in">
              
              {/* Hired List */}
              <div className="bg-white rounded-xl border border-green-200 shadow-sm overflow-hidden">
                <div className="p-4 border-b border-green-100 bg-green-50 font-bold text-green-800 flex items-center gap-2">
                   <CheckCircle size={18} /> Hired Students
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm text-left">
                    <thead className="text-gray-500 bg-white border-b">
                      <tr>
                        <th className="px-4 py-3">Name</th>
                        <th className="px-4 py-3">Reg No</th>
                        <th className="px-4 py-3">Department</th>
                        <th className="px-4 py-3 text-right">CGPA</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100">
                      {hiredStudents.length > 0 ? hiredStudents.map((s) => (
                        <tr key={s.studentId} className="hover:bg-green-50/50">
                          <td className="px-4 py-3 font-medium text-gray-900">
                            <button
                              onClick={() => navigate(`/admin/students/${s.studentId}`)}
                              className="text-indigo-700 hover:underline"
                            >
                              {s.studentName}
                            </button>
                          </td>
                          <td className="px-4 py-3 text-gray-500">{s.studentRegistration}</td>
                          <td className="px-4 py-3 text-gray-500">{s.department}</td>
                          <td className="px-4 py-3 text-right font-bold text-green-600">{Number(s.cgpa ?? 0).toFixed(2)}</td>
                        </tr>
                      )) : (
                        <tr><td colSpan="4" className="p-4 text-center text-gray-500 italic">No students hired yet.</td></tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Shortlisted List */}
              <div className="bg-white rounded-xl border border-indigo-200 shadow-sm overflow-hidden">
                <div className="p-4 border-b border-indigo-100 bg-indigo-50 font-bold text-indigo-800 flex items-center gap-2">
                   <Users size={18} /> Shortlisted Students
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm text-left">
                    <thead className="text-gray-500 bg-white border-b">
                      <tr>
                        <th className="px-4 py-3">Name</th>
                        <th className="px-4 py-3">Reg No</th>
                        <th className="px-4 py-3">Department</th>
                        <th className="px-4 py-3 text-right">CGPA</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100">
                      {shortlistedStudents.length > 0 ? shortlistedStudents.map((s) => (
                        <tr key={s.studentId} className="hover:bg-indigo-50/50">
                          <td className="px-4 py-3 font-medium text-gray-900">
                            <button
                              onClick={() => navigate(`/admin/students/${s.studentId}`)}
                              className="text-indigo-700 hover:underline"
                            >
                              {s.studentName}
                            </button>
                          </td>
                          <td className="px-4 py-3 text-gray-500">{s.studentRegistration}</td>
                          <td className="px-4 py-3 text-gray-500">{s.department}</td>
                          <td className="px-4 py-3 text-right font-bold text-indigo-600">{Number(s.cgpa ?? 0).toFixed(2)}</td>
                        </tr>
                      )) : (
                        <tr><td colSpan="4" className="p-4 text-center text-gray-500 italic">No students shortlisted yet.</td></tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>

            </div>
          )}

          {/* TAB 4: SURVEYS */}
          {activeTab === 'surveys' && (
            <div className="space-y-6 animate-fade-in">
              {surveySummary && surveySummary.totalSurveys > 0 ? (
                <>
                  {/* Survey Stats */}
                  <div className="grid grid-cols-3 gap-4">
                    <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm text-center">
                      <p className="text-gray-500 text-xs font-medium">Total</p>
                      <h3 className="text-2xl font-bold text-gray-800 mt-1">{surveySummary.totalSurveys}</h3>
                    </div>
                    <div className="bg-indigo-50 p-4 rounded-xl border border-indigo-200 shadow-sm text-center">
                      <p className="text-indigo-600 text-xs font-medium">CDC</p>
                      <h3 className="text-2xl font-bold text-indigo-600 mt-1">{surveySummary.cdcSurveys}</h3>
                    </div>
                    <div className="bg-amber-50 p-4 rounded-xl border border-amber-200 shadow-sm text-center">
                      <p className="text-amber-600 text-xs font-medium">Department</p>
                      <h3 className="text-2xl font-bold text-amber-600 mt-1">{surveySummary.departmentSurveys}</h3>
                    </div>
                  </div>

                  {/* Survey Responses Table */}
                  <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
                    <div className="p-4 border-b bg-gray-50 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                      <div className="font-bold text-gray-800">Survey Responses</div>
                      <div className="flex flex-wrap gap-2">
                        <button
                          onClick={() => handleDownloadSurveyPdf('CDC')}
                          className="px-3 py-1.5 text-xs font-medium text-indigo-700 bg-indigo-50 hover:bg-indigo-100 rounded-lg transition-colors"
                        >
                          CDC PDF
                        </button>
                        <button
                          onClick={() => handleDownloadSurveyPdf('Department')}
                          className="px-3 py-1.5 text-xs font-medium text-amber-700 bg-amber-50 hover:bg-amber-100 rounded-lg transition-colors"
                        >
                          Departmental PDF
                        </button>
                        <button
                          onClick={() => handleDownloadSurveyPdf('Combined')}
                          className="px-3 py-1.5 text-xs font-medium text-purple-700 bg-purple-50 hover:bg-purple-100 rounded-lg transition-colors"
                        >
                          Combined PDF
                        </button>
                      </div>
                    </div>
                    <div className="overflow-x-auto">
                      <table className="w-full text-sm">
                        <thead className="bg-gray-50 border-b">
                          <tr>
                            <th className="px-4 py-3 text-left text-xs font-bold text-gray-700">Type</th>
                            <th className="px-4 py-3 text-left text-xs font-bold text-gray-700">Submitted</th>
                            <th className="px-4 py-3 text-right text-xs font-bold text-gray-700">Action</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y">
                          {surveySummary.surveys.map((survey) => (
                            <tr key={survey.surveyId} className="hover:bg-gray-50">
                              <td className="px-4 py-3">
                                <span className={`px-2.5 py-0.5 rounded-full text-xs font-bold border ${
                                  survey.type === 'CDC'
                                    ? 'bg-indigo-100 text-indigo-700 border-indigo-200'
                                    : 'bg-amber-100 text-amber-700 border-amber-200'
                                }`}>
                                  {survey.type}
                                </span>
                              </td>
                              <td className="px-4 py-3 text-gray-600">
                                {new Date(survey.submittedAt).toLocaleDateString()}
                              </td>
                              <td className="px-4 py-3 text-right">
                                <button
                                  onClick={() => setSelectedSurvey(survey)}
                                  className="px-3 py-1.5 text-xs font-medium text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-lg transition-colors inline-flex items-center gap-1"
                                >
                                  <Eye size={14} /> View
                                </button>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                </>
              ) : (
                <div className="bg-white p-8 rounded-xl border border-gray-200 shadow-sm text-center">
                  <FileText size={48} className="text-gray-300 mx-auto mb-4" />
                  <p className="text-gray-600 font-medium">No surveys submitted yet</p>
                  <p className="text-sm text-gray-400 mt-1">Surveys will appear here once companies submit them</p>
                </div>
              )}
            </div>
          )}

        </div>
      </div>

      {/* Assign Room Modal */}
      {showAssignModal && (
        <AssignRoomModal 
          companyId={companyId}
          companyName={data.name}
          onClose={() => setShowAssignModal(false)}
          onSuccess={fetchDetails}
        />
      )}

      {isEditingProfile && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-2xl overflow-hidden animate-fade-in">
            <div className="px-6 py-4 border-b flex justify-between items-center bg-gray-50">
              <h3 className="font-bold text-gray-800">Edit Company Profile</h3>
              <button onClick={() => setIsEditingProfile(false)} className="text-gray-400 hover:text-gray-600">
                <X size={20} />
              </button>
            </div>

            <div className="p-6 grid grid-cols-1 md:grid-cols-2 gap-4 max-h-[70vh] overflow-y-auto">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Company Name</label>
                <input className="w-full px-3 py-2 border rounded-lg" value={profileFormData.name} onChange={(e) => setProfileFormData({ ...profileFormData, name: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Industry</label>
                <input className="w-full px-3 py-2 border rounded-lg" value={profileFormData.industry} onChange={(e) => setProfileFormData({ ...profileFormData, industry: e.target.value })} />
              </div>
              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <textarea rows="3" className="w-full px-3 py-2 border rounded-lg" value={profileFormData.description} onChange={(e) => setProfileFormData({ ...profileFormData, description: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Website</label>
                <input className="w-full px-3 py-2 border rounded-lg" value={profileFormData.website} onChange={(e) => setProfileFormData({ ...profileFormData, website: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Address</label>
                <input className="w-full px-3 py-2 border rounded-lg" value={profileFormData.address} onChange={(e) => setProfileFormData({ ...profileFormData, address: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Company Email</label>
                <input className="w-full px-3 py-2 border rounded-lg" value={profileFormData.companyEmail} onChange={(e) => setProfileFormData({ ...profileFormData, companyEmail: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Company Phone</label>
                <input className="w-full px-3 py-2 border rounded-lg" value={profileFormData.companyPhone} onChange={(e) => setProfileFormData({ ...profileFormData, companyPhone: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Focal Person Name</label>
                <input className="w-full px-3 py-2 border rounded-lg" value={profileFormData.focalPersonName} onChange={(e) => setProfileFormData({ ...profileFormData, focalPersonName: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Focal Person Email</label>
                <input className="w-full px-3 py-2 border rounded-lg" value={profileFormData.focalPersonEmail} onChange={(e) => setProfileFormData({ ...profileFormData, focalPersonEmail: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Focal Person Phone</label>
                <input className="w-full px-3 py-2 border rounded-lg" value={profileFormData.focalPersonPhone} onChange={(e) => setProfileFormData({ ...profileFormData, focalPersonPhone: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Reps Count</label>
                <input type="number" min="1" className="w-full px-3 py-2 border rounded-lg" value={profileFormData.repsCount} onChange={(e) => setProfileFormData({ ...profileFormData, repsCount: e.target.value })} />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Interview Duration (mins)</label>
                <input type="number" min="1" className="w-full px-3 py-2 border rounded-lg" value={profileFormData.interviewDurationMinutes} onChange={(e) => setProfileFormData({ ...profileFormData, interviewDurationMinutes: e.target.value })} />
              </div>
            </div>

            <div className="px-6 py-4 border-t bg-gray-50 flex justify-end gap-3">
              <button
                onClick={() => setIsEditingProfile(false)}
                className="px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded-lg"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveCompanyProfile}
                disabled={profileSaving}
                className="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg disabled:opacity-60 flex items-center gap-2"
              >
                <Save size={16} /> {profileSaving ? 'Saving...' : 'Save Profile'}
              </button>
            </div>
          </div>
        </div>
      )}

      {selectedSurvey && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
          {(() => {
            const selectedSubmittedAt = selectedSurvey.submittedAt || selectedSurvey.SubmittedAt;
            return (
          <div className="bg-white rounded-xl shadow-xl w-full max-w-3xl overflow-hidden animate-fade-in max-h-[85vh] flex flex-col">
            <div className="px-6 py-4 border-b flex justify-between items-center bg-gray-50">
              <div>
                <h3 className="font-bold text-gray-900">Survey Response Details</h3>
                <p className="text-xs text-gray-500 mt-1">
                  {String(selectedSurvey.type || selectedSurvey.Type || 'Unknown')} • {selectedSubmittedAt ? new Date(selectedSubmittedAt).toLocaleString() : ''}
                </p>
              </div>
              <button onClick={() => setSelectedSurvey(null)} className="text-gray-400 hover:text-gray-600">
                <X size={20} />
              </button>
            </div>

            <div className="p-6 overflow-y-auto space-y-4">
              {getSurveyQuestionAnswerRows(selectedSurvey).map((item, idx) => (
                <div key={`${idx}-${item.question}`} className="border border-gray-200 rounded-lg p-4">
                  <p className="text-sm font-semibold text-gray-900">{item.question}</p>
                  <p className="text-sm text-gray-700 mt-2 whitespace-pre-wrap">{item.answer || 'N/A'}</p>
                </div>
              ))}
            </div>

            <div className="px-6 py-4 border-t bg-gray-50 flex justify-end">
              <button
                onClick={() => setSelectedSurvey(null)}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-100"
              >
                Close
              </button>
            </div>
          </div>
            );
          })()}
        </div>
      )}
    </div>
  );
};

export default CompanyDetail;