/* eslint-disable no-unused-vars */
import React, { useEffect, useState } from 'react';
import { Clock, CheckCircle2, XCircle, Calendar, Loader2, Inbox, Send, History, User, ArrowDownLeft, ArrowUpRight, Download, Bell, ChevronDown } from 'lucide-react';
import { getPendingInterviewRequests, getAllInterviewRequests, getAnalytics, acceptInterviewRequest, rejectInterviewRequest, getFileUrl, getStudentAvailability, scheduleStudentInterview, startInterview, completeInterview, getStudentProfile, scheduleAllInterviews, rescheduleInterview, notifyStudent } from '../api';
import { PDFDocument, rgb, degrees, StandardFonts } from 'pdf-lib';

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

export default function InterviewManager({ user, roomName, onError, onSuccess, onSelectStudent, navigationTarget, isPresent, isJobFairDay }) {
  const [activeTab, setActiveTab] = useState('pending'); // pending | accepted | scheduled | completed
  const [pendingView, setPendingView] = useState('all'); // all | inbox | sent
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
  const [schedulingAll, setSchedulingAll] = useState(false);
  const [startingInterviewId, setStartingInterviewId] = useState(null);
  const [completeModal, setCompleteModal] = useState(null); // { interview }
  const [selectedResult, setSelectedResult] = useState('Hired');
  const [completing, setCompleting] = useState(false);
  const [selectedScheduledStudentId, setSelectedScheduledStudentId] = useState(null);
  const [selectedScheduledInterview, setSelectedScheduledInterview] = useState(null);
  const [selectedStudentProfile, setSelectedStudentProfile] = useState(null);
  const [profileLoading, setProfileLoading] = useState(false);
  const [downloadingAllCvs, setDownloadingAllCvs] = useState(false);
  const [showBulkScheduleModal, setShowBulkScheduleModal] = useState(false);
  const [bulkScheduleStartTime, setBulkScheduleStartTime] = useState(() => {
    // Default to current time HH:mm
    const now = new Date();
    return `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
  });
  const [isInterviewWindowClosed, setIsInterviewWindowClosed] = useState(false);
  const [nowTick, setNowTick] = useState(Date.now());
  const [notifyModal, setNotifyModal] = useState(null); // { interview }
  const [notifyPreset, setNotifyPreset] = useState('NEXT');
  const [notifyTitle, setNotifyTitle] = useState('Interview Update');
  const [notifyBody, setNotifyBody] = useState('');
  const [sendingNotification, setSendingNotification] = useState(false);
  const [quickNotifyKey, setQuickNotifyKey] = useState('');

  useEffect(() => {
    const intervalId = setInterval(() => setNowTick(Date.now()), 1000);
    return () => clearInterval(intervalId);
  }, []);

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
          return interviewStatus === 'hired' || interviewStatus === 'shortlisted' || interviewStatus === 'rejected' || interviewStatus === 'didnotappear';
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
        return interviewStatus !== 'hired' && interviewStatus !== 'shortlisted' && interviewStatus !== 'rejected' && interviewStatus !== 'didnotappear';
      });

      setIsInterviewWindowClosed(hasCutoffPassed(analyticsData?.jobFairDate));

      setPendingRequests(requestsData.pendingRequests || []);
      setAcceptedRequests(acceptedOnly);
      setCompletedInterviews(completed);
      setScheduledInterviews(normalizedScheduled);
      setStats(analyticsData.summary);
    })
    .catch(err => onError(err.message))
    .finally(() => setLoading(false));
  }, [refreshKey, onError]);

  useEffect(() => {
    if (!navigationTarget) return;
    if (navigationTarget.tab) setActiveTab(navigationTarget.tab);
    if (navigationTarget.pendingView) setPendingView(navigationTarget.pendingView);
  }, [navigationTarget]);

  const formatDateTime = (value) => {
    if (!value) return '--';
    return new Date(value).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' });
  };

  const getPktDateParts = (inputDate) => {
    const formatter = new Intl.DateTimeFormat('en-CA', {
      timeZone: 'Asia/Karachi',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false
    });
    const parts = formatter.formatToParts(new Date(inputDate));
    const pick = (type) => Number(parts.find((p) => p.type === type)?.value || 0);
    return { year: pick('year'), month: pick('month'), day: pick('day'), hour: pick('hour'), minute: pick('minute') };
  };

  const hasCutoffPassed = (jobFairDate) => {
    if (!jobFairDate) return false;
    const now = getPktDateParts(new Date());
    const fair = getPktDateParts(jobFairDate);
    const nowDateNum = now.year * 10000 + now.month * 100 + now.day;
    const fairDateNum = fair.year * 10000 + fair.month * 100 + fair.day;
    if (nowDateNum > fairDateNum) return true;
    if (nowDateNum < fairDateNum) return false;
    return now.hour > 16 || (now.hour === 16 && now.minute > 30);
  };

  const handleAccept = async () => {
    if (isInterviewWindowClosed) {
      onError('Job Fair has ended.');
      return;
    }
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

  const openScheduleModal = async (target, mode = 'schedule') => {
    if (isInterviewWindowClosed) {
      onError('Job Fair has ended.');
      return;
    }

    setScheduleModal({ target, mode });
    setAvailableSlots([]);
    setSlotDurationMinutes(30);
    setSelectedSlot('');
    setLoadingSlots(true);

    try {
      const now = new Date();
      const localDate = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
      const availability = await getStudentAvailability(target.studentId, localDate);
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
    if (isInterviewWindowClosed) {
      onError('Job Fair has ended.');
      return;
    }

    if (!scheduleModal?.target?.studentId || !selectedSlot) {
      onError('Please select an available slot');
      return;
    }

    setScheduling(true);
    try {
      if (scheduleModal.mode === 'reschedule') {
        await rescheduleInterview(
          scheduleModal.target.interviewId,
          selectedSlot,
          scheduleModal.target.requestId ?? null
        );
      } else {
        await scheduleStudentInterview(
          scheduleModal.target.studentId,
          selectedSlot,
          scheduleModal.target.requestId
        );
      }

      setScheduleModal(null);
      setAvailableSlots([]);
      setSelectedSlot('');
      setRefreshKey(k => k + 1);
      if (onSuccess) onSuccess(scheduleModal.mode === 'reschedule' ? 'Interview rescheduled successfully' : 'Interview scheduled successfully');
    } catch (err) {
      onError(err.message);
    } finally {
      setScheduling(false);
    }
  };

  const handleScheduleAllAccepted = async (startTimeStr = null) => {
    if (isInterviewWindowClosed) {
      onError('Job Fair has ended.');
      return;
    }

    setSchedulingAll(true);
    try {
      let dateParam = null;
      if (startTimeStr) {
        const [hours, minutes] = startTimeStr.split(':').map(Number);
        const d = new Date();
        d.setHours(hours, minutes, 0, 0);
        dateParam = d.toISOString();
      }

      const result = await scheduleAllInterviews(dateParam);
      setRefreshKey(k => k + 1);
      if (onSuccess) onSuccess(`Scheduled ${result?.count || 0} interview(s) from accepted requests.`);
      setShowBulkScheduleModal(false);
    } catch (err) {
      onError(`Failed to auto-schedule interviews: ${err.message}`);
    } finally {
      setSchedulingAll(false);
    }
  };

  const isAlreadyScheduled = (request) => {
    return scheduledInterviews.some(
      (interview) => String(interview.studentId) === String(request.studentId)
    );
  };

  const filteredPendingRequests = pendingRequests.filter((req) => {
    if (pendingView === 'all') return true;
    const isIncoming = req.requestedBy === 1 || req.requestedBy === 'Student';
    if (pendingView === 'inbox') return isIncoming;
    if (pendingView === 'sent') return !isIncoming;
    return true;
  });

  const handleStartInterview = async (interview) => {
    if (!canStartInterview(interview)) {
      onError('Interview can only be started within ±15 minutes of scheduled time.');
      return;
    }
    setStartingInterviewId(interview.interviewId);
    try {
      await startInterview(interview.interviewId);
      setRefreshKey(k => k + 1);
      if (onSuccess) onSuccess('Interview marked as started');
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
      if (onSuccess) onSuccess(`Interview ended with result: ${selectedResult}`);
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
    if (val === 'didnotappear' || val === 'did not appear') return 'DID NOT APPEAR';
    if (val === 'rejected') return 'REJECTED';
    return 'COMPLETED';
  };

  const getStatusBadgeClass = (status) => {
    const val = String(status || '').trim().toLowerCase();
    if (val === 'hired') return 'bg-green-100 text-green-800 border border-green-200';
    if (val === 'shortlisted') return 'bg-yellow-100 text-yellow-800 border border-yellow-200';
    if (val === 'didnotappear' || val === 'did not appear') return 'bg-slate-100 text-slate-800 border border-slate-200';
    if (val === 'rejected') return 'bg-red-100 text-red-800 border border-red-200';
    return 'bg-gray-100 text-gray-700 border border-gray-200';
  };

  const getSafeDate = (value) => {
    if (!value) return null;
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  };

  const getInterviewDuration = (interview) => {
    const duration = Number(interview?.durationMinutes ?? interview?.DurationMinutes ?? 30);
    return Number.isFinite(duration) && duration > 0 ? duration : 30;
  };

  const canStartInterview = (interview) => {
    const status = String(interview?.status || '').toLowerCase();
    if (status !== 'queued') return false;

    const scheduled = getSafeDate(interview?.scheduledTime);
    if (!scheduled) return true;

    const earliest = scheduled.getTime() - (15 * 60 * 1000);
    const latest = scheduled.getTime() + (15 * 60 * 1000);
    return nowTick >= earliest && nowTick <= latest;
  };

  const canMarkDidNotAppear = (interview) => {
    const status = String(interview?.status || '').toLowerCase();
    if (status !== 'queued' && status !== 'inprogress') return false;

    const scheduled = getSafeDate(interview?.scheduledTime);
    if (!scheduled) return true;

    return nowTick >= (scheduled.getTime() - (15 * 60 * 1000));
  };

  const getRemainingSeconds = (interview) => {
    const status = String(interview?.status || '').toLowerCase();
    if (status !== 'inprogress') return null;

    const started = getSafeDate(interview?.startedAt);
    if (!started) return null;

    const endMs = started.getTime() + (getInterviewDuration(interview) * 60 * 1000);
    return Math.floor((endMs - nowTick) / 1000);
  };

  const formatDurationLabel = (seconds) => {
    const abs = Math.abs(seconds);
    const mins = Math.floor(abs / 60);
    const secs = abs % 60;
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  };

  const getGlobalOvertimeMinutes = () => {
    const overtimeValues = scheduledInterviews
      .filter((it) => String(it?.status || '').toLowerCase() === 'inprogress')
      .map((it) => getRemainingSeconds(it))
      .filter((sec) => typeof sec === 'number' && sec < 0)
      .map((sec) => Math.ceil(Math.abs(sec) / 60));

    if (overtimeValues.length === 0) return 0;
    return Math.max(...overtimeValues);
  };

  const buildNotificationTemplate = (preset, interview) => {
    const studentName = interview?.studentName || 'Student';
    const companyName = user?.name || 'the company';
    const overtimeMinutes = getGlobalOvertimeMinutes();
    const roomInfo = roomName ? ` at Room ${roomName}` : '';

    if (preset === 'NEXT') {
      return {
        title: 'You Are Next',
        body: `Dear ${studentName}, you are next. Please come to the interview room${roomInfo} for ${companyName} now.`
      };
    }

    if (preset === 'SOON') {
      return {
        title: 'Interview Starting Soon',
        body: `Dear ${studentName}, your interview with ${companyName}${roomInfo} is starting soon. Please be ready and arrive at the room.`
      };
    }

    if (preset === 'DELAY') {
      const delay = overtimeMinutes > 0 ? overtimeMinutes : 5;
      return {
        title: 'Interview Delay Update',
        body: `Dear ${studentName}, the previous interview at ${companyName} is running overtime. Your interview might be delayed by approximately ${delay} minute${delay === 1 ? '' : 's'}. Please wait near the interview room${roomInfo}.`
      };
    }

    return {
      title: 'Interview Update',
      body: ''
    };
  };

  const openNotifyModal = (interview) => {
    const preset = 'NEXT';
    const template = buildNotificationTemplate(preset, interview);
    setNotifyPreset(preset);
    setNotifyTitle(template.title);
    setNotifyBody(template.body);
    setNotifyModal({ interview });
  };

  const handlePresetChange = (preset) => {
    setNotifyPreset(preset);
    if (!notifyModal?.interview) return;
    const template = buildNotificationTemplate(preset, notifyModal.interview);
    setNotifyTitle(template.title);
    setNotifyBody(template.body);
  };

  const handleSendStudentNotification = async () => {
    if (!notifyModal?.interview?.studentId) {
      onError('Student reference is missing for notification.');
      return;
    }
    if (!notifyTitle.trim() || !notifyBody.trim()) {
      onError('Please provide both title and message.');
      return;
    }

    setSendingNotification(true);
    try {
      await notifyStudent(
        notifyModal.interview.studentId,
        notifyTitle.trim(),
        notifyBody.trim(),
        notifyPreset === 'CUSTOM' ? 'CompanyCustomMessage' : `CompanyPreset${notifyPreset}`
      );
      setNotifyModal(null);
      if (onSuccess) onSuccess('Notification sent to student.');
    } catch (err) {
      onError(err.message || 'Failed to send notification.');
    } finally {
      setSendingNotification(false);
    }
  };

  const handleQuickPresetNotification = async (interview, preset) => {
    if (!interview?.studentId) {
      onError('Student reference is missing for notification.');
      return;
    }

    const template = buildNotificationTemplate(preset, interview);
    if (!template.title.trim() || !template.body.trim()) {
      onError('Unable to generate preset notification content.');
      return;
    }

    const actionKey = `${interview.interviewId}:${preset}`;
    setQuickNotifyKey(actionKey);
    try {
      await notifyStudent(
        interview.studentId,
        template.title,
        template.body,
        `CompanyPreset${preset}`
      );
      if (onSuccess) onSuccess(`Notification sent to ${interview.studentName}.`);
    } catch (err) {
      onError(err.message || 'Failed to send quick notification.');
    } finally {
      setQuickNotifyKey('');
    }
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
        if (onSuccess) onSuccess(`Downloaded available PDF CVs. Skipped ${skipped.length} non-PDF/unavailable CV(s).`);
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
      
      {/* --- INFO BANNERS --- */}
      {!isJobFairDay && (
        <div className="mb-4 p-3 bg-blue-50 border border-blue-200 text-blue-800 rounded-lg text-sm flex items-center gap-2 font-medium">
          <Clock className="w-5 h-5 flex-shrink-0" />
          <span>Interview scheduling is only possible on job fair day.</span>
        </div>
      )}

      {isJobFairDay && !isPresent && (
        <div className="mb-4 p-3 bg-amber-50 border border-amber-200 text-amber-800 rounded-lg text-sm flex items-center gap-2 font-medium">
          <Clock className="w-5 h-5 flex-shrink-0" />
          <span>Please mark your attendance to start scheduling your interviews on job fair day.</span>
        </div>
      )}

      {/* --- KPI Stats Row --- */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatBox label="Pending Requests" value={pendingRequests.length} icon={Inbox} color="text-orange-600" bg="bg-orange-50" />
        <StatBox label="Accepted" value={acceptedRequests.length} icon={CheckCircle2} color="text-green-600" bg="bg-green-50" />
        <StatBox label="Scheduled" value={scheduledInterviews.length} icon={Calendar} color="text-blue-600" bg="bg-blue-50" />
        <StatBox label="Total Called" value={stats?.totalStudentsCalled || 0} icon={History} color="text-purple-600" bg="bg-purple-50" />
      </div>

      {/* --- Tabs --- */}
      <div className="border-b border-gray-200 overflow-x-auto">
        <div className="flex gap-6 min-w-max">
          <TabBtn id="pending" label="Inbox & Sent" count={pendingRequests.length} active={activeTab} onClick={setActiveTab} />
          <TabBtn id="accepted" label="Accepted" count={acceptedRequests.length} active={activeTab} onClick={setActiveTab} />
          <TabBtn id="scheduled" label="Scheduled Interviews" active={activeTab} onClick={setActiveTab} />
          <TabBtn id="completed" label="Completed" count={completedInterviews.length} active={activeTab} onClick={setActiveTab} />
        </div>
      </div>

      {/* --- PENDING REQUESTS VIEW --- */}
      {activeTab === 'pending' && (
        <div className="space-y-4">
          <div className="flex items-center gap-2">
            <button onClick={() => setPendingView('all')} className={`px-2.5 py-1.5 rounded-lg text-xs font-semibold ${pendingView === 'all' ? 'bg-slate-900 text-white' : 'bg-slate-100 text-slate-600'}`}>All ({pendingRequests.length})</button>
            <button onClick={() => setPendingView('inbox')} className={`px-2.5 py-1.5 rounded-lg text-xs font-semibold ${pendingView === 'inbox' ? 'bg-slate-900 text-white' : 'bg-slate-100 text-slate-600'}`}>Inbox ({pendingRequests.filter(r => r.requestedBy === 1 || r.requestedBy === 'Student').length})</button>
            <button onClick={() => setPendingView('sent')} className={`px-2.5 py-1.5 rounded-lg text-xs font-semibold ${pendingView === 'sent' ? 'bg-slate-900 text-white' : 'bg-slate-100 text-slate-600'}`}>Sent ({pendingRequests.filter(r => !(r.requestedBy === 1 || r.requestedBy === 'Student')).length})</button>
          </div>

          {filteredPendingRequests.length === 0 ? (
            <EmptyState message="No pending requests." />
          ) : (
            <div className="grid grid-cols-1 gap-4">
              {filteredPendingRequests.map(req => {
                // Logic: Check who requested (0 = Company, 1 = Student)
                const isIncoming = req.requestedBy === 1 || req.requestedBy === 'Student';

                return (
                  <div 
                    key={req.requestId} 
                    onClick={() => onSelectStudent && onSelectStudent(req, 'interviews')}
                    className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex flex-col md:flex-row items-start md:items-center gap-4 transition-all hover:border-blue-400 hover:shadow-md cursor-pointer group"
                  >
                    
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
                              <span className="font-bold text-gray-900 group-hover:text-blue-700">
                                {req.studentName}
                              </span>
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
                    <div className="flex items-center gap-2 w-full md:w-auto mt-2 md:mt-0" onClick={(e) => e.stopPropagation()}>
                      <button
                        onClick={() => onSelectStudent && onSelectStudent(req)}
                        className="flex-1 md:flex-none bg-white border border-gray-200 text-gray-700 px-3 py-2 rounded-lg text-sm font-medium hover:bg-gray-50"
                      >
                        View Profile
                      </button>

                      {isIncoming ? (
                        <>
                            <button 
                              onClick={() => { setActionModal({ type: 'accept', request: req }); }}
                              disabled={isInterviewWindowClosed}
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
          <div className="flex justify-end">
            {isJobFairDay && isPresent && (
              <button
                onClick={() => setShowBulkScheduleModal(true)}
                disabled={schedulingAll || acceptedRequests.length === 0 || isInterviewWindowClosed}
                className="bg-indigo-600 text-white px-3 py-2 rounded-lg text-xs font-semibold hover:bg-indigo-700 disabled:opacity-50 inline-flex items-center gap-2"
              >
                {schedulingAll ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Calendar className="w-3.5 h-3.5" />} Schedule All
              </button>
            )}
          </div>

          {acceptedRequests.length === 0 ? (
            <EmptyState message="No accepted requests." />
          ) : (
            <div className="bg-white rounded-xl border shadow-sm overflow-x-auto">
              <table className="w-full min-w-[980px] text-sm text-left">
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
                            isJobFairDay && isPresent ? (
                              <button
                                onClick={() => openScheduleModal(req, 'schedule')}
                                disabled={isInterviewWindowClosed}
                                className="bg-blue-600 text-white px-3 py-1.5 rounded-lg text-xs font-medium hover:bg-blue-700 inline-flex items-center gap-1"
                              >
                                <Calendar className="w-3.5 h-3.5" /> Schedule
                              </button>
                            ) : null
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
            <div className="bg-white rounded-xl border shadow-sm overflow-x-auto">
              <table className="w-full min-w-[900px] text-sm text-left">
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
                          {getRemainingSeconds(int) !== null && (
                            <div className={`px-2 py-1 rounded w-fit font-semibold ${getRemainingSeconds(int) >= 0 ? 'text-emerald-700 bg-emerald-50 border border-emerald-100' : 'text-red-700 bg-red-50 border border-red-100'}`}>
                              {getRemainingSeconds(int) >= 0
                                ? `Time Left: ${formatDurationLabel(getRemainingSeconds(int))}`
                                : `Overtime: ${formatDurationLabel(getRemainingSeconds(int))}`}
                            </div>
                          )}
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
                               disabled={startingInterviewId === int.interviewId || !canStartInterview(int)}
                               className="text-xs font-medium bg-green-600 hover:bg-green-700 text-white px-2.5 py-1 rounded disabled:opacity-50"
                               title={!canStartInterview(int) ? 'Start allowed only within ±15 minutes of scheduled time.' : 'Start interview'}
                             >
                               {startingInterviewId === int.interviewId ? 'Starting...' : 'Start Interview'}
                             </button>
                           )}

                           <button
                             onClick={() => openScheduleModal(int, 'reschedule')}
                             disabled={isInterviewWindowClosed}
                             className="text-xs font-medium bg-blue-600 hover:bg-blue-700 text-white px-2.5 py-1 rounded disabled:opacity-50"
                           >
                             Reschedule
                           </button>

                            <div className="relative inline-block group/notify">
                              <button
                                className="text-xs font-medium bg-indigo-600 hover:bg-indigo-700 text-white px-2.5 py-1 rounded inline-flex items-center gap-1"
                              >
                                <Bell className="w-3 h-3" /> Notify <ChevronDown className="w-3 h-3" />
                              </button>
                              <div className="absolute right-0 mt-1 w-48 bg-white border border-gray-200 rounded-lg shadow-xl opacity-0 invisible group-hover/notify:opacity-100 group-hover/notify:visible transition-all z-20 overflow-hidden">
                                <div className="p-1.5 space-y-0.5">
                                   <button 
                                     onClick={() => openNotifyModal(int)}
                                     className="w-full text-left px-3 py-2 text-xs font-medium text-gray-700 hover:bg-gray-50 hover:text-indigo-600 rounded flex items-center gap-2"
                                   >
                                     <Send className="w-3 h-3" /> Preview & Send
                                   </button>
                                   <div className="h-px bg-gray-100 my-1 mx-2"></div>
                                   <button 
                                     onClick={() => {
                                       const template = buildNotificationTemplate('NEXT', int);
                                       setNotifyPreset('NEXT');
                                       setNotifyTitle(template.title);
                                       setNotifyBody(template.body);
                                       setNotifyModal({ interview: int });
                                     }}
                                     className="w-full text-left px-3 py-2 text-xs font-medium text-gray-700 hover:bg-gray-50 hover:text-teal-600 rounded flex items-center gap-2"
                                   >
                                     <div className="w-2 h-2 rounded-full bg-teal-500"></div> You Are Next
                                   </button>
                                   <button 
                                     onClick={() => {
                                       const template = buildNotificationTemplate('DELAY', int);
                                       setNotifyPreset('DELAY');
                                       setNotifyTitle(template.title);
                                       setNotifyBody(template.body);
                                       setNotifyModal({ interview: int });
                                     }}
                                     className="w-full text-left px-3 py-2 text-xs font-medium text-gray-700 hover:bg-gray-50 hover:text-orange-600 rounded flex items-center gap-2"
                                   >
                                     <div className="w-2 h-2 rounded-full bg-orange-500"></div> Delay Update
                                   </button>
                                   <button 
                                     onClick={() => {
                                       const template = buildNotificationTemplate('SOON', int);
                                       setNotifyPreset('SOON');
                                       setNotifyTitle(template.title);
                                       setNotifyBody(template.body);
                                       setNotifyModal({ interview: int });
                                     }}
                                     className="w-full text-left px-3 py-2 text-xs font-medium text-gray-700 hover:bg-gray-50 hover:text-indigo-600 rounded flex items-center gap-2"
                                   >
                                     <div className="w-2 h-2 rounded-full bg-indigo-500"></div> Starting Soon
                                   </button>
                                </div>
                              </div>
                            </div>

                           {canMarkDidNotAppear(int) && (
                             <button
                               onClick={() => completeInterview(int.interviewId, 'DidNotAppear').then(() => {
                                 setRefreshKey(k => k + 1);
                                 if (onSuccess) onSuccess('Interview marked as student did not appear.');
                               }).catch((err) => onError(err.message))}
                               className="text-xs font-medium bg-slate-600 hover:bg-slate-700 text-white px-2.5 py-1 rounded"
                             >
                               Student Didn&apos;t Appear
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
                    <p className="text-xs text-gray-500">Academic Grade</p>
                    <p className="font-medium text-blue-700">
                      {(() => {
                        const latestEducation = [...(selectedStudentProfile.educations || [])]
                          .sort((a, b) => new Date(b.endDate || b.startDate || 0) - new Date(a.endDate || a.startDate || 0))[0];
                        return (
                          getEducationGradeLabel(latestEducation) ||
                          (selectedStudentProfile.cgpa?.toFixed
                            ? `CGPA: ${selectedStudentProfile.cgpa.toFixed(2)}`
                            : (selectedStudentProfile.cgpa ? `CGPA: ${selectedStudentProfile.cgpa}` : 'N/A'))
                        );
                      })()}
                    </p>
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
                            {getEducationGradeLabel(edu) && (
                              <p className="text-xs text-blue-700 mt-1">{getEducationGradeLabel(edu)}</p>
                            )}
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
            <div className="bg-white rounded-xl border shadow-sm overflow-x-auto">
              <div className="px-4 py-3 border-b bg-gray-50 flex justify-end">
                <button
                  onClick={handleDownloadAllCompletedCvs}
                  disabled={downloadingAllCvs}
                  className="inline-flex items-center gap-2 text-xs font-medium bg-indigo-600 hover:bg-indigo-700 text-white px-3 py-1.5 rounded-lg disabled:opacity-50"
                >
                  {downloadingAllCvs ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Download className="w-3.5 h-3.5" />} Download All CVs
                </button>
              </div>
              <table className="w-full min-w-[900px] text-sm text-left">
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
                          
                          {String(item.status).toLowerCase() === 'didnotappear' && isJobFairDay && (
                            <button
                              onClick={() => openScheduleModal(item, 'reschedule')}
                              className="text-amber-600 hover:text-amber-700 text-xs font-bold border border-amber-200 bg-amber-50 px-2 py-1 rounded inline-flex items-center gap-1"
                              title="Reschedule this candidate"
                            >
                              <Calendar className="w-3.5 h-3.5" /> Reschedule
                            </button>
                          )}

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
                Candidate: <span className="font-medium text-gray-900">{scheduleModal.target.studentName}</span>
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
                  {scheduling ? <Loader2 className="animate-spin w-4 h-4" /> : (scheduleModal.mode === 'reschedule' ? 'Reschedule Interview' : 'Schedule Interview')}
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
                <option value="DidNotAppear">Student Didn&apos;t Appear</option>
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

      {notifyModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 animate-fade-in">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-xl overflow-hidden">
            <div className="p-6 border-b">
              <h3 className="text-lg font-bold text-gray-900">Send Notification</h3>
              <p className="text-sm text-gray-500 mt-1">
                Student: <span className="font-medium text-gray-900">{notifyModal.interview.studentName}</span>
              </p>
            </div>

            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Preset</label>
                <select
                  value={notifyPreset}
                  onChange={(e) => handlePresetChange(e.target.value)}
                  className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 outline-none"
                >
                  <option value="NEXT">You are next, please come</option>
                  <option value="SOON">Interview starts soon</option>
                  <option value="DELAY">Interview delayed due to overtime</option>
                  <option value="CUSTOM">Custom message</option>
                </select>
                {notifyPreset === 'DELAY' && getGlobalOvertimeMinutes() <= 0 && (
                  <p className="mt-1 text-xs text-amber-700">No active overtime detected right now. You can still edit and send the message manually.</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Title</label>
                <input
                  value={notifyTitle}
                  onChange={(e) => setNotifyTitle(e.target.value)}
                  className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 outline-none"
                  placeholder="Notification title"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Message</label>
                <textarea
                  rows={4}
                  value={notifyBody}
                  onChange={(e) => setNotifyBody(e.target.value)}
                  className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 outline-none resize-none"
                  placeholder="Write your custom message to the student"
                />
              </div>

              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setNotifyModal(null)}
                  className="flex-1 py-2.5 text-gray-600 font-medium hover:bg-gray-100 rounded-lg"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  disabled={sendingNotification}
                  onClick={handleSendStudentNotification}
                  className="flex-1 py-2.5 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 disabled:opacity-50 flex justify-center items-center gap-2"
                >
                  {sendingNotification ? <Loader2 className="animate-spin w-4 h-4" /> : 'Send Notification'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {showBulkScheduleModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 animate-fade-in">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-sm overflow-hidden">
            <div className="p-6 border-b bg-indigo-50">
               <div className="w-12 h-12 bg-indigo-100 text-indigo-600 rounded-full flex items-center justify-center mb-3">
                  <Calendar className="w-6 h-6" />
               </div>
               <h3 className="text-lg font-bold text-gray-900">Schedule All Interviews</h3>
               <p className="text-sm text-gray-500 mt-1">Pick a starting time for the optimization.</p>
            </div>
            <div className="p-6 space-y-4">
               <div>
                  <label className="block text-sm font-bold text-gray-700 mb-2">Start Scheduling From</label>
                  <input 
                    type="time" 
                    value={bulkScheduleStartTime}
                    onChange={(e) => setBulkScheduleStartTime(e.target.value)}
                    className="w-full p-3 border-2 border-gray-100 rounded-xl focus:border-indigo-500 focus:ring-4 focus:ring-indigo-50/50 outline-none transition-all font-medium text-lg"
                  />
                  <p className="mt-2 text-xs text-gray-500 bg-gray-50 p-2 rounded-lg border border-gray-100">
                    Interviews will be scheduled sequentially starting from this time, respecting existing bookings.
                  </p>
               </div>
               <div className="flex gap-3 pt-2">
                  <button onClick={() => setShowBulkScheduleModal(false)} className="flex-1 py-3 text-gray-500 font-bold hover:bg-gray-100 rounded-xl transition-colors">Cancel</button>
                  <button 
                    onClick={() => handleScheduleAllAccepted(bulkScheduleStartTime)}
                    disabled={schedulingAll}
                    className="flex-1 py-3 bg-indigo-600 text-white font-bold rounded-xl hover:bg-indigo-700 shadow-md shadow-indigo-100 flex items-center justify-center gap-2 transition-all active:scale-95"
                  >
                    {schedulingAll ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Start Scheduling'}
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