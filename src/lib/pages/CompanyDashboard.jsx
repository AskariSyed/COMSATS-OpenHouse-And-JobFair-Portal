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
import { getConfirmationStatus } from '../api';

export default function CompanyDashboard({ user, onError, activeTab }) {
  const [selectedStudentId, setSelectedStudentId] = useState(null);
  const [selectedProjectId, setSelectedProjectId] = useState(null);
  const [showAttendanceScanner, setShowAttendanceScanner] = useState(false);
  const [attendanceStatus, setAttendanceStatus] = useState(null);

  useEffect(() => {
    setSelectedStudentId(null);
    setSelectedProjectId(null);
  }, [activeTab]);

  useEffect(() => {
    getConfirmationStatus()
      .then((status) => setAttendanceStatus(status))
      .catch(() => setAttendanceStatus(null));
  }, []);

  const refreshAttendanceStatus = () => {
    getConfirmationStatus()
      .then((status) => setAttendanceStatus(status))
      .catch(() => setAttendanceStatus(null));
  };

  const jobFairDate = attendanceStatus?.jobFairDate ? new Date(attendanceStatus.jobFairDate) : null;
  const isJobFairDay = jobFairDate ? jobFairDate.toDateString() === new Date().toDateString() : false;
  const canMarkAttendance = isJobFairDay && !attendanceStatus?.isPresent;

  const safeSelectStudent = (student) => {
    const id = student.studentId || student.StudentId || student.id || student.Id;
    if (id) {
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
        onMarked={() => {
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
      {canMarkAttendance && (
        <div className="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-lg flex items-center justify-between gap-3">
          <div>
            <p className="text-sm font-semibold text-blue-900">Job Fair Attendance</p>
            <p className="text-xs text-blue-700">Today is Job Fair day. Scan the admin QR to mark your company as present.</p>
          </div>
          <button
            onClick={() => setShowAttendanceScanner(true)}
            className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-medium whitespace-nowrap"
          >
            Mark Attendance
          </button>
        </div>
      )}
      {activeTab === 'overview' && <AnalyticsView onError={onError} />}
      {activeTab === 'profile' && <CompanyProfile onError={onError} />}
      {activeTab === 'students' && <StudentDirectory onSelect={safeSelectStudent} onError={onError} />}
      {activeTab === 'fyps' && <FYPExplorer onSelectProject={(id) => setSelectedProjectId(id)} onError={onError} />}
      {activeTab === 'interviews' && <InterviewManager onError={onError} />}
      {activeTab === 'requests' && <CompanyRequests onError={onError} />}
      {activeTab === 'surveys' && <SurveyForm onError={onError} />}
      {activeTab === 'notices' && <NoticesBoard onError={onError} />}
    </div>
  );
}