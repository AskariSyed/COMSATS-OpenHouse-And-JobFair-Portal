import React, { useEffect, useState } from 'react';
import { ChevronRight, Mail, Loader2, MapPin, GraduationCap, Briefcase, Award, Github, Linkedin, Globe, Send, CheckCircle2, XCircle, Clock, Calendar, Phone, Play, Twitter, Facebook, Instagram, Briefcase as Portfolio } from 'lucide-react';
import { getStudentProfile, getFileUrl, sendInterviewRequest, acceptInterviewRequest, rejectInterviewRequest, startInterview, startWalkInInterview, completeInterview } from '../api';
import { getThumbnailUrl, getYoutubeId } from '../utils/videoUtils';

const formatGradeValue = (value, digits = 2) => {
   const num = Number(value);
   if (!Number.isFinite(num)) return null;
   return Number.isInteger(num) ? String(num) : num.toFixed(digits);
};

const getEducationGradeLabel = (edu) => {
   if (!edu) return null;

   const type = String(edu.gradeType || '').trim().toLowerCase();
   const gradeValue = Number(edu.gradeValue);
   const cgpa = Number(edu.cgpa);
   const marksObtained = Number(edu.marksObtained);
   const totalMarks = Number(edu.totalMarks);

   if (type === 'percentage') {
      const raw = Number.isFinite(gradeValue)
         ? gradeValue
         : (Number.isFinite(cgpa) ? cgpa * 25 : NaN);
      const value = formatGradeValue(raw);
      return value ? `Percentage: ${value}%` : null;
   }

   if (type === 'marks') {
      if (Number.isFinite(marksObtained) && Number.isFinite(totalMarks) && totalMarks > 0) {
         return `Marks: ${formatGradeValue(marksObtained)}/${formatGradeValue(totalMarks)}`;
      }
      return null;
   }

   const cgpaValue = Number.isFinite(cgpa) ? cgpa : gradeValue;
   const value = formatGradeValue(cgpaValue);
   return value ? `CGPA: ${value}` : null;
};

export default function StudentProfile({
   studentId,
   onBack,
   onViewFYP,
   onNavigateToInterviews,
   readOnly = false,
   initialTab = 'profile',
   isJobFairDay = false,
   isCompanyPresent = false,
}) {
  const [profile, setProfile] = useState(null);
  const [activeTab, setActiveTab] = useState(initialTab);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
   const [interviewActionLoading, setInterviewActionLoading] = useState(false);
   const [endInterviewModal, setEndInterviewModal] = useState({
      open: false,
      interviewId: null,
      result: 'Hired'
   });
  const [refreshKey, setRefreshKey] = useState(0);

  useEffect(() => {
    if (!studentId) return;
    setLoading(true);
    getStudentProfile(studentId)
      .then(data => setProfile(data.student))
      .catch(err => console.error("Profile load error:", err))
      .finally(() => setLoading(false));
  }, [studentId, refreshKey]);

   const getCurrentInterviewFromProfile = (sourceProfile) => {
      if (!sourceProfile) {
         return { interviewId: null, status: '' };
      }

      const currentInterview = sourceProfile.CurrentInterview || sourceProfile.currentInterview || {};
      const interviewId =
         currentInterview?.InterviewId ||
         currentInterview?.interviewId ||
         sourceProfile.CurrentInterviewId ||
         sourceProfile.currentInterviewId ||
         null;
      const status = String(
         currentInterview?.Status ||
         currentInterview?.status ||
         sourceProfile.CurrentInterviewStatus ||
         sourceProfile.currentInterviewStatus ||
         ''
      ).toLowerCase();

      return { interviewId, status };
   };

  // --- ACTIONS ---
  const handleSendRequest = async () => {
    setActionLoading(true);
    try { await sendInterviewRequest(studentId); setRefreshKey(k => k + 1); } 
    catch (err) { alert(err.message); } 
    finally { setActionLoading(false); }
  };

  const handleAcceptRequest = async () => {
    const reqId = profile.interviewRequest?.requestId || profile.InterviewRequest?.RequestId;
    if (!reqId) return;
    if (!window.confirm("Accept this interview request?")) return;
    setActionLoading(true);
    try { await acceptInterviewRequest(reqId); setRefreshKey(k => k + 1); } 
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

   const handleStartCurrentInterview = async (interviewId) => {
      if (!interviewId) return;
      setInterviewActionLoading(true);
      try {
         await startInterview(interviewId);
         setRefreshKey(k => k + 1);
      } catch (err) {
         alert(err.message || 'Failed to start interview');
      } finally {
         setInterviewActionLoading(false);
      }
   };

   const handleEndCurrentInterview = async (interviewId) => {
      if (!interviewId) return;

      setEndInterviewModal({
         open: true,
         interviewId,
         result: 'Hired'
      });
   };

   const confirmEndCurrentInterview = async () => {
      const interviewId = endInterviewModal.interviewId;
      const selectedResult = endInterviewModal.result;
      if (!interviewId || !selectedResult) return;

      const allowed = ['Hired', 'Shortlisted', 'Rejected'];
      if (!allowed.includes(selectedResult)) return;

      setInterviewActionLoading(true);
      try {
         await completeInterview(interviewId, selectedResult);
         setEndInterviewModal({ open: false, interviewId: null, result: 'Hired' });
         setRefreshKey(k => k + 1);
      } catch (err) {
         alert(err.message || 'Failed to end interview');
      } finally {
         setInterviewActionLoading(false);
      }
   };

    const handleStartWalkInInterview = async () => {
         if (!studentId) return;

         if (!window.confirm('Are you really starting a walk in interview?')) {
            return;
         }

         setInterviewActionLoading(true);
         try {
            const result = await startWalkInInterview(studentId, false);
            const optimisticInterviewId = result?.InterviewId || result?.interviewId || null;
            const optimisticStartedAt = result?.StartedAt || result?.startedAt || new Date().toISOString();

            setProfile(prev => {
               if (!prev) return prev;
               const existing = prev.CurrentInterview || prev.currentInterview || {};
               return {
                  ...prev,
                  CurrentInterview: {
                     ...existing,
                     InterviewId: optimisticInterviewId || existing.InterviewId || existing.interviewId,
                     Status: 'InProgress',
                     StartedAt: optimisticStartedAt,
                     ScheduledTime: null
                  }
               };
            });
            setRefreshKey(k => k + 1);
         } catch (err) {
            const message = String(err?.message || '');
            const needsOverwrite = message.toLowerCase().includes('confirm overwrite') || message.toLowerCase().includes('requiresoverride');

            if (needsOverwrite) {
               const confirmOverwrite = window.confirm('A scheduled interview already exists. Overwrite it and start walk-in now?');
               if (confirmOverwrite) {
                  try {
                     const result = await startWalkInInterview(studentId, true);
                     const optimisticInterviewId = result?.InterviewId || result?.interviewId || null;
                     const optimisticStartedAt = result?.StartedAt || result?.startedAt || new Date().toISOString();

                     setProfile(prev => {
                        if (!prev) return prev;
                        const existing = prev.CurrentInterview || prev.currentInterview || {};
                        return {
                           ...prev,
                           CurrentInterview: {
                              ...existing,
                              InterviewId: optimisticInterviewId || existing.InterviewId || existing.interviewId,
                              Status: 'InProgress',
                              StartedAt: optimisticStartedAt,
                              ScheduledTime: null
                           }
                        };
                     });
                     setRefreshKey(k => k + 1);
                     return;
                  } catch (overwriteErr) {
                     alert(overwriteErr.message || 'Failed to overwrite scheduled interview');
                     return;
                  }
               }
               return;
            }

            alert(err.message || 'Failed to start walk-in interview');
         } finally {
            setInterviewActionLoading(false);
         }
    };

  // --- HEADER ACTION RENDERER ---
  const renderHeaderAction = () => {
    if (!profile) return null;

      if (readOnly) {
         return (
            <div className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-bold bg-gray-50 text-gray-600 border border-gray-200 cursor-default">
               Historical View (Read Only)
            </div>
         );
      }

      const canInterviewInCurrentFair = profile.canInterviewInCurrentFair ?? profile.CanInterviewInCurrentFair ?? true;
      if (!canInterviewInCurrentFair) {
         return (
            <div className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-bold bg-amber-50 text-amber-700 border border-amber-200 cursor-default">
               Join Current Fair to Invite
            </div>
         );
      }

    const req = profile.InterviewRequest || profile.interviewRequest || {};
    const hasRequest = req.HasRequest === true || req.hasRequest === true;
    const status = (req.Status || req.status || '').toLowerCase();
      const { interviewId: currentInterviewId, status: currentInterviewStatus } = getCurrentInterviewFromProfile(profile);
         const walkInInterviewEnabledNow = profile.walkInInterviewEnabledNow ?? profile.WalkInInterviewEnabledNow ?? false;
    const requestedByVal = req.RequestedBy !== undefined ? req.RequestedBy : req.requestedBy;
    const isStudentRequest = requestedByVal === 1 || requestedByVal === 'Student';

      if (currentInterviewId && currentInterviewStatus === 'inprogress') {
         return (
            <button
               onClick={() => handleEndCurrentInterview(currentInterviewId)}
               disabled={interviewActionLoading}
               className="flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-bold shadow-md bg-amber-600 hover:bg-amber-700 text-white transition-all transform hover:-translate-y-0.5 disabled:opacity-60"
            >
               {interviewActionLoading ? <Loader2 className="animate-spin w-4 h-4" /> : <><XCircle className="w-4 h-4" /> End Interview</>}
            </button>
         );
      }

      if (currentInterviewId && currentInterviewStatus === 'queued') {
         if (!(isJobFairDay && isCompanyPresent)) {
            return (
               <div className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-bold bg-yellow-50 text-yellow-800 border border-yellow-200 cursor-default">
                  <Calendar className="w-5 h-5" /> Interview Scheduled
               </div>
            );
         }

         return (
            <button
               onClick={() => handleStartCurrentInterview(currentInterviewId)}
               disabled={interviewActionLoading}
               className="flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-bold shadow-md bg-green-600 hover:bg-green-700 text-white transition-all transform hover:-translate-y-0.5 disabled:opacity-60"
            >
               {interviewActionLoading ? <Loader2 className="animate-spin w-4 h-4" /> : <><Play className="w-4 h-4" /> Start Interview</>}
            </button>
         );
      }

      if (currentInterviewStatus === 'hired') {
         return (
            <div className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-bold bg-emerald-50 text-emerald-700 border border-emerald-200 cursor-default">
               <CheckCircle2 className="w-5 h-5" /> Hired
            </div>
         );
      }

      if (currentInterviewStatus === 'shortlisted') {
         return (
            <div className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-bold bg-blue-50 text-blue-700 border border-blue-200 cursor-default">
               <CheckCircle2 className="w-5 h-5" /> Shortlisted
            </div>
         );
      }

      if (currentInterviewStatus === 'rejected') {
         return (
            <div className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-bold bg-red-50 text-red-600 border border-red-200 cursor-default">
               <XCircle className="w-5 h-5" /> Rejected
            </div>
         );
      }

    // 1. No Request -> "Send Request"
    if (!hasRequest) {
         return (
            <div className="flex items-center gap-2">
               <button onClick={handleSendRequest} disabled={actionLoading} className="flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-bold shadow-md bg-blue-600 hover:bg-blue-700 text-white transition-all transform hover:-translate-y-0.5">
                  {actionLoading ? <Loader2 className="animate-spin w-4 h-4" /> : <><Send className="w-4 h-4" /> Send Interview Request</>}
               </button>
               {walkInInterviewEnabledNow && (
                  <button
                     onClick={handleStartWalkInInterview}
                     disabled={interviewActionLoading}
                     className="flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-bold shadow-md bg-emerald-600 hover:bg-emerald-700 text-white transition-all transform hover:-translate-y-0.5 disabled:opacity-60"
                  >
                     {interviewActionLoading ? <Loader2 className="animate-spin w-4 h-4" /> : <><Play className="w-4 h-4" /> Start Walk-in Interview</>}
                  </button>
               )}
            </div>
         );
    }

    // 2. Scheduled -> Badge
    if (status === 'accepted') {
         if (!currentInterviewId) {
            return (
               <div className="flex items-center gap-2">
                  <button
                     onClick={() => onNavigateToInterviews && onNavigateToInterviews()}
                     className="flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-bold shadow-md bg-blue-600 hover:bg-blue-700 text-white transition-all transform hover:-translate-y-0.5"
                  >
                     <Calendar className="w-4 h-4" /> Schedule Interview
                  </button>
                  {walkInInterviewEnabledNow && (
                    <button
                      onClick={handleStartWalkInInterview}
                      disabled={interviewActionLoading}
                      className="flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-bold shadow-md bg-emerald-600 hover:bg-emerald-700 text-white transition-all transform hover:-translate-y-0.5 disabled:opacity-60"
                    >
                      {interviewActionLoading ? <Loader2 className="animate-spin w-4 h-4" /> : <><Play className="w-4 h-4" /> Start Walk-in Interview</>}
                    </button>
                  )}
               </div>
            );
         }

      return (
            <div className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-bold bg-green-50 text-green-700 border border-green-200 cursor-default">
               <CheckCircle2 className="w-5 h-5" /> Request Accepted
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
                <button onClick={handleAcceptRequest} disabled={actionLoading} className="flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-bold bg-green-600 hover:bg-green-700 text-white shadow-md transition-all transform hover:-translate-y-0.5">
                  <CheckCircle2 className="w-4 h-4" /> Accept Request
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
               <Clock className="w-5 h-5" /> Interview Requested
        </div>
      );
    }
    return null;
  };

  // --- RENDER ---
  if (!studentId) return <div className="text-center p-8 text-red-500">Error: No Student ID provided.</div>;
  if (loading) return <div className="h-96 flex items-center justify-center"><Loader2 className="animate-spin text-blue-600 w-8 h-8" /></div>;
  if (!profile) return <div className="text-center text-red-500 p-8">Failed to load profile.</div>;

   const { user, educations, experiences, projects, skills, contactLinks, certifications, achievements } = profile;
   const acceptedProjects = (projects || []).filter((p) => {
      const status = String(p.status || '').toLowerCase();
      return !status || status === 'accepted';
   });
   const latestEducation = [...(educations || [])]
      .sort((a, b) => new Date(b.endDate || b.startDate || 0) - new Date(a.endDate || a.startDate || 0))[0];
   const academicGradeLabel =
      getEducationGradeLabel(latestEducation) ||
      (Number.isFinite(Number(profile.cgpa)) ? `CGPA: ${Number(profile.cgpa).toFixed(2)}` : 'N/A');

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
                    <div className="text-base font-bold text-gray-900 leading-none">{academicGradeLabel}</div>
                    <div className="text-[10px] text-gray-400 uppercase font-bold tracking-wider">Academic Grade</div>
                 </div>
                 {renderHeaderAction()}
              </div>
           </div>

                <div className="ml-36 mt-2 flex flex-wrap gap-2">
                   {(() => {
                      const req = profile.InterviewRequest || profile.interviewRequest || {};
                      const reqStatus = String(req.Status || req.status || '').toLowerCase();
                      const { status: interviewStatus } = getCurrentInterviewFromProfile(profile);

                      return (
                         <>
                            {reqStatus === 'pending' && (
                               <span className="text-[11px] px-2 py-1 rounded-full bg-yellow-50 text-yellow-700 border border-yellow-200">Interview Requested</span>
                            )}
                            {interviewStatus === 'queued' && (
                               <span className="text-[11px] px-2 py-1 rounded-full bg-blue-50 text-blue-700 border border-blue-200">Interview Queued</span>
                            )}
                            {interviewStatus === 'inprogress' && (
                               <span className="text-[11px] px-2 py-1 rounded-full bg-purple-50 text-purple-700 border border-purple-200">Interview In Progress</span>
                            )}
                            {reqStatus === 'accepted' && !interviewStatus && (
                               <span className="text-[11px] px-2 py-1 rounded-full bg-green-50 text-green-700 border border-green-200">Accepted (Awaiting Schedule)</span>
                            )}
                            {interviewStatus === 'hired' && (
                               <span className="text-[11px] px-2 py-1 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200">Hired</span>
                            )}
                            {interviewStatus === 'shortlisted' && (
                               <span className="text-[11px] px-2 py-1 rounded-full bg-blue-50 text-blue-700 border border-blue-200">Shortlisted</span>
                            )}
                            {interviewStatus === 'rejected' && (
                               <span className="text-[11px] px-2 py-1 rounded-full bg-red-50 text-red-700 border border-red-200">Rejected</span>
                            )}
                         </>
                      );
                   })()}
                </div>

           {/* Contact & Links Bar */}
           <div className="mt-8 pt-6 border-t border-gray-100 flex flex-wrap justify-between gap-6">
              <div className="flex flex-wrap gap-6 text-sm text-gray-600">
                 {user?.email && <span className="flex items-center gap-2 hover:text-blue-600 transition-colors"><Mail className="w-4 h-4 text-gray-400" /> {user.email}</span>}
                 {user?.phone && <span className="flex items-center gap-2 hover:text-blue-600 transition-colors"><Phone className="w-4 h-4 text-gray-400" /> {user.phone}</span>}
                 <span className="flex items-center gap-2"><MapPin className="w-4 h-4 text-gray-400" /> Wah Campus</span>
                         {profile?.cvUrl && (
                            <a
                               href={getFileUrl(profile.cvUrl)}
                               target="_blank"
                               rel="noreferrer"
                               className="flex items-center gap-2 px-3 py-1.5 rounded-lg border border-gray-200 bg-white hover:bg-gray-50 text-gray-700"
                            >
                               <Calendar className="w-4 h-4 text-gray-400" /> Download CV
                            </a>
                         )}
              </div>
              
              <div className="flex gap-2">
                 {contactLinks?.map((link, i) => {
                   const platform = link.platform?.toLowerCase() || 'other';
                   let Icon = Globe;
                   let hoverColor = 'hover:text-blue-600';
                   
                   if (platform === 'linkedin') {
                     Icon = Linkedin;
                     hoverColor = 'hover:text-blue-700';
                   } else if (platform === 'github') {
                     Icon = Github;
                     hoverColor = 'hover:text-gray-900';
                   } else if (platform === 'portfolio') {
                     Icon = Portfolio;
                     hoverColor = 'hover:text-purple-600';
                   } else if (platform === 'twitter') {
                     Icon = Twitter;
                     hoverColor = 'hover:text-sky-500';
                   } else if (platform === 'facebook') {
                     Icon = Facebook;
                     hoverColor = 'hover:text-blue-600';
                   } else if (platform === 'instagram') {
                     Icon = Instagram;
                     hoverColor = 'hover:text-pink-600';
                   }
                   
                   return (
                     <a 
                       key={i} 
                       href={link.url} 
                       target="_blank" 
                       rel="noreferrer" 
                       className={`p-2 text-gray-400 ${hoverColor} hover:bg-blue-50 rounded-lg transition-all`}
                       title={link.platform}
                     >
                       <Icon className="w-4 h-4" />
                     </a>
                   );
                 })}
              </div>
           </div>
        </div>
      </div>

      {/* --- TABS NAVIGATION --- */}
      <div className="flex border-b border-gray-200 mb-6 sticky top-0 bg-gray-50/80 backdrop-blur-md z-10 pt-2">
         <button 
            onClick={() => setActiveTab('profile')}
            className={`px-6 py-3 text-sm font-bold border-b-2 transition-all ${activeTab === 'profile' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-400 hover:text-gray-600'}`}
         >
            Full Profile
         </button>
         <button 
            onClick={() => setActiveTab('interviews')}
            className={`px-6 py-3 text-sm font-bold border-b-2 transition-all flex items-center gap-2 ${activeTab === 'interviews' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-400 hover:text-gray-600'}`}
         >
            <Calendar className="w-4 h-4" /> Scheduled Interviews
         </button>
      </div>

      {/* --- TAB CONTENT --- */}
      {activeTab === 'profile' ? (
         <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 animate-fade-in">
            {/* LEFT COLUMN */}
            <div className="space-y-6">
            {/* Skills */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
               <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2 text-sm uppercase tracking-wider">
                  <Award className="w-4 h-4 text-blue-600" /> Skills
               </h3>
               <div className="flex flex-wrap gap-2">
                  {skills?.length > 0 ? skills.map((s, idx) => (
                     <span key={idx} className="bg-gray-50 border border-gray-200 text-gray-700 px-3 py-1.5 rounded-lg text-xs font-medium">
                        {s}
                     </span>
                  )) : <span className="text-gray-400 text-sm italic">No skills listed.</span>}
               </div>
            </div>

            {/* Education */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
               <h3 className="font-bold text-gray-900 border-b border-gray-100 pb-4 mb-6">Education</h3>
               <div className="space-y-6">
                  {educations?.length > 0 ? educations.map((edu, i) => (
                     <div key={i} className="space-y-2">
                        <div className="flex justify-between items-start gap-2">
                           <h4 className="font-bold text-gray-800">{edu.institutionName}</h4>
                           <span className="text-xs font-bold bg-blue-50 text-blue-700 px-2 py-1 rounded-full whitespace-nowrap">
                              {new Date(edu.startDate).getFullYear()} - {edu.isCurrent ? 'Present' : new Date(edu.endDate).getFullYear()}
                           </span>
                        </div>
                        <p className="text-sm text-gray-600">{edu.degree} in {edu.fieldOfStudy}</p>
                        {edu.location && <p className="text-xs text-gray-500">{edu.location}</p>}
                                    {getEducationGradeLabel(edu) && (
                                       <p className="text-xs text-gray-500">
                                          <span className="font-semibold text-blue-600">{getEducationGradeLabel(edu)}</span>
                                       </p>
                                    )}
                     </div>
                  )) : <div className="text-gray-400 italic">No education details.</div>}
               </div>
            </div>

            {/* Experience */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
               <h3 className="font-bold text-gray-900 border-b border-gray-100 pb-4 mb-6">
                  <Briefcase className="w-4 h-4 text-blue-600 inline mr-2" /> Experience
               </h3>
               <div className="space-y-6">
                  {experiences?.length > 0 ? experiences.map((exp, i) => (
                     <div key={i} className="relative pl-4 border-l-2 border-blue-100">
                        <div className="absolute -left-[5px] top-1.5 w-2.5 h-2.5 rounded-full bg-blue-500"></div>
                        <h4 className="font-bold text-sm text-gray-900">{exp.role}</h4>
                        <p className="text-sm text-gray-600 font-medium">{exp.companyName}</p>
                        {exp.location && <p className="text-xs text-gray-500">{exp.location}</p>}
                        <p className="text-xs text-gray-400 mt-1">
                           {new Date(exp.startDate).toLocaleDateString('en-US', { month: 'short', year: 'numeric' })} - {exp.isCurrent ? 'Present' : new Date(exp.endDate).toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}
                        </p>
                        {exp.description && <p className="text-xs text-gray-600 mt-2 leading-relaxed">{exp.description}</p>}
                     </div>
                  )) : <span className="text-gray-400 text-sm italic">No experience listed.</span>}
               </div>
            </div>

            {/* Certifications */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
               <h3 className="font-bold text-gray-900 border-b border-gray-100 pb-4 mb-6 flex items-center gap-2">
                  <Award className="w-5 h-5 text-blue-600" /> Certifications
               </h3>
               <div className="space-y-4">
                  {certifications?.length > 0 ? certifications.map((cert) => (
                     <div key={cert.certificationId} className="border border-gray-200 rounded-xl p-4 hover:border-blue-300 transition-all bg-blue-50/30">
                        <div className="flex justify-between items-start mb-2">
                           <h4 className="font-bold text-gray-900">{cert.title}</h4>
                           {cert.issueDate && (
                              <span className="text-xs text-gray-500 bg-white px-2 py-1 rounded-full whitespace-nowrap">
                                 {new Date(cert.issueDate).toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}
                              </span>
                           )}
                        </div>
                        {cert.issuer && (
                           <p className="text-sm text-gray-700 font-medium mb-1">{cert.issuer}</p>
                        )}
                        {cert.credentialId && (
                           <p className="text-xs text-gray-600 mb-2">ID: {cert.credentialId}</p>
                        )}
                        {cert.credentialUrl && (
                           <a href={cert.credentialUrl} target="_blank" rel="noreferrer" className="text-xs text-blue-600 hover:text-blue-700 flex items-center gap-1 font-medium">
                              View Certificate <Globe className="w-3 h-3" />
                           </a>
                        )}
                     </div>
                  )) : <div className="text-gray-400 italic">No certifications listed.</div>}
               </div>
            </div>
         </div>

         {/* RIGHT COLUMN */}
         <div className="space-y-6">
            {/* Projects */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
               <h3 className="font-bold text-gray-900 border-b border-gray-100 pb-4 mb-6">Projects</h3>
               <div className="space-y-4">
                  {acceptedProjects.length > 0 ? acceptedProjects.map(p => {
                     const isFYP = p.type?.toLowerCase() === 'finalyear';
                     const youtubeId = p.demoUrl ? getYoutubeId(p.demoUrl) : null;
                     const thumbnail = youtubeId ? getThumbnailUrl(p.demoUrl) : null;
                     
                     return (
                        <div 
                           key={p.projectId} 
                           className={`group bg-gradient-to-br from-blue-50 to-white border border-gray-200 p-5 rounded-xl hover:border-blue-300 transition-all hover:shadow-md ${
                              isFYP && onViewFYP ? 'cursor-pointer' : ''
                           }`}
                           onClick={() => isFYP && onViewFYP && onViewFYP(p.projectId)}
                        >
                           <div className="flex gap-4">
                              {/* YouTube Thumbnail - Left Side */}
                              {thumbnail && (
                                 <div className="relative w-32 flex-shrink-0 rounded-lg overflow-hidden group">
                                    <img 
                                       src={thumbnail} 
                                       alt={p.title}
                                       className="w-full h-full object-cover"
                                    />
                                    <div className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                                       <Play className="w-8 h-8 text-white" />
                                    </div>
                                 </div>
                              )}
                              
                              {/* Project Details - Right Side */}
                              <div className="flex-1 min-w-0">
                                 <div className="flex justify-between items-start mb-2">
                                    <h4 className="font-bold text-blue-700 group-hover:text-blue-800">{p.title}</h4>
                                    <span className="text-[10px] uppercase font-bold bg-white text-gray-700 px-2 py-1 rounded border border-gray-200 ml-2">{p.type}</span>
                                 </div>
                                 <p className="text-sm text-gray-600 leading-relaxed line-clamp-3">{p.description}</p>
                           
                                 {(p.demoUrl || p.gitHubUrl) && (
                                    <div className="flex gap-2 mt-3">
                                       {p.gitHubUrl && (
                                          <a 
                                             href={p.gitHubUrl} 
                                             target="_blank" 
                                             rel="noreferrer" 
                                             className="text-xs text-gray-600 hover:text-blue-600 flex items-center gap-1"
                                             onClick={(e) => e.stopPropagation()}
                                          >
                                             <Github className="w-3 h-3" /> GitHub
                                          </a>
                                       )}
                                       {p.demoUrl && !youtubeId && (
                                          <a 
                                             href={p.demoUrl} 
                                             target="_blank" 
                                             rel="noreferrer" 
                                             className="text-xs text-gray-600 hover:text-blue-600 flex items-center gap-1"
                                             onClick={(e) => e.stopPropagation()}
                                          >
                                             <Globe className="w-3 h-3" /> Demo
                                          </a>
                                       )}
                                    </div>
                                 )}
                           
                                 {isFYP && onViewFYP && (
                                    <div className="mt-3 pt-3 border-t border-gray-200">
                                       <span className="text-xs text-blue-600 font-medium flex items-center gap-1">
                                          Click to view full project details <ChevronRight className="w-3 h-3" />
                                       </span>
                                    </div>
                                 )}
                              </div>
                           </div>
                        </div>
                     );
                  }) : <div className="text-gray-400 italic">No projects listed.</div>}
               </div>
            </div>

            {/* Achievements */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
               <h3 className="font-bold text-gray-900 border-b border-gray-100 pb-4 mb-6 flex items-center gap-2">
                  <Award className="w-5 h-5 text-yellow-600" /> Achievements
               </h3>
               <div className="space-y-4">
                  {achievements?.length > 0 ? achievements.map((achievement) => (
                     <div key={achievement.achievementId} className="border border-gray-200 rounded-xl p-4 hover:border-yellow-300 transition-all bg-yellow-50/30">
                        <div className="flex justify-between items-start mb-2">
                           <h4 className="font-bold text-gray-900">{achievement.title}</h4>
                           {achievement.dateAchieved && (
                              <span className="text-xs text-gray-500 bg-white px-2 py-1 rounded-full whitespace-nowrap">
                                 {new Date(achievement.dateAchieved).toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}
                              </span>
                           )}
                        </div>
                        {achievement.description && (
                           <p className="text-sm text-gray-700 leading-relaxed">{achievement.description}</p>
                        )}
                     </div>
                  )) : <div className="text-gray-400 italic">No achievements listed.</div>}
               </div>
            </div>
            </div>
         </div>
      ) : (
         <div className="animate-fade-in space-y-6">
            <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-8 text-center">
               <div className="max-w-md mx-auto">
                  <div className="w-16 h-16 bg-blue-50 text-blue-600 rounded-full flex items-center justify-center mx-auto mb-4">
                     <Calendar className="w-8 h-8" />
                  </div>
                  <h3 className="text-xl font-bold text-gray-900 mb-2">Interview Status</h3>
                  
                  {(() => {
                     const { interviewId, status } = getCurrentInterviewFromProfile(profile);
                     const req = profile.InterviewRequest || profile.interviewRequest || {};
                     const reqStatus = String(req.Status || req.status || '').toLowerCase();

                     if (interviewId) {
                        const interview = profile.CurrentInterview || profile.currentInterview || {};
                        const scheduledTime = interview.ScheduledTime || interview.scheduledTime;
                        const startedAt = interview.StartedAt || interview.startedAt;
                        
                        return (
                           <div className="mt-6 p-6 rounded-2xl bg-gray-50 border border-gray-100 text-left">
                              <div className="flex justify-between items-start mb-6">
                                 <div>
                                    <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-1">Current Status</p>
                                    <div className="flex items-center gap-2">
                                       <span className={`px-3 py-1 rounded-full text-sm font-bold uppercase ${
                                          status === 'inprogress' ? 'bg-purple-100 text-purple-700' :
                                          status === 'queued' ? 'bg-blue-100 text-blue-700' :
                                          'bg-green-100 text-green-700'
                                       }`}>
                                          {status === 'inprogress' ? 'In Progress' : status === 'queued' ? 'Scheduled' : status}
                                       </span>
                                    </div>
                                 </div>
                                 {scheduledTime && (
                                    <div className="text-right">
                                       <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-1">Time</p>
                                       <p className="font-bold text-gray-900">{new Date(scheduledTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</p>
                                       <p className="text-[10px] text-gray-500">{new Date(scheduledTime).toLocaleDateString()}</p>
                                    </div>
                                 )}
                              </div>

                              <div className="space-y-4 pt-4 border-t border-gray-200">
                                 {startedAt && (
                                    <div className="flex justify-between text-sm">
                                       <span className="text-gray-500">Interview Started</span>
                                       <span className="font-medium text-gray-900">{new Date(startedAt).toLocaleTimeString()}</span>
                                    </div>
                                 )}
                                 <div className="flex justify-between text-sm">
                                    <span className="text-gray-500">Venue</span>
                                    <span className="font-medium text-gray-900">Assigned Interview Room</span>
                                 </div>
                              </div>

                              <div className="mt-8 flex justify-center">
                                 {renderHeaderAction()}
                              </div>
                           </div>
                        );
                     }

                     if (reqStatus === 'accepted') {
                        return (
                           <div className="mt-6">
                              <p className="text-gray-600 mb-6">The interview request was accepted, but it hasn't been scheduled into a specific time slot yet.</p>
                              <div className="flex justify-center">
                                 {renderHeaderAction()}
                              </div>
                           </div>
                        );
                     }

                     if (reqStatus === 'pending') {
                        return (
                           <div className="mt-6">
                              <p className="text-gray-600 mb-6">An interview request is currently pending student response.</p>
                              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-yellow-50 text-yellow-700 border border-yellow-200 font-bold text-sm">
                                 <Clock className="w-4 h-4" /> Awaiting Response
                              </div>
                           </div>
                        );
                     }

                     return (
                        <div className="mt-6">
                           <p className="text-gray-600 mb-6">No active interview or request found for this student.</p>
                           <div className="flex justify-center">
                              {renderHeaderAction()}
                           </div>
                        </div>
                     );
                  })()}
               </div>
            </div>
         </div>
      )}

      {endInterviewModal.open && (
         <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
            <div className="w-full max-w-md bg-white rounded-xl shadow-xl border border-gray-200 p-6">
               <h3 className="text-lg font-bold text-gray-900">End Interview</h3>
               <p className="text-sm text-gray-600 mt-1">Select final interview result.</p>

               <div className="mt-4">
                  <label className="block text-sm font-medium text-gray-700 mb-2">Result</label>
                  <select
                     value={endInterviewModal.result}
                     onChange={(e) => setEndInterviewModal(prev => ({ ...prev, result: e.target.value }))}
                     className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                     disabled={interviewActionLoading}
                  >
                     <option value="Hired">Hired</option>
                     <option value="Shortlisted">Shortlisted</option>
                     <option value="Rejected">Rejected</option>
                  </select>
               </div>

               <div className="mt-6 flex justify-end gap-3">
                  <button
                     onClick={() => setEndInterviewModal({ open: false, interviewId: null, result: 'Hired' })}
                     disabled={interviewActionLoading}
                     className="px-4 py-2 rounded-lg text-sm font-semibold bg-gray-100 hover:bg-gray-200 text-gray-700 disabled:opacity-60"
                  >
                     Cancel
                  </button>
                  <button
                     onClick={confirmEndCurrentInterview}
                     disabled={interviewActionLoading}
                     className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold bg-amber-600 hover:bg-amber-700 text-white disabled:opacity-60"
                  >
                     {interviewActionLoading ? <Loader2 className="animate-spin w-4 h-4" /> : <XCircle className="w-4 h-4" />}
                     Confirm End
                  </button>
               </div>
            </div>
         </div>
      )}



    </div>
  );
}