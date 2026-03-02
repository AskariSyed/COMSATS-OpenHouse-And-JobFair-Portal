/* eslint-disable no-unused-vars */
import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { 
  ArrowLeft, Building2, MapPin, Mail, Phone, Globe, User, 
  Briefcase, CheckCircle, XCircle, Clock, Calendar, 
  Users, Layout, Link as LinkIcon, FileText, Eye
} from 'lucide-react';
import api from '../../lib/api';
import { toast } from 'react-hot-toast';
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend } from 'recharts';

// 🔧 CONFIGURATION
const BACKEND_URL = "https://localhost:7050"; 

const getImageUrl = (path) => {
  if (!path) return null;
  if (path.startsWith('http')) return path; 
  return `${BACKEND_URL}${path}`; 
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
      toast.error("Failed to assign room");
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
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('overview'); // overview | pipeline | results | surveys
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [surveysData, setSurveysData] = useState(null);

  const fetchDetails = async () => {
    try {
      // Matches AdminController [HttpGet("companies/{companyId}/details")]
      const res = await api.get(`/admin/companies/${companyId}/details`);
      setData(res.data);
    } catch (err) {
      toast.error("Failed to load company details");
      navigate('/admin/companies');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDetails();
  }, [companyId, navigate]);

  if (loading) return (
    <div className="flex flex-col items-center justify-center h-[80vh]">
      <div className="w-12 h-12 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin mb-4"></div>
      <p className="text-gray-500 font-medium">Loading Company Profile...</p>
    </div>
  );

  if (!data) return null;

  // Chart Data
  const statData = [
    { name: 'Hired', value: data.interviewStats.hired, color: '#10B981' },
    { name: 'Shortlisted', value: data.interviewStats.shortlisted, color: '#6366F1' },
    { name: 'Rejected', value: data.interviewStats.rejected, color: '#EF4444' },
    { name: 'Pending', value: data.interviewStats.pending, color: '#F59E0B' },
  ].filter(d => d.value > 0);

  return (
    <div className="max-w-7xl mx-auto pb-10 px-4 sm:px-6 animate-fade-in">
      
      {/* Back Button */}
      <button 
        onClick={() => navigate(-1)}
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
                  <img src={getImageUrl(data.logoUrl)} alt={data.name} className="w-full h-full object-contain p-1" />
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
                  <Mail size={18} /> {data.contactDetails.email}
                </div>
                {/* Phone */}
                <div className="flex items-center gap-3 text-sm text-gray-600 p-2">
                  <Phone size={18} /> {data.contactDetails.phone}
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
                <p className="font-bold text-gray-900">{data.focalPerson.name}</p>
                <p className="text-sm text-gray-500">{data.focalPerson.email}</p>
                <p className="text-sm text-gray-500">{data.focalPerson.phone}</p>
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
                        const res = await api.get(`/api/survey/company/${companyId}`);
                        setSurveysData(res.data);
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
                  <Briefcase className="text-gray-400" size={20} /> Job Openings ({data.totalJobs})
                </h3>
                <div className="grid gap-4">
                  {data.jobs.length > 0 ? data.jobs.map(job => (
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
                    <span className="text-3xl font-bold text-green-600">{data.interviewStats.hired}</span>
                    <span className="text-sm font-medium text-green-800">Total Hired</span>
                  </div>
                  <div className="bg-indigo-50 p-4 rounded-xl flex flex-col justify-center items-center text-center">
                    <span className="text-3xl font-bold text-indigo-600">{data.interviewStats.shortlisted}</span>
                    <span className="text-sm font-medium text-indigo-800">Shortlisted</span>
                  </div>
                  <div className="bg-amber-50 p-4 rounded-xl flex flex-col justify-center items-center text-center">
                    <span className="text-3xl font-bold text-amber-600">{data.interviewStats.pending}</span>
                    <span className="text-sm font-medium text-amber-800">In Queue</span>
                  </div>
                  <div className="bg-gray-50 p-4 rounded-xl flex flex-col justify-center items-center text-center">
                    <span className="text-3xl font-bold text-gray-600">{data.interviewStats.totalInterviews}</span>
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
                      {data.scheduledInterviews.length > 0 ? data.scheduledInterviews.map((int) => (
                        <tr key={int.interviewId} className="hover:bg-gray-50">
                          <td className="px-4 py-3 font-medium text-gray-900">{int.studentName}</td>
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
                      {data.hiredStudents.length > 0 ? data.hiredStudents.map((s) => (
                        <tr key={s.studentId} className="hover:bg-green-50/50">
                          <td className="px-4 py-3 font-medium text-gray-900">{s.studentName}</td>
                          <td className="px-4 py-3 text-gray-500">{s.studentRegistration}</td>
                          <td className="px-4 py-3 text-gray-500">{s.department}</td>
                          <td className="px-4 py-3 text-right font-bold text-green-600">{s.cgpa.toFixed(2)}</td>
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
                      {data.shortlistedStudents.length > 0 ? data.shortlistedStudents.map((s) => (
                        <tr key={s.studentId} className="hover:bg-indigo-50/50">
                          <td className="px-4 py-3 font-medium text-gray-900">{s.studentName}</td>
                          <td className="px-4 py-3 text-gray-500">{s.studentRegistration}</td>
                          <td className="px-4 py-3 text-gray-500">{s.department}</td>
                          <td className="px-4 py-3 text-right font-bold text-indigo-600">{s.cgpa.toFixed(2)}</td>
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
              {surveysData && surveysData.totalSurveys > 0 ? (
                <>
                  {/* Survey Stats */}
                  <div className="grid grid-cols-3 gap-4">
                    <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm text-center">
                      <p className="text-gray-500 text-xs font-medium">Total</p>
                      <h3 className="text-2xl font-bold text-gray-800 mt-1">{surveysData.totalSurveys}</h3>
                    </div>
                    <div className="bg-indigo-50 p-4 rounded-xl border border-indigo-200 shadow-sm text-center">
                      <p className="text-indigo-600 text-xs font-medium">CDC</p>
                      <h3 className="text-2xl font-bold text-indigo-600 mt-1">{surveysData.cdcSurveys}</h3>
                    </div>
                    <div className="bg-amber-50 p-4 rounded-xl border border-amber-200 shadow-sm text-center">
                      <p className="text-amber-600 text-xs font-medium">Department</p>
                      <h3 className="text-2xl font-bold text-amber-600 mt-1">{surveysData.departmentSurveys}</h3>
                    </div>
                  </div>

                  {/* Survey Responses Table */}
                  <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
                    <div className="p-4 border-b bg-gray-50 font-bold text-gray-800">
                      Survey Responses
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
                          {surveysData.surveys.map((survey) => (
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
                                  onClick={() => {
                                    // Open a modal or navigate to view full responses
                                    alert(`Survey ID: ${survey.surveyId}\n\nFull survey data:\n${JSON.stringify(survey.responses, null, 2)}`);
                                  }}
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
    </div>
  );
};

export default CompanyDetail;