/* eslint-disable no-unused-vars */
/* eslint-disable react-hooks/set-state-in-effect */
import React, { useState, useEffect } from 'react';
import AnalyticsView from '../components/AnalyticsView';
import StudentDirectory from '../components/StudentDirectory';
import NoticesBoard from '../components/NoticesBoard';
import StudentProfile from '../components/StudentProfile';
import FYPExplorer from '../components/FYPExplorer';
import FYPDetails from '../components/FYPDetails';
import InterviewManager from '../components/InterviewManager';
import CompanyProfile from '../components/CompanyProfile';
import CompanyRequests from '../components/CompanyRequests';
import SurveyForm from '../components/SurveyForm';
import AttendanceScanner from '../components/AttendanceScanner';
import PreviousJobFairAnalytics from '../components/PreviousJobFairAnalytics';
import { getConfirmationStatus, getCompanyProfile, getNotices } from '../api';
import { getMySurveyStatus } from '../api';

const SURVEY_REMINDER_INTERVAL_MS = 20 * 60 * 1000;
const NOTICE_BANNER_REFRESH_MS = 5 * 60 * 1000;

const getPktDateParts = (inputDate) => {
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Karachi',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });

  const parts = formatter.formatToParts(new Date(inputDate));
  const pick = (type) => Number(parts.find((p) => p.type === type)?.value || 0);

  return {
    year: pick('year'),
    month: pick('month'),
    day: pick('day'),
    hour: pick('hour'),
    minute: pick('minute'),
  };
};

const isAfterMandatorySurveyTimePkt = (jobFairDate) => {
  if (!jobFairDate) return false;
  const now = getPktDateParts(new Date());
  const fair = getPktDateParts(jobFairDate);
  const nowDateNum = now.year * 10000 + now.month * 100 + now.day;
  const fairDateNum = fair.year * 10000 + fair.month * 100 + fair.day;

  if (nowDateNum !== fairDateNum) return false;
  return now.hour > 14 || (now.hour === 14 && now.minute >= 0);
};

export default function CompanyDashboard({ user, onError, onSuccess, activeTab, onTabChange, profileContext, onProfileContextChange }) {
  const [selectedStudentId, setSelectedStudentId] = useState(null);
  const [selectedProjectId, setSelectedProjectId] = useState(null);
  const [showAttendanceScanner, setShowAttendanceScanner] = useState(false);
  const [attendanceStatus, setAttendanceStatus] = useState(null);
  const [surveyAvailability, setSurveyAvailability] = useState({ hasActiveJobFair: true, isJobFairDay: true });
  const [surveySubmitted, setSurveySubmitted] = useState(false);
  const [surveyReminderOpen, setSurveyReminderOpen] = useState(false);
  const [interviewNavTarget, setInterviewNavTarget] = useState({ tab: 'pending', pendingView: 'all', key: 0 });
  const [profileTab, setProfileTab] = useState('profile');
  const [profileCompletion, setProfileCompletion] = useState({ isComplete: true, missingFields: [] });
  const [companyBannerNotices, setCompanyBannerNotices] = useState([]);

  const reminderStorageKey = `companySurveyReminderLastShown:${user?.id || user?.email || 'default'}`;

  const refreshSurveyStatus = () => {
    getMySurveyStatus()
      .then((status) => {
        const hasActive = Boolean(status?.hasActiveJobFair ?? status?.HasActiveJobFair ?? true);
        const isFairDay = Boolean(status?.isJobFairDay ?? status?.IsJobFairDay ?? false);
        const submittedData = status?.submitted || status?.Submitted || {};
        const cdcSubmitted = Boolean(submittedData.cdc ?? submittedData.Cdc);
        const departmentSubmitted = Boolean(submittedData.department ?? submittedData.Department);

        setSurveyAvailability({
          hasActiveJobFair: hasActive,
          isJobFairDay: isFairDay,
        });
        setSurveySubmitted(cdcSubmitted && departmentSubmitted);
      })
      .catch(() => setSurveyAvailability({ hasActiveJobFair: true, isJobFairDay: false }));
  };

  const refreshCompanyBannerNotices = () => {
    getNotices()
      .then((items) => {
        const notices = Array.isArray(items) ? items : [];
        const banners = notices
          .filter((n) => Boolean(n?.isBanner ?? n?.IsBanner))
          .map((n) => {
            const title = String(n?.title || n?.Title || '').trim();
            const content = String(n?.content || n?.Content || '').trim();
            if (title && content) return `${title}: ${content}`;
            return title || content;
          })
          .filter(Boolean);

        setCompanyBannerNotices(banners);
      })
      .catch(() => setCompanyBannerNotices([]));
  };

  const normalizedAttendance = attendanceStatus
    ? {
        jobFairDate: attendanceStatus.jobFairDate || attendanceStatus.JobFairDate,
        isPresent: attendanceStatus.isPresent ?? attendanceStatus.IsPresent,
        arrivalStatus: attendanceStatus.arrivalStatus || attendanceStatus.ArrivalStatus,
      }
    : null;

  const applyProfileCompletion = (profile) => {
    const completion = profile?.profileCompletion || profile?.ProfileCompletion || {};
    const isComplete = Boolean(completion.isComplete ?? completion.IsComplete ?? true);
    const missingFields = completion.missingFields || completion.MissingFields || [];
    setProfileCompletion({ isComplete, missingFields });
    return { isComplete };
  };

  useEffect(() => {
    let cancelled = false;

    getCompanyProfile()
      .then((profile) => {
        if (cancelled) return;

        const { isComplete } = applyProfileCompletion(profile);

        if (!isComplete && activeTab !== 'profile' && onTabChange) {
          onTabChange('profile');
        }
      })
      .catch(() => {
        if (!cancelled) {
          setProfileCompletion({ isComplete: true, missingFields: [] });
        }
      });

    return () => {
      cancelled = true;
    };
  }, [activeTab, onTabChange]);

  const showSurveyHeadline =
    surveyAvailability.hasActiveJobFair &&
    surveyAvailability.isJobFairDay &&
    Boolean(normalizedAttendance?.isPresent) &&
    !surveySubmitted;

  useEffect(() => {
    setSelectedStudentId(null);
    setSelectedProjectId(null);
  }, [activeTab]);

  useEffect(() => {
    getConfirmationStatus()
      .then((status) => setAttendanceStatus(status))
      .catch(() => setAttendanceStatus(null));

    refreshSurveyStatus();
    refreshCompanyBannerNotices();

    const noticeIntervalId = setInterval(refreshCompanyBannerNotices, NOTICE_BANNER_REFRESH_MS);
    return () => clearInterval(noticeIntervalId);
  }, []);

  useEffect(() => {
    const checkReminder = () => {
      const isPresent = Boolean(normalizedAttendance?.isPresent);
      const isSurveyPending = !surveySubmitted;
      const shouldPrompt =
        surveyAvailability.hasActiveJobFair &&
        surveyAvailability.isJobFairDay &&
        isPresent &&
        isSurveyPending &&
        isAfterMandatorySurveyTimePkt(normalizedAttendance?.jobFairDate);

      if (!shouldPrompt) {
        setSurveyReminderOpen(false);
        return;
      }

      const lastShown = Number(localStorage.getItem(reminderStorageKey) || 0);
      const nowMs = Date.now();
      if (!lastShown || nowMs - lastShown >= SURVEY_REMINDER_INTERVAL_MS) {
        setSurveyReminderOpen(true);
        localStorage.setItem(reminderStorageKey, String(nowMs));
      }
    };

    checkReminder();
    const intervalId = setInterval(checkReminder, 60 * 1000);
    return () => clearInterval(intervalId);
  }, [
    surveyAvailability.hasActiveJobFair,
    surveyAvailability.isJobFairDay,
    surveySubmitted,
    normalizedAttendance?.isPresent,
    normalizedAttendance?.jobFairDate,
    reminderStorageKey,
  ]);

  const refreshAttendanceStatus = () => {
    getConfirmationStatus()
      .then((status) => setAttendanceStatus(status))
      .catch(() => setAttendanceStatus(null));
  };

  const jobFairDate = normalizedAttendance?.jobFairDate ? new Date(normalizedAttendance.jobFairDate) : null;
  const isJobFairDay = jobFairDate ? jobFairDate.toDateString() === new Date().toDateString() : false;
  const isOnSpotRegistration = String(normalizedAttendance?.arrivalStatus || '').toLowerCase() === 'onspot';
  const canMarkAttendance = isJobFairDay && !normalizedAttendance?.isPresent && !isOnSpotRegistration;
  const bannerMessages = [];

  if (!profileCompletion.isComplete) {
    const missingText = profileCompletion.missingFields?.length > 0 ? `Missing: ${profileCompletion.missingFields.join(', ')}.` : 'Your profile still has required fields to complete.';
    bannerMessages.push(`Complete your company profile before moving forward. ${missingText}`);
  }

  if (showSurveyHeadline) {
    bannerMessages.push('Fill both CDC and Department surveys today to be eligible for your Job Fair participation certificate.');
  }

  if (companyBannerNotices.length > 0) {
    bannerMessages.push(...companyBannerNotices);
  }

  const safeSelectStudent = (student, tab = 'profile') => {
    const id = student.studentId || student.StudentId || student.id || student.Id;
    if (id) {
      const fromPastAnalytics = Boolean(student.fromPastAnalytics || student.FromPastAnalytics);
      if (onProfileContextChange) {
        onProfileContextChange(fromPastAnalytics ? 'history' : 'current');
      }
      setProfileTab(tab);
      setSelectedProjectId(null);
      setSelectedStudentId(id);
    }
    else {
      console.error("Student ID missing:", student);
      onError("Error: Could not load student details");
    }
  };

  // --- NAVIGATION CONTROLLER ---

  if (selectedProjectId) {
    return (
      <div className="max-w-6xl mx-auto animate-fade-in py-6">
        <FYPDetails 
          projectId={selectedProjectId} 
          onBack={() => setSelectedProjectId(null)} 
          onSelectStudent={safeSelectStudent} 
          onError={onError} 
        />
      </div>
    );
  }

  if (showAttendanceScanner) {
    return (
      <AttendanceScanner
        onBack={() => setShowAttendanceScanner(false)}
        onError={onError}
        onMarked={(result) => {
          const roomName = result?.roomName || result?.RoomName;
          const companyName = result?.companyName || result?.CompanyName || user?.name || 'Company';
          const needsManualRoomAllotment = Boolean(result?.needsManualRoomAllotment ?? result?.NeedsManualRoomAllotment);
          const apiMessage = result?.message || result?.Message;

          const welcomeMessage = needsManualRoomAllotment
            ? `Welcome ${companyName}! Attendance marked successfully. No suitable room is currently available, please ask administration for manual room allotment.`
            : roomName
              ? `Welcome ${companyName}! Your room number is ${roomName}.`
              : (apiMessage || `Welcome ${companyName}! Attendance marked successfully.`);
          window.alert(welcomeMessage);
          refreshAttendanceStatus();
          setShowAttendanceScanner(false);
        }}
      />
    );
  }

  if (selectedStudentId) {
    return (
      <div className="max-w-6xl mx-auto animate-fade-in py-6">
        <StudentProfile 
          studentId={selectedStudentId} 
          onBack={() => setSelectedStudentId(null)} 
          readOnly={profileContext === 'history'}
          initialTab={profileTab}
          onNavigateToInterviews={() => {
            setSelectedStudentId(null);
            if (onTabChange) onTabChange('interviews');
          }}
          onViewFYP={(projectId) => {
            setSelectedStudentId(null);
            setSelectedProjectId(projectId);
          }}
        />
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto animate-fade-in">
      {bannerMessages.length > 0 && (
        <div className="mb-4 overflow-hidden rounded-xl border border-red-300 bg-gradient-to-r from-red-600 via-rose-600 to-red-700 px-4 py-3 text-white shadow-lg">
          <div className="company-survey-marquee whitespace-nowrap text-sm font-semibold tracking-wide">
            {bannerMessages.map((message, index) => (
              <span key={index} className="inline-flex items-center">
                <span>{message}</span>
                {index < bannerMessages.length - 1 && <span className="mx-4 text-white/70">•</span>}
              </span>
            ))}
          </div>
        </div>
      )}
      {canMarkAttendance && (
        <div className="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-lg flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <div>
            <p className="text-sm font-semibold text-blue-900">Job Fair Attendance</p>
            <p className="text-xs text-blue-700">Today is Job Fair day. Scan the admin QR to mark your company as present.</p>
          </div>
          <button
            onClick={() => setShowAttendanceScanner(true)}
            className="w-full sm:w-auto px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-medium"
          >
            Mark Attendance
          </button>
        </div>
      )}
      {activeTab === 'overview' && (
        <AnalyticsView
          onError={onError}
          onSuccess={onSuccess}
          attendanceStatus={attendanceStatus}
          onNavigateToInterviews={(tab = 'pending', pendingView = 'all') => {
            setInterviewNavTarget({ tab, pendingView, key: Date.now() });
            if (onTabChange) onTabChange('interviews');
          }}
        />
      )}
      {activeTab === 'history-analytics' && <PreviousJobFairAnalytics onError={onError} onSuccess={onSuccess} onSelectStudent={safeSelectStudent} />}
      {activeTab === 'profile' && (
        <CompanyProfile
          onError={onError}
          onSuccess={onSuccess}
          onProfileCompletionChange={(completion) => setProfileCompletion(completion)}
        />
      )}
      {activeTab === 'students' && (
        <StudentDirectory
          onSelect={safeSelectStudent}
          onError={onError}
          onSuccess={onSuccess}
          onNavigateToInterviews={() => onTabChange && onTabChange('interviews')}
        />
      )}
      {activeTab === 'fyps' && <FYPExplorer onSelectProject={(id) => setSelectedProjectId(id)} onError={onError} />}
      {activeTab === 'interviews' && (
        <InterviewManager
          user={user}
          roomName={attendanceStatus?.RoomDetails?.RoomName}
          onError={onError}
          onSuccess={onSuccess}
          onSelectStudent={safeSelectStudent}
          navigationTarget={interviewNavTarget}
          isPresent={Boolean(normalizedAttendance?.isPresent)}
          isJobFairDay={isJobFairDay}
        />
      )}
      {activeTab === 'requests' && <CompanyRequests onError={onError} onSuccess={onSuccess} />}
      {activeTab === 'surveys' && (
        <SurveyForm
          onError={onError}
          onSuccess={(message) => {
            if (onSuccess) onSuccess(message);
            refreshSurveyStatus();
          }}
          forceDisabled={!(surveyAvailability.hasActiveJobFair && surveyAvailability.isJobFairDay)}
        />
      )}
      {activeTab === 'notices' && <NoticesBoard onError={onError} />}
    </div>
  );
}