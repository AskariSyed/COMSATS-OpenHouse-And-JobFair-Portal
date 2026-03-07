import React, { useState, useEffect, useMemo } from 'react';
import { Search, Loader2, GraduationCap, AlertCircle, Clock, CheckCircle2, XCircle, UserPlus, Eye, Send, Calendar, Download, X } from 'lucide-react';
import { getStudents, getStudentsByInterviewStatus, getFileUrl, sendInterviewRequest } from '../api';
import { allSkillsList, skillsData } from '../../data/skills';

export default function StudentDirectory({ onSelect, onError, onSuccess, onNavigateToInterviews }) {
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(false);
  const [filters, setFilters] = useState({ name: '', registration: '', department: '', skills: [] });
  const [sortBy, setSortBy] = useState('name'); // Default sort by name
  const [listMode, setListMode] = useState('all');
  const [requestingStudentId, setRequestingStudentId] = useState(null);
  const [skillToAdd, setSkillToAdd] = useState('');

  const fetchStudents = async () => {
    setLoading(true);
    try {
      let data;
      if (listMode === 'all') {
        // Fetch full list and apply filters on client to support richer search combinations.
        data = await getStudents();
      } else {
        data = await getStudentsByInterviewStatus(listMode);
      }
      setStudents(data || []);
    } catch (err) {
      onError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchStudents(); }, [listMode]);

  const normalize = (val) => String(val || '').trim().toLowerCase();
  const cleanReg = (val) => normalize(val).replace(/[^a-z0-9]/g, '');

  const formatRegistrationInput = (val) => String(val || '')
    .toUpperCase()
    .replace(/[^A-Z0-9-]/g, '')
    .replace(/-{2,}/g, '-');

  const departmentOptions = useMemo(() => {
    const fromStudents = (students || [])
      .map((s) => s.Department || s.department || '')
      .filter(Boolean);
    const fromSkillsData = (skillsData?.departments || []).map((d) => d.name).filter(Boolean);
    return [...new Set([...fromSkillsData, ...fromStudents])].sort((a, b) => a.localeCompare(b));
  }, [students]);

  const availableSkills = useMemo(
    () => allSkillsList.filter((skill) => !filters.skills.includes(skill)),
    [filters.skills]
  );

  const filteredStudents = useMemo(() => {
    const nameQuery = normalize(filters.name);
    const regQuery = cleanReg(filters.registration);
    const deptQuery = normalize(filters.department);
    const selectedSkills = (filters.skills || []).map(normalize).filter(Boolean);

    return (students || []).filter((s) => {
      const studentName = normalize(s.Name || s.name);
      const studentReg = cleanReg(s.RegistrationNo || s.registrationNo);
      const studentDept = normalize(s.Department || s.department);
      const studentSkills = (s.Skills || s.skills || []).map(normalize);

      const matchesName = !nameQuery || studentName.includes(nameQuery);
      const matchesRegistration = !regQuery || studentReg.includes(regQuery);
      const matchesDepartment = !deptQuery || studentDept === deptQuery;
      const matchesSkills = selectedSkills.length === 0 || selectedSkills.every((skill) => studentSkills.includes(skill));

      return matchesName && matchesRegistration && matchesDepartment && matchesSkills;
    });
  }, [students, filters, listMode]);

  const handleSearch = (e) => {
    e.preventDefault();
    fetchStudents();
  };

  const handleAddSkill = (skill) => {
    if (!skill) return;
    setFilters((prev) => {
      if (prev.skills.includes(skill)) return prev;
      return { ...prev, skills: [...prev.skills, skill] };
    });
    setSkillToAdd('');
  };

  const handleRemoveSkill = (skill) => {
    setFilters((prev) => ({ ...prev, skills: prev.skills.filter((s) => s !== skill) }));
  };

  const handleClearFilters = () => {
    setFilters({ name: '', registration: '', department: '', skills: [] });
    setSkillToAdd('');
  };

  const getInterviewMeta = (student) => {
    const req = student.InterviewRequest || student.interviewRequest || {};
    const hasRequest = req.HasRequest === true || req.hasRequest === true;
    const reqStatus = normalize(req.Status || req.status);
    const currentInterviewStatus = normalize(student.CurrentInterviewStatus || student.currentInterviewStatus);
    const currentInterviewId = student.CurrentInterviewId || student.currentInterviewId || null;

    const cvUrl = student.CvUrl || student.cvUrl || student.CVUrl || student.user?.cvUrl || null;
    const isAccepted = reqStatus === 'accepted';
    const alreadyScheduled = Boolean(currentInterviewId) || currentInterviewStatus === 'queued' || currentInterviewStatus === 'inprogress';

    return {
      canSendRequest: !hasRequest,
      canSchedule: isAccepted,
      alreadyScheduled,
      cvUrl,
    };
  };

  const handleSendInterviewRequest = async (student) => {
    const studentId = getStudentId(student);
    if (!studentId) {
      onError('Missing Student ID');
      return;
    }

    setRequestingStudentId(studentId);
    try {
      await sendInterviewRequest(studentId);
      await fetchStudents();
      if (onSuccess) onSuccess('Interview request sent successfully.');
    } catch (err) {
      onError(err.message);
    } finally {
      setRequestingStudentId(null);
    }
  };

  const renderActionButtons = (student, safeId, compact = false) => {
    const { canSendRequest, canSchedule, alreadyScheduled, cvUrl } = getInterviewMeta(student);

    const iconBtnBase = 'w-8 h-8 rounded-full inline-flex items-center justify-center transition-colors';

    return (
      <div className={`flex ${compact ? 'justify-center' : 'justify-center'} items-center gap-1 flex-wrap`}>
        <button
          onClick={() => {
            if (!safeId) return onError('Missing Student ID');
            onSelect({ ...student, studentId: safeId });
          }}
          className={`${iconBtnBase} text-blue-600 hover:bg-blue-50`}
          title="View Profile"
          aria-label="View Profile"
        >
          <Eye className="w-4 h-4" />
        </button>

        {cvUrl && (
          <a
            href={getFileUrl(cvUrl)}
            target="_blank"
            rel="noreferrer"
            className={`${iconBtnBase} text-gray-700 hover:bg-gray-100`}
            title="View / Download CV"
            aria-label="View or Download CV"
          >
            <Download className="w-4 h-4" />
          </a>
        )}

        {canSendRequest && (
          <button
            onClick={() => handleSendInterviewRequest(student)}
            disabled={requestingStudentId === safeId}
            className={`${iconBtnBase} text-blue-700 hover:bg-blue-100 disabled:opacity-60`}
            title="Request Interview"
            aria-label="Request Interview"
          >
            {requestingStudentId === safeId ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
          </button>
        )}

        {canSchedule && (
          <button
            onClick={() => {
              if (onNavigateToInterviews) {
                onNavigateToInterviews();
                return;
              }
              if (!safeId) return onError('Missing Student ID');
              onSelect({ ...student, studentId: safeId });
            }}
            disabled={alreadyScheduled}
            className={`${iconBtnBase} ${alreadyScheduled ? 'text-emerald-700 bg-emerald-50' : 'text-indigo-700 hover:bg-indigo-100'} disabled:opacity-50`}
            title={alreadyScheduled ? 'Interview already scheduled' : 'Schedule Interview'}
            aria-label={alreadyScheduled ? 'Interview already scheduled' : 'Schedule Interview'}
          >
            <Calendar className="w-4 h-4" />
          </button>
        )}
      </div>
    );
  };

  // Sorting Logic
  const getSortedStudents = () => {
    return [...filteredStudents].sort((a, b) => {
      if (sortBy === 'cgpa') {
        const cgpaA = Number(a.CGPA ?? a.cgpa ?? -1);
        const cgpaB = Number(b.CGPA ?? b.cgpa ?? -1);
        return cgpaB - cgpaA;
      }

      const getVal = (obj, key) => {
        // Handle case sensitivity and potential nulls
        const val = obj[key] || obj[key.toLowerCase()] || '';
        return val.toString().toLowerCase();
      };

      const valA = getVal(a, sortBy === 'registration' ? 'RegistrationNo' : sortBy === 'department' ? 'Department' : 'Name');
      const valB = getVal(b, sortBy === 'registration' ? 'RegistrationNo' : sortBy === 'department' ? 'Department' : 'Name');
      
      return valA.localeCompare(valB);
    });
  };

  const sortedStudents = getSortedStudents();

  const getStudentId = (s) => s.StudentId || s.studentId || s.id;

  // --- LOGIC: Render Status Chip ---
  const renderStatusChip = (student) => {
    const interviewOutcome = (student.InterviewOutcome || student.interviewOutcome || '').toLowerCase();
    const currentInterviewStatus = (student.CurrentInterviewStatus || student.currentInterviewStatus || '').toLowerCase();

    if (currentInterviewStatus === 'queued') {
      return (
        <span className="bg-blue-100 text-blue-700 text-[10px] font-bold px-2 py-1 rounded-full inline-flex items-center gap-1 border border-blue-200 whitespace-nowrap">
          <Clock className="w-3 h-3" /> Queued
        </span>
      );
    }
    if (currentInterviewStatus === 'inprogress') {
      return (
        <span className="bg-purple-100 text-purple-700 text-[10px] font-bold px-2 py-1 rounded-full inline-flex items-center gap-1 border border-purple-200 whitespace-nowrap">
          <Clock className="w-3 h-3" /> In Progress
        </span>
      );
    }
    if (currentInterviewStatus === 'hired') {
      return (
        <span className="bg-emerald-100 text-emerald-700 text-[10px] font-bold px-2 py-1 rounded-full inline-flex items-center gap-1 border border-emerald-200 whitespace-nowrap">
          <CheckCircle2 className="w-3 h-3" /> Hired
        </span>
      );
    }
    if (currentInterviewStatus === 'shortlisted') {
      return (
        <span className="bg-blue-100 text-blue-700 text-[10px] font-bold px-2 py-1 rounded-full inline-flex items-center gap-1 border border-blue-200 whitespace-nowrap">
          <CheckCircle2 className="w-3 h-3" /> Shortlisted
        </span>
      );
    }
    if (currentInterviewStatus === 'rejected') {
      return (
        <span className="bg-red-50 text-red-600 text-[10px] font-bold px-2 py-1 rounded-full inline-flex items-center gap-1 border border-red-100 whitespace-nowrap">
          <XCircle className="w-3 h-3" /> Rejected
        </span>
      );
    }

    if (interviewOutcome === 'hired') {
      return (
        <span className="bg-emerald-100 text-emerald-700 text-[10px] font-bold px-2 py-1 rounded-full inline-flex items-center gap-1 border border-emerald-200 whitespace-nowrap">
          <CheckCircle2 className="w-3 h-3" /> Hired
        </span>
      );
    }
    if (interviewOutcome === 'shortlisted') {
      return (
        <span className="bg-blue-100 text-blue-700 text-[10px] font-bold px-2 py-1 rounded-full inline-flex items-center gap-1 border border-blue-200 whitespace-nowrap">
          <CheckCircle2 className="w-3 h-3" /> Shortlisted
        </span>
      );
    }
    if (interviewOutcome === 'rejected') {
      return (
        <span className="bg-red-50 text-red-600 text-[10px] font-bold px-2 py-1 rounded-full inline-flex items-center gap-1 border border-red-100 whitespace-nowrap">
          <XCircle className="w-3 h-3" /> Rejected
        </span>
      );
    }

    const req = student.InterviewRequest || student.interviewRequest;
    
    if (!req || (!req.HasRequest && !req.hasRequest)) return null;

    const status = (req.Status || req.status || '').toLowerCase();
    // Handle Enum: 0 = Company, 1 = Student
    const requestedByVal = req.RequestedBy !== undefined ? req.RequestedBy : req.requestedBy;
    const isStudentRequest = requestedByVal === 1 || requestedByVal === 'Student';

    if (status === 'accepted') {
        return (
        <span className="bg-green-100 text-green-700 text-[10px] font-bold px-2 py-1 rounded-full inline-flex items-center gap-1 border border-green-200 whitespace-nowrap">
          <CheckCircle2 className="w-3 h-3" /> Accepted
            </span>
        );
    }
    if (status === 'rejected') {
        return (
        <span className="bg-red-50 text-red-600 text-[10px] font-bold px-2 py-1 rounded-full inline-flex items-center gap-1 border border-red-100 whitespace-nowrap">
                <XCircle className="w-3 h-3" /> Rejected
            </span>
        );
    }
    if (status === 'pending') {
        if (isStudentRequest) {
            return (
          <span className="bg-purple-100 text-purple-700 text-[10px] font-bold px-2 py-1 rounded-full inline-flex items-center gap-1 border border-purple-200 whitespace-nowrap animate-pulse">
            <UserPlus className="w-3 h-3" /> Incoming
                </span>
            );
        } else {
            return (
          <span className="bg-yellow-50 text-yellow-700 text-[10px] font-bold px-2 py-1 rounded-full inline-flex items-center gap-1 border border-yellow-200 whitespace-nowrap">
            <Clock className="w-3 h-3" /> Sent
                </span>
            );
        }
    }
    return null;
  };

  return (
    <div>
      <div className="bg-white p-3 rounded-xl shadow-sm border border-gray-200 mb-4">
        <div className="flex flex-wrap gap-2">
          {[
            { key: 'all', label: 'All Students' },
            { key: 'hired', label: 'Hired' },
            { key: 'shortlisted', label: 'Shortlisted' },
            { key: 'rejected', label: 'Rejected' }
          ].map((tab) => (
            <button
              key={tab.key}
              type="button"
              onClick={() => setListMode(tab.key)}
              className={`px-3 py-1.5 text-sm rounded-lg border transition-colors ${
                listMode === tab.key
                  ? 'bg-blue-600 text-white border-blue-600'
                  : 'bg-white text-gray-700 border-gray-200 hover:bg-gray-50'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-200 mb-6">
        <form onSubmit={handleSearch} className="grid grid-cols-1 md:grid-cols-6 gap-4">
          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase block mb-1">Student Name</label>
            <input
              className="w-full border rounded-lg p-2"
              value={filters.name}
              placeholder="e.g. Ali"
              onChange={(e) => setFilters((prev) => ({ ...prev, name: e.target.value }))}
            />
          </div>

          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase block mb-1">Registration No</label>
            <input
              className="w-full border rounded-lg p-2"
              value={filters.registration}
              placeholder="e.g. SP22-BCS-001"
              onChange={(e) => setFilters((prev) => ({ ...prev, registration: formatRegistrationInput(e.target.value) }))}
            />
          </div>

          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase block mb-1">Department</label>
            <select
              value={filters.department}
              onChange={(e) => setFilters((prev) => ({ ...prev, department: e.target.value }))}
              className="w-full border rounded-lg p-2"
            >
              <option value="">All Departments</option>
              {departmentOptions.map((dept) => (
                <option key={dept} value={dept}>{dept}</option>
              ))}
            </select>
          </div>

          <div className="md:col-span-2">
            <label className="text-xs font-semibold text-gray-500 uppercase block mb-1">Add Skill</label>
            <select
              className="w-full border rounded-lg p-2"
              value={skillToAdd}
              onChange={(e) => {
                const value = e.target.value;
                setSkillToAdd(value);
                if (value) handleAddSkill(value);
              }}
            >
              <option value="">Select skill...</option>
              {availableSkills.map((skill) => (
                <option key={skill} value={skill}>{skill}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase block mb-1">Sort By</label>
            <select 
              className="w-full border rounded-lg p-2" 
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
            >
              <option value="name">Name (A-Z)</option>
              <option value="cgpa">CGPA (High to Low)</option>
              <option value="department">Department</option>
              <option value="registration">Registration No</option>
            </select>
          </div>

          <div className="flex items-end gap-2">
            <button type="submit" className="w-full bg-blue-600 text-white py-2 rounded-lg flex items-center justify-center gap-2 hover:bg-blue-700 transition-colors">
              <Search className="w-4 h-4" /> Refresh
            </button>
            <button
              type="button"
              onClick={handleClearFilters}
              className="w-full bg-gray-100 text-gray-700 py-2 rounded-lg hover:bg-gray-200 transition-colors"
            >
              Clear
            </button>
          </div>
        </form>

        <div className="mt-3 min-h-7">
          {filters.skills.length > 0 && (
            <div className="flex flex-wrap gap-2">
              {filters.skills.map((skill) => (
                <span key={skill} className="inline-flex items-center gap-1 bg-blue-50 text-blue-700 border border-blue-100 px-2 py-1 rounded-full text-[11px] font-medium">
                  {skill}
                  <button
                    type="button"
                    onClick={() => handleRemoveSkill(skill)}
                    className="text-blue-600 hover:text-blue-800"
                    title={`Remove ${skill}`}
                    aria-label={`Remove ${skill}`}
                  >
                    <X className="w-3 h-3" />
                  </button>
                </span>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Students Table */}
      {loading ? (
        <div className="text-center py-12"><Loader2 className="animate-spin mx-auto text-blue-600" /></div>
      ) : sortedStudents.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-xl border border-dashed border-gray-200">
           <AlertCircle className="w-10 h-10 text-gray-300 mx-auto mb-3" />
           <p className="text-gray-500">No students found.</p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="md:hidden p-2 space-y-2">
            {sortedStudents.map((student, index) => {
              const safeId = getStudentId(student);
              const key = safeId || index;
              const cgpa = student.CGPA ?? student.cgpa;
              const fypTitle = student.FypTitle || student.fypTitle;
              const skills = student.Skills || student.skills || [];
              const allSkills = skills.length > 0 ? skills.join(', ') : 'No skills listed';

              return (
                <div key={key} className="border border-gray-200 rounded-lg p-2.5 bg-white">
                  <div className="flex items-center gap-2.5 mb-2">
                    <div className="w-9 h-9 bg-blue-100 rounded-full flex items-center justify-center font-bold text-blue-600 text-xs overflow-hidden border border-gray-100 flex-shrink-0">
                      {student.ProfilePicUrl || student.profilePicUrl ? (
                        <img
                          src={getFileUrl(student.ProfilePicUrl || student.profilePicUrl)}
                          alt={student.Name || student.name}
                          className="w-full h-full object-cover"
                          onError={(e) => {
                            e.target.style.display = 'none';
                            e.target.nextSibling.style.display = 'block';
                          }}
                        />
                      ) : null}
                      <span style={{ display: (student.ProfilePicUrl || student.profilePicUrl) ? 'none' : 'block' }}>
                        {(student.Name || student.name)?.charAt(0)}
                      </span>
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="font-medium text-gray-900 truncate text-sm text-center" title={student.Name || student.name}>{student.Name || student.name}</p>
                      <p className="text-[11px] text-gray-500 text-center truncate">{student.RegistrationNo || student.registrationNo}</p>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-2 text-center text-xs">
                    <div className="text-gray-700 truncate" title={student.Department || student.department}>{student.Department || student.department || 'N/A'}</div>
                    <div className="font-medium text-gray-800">{cgpa !== undefined && cgpa !== null ? Number(cgpa).toFixed(2) : 'N/A'}</div>
                    <div className="col-span-2 text-purple-700 font-medium truncate" title={fypTitle || 'No FYP title'}>{fypTitle || 'N/A'}</div>
                    <div className="col-span-2" title={allSkills}>
                      {skills.length > 0 ? (
                        <span className="text-[10px] bg-blue-50 text-blue-700 border border-blue-100 px-2 py-0.5 rounded-full inline-block">
                          {skills.length} skill{skills.length > 1 ? 's' : ''}
                        </span>
                      ) : (
                        <span className="text-[11px] text-gray-400">N/A</span>
                      )}
                    </div>
                    <div className="col-span-2 flex justify-center">
                      {renderStatusChip(student) || <span className="text-[11px] text-gray-400">No Request</span>}
                    </div>
                  </div>

                  <div className="mt-2 w-full">
                    {renderActionButtons(student, safeId, true)}
                  </div>
                </div>
              );
            })}
          </div>

          <div className="hidden md:block">
            <table className="w-full min-w-full text-sm table-fixed">
              <thead className="sticky top-0 z-10 bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="bg-gray-50 text-center px-2 py-2 text-xs font-semibold text-gray-600 uppercase w-[23%]">Student</th>
                  <th className="bg-gray-50 text-center px-2 py-2 text-xs font-semibold text-gray-600 uppercase w-[13%]">Department</th>
                  <th className="bg-gray-50 text-center px-2 py-2 text-xs font-semibold text-gray-600 uppercase w-[8%]">CGPA</th>
                  <th className="bg-gray-50 text-center px-2 py-2 text-xs font-semibold text-gray-600 uppercase w-[19%]">FYP Title</th>
                  <th className="bg-gray-50 text-center px-2 py-2 text-xs font-semibold text-gray-600 uppercase w-[10%]">Skills</th>
                  <th className="bg-gray-50 text-center px-2 py-2 text-xs font-semibold text-gray-600 uppercase w-[17%]">Status</th>
                  <th className="bg-gray-50 text-center px-2 py-2 text-xs font-semibold text-gray-600 uppercase w-[10%]">Action</th>
                </tr>
              </thead>
              <tbody>
                {sortedStudents.map((student, index) => {
                  const safeId = getStudentId(student);
                  const key = safeId || index;
                  const cgpa = student.CGPA ?? student.cgpa;
                  const fypTitle = student.FypTitle || student.fypTitle;
                  const skills = student.Skills || student.skills || [];
                  const allSkills = skills.length > 0 ? skills.join(', ') : 'No skills listed';

                  return (
                    <tr key={key} className="border-b border-gray-100 last:border-b-0 hover:bg-blue-50/30 transition-colors">
                      <td className="px-2 py-2.5 text-left align-middle">
                        <div className="flex items-center justify-start gap-2.5 min-w-0">
                          <div className="w-9 h-9 bg-blue-100 rounded-full flex items-center justify-center font-bold text-blue-600 text-xs overflow-hidden border border-gray-100 flex-shrink-0">
                            {student.ProfilePicUrl || student.profilePicUrl ? (
                              <img 
                                src={getFileUrl(student.ProfilePicUrl || student.profilePicUrl)} 
                                alt={student.Name || student.name}
                                className="w-full h-full object-cover"
                                onError={(e) => {
                                  e.target.style.display = 'none';
                                  e.target.nextSibling.style.display = 'block';
                                }}
                              />
                            ) : null}
                            <span style={{ display: (student.ProfilePicUrl || student.profilePicUrl) ? 'none' : 'block' }}>
                              {(student.Name || student.name)?.charAt(0)}
                            </span>
                          </div>
                          <div className="min-w-0 text-left">
                            <p className="font-medium text-gray-900 truncate text-left" title={student.Name || student.name}>{student.Name || student.name}</p>
                            <p className="text-[11px] text-gray-500 truncate text-left">{student.RegistrationNo || student.registrationNo}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-2 py-2.5 text-xs text-gray-700 text-center align-middle">
                        <div className="flex items-center justify-center gap-1">
                          <GraduationCap className="w-3 h-3 text-blue-500 flex-shrink-0" />
                          <span className="truncate" title={student.Department || student.department}>{student.Department || student.department || 'N/A'}</span>
                        </div>
                      </td>
                      <td className="px-2 py-2.5 text-xs font-medium text-gray-800 whitespace-nowrap text-center align-middle">
                        {cgpa !== undefined && cgpa !== null ? Number(cgpa).toFixed(2) : 'N/A'}
                      </td>
                      <td className="px-2 py-2.5 text-xs text-purple-700 font-medium text-center align-middle">
                        <span className="block truncate" title={fypTitle || 'No FYP title'}>{fypTitle || 'N/A'}</span>
                      </td>
                      <td className="px-2 py-2.5 text-center align-middle w-[140px] min-w-[140px] max-w-[140px]">
                        <div className="w-full flex justify-center" title={allSkills}>
                          {skills.length > 0 ? (
                            <span className="text-[10px] bg-blue-50 text-blue-700 border border-blue-100 px-2 py-0.5 rounded-full truncate max-w-[120px]">
                              {skills.length} skill{skills.length > 1 ? 's' : ''}
                            </span>
                          ) : (
                            <span className="text-[11px] text-gray-400">N/A</span>
                          )}
                        </div>
                      </td>
                      <td className="px-2 py-2.5 text-center align-middle">
                        <div className="flex justify-center">
                          {renderStatusChip(student) || <span className="text-[11px] text-gray-400">No Request</span>}
                        </div>
                      </td>
                      <td className="px-2 py-2.5 text-center align-middle">
                        {renderActionButtons(student, safeId)}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}