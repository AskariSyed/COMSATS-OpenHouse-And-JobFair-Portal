import React, { useState, useEffect } from 'react';
import { Search, Loader2, GraduationCap, AlertCircle, Clock, CheckCircle2, XCircle, UserPlus } from 'lucide-react';
import { getStudents, getFileUrl } from '../api';

export default function StudentDirectory({ onSelect, onError }) {
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(false);
  const [filters, setFilters] = useState({ type: '', value: '' });

  const fetchStudents = async () => {
    setLoading(true);
    try {
      const data = await getStudents(filters.type, filters.value);
      setStudents(data || []);
    } catch (err) {
      onError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchStudents(); }, []);

  const handleSearch = (e) => {
    e.preventDefault();
    fetchStudents();
  };

  const getStudentId = (s) => s.StudentId || s.studentId || s.id;

  // --- LOGIC: Render Status Chip ---
  const renderStatusChip = (student) => {
    const req = student.InterviewRequest || student.interviewRequest;
    
    if (!req || (!req.HasRequest && !req.hasRequest)) return null;

    const status = (req.Status || req.status || '').toLowerCase();
    // Handle Enum: 0 = Company, 1 = Student
    const requestedByVal = req.RequestedBy !== undefined ? req.RequestedBy : req.requestedBy;
    const isStudentRequest = requestedByVal === 1 || requestedByVal === 'Student';

    if (status === 'accepted') {
        return (
            <span className="absolute top-4 right-4 bg-green-100 text-green-700 text-[10px] font-bold px-2 py-1 rounded-full flex items-center gap-1 shadow-sm border border-green-200 z-10">
                <CheckCircle2 className="w-3 h-3" /> Scheduled
            </span>
        );
    }
    if (status === 'rejected') {
        return (
            <span className="absolute top-4 right-4 bg-red-50 text-red-600 text-[10px] font-bold px-2 py-1 rounded-full flex items-center gap-1 shadow-sm border border-red-100 z-10">
                <XCircle className="w-3 h-3" /> Rejected
            </span>
        );
    }
    if (status === 'pending') {
        if (isStudentRequest) {
            return (
                <span className="absolute top-4 right-4 bg-purple-100 text-purple-700 text-[10px] font-bold px-2 py-1 rounded-full flex items-center gap-1 shadow-sm border border-purple-200 z-10 animate-pulse">
                    <UserPlus className="w-3 h-3" /> Incoming Request
                </span>
            );
        } else {
            return (
                <span className="absolute top-4 right-4 bg-yellow-50 text-yellow-700 text-[10px] font-bold px-2 py-1 rounded-full flex items-center gap-1 shadow-sm border border-yellow-200 z-10">
                    <Clock className="w-3 h-3" /> Request Sent
                </span>
            );
        }
    }
    return null;
  };

  return (
    <div>
      {/* Filters */}
      <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-200 mb-6">
        <form onSubmit={handleSearch} className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase block mb-1">Filter By</label>
            <select className="w-full border rounded-lg p-2" onChange={(e) => setFilters({...filters, type: e.target.value})}>
              <option value="">All Students</option>
              <option value="skill">Skill</option>
              <option value="department">Department</option>
              <option value="registration">Registration No</option>
            </select>
          </div>
          <div className="col-span-2">
            <label className="text-xs font-semibold text-gray-500 uppercase block mb-1">Search Term</label>
            <input 
              disabled={!filters.type}
              placeholder={!filters.type ? "Select filter first..." : "Enter search term..."} 
              className="w-full border rounded-lg p-2"
              onChange={(e) => setFilters({...filters, value: e.target.value})}
            />
          </div>
          <div className="flex items-end">
            <button type="submit" className="w-full bg-blue-600 text-white py-2 rounded-lg flex items-center justify-center gap-2 hover:bg-blue-700 transition-colors">
              <Search className="w-4 h-4" /> Search
            </button>
          </div>
        </form>
      </div>

      {/* Grid */}
      {loading ? (
        <div className="text-center py-12"><Loader2 className="animate-spin mx-auto text-blue-600" /></div>
      ) : students.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-xl border border-dashed border-gray-200">
           <AlertCircle className="w-10 h-10 text-gray-300 mx-auto mb-3" />
           <p className="text-gray-500">No students found.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {students.map((student, index) => {
            const safeId = getStudentId(student);
            const key = safeId || index; 
            
            return (
            <div key={key} className="bg-white rounded-xl border border-gray-200 hover:shadow-lg transition-all p-6 flex flex-col relative group">
              
              {/* STATUS CHIP */}
              {renderStatusChip(student)}

              <div className="flex justify-between items-start mb-4 mt-2">
                <div className="flex gap-3">
                  <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center font-bold text-blue-600 text-lg overflow-hidden border border-gray-100 flex-shrink-0">
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
                  <div className="min-w-0 pr-10">
                    <h3 className="font-bold text-gray-900 line-clamp-1 group-hover:text-blue-600 transition-colors" title={student.Name || student.name}>
                        {student.Name || student.name}
                    </h3>
                    <p className="text-xs text-gray-500">{student.RegistrationNo || student.registrationNo}</p>
                  </div>
                </div>
              </div>
              
              <p className="text-sm text-gray-600 mb-4 flex items-center gap-2">
                <GraduationCap className="w-4 h-4 text-blue-500" /> {student.Department || student.department}
              </p>
              
              <div className="flex flex-wrap gap-2 mb-4 flex-1 content-start">
                {(student.Skills || student.skills)?.slice(0, 3).map((s, i) => (
                  <span key={i} className="text-[10px] bg-gray-50 text-gray-600 border border-gray-100 px-2 py-1 rounded">{s}</span>
                ))}
                {(student.Skills || student.skills)?.length > 3 && (
                   <span className="text-[10px] text-gray-400 self-center">+{ (student.Skills || student.skills).length - 3}</span>
                )}
              </div>
              
              <button 
                onClick={() => {
                    if (!safeId) return onError("Missing Student ID");
                    onSelect({ ...student, studentId: safeId });
                }} 
                className="w-full border border-blue-600 text-blue-600 py-2.5 rounded-lg text-sm font-medium hover:bg-blue-50 transition-colors mt-auto"
              >
                View Profile
              </button>
            </div>
            );
          })}
        </div>
      )}
    </div>
  );
}