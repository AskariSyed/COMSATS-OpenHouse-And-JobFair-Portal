import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Search, Filter, Eye, BookOpen, Award, XCircle, Bell, Edit2, X, Save, ArrowUpDown, ChevronDown, ChevronUp, FileText
} from 'lucide-react';
import { toast } from 'react-hot-toast';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import SendNotificationModal from '../../lib/components/SendNotificationModal';
import api, { getFileUrl, updateStudentCredentials } from '../../lib/api';
import { getAllJobFairs } from '../../lib/api';

// 🔧 CONFIGURATION

const StudentsList = () => {
  const strongPasswordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$/;
  const navigate = useNavigate();
  const [students, setStudents] = useState([]);
  const [meta, setMeta] = useState({ page: 1, totalPages: 1, totalCount: 0 });
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [jobFairs, setJobFairs] = useState([]);
  const [selectedJobFairId, setSelectedJobFairId] = useState('');
  const [editingId, setEditingId] = useState(null);
  const [editFormData, setEditFormData] = useState({ email: '', password: '' });
  const [editLoading, setEditLoading] = useState(false);
  const [sortConfig, setSortConfig] = useState({ key: 'name', direction: 'asc' });
  const [expandedStudentId, setExpandedStudentId] = useState(null);
  
  // Notification Modal State
  const [notifyModal, setNotifyModal] = useState({ open: false, student: null });

  // Fetch Students (Accepts page AND search query)
  const fetchStudents = useCallback(async (page = 1, search = '', jobFairId = '') => {
    setLoading(true);
    try {
      // Append search param if it exists
      const searchQuery = search ? `&search=${encodeURIComponent(search)}` : '';
      const jobFairQuery = jobFairId ? `&jobFairId=${encodeURIComponent(jobFairId)}` : '';
      const res = await api.get(`/admin/students?page=${page}&pageSize=15${searchQuery}${jobFairQuery}`);
      
      setStudents(res.data.students);
      setMeta({
        page: res.data.page,
        totalPages: res.data.totalPages,
        totalCount: res.data.totalCount
      });
    } catch (error) {
      console.error(error);
      toast.error("Failed to fetch students");
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchJobFairs = useCallback(async () => {
    try {
      const response = await getAllJobFairs();
      const jobFairsList = response.data?.jobFairs || response.data?.JobFairs || response.data || [];
      const normalizedJobFairs = Array.isArray(jobFairsList) ? jobFairsList : [];
      setJobFairs(normalizedJobFairs);

      const active = normalizedJobFairs.find(jf => (jf.isActive ?? jf.IsActive) === true);
      const activeId = active ? (active.jobFairId ?? active.JobFairId) : '';
      setSelectedJobFairId(activeId ? String(activeId) : '');
      await fetchStudents(1, '', activeId ? String(activeId) : '');
    } catch (error) {
      console.error(error);
      toast.error('Failed to fetch job fairs');
      await fetchStudents(1, '', '');
    }
  }, [fetchStudents]);

  // Initial Load
  useEffect(() => {
    fetchJobFairs();
  }, [fetchJobFairs]);

  // Handler: When user types
  const handleSearch = (e) => {
    e.preventDefault(); 
    fetchStudents(1, searchTerm, selectedJobFairId);
  };

  // Handler: Clear search
  const clearSearch = () => {
    setSearchTerm('');
    fetchStudents(1, '', selectedJobFairId);
  };

  const downloadStudentsList = async () => {
    try {
      const toastId = toast.loading('Generating Excel file...');
      const query = [];
      if (selectedJobFairId) query.push(`jobFairId=${selectedJobFairId}`);
      if (searchTerm) query.push(`search=${encodeURIComponent(searchTerm)}`);
      const queryString = query.length ? `?${query.join('&')}` : '';

      const response = await api.get(`/admin/students/export${queryString}`, {
        responseType: 'blob'
      });
      
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `StudentsList_${new Date().toISOString().split('T')[0]}.xlsx`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      
      toast.dismiss(toastId);
      toast.success('Downloaded successfully');
    } catch (error) {
      console.error(error);
      toast.error('Failed to download students list');
    }
  };

  const downloadPdfReport = async () => {
    const toastId = toast.loading('Preparing PDF report...');
    try {
      const query = [];
      if (selectedJobFairId) query.push(`jobFairId=${selectedJobFairId}`);
      if (searchTerm) query.push(`search=${encodeURIComponent(searchTerm)}`);
      query.push(`page=1&pageSize=10000`);
      const queryString = query.length ? `?${query.join('&')}` : '';

      const res = await api.get(`/admin/students${queryString}`);
      const allStudents = res.data.students || [];

      const doc = new jsPDF();
      
      doc.setFontSize(18);
      doc.setTextColor(79, 70, 229);
      doc.text("Student Profile Completeness Report", 14, 20);
      
      doc.setFontSize(10);
      doc.setTextColor(100);
      doc.text(`Generated on: ${new Date().toLocaleString()}`, 14, 28);

      const total = allStudents.length;
      const complete = allStudents.filter(s => s.isProfileComplete).length;
      const incomplete = total - complete;

      doc.setFontSize(12);
      doc.setTextColor(0);
      doc.text(`Total Students: ${total}  |  Complete: ${complete}  |  Incomplete: ${incomplete}`, 14, 40);

      const tableData = allStudents.map(s => {
        return [
          s.name || '-',
          s.registrationNo || '-',
          s.department || '-',
          s.cgpa?.toFixed(2) || '-',
          s.isProfileComplete ? 'Yes' : 'No',
          s.isProfileComplete ? '-' : (s.missingItems || 'Unknown')
        ];
      });

      autoTable(doc, {
        startY: 45,
        head: [['Name', 'Reg No', 'Department', 'CGPA', 'Profile Complete', 'Missing Details']],
        body: tableData,
        theme: 'striped',
        headStyles: { fillColor: [79, 70, 229] },
        styles: { fontSize: 10 },
        didParseCell: function (data) {
          if (data.section === 'body' && data.column.index === 4) {
            const status = data.cell.raw;
            if (status === 'Yes') data.cell.styles.textColor = [16, 185, 129];
            if (status === 'No') data.cell.styles.textColor = [225, 29, 72];
          }
        }
      });

      doc.save(`Student_Profiles_${new Date().toISOString().split('T')[0]}.pdf`);
      toast.dismiss(toastId);
      toast.success("PDF downloaded successfully!");
    } catch (error) {
      console.error(error);
      toast.dismiss(toastId);
      toast.error('Failed to generate PDF report');
    }
  };

  const handleEditClick = (student) => {
    setEditingId(student.studentId);
    setEditFormData({
      email: student.email || '',
      password: ''
    });
  };

  const handleEditSave = async (studentId) => {
    try {
      setEditLoading(true);
      const updateData = {};
      if (editFormData.email.trim()) updateData.email = editFormData.email.trim();
      if (editFormData.password.trim()) {
        if (!strongPasswordRegex.test(editFormData.password.trim())) {
          toast.error('Password must include uppercase, lowercase, number, special character and be at least 8 characters.');
          setEditLoading(false);
          return;
        }
        updateData.password = editFormData.password.trim();
      }

      if (Object.keys(updateData).length === 0) {
        toast.error('Please update at least one field');
        return;
      }

      await updateStudentCredentials(studentId, updateData);
      toast.success('Student credentials updated');
      setEditingId(null);
      setEditFormData({ email: '', password: '' });
      fetchStudents(meta.page, searchTerm, selectedJobFairId);
    } catch (error) {
      console.error(error);
      const errorMsg = error.response?.data?.Message || 'Failed to update credentials';
      toast.error(errorMsg);
    } finally {
      setEditLoading(false);
    }
  };

  const sortedStudents = useMemo(() => {
    return [...students].sort((a, b) => {
      const directionFactor = sortConfig.direction === 'asc' ? 1 : -1;

      if (sortConfig.key === 'cgpa') {
        return (((a.cgpa ?? 0) - (b.cgpa ?? 0)) * directionFactor);
      }

      if (sortConfig.key === 'registrationNo') {
        return ((a.registrationNo || '').localeCompare(b.registrationNo || '') * directionFactor);
      }

      if (sortConfig.key === 'department') {
        return ((a.department || '').localeCompare(b.department || '') * directionFactor);
      }

      return ((a.name || '').localeCompare(b.name || '') * directionFactor);
    });
  }, [students, sortConfig]);

  const toggleSort = (key) => {
    setSortConfig((prev) => {
      if (prev.key === key) {
        return { key, direction: prev.direction === 'asc' ? 'desc' : 'asc' };
      }
      return { key, direction: 'asc' };
    });
  };

  return (
    <div className="space-y-6 animate-fade-in pb-10">
      
      {/* Header & Controls */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Student Directory</h1>
          <p className="text-gray-500 text-sm">View profiles, FYPs, and academic details.</p>
        </div>
        
        <div className="flex flex-wrap gap-2 w-full sm:w-auto items-center">
          
          <button 
            onClick={downloadPdfReport}
            className="flex items-center gap-2 px-4 py-2 bg-white border border-gray-200 text-gray-700 rounded-lg text-sm font-medium hover:bg-gray-50 shadow-sm transition"
          >
            <FileText size={16} className="text-indigo-600" /> PDF Report
          </button>

          {/* Download CSV Button */}
          <button 
            onClick={downloadStudentsList}
            className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg text-sm font-medium hover:bg-green-700 shadow-sm transition"
          >
            <BookOpen size={16} /> Download Excel
          </button>

          {/* Notify All Button */}
          <button 
            onClick={() => setNotifyModal({ open: true, student: null })}
            className="flex items-center gap-2 px-4 py-2 bg-amber-500 text-white rounded-lg text-sm font-medium hover:bg-amber-600 shadow-sm transition"
          >
            <Bell size={16} /> Notify All
          </button>

          {/* Search Form */}
          <select
            value={selectedJobFairId}
            onChange={(e) => {
              const nextJobFairId = e.target.value;
              setSelectedJobFairId(nextJobFairId);
              fetchStudents(1, searchTerm, nextJobFairId);
            }}
            className="px-3 py-2 border rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 shadow-sm"
          >
            <option value="">Active Job Fair</option>
            {jobFairs.map((jf) => {
              const id = jf.jobFairId ?? jf.JobFairId;
              const semester = jf.semester ?? jf.Semester;
              const isActive = jf.isActive ?? jf.IsActive;
              return (
                <option key={id} value={String(id)}>
                  {semester}{isActive ? ' (Active)' : ''}
                </option>
              );
            })}
          </select>

          {/* Search Form */}
          <form onSubmit={handleSearch} className="relative flex-1 sm:w-64">
            <input 
              type="text" 
              placeholder="Search name, reg no..." 
              className="pl-9 pr-8 py-2 border rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none w-full shadow-sm"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            <Search className="w-4 h-4 absolute left-3 top-2.5 text-gray-400" />
            
            {searchTerm && (
              <button 
                type="button" 
                onClick={clearSearch}
                className="absolute right-2 top-2.5 text-gray-400 hover:text-gray-600"
              >
                <XCircle size={16} />
              </button>
            )}
          </form>

          <button 
            onClick={() => fetchStudents(1, searchTerm, selectedJobFairId)}
            className="px-4 py-2 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 shadow-sm transition"
          >
            Search
          </button>
        </div>
      </div>

      {/* Data Table */}
      <div className="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">
                  <button type="button" onClick={() => toggleSort('name')} className="inline-flex items-center gap-1 hover:text-gray-700">
                    Student <ArrowUpDown size={12} />
                  </button>
                </th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">
                  <button type="button" onClick={() => toggleSort('registrationNo')} className="inline-flex items-center gap-1 hover:text-gray-700">
                    Reg No <ArrowUpDown size={12} />
                  </button>
                </th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">
                  <button type="button" onClick={() => toggleSort('department')} className="inline-flex items-center gap-1 hover:text-gray-700">
                    Dept <ArrowUpDown size={12} />
                  </button>
                </th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">
                  <button type="button" onClick={() => toggleSort('cgpa')} className="inline-flex items-center gap-1 hover:text-gray-700">
                    CGPA <ArrowUpDown size={12} />
                  </button>
                </th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">
                  Complete
                </th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {loading ? (
                 [...Array(5)].map((_, i) => (
                   <tr key={i} className="animate-pulse">
                      <td colSpan="8" className="px-6 py-4"><div className="h-10 bg-gray-100 rounded w-full"></div></td>
                   </tr>
                 ))
              ) : sortedStudents.length > 0 ? (
                sortedStudents.map((s) => (
                  <React.Fragment key={s.studentId}>
                    <tr
                      className="hover:bg-indigo-50 cursor-pointer transition-colors"
                      onClick={() => navigate(`/admin/students/${s.studentId}`)}
                      title="View Profile"
                    >
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-9 h-9 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-700 font-bold text-sm shrink-0 overflow-hidden">
                            {(s.profilePicUrl || s.profilePic || s.profilePicPath) ? (
                              <img
                                src={getFileUrl(s.profilePicUrl || s.profilePic || s.profilePicPath)}
                                className="w-full h-full object-cover"
                                alt={s.name}
                                onError={e => { e.target.onerror = null; e.target.src = '/default-profile.png'; }}
                              />
                            ) : (
                              s.name?.charAt(0)
                            )}
                          </div>
                          <div>
                            <p className="font-medium text-indigo-700 underline underline-offset-2">{s.name}</p>
                            <p className="text-xs text-gray-500 truncate max-w-[150px]">{s.email}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-sm font-mono text-gray-600">{s.registrationNo}</td>
                      <td className="px-6 py-4"><span className="bg-blue-50 text-blue-700 px-2 py-0.5 rounded text-xs">{s.department}</span></td>
                      <td className="px-6 py-4"><span className={`font-bold ${s.cgpa >= 3.0 ? 'text-emerald-600' : 'text-gray-600'}`}>{s.cgpa?.toFixed(2)}</span></td>
                      <td className="px-6 py-4">
                        <span className={`inline-flex px-2 py-0.5 rounded text-xs font-semibold ${s.isProfileComplete ? 'bg-emerald-100 text-emerald-700' : 'bg-rose-100 text-rose-700'}`}>
                          {s.isProfileComplete ? 'Yes' : 'No'}
                        </span>
                      </td>

                      <td className="px-6 py-4 text-right">
                        {editingId === s.studentId ? (
                          <div className="flex flex-col gap-2 bg-gray-50 p-3 rounded-lg -mr-3">
                            <input
                              type="email"
                              placeholder="New Email"
                              value={editFormData.email}
                              onChange={(e) => setEditFormData({ ...editFormData, email: e.target.value })}
                              className="px-2 py-1 border rounded text-sm focus:ring-2 focus:ring-indigo-500 outline-none"
                            />
                            <input
                              type="password"
                              placeholder="New Password (optional)"
                              value={editFormData.password}
                              onChange={(e) => setEditFormData({ ...editFormData, password: e.target.value })}
                              className="px-2 py-1 border rounded text-sm focus:ring-2 focus:ring-indigo-500 outline-none"
                            />
                            <div className="flex gap-2">
                              <button
                                onClick={e => { e.stopPropagation(); handleEditSave(s.studentId); }}
                                disabled={editLoading}
                                className="flex-1 text-xs bg-green-600 text-white px-2 py-1 rounded hover:bg-green-700 disabled:opacity-60"
                              >
                                Save
                              </button>
                              <button
                                onClick={e => { e.stopPropagation(); setEditingId(null); }}
                                className="flex-1 text-xs bg-gray-400 text-white px-2 py-1 rounded hover:bg-gray-500"
                              >
                                Cancel
                              </button>
                            </div>
                          </div>
                        ) : (
                          <div className="flex justify-end gap-2">
                            <button
                              onClick={e => {
                                e.stopPropagation();
                                setExpandedStudentId(expandedStudentId === s.studentId ? null : s.studentId);
                              }}
                              className="text-violet-600 hover:text-violet-900 bg-violet-50 p-2 rounded-lg hover:bg-violet-100 transition"
                              title="Toggle Interview History"
                            >
                              {expandedStudentId === s.studentId ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
                            </button>
                            <button
                              onClick={e => { e.stopPropagation(); navigate(`/admin/students/${s.studentId}?edit=profile`); }}
                              className="text-emerald-600 hover:text-emerald-900 bg-emerald-50 p-2 rounded-lg hover:bg-emerald-100 transition"
                              title="Edit Full Profile"
                            >
                              <BookOpen size={16} />
                            </button>
                            <button
                              onClick={e => { e.stopPropagation(); handleEditClick(s); }}
                              className="text-blue-600 hover:text-blue-900 bg-blue-50 p-2 rounded-lg hover:bg-blue-100 transition"
                              title="Edit Credentials"
                            >
                              <Edit2 size={16} />
                            </button>
                            <button
                              onClick={e => { e.stopPropagation(); setNotifyModal({ open: true, student: s }); }}
                              className="text-amber-600 hover:text-amber-900 bg-amber-50 p-2 rounded-lg hover:bg-amber-100 transition"
                              title="Notify Student"
                            >
                              <Bell size={16} />
                            </button>
                            {s.cvUrl && (
                              <>
                                <a
                                  href={getFileUrl(s.cvUrl)}
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="text-fuchsia-600 hover:text-fuchsia-900 bg-fuchsia-50 p-2 rounded-lg hover:bg-fuchsia-100 transition"
                                  title="View CV"
                                  onClick={e => e.stopPropagation()}
                                >
                                  <Eye size={16} />
                                </a>
                                <a
                                  href={getFileUrl(s.cvUrl)}
                                  download
                                  className="text-green-600 hover:text-green-900 bg-green-50 p-2 rounded-lg hover:bg-green-100 transition"
                                  title="Download CV"
                                  onClick={e => e.stopPropagation()}
                                >
                                  <BookOpen size={16} />
                                </a>
                              </>
                            )}
                          </div>
                        )}
                      </td>
                    </tr>

                    {expandedStudentId === s.studentId && (
                      <tr className="bg-gray-50">
                        <td colSpan="6" className="px-6 py-4">
                          <div className="rounded-lg border border-gray-200 bg-white overflow-hidden">
                            <div className="px-4 py-3 border-b bg-gray-50">
                              <p className="text-sm font-semibold text-gray-700">Interview History</p>
                            </div>

                            {Array.isArray(s.interviewHistory) && s.interviewHistory.length > 0 ? (
                              <div className="overflow-x-auto">
                                <table className="w-full text-sm">
                                  <thead className="bg-gray-100 text-gray-600">
                                    <tr>
                                      <th className="px-4 py-2 text-left">Company</th>
                                      <th className="px-4 py-2 text-left">Result</th>
                                      <th className="px-4 py-2 text-left">Scheduled</th>
                                      <th className="px-4 py-2 text-left">Last Updated</th>
                                    </tr>
                                  </thead>
                                  <tbody className="divide-y divide-gray-100">
                                    {s.interviewHistory.map((item) => (
                                      <tr key={item.interviewId}>
                                        <td className="px-4 py-2 font-medium text-gray-800">{item.companyName || 'Unknown Company'}</td>
                                        <td className="px-4 py-2">
                                          <span className={`inline-flex px-2 py-0.5 rounded text-xs font-semibold ${
                                            item.result === 'Hired'
                                              ? 'bg-emerald-100 text-emerald-700'
                                              : item.result === 'Shortlisted'
                                                ? 'bg-amber-100 text-amber-700'
                                                : item.result === 'Rejected'
                                                  ? 'bg-rose-100 text-rose-700'
                                                  : 'bg-gray-100 text-gray-700'
                                          }`}>
                                            {item.result}
                                          </span>
                                        </td>
                                        <td className="px-4 py-2 text-gray-600">{item.scheduledTime ? new Date(item.scheduledTime).toLocaleString() : 'Not Scheduled'}</td>
                                        <td className="px-4 py-2 text-gray-600">{item.updatedAt ? new Date(item.updatedAt).toLocaleString() : '-'}</td>
                                      </tr>
                                    ))}
                                  </tbody>
                                </table>
                              </div>
                            ) : (
                              <div className="px-4 py-4 text-sm text-gray-500">
                                No interview record found for this student in the selected job fair.
                              </div>
                            )}
                          </div>
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                ))
              ) : (
                <tr>
                  <td colSpan="8" className="px-6 py-16 text-center">
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
                  onClick={() => fetchStudents(meta.page - 1, searchTerm, selectedJobFairId)} 
                  disabled={meta.page <= 1} 
                  className="px-4 py-2 border rounded-lg bg-white text-sm font-medium hover:bg-gray-50 disabled:opacity-50"
                >
                  Previous
                </button>
                <button 
                  onClick={() => fetchStudents(meta.page + 1, searchTerm, selectedJobFairId)} 
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

export default StudentsList;