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
import CompanyProfile from '../components/CompanyProfile'; // <--- IMPORT

export default function CompanyDashboard({ user, onError, activeTab }) {
  const [selectedStudentId, setSelectedStudentId] = useState(null);
  const [selectedProjectId, setSelectedProjectId] = useState(null);

  useEffect(() => {
    setSelectedStudentId(null);
    setSelectedProjectId(null);
  }, [activeTab]);

  const safeSelectStudent = (student) => {
    const id = student.studentId || student.StudentId || student.id || student.Id;
    if (id) setSelectedStudentId(id);
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
      {activeTab === 'overview' && <AnalyticsView onError={onError} />}
      {activeTab === 'profile' && <CompanyProfile onError={onError} />}  {/* <--- ADDED THIS */}
      {activeTab === 'students' && <StudentDirectory onSelect={safeSelectStudent} onError={onError} />}
      {activeTab === 'fyps' && <FYPExplorer onSelectProject={(id) => setSelectedProjectId(id)} onError={onError} />}
      {activeTab === 'interviews' && <InterviewManager onError={onError} />}
      {activeTab === 'notices' && <NoticesBoard onError={onError} />}
    </div>
  );
}