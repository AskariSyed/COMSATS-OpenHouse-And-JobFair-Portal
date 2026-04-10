/* eslint-disable react-hooks/set-state-in-effect */
/* eslint-disable no-unused-vars */
import React, { useEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { Building2, MapPin, Globe, Phone, Mail, User, Edit2, Plus, Trash2, Briefcase, Users, CheckCircle, Link as LinkIcon, X, Loader2, Save, Clock } from 'lucide-react';
import { getCompanyProfile, updateCompanyProfile, createJob, updateJob, deleteJob, addContactLink, deleteContactLink, getFileUrl, confirmAttendance, getConfirmationStatus, changePassword, getCompanyHistoricalAnalytics, copyJobToCurrentJobFair } from '../api';
import { allSkillsList } from '../../data/skills';

const PHONE_11_REGEX = /^\d{11}$/;
const STRONG_PASSWORD_REGEX = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$/;

export default function CompanyProfile({ onError, onSuccess, onProfileCompletionChange }) {
  const onErrorRef = useRef(onError);
  const onProfileCompletionChangeRef = useRef(onProfileCompletionChange);
  const autoOpenedIncompleteRef = useRef(false);
  const [profile, setProfile] = useState(null);
  const [attendance, setAttendance] = useState(null);
  const [loading, setLoading] = useState(true);
  const [confirming, setConfirming] = useState(false);
  const [refreshKey, setRefreshKey] = useState(0);

  // Modals
  const [profileEditSection, setProfileEditSection] = useState(null);
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [showJobModal, setShowJobModal] = useState(false);
  const [editingJob, setEditingJob] = useState(null);
  const [showImportJobsModal, setShowImportJobsModal] = useState(false);
  const [importHistoryData, setImportHistoryData] = useState(null);
  const [importHistoryLoading, setImportHistoryLoading] = useState(false);
  const [selectedImportJobFairId, setSelectedImportJobFairId] = useState('');
  const [importingJobId, setImportingJobId] = useState(null);

  useEffect(() => {
    onErrorRef.current = onError;
  }, [onError]);

  useEffect(() => {
    onProfileCompletionChangeRef.current = onProfileCompletionChange;
  }, [onProfileCompletionChange]);

  useEffect(() => {
    setLoading(true);
    Promise.all([
      getCompanyProfile(),
      getConfirmationStatus().catch(err => { console.warn("Attendance status fetch failed", err); return null; })
    ])
      .then(([profileData, attendanceData]) => {
        setProfile(profileData);
        setAttendance(attendanceData);

        if (onProfileCompletionChangeRef.current) {
          const completion = profileData?.profileCompletion || profileData?.ProfileCompletion || {};
          const isComplete = Boolean(completion.isComplete ?? completion.IsComplete ?? true);
          const missingFields = completion.missingFields || completion.MissingFields || [];
          onProfileCompletionChangeRef.current({ isComplete, missingFields });
        }
      })
      .catch(err => onErrorRef.current?.(err.message))
      .finally(() => setLoading(false));
  }, [refreshKey]);

  const contactInfo = profile?.contactInfo || {};
  const focalPerson = profile?.focalPerson || {};
  const interviewStats = profile?.interviewStats || {};
  const jobs = profile?.jobs || { jobs: [] };
  const interviewDurationMinutes = profile?.companySettings?.interviewDurationMinutes ?? profile?.companySettings?.InterviewDurationMinutes ?? 30;
  const repsCount = profile?.companySettings?.repsCount ?? profile?.companySettings?.RepsCount ?? 1;
  const isWalkInInterviewing = profile?.companySettings?.isWalkInInterviewing ?? profile?.companySettings?.IsWalkInInterviewing ?? false;
  const attendanceModel = attendance
    ? {
        isConfirmed: attendance.isConfirmed ?? attendance.IsConfirmed,
        arrivalStatus: attendance.arrivalStatus ?? attendance.ArrivalStatus,
        jobFairDate: attendance.jobFairDate ?? attendance.JobFairDate,
        roomAssigned: attendance.roomAssigned ?? attendance.RoomAssigned,
        roomDetails: (() => {
          const room = attendance.roomDetails ?? attendance.RoomDetails;
          if (!room) return null;
          return {
            roomName: room.roomName ?? room.RoomName,
            capacity: room.capacity ?? room.Capacity,
          };
        })(),
        confirmedAt: attendance.confirmedAt ?? attendance.ConfirmedAt,
        canConfirmAttendance: attendance.canConfirmAttendance ?? attendance.CanConfirmAttendance,
        daysUntilJobFair: attendance.daysUntilJobFair ?? attendance.DaysUntilJobFair,
      }
    : null;
  const profileCompletion = profile?.profileCompletion || profile?.ProfileCompletion || {};
  const isProfileComplete = profileCompletion.isComplete ?? profileCompletion.IsComplete ?? true;
  const missingProfileFields = profileCompletion.missingFields || profileCompletion.MissingFields || [];
  const isOnSpotRegistration = String(attendanceModel?.arrivalStatus || '').toLowerCase() === 'onspot';
  const incompleteFieldSet = new Set(missingProfileFields.map((field) => String(field || '').toLowerCase()));
  const shouldPromptInitialJobPost = !isProfileComplete && incompleteFieldSet.has('at least one job posting');

  const getAutoOpenTarget = () => {
    if (!isProfileComplete) {
      if (!contactInfo?.email || !contactInfo?.phone) return 'contact';
      if (incompleteFieldSet.has('company description')) return 'details';
      if (incompleteFieldSet.has('company logo')) return 'branding';
      if (incompleteFieldSet.has('expected interview duration')) return 'interview';
      if (incompleteFieldSet.has('at least one job posting')) return 'job';
      return 'details';
    }

    return null;
  };

  useEffect(() => {
    if (!profile || isProfileComplete) {
      autoOpenedIncompleteRef.current = false;
      return;
    }

    if (autoOpenedIncompleteRef.current) {
      return;
    }

    const nextTarget = getAutoOpenTarget();
    if (nextTarget === 'job') {
      setEditingJob(null);
      setShowJobModal(true);
    } else if (nextTarget) {
      setProfileEditSection(nextTarget);
    }

    autoOpenedIncompleteRef.current = true;
  }, [profile, isProfileComplete, contactInfo?.email, contactInfo?.phone, missingProfileFields.join('|')]);

  if (loading) return <div className="h-96 flex items-center justify-center"><Loader2 className="animate-spin w-8 h-8 text-blue-600" /></div>;
  if (!profile) return <div className="text-center p-12 text-red-500">Profile not found.</div>;

  // --- HANDLERS ---
  const handleConfirmAttendance = async () => {
    const canConfirm = attendance?.canConfirmAttendance ?? attendance?.CanConfirmAttendance;
    if (!canConfirm) {
      onError('Attendance confirmation is only allowed one or more days before the job fair date.');
      return;
    }

    if (!confirm("Are you sure you want to confirm your attendance? This will notify the administration.")) return;
    
    setConfirming(true);
    try {
      await confirmAttendance();
      setRefreshKey(k => k + 1);
      alert("Attendance confirmed successfully!");
    } catch (err) {
      onError(err.message || "Failed to confirm attendance");
    } finally {
      setConfirming(false);
    }
  };

  const handleLinkDelete = async (id) => {
    if(confirm('Remove this link?')) {
      try { await deleteContactLink(id); setRefreshKey(k => k+1); } catch(e) { onError(e.message); }
    }
  };

  const handleJobDelete = async (id) => {
    if(confirm('Delete this job posting?')) {
      try { await deleteJob(id); setRefreshKey(k => k+1); } catch(e) { onError(e.message); }
    }
  };

  const normalizeJobFairs = (data) => {
    const fairs = data?.jobFairs || data?.JobFairs || [];
    return fairs.map((fair) => ({
      jobFairId: fair.jobFairId || fair.JobFairId,
      jobFairName: fair.jobFairName || fair.JobFairName,
      jobFairDate: fair.jobFairDate || fair.JobFairDate,
      jobs: fair.jobs || fair.Jobs || [],
    }));
  };

  const handleOpenImportJobs = async () => {
    setShowImportJobsModal(true);
    setImportHistoryLoading(true);
    try {
      const data = await getCompanyHistoricalAnalytics();
      setImportHistoryData(data);
      const fairs = normalizeJobFairs(data);
      if (fairs.length > 0) {
        setSelectedImportJobFairId(String(fairs[0].jobFairId));
      } else {
        setSelectedImportJobFairId('');
      }
    } catch (err) {
      onError(err.message || 'Failed to load previous job fairs.');
      setShowImportJobsModal(false);
    } finally {
      setImportHistoryLoading(false);
    }
  };

  const handleImportJob = async (jobId) => {
    setImportingJobId(jobId);
    try {
      const result = await copyJobToCurrentJobFair(jobId);
      onSuccess?.(result?.message || 'Job imported to current job fair.');
      setRefreshKey(k => k + 1);
    } catch (err) {
      onError(err.message || 'Failed to import job.');
    } finally {
      setImportingJobId(null);
    }
  };

  const formattedJobFairDate = attendanceModel?.jobFairDate
    ? new Date(attendanceModel.jobFairDate).toLocaleDateString()
    : 'Date not announced';

  const daysUntilLabel =
    typeof attendanceModel?.daysUntilJobFair === 'number'
      ? attendanceModel.daysUntilJobFair === 0
        ? 'Today'
        : attendanceModel.daysUntilJobFair > 0
        ? `${attendanceModel.daysUntilJobFair} day${attendanceModel.daysUntilJobFair === 1 ? '' : 's'} until job fair`
        : 'Job fair date passed'
      : 'Days remaining unavailable';

  return (
    <div className="max-w-6xl mx-auto animate-fade-in pb-10">
      {!isProfileComplete && (
        <div className="mb-6 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-amber-900 shadow-sm">
          <p className="font-bold">Complete your company profile before moving forward.</p>
          {missingProfileFields.length > 0 && (
            <p className="mt-1 text-sm">
              Missing: {missingProfileFields.join(', ')}.
            </p>
          )}
        </div>
      )}
      
      {/* --- HEADER SECTION --- */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden mb-8">
        {/* Gradient Cover */}
        <div className="h-40 bg-gradient-to-r from-slate-900 via-slate-800 to-blue-900 relative">
           <button
             onClick={() => setShowPasswordModal(true)}
             className="absolute top-6 right-6 bg-white/10 hover:bg-white/20 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2 transition-colors backdrop-blur-sm"
           >
             Change Password
           </button>
        </div>

        <div className="px-8 pb-8 relative">
          {/* Logo (Overlapping) */}
          <div className="absolute -top-16 left-8 w-32 h-32 rounded-2xl p-1.5 bg-white shadow-lg">
            <div className="w-full h-full rounded-xl overflow-hidden bg-gray-50 border border-gray-100 flex items-center justify-center">
                {profile.logoUrl ? (
                    <img src={getFileUrl(profile.logoUrl)} className="w-full h-full object-contain" alt="Logo" />
                ) : (
                    <span className="text-4xl font-bold text-slate-300">{profile.name?.charAt(0)}</span>
                )}
            </div>
          </div>

          {/* Info Row */}
          <div className="ml-36 pt-3 min-h-[60px] flex flex-col justify-center">
             <div className="flex flex-wrap items-center gap-3">
               <h1 className="text-3xl font-bold text-gray-900">{profile.name}</h1>
               {attendanceModel?.isConfirmed && (
                 <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-700 border border-emerald-200">
                   <CheckCircle className="w-3.5 h-3.5" /> Participation Confirmed
                 </span>
               )}
               <button
                 onClick={() => setProfileEditSection('details')}
                 className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold rounded-lg border border-blue-200 text-blue-700 bg-blue-50 hover:bg-blue-100 transition-colors"
               >
                 <Edit2 className="w-3.5 h-3.5" /> Edit Details
               </button>
               <button
                 onClick={() => setProfileEditSection('branding')}
                 className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold rounded-lg border border-slate-200 text-slate-700 bg-slate-50 hover:bg-slate-100 transition-colors"
               >
                 <Edit2 className="w-3.5 h-3.5" /> Edit Logo
               </button>
             </div>
             <div className="flex flex-wrap gap-4 text-sm text-gray-500 mt-1">
               <span className="flex items-center gap-1.5"><Building2 className="w-4 h-4 text-blue-500"/> {profile.industry}</span>
               <span className="flex items-center gap-1.5"><MapPin className="w-4 h-4 text-blue-500"/> {profile.address}</span>
               {profile.website && (
                 <a href={profile.website} target="_blank" rel="noreferrer" className="flex items-center gap-1.5 text-blue-600 hover:underline">
                   <Globe className="w-4 h-4"/> Website
                 </a>
               )}
             </div>
               {profile.description && (
                 <p className="mt-2 text-sm text-gray-600 max-w-2xl">{profile.description}</p>
               )}
          </div>
        </div>
      </div>

      {/* --- STATS GRID --- */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
         <StatCard label="Active Jobs" value={jobs.jobs.length} icon={Briefcase} color="blue" />
         <StatCard label="Candidates" value={interviewStats.totalInterviews} icon={Users} color="purple" />
         <StatCard label="Hired" value={interviewStats.hiredCandidates} icon={CheckCircle} color="green" />
         <StatCard label="Pending Requests" value={interviewStats.pendingRequests} icon={Clock} color="orange" />
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* --- LEFT COLUMN: DETAILS --- */}
        <div className="space-y-6">
            {/* Attendance Card */}
            {attendanceModel && !attendanceModel.isConfirmed && !isOnSpotRegistration && (
              <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
                <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2 border-b border-gray-100 pb-3">
                  <CheckCircle className="w-5 h-5 text-blue-600" />
                  Job Fair Attendance
                </h3>
                
                <div className="space-y-4">
                  {!attendanceModel.isConfirmed && (
                    <div className="text-sm text-slate-700 bg-blue-50 border border-blue-200 rounded-lg px-3 py-2">
                      Do you confirm you will attend the job fair?
                    </div>
                  )}

                  <div className="bg-slate-50 border border-slate-200 rounded-lg p-3">
                    <div className="text-xs uppercase tracking-wide text-slate-500 font-semibold">Job Fair Date</div>
                    <div className="text-base font-bold text-slate-900 mt-1">{formattedJobFairDate}</div>
                    <div className="text-xs text-slate-600 mt-1">{daysUntilLabel}</div>
                  </div>

                  {!attendanceModel.isConfirmed && (
                    <button
                      onClick={handleConfirmAttendance}
                      disabled={confirming || !attendanceModel.canConfirmAttendance}
                      className="w-full py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed text-white rounded-lg font-medium transition-colors flex items-center justify-center gap-2"
                    >
                      {confirming ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Confirm Attendance'}
                    </button>
                  )}

                  {!attendanceModel.isConfirmed && !attendanceModel.canConfirmAttendance && (
                    <div className="text-xs text-amber-700 bg-amber-50 border border-amber-200 rounded p-2">
                      Attendance confirmation is available one or more days before the job fair.
                    </div>
                  )}
                </div>
              </div>
            )}

            {attendanceModel?.roomAssigned && attendanceModel?.roomDetails?.roomName && (
              <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
                <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2 border-b border-gray-100 pb-3">
                  <MapPin className="w-5 h-5 text-blue-600" />
                  Room Allocation
                </h3>
                <div className="bg-blue-50 p-3 rounded-lg border border-blue-200">
                  <div className="text-xs uppercase tracking-wide text-blue-700 font-semibold">Room</div>
                  <div className="text-lg font-bold text-blue-900 mt-1">{attendanceModel.roomDetails.roomName}</div>
                  <div className="text-xs text-blue-700 mt-1">Capacity: {attendanceModel.roomDetails.capacity}</div>
                </div>
              </div>
            )}

            {/* Contact Info */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
                <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2 border-b border-gray-100 pb-3">
                    <User className="w-5 h-5 text-blue-600" /> Focal Person
                </h3>
                <div className="space-y-3 text-sm">
                    <div>
                        <p className="text-gray-500 text-xs uppercase font-bold">Name</p>
                        <p className="font-medium text-gray-900">{focalPerson.name}</p>
                    </div>
                    <div>
                        <p className="text-gray-500 text-xs uppercase font-bold">Email</p>
                        <a href={`mailto:${focalPerson.email}`} className="text-blue-600 hover:underline">{focalPerson.email}</a>
                    </div>
                    <div>
                        <p className="text-gray-500 text-xs uppercase font-bold">Direct Phone</p>
                        <p className="text-gray-700">{focalPerson.phone}</p>
                    </div>
                </div>
            </div>

            {/* Official Contact */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
                <div className="flex items-center justify-between mb-4 border-b border-gray-100 pb-3">
                  <h3 className="font-bold text-gray-900 flex items-center gap-2">
                      <Phone className="w-5 h-5 text-blue-600" /> Official Contact
                  </h3>
                  <button
                    onClick={() => setProfileEditSection('contact')}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold rounded-lg border border-blue-200 text-blue-700 bg-blue-50 hover:bg-blue-100 transition-colors"
                  >
                    <Edit2 className="w-3.5 h-3.5" /> Edit
                  </button>
                </div>
                <div className="space-y-3 text-sm">
                    <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-blue-50 flex items-center justify-center text-blue-600"><Mail className="w-4 h-4"/></div>
                        <div className="overflow-hidden">
                            <p className="text-xs text-gray-500">Email</p>
                            <p className="font-medium text-gray-900 truncate">{contactInfo.email}</p>
                        </div>
                    </div>
                    <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-blue-50 flex items-center justify-center text-blue-600"><Phone className="w-4 h-4"/></div>
                        <div>
                            <p className="text-xs text-gray-500">Phone</p>
                            <p className="font-medium text-gray-900">{contactInfo.phone}</p>
                        </div>
                    </div>
                </div>
            </div>

            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
                <div className="flex items-center justify-between mb-4 border-b border-gray-100 pb-3">
                  <h3 className="font-bold text-gray-900 flex items-center gap-2">
                    <Clock className="w-5 h-5 text-blue-600" /> Interview Settings
                  </h3>
                  <button
                    onClick={() => setProfileEditSection('interview')}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold rounded-lg border border-blue-200 text-blue-700 bg-blue-50 hover:bg-blue-100 transition-colors"
                  >
                    <Edit2 className="w-3.5 h-3.5" /> Edit
                  </button>
                </div>
                <div className="text-sm">
                  <p className="text-xs uppercase tracking-wide text-gray-500 font-bold">Expected Interview Duration</p>
                  <p className="text-xl font-bold text-gray-900 mt-1">{interviewDurationMinutes} minutes</p>
                  <p className="text-xs uppercase tracking-wide text-gray-500 font-bold mt-4">Number of Representatives</p>
                  <p className="text-xl font-bold text-gray-900 mt-1">{repsCount}</p>
                  <p className="text-xs uppercase tracking-wide text-gray-500 font-bold mt-4">Walk-In Interviewing</p>
                  <p className={`text-base font-bold mt-1 ${isWalkInInterviewing ? 'text-emerald-700' : 'text-slate-700'}`}>
                    {isWalkInInterviewing ? 'Active' : 'Inactive'}
                  </p>
                </div>
            </div>

            {/* Social Links */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
                <div className="flex justify-between items-center mb-4 border-b border-gray-100 pb-3">
                    <h3 className="font-bold text-gray-900 flex items-center gap-2"><LinkIcon className="w-5 h-5 text-blue-600"/> Social Links</h3>
                    <AddLinkButton onAdd={async (link) => { try { await addContactLink(link); setRefreshKey(k=>k+1); } catch(e){ onError(e.message); } }} />
                </div>
                <div className="flex flex-wrap gap-2">
                    {profile.socialLinks.map(link => (
                        <div key={link.linkId} className="flex items-center gap-2 px-3 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-xs transition-colors hover:bg-gray-100">
                            <Globe className="w-3 h-3 text-gray-400"/>
                            <a href={link.url} target="_blank" rel="noreferrer" className="hover:text-blue-600 font-medium text-gray-700">{link.platform}</a>
                            <button onClick={() => handleLinkDelete(link.linkId)} className="text-gray-400 hover:text-red-500 ml-1"><X className="w-3 h-3"/></button>
                        </div>
                    ))}
                    {profile.socialLinks.length === 0 && <p className="text-sm text-gray-400 italic">No links added.</p>}
                </div>
            </div>
        </div>

        {/* --- RIGHT COLUMN: JOBS --- */}
        <div className="lg:col-span-2">
            <div className="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden">
                <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                    <div>
                        <h2 className="text-xl font-bold text-gray-900">Job Postings</h2>
                        <p className="text-sm text-gray-500">Manage your open positions</p>
                    </div>
                  <div className="flex items-center gap-2">
                    <button onClick={handleOpenImportJobs} className="flex items-center gap-2 px-4 py-2 bg-white text-slate-700 border border-slate-200 rounded-lg text-sm font-bold hover:bg-slate-50 transition-colors">
                    <Briefcase className="w-4 h-4" /> Import From Previous Fair
                    </button>
                    <button onClick={() => { setEditingJob(null); setShowJobModal(true); }} className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-bold hover:bg-blue-700 shadow-md transition-all transform hover:-translate-y-0.5">
                      <Plus className="w-4 h-4" /> Post Job
                    </button>
                  </div>
                </div>
                
                <div className="p-6 space-y-4">
                    {jobs.jobs.length === 0 ? (
                        <div className="text-center py-12 border-2 border-dashed border-gray-200 rounded-xl">
                            <Briefcase className="w-12 h-12 mx-auto mb-3 text-gray-300" />
                            <p className="text-gray-500 font-medium">No active job postings.</p>
                            <p className="text-sm text-gray-400">Create a job to start recruiting.</p>
                        </div>
                    ) : (
                        jobs.jobs.map(job => (
                            <div key={job.jobId} className="group bg-white border border-gray-200 rounded-xl p-5 hover:shadow-md hover:border-blue-300 transition-all relative">
                                <div className="flex justify-between items-start mb-2">
                                    <div>
                                        <h3 className="font-bold text-lg text-gray-900 group-hover:text-blue-600 transition-colors">{job.jobTitle}</h3>
                                        <div className="flex gap-2 mt-1">
                                            <span className="text-[10px] font-bold bg-blue-50 text-blue-700 px-2 py-0.5 rounded border border-blue-100 uppercase tracking-wide">
                                                {['Full Time','Internship','Part Time'][job.jobType]}
                                            </span>
                                            <span className="text-[10px] font-bold bg-gray-100 text-gray-600 px-2 py-0.5 rounded border border-gray-200">
                                                {job.numberOfJobs} Openings
                                            </span>
                                        </div>
                                    </div>
                                    <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                        <button onClick={() => { setEditingJob(job); setShowJobModal(true); }} className="p-2 hover:bg-gray-100 rounded-lg text-gray-500 hover:text-blue-600 transition-colors"><Edit2 className="w-4 h-4"/></button>
                                        <button onClick={() => handleJobDelete(job.jobId)} className="p-2 hover:bg-red-50 rounded-lg text-gray-500 hover:text-red-600 transition-colors"><Trash2 className="w-4 h-4"/></button>
                                    </div>
                                </div>
                                
                                <p className="text-sm text-gray-600 line-clamp-2 mb-3 leading-relaxed">{job.jobDescription}</p>
                                
                                <div className="flex flex-wrap gap-1.5">
                                    {job.requiredSkills?.slice(0, 4).map((s, i) => (
                                        <span key={i} className="text-xs bg-gray-50 text-gray-700 border border-gray-200 px-2 py-1 rounded-md font-medium">{s}</span>
                                    ))}
                                    {job.requiredSkills?.length > 4 && <span className="text-xs text-gray-400 flex items-center px-1">+{job.requiredSkills.length-4}</span>}
                                </div>
                            </div>
                        ))
                    )}
                </div>
            </div>
        </div>

      </div>

      {/* --- MODALS --- */}
      {profileEditSection && (
        <ProfileModal
          profile={profile}
          section={profileEditSection}
          onClose={() => setProfileEditSection(null)}
          onSave={async () => {
            setRefreshKey(k => k+1);
            setProfileEditSection(null);
            if (shouldPromptInitialJobPost) {
              setEditingJob(null);
              setShowJobModal(true);
            }
          }}
          onError={onError}
        />
      )}
      {showPasswordModal && <PasswordModal onClose={() => setShowPasswordModal(false)} onError={onError} />}
      
      {showJobModal && <JobModal job={editingJob} onClose={() => setShowJobModal(false)} onSave={async () => { setRefreshKey(k => k+1); setShowJobModal(false); }} onError={onError} />}

      {showImportJobsModal && (
        <ImportJobsModal
          loading={importHistoryLoading}
          data={importHistoryData}
          selectedJobFairId={selectedImportJobFairId}
          onSelectJobFair={setSelectedImportJobFairId}
          importingJobId={importingJobId}
          onImportJob={handleImportJob}
          onClose={() => {
            setShowImportJobsModal(false);
            setImportHistoryData(null);
            setSelectedImportJobFairId('');
            setImportingJobId(null);
          }}
        />
      )}

    </div>
  );
}

// --- SUB-COMPONENTS ---

function StatCard({ label, value, icon: Icon, color }) {
  const colors = { blue: 'bg-blue-50 text-blue-600', purple: 'bg-purple-50 text-purple-600', green: 'bg-green-50 text-green-600', orange: 'bg-orange-50 text-orange-600' };
  return (
    <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-sm flex items-center gap-4 hover:shadow-md transition-shadow">
      <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${colors[color]}`}><Icon className="w-6 h-6"/></div>
      <div><div className="text-2xl font-bold text-gray-900 leading-none mb-1">{value}</div><div className="text-xs text-gray-500 uppercase font-bold tracking-wide">{label}</div></div>
    </div>
  );
}

function ModalPortal({ children }) {
  if (typeof document === 'undefined') return null;
  return createPortal(children, document.body);
}

function ImportJobsModal({ loading, data, selectedJobFairId, onSelectJobFair, importingJobId, onImportJob, onClose }) {
  const fairs = (data?.jobFairs || data?.JobFairs || []).map((fair) => ({
    jobFairId: fair.jobFairId || fair.JobFairId,
    jobFairName: fair.jobFairName || fair.JobFairName,
    jobFairDate: fair.jobFairDate || fair.JobFairDate,
    jobs: fair.jobs || fair.Jobs || [],
  }));

  const selectedFair = fairs.find((fair) => String(fair.jobFairId) === String(selectedJobFairId));
  const jobs = selectedFair?.jobs || [];

  return (
    <ModalPortal>
      <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
        <div className="bg-white rounded-2xl shadow-2xl w-full max-w-3xl overflow-hidden animate-fade-in-down">
        <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
          <h3 className="text-lg font-bold text-gray-900">Import Jobs From Previous Job Fair</h3>
          <button onClick={onClose}><X className="w-5 h-5 text-gray-400 hover:text-gray-600"/></button>
        </div>

        <div className="p-6 space-y-4">
          {loading ? (
            <div className="h-40 flex items-center justify-center">
              <Loader2 className="animate-spin w-7 h-7 text-blue-600" />
            </div>
          ) : fairs.length === 0 ? (
            <div className="text-center py-12 border border-dashed border-gray-300 rounded-xl text-gray-500">
              No previous job fair data found.
            </div>
          ) : (
            <>
              <div>
                <label className="block text-xs font-bold text-gray-500 uppercase mb-1.5">Select Previous Job Fair</label>
                <select
                  className="w-full border border-gray-300 rounded-lg p-2.5 text-sm outline-none focus:border-blue-500 bg-white"
                  value={selectedJobFairId}
                  onChange={(e) => onSelectJobFair(e.target.value)}
                >
                  {fairs.map((fair) => (
                    <option key={fair.jobFairId} value={fair.jobFairId}>
                      {fair.jobFairName} ({new Date(fair.jobFairDate).toLocaleDateString()})
                    </option>
                  ))}
                </select>
              </div>

              <div className="space-y-3 max-h-96 overflow-y-auto pr-1">
                {jobs.length === 0 ? (
                  <div className="text-center py-10 border border-dashed border-gray-300 rounded-xl text-gray-500">
                    No jobs found in this job fair.
                  </div>
                ) : (
                  jobs.map((job) => (
                    <div key={job.jobId || job.JobId} className="border border-gray-200 rounded-xl p-4 flex items-start justify-between gap-4">
                      <div>
                        <h4 className="font-semibold text-gray-900">{job.jobTitle || job.JobTitle}</h4>
                        <p className="text-sm text-gray-600 mt-1 line-clamp-2">{job.jobDescription || job.JobDescription}</p>
                        <div className="mt-2 text-xs text-gray-500">Openings: {job.numberOfJobs || job.NumberOfJobs || 0}</div>
                      </div>
                      <button
                        onClick={() => onImportJob(job.jobId || job.JobId)}
                        disabled={importingJobId === (job.jobId || job.JobId)}
                        className="shrink-0 px-3 py-2 rounded-lg text-sm font-semibold bg-blue-600 text-white hover:bg-blue-700 disabled:bg-blue-300 flex items-center gap-2"
                      >
                        {importingJobId === (job.jobId || job.JobId) ? <Loader2 className="w-4 h-4 animate-spin" /> : null}
                        Import
                      </button>
                    </div>
                  ))
                )}
              </div>
            </>
          )}
        </div>
        </div>
      </div>
    </ModalPortal>
  );
}

function AddLinkButton({ onAdd }) {
  const [isOpen, setIsOpen] = useState(false);
  const [data, setData] = useState({ platform: 0, url: '' });
  
  const handleSubmit = () => {
    if(data.url) { onAdd(data); setIsOpen(false); setData({ platform: 0, url: '' }); }
  };

  if(!isOpen) return <button onClick={() => setIsOpen(true)} className="text-xs bg-blue-50 text-blue-600 px-2 py-1 rounded-lg font-bold hover:bg-blue-100 transition-colors flex items-center gap-1"><Plus className="w-3 h-3"/> Add Link</button>;

  return (
    <div className="flex items-center gap-2 animate-fade-in bg-white border border-gray-200 rounded-lg p-1.5 absolute right-6 z-10 shadow-xl">
       <select className="text-xs border border-gray-300 rounded p-1.5 outline-none focus:border-blue-500 bg-white" value={data.platform} onChange={e => setData({...data, platform: parseInt(e.target.value)})}>
         <option value={0}>LinkedIn</option>
         <option value={1}>Website</option>
         <option value={2}>Twitter</option>
         <option value={3}>Facebook</option>
         <option value={4}>Instagram</option>
         <option value={5}>Other</option>
       </select>
       <input className="text-xs border border-gray-300 rounded p-1.5 w-32 outline-none focus:border-blue-500" placeholder="https://..." value={data.url} onChange={e => setData({...data, url: e.target.value})} />
       <button onClick={handleSubmit} className="bg-green-500 text-white p-1.5 rounded hover:bg-green-600"><CheckCircle className="w-3 h-3"/></button>
       <button onClick={() => setIsOpen(false)} className="text-red-400 hover:text-red-600 p-1"><X className="w-3 h-3"/></button>
    </div>
  );
}

function ProfileModal({ profile, section, onClose, onSave, onError }) {
  const socialPlatformOptions = [
    { platform: 0, label: 'LinkedIn' },
    { platform: 1, label: 'Website' },
    { platform: 2, label: 'Twitter' },
    { platform: 3, label: 'Facebook' },
    { platform: 4, label: 'Instagram' },
  ];
  const [formData, setFormData] = useState({
    ...profile,
    description: profile?.description || '',
    interviewDurationMinutes: profile?.companySettings?.interviewDurationMinutes ?? profile?.companySettings?.InterviewDurationMinutes ?? 30,
    repsCount: profile?.companySettings?.repsCount ?? profile?.companySettings?.RepsCount ?? 1,
    Logo: null
  });
  const [initialSocialLinks, setInitialSocialLinks] = useState(
    socialPlatformOptions.map((option) => ({ ...option, url: '' }))
  );
  const [loading, setLoading] = useState(false);

  const modalTitleMap = {
    details: 'Add Company Details',
    contact: 'Edit Official Contact',
    interview: 'Edit Interview Settings',
    branding: 'Add Company Logo'
  };

  const detailsAreAlreadyFilled = Boolean(
    profile?.description ||
    profile?.website ||
    profile?.address
  );
  const showDetails = section === 'details';
  const showContact = section === 'contact';
  const showInterview = section === 'interview';
  const showBranding = section === 'branding';
  const isFirstTimeDetailsSetup = showDetails && !detailsAreAlreadyFilled;
  const hasLogoAlready = Boolean(profile?.logoUrl);
  const title = section === 'details' && detailsAreAlreadyFilled
    ? 'Edit Company Details'
    : section === 'branding' && hasLogoAlready
      ? 'Update Company Logo'
      : modalTitleMap[section] || 'Edit Company Profile';

  const handleSubmit = async (e) => {
    e.preventDefault();
    if ((formData.description || '').length > 500) {
      onError('Description cannot exceed 500 characters.');
      return;
    }
    const duration = Number(formData.interviewDurationMinutes || 30);
    if (duration < 5 || duration > 240) {
      onError('Interview duration must be between 5 and 240 minutes.');
      return;
    }
    const reps = Number(formData.repsCount || 1);
    if (reps < 1 || reps > 100) {
      onError('Representatives must be between 1 and 100.');
      return;
    }
    if (!PHONE_11_REGEX.test(String(formData.contactInfo.phone || '').trim())) {
      onError('Official phone must be exactly 11 digits.');
      return;
    }
    if (formData.Logo && !(formData.Logo.type || '').startsWith('image/')) {
      onError('Logo must be an image file (PNG/JPG/JPEG/WEBP).');
      return;
    }

    if (isFirstTimeDetailsSetup) {
      const invalidLink = initialSocialLinks.find((link) => {
        const url = String(link.url || '').trim();
        if (!url) return false;
        try {
          const parsed = new URL(url);
          return parsed.protocol !== 'http:' && parsed.protocol !== 'https:';
        } catch {
          return true;
        }
      });

      if (invalidLink) {
        onError(`Please enter a valid URL for ${invalidLink.label}.`);
        return;
      }
    }

    setLoading(true);
    try {
      const data = new FormData();
      data.append('CompanyEmail', formData.contactInfo.email);
      data.append('CompanyPhone', formData.contactInfo.phone);
      data.append('Website', formData.website || '');
      data.append('Address', formData.address);
      data.append('Description', formData.description || '');
      data.append('InterviewDurationMinutes', String(formData.interviewDurationMinutes || 30));
      data.append('RepsCount', String(formData.repsCount || 1));
      if(formData.Logo) data.append('Logo', formData.Logo);
      
      await updateCompanyProfile(data);

      if (isFirstTimeDetailsSetup) {
        const linksToAdd = initialSocialLinks
          .map((link) => ({
            platform: link.platform,
            url: String(link.url || '').trim()
          }))
          .filter((link) => Boolean(link.url));

        for (const link of linksToAdd) {
          await addContactLink(link);
        }
      }

      onSave();
    } catch (err) { onError(err.message); } finally { setLoading(false); }
  };

  return (
    <ModalPortal>
      <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-3 sm:p-4 backdrop-blur-sm overflow-y-auto">
        <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden animate-fade-in-down my-2 sm:my-6 max-h-[calc(100vh-1rem)] sm:max-h-[calc(100vh-3rem)] flex flex-col">
        <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/50 shrink-0">
           <h3 className="text-lg font-bold text-gray-900">{title}</h3>
           <button onClick={onClose}><X className="w-5 h-5 text-gray-400 hover:text-gray-600"/></button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-5 overflow-y-auto">
           {showContact && (
             <>
               <Input label="Official Email" value={formData.contactInfo.email} onChange={e => setFormData({...formData, contactInfo: {...formData.contactInfo, email: e.target.value}})} />
               <Input
                 label="Official Phone"
                 value={formData.contactInfo.phone}
                 onChange={e => setFormData({...formData, contactInfo: {...formData.contactInfo, phone: e.target.value.replace(/\D/g, '').slice(0, 11)}})}
                 type="tel"
                 inputMode="numeric"
                 maxLength={11}
                 pattern="\d{11}"
               />
             </>
           )}

           {showDetails && (
             <>
               <Input label="Website URL" value={formData.website} onChange={e => setFormData({...formData, website: e.target.value})} />
               <Input label="Headquarters Address" value={formData.address} onChange={e => setFormData({...formData, address: e.target.value})} />
               <div>
                 <div className="flex items-center justify-between mb-1.5">
                   <label className="block text-xs font-bold text-gray-500 uppercase">Company Description</label>
                   <span className={`text-xs font-semibold ${(formData.description || '').length > 500 ? 'text-red-600' : 'text-gray-500'}`}>
                     {(formData.description || '').length}/500
                   </span>
                 </div>
                 <textarea
                   className="w-full border border-gray-300 rounded-lg p-3 outline-none focus:ring-2 focus:ring-blue-500 transition-all h-28 resize-none"
                   value={formData.description || ''}
                   maxLength={500}
                   onChange={e => setFormData({...formData, description: e.target.value.slice(0, 500)})}
                   placeholder="Write a short company description"
                 />
               </div>

               {isFirstTimeDetailsSetup && (
                 <>
                   <Input
                     label="Expected Interview Time (minutes)"
                     type="number"
                     min="5"
                     max="240"
                     value={formData.interviewDurationMinutes}
                     onChange={e => setFormData({...formData, interviewDurationMinutes: Number(e.target.value)})}
                   />
                   <Input
                     label="Number of Representatives"
                     type="number"
                     min="1"
                     max="100"
                     value={formData.repsCount}
                     onChange={e => setFormData({...formData, repsCount: Number(e.target.value)})}
                   />
                   <div className="pt-2">
                     <label className="block text-xs font-bold text-gray-500 uppercase mb-2">Upload Company Logo</label>
                     <div className="flex items-center justify-center w-full">
                       <label className="flex flex-col items-center justify-center w-full h-32 border-2 border-gray-300 border-dashed rounded-lg cursor-pointer bg-gray-50 hover:bg-gray-100 transition-colors">
                         <div className="flex flex-col items-center justify-center pt-5 pb-6">
                           <p className="mb-2 text-sm text-gray-500"><span className="font-semibold">Click to upload</span> or drag and drop</p>
                           <p className="text-xs text-gray-500">PNG, JPG (MAX. 2MB)</p>
                           {formData.Logo && <p className="mt-2 text-sm text-blue-600 font-bold">{formData.Logo.name}</p>}
                         </div>
                         <input
                           type="file"
                           accept="image/*"
                           className="hidden"
                           onChange={e => {
                             const selected = e.target.files?.[0] || null;
                             if (selected && !(selected.type || '').startsWith('image/')) {
                               onError('Please select an image file only.');
                               e.target.value = '';
                               return;
                             }
                             setFormData({...formData, Logo: selected});
                           }}
                         />
                       </label>
                     </div>
                   </div>

                   <div className="pt-2">
                     <label className="block text-xs font-bold text-gray-500 uppercase mb-2">Social Links (Optional)</label>
                     <div className="space-y-3">
                       {initialSocialLinks.map((link, idx) => (
                         <div key={link.platform}>
                           <label className="block text-xs font-semibold text-gray-600 mb-1">{link.label}</label>
                           <input
                             type="url"
                             placeholder={`https://${link.label.toLowerCase()}.com/...`}
                             value={link.url}
                             onChange={(e) => {
                               const next = [...initialSocialLinks];
                               next[idx] = { ...next[idx], url: e.target.value };
                               setInitialSocialLinks(next);
                             }}
                             className="w-full border border-gray-300 rounded-lg p-2.5 outline-none focus:ring-2 focus:ring-blue-500"
                           />
                         </div>
                       ))}
                     </div>
                   </div>
                 </>
               )}
             </>
           )}

           {showInterview && (
             <>
               <Input
                 label="Expected Interview Time (minutes)"
                 type="number"
                 min="5"
                 max="240"
                 value={formData.interviewDurationMinutes}
                 onChange={e => setFormData({...formData, interviewDurationMinutes: Number(e.target.value)})}
               />
               <Input
                 label="Number of Representatives"
                 type="number"
                 min="1"
                 max="100"
                 value={formData.repsCount}
                 onChange={e => setFormData({...formData, repsCount: Number(e.target.value)})}
               />
             </>
           )}
           
           {showBranding && <div className="pt-2">
              <label className="block text-xs font-bold text-gray-500 uppercase mb-2">Update Logo</label>
              <div className="flex items-center justify-center w-full">
                  <label className="flex flex-col items-center justify-center w-full h-32 border-2 border-gray-300 border-dashed rounded-lg cursor-pointer bg-gray-50 hover:bg-gray-100 transition-colors">
                      <div className="flex flex-col items-center justify-center pt-5 pb-6">
                          <p className="mb-2 text-sm text-gray-500"><span className="font-semibold">Click to upload</span> or drag and drop</p>
                          <p className="text-xs text-gray-500">PNG, JPG (MAX. 2MB)</p>
                          {formData.Logo && <p className="mt-2 text-sm text-blue-600 font-bold">{formData.Logo.name}</p>}
                      </div>
                      <input
                        type="file"
                        accept="image/*"
                        className="hidden"
                        onChange={e => {
                          const selected = e.target.files?.[0] || null;
                          if (selected && !(selected.type || '').startsWith('image/')) {
                            onError('Please select an image file only.');
                            e.target.value = '';
                            return;
                          }
                          setFormData({...formData, Logo: selected});
                        }}
                      />
                  </label>
              </div> 
                   </div>}

            <div className="pt-4 flex gap-3 sticky bottom-0 bg-white">
              <button type="button" onClick={onClose} className="flex-1 py-3 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-xl font-bold transition-colors">Cancel</button>
              <button disabled={loading} className="flex-1 py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 flex justify-center gap-2 transition-colors shadow-lg shadow-blue-200">
                 {loading ? <Loader2 className="animate-spin w-5 h-5"/> : 'Save Changes'}
              </button>
           </div>
        </form>
        </div>
      </div>
    </ModalPortal>
  );
}

function PasswordModal({ onClose, onError }) {
  const [form, setForm] = useState({ currentPassword: '', newPassword: '', confirmPassword: '' });
  const [errors, setErrors] = useState({});
  const [loading, setLoading] = useState(false);

  const validate = () => {
    const nextErrors = {};
    if (!form.currentPassword.trim()) {
      nextErrors.currentPassword = 'Current password is required';
    }
    if (!form.newPassword) {
      nextErrors.newPassword = 'New password is required';
    } else if (!STRONG_PASSWORD_REGEX.test(form.newPassword)) {
      nextErrors.newPassword = 'Use 8+ chars with uppercase, lowercase, number, and special character';
    }
    if (!form.confirmPassword) {
      nextErrors.confirmPassword = 'Confirm password is required';
    } else if (form.confirmPassword !== form.newPassword) {
      nextErrors.confirmPassword = 'Passwords do not match';
    }
    if (form.currentPassword && form.newPassword && form.currentPassword === form.newPassword) {
      nextErrors.newPassword = 'New password must be different from current password';
    }
    setErrors(nextErrors);
    return Object.keys(nextErrors).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate()) return;
    setLoading(true);
    try {
      await changePassword(form.currentPassword, form.newPassword, form.confirmPassword);
      alert('Password changed successfully');
      onClose();
    } catch (err) {
      onError(err.message || 'Failed to change password');
    } finally {
      setLoading(false);
    }
  };

  return (
    <ModalPortal>
      <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
        <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden animate-fade-in-down">
        <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
           <h3 className="text-lg font-bold text-gray-900">Change Password</h3>
           <button onClick={onClose}><X className="w-5 h-5 text-gray-400 hover:text-gray-600"/></button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <Input label="Current Password" type="password" value={form.currentPassword} onChange={e => { setForm({ ...form, currentPassword: e.target.value }); setErrors({ ...errors, currentPassword: undefined }); }} />
            {errors.currentPassword && <p className="mt-1 text-xs text-red-600">{errors.currentPassword}</p>}
          </div>
          <div>
            <Input label="New Password" type="password" value={form.newPassword} onChange={e => { setForm({ ...form, newPassword: e.target.value }); setErrors({ ...errors, newPassword: undefined }); }} />
            {errors.newPassword && <p className="mt-1 text-xs text-red-600">{errors.newPassword}</p>}
          </div>
          <div>
            <Input label="Confirm Password" type="password" value={form.confirmPassword} onChange={e => { setForm({ ...form, confirmPassword: e.target.value }); setErrors({ ...errors, confirmPassword: undefined }); }} />
            {errors.confirmPassword && <p className="mt-1 text-xs text-red-600">{errors.confirmPassword}</p>}
          </div>
          <div className="pt-3 flex gap-3">
            <button type="button" onClick={onClose} className="flex-1 py-3 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-xl font-bold transition-colors">Cancel</button>
            <button disabled={loading} className="flex-1 py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 flex justify-center gap-2 transition-colors shadow-lg shadow-blue-200">
              {loading ? <Loader2 className="animate-spin w-5 h-5"/> : 'Update Password'}
            </button>
          </div>
        </form>
        </div>
      </div>
    </ModalPortal>
  );
}

function JobModal({ job, onClose, onSave, onError }) {
  const [formData, setFormData] = useState(job || { JobTitle: '', JobDescription: '', JobCount: 1, JobType: 0, RequiredSkills: [] });
  const [skillInput, setSkillInput] = useState('');
  const [selectedSkill, setSelectedSkill] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const payload = {
         JobTitle: formData.JobTitle || formData.jobTitle,
         JobDescription: formData.JobDescription || formData.jobDescription,
         NumberOfJobs: formData.NumberOfJobs || formData.numberOfJobs || 1,
         JobType: formData.JobType || formData.jobType || 0,
         RequiredSkills: formData.RequiredSkills || formData.requiredSkills || []
      };
      
      if (job) await updateJob(job.jobId, payload);
      else await createJob(payload);
      
      onSave();
    } catch (err) { onError(err.message); } finally { setLoading(false); }
  };

  const addSkill = (e) => {
    e.preventDefault();
     const manualSkill = skillInput.trim();
     const dropdownSkill = selectedSkill.trim();
     const skillToAdd = manualSkill || dropdownSkill;
     if (skillToAdd) {
       const skills = formData.RequiredSkills || formData.requiredSkills || [];
       const exists = skills.some(s => String(s).toLowerCase() === skillToAdd.toLowerCase());
       if (!exists) {
         setFormData({...formData, RequiredSkills: [...skills, skillToAdd]});
       }
       setSkillInput('');
       setSelectedSkill('');
    }
  };

  return (
    <ModalPortal>
      <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
        <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden animate-fade-in-down">
        <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
           <h3 className="text-lg font-bold text-gray-900">{job ? 'Edit Job Posting' : 'Create New Job'}</h3>
           <button onClick={onClose}><X className="w-5 h-5 text-gray-400 hover:text-gray-600"/></button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-5">
           <Input label="Job Title" placeholder="e.g. Software Engineer" value={formData.JobTitle || formData.jobTitle || ''} onChange={e => setFormData({...formData, JobTitle: e.target.value})} />
           
           <div className="flex gap-4">
              <div className="flex-1">
                 <label className="block text-xs font-bold text-gray-500 uppercase mb-1.5">Positions</label>
                 <input type="number" min="1" className="w-full border border-gray-300 rounded-lg p-2.5 outline-none focus:ring-2 focus:ring-blue-500" value={formData.NumberOfJobs || formData.numberOfJobs || 1} onChange={e => setFormData({...formData, NumberOfJobs: parseInt(e.target.value)})} />
              </div>
              <div className="flex-1">
                 <label className="block text-xs font-bold text-gray-500 uppercase mb-1.5">Type</label>
                 <select className="w-full border border-gray-300 rounded-lg p-2.5 outline-none focus:ring-2 focus:ring-blue-500 bg-white" value={formData.JobType || formData.jobType || 0} onChange={e => setFormData({...formData, JobType: parseInt(e.target.value)})}>
                    <option value={0}>Full Time</option><option value={1}>Internship</option><option value={2}>Part Time</option>
                 </select>
              </div>
           </div>
           
           <div>
              <label className="block text-xs font-bold text-gray-500 uppercase mb-1.5">Description</label>
              <textarea className="w-full border border-gray-300 rounded-lg p-3 h-32 resize-none outline-none focus:ring-2 focus:ring-blue-500" placeholder="Describe the role and responsibilities..." value={formData.JobDescription || formData.jobDescription || ''} onChange={e => setFormData({...formData, JobDescription: e.target.value})}></textarea>
           </div>
           
           <div>
              <label className="block text-xs font-bold text-gray-500 uppercase mb-1.5">Required Skills</label>
              <div className="flex gap-2 mb-3">
                 <select
                   className="flex-1 border border-gray-300 rounded-lg p-2.5 text-sm outline-none focus:border-blue-500 bg-white"
                   value={selectedSkill}
                   onChange={e => setSelectedSkill(e.target.value)}
                 >
                   <option value="">Select skill from list...</option>
                   {allSkillsList.map(skill => (
                     <option key={skill} value={skill}>{skill}</option>
                   ))}
                 </select>
                 <input className="flex-1 border border-gray-300 rounded-lg p-2.5 text-sm outline-none focus:border-blue-500" value={skillInput} onChange={e => setSkillInput(e.target.value)} placeholder="Or type custom skill..." />
                 <button onClick={addSkill} className="bg-blue-50 text-blue-600 px-4 rounded-lg text-sm font-bold hover:bg-blue-100 border border-blue-100">Add</button>
              </div>
              <div className="flex flex-wrap gap-2 min-h-[40px] p-2 bg-gray-50 rounded-lg border border-gray-100">
                 {(formData.RequiredSkills || formData.requiredSkills || []).map((s, i) => (
                    <span key={i} className="text-xs bg-white border border-gray-200 text-gray-700 px-2 py-1 rounded-md flex items-center gap-1 shadow-sm">
                        {s} 
                        <button type="button" onClick={() => {
                            const skills = formData.RequiredSkills || formData.requiredSkills;
                            setFormData({...formData, RequiredSkills: skills.filter(x => x !== s)});
                        }} className="hover:text-red-500"><X className="w-3 h-3"/></button>
                    </span>
                 ))}
                 {(formData.RequiredSkills || formData.requiredSkills || []).length === 0 && <span className="text-xs text-gray-400 italic p-1">No skills added yet.</span>}
              </div>
           </div>

           <div className="pt-4 flex gap-3">
              <button type="button" onClick={onClose} className="flex-1 py-3 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-xl font-bold transition-colors">Cancel</button>
              <button disabled={loading} className="flex-1 py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 flex justify-center gap-2 transition-colors shadow-lg shadow-blue-200">
                 {loading ? <Loader2 className="animate-spin w-5 h-5"/> : 'Save Job Posting'}
              </button>
           </div>
        </form>
        </div>
      </div>
    </ModalPortal>
  );
}

function Input({ label, value, onChange, type="text", placeholder, ...rest }) {
  return (
    <div>
      <label className="block text-xs font-bold text-gray-500 uppercase mb-1.5">{label}</label>
      <input type={type} placeholder={placeholder} value={value || ''} onChange={onChange} className="w-full border border-gray-300 rounded-lg p-3 outline-none focus:ring-2 focus:ring-blue-500 transition-all" {...rest} />
    </div>
  );
}