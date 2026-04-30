import React, { useState, useEffect, useMemo, useRef } from 'react';
import { Search, Loader2, GraduationCap, AlertCircle, Clock, CheckCircle2, XCircle, UserPlus, Eye, Send, Calendar, Download, X, Plus, ArrowUpDown } from 'lucide-react';
import { getStudents, getFileUrl, sendInterviewRequest, getAnalytics, getCompanyProfile } from '../api';
import { allSkillsList, skillsData } from '../../data/skills';

const DEFAULT_PAGE_SIZE = 10;

export default function StudentDirectory({ onSelect, onError, onSuccess, onNavigateToInterviews, isJobFairDay = true, isCompanyPresent = true }) {
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(false);
  const [filters, setFilters] = useState({ search: '', department: '', skills: [] });
  const [sortBy, setSortBy] = useState('name');
  const [listMode, setListMode] = useState('all');
  const [requestingStudentId, setRequestingStudentId] = useState(null);
  const [skillToAdd, setSkillToAdd] = useState('');
  const [isInterviewWindowClosed, setIsInterviewWindowClosed] = useState(false);
  const [backendSearchLoading, setBackendSearchLoading] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(DEFAULT_PAGE_SIZE);
  const [totalCount, setTotalCount] = useState(0);
  const [companySkills, setCompanySkills] = useState([]);
  const [hoveredStudentId, setHoveredStudentId] = useState(null);
  const [tooltipPos, setTooltipPos] = useState(null);
  const searchDebounceRef = useRef(null);
  const deptDebounceRef = useRef(null);
  const backendSearchRef = useRef({});
  const pageSizeRef = useRef(DEFAULT_PAGE_SIZE);

  useEffect(() => {
    pageSizeRef.current = pageSize;
  }, [pageSize]);

  const fetchStudents = async (queryParams = {}, page = 1, pageSizeOverride = null) => {
    setBackendSearchLoading(true);
    setCurrentPage(page);
    try {
      // Use explicit pageSizeOverride when provided (e.g. when pageSize state hasn't updated yet)
      const effectivePageSize =
        Number(pageSizeOverride ?? pageSizeRef.current ?? DEFAULT_PAGE_SIZE) ||
        DEFAULT_PAGE_SIZE;
      // Call backend with all active query parameters, including tab status filter
      // For "recommended" tab we perform client-side matching and sorting
      if (listMode === 'recommended') {
        // Ensure we have company skills available. Use a local array to avoid
        // relying on state update timing when computing matches below.
        let skillsArr = Array.isArray(companySkills) ? companySkills : [];
        try {
          if (!skillsArr || skillsArr.length === 0) {
            const profile = await getCompanyProfile();
            const jobs = profile?.jobs?.jobs || profile?.jobs || [];
            const aggregated = (jobs || []).flatMap(j => j.requiredSkills || j.RequiredSkills || []);
            const unique = Array.from(new Set((aggregated || []).map(s => String(s || '').toLowerCase())));
            setCompanySkills(unique);
            skillsArr = unique;
          }
        } catch (err) {
          // If company profile fails, proceed without recommended results
          setBackendSearchLoading(false);
          onError(err.message || 'Failed to load company profile for recommendations');
          return;
        }

        // Fetch a large page to perform client-side ranking. Note: this may be heavy for very large datasets.
        const allParams = { ...queryParams, page: 1, pageSize: 10000 };
        const data = await getStudents(allParams);

        const allItems = data?.items || data || [];

        const skillsSet = new Set((skillsArr || []).map(s => String(s || '').toLowerCase()));
        const scored = (allItems || []).map((stu) => {
          // Normalize student skills whether they come as array or comma-separated string
          let raw = stu.skills ?? stu.Skills ?? [];
          let origSkills = [];
          if (Array.isArray(raw)) {
            origSkills = raw.map(s => String(s || '').trim()).filter(Boolean);
          } else if (typeof raw === 'string') {
            origSkills = raw.split(/[,;|]/).map(s => String(s || '').trim()).filter(Boolean);
          }

          const lowered = origSkills.map(s => s.toLowerCase());
          const matched = origSkills.filter((s, idx) => skillsSet.has(lowered[idx]));
          // Deduplicate matched skills while preserving order/casing
          const seen = new Set();
          const uniqueMatched = matched.filter(s => {
            const k = s.toLowerCase();
            if (seen.has(k)) return false;
            seen.add(k);
            return true;
          });

          const matchCount = uniqueMatched.length;
          return { ...stu, _matchCount: matchCount, _matchedSkills: uniqueMatched };
        })
        .filter(s => s._matchCount > 0)
        .sort((a,b) => b._matchCount - a._matchCount || String((b.Name||b.name||'')).localeCompare(String((a.Name||a.name||''))));

        setStudents(scored);
        setTotalCount(scored.length);
        setCurrentPage(page);
      } else {
        const paginatedParams = { ...queryParams, page, pageSize: effectivePageSize };
        if (listMode !== 'all') {
          paginatedParams.status = listMode;
        }
        const data = await getStudents(paginatedParams);
        
        // Handle paginated response
        if (data?.items) {
          setStudents(data.items || []);
          setTotalCount(data.totalCount || 0);
          setCurrentPage(Number(data.page) || page);
          if (data.pageSize) {
            setPageSize(Number(data.pageSize) || effectivePageSize);
          }
        } else {
          // Handle legacy non-paginated response (backward compatibility)
          setStudents(data || []);
          setTotalCount(data?.length || 0);
          setCurrentPage(page);
        }
      }
      backendSearchRef.current = queryParams;
    } catch (err) {
      onError(err.message);
    } finally {
      setBackendSearchLoading(false);
    }
  };

  // Debounce backend search when search field changes
  const handleSearchInputChange = (value) => {
    setFilters((prev) => {
      if (searchDebounceRef.current) {
        clearTimeout(searchDebounceRef.current);
      }

      if (!value.trim()) {
        // If search is cleared, fetch with department and skills filters if set
        searchDebounceRef.current = setTimeout(() => {
          const queryParams = {};
          if (prev.department) queryParams.department = prev.department;
          if (prev.skills.length > 0) queryParams.skills = prev.skills;
          fetchStudents(queryParams, 1, pageSizeRef.current); // Reset to page 1
        }, 300);
      } else {
        // Debounce backend search by 500ms
        searchDebounceRef.current = setTimeout(() => {
          const queryParams = { search: value };
          if (prev.department) queryParams.department = prev.department;
          if (prev.skills.length > 0) queryParams.skills = prev.skills;
          fetchStudents(queryParams, 1, pageSizeRef.current); // Reset to page 1
        }, 500);
      }

      return { ...prev, search: value };
    });
  };

  // Debounce backend search when department changes
  const handleDepartmentChange = (dept) => {
    setFilters((prev) => {
      // Build query params with the new department and current search
      const queryParams = {};
      if (prev.search) queryParams.search = prev.search;
      if (dept) queryParams.department = dept;
      if (prev.skills.length > 0) queryParams.skills = prev.skills;
      
      // Trigger backend search
      if (deptDebounceRef.current) {
        clearTimeout(deptDebounceRef.current);
      }
      deptDebounceRef.current = setTimeout(() => {
        fetchStudents(queryParams, 1, pageSizeRef.current); // Reset to page 1
      }, 300);
      
      return { ...prev, department: dept };
    });
  };

  useEffect(() => { 
    fetchStudents({}, 1, pageSizeRef.current);
  }, [listMode]);

  useEffect(() => {
    // Cleanup debounce on unmount
    return () => {
      if (searchDebounceRef.current) {
        clearTimeout(searchDebounceRef.current);
      }
      if (deptDebounceRef.current) {
        clearTimeout(deptDebounceRef.current);
      }
    };
  }, []);

  useEffect(() => {
    const loadInterviewWindow = async () => {
      try {
        const analytics = await getAnalytics();
        const fairDate = analytics?.jobFairDate;
        if (!fairDate) return;
        setIsInterviewWindowClosed(hasCutoffPassed(fairDate));
      } catch {
        // Keep UI permissive if analytics is unavailable; backend still enforces rule.
      }
    };
    loadInterviewWindow();
  }, []);

  const normalize = (val) => String(val || '').trim().toLowerCase();
  const normalizedCompanySkills = useMemo(
    () => new Set((companySkills || []).map((skill) => normalize(skill)).filter(Boolean)),
    [companySkills]
  );
  const cleanReg = (val) => normalize(val).replace(/[^a-z0-9]/g, '');

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
    return {
      year: pick('year'),
      month: pick('month'),
      day: pick('day'),
      hour: pick('hour'),
      minute: pick('minute')
    };
  };

  const hasCutoffPassed = (jobFairDate) => {
    const now = getPktDateParts(new Date());
    const fair = getPktDateParts(jobFairDate);
    const nowDateNum = now.year * 10000 + now.month * 100 + now.day;
    const fairDateNum = fair.year * 10000 + fair.month * 100 + fair.day;

    if (nowDateNum > fairDateNum) return true;
    if (nowDateNum < fairDateNum) return false;
    return now.hour > 16 || (now.hour === 16 && now.minute > 30);
  };

  const formatRegistrationInput = (val) => String(val || '')
    .toUpperCase()
    .replace(/[^A-Z0-9-]/g, '')
    .replace(/-{2,}/g, '-');

  const departmentOptions = [
    "Computer Science",
    "Civil Engineering",
    "Mechanical Engineering",
    "Electrical Engineering",
    "Management Sciences"
  ];

  const availableSkills = useMemo(
    () => allSkillsList.filter((skill) => !filters.skills.includes(skill)),
    [filters.skills]
  );

  const filteredStudents = useMemo(() => {
    // Basic normalization helpers
    const searchQuery = normalize(filters.search);
    const regQuery = cleanReg(filters.search);
    const deptQuery = normalize(filters.department);
    const selectedSkills = (filters.skills || []).map(normalize).filter(Boolean);

    return (students || []).filter((s) => {
      // Robust property access for both camelCase and PascalCase
      const name = s.name ?? s.Name ?? '';
      const regNo = s.registrationNo ?? s.RegistrationNo ?? '';
      const dept = s.department ?? s.Department ?? '';
      const skills = s.skills ?? s.Skills ?? [];

      const studentName = normalize(name);
      const studentReg = cleanReg(regNo);
      const studentDept = normalize(dept);
      const studentSkills = (Array.isArray(skills) ? skills : []).map(normalize);

      // Search matching logic (Name or Registration)
      // If we just fetched results for a specific search term from the backend, 
      // we should be permissive to avoid discrepancies between backend and frontend filtering.
      const matchesSearch = !searchQuery || 
                           studentName.includes(searchQuery) || 
                           studentReg.includes(regQuery) ||
                           (regNo && searchQuery.includes(cleanReg(regNo)));

      const matchesDepartment = !deptQuery || studentDept === deptQuery;
      
      const matchesSkills = selectedSkills.length === 0 || 
                           selectedSkills.every((skill) => studentSkills.includes(skill));

      return matchesSearch && matchesDepartment && matchesSkills;
    });
  }, [students, filters, listMode]);

  const handleSearch = (e) => {
    e.preventDefault();
    // Now automatic via debounce, but keep this for manual refresh if needed
  };

  const handleAddSkill = (skill) => {
    if (!skill) return;
    setFilters((prev) => {
      if (prev.skills.includes(skill)) return prev;
      const newSkills = [...prev.skills, skill];
      
      // Build query params and fetch with updated skills
      const queryParams = {};
      if (prev.search) queryParams.search = prev.search;
      if (prev.department) queryParams.department = prev.department;
      if (newSkills.length > 0) queryParams.skills = newSkills;
      
      fetchStudents(queryParams, 1, pageSizeRef.current); // Reset to page 1
      
      return { ...prev, skills: newSkills };
    });
    setSkillToAdd('');
  };

  const handleRemoveSkill = (skill) => {
    setFilters((prev) => {
      const newSkills = prev.skills.filter((s) => s !== skill);
      
      // Build query params and fetch with updated skills
      const queryParams = {};
      if (prev.search) queryParams.search = prev.search;
      if (prev.department) queryParams.department = prev.department;
      if (newSkills.length > 0) queryParams.skills = newSkills;
      
      fetchStudents(queryParams, 1, pageSizeRef.current); // Reset to page 1
      
      return { ...prev, skills: newSkills };
    });
  };

  const handleClearFilters = () => {
    setFilters({ search: '', department: '', skills: [] });
    setSkillToAdd('');
    fetchStudents({}, 1, pageSizeRef.current);
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
    if (isInterviewWindowClosed) {
      onError('Job Fair has ended.');
      return;
    }

    const studentId = getStudentId(student);
    if (!studentId) {
      onError('Missing Student ID');
      return;
    }

    setRequestingStudentId(studentId);
    try {
      await sendInterviewRequest(studentId);
      await fetchStudents(backendSearchRef.current);
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
        {cvUrl && (
          <>
            <a
              href={getFileUrl(cvUrl)}
              target="_blank"
              rel="noreferrer"
              className={`${iconBtnBase} text-blue-600 hover:bg-blue-50`}
              title="View CV"
              aria-label="View CV"
              onClick={(e) => e.stopPropagation()}
            >
              <Eye className="w-4 h-4" />
            </a>
            <a
              href={getFileUrl(cvUrl)}
              download
              className={`${iconBtnBase} text-gray-700 hover:bg-gray-100`}
              title="Download CV"
              aria-label="Download CV"
              onClick={(e) => e.stopPropagation()}
            >
              <Download className="w-4 h-4" />
            </a>
          </>
        )}

        {canSendRequest && (
          <button
            onClick={(e) => {
              e.stopPropagation();
              handleSendInterviewRequest(student);
            }}
            disabled={requestingStudentId === safeId || isInterviewWindowClosed}
            className={`${iconBtnBase} text-blue-700 hover:bg-blue-100 disabled:opacity-60`}
            title="Request Interview"
            aria-label="Request Interview"
          >
            {requestingStudentId === safeId ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
          </button>
        )}

        {canSchedule && (() => {
          const isScheduleDisabledCondition = !alreadyScheduled && (!isJobFairDay || !isCompanyPresent || isInterviewWindowClosed);
          return (
            <button
              onClick={(e) => {
                e.stopPropagation();
                if (alreadyScheduled) {
                  if (onNavigateToInterviews) {
                    onNavigateToInterviews();
                  }
                  return;
                }
                if (!isJobFairDay) {
                  return onError('Scheduling is only available on the Job Fair day.');
                }
                if (!isCompanyPresent) {
                  return onError('You must mark your company as present today to schedule interviews.');
                }
                if (isInterviewWindowClosed) {
                  return onError('Interview scheduling window is closed.');
                }
                if (!safeId) return onError('Missing Student ID');
                onSelect({ ...student, studentId: safeId });
              }}
              className={`${iconBtnBase} ${alreadyScheduled ? 'text-emerald-700 bg-emerald-50' : 'text-indigo-700 hover:bg-indigo-100'} ${isScheduleDisabledCondition ? 'opacity-50 cursor-not-allowed' : ''}`}
              title={alreadyScheduled ? 'Interview already scheduled' : 'Schedule Interview'}
              aria-label={alreadyScheduled ? 'Interview already scheduled' : 'Schedule Interview'}
            >
              <Calendar className="w-4 h-4" />
            </button>
          );
        })()}
      </div>
    );
  };

  // Sorting Logic
  const getSortedStudents = () => {
    // When showing recommended students, sort by computed match count (descending)
    if (listMode === 'recommended') {
      return [...filteredStudents].sort((a, b) => (b._matchCount || 0) - (a._matchCount || 0) || String((a.Name||a.name||'')).localeCompare(String((b.Name||b.name||''))));
    }

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
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const safeCurrentPage = Math.min(currentPage, totalPages);
  const pageStartIndex = (safeCurrentPage - 1) * pageSize;
  const pagedStudents = Array.isArray(sortedStudents) ? sortedStudents.slice(pageStartIndex, pageStartIndex + pageSize) : sortedStudents;

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
            { key: 'recommended', label: 'Recommended' },
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
      <div className="bg-white p-2.5 rounded-xl shadow-sm border border-gray-200 mb-4">
        <form onSubmit={handleSearch} className="space-y-2">
          <div className="grid grid-cols-1 md:grid-cols-7 gap-2">
            <div className="md:col-span-2">
              <label className="text-[11px] font-semibold text-gray-500 uppercase block mb-0.5">Search Student <span className="text-gray-400">(Name or Reg)</span></label>
              <input
                className="w-full border rounded-lg p-1.5 text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                value={filters.search}
                placeholder="e.g. Ali or SP22-BCS-001"
                onChange={(e) => handleSearchInputChange(e.target.value)}
              />
              {backendSearchLoading && <p className="text-[10px] text-blue-600 mt-0.5 flex items-center gap-1"><Loader2 className="w-3 h-3 animate-spin" /> Searching...</p>}
            </div>

            <div>
              <label className="text-[11px] font-semibold text-gray-500 uppercase block mb-0.5">Department</label>
              <select
                value={filters.department}
                onChange={(e) => handleDepartmentChange(e.target.value)}
                className="w-full border rounded-lg p-1.5 text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="">All Departments</option>
                {departmentOptions.map((dept) => (
                  <option key={dept} value={dept}>{dept}</option>
                ))}
              </select>
            </div>

            <div className="md:col-span-2">
              <label className="text-[11px] font-semibold text-gray-500 uppercase block mb-0.5">Add Skill</label>
              <div className="flex gap-1 items-center">
                <input
                  type="text"
                  className="flex-1 border rounded-lg p-1.5 text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  value={skillToAdd}
                  placeholder="Type to search skills..."
                  onChange={(e) => setSkillToAdd(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && skillToAdd.trim()) {
                      e.preventDefault();
                      handleAddSkill(skillToAdd);
                    }
                  }}
                  list="skills-list"
                />
                <button
                  type="button"
                  onClick={() => skillToAdd.trim() && handleAddSkill(skillToAdd)}
                  disabled={!skillToAdd.trim()}
                  className="px-2 py-1.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors flex items-center justify-center"
                  title="Add skill (or press Enter)"
                  aria-label="Add skill"
                >
                  <Plus className="w-4 h-4" />
                </button>
              </div>
              <datalist id="skills-list">
                {availableSkills.map((skill) => (
                  <option key={skill} value={skill}>{skill}</option>
                ))}
              </datalist>
            </div>

            <div>
              <label className="text-[11px] font-semibold text-gray-500 uppercase block mb-0.5">Sort By</label>
              <select 
                className="w-full border rounded-lg p-1.5 text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent" 
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value)}
              >
                <option value="name">Name (A-Z)</option>
                <option value="cgpa">CGPA (High to Low)</option>
                <option value="department">Department</option>
                <option value="registration">Registration No</option>
              </select>
            </div>

            <div className="flex items-end gap-1 flex-nowrap">
              <button type="submit" className="flex-1 min-w-0 bg-blue-600 text-white py-1.5 px-2 rounded-lg flex items-center justify-center gap-1 hover:bg-blue-700 transition-colors text-xs whitespace-nowrap">
                <Search className="w-4 h-4" /> Refresh
              </button>
              <button
                type="button"
                onClick={handleClearFilters}
                className="flex-1 min-w-0 bg-gray-100 text-gray-700 py-1.5 px-2 rounded-lg hover:bg-gray-200 transition-colors text-xs whitespace-nowrap"
              >
                Clear
              </button>
            </div>
          </div>

          {/* Skill suggestions with side-by-side display */}
          {skillToAdd.trim() && availableSkills.filter(s => s.toLowerCase().includes(skillToAdd.toLowerCase())).length > 0 && (
            <div className="border-t pt-2">
              <p className="text-[11px] font-semibold text-gray-500 uppercase mb-1">Suggestions</p>
              <div className="flex flex-wrap gap-1">
                {availableSkills
                  .filter(s => s.toLowerCase().includes(skillToAdd.toLowerCase()))
                  .slice(0, 8)
                  .map((skill) => (
                    <button
                      key={skill}
                      type="button"
                      onClick={() => handleAddSkill(skill)}
                      className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium border border-blue-300 bg-blue-50 text-blue-700 hover:bg-blue-100 transition-colors"
                    >
                      <span className="text-sm">+</span> {skill}
                    </button>
                  ))}
              </div>
            </div>
          )}
        </form>

        {/* Selected Skills */}
        <div className="mt-2 min-h-7">
          {filters.skills.length > 0 && (
            <div className="flex flex-wrap gap-1">
              {filters.skills.map((skill) => (
                <span key={skill} className="inline-flex items-center gap-1 bg-blue-50 text-blue-700 border border-blue-100 px-2 py-0.5 rounded-full text-[11px] font-medium">
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
      {loading || backendSearchLoading ? (
        <div className="text-center py-12"><Loader2 className="animate-spin mx-auto text-blue-600" /></div>
      ) : sortedStudents.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-xl border border-dashed border-gray-200">
           <AlertCircle className="w-10 h-10 text-gray-300 mx-auto mb-3" />
           <p className="text-gray-500">No students found.</p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="md:hidden p-2 space-y-2">
            {pagedStudents.map((student, index) => {
              const safeId = getStudentId(student);
              const key = safeId || index;
              const cgpa = student.CGPA ?? student.cgpa;
              const fypTitle = student.FypTitle || student.fypTitle;
              const skills = student.Skills || student.skills || [];
              const allSkills = skills.length > 0 ? skills.join(', ') : 'No skills listed';

              return (
                <div
                  key={key}
                  className="border border-gray-200 rounded-lg p-2.5 bg-white cursor-pointer"
                  onClick={() => {
                    if (!safeId) return onError('Missing Student ID');
                    onSelect({ ...student, studentId: safeId });
                  }}
                >
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
                    <div className="col-span-2 relative">
                      {listMode === 'recommended' && (student._matchedSkills || []).length > 0 ? (
                        <div 
                          className="relative inline-block"
                            onMouseEnter={(e) => {
                            setHoveredStudentId(getStudentId(student));
                            const tooltipWidth = 280;
                            const tooltipHeight = 150;
                            let leftPos = e.clientX - tooltipWidth - 10;
                            let topPos = e.clientY + 10;
                            
                            // Ensure not off left edge
                            if (leftPos < 10) {
                              leftPos = 10;
                            }
                            // Boundary check for bottom edge
                            if (topPos + tooltipHeight > window.innerHeight) {
                              topPos = e.clientY - tooltipHeight - 10;
                            }
                            
                            setTooltipPos({ top: topPos, left: leftPos });
                          }}
                          onMouseLeave={() => setHoveredStudentId(null)}
                        >
                          <span className="relative overflow-visible text-[10px] bg-amber-50 text-amber-800 border border-amber-100 px-2 py-0.5 pr-7 rounded-full inline-flex items-center cursor-pointer hover:bg-amber-100 transition-colors max-w-[180px]">
                              <span className="truncate flex-1">
                                {(student._matchedSkills || []).slice(0,3).join(', ')}{(student._matchedSkills || []).length > 3 ? ` +${(student._matchedSkills || []).length - 3}` : ''}
                              </span>
                              <span className="absolute right-1 top-1/2 -translate-y-1/2 inline-flex items-center justify-center w-5 h-5 bg-amber-600 text-white text-[9px] font-bold rounded-full shadow-md ring-2 ring-white z-10 flex-shrink-0">
                                {(student._matchedSkills || []).length}
                              </span>
                          </span>
                          {hoveredStudentId === getStudentId(student) && tooltipPos && (
                            <div 
                              className="fixed z-50 bg-white border border-gray-300 rounded-lg shadow-2xl p-3 w-max max-w-xs"
                              style={{ top: `${tooltipPos.top}px`, left: `${tooltipPos.left}px` }}
                            >
                              <p className="text-xs font-semibold text-gray-700 mb-2">All Skills (✓ matched):</p>
                              <div className="flex flex-wrap gap-1">
                                {(skills || []).map((skill, idx) => {
                                  const isMatched = (student._matchedSkills || []).some(m => m.toLowerCase() === String(skill).toLowerCase());
                                  return (
                                    <span
                                      key={idx}
                                      className={`text-[11px] px-2 py-1 rounded-full font-medium ${
                                        isMatched
                                          ? 'bg-green-100 text-green-800 border border-green-300'
                                          : 'bg-gray-100 text-gray-600 border border-gray-200'
                                      }`}
                                    >
                                      {skill}
                                    </span>
                                  );
                                })}
                              </div>
                            </div>
                          )}
                        </div>
                      ) : skills.length > 0 ? (
                        <div 
                          className="relative inline-block"
                          onMouseEnter={(e) => {
                            setHoveredStudentId(getStudentId(student));
                            const tooltipWidth = 250;
                            const tooltipHeight = 150;
                            let leftPos = e.clientX - tooltipWidth - 10;
                            let topPos = e.clientY + 10;
                            
                            // Ensure not off left edge
                            if (leftPos < 10) {
                              leftPos = 10;
                            }
                            // Boundary check for bottom edge
                            if (topPos + tooltipHeight > window.innerHeight) {
                              topPos = e.clientY - tooltipHeight - 10;
                            }
                            
                            setTooltipPos({ top: topPos, left: leftPos });
                          }}
                          onMouseLeave={() => setHoveredStudentId(null)}
                        >
                          <span className="relative overflow-visible text-[10px] bg-blue-50 text-blue-700 border border-blue-100 px-2 py-0.5 pr-7 rounded-full inline-flex items-center cursor-pointer hover:bg-blue-100 transition-colors max-w-[180px]">
                              <span className="truncate flex-1">
                                {skills.length} skill{skills.length > 1 ? 's' : ''}
                              </span>
                              <span className="absolute right-1 top-1/2 -translate-y-1/2 inline-flex items-center justify-center w-5 h-5 bg-blue-600 text-white text-[9px] font-bold rounded-full shadow-md ring-2 ring-white z-10 flex-shrink-0">
                                {skills.length}
                              </span>
                          </span>
                          {hoveredStudentId === getStudentId(student) && tooltipPos && (
                            <div 
                              className="fixed z-50 bg-white border border-gray-300 rounded-lg shadow-2xl p-3 w-max max-w-xs"
                              style={{ top: `${tooltipPos.top}px`, left: `${tooltipPos.left}px` }}
                            >
                              <p className="text-xs font-semibold text-gray-700 mb-2">All Skills:</p>
                              <div className="flex flex-wrap gap-1">
                                {(skills || []).map((skill, idx) => (
                                  <span
                                    key={idx}
                                    className="text-[11px] px-2 py-1 rounded-full font-medium bg-blue-100 text-blue-700 border border-blue-200"
                                  >
                                    {skill}
                                  </span>
                                ))}
                              </div>
                            </div>
                          )}
                        </div>
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
                  <th className="bg-gray-50 text-center px-2 py-2 text-xs font-semibold text-gray-600 uppercase w-[23%]">
                    <button type="button" onClick={() => setSortBy('name')} className="inline-flex items-center gap-1 hover:text-gray-800">
                      Student <ArrowUpDown className="w-3 h-3" />
                    </button>
                  </th>
                  <th className="bg-gray-50 text-center px-2 py-2 text-xs font-semibold text-gray-600 uppercase w-[13%]">
                    <button type="button" onClick={() => setSortBy('department')} className="inline-flex items-center gap-1 hover:text-gray-800">
                      Department <ArrowUpDown className="w-3 h-3" />
                    </button>
                  </th>
                  <th className="bg-gray-50 text-center px-2 py-2 text-xs font-semibold text-gray-600 uppercase w-[8%]">
                    <button type="button" onClick={() => setSortBy('cgpa')} className="inline-flex items-center gap-1 hover:text-gray-800">
                      CGPA <ArrowUpDown className="w-3 h-3" />
                    </button>
                  </th>
                  <th className="bg-gray-50 text-center px-2 py-2 text-xs font-semibold text-gray-600 uppercase w-[19%]">FYP Title</th>
                  <th className="bg-gray-50 text-center px-2 py-2 text-xs font-semibold text-gray-600 uppercase w-[10%]">Skills</th>
                  <th className="bg-gray-50 text-center px-2 py-2 text-xs font-semibold text-gray-600 uppercase w-[17%]">Status</th>
                  <th className="bg-gray-50 text-center px-2 py-2 text-xs font-semibold text-gray-600 uppercase w-[10%]">Action</th>
                </tr>
              </thead>
              <tbody>
                {pagedStudents.map((student, index) => {
                  const safeId = getStudentId(student);
                  const key = safeId || index;
                  const cgpa = student.CGPA ?? student.cgpa;
                  const fypTitle = student.FypTitle || student.fypTitle;
                  const skills = student.Skills || student.skills || [];
                  const allSkills = skills.length > 0 ? skills.join(', ') : 'No skills listed';

                  return (
                    <tr
                      key={key}
                      className="border-b border-gray-100 last:border-b-0 hover:bg-blue-50/30 transition-colors cursor-pointer"
                      onClick={() => {
                        if (!safeId) return onError('Missing Student ID');
                        onSelect({ ...student, studentId: safeId });
                      }}
                    >
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
                      <td className="px-2 py-2.5 text-center align-middle w-[140px] min-w-[140px] max-w-[140px] relative">
                        <div className="w-full flex justify-center">
                          {listMode === 'recommended' && (student._matchedSkills || []).length > 0 ? (
                            <div 
                              className="relative inline-block"
                              onMouseEnter={(e) => {
                                setHoveredStudentId(getStudentId(student));
                                const tooltipWidth = 280;
                                const tooltipHeight = 150;
                                let leftPos = e.clientX - tooltipWidth - 10;
                                let topPos = e.clientY + 10;
                                
                                // Ensure not off left edge
                                if (leftPos < 10) {
                                  leftPos = 10;
                                }
                                // Boundary check for bottom edge
                                if (topPos + tooltipHeight > window.innerHeight) {
                                  topPos = e.clientY - tooltipHeight - 10;
                                }
                                
                                setTooltipPos({ top: topPos, left: leftPos });
                              }}
                              onMouseLeave={() => setHoveredStudentId(null)}
                            >
                              <span className="relative overflow-visible text-[10px] bg-amber-50 text-amber-800 border border-amber-100 px-2 py-0.5 pr-6 rounded-full inline-flex items-center cursor-pointer hover:bg-amber-100 transition-colors max-w-[120px]">
                                <span className="truncate flex-1">
                                  {(student._matchedSkills || []).slice(0,3).join(', ')}{(student._matchedSkills || []).length > 3 ? ` +${(student._matchedSkills || []).length - 3}` : ''}
                                </span>
                                <span className="absolute right-0.5 top-1/2 -translate-y-1/2 inline-flex items-center justify-center w-4 h-4 bg-amber-600 text-white text-[8px] font-bold rounded-full shadow-sm z-10 flex-shrink-0">
                                  {(student._matchedSkills || []).length}
                                </span>
                              </span>
                              {hoveredStudentId === getStudentId(student) && tooltipPos && (
                                <div 
                                  className="fixed z-50 bg-white border border-gray-300 rounded-lg shadow-2xl p-3 w-max max-w-xs"
                                  style={{ top: `${tooltipPos.top}px`, left: `${tooltipPos.left}px` }}
                                >
                                  <p className="text-xs font-semibold text-gray-700 mb-2">All Skills (✓ matched):</p>
                                  <div className="flex flex-wrap gap-1">
                                    {(skills || []).map((skill, idx) => {
                                      const isMatched = (student._matchedSkills || []).some(m => m.toLowerCase() === String(skill).toLowerCase());
                                      return (
                                        <span
                                          key={idx}
                                          className={`text-[11px] px-2 py-1 rounded-full font-medium ${
                                            isMatched
                                              ? 'bg-green-100 text-green-800 border border-green-300'
                                              : 'bg-gray-100 text-gray-600 border border-gray-200'
                                          }`}
                                        >
                                          {skill}
                                        </span>
                                      );
                                    })}
                                  </div>
                                </div>
                              )}
                            </div>
                          ) : skills.length > 0 ? (
                            <div 
                              className="relative inline-block"
                              onMouseEnter={(e) => {
                                setHoveredStudentId(getStudentId(student));
                                const tooltipWidth = 250;
                                const tooltipHeight = 120;
                                let leftPos = e.clientX - tooltipWidth - 10;
                                let topPos = e.clientY + 10;
                                
                                // Ensure not off left edge
                                if (leftPos < 10) {
                                  leftPos = 10;
                                }
                                // Boundary check for bottom edge
                                if (topPos + tooltipHeight > window.innerHeight) {
                                  topPos = e.clientY - tooltipHeight - 10;
                                }
                                
                                setTooltipPos({ top: topPos, left: leftPos });
                              }}
                              onMouseLeave={() => setHoveredStudentId(null)}
                            >
                              <span className="text-[10px] bg-blue-50 text-blue-700 border border-blue-100 px-2 py-0.5 rounded-full truncate max-w-[120px] cursor-pointer hover:bg-blue-100 transition-colors inline-block">
                                {skills.length} skill{skills.length > 1 ? 's' : ''}
                              </span>
                              {hoveredStudentId === getStudentId(student) && tooltipPos && (
                                <div 
                                  className="fixed z-50 bg-white border border-gray-300 rounded-lg shadow-2xl p-3 w-max max-w-xs"
                                  style={{ top: `${tooltipPos.top}px`, left: `${tooltipPos.left}px` }}
                                >
                                  <p className="text-xs font-semibold text-gray-700 mb-2">All Skills:</p>
                                  <div className="flex flex-wrap gap-1">
                                    {(skills || []).map((skill, idx) => {
                                      const isMatched = normalizedCompanySkills.has(normalize(skill));
                                      return (
                                        <span
                                          key={idx}
                                          className={`text-[11px] px-2 py-1 rounded-full font-medium border ${
                                            isMatched
                                              ? 'bg-green-100 text-green-800 border-green-300'
                                              : 'bg-blue-100 text-blue-700 border-blue-200'
                                          }`}
                                        >
                                          {skill}
                                        </span>
                                      );
                                    })}
                                  </div>
                                </div>
                              )}
                            </div>
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

      {/* Pagination Controls */}
      {students.length > 0 && totalCount > 0 && (
        <div className="mt-4 flex items-center justify-between bg-white p-4 rounded-xl border border-gray-200">
          <div className="text-sm text-gray-600">
            Showing <span className="font-semibold">{pageStartIndex + 1}</span> to <span className="font-semibold">{Math.min(pageStartIndex + pageSize, totalCount)}</span> of <span className="font-semibold">{totalCount}</span> students
          </div>
          
          <div className="flex items-center gap-2">
            <button
              onClick={() => fetchStudents(backendSearchRef.current, Math.max(1, safeCurrentPage - 1))}
              disabled={safeCurrentPage === 1 || backendSearchLoading}
              className="px-3 py-2 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Previous
            </button>

            <div className="flex items-center gap-1">
              {Array.from({ length: totalPages }, (_, i) => i + 1)
                .filter(page => {
                  const maxVisible = 5;
                  const start = Math.max(1, safeCurrentPage - Math.floor(maxVisible / 2));
                  const end = Math.min(totalPages, start + maxVisible - 1);
                  return page >= start && page <= end;
                })
                .map(page => (
                  <button
                    key={page}
                    onClick={() => fetchStudents(backendSearchRef.current, page)}
                    disabled={backendSearchLoading}
                    className={`w-10 h-10 rounded-lg text-sm font-medium transition-colors ${
                      page === safeCurrentPage
                        ? 'bg-blue-600 text-white'
                        : 'border border-gray-300 text-gray-700 hover:bg-gray-50 disabled:opacity-50'
                    }`}
                  >
                    {page}
                  </button>
                ))}
            </div>

            <button
              onClick={() => fetchStudents(backendSearchRef.current, Math.min(totalPages, safeCurrentPage + 1))}
              disabled={safeCurrentPage >= totalPages || backendSearchLoading}
              className="px-3 py-2 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Next
            </button>
          </div>

          <select
            value={pageSize}
            onChange={(e) => {
              const newPageSize = Number(e.target.value);
              setPageSize(newPageSize);
              // Pass newPageSize directly — React state update is async and pageSize
              // would still be the old value if we relied on it inside fetchStudents.
              fetchStudents(backendSearchRef.current, 1, newPageSize);
            }}
            disabled={backendSearchLoading}
            className="px-3 py-2 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50"
          >
            <option value={5}>5 per page</option>
            <option value={10}>10 per page</option>
            <option value={20}>20 per page</option>
            <option value={50}>50 per page</option>
          </select>
        </div>
      )}
    </div>
  );
}