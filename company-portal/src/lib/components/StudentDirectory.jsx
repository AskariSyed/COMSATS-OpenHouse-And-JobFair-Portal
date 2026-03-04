import React, { useState, useEffect } from 'react';
import { Search, Loader2, GraduationCap, AlertCircle, Clock, CheckCircle2, XCircle, UserPlus, Eye } from 'lucide-react';
import { getStudents, getStudentsByInterviewStatus, getFileUrl } from '../api';

export default function StudentDirectory({ onSelect, onError }) {
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(false);
  const [filters, setFilters] = useState({ type: '', value: '' });
  const [sortBy, setSortBy] = useState('name'); // Default sort by name
  const [listMode, setListMode] = useState('all');

  const fetchStudents = async () => {
    setLoading(true);
    try {
      let data;
      if (listMode === 'all') {
        data = await getStudents(filters.type, filters.value);
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

  const handleSearch = (e) => {
    e.preventDefault();
    fetchStudents();
  };

  // Sorting Logic
  const getSortedStudents = () => {
    return [...students].sort((a, b) => {
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
        <form onSubmit={handleSearch} className="grid grid-cols-1 md:grid-cols-5 gap-4">
          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase block mb-1">Filter By</label>
            <select
              className="w-full border rounded-lg p-2"
              onChange={(e) => setFilters({...filters, type: e.target.value})}
              disabled={listMode !== 'all'}
            >
              <option value="">All Students</option>
              <option value="skill">Skill</option>
              <option value="department">Department</option>
              <option value="registration">Registration No</option>
            </select>
          </div>
          <div className="col-span-2">
            <label className="text-xs font-semibold text-gray-500 uppercase block mb-1">Search Term</label>
            <input 
              disabled={!filters.type || listMode !== 'all'}
              placeholder={listMode !== 'all' ? 'Filters disabled for outcome lists' : !filters.type ? "Select filter first..." : "Enter search term..."}
              className="w-full border rounded-lg p-2"
              onChange={(e) => setFilters({...filters, value: e.target.value})}
            />
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
          <div className="flex items-end">
            <button type="submit" disabled={listMode !== 'all'} className="w-full bg-blue-600 text-white py-2 rounded-lg flex items-center justify-center gap-2 hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
              <Search className="w-4 h-4" /> Search
            </button>
          </div>
        </form>
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

                  <button
                    onClick={() => {
                      if (!safeId) return onError("Missing Student ID");
                      onSelect({ ...student, studentId: safeId });
                    }}
                    className="mt-2 w-full px-3 py-1.5 border border-blue-600 text-blue-600 rounded-lg text-xs font-medium hover:bg-blue-50 transition-colors flex items-center justify-center"
                    title="View Profile"
                    aria-label="View Profile"
                  >
                    <Eye className="w-4 h-4" />
                  </button>
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
                        <button 
                          onClick={() => {
                            if (!safeId) return onError("Missing Student ID");
                            onSelect({ ...student, studentId: safeId });
                          }} 
                          className="w-8 h-8 border border-blue-600 text-blue-600 rounded-lg hover:bg-blue-50 transition-colors inline-flex items-center justify-center"
                          title="View Profile"
                          aria-label="View Profile"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
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