/* eslint-disable no-unused-vars */
import React, { useEffect, useState } from 'react';
import { Clock, CheckCircle2, XCircle, Calendar, Loader2, Inbox, Send, History, User, ArrowDownLeft, ArrowUpRight, Download } from 'lucide-react';
import { getPendingInterviewRequests, getAllInterviewRequests, getAnalytics, acceptInterviewRequest, rejectInterviewRequest, getFileUrl, getStudentAvailability, scheduleStudentInterview, startInterview, completeInterview, getStudentProfile } from '../api';
import { PDFDocument, rgb, degrees, StandardFonts } from 'pdf-lib';

export default function InterviewManager({ onError, onSelectStudent }) {
  const [activeTab, setActiveTab] = useState('pending'); // pending | accepted | scheduled | completed
  const [loading, setLoading] = useState(true);
  const [refreshKey, setRefreshKey] = useState(0); 
  
  const [pendingRequests, setPendingRequests] = useState([]);
  const [acceptedRequests, setAcceptedRequests] = useState([]);
  const [completedInterviews, setCompletedInterviews] = useState([]);
  const [scheduledInterviews, setScheduledInterviews] = useState([]);
  const [stats, setStats] = useState(null);

  // Modal States
  const [actionModal, setActionModal] = useState(null); // { type: 'accept' | 'reject', request: ... }
  const [rejectReason, setRejectReason] = useState('');
  const [processing, setProcessing] = useState(false);
  const [scheduleModal, setScheduleModal] = useState(null); // { request }
  const [availableSlots, setAvailableSlots] = useState([]);
  const [slotDurationMinutes, setSlotDurationMinutes] = useState(30);
  const [selectedSlot, setSelectedSlot] = useState('');
  const [loadingSlots, setLoadingSlots] = useState(false);
  const [scheduling, setScheduling] = useState(false);
  const [startingInterviewId, setStartingInterviewId] = useState(null);
  const [completeModal, setCompleteModal] = useState(null); // { interview }
  const [selectedResult, setSelectedResult] = useState('Hired');
  const [completing, setCompleting] = useState(false);
  const [selectedScheduledStudentId, setSelectedScheduledStudentId] = useState(null);
  const [selectedScheduledInterview, setSelectedScheduledInterview] = useState(null);
  const [selectedStudentProfile, setSelectedStudentProfile] = useState(null);
  const [profileLoading, setProfileLoading] = useState(false);
  const [downloadingAllCvs, setDownloadingAllCvs] = useState(false);

  useEffect(() => {
    setLoading(true);
    Promise.all([
      getPendingInterviewRequests(),
      getAllInterviewRequests('Accepted'),
      getAnalytics()
    ]).then(([requestsData, acceptedData, analyticsData]) => {
      const normalizedScheduled = (analyticsData.interviews?.scheduledInterviews || []).filter((interview) => {
        const scheduledTime = interview.scheduledTime || interview.ScheduledTime;
        const status = String(interview.status || interview.Status || '').toLowerCase();
        if (!scheduledTime) return false;

        const interviewDate = new Date(scheduledTime);
        if (Number.isNaN(interviewDate.getTime())) return false;

        return status === 'queued' || status === 'accepted' || status === 'inprogress' || status === '';
      });

      const allAcceptedRequests = acceptedData.requests || [];
      const completed = allAcceptedRequests
        .filter((req) => {
          const interview = req.interview || req.Interview;
          const interviewStatus = String(interview?.interviewStatus || interview?.InterviewStatus || '').toLowerCase();
          return interviewStatus === 'hired' || interviewStatus === 'shortlisted' || interviewStatus === 'rejected';
        })
        .map((req) => {
          const interview = req.interview || req.Interview;
          return {
            requestId: req.requestId || req.RequestId,
            studentId: req.studentId || req.StudentId,
            studentName: req.studentName || req.StudentName,
            studentRegistration: req.studentRegistration || req.StudentRegistration,
            studentCvUrl: req.studentCvUrl || req.StudentCvUrl,
            status: interview?.interviewStatus || interview?.InterviewStatus || 'Completed',
            scheduledTime: interview?.scheduledTime || interview?.ScheduledTime,
            endedAt: interview?.endedAt || interview?.EndedAt,
          };
        });

      const acceptedOnly = allAcceptedRequests.filter((req) => {
        const interview = req.interview || req.Interview;
        const interviewStatus = String(interview?.interviewStatus || interview?.InterviewStatus || '').toLowerCase();
        return interviewStatus !== 'hired' && interviewStatus !== 'shortlisted' && interviewStatus !== 'rejected';
      });

      setPendingRequests(requestsData.pendingRequests || []);
      setAcceptedRequests(acceptedOnly);
      setCompletedInterviews(completed);
      setScheduledInterviews(normalizedScheduled);
      setStats(analyticsData.summary);
    })
    .catch(err => onError(err.message))
    .finally(() => setLoading(false));
  }, [refreshKey, onError]);

  const formatDateTime = (value) => {
    if (!value) return '--';
    return new Date(value).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' });
  };

  const handleAccept = async () => {
    setProcessing(true);
    try {
      await acceptInterviewRequest(actionModal.request.requestId);
      setActionModal(null);
      setRefreshKey(k => k + 1);
    } catch (err) {
      onError(err.message);
    } finally {
      setProcessing(false);
    }
  };

  const handleReject = async (e) => {
    e.preventDefault();
    if (!rejectReason) return onError("Please provide a reason");
    setProcessing(true);
    try {
      await rejectInterviewRequest(actionModal.request.requestId, rejectReason);
      setActionModal(null);
      setRefreshKey(k => k + 1);
    } catch (err) {
      onError(err.message);
    } finally {
      setProcessing(false);
    }
  };

  const openScheduleModal = async (request) => {
    setScheduleModal({ request });
    setAvailableSlots([]);
    setSlotDurationMinutes(30);
    setSelectedSlot('');
    setLoadingSlots(true);

    try {
      const now = new Date();
      const localDate = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
      const availability = await getStudentAvailability(request.studentId, localDate);
      const slots = availability?.slots || [];
      setSlotDurationMinutes(Number(availability?.slotDurationMinutes) || 30);
      setAvailableSlots(slots);
      if (slots.length > 0) {
        setSelectedSlot(slots[0]);
      }
    } catch (err) {
      onError(err.message);
      setScheduleModal(null);
    } finally {
      setLoadingSlots(false);
    }
  };

  const handleScheduleStudent = async () => {
    if (!scheduleModal?.request?.studentId || !selectedSlot) {
      onError('Please select an available slot');
      return;
    }

    setScheduling(true);
    try {
      await scheduleStudentInterview(
        scheduleModal.request.studentId,
        selectedSlot,
        scheduleModal.request.requestId
      );

      setScheduleModal(null);
      setAvailableSlots([]);
      setSelectedSlot('');
      setRefreshKey(k => k + 1);
      onError('Interview scheduled successfully');
    } catch (err) {
      onError(err.message);
    } finally {
      setScheduling(false);
    }
  };

  const isAlreadyScheduled = (request) => {
    return scheduledInterviews.some(
      (interview) => String(interview.studentId) === String(request.studentId)
    );
  };

  const handleStartInterview = async (interview) => {
    setStartingInterviewId(interview.interviewId);
    try {
      await startInterview(interview.interviewId);
      setRefreshKey(k => k + 1);
      onError('Interview marked as started');
    } catch (err) {
      onError(err.message);
    } finally {
      setStartingInterviewId(null);
    }
  };

  const openCompleteModal = (interview) => {
    setCompleteModal({ interview });
    setSelectedResult('Hired');
  };

  const handleCompleteInterview = async () => {
    if (!completeModal?.interview?.interviewId) return;

    setCompleting(true);
    try {
      await completeInterview(completeModal.interview.interviewId, selectedResult);
      setCompleteModal(null);
      setRefreshKey(k => k + 1);
      onError(`Interview ended with result: ${selectedResult}`);
    } catch (err) {
      onError(err.message);
    } finally {
      setCompleting(false);
    }
  };

  const handleViewStudentProfile = async (interview) => {
    setSelectedScheduledStudentId(interview.studentId);
    setSelectedScheduledInterview(interview);
    setProfileLoading(true);
    try {
      const data = await getStudentProfile(interview.studentId);
      const profile = data?.student || null;
      setSelectedStudentProfile(profile);
    } catch (err) {
      onError(err.message);
      setSelectedStudentProfile(null);
      setSelectedScheduledInterview(null);
    } finally {
      setProfileLoading(false);
    }
  };

  const downloadBlob = (bytes, fileName, mimeType = 'application/pdf') => {
    const blob = new Blob([bytes], { type: mimeType });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = fileName;
    document.body.appendChild(link);
    link.click();
    link.remove();
    URL.revokeObjectURL(url);
  };

  const normalizeStatusLabel = (status) => {
    const val = String(status || '').trim().toLowerCase();
    if (val === 'hired') return 'HIRED';
    if (val === 'shortlisted') return 'SHORTLISTED';
    if (val === 'rejected') return 'REJECTED';
    return 'COMPLETED';
  };

  const getStatusBadgeClass = (status) => {
    const val = String(status || '').trim().toLowerCase();
    if (val === 'hired') return 'bg-green-100 text-green-800 border border-green-200';
    if (val === 'shortlisted') return 'bg-yellow-100 text-yellow-800 border border-yellow-200';
    if (val === 'rejected') return 'bg-red-100 text-red-800 border border-red-200';
    return 'bg-gray-100 text-gray-700 border border-gray-200';
  };

  const getWatermarkColor = (label) => {
    if (label === 'HIRED') return rgb(0.1, 0.6, 0.2);
    if (label === 'SHORTLISTED') return rgb(0.78, 0.58, 0.0);
    if (label === 'REJECTED') return rgb(0.85, 0.1, 0.1);
    return rgb(0.35, 0.35, 0.35);
  };

  const applyWatermark = async (pdfDoc, label) => {
    const pages = pdfDoc.getPages();
    const font = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
    const watermarkColor = getWatermarkColor(label);

    pages.forEach((page) => {
      const { width, height } = page.getSize();
      const textSize = Math.min(width, height) / 8;
      page.drawText(label, {
        x: width * 0.12,
        y: height * 0.45,
        size: textSize,
        font,
        color: watermarkColor,
        rotate: degrees(35),
        opacity: 0.18,
      });
    });
  };

  const handleDownloadCv = async (item) => {
    if (!item?.studentCvUrl) {
      onError('CV not available for this student.');
      return;
    }

    try {
      const cvUrl = getFileUrl(item.studentCvUrl);
      const response = await fetch(cvUrl);
      if (!response.ok) throw new Error('Failed to fetch CV');

      const contentType = response.headers.get('content-type') || '';
      const bytes = await response.arrayBuffer();
      const nameBase = `${(item.studentName || 'student').replace(/[^a-z0-9]/gi, '_')}_${normalizeStatusLabel(item.status).toLowerCase()}`;

      if (contentType.includes('pdf') || String(item.studentCvUrl).toLowerCase().endsWith('.pdf')) {
        const pdfDoc = await PDFDocument.load(bytes);
        await applyWatermark(pdfDoc, normalizeStatusLabel(item.status));
        const out = await pdfDoc.save();
        downloadBlob(out, `${nameBase}.pdf`);
      } else {
        downloadBlob(bytes, `${nameBase}`, contentType || 'application/octet-stream');
      }
    } catch (err) {
      onError(err.message || 'Failed to download CV');
    }
  };

  const handleDownloadAllCompletedCvs = async () => {
    const candidates = completedInterviews.filter((item) => item.studentCvUrl);
    if (candidates.length === 0) {
      onError('No CVs available to download.');
      return;
    }

    setDownloadingAllCvs(true);
    try {
      const mergedDoc = await PDFDocument.create();
      const skipped = [];

      for (const item of candidates) {
        try {
          const cvUrl = getFileUrl(item.studentCvUrl);
          const response = await fetch(cvUrl);
          if (!response.ok) throw new Error('fetch failed');
          const contentType = response.headers.get('content-type') || '';
          if (!contentType.includes('pdf') && !String(item.studentCvUrl).toLowerCase().endsWith('.pdf')) {
            skipped.push(item.studentName);
            continue;
          }

          const bytes = await response.arrayBuffer();
          const studentPdf = await PDFDocument.load(bytes);
          await applyWatermark(studentPdf, normalizeStatusLabel(item.status));
          const copied = await mergedDoc.copyPages(studentPdf, studentPdf.getPageIndices());
          copied.forEach((page) => mergedDoc.addPage(page));
        } catch {
          skipped.push(item.studentName);
        }
      }

      if (mergedDoc.getPageCount() === 0) {
        onError('Unable to prepare any PDF CVs for download.');
        return;
      }

      const out = await mergedDoc.save();
      downloadBlob(out, `completed_interviews_cvs_${new Date().toISOString().slice(0, 10)}.pdf`);

      if (skipped.length > 0) {
        onError(`Downloaded available PDF CVs. Skipped ${skipped.length} non-PDF/unavailable CV(s).`);
      }
    } catch (err) {
      onError(err.message || 'Failed to download all CVs');
    } finally {
      setDownloadingAllCvs(false);
    }
  };

  if (loading && !stats) return <div className="p-12 text-center"><Loader2 className="animate-spin mx-auto text-blue-600" /></div>;

  return (
    <div className="space-y-6 animate-fade-in relative">
      
      {/* --- KPI Stats Row --- */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatBox label="Pending Requests" value={pendingRequests.length} icon={Inbox} color="text-orange-600" bg="bg-orange-50" />
        <StatBox label="Accepted" value={acceptedRequests.length} icon={CheckCircle2} color="text-green-600" bg="bg-green-50" />
        <StatBox label="Scheduled" value={scheduledInterviews.length} icon={Calendar} color="text-blue-600" bg="bg-blue-50" />
        <StatBox label="Total Called" value={stats?.totalStudentsCalled || 0} icon={History} color="text-purple-600" bg="bg-purple-50" />
      </div>

      {/* --- Tabs --- */}
      <div className="border-b border-gray-200 flex gap-6">
        <TabBtn id="pending" label="Inbox & Sent" count={pendingRequests.length} active={activeTab} onClick={setActiveTab} />
        <TabBtn id="accepted" label="Accepted" count={acceptedRequests.length} active={activeTab} onClick={setActiveTab} />
        <TabBtn id="scheduled" label="Scheduled Interviews" active={activeTab} onClick={setActiveTab} />
        <TabBtn id="completed" label="Completed" count={completedInterviews.length} active={activeTab} onClick={setActiveTab} />
      </div>

      {/* --- PENDING REQUESTS VIEW --- */}
      {activeTab === 'pending' && (
        <div className="space-y-4">
          {pendingRequests.length === 0 ? (
            <EmptyState message="No pending requests." />
          ) : (
            <div className="grid grid-cols-1 gap-4">
              {pendingRequests.map(req => {
                // Logic: Check who requested (0 = Company, 1 = Student)
                const isIncoming = req.requestedBy === 1 || req.requestedBy === 'Student';

                return (
                  <div key={req.requestId} className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex flex-col md:flex-row items-start md:items-center gap-4 transition-all hover:border-blue-300">
                    
                    {/* Student Info */}
                    <div className="flex items-center gap-3 flex-1">
                      <div className="w-12 h-12 bg-gray-100 rounded-full overflow-hidden flex-shrink-0 border border-gray-200">
                        {req.studentProfilePic ? (
                          <img src={getFileUrl(req.studentProfilePic)} className="w-full h-full object-cover" alt="" />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center font-bold text-gray-400"><User className="w-6 h-6"/></div>
                        )}
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                            <h4 className="font-bold text-gray-900">{req.studentName}</h4>
                            {/* BADGE: Who requested? */}
                            {isIncoming ? (
                                <span className="text-[10px] bg-purple-100 text-purple-700 px-2 py-0.5 rounded-full flex items-center gap-1 font-bold border border-purple-200">
                                    <ArrowDownLeft className="w-3 h-3" /> Incoming
                                </span>
                            ) : (
                                <span className="text-[10px] bg-yellow-50 text-yellow-700 px-2 py-0.5 rounded-full flex items-center gap-1 font-bold border border-yellow-200">
                                    <ArrowUpRight className="w-3 h-3" /> Sent by You
                                </span>
                            )}
                        </div>
                        <p className="text-xs text-gray-500">{req.studentDepartment} • {req.studentRegistration}</p>
                        <div className="flex gap-2 mt-1">
                          {req.studentSkills?.slice(0, 3).map((s, i) => <span key={i} className="text-[10px] bg-gray-50 px-1.5 py-0.5 rounded text-gray-600 border border-gray-100">{s}</span>)}
                        </div>
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-2 w-full md:w-auto mt-2 md:mt-0">
                      {isIncoming ? (
                        <>
                            <button 
                              onClick={() => { setActionModal({ type: 'accept', request: req }); }}
                              className="flex-1 md:flex-none bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-700 flex items-center justify-center gap-2 shadow-sm"
                            >
                              <CheckCircle2 className="w-4 h-4" /> Accept
                            </button>
                            <button 
                              onClick={() => { setRejectReason(''); setActionModal({ type: 'reject', request: req }); }}
                              className="flex-1 md:flex-none bg-white border border-gray-200 text-red-600 px-4 py-2 rounded-lg text-sm font-medium hover:bg-red-50 flex items-center justify-center gap-2 shadow-sm"
                            >
                              <XCircle className="w-4 h-4" /> Reject
                            </button>
                        </>
                      ) : (
                        <div className="flex items-center gap-2 text-gray-400 bg-gray-50 px-4 py-2 rounded-lg border border-gray-100 text-sm font-medium cursor-default">
                            <Clock className="w-4 h-4" /> Awaiting Student Response...
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* --- ACCEPTED REQUESTS VIEW --- */}
      {activeTab === 'accepted' && (
        <div className="space-y-4">
          {acceptedRequests.length === 0 ? (
            <EmptyState message="No accepted requests." />
          ) : (
            <div className="bg-white rounded-xl border overflow-hidden shadow-sm">
              <table className="w-full text-sm text-left">
                <thead className="bg-gray-50 text-gray-500 font-medium border-b">
                  <tr>
                    <th className="p-4">Candidate</th>
                    <th className="p-4">Email</th>
                    <th className="p-4">Department</th>
                    <th className="p-4">CGPA</th>
                    <th className="p-4">Request Date</th>
                    <th className="p-4">Response Date</th>
                    <th className="p-4 text-right">Action</th>
                  </tr>
                </thead>
                <tbody>
                  {acceptedRequests.map(req => (
                    <tr key={req.requestId} className="border-b last:border-0 hover:bg-gray-50">
                      <td className="p-4">
                        <div className="flex items-center gap-3">
                          {req.studentProfilePic ? (
                            <img src={getFileUrl(req.studentProfilePic)} alt="" className="w-10 h-10 rounded-full object-cover" />
                          ) : (
                            <div className="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center text-green-600 font-bold">
                              {req.studentName?.charAt(0)}
                            </div>
                          )}
                          <div>
                            <div className="font-medium text-gray-900">{req.studentName}</div>
                            <div className="text-xs text-gray-500">{req.studentRegistration}</div>
                          </div>
                        </div>
                      </td>
                      <td className="p-4 text-gray-600">{req.studentEmail}</td>
                      <td className="p-4 text-gray-600">{req.studentDepartment}</td>
                      <td className="p-4">
                        <span className="font-semibold text-blue-600">{req.studentCGPA?.toFixed(2)}</span>
                      </td>
                      <td className="p-4 text-gray-600 text-xs">
                        {new Date(req.requestDate).toLocaleDateString()}
                      </td>
                      <td className="p-4 text-gray-600 text-xs">
                        {new Date(req.responseDate).toLocaleDateString()}
                      </td>
                      <td className="p-4 text-right">
                        <div className="flex justify-end gap-2 flex-wrap">
                          <button
                            onClick={() => {
                              if (onSelectStudent) {
                                onSelectStudent(req);
                                return;
                              }
                              handleViewStudentProfile(req);
                            }}
                            className="text-gray-600 hover:text-blue-600 text-xs font-medium border border-gray-200 bg-white px-2 py-1 rounded"
                          >
                            View Profile
                          </button>

                          {isAlreadyScheduled(req) ? (
                            <span className="bg-green-100 text-green-800 px-2 py-1 rounded-full text-xs font-bold inline-flex items-center gap-1">
                              <CheckCircle2 className="w-3 h-3" /> Scheduled
                            </span>
                          ) : (
                            <button
                              onClick={() => openScheduleModal(req)}
                              className="bg-blue-600 text-white px-3 py-1.5 rounded-lg text-xs font-medium hover:bg-blue-700 inline-flex items-center gap-1"
                            >
                              <Calendar className="w-3.5 h-3.5" /> Schedule
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* --- SCHEDULED INTERVIEWS VIEW --- */}
      {activeTab === 'scheduled' && (
        <div className={`${selectedScheduledStudentId ? 'grid grid-cols-1 xl:grid-cols-2 gap-6 items-start' : ''}`}>
          <div>
          {scheduledInterviews.length === 0 ? (
             <EmptyState message="No upcoming interviews scheduled." />
          ) : (
            <div className="bg-white rounded-xl border overflow-hidden shadow-sm">
              <table className="w-full text-sm text-left">
                <thead className="bg-gray-50 text-gray-500 font-medium border-b">
                  <tr>
                    <th className="p-4">Candidate</th>
                    <th className="p-4">Date & Time</th>
                    <th className="p-4">Status</th>
                    <th className="p-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {scheduledInterviews.map(int => (
                    <tr key={int.interviewId} className="border-b last:border-0 hover:bg-gray-50">
                      <td className="p-4 font-medium">
                          {int.studentName} 
                          <span className="text-gray-400 font-normal text-xs block">{int.registrationNo}</span>
                      </td>
                      <td className="p-4">
                        <div className="flex items-center gap-2 text-blue-600 font-medium bg-blue-50 w-fit px-3 py-1 rounded-full">
                           <Clock className="w-3.5 h-3.5" />
                           {formatDateTime(int.scheduledTime)}
                        </div>
                        <div className="mt-2 space-y-1 text-xs">
                          <div className="text-amber-700 bg-amber-50 border border-amber-100 px-2 py-1 rounded w-fit">Start: {formatDateTime(int.startedAt)}</div>
                          <div className="text-rose-700 bg-rose-50 border border-rose-100 px-2 py-1 rounded w-fit">End: {formatDateTime(int.endedAt)}</div>
                        </div>
                      </td>
                      <td className="p-4">
                        <span className="bg-green-100 text-green-800 px-2 py-1 rounded-full text-xs font-bold flex items-center gap-1 w-fit">
                            <CheckCircle2 className="w-3 h-3" /> {int.status || 'Scheduled'}
                        </span>
                      </td>
                      <td className="p-4 text-right">
                         <div className="flex justify-end gap-2 flex-wrap">
                           <button
                             onClick={() => handleViewStudentProfile(int)}
                             className="text-gray-600 hover:text-blue-600 text-xs font-medium border border-gray-200 bg-white px-2 py-1 rounded"
                           >
                             View Profile
                           </button>

                           {(String(int.status).toLowerCase() === 'queued') && (
                             <button
                               onClick={() => handleStartInterview(int)}
                               disabled={startingInterviewId === int.interviewId}
                               className="text-xs font-medium bg-green-600 hover:bg-green-700 text-white px-2.5 py-1 rounded disabled:opacity-50"
                             >
                               {startingInterviewId === int.interviewId ? 'Starting...' : 'Start Interview'}
                             </button>
                           )}

                           {(String(int.status).toLowerCase() === 'inprogress') && (
                             <button
                               onClick={() => openCompleteModal(int)}
                               className="text-xs font-medium bg-amber-600 hover:bg-amber-700 text-white px-2.5 py-1 rounded"
                             >
                               End Interview
                             </button>
                           )}
                         </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
          </div>

          {selectedScheduledStudentId && (
            <div className="bg-white rounded-xl border shadow-sm p-5 sticky top-4 max-h-[80vh] overflow-auto">
              <div className="flex items-center justify-between mb-4">
                <h4 className="font-bold text-gray-900">Student Profile</h4>
                <button
                  onClick={() => {
                    setSelectedScheduledStudentId(null);
                    setSelectedScheduledInterview(null);
                    setSelectedStudentProfile(null);
                  }}
                  className="text-xs text-gray-500 hover:text-gray-700"
                >
                  Close
                </button>
              </div>

              {profileLoading ? (
                <div className="py-8 flex items-center justify-center text-gray-500 gap-2">
                  <Loader2 className="w-4 h-4 animate-spin" /> Loading profile...
                </div>
              ) : selectedStudentProfile ? (
                <div className="space-y-3 text-sm">
                  <div className="grid grid-cols-2 gap-3 text-xs">
                    <div>
                      <p className="text-gray-500">Interview Time</p>
                      <p className="font-medium text-gray-800">{formatDateTime(selectedScheduledInterview?.scheduledTime)}</p>
                    </div>
                    <div>
                      <p className="text-gray-500">Status</p>
                      <p className="font-medium text-gray-800">{selectedScheduledInterview?.status || 'Scheduled'}</p>
                    </div>
                  </div>

                  <div>
                    <p className="text-xs text-gray-500">Name</p>
                    <p className="font-semibold text-gray-900">{selectedStudentProfile.user?.fullName || 'N/A'}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500">Registration</p>
                    <p className="font-medium text-gray-800">{selectedStudentProfile.registrationNo || 'N/A'}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500">Department</p>
                    <p className="font-medium text-gray-800">{selectedStudentProfile.department || 'N/A'}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500">CGPA</p>
                    <p className="font-medium text-blue-700">{selectedStudentProfile.cgpa?.toFixed ? selectedStudentProfile.cgpa.toFixed(2) : selectedStudentProfile.cgpa || 'N/A'}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500">Email</p>
                    <p className="font-medium text-gray-800 break-all">{selectedStudentProfile.user?.email || 'N/A'}</p>
                  </div>

                  <div>
                    <p className="text-xs text-gray-500">Uploaded CV</p>
                    {selectedStudentProfile.cvUrl ? (
                      <div className="space-y-2 mt-1">
                        <div className="flex gap-2">
                          <a
                            href={getFileUrl(selectedStudentProfile.cvUrl)}
                            target="_blank"
                            rel="noreferrer"
                            className="text-xs font-medium border border-gray-300 bg-white hover:bg-gray-50 text-gray-700 px-2.5 py-1 rounded"
                          >
                            Download CV
                          </a>
                        </div>
                      </div>
                    ) : (
                      <span className="text-gray-400 text-xs">No CV uploaded yet.</span>
                    )}
                  </div>

                  <div>
                    <p className="text-xs text-gray-500">Skills</p>
                    <div className="flex flex-wrap gap-1 mt-1">
                      {(selectedStudentProfile.skills || []).length > 0
                        ? selectedStudentProfile.skills.map((skill, idx) => (
                            <span key={idx} className="px-2 py-0.5 rounded bg-gray-100 text-gray-700 text-xs">{skill}</span>
                          ))
                        : <span className="text-gray-400 text-xs">No skills listed.</span>}
                    </div>
                  </div>

                  <div>
                    <p className="text-xs text-gray-500 mb-1">Education</p>
                    {(selectedStudentProfile.educations || []).length > 0 ? (
                      <div className="space-y-2">
                        {selectedStudentProfile.educations.map((edu, idx) => (
                          <div key={idx} className="p-2 rounded border border-gray-100 bg-gray-50">
                            <p className="font-medium text-gray-800">{edu.degree || 'Degree'} {edu.fieldOfStudy ? `in ${edu.fieldOfStudy}` : ''}</p>
                            <p className="text-xs text-gray-600">{edu.institutionName || 'Institution'}</p>
                          </div>
                        ))}
                      </div>
                    ) : <span className="text-gray-400 text-xs">No education records.</span>}
                  </div>

                  <div>
                    <p className="text-xs text-gray-500 mb-1">Experience</p>
                    {(selectedStudentProfile.experiences || []).length > 0 ? (
                      <div className="space-y-2">
                        {selectedStudentProfile.experiences.map((exp, idx) => (
                          <div key={idx} className="p-2 rounded border border-gray-100 bg-gray-50">
                            <p className="font-medium text-gray-800">{exp.role || 'Role'}</p>
                            <p className="text-xs text-gray-600">{exp.companyName || 'Company'}</p>
                          </div>
                        ))}
                      </div>
                    ) : <span className="text-gray-400 text-xs">No experience records.</span>}
                  </div>

                  <div>
                    <p className="text-xs text-gray-500 mb-1">Projects</p>
                    {(selectedStudentProfile.projects || []).length > 0 ? (
                      <div className="space-y-2">
                        {selectedStudentProfile.projects.map((project, idx) => (
                          <div key={idx} className="p-2 rounded border border-gray-100 bg-gray-50">
                            <p className="font-medium text-gray-800">{project.title || 'Project'}</p>
                            {project.description && <p className="text-xs text-gray-600 mt-0.5">{project.description}</p>}
                          </div>
                        ))}
                      </div>
                    ) : <span className="text-gray-400 text-xs">No projects listed.</span>}
                  </div>
                </div>
              ) : (
                <p className="text-sm text-gray-500">Profile not available.</p>
              )}
            </div>
          )}
        </div>
      )}

      {activeTab === 'completed' && (
        <div>
          {completedInterviews.length === 0 ? (
            <EmptyState message="No completed interviews yet." />
          ) : (
            <div className="bg-white rounded-xl border overflow-hidden shadow-sm">
              <div className="px-4 py-3 border-b bg-gray-50 flex justify-end">
                <button
                  onClick={handleDownloadAllCompletedCvs}
                  disabled={downloadingAllCvs}
                  className="inline-flex items-center gap-2 text-xs font-medium bg-indigo-600 hover:bg-indigo-700 text-white px-3 py-1.5 rounded-lg disabled:opacity-50"
                >
                  {downloadingAllCvs ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Download className="w-3.5 h-3.5" />} Download All CVs
                </button>
              </div>
              <table className="w-full text-sm text-left">
                <thead className="bg-gray-50 text-gray-500 font-medium border-b">
                  <tr>
                    <th className="p-4">Candidate</th>
                    <th className="p-4">Scheduled</th>
                    <th className="p-4">Ended</th>
                    <th className="p-4">Result</th>
                    <th className="p-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {completedInterviews.map((item) => (
                    <tr key={item.requestId} className="border-b last:border-0 hover:bg-gray-50">
                      <td className="p-4 font-medium">
                        {item.studentName}
                        <span className="text-gray-400 font-normal text-xs block">{item.studentRegistration}</span>
                      </td>
                      <td className="p-4 text-gray-700">{formatDateTime(item.scheduledTime)}</td>
                      <td className="p-4 text-gray-700">{formatDateTime(item.endedAt)}</td>
                      <td className="p-4">
                        <span className={`px-2 py-1 rounded-full text-xs font-bold ${getStatusBadgeClass(item.status)}`}>
                          {item.status}
                        </span>
                      </td>
                      <td className="p-4 text-right">
                        <div className="flex justify-end gap-2">
                          <button
                            onClick={() => onSelectStudent && onSelectStudent(item)}
                            className="text-gray-600 hover:text-blue-600 text-xs font-medium border border-gray-200 bg-white px-2 py-1 rounded inline-flex items-center gap-1"
                            title="View Profile"
                          >
                            <User className="w-3.5 h-3.5" /> Profile
                          </button>
                          <button
                            onClick={() => handleDownloadCv(item)}
                            disabled={!item.studentCvUrl}
                            className="text-gray-600 hover:text-indigo-600 text-xs font-medium border border-gray-200 bg-white px-2 py-1 rounded inline-flex items-center gap-1 disabled:opacity-50"
                            title={item.studentCvUrl ? 'Download CV' : 'CV not available'}
                          >
                            <Download className="w-3.5 h-3.5" /> CV
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* --- MODALS --- */}
      {actionModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 animate-fade-in">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b">
              <h3 className="text-lg font-bold text-gray-900">
                {actionModal.type === 'accept' ? 'Accept Interview Request' : 'Reject Request'}
              </h3>
              <p className="text-sm text-gray-500 mt-1">
                Candidate: <span className="font-medium text-gray-900">{actionModal.request.studentName}</span>
              </p>
            </div>
            
            <div className="p-6">
              {actionModal.type === 'accept' ? (
                <div className="space-y-4">
                  <p className="text-sm text-gray-600">
                    Are you sure you want to accept this interview request? The interview will be added to your queue.
                  </p>
                  <div className="flex gap-3 pt-2">
                    <button type="button" onClick={() => setActionModal(null)} className="flex-1 py-2.5 text-gray-600 font-medium hover:bg-gray-100 rounded-lg">Cancel</button>
                    <button onClick={handleAccept} disabled={processing} className="flex-1 py-2.5 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 flex justify-center items-center gap-2">
                       {processing ? <Loader2 className="animate-spin w-4 h-4" /> : 'Accept Request'}
                    </button>
                  </div>
                </div>
              ) : (
                <form onSubmit={handleReject} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Reason for Rejection</label>
                    <textarea 
                      required
                      rows={3}
                      value={rejectReason}
                      onChange={(e) => setRejectReason(e.target.value)}
                      placeholder="e.g. Position filled, Skills mismatch..."
                      className="w-full p-3 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none resize-none"
                    />
                  </div>
                  <div className="flex gap-3 pt-2">
                    <button type="button" onClick={() => setActionModal(null)} className="flex-1 py-2.5 text-gray-600 font-medium hover:bg-gray-100 rounded-lg">Cancel</button>
                    <button disabled={processing} className="flex-1 py-2.5 bg-red-600 text-white font-medium rounded-lg hover:bg-red-700 flex justify-center items-center gap-2">
                       {processing ? <Loader2 className="animate-spin w-4 h-4" /> : 'Reject Request'}
                    </button>
                  </div>
                </form>
              )}
            </div>
          </div>
        </div>
      )}

      {scheduleModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 animate-fade-in">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg overflow-hidden">
            <div className="p-6 border-b">
              <h3 className="text-lg font-bold text-gray-900">Schedule Interview</h3>
              <p className="text-sm text-gray-500 mt-1">
                Candidate: <span className="font-medium text-gray-900">{scheduleModal.request.studentName}</span>
              </p>
            </div>

            <div className="p-6 space-y-4">
              {loadingSlots ? (
                <div className="py-8 flex items-center justify-center text-gray-500 gap-2">
                  <Loader2 className="w-4 h-4 animate-spin" /> Loading available slots...
                </div>
              ) : availableSlots.length === 0 ? (
                <div className="py-6 text-center text-sm text-gray-500 bg-gray-50 rounded-lg border border-gray-100">
                  No available slots found for this student.
                </div>
              ) : (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Select Available Slot</label>
                  <select
                    className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 outline-none"
                    value={selectedSlot}
                    onChange={(e) => setSelectedSlot(e.target.value)}
                  >
                    {availableSlots.map((slot) => (
                      <option key={slot} value={slot}>
                        {formatDateTime(slot)}
                      </option>
                    ))}
                  </select>
                  {selectedSlot && (
                    <p className="mt-2 text-xs text-gray-500">
                      Interview window: {formatDateTime(selectedSlot)} - {formatDateTime(new Date(new Date(selectedSlot).getTime() + slotDurationMinutes * 60000))}
                    </p>
                  )}
                </div>
              )}

              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setScheduleModal(null)}
                  className="flex-1 py-2.5 text-gray-600 font-medium hover:bg-gray-100 rounded-lg"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  disabled={loadingSlots || scheduling || availableSlots.length === 0 || !selectedSlot}
                  onClick={handleScheduleStudent}
                  className="flex-1 py-2.5 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 disabled:opacity-50 flex justify-center items-center gap-2"
                >
                  {scheduling ? <Loader2 className="animate-spin w-4 h-4" /> : 'Schedule Interview'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {completeModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 animate-fade-in">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b">
              <h3 className="text-lg font-bold text-gray-900">Complete Interview</h3>
              <p className="text-sm text-gray-500 mt-1">
                Candidate: <span className="font-medium text-gray-900">{completeModal.interview.studentName}</span>
              </p>
            </div>

            <div className="p-6 space-y-4">
              <div className="rounded-lg border border-gray-200 bg-gray-50 p-3 text-xs text-gray-600 space-y-1">
                <div><span className="font-medium">Scheduled:</span> {formatDateTime(completeModal.interview.scheduledTime)}</div>
                <div><span className="font-medium">Start:</span> {formatDateTime(completeModal.interview.startedAt)}</div>
                <div><span className="font-medium">End:</span> {formatDateTime(new Date())}</div>
              </div>

              <label className="block text-sm font-medium text-gray-700">Select Result</label>
              <select
                value={selectedResult}
                onChange={(e) => setSelectedResult(e.target.value)}
                className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 outline-none"
              >
                <option value="Hired">Hired</option>
                <option value="Shortlisted">Shortlisted</option>
                <option value="Rejected">Rejected</option>
              </select>

              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setCompleteModal(null)}
                  className="flex-1 py-2.5 text-gray-600 font-medium hover:bg-gray-100 rounded-lg"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  disabled={completing}
                  onClick={handleCompleteInterview}
                  className="flex-1 py-2.5 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 disabled:opacity-50 flex justify-center items-center gap-2"
                >
                  {completing ? <Loader2 className="animate-spin w-4 h-4" /> : 'Save Result'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}

// --- Sub Components ---

function StatBox({ label, value, icon: Icon, color, bg }) {
  return (
    <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex items-center gap-3">
      <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${bg} ${color}`}>
        <Icon className="w-5 h-5" />
      </div>
      <div>
        <div className="text-2xl font-bold text-gray-900">{value}</div>
        <div className="text-xs text-gray-500 font-medium">{label}</div>
      </div>
    </div>
  );
}

function TabBtn({ id, label, count, active, onClick }) {
  const isActive = active === id;
  return (
    <button 
      onClick={() => onClick(id)}
      className={`pb-3 px-1 text-sm font-medium border-b-2 transition-colors relative ${isActive ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700'}`}
    >
      {label}
      {count !== undefined && count > 0 && (
        <span className="ml-2 bg-red-500 text-white text-[10px] px-1.5 py-0.5 rounded-full">{count}</span>
      )}
    </button>
  );
}

function EmptyState({ message }) {
  return (
    <div className="bg-gray-50 border-2 border-dashed border-gray-200 rounded-xl p-12 text-center flex flex-col items-center justify-center text-gray-400">
      <Inbox className="w-12 h-12 mb-3 opacity-20" />
      <p>{message}</p>
    </div>
  );
}