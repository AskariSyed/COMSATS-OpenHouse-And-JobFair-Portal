import React, { useEffect, useState } from 'react';
import { ChevronRight, Mail, Loader2, MapPin, GraduationCap, Briefcase, Award, Github, Linkedin, Globe, Send, CheckCircle2, XCircle, Clock, Calendar, Phone, Play, Twitter, Facebook, Instagram, Briefcase as Portfolio } from 'lucide-react';
import { getStudentProfile, getFileUrl, sendInterviewRequest, acceptInterviewRequest, rejectInterviewRequest } from '../api';
import { getThumbnailUrl, getYoutubeId } from '../utils/videoUtils';

export default function StudentProfile({ studentId, onBack, onViewFYP }) {
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0);

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

  const { user, educations, experiences, projects, skills, contactLinks, certifications, achievements } = profile;

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

      {/* --- BALANCED 2-COLUMN LAYOUT --- */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
         
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
                        {edu.cgpa && <p className="text-xs text-gray-500">CGPA: <span className="font-semibold text-blue-600">{edu.cgpa.toFixed(2)}</span></p>}
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
                  {projects?.length > 0 ? projects.map(p => {
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



    </div>
  );
}