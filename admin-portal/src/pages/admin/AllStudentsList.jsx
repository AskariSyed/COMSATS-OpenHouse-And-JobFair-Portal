/* eslint-disable no-unused-vars */
import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Search, Filter, Eye, BookOpen, Award, XCircle, Bell, CheckCircle, UserPlus, ArrowUpDown, RotateCcw
} from 'lucide-react';
import { toast } from 'react-hot-toast';
import SendNotificationModal from '../../lib/components/SendNotificationModal';
import api, { BACKEND_URL, getAllStudentsGlobal, registerStudentForFair } from '../../lib/api';

// 🔧 CONFIGURATION

const getImageUrl = (path) => {
  if (!path) return null;
  if (path.startsWith('http')) return path; 
  // Now it uses the central configuration
  return `${BACKEND_URL}${path}`; 
};

const AllStudentsList = () => {
  const navigate = useNavigate();
  const [students, setStudents] = useState([]);
  const [meta, setMeta] = useState({ page: 1, totalPages: 1, totalCount: 0 });
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [departmentFilter, setDepartmentFilter] = useState('');
  const [sortConfig, setSortConfig] = useState({ key: 'name', direction: 'asc' });
  
  // Notification Modal State
  const [notifyModal, setNotifyModal] = useState({ open: false, student: null });

  // Fetch Students (Accepts page AND search query)
  const fetchStudents = async (page = 1, search = '', dept = '') => {
    setLoading(true);
    try {
      // Use Global Endpoint to see ALL students
      const res = await getAllStudentsGlobal(page, search, dept);
      
      if (Array.isArray(res.data)) {
         setStudents(res.data);
         setMeta({ page, totalPages: 1, totalCount: res.data.length });
      } else {
         setStudents(res.data.data || res.data.students || []);
         setMeta({
            page: res.data.page || page,
            totalPages: res.data.totalPages || 1,
            totalCount: res.data.totalCount || 0
         });
      }

    } catch (error) {
      console.error(error);
      toast.error("Failed to fetch students");
    } finally {
      setLoading(false);
    }
  };

  const handleRegister = async (studentId) => {
    try {
      await registerStudentForFair(studentId);
      toast.success("Student registered for Job Fair");
      fetchStudents(meta.page, searchTerm, departmentFilter); // Refresh
    } catch (error) {
      toast.error("Failed to register student");
    }
  };

  // Initial Load
  useEffect(() => {
    fetchStudents(1, searchTerm, departmentFilter);
  }, [departmentFilter]); // Refetch when department changes

  // Handler: When user types
  const handleSearch = (e) => {
    e.preventDefault(); 
    fetchStudents(1, searchTerm, departmentFilter);
  };

  // Handler: Clear search
  const clearFilters = () => {
    setSearchTerm('');
    setDepartmentFilter('');
    setSortConfig({ key: 'name', direction: 'asc' });
    fetchStudents(1, '', '');
  };

  // Client-side Sorting
  const sortedStudents = [...students].sort((a, b) => {
    if (sortConfig.key === 'name') {
      return sortConfig.direction === 'asc' 
        ? (a.name || '').localeCompare(b.name || '')
        : (b.name || '').localeCompare(a.name || '');
    }
    if (sortConfig.key === 'cgpa') {
      return sortConfig.direction === 'asc' 
        ? (a.cgpa || 0) - (b.cgpa || 0)
        : (b.cgpa || 0) - (a.cgpa || 0);
    }
    if (sortConfig.key === 'regNo') {
       return sortConfig.direction === 'asc'
        ? (a.registrationNo || '').localeCompare(b.registrationNo || '')
        : (b.registrationNo || '').localeCompare(a.registrationNo || '');
    }
    return 0;
  });

  return (
    <div className="space-y-6 animate-fade-in pb-10">
      
      {/* Header & Controls */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">All Students Directory</h1>
          <p className="text-gray-500 text-sm">Global list of all registered students.</p>
        </div>
        
        <div className="flex flex-wrap gap-2 w-full sm:w-auto items-center">
          
          {/* Notify All Button */}
          <button 
            onClick={() => setNotifyModal({ open: true, student: null })}
            className="flex items-center gap-2 px-4 py-2 bg-amber-500 text-white rounded-lg text-sm font-medium hover:bg-amber-600 shadow-sm transition"
          >
            <Bell size={16} /> Notify All
          </button>
        </div>
      </div>

      {/* Toolbar */}
      <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex flex-col lg:flex-row gap-4 items-end lg:items-center justify-between sticky top-0 z-10">
        <div className="flex flex-wrap gap-3 w-full lg:w-auto">
          {/* Search */}
          <form onSubmit={handleSearch} className="relative group">
            <Search className="w-4 h-4 absolute left-3 top-2.5 text-gray-400 group-focus-within:text-indigo-500 transition-colors" />
            <input 
              type="text" 
              placeholder="Search name, reg no..." 
              className="pl-9 pr-8 py-2 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 focus:border-transparent outline-none w-64 transition-all"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            {searchTerm && (
              <button 
                type="button" 
                onClick={() => { setSearchTerm(''); fetchStudents(1, '', departmentFilter); }}
                className="absolute right-2 top-2.5 text-gray-400 hover:text-gray-600"
              >
                <XCircle size={16} />
              </button>
            )}
          </form>

          {/* Department Filter */}
          <div className="flex items-center gap-2 border border-gray-200 rounded-lg px-3 py-2 bg-gray-50 focus-within:bg-white focus-within:ring-2 focus-within:ring-indigo-500 transition-all">
            <Filter size={14} className="text-gray-500" />
            <select 
              className="bg-transparent outline-none text-sm text-gray-700 cursor-pointer min-w-[120px]"
              value={departmentFilter}
              onChange={(e) => setDepartmentFilter(e.target.value)}
            >
              <option value="">All Departments</option>
              <option value="CS">Computer Science</option>
              <option value="SE">Software Engineering</option>
              <option value="IT">Information Technology</option>
              <option value="EE">Electrical Engineering</option>
              <option value="CE">Civil Engineering</option>
              <option value="ME">Mechanical Engineering</option>
              <option value="BBA">Management Sciences</option>
            </select>
          </div>
        </div>
        
        <div className="flex gap-3 items-center w-full lg:w-auto justify-end">
          {/* Sort Dropdown */}
          <div className="flex items-center gap-2">
            <ArrowUpDown size={16} className="text-gray-400" />
            <select 
              className="text-sm font-medium text-gray-700 bg-transparent outline-none cursor-pointer hover:text-indigo-600" 
              value={`${sortConfig.key}-${sortConfig.direction}`} 
              onChange={(e) => { const [key, direction] = e.target.value.split('-'); setSortConfig({ key, direction }); }}
            >
              <option value="name-asc">Name (A-Z)</option>
              <option value="name-desc">Name (Z-A)</option>
              <option value="cgpa-desc">CGPA (High-Low)</option>
              <option value="cgpa-asc">CGPA (Low-High)</option>
              <option value="regNo-asc">Reg No (Asc)</option>
            </select>
          </div>
          
          <button 
            onClick={clearFilters} 
            className="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-full transition" 
            title="Reset Filters"
          >
            <RotateCcw size={18} />
          </button>
        </div>
      </div>

      {/* Data Table */}
      <div className="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Student</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Reg No</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Dept</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">CGPA</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Status</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {loading ? (
                 [...Array(5)].map((_, i) => (
                   <tr key={i} className="animate-pulse">
                      <td colSpan="7" className="px-6 py-4"><div className="h-10 bg-gray-100 rounded w-full"></div></td>
                   </tr>
                 ))
              ) : sortedStudents.length > 0 ? (
                sortedStudents.map((s) => (
                  <tr key={s.studentId} className="hover:bg-gray-50 transition-colors">
                    {/* Name & Pic */}
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-700 font-bold text-sm shrink-0 overflow-hidden border border-indigo-200">
                          {(s.profilePicUrl || s.profilePic) ? (
                            <img 
                              src={getImageUrl(s.profilePicUrl || s.profilePic)} 
                              className="w-full h-full object-cover" 
                              alt={s.name}
                              onError={(e) => { e.target.style.display = 'none'; e.target.parentElement.innerText = s.name?.charAt(0); }} 
                            />
                          ) : (
                            s.name?.charAt(0)
                          )}
                        </div>
                        <div>
                           <p className="font-medium text-gray-900">{s.name}</p>
                           <p className="text-xs text-gray-500 truncate max-w-[150px]">{s.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm font-mono text-gray-600">{s.registrationNo}</td>
                    <td className="px-6 py-4"><span className="bg-blue-50 text-blue-700 px-2 py-0.5 rounded text-xs">{s.department}</span></td>
                    <td className="px-6 py-4"><span className={`font-bold ${s.cgpa >= 3.0 ? 'text-emerald-600' : 'text-gray-600'}`}>{s.cgpa?.toFixed(2)}</span></td>
                    
                    {/* Status Column */}
                    <td className="px-6 py-4">
                      {s.isRegistered ? (
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                          <CheckCircle size={12} /> Registered
                        </span>
                      ) : (
                        <button 
                          onClick={() => handleRegister(s.studentId)}
                          className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-600 hover:bg-indigo-100 hover:text-indigo-700 transition-colors"
                        >
                          <UserPlus size={12} /> Register
                        </button>
                      )}
                    </td>

                    <td className="px-6 py-4 text-right">
                      <div className="flex justify-end gap-2">
                        <button 
                          onClick={() => setNotifyModal({ open: true, student: s })}
                          className="text-amber-600 hover:text-amber-900 bg-amber-50 p-2 rounded-lg hover:bg-amber-100 transition"
                          title="Notify Student"
                        >
                          <Bell size={16} />
                        </button>
                        <button 
                          onClick={() => navigate(`/admin/students/${s.studentId}`)} 
                          className="text-indigo-600 hover:text-indigo-900 bg-indigo-50 p-2 rounded-lg hover:bg-indigo-100 transition"
                          title="View Details"
                        >
                          <Eye size={16} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="7" className="px-6 py-16 text-center">
                    <div className="flex flex-col items-center justify-center text-gray-500">
                      <div className="bg-gray-100 p-4 rounded-full mb-3">
                        <Search size={32} className="text-gray-400" />
                      </div>
                      <h3 className="text-lg font-semibold text-gray-700 mb-1">No Students Found</h3>
                      <p className="text-sm max-w-xs mx-auto mb-4">
                        We couldn't find any students matching <strong>"{searchTerm}"</strong>. 
                        Try adjusting your search or filters.
                      </p>
                      {searchTerm && (
                        <button 
                          onClick={clearSearch}
                          className="text-indigo-600 hover:text-indigo-800 font-medium text-sm flex items-center gap-1"
                        >
                          <XCircle size={14} /> Clear Search
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="px-6 py-4 border-t border-gray-200 bg-gray-50 flex items-center justify-between">
            <span className="text-sm text-gray-500">
              Showing Page {meta.page} of {meta.totalPages}
            </span>
            <div className="flex gap-2">
                <button 
                  onClick={() => fetchStudents(meta.page - 1, searchTerm, departmentFilter)} 
                  disabled={meta.page <= 1} 
                  className="px-4 py-2 border rounded-lg bg-white text-sm font-medium hover:bg-gray-50 disabled:opacity-50"
                >
                  Previous
                </button>
                <button 
                  onClick={() => fetchStudents(meta.page + 1, searchTerm, departmentFilter)} 
                  disabled={meta.page >= meta.totalPages} 
                  className="px-4 py-2 border rounded-lg bg-white text-sm font-medium hover:bg-gray-50 disabled:opacity-50"
                >
                  Next
                </button>
            </div>
         </div>
      </div>

      {/* Notification Modal */}
      <SendNotificationModal 
        isOpen={notifyModal.open} 
        onClose={() => setNotifyModal({ open: false, student: null })}
        recipientId={notifyModal.student?.studentId}
        recipientName={notifyModal.student?.name}
        type="student"
      />
    </div>
  );
};

export default AllStudentsList;