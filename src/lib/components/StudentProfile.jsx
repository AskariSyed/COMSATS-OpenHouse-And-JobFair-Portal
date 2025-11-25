import React, { useEffect, useState } from 'react';
import { ChevronRight, Mail, Loader2, MapPin, GraduationCap, Briefcase, Award, Github, Linkedin, Globe, Send, CheckCircle2, XCircle, Clock, Calendar, Phone } from 'lucide-react';
import { getStudentProfile, getFileUrl, sendInterviewRequest, acceptInterviewRequest, rejectInterviewRequest } from '../api';

export default function StudentProfile({ studentId, onBack }) {
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0); 

  const [showScheduleModal, setShowScheduleModal] = useState(false);
  const [scheduleTime, setScheduleTime] = useState('');

  useEffect(() => {
    if (!studentId) return;
    setLoading(true);
    getStudentProfile(studentId)
      .then(data => setProfile(data.student))
      .catch(err => console.error("Profile load error:", err))
      .finally(() => setLoading(false));
  }, [studentId, refreshKey]);

  // --- ACTIONS ---
  const handleSendRequest = async () => {
    setActionLoading(true);
    try { await sendInterviewRequest(studentId); setRefreshKey(k => k + 1); } 
    catch (err) { alert(err.message); } 
    finally { setActionLoading(false); }
  };

  const handleAcceptRequest = async (e) => {
    e.preventDefault();
    const reqId = profile.interviewRequest?.requestId || profile.InterviewRequest?.RequestId;
    if (!reqId) return;
    setActionLoading(true);
    try { await acceptInterviewRequest(reqId, scheduleTime); setShowScheduleModal(false); setRefreshKey(k => k + 1); } 
    catch (err) { alert(err.message); } 
    finally { setActionLoading(false); }
  };

  const handleRejectRequest = async () => {
    const reqId = profile.interviewRequest?.requestId || profile.InterviewRequest?.RequestId;
    if (!reqId) return;
    if (!window.confirm("Reject this candidate?")) return;
    setActionLoading(true);
    try { await rejectInterviewRequest(reqId, "Rejected via portal"); setRefreshKey(k => k + 1); } 
    catch (err) { alert(err.message); } 
    finally { setActionLoading(false); }
  };

  // --- HEADER ACTION RENDERER ---
  const renderHeaderAction = () => {
    if (!profile) return null;

    const req = profile.InterviewRequest || profile.interviewRequest || {};
    const hasRequest = req.HasRequest === true || req.hasRequest === true;
    const status = (req.Status || req.status || '').toLowerCase();
    const requestedByVal = req.RequestedBy !== undefined ? req.RequestedBy : req.requestedBy;
    const isStudentRequest = requestedByVal === 1 || requestedByVal === 'Student';

    // 1. No Request -> "Send Request"
    if (!hasRequest) {
      return (
        <button onClick={handleSendRequest} disabled={actionLoading} className="flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-bold shadow-md bg-blue-600 hover:bg-blue-700 text-white transition-all transform hover:-translate-y-0.5">
          {actionLoading ? <Loader2 className="animate-spin w-4 h-4" /> : <><Send className="w-4 h-4" /> Send Interview Request</>}
        </button>
      );
    }

    // 2. Scheduled -> Badge
    if (status === 'accepted') {
      return (
        <div className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-bold bg-green-50 text-green-700 border border-green-200 cursor-default">
          <CheckCircle2 className="w-5 h-5" /> Interview Scheduled
        </div>
      );
    }

    // 3. Rejected -> Badge
    if (status === 'rejected') {
      return (
        <div className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-bold bg-red-50 text-red-600 border border-red-200 cursor-default">
          <XCircle className="w-5 h-5" /> Rejected
        </div>
      );
    }

    // 4. Pending
    if (status === 'pending') {
      // 4a. Incoming (from Student)
      if (isStudentRequest) {
         return (
            <div className="flex gap-3 items-center">
                <button onClick={() => setShowScheduleModal(true)} disabled={actionLoading} className="flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-bold bg-green-600 hover:bg-green-700 text-white shadow-md transition-all transform hover:-translate-y-0.5">
                  <CheckCircle2 className="w-4 h-4" /> Accept & Schedule
                </button>
                <button onClick={handleRejectRequest} disabled={actionLoading} className="flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-bold bg-white border border-gray-300 text-gray-700 hover:bg-red-50 hover:text-red-600 hover:border-red-200 shadow-sm transition-all transform hover:-translate-y-0.5">
                  <XCircle className="w-4 h-4" /> Reject
                </button>
            </div>
         );
      }
      // 4b. Outgoing (from Company)
      return (
        <div className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-bold bg-yellow-50 text-yellow-700 border border-yellow-200 cursor-default">
          <Clock className="w-5 h-5" /> Request Pending
        </div>
      );
    }
    return null;
  };

  // --- RENDER ---
  if (!studentId) return <div className="text-center p-8 text-red-500">Error: No Student ID provided.</div>;
  if (loading) return <div className="h-96 flex items-center justify-center"><Loader2 className="animate-spin text-blue-600 w-8 h-8" /></div>;
  if (!profile) return <div className="text-center text-red-500 p-8">Failed to load profile.</div>;

  const { user, educations, experiences, projects, skills, contactLinks } = profile;

  return (
    <div className="max-w-6xl mx-auto animate-fade-in pb-10">
      
      {/* --- NEW HEADER DESIGN --- */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden mb-6">
        
        {/* 1. Gradient Cover */}
        <div className="h-40 bg-gradient-to-r from-slate-800 via-slate-700 to-slate-900 relative">
           <button onClick={onBack} className="absolute top-6 left-6 bg-white/10 hover:bg-white/20 text-white px-3 py-1.5 rounded-lg text-sm font-medium flex items-center gap-1 transition-colors backdrop-blur-sm">
              <ChevronRight className="w-4 h-4 rotate-180" /> Back
           </button>
        </div>

        {/* 2. Profile Content */}
        <div className="px-8 pb-8 relative">
           {/* Avatar (Overlapping) */}
           <div className="absolute -top-16 left-8 w-32 h-32 rounded-2xl p-1 bg-white shadow-lg">
              {profile.profilePicUrl ? (
                 <img src={getFileUrl(profile.profilePicUrl)} alt={user?.fullName} className="w-full h-full object-cover rounded-xl bg-gray-50" />
              ) : (
                 <div className="w-full h-full bg-blue-50 text-blue-600 rounded-xl flex items-center justify-center text-4xl font-bold">
                    {user?.fullName?.charAt(0)}
                 </div>
              )}
           </div>

           {/* Info Row */}
           <div className="ml-36 pt-3 flex flex-col md:flex-row justify-between items-start md:items-center gap-4 min-h-[60px]">
              <div>
                 <h1 className="text-3xl font-bold text-gray-900">{user?.fullName}</h1>
                 <div className="flex items-center gap-2 text-gray-500 text-sm mt-1">
                    <GraduationCap className="w-4 h-4" /> {profile.registrationNo}
                    <span className="w-1 h-1 bg-gray-300 rounded-full"></span>
                    {profile.department}
                 </div>
              </div>
              {/* Right Side Actions */}
              <div className="flex items-center gap-4">
                 <div className="hidden md:block text-right mr-4">
                    <div className="text-3xl font-bold text-gray-900 leading-none">{profile.cgpa?.toFixed(2)}</div>
                    <div className="text-[10px] text-gray-400 uppercase font-bold tracking-wider">CGPA</div>
                 </div>
                 {renderHeaderAction()}
              </div>
           </div>

           {/* Contact & Links Bar */}
           <div className="mt-8 pt-6 border-t border-gray-100 flex flex-wrap justify-between gap-6">
              <div className="flex flex-wrap gap-6 text-sm text-gray-600">
                 {user?.email && <span className="flex items-center gap-2 hover:text-blue-600 transition-colors"><Mail className="w-4 h-4 text-gray-400" /> {user.email}</span>}
                 {user?.phone && <span className="flex items-center gap-2 hover:text-blue-600 transition-colors"><Phone className="w-4 h-4 text-gray-400" /> {user.phone}</span>}
                 <span className="flex items-center gap-2"><MapPin className="w-4 h-4 text-gray-400" /> Wah Campus</span>
              </div>
              
              <div className="flex gap-2">
                 {contactLinks?.map((link, i) => (
                   <a key={i} href={link.url} target="_blank" rel="noreferrer" className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-all">
                     <Globe className="w-4 h-4" />
                   </a>
                 ))}
              </div>
           </div>
        </div>
      </div>

      {/* --- CONTENT GRID (Unchanged Layout) --- */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
         {/* Left Sidebar */}
         <div className="space-y-6">
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
               <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2 text-sm uppercase tracking-wider"><Award className="w-4 h-4 text-blue-600" /> Skills</h3>
               <div className="flex flex-wrap gap-2">
                  {skills?.length > 0 ? skills.map(s => (
                     <span key={s} className="bg-gray-50 border border-gray-200 text-gray-700 px-3 py-1.5 rounded-lg text-xs font-medium">
                        {s}
                     </span>
                  )) : <span className="text-gray-400 text-sm italic">No skills listed.</span>}
               </div>
            </div>

            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
               <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2 text-sm uppercase tracking-wider"><Briefcase className="w-4 h-4 text-blue-600" /> Experience</h3>
               <div className="space-y-6">
                  {experiences?.length > 0 ? experiences.map((exp, i) => (
                     <div key={i} className="relative pl-4 border-l-2 border-gray-100">
                        <div className="absolute -left-[5px] top-1.5 w-2.5 h-2.5 rounded-full bg-gray-300"></div>
                        <h4 className="font-bold text-sm text-gray-900">{exp.role}</h4>
                        <p className="text-xs text-gray-500 font-medium">{exp.companyName}</p>
                        <p className="text-[10px] text-gray-400 mt-1">{new Date(exp.startDate).getFullYear()} - {exp.isCurrent ? 'Present' : new Date(exp.endDate).getFullYear()}</p>
                     </div>
                  )) : <span className="text-gray-400 text-sm italic">No experience listed.</span>}
               </div>
            </div>
         </div>

         {/* Main Content */}
         <div className="lg:col-span-2 space-y-6">
            {/* Education */}
            <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-200">
               <h3 className="font-bold text-gray-900 border-b border-gray-100 pb-4 mb-6 text-lg">Education</h3>
               <div className="space-y-6">
                  {educations?.length > 0 ? educations.map((edu, i) => (
                     <div key={i} className="flex flex-col sm:flex-row sm:justify-between sm:items-start gap-2">
                        <div>
                           <h4 className="font-bold text-gray-800 text-base">{edu.institutionName}</h4>
                           <p className="text-sm text-gray-500">{edu.degree} in {edu.fieldOfStudy}</p>
                        </div>
                        <span className="text-xs font-bold bg-blue-50 text-blue-700 px-3 py-1 rounded-full whitespace-nowrap self-start">
                           {new Date(edu.startDate).getFullYear()} - {new Date(edu.endDate).getFullYear()}
                        </span>
                     </div>
                  )) : <div className="text-gray-400 italic">No education details.</div>}
               </div>
            </div>

            {/* Projects */}
            <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-200">
               <h3 className="font-bold text-gray-900 border-b border-gray-100 pb-4 mb-6 text-lg">Projects</h3>
               <div className="grid grid-cols-1 gap-4">
                  {projects?.length > 0 ? projects.map(p => (
                     <div key={p.projectId} className="group bg-white border border-gray-200 p-5 rounded-xl hover:border-blue-300 transition-all hover:shadow-sm">
                        <div className="flex justify-between items-start mb-2">
                           <h4 className="font-bold text-blue-700 group-hover:text-blue-800">{p.title}</h4>
                           <span className="text-[10px] uppercase font-bold bg-gray-100 text-gray-600 px-2 py-1 rounded">{p.type}</span>
                        </div>
                        <p className="text-sm text-gray-600 line-clamp-2 leading-relaxed">{p.description}</p>
                     </div>
                  )) : <div className="text-gray-400 italic">No projects listed.</div>}
               </div>
            </div>
         </div>
      </div>

      {/* SCHEDULE MODAL */}
      {showScheduleModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
            <div className="bg-white rounded-2xl shadow-2xl p-6 w-full max-w-sm animate-fade-in-down border border-gray-100">
                <div className="flex items-center gap-3 mb-6 text-blue-600 bg-blue-50 p-3 rounded-xl">
                    <Calendar className="w-6 h-6" />
                    <h3 className="text-lg font-bold text-gray-900">Schedule Interview</h3>
                </div>
                <p className="text-sm text-gray-600 mb-6 leading-relaxed">
                   You are accepting a request from <strong className="text-gray-900">{user?.fullName}</strong>. 
                   Please select a time slot for the interview.
                </p>
                <form onSubmit={handleAcceptRequest}>
                    <label className="block text-xs font-bold text-gray-500 uppercase mb-1.5 ml-1">Date & Time</label>
                    <input 
                        type="datetime-local" 
                        required
                        value={scheduleTime}
                        onChange={e => setScheduleTime(e.target.value)}
                        className="w-full border border-gray-300 rounded-xl p-3 mb-6 focus:ring-2 focus:ring-blue-500 outline-none transition-all bg-gray-50 focus:bg-white" 
                    />
                    <div className="flex gap-3">
                        <button type="button" onClick={() => setShowScheduleModal(false)} className="flex-1 py-3 text-gray-600 font-medium hover:bg-gray-100 rounded-xl transition-colors">Cancel</button>
                        <button type="submit" disabled={actionLoading} className="flex-1 py-3 bg-blue-600 text-white rounded-xl hover:bg-blue-700 font-bold flex justify-center items-center gap-2 shadow-lg shadow-blue-200 transition-all">
                            {actionLoading ? <Loader2 className="animate-spin w-4 h-4" /> : 'Confirm'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
      )}

    </div>
  );
}