import React, { useEffect, useState } from 'react';
import { Calendar, CheckCircle, AlertCircle, Plus, Zap, Trash2, Edit2, X, Save } from 'lucide-react';
import api, { getAllJobFairs, deleteJobFair, activateJobFair, updateJobFair } from '../../lib/api';
import toast from 'react-hot-toast';

const JobFairSetup = () => {
  const [loading, setLoading] = useState(false);
  const [listLoading, setListLoading] = useState(false);
  const [jobFairs, setJobFairs] = useState([]);
  const [editingId, setEditingId] = useState(null);
  const [editFormData, setEditFormData] = useState({ semester: '', date: '' });
  const [formData, setFormData] = useState({
    semester: '',
    date: '',
    isActive: true
  });

  const fetchJobFairs = async () => {
    setListLoading(true);
    try {
      const response = await getAllJobFairs();
      const jobFairsList = response.data?.jobFairs || response.data || [];
      setJobFairs(Array.isArray(jobFairsList) ? jobFairsList : []);
    } catch (error) {
      console.error(error);
      toast.error('Unable to load job fairs');
      setJobFairs([]);
    } finally {
      setListLoading(false);
    }
  };

  useEffect(() => {
    fetchJobFairs();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Matches AdminController.cs [HttpPost("jobfairs")]
      await api.post('/admin/jobfairs', {
        semester: formData.semester,
        date: new Date(formData.date).toISOString(), // Ensure ISO format
        isActive: formData.isActive
      });

      toast.success("Job Fair created and activated!");
      // Optional: Reset form or redirect
      setFormData({ semester: '', date: '', isActive: true });
      fetchJobFairs();
      
    } catch (error) {
      console.error(error);
      toast.error(error.response?.data || "Failed to create Job Fair");
    } finally {
      setLoading(false);
    }
  };

  const handleActivate = async (jobFairId) => {
    try {
      await activateJobFair(jobFairId);
      toast.success('Job Fair activated');
      fetchJobFairs();
    } catch (error) {
      console.error(error);
      toast.error(error.response?.data?.Message || 'Failed to activate Job Fair');
    }
  };

  const handleDelete = async (jobFairId) => {
    const confirm = window.confirm('Delete this future Job Fair? This cannot be undone.');
    if (!confirm) return;

    try {
      await deleteJobFair(jobFairId);
      toast.success('Job Fair deleted');
      fetchJobFairs();
    } catch (error) {
      console.error(error);
      toast.error(error.response?.data?.Message || 'Failed to delete Job Fair');
    }
  };

  const handleEditClick = (jf) => {
    const dateValue = jf.date || jf.Date;
    const dateNow = new Date();
    const jobFairDate = new Date(dateValue);
    
    // Check if job fair date has passed or is today
    if (jobFairDate.toDateString() <= dateNow.toDateString()) {
      toast.error('Cannot edit a job fair that has started or already occurred.');
      return;
    }

    const dateString = dateValue ? new Date(dateValue).toISOString().split('T')[0] : '';
    setEditingId(jf.JobFairId || jf.jobFairId);
    setEditFormData({
      semester: jf.Semester || jf.semester || '',
      date: dateString
    });
  };

  const handleEditSave = async (jobFairId) => {
    try {
      setLoading(true);
      const updateData = {};
      if (editFormData.semester.trim()) updateData.semester = editFormData.semester.trim();
      if (editFormData.date) updateData.date = new Date(editFormData.date).toISOString();

      if (Object.keys(updateData).length === 0) {
        toast.error('Please update at least one field');
        return;
      }

      await updateJobFair(jobFairId, updateData);
      toast.success('Job Fair updated successfully');
      setEditingId(null);
      setEditFormData({ semester: '', date: '' });
      fetchJobFairs();
    } catch (error) {
      console.error(error);
      const errorMsg = error.response?.data?.Message || error.response?.data?.message || error.message || 'Failed to update Job Fair';
      toast.error(errorMsg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="h-full flex flex-col overflow-hidden">
      {/* Header Section */}
      <div className="relative overflow-hidden bg-gradient-to-br from-indigo-600 via-indigo-700 to-purple-700 rounded-2xl shadow-xl p-8 text-white">
        <div className="absolute top-0 right-0 -mt-4 -mr-4 w-40 h-40 bg-white opacity-10 rounded-full blur-3xl"></div>
        <div className="absolute bottom-0 left-0 -mb-4 -ml-4 w-32 h-32 bg-purple-300 opacity-20 rounded-full blur-2xl"></div>
        <div className="relative z-10">
          <div className="flex items-center gap-3 mb-3">
            <div className="p-3 bg-white/20 backdrop-blur-sm rounded-xl">
              <Calendar className="text-white" size={32} />
            </div>
            <div>
              <h1 className="text-3xl font-bold">Job Fair Management</h1>
              <p className="text-indigo-100 text-sm mt-1">Organize and manage recruitment events with ease</p>
            </div>
          </div>
          <div className="mt-6 flex gap-4">
            <div className="bg-white/10 backdrop-blur-sm rounded-lg px-4 py-2">
              <div className="text-2xl font-bold">{jobFairs.length}</div>
              <div className="text-xs text-indigo-100">Total Events</div>
            </div>
            <div className="bg-white/10 backdrop-blur-sm rounded-lg px-4 py-2">
              <div className="text-2xl font-bold">{jobFairs.filter(jf => jf.IsActive || jf.isActive).length}</div>
              <div className="text-xs text-indigo-100">Active Events</div>
            </div>
          </div>
        </div>
      </div>

      {/* Create New Job Fair Card */}
      <div className="bg-white rounded-2xl shadow-lg border border-gray-100 overflow-hidden hover:shadow-xl transition-shadow duration-300">
        <div className="bg-gradient-to-r from-indigo-50 to-purple-50 p-6 border-b border-gray-100">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-indigo-600 rounded-lg">
              <Plus className="text-white" size={24} />
            </div>
            <div>
              <h2 className="text-xl font-bold text-gray-900">Create New Job Fair</h2>
              <p className="text-gray-600 text-sm">Set up a new recruitment event for students</p>
            </div>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="p-8 space-y-6">
          
          {/* Semester Name */}
          <div className="group">
            <label className="block text-sm font-semibold text-gray-700 mb-2">Event Title / Semester</label>
            <input 
              type="text" 
              required
              placeholder="e.g., Spring 2026 Career Fair"
              className="w-full px-4 py-3.5 rounded-xl border-2 border-gray-200 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all group-hover:border-gray-300"
              value={formData.semester}
              onChange={(e) => setFormData({...formData, semester: e.target.value})}
            />
          </div>

          {/* Date */}
          <div className="group">
            <label className="block text-sm font-semibold text-gray-700 mb-2">Event Date</label>
            <input 
              type="date" 
              required
              className="w-full px-4 py-3.5 rounded-xl border-2 border-gray-200 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all group-hover:border-gray-300"
              value={formData.date}
              onChange={(e) => setFormData({...formData, date: e.target.value})}
            />
          </div>

          {/* Info Box */}
          <div className="relative bg-gradient-to-br from-blue-50 to-indigo-50 border-l-4 border-blue-500 p-5 rounded-lg">
            <div className="flex gap-3">
              <AlertCircle className="text-blue-600 shrink-0 mt-0.5" size={22} />
              <div className="text-sm">
                <p className="font-semibold text-blue-900 mb-1">🎯 Activation Reminder</p>
                <p className="text-blue-800 leading-relaxed">
                  Creating an active job fair will automatically deactivate previous events. 
                  All new registrations, rooms, and company data will be associated with this event.
                </p>
              </div>
            </div>
          </div>

          {/* Submit Button */}
          <button 
            type="submit" 
            disabled={loading}
            className="w-full group relative flex items-center justify-center py-4 px-6 rounded-xl shadow-lg text-white bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 focus:ring-4 focus:ring-indigo-300 transition-all font-semibold disabled:opacity-70 disabled:cursor-not-allowed overflow-hidden"
          >
            <span className="absolute inset-0 bg-white opacity-0 group-hover:opacity-10 transition-opacity"></span>
            <CheckCircle className="mr-2" size={20} />
            {loading ? 'Creating Event...' : 'Create & Activate Job Fair'}
          </button>

        </form>
      </div>

      {/* Existing Job Fairs List */}
      <div className="bg-white rounded-2xl shadow-lg border border-gray-100 overflow-hidden">
        <div className="bg-gradient-to-r from-gray-50 to-slate-50 p-6 border-b border-gray-100">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-indigo-600 rounded-lg">
                <CheckCircle className="text-white" size={24} />
              </div>
              <div>
                <h2 className="text-xl font-bold text-gray-900">Existing Events</h2>
                <p className="text-gray-600 text-sm">Manage your past and upcoming job fairs</p>
              </div>
            </div>
            {listLoading && (
              <div className="flex items-center gap-2 text-sm text-gray-500">
                <div className="w-4 h-4 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
                Loading...
              </div>
            )}
          </div>
        </div>

        <div className="divide-y divide-gray-100">
          {jobFairs.length === 0 && (
            <div className="p-12 text-center">
              <div className="inline-flex items-center justify-center w-16 h-16 bg-gray-100 rounded-full mb-4">
                <Calendar className="text-gray-400" size={32} />
              </div>
              <p className="text-gray-500 font-medium">No job fairs created yet</p>
              <p className="text-gray-400 text-sm mt-1">Create your first event using the form above</p>
            </div>
          )}

          {jobFairs.map((jf) => {
            const id = jf.JobFairId || jf.jobFairId;
            const isActive = jf.IsActive ?? jf.isActive;
            const dateValue = jf.date || jf.Date;
            const formattedDate = dateValue ? new Date(dateValue).toLocaleDateString('en-US', { 
              weekday: 'long', 
              year: 'numeric', 
              month: 'long', 
              day: 'numeric' 
            }) : '—';
            const isEditing = editingId === id;
            
            const dateNow = new Date();
            const jobFairDate = new Date(dateValue);
            const canEdit = jobFairDate.toDateString() > dateNow.toDateString();
            const isPast = jobFairDate < dateNow;

            return (
              <div key={id} className={`p-6 hover:bg-gray-50 transition-colors ${isActive ? 'bg-indigo-50/30' : ''}`}>
                {isEditing ? (
                  <div className="space-y-4 bg-white p-6 rounded-xl border-2 border-indigo-200">
                    <div>
                      <label className="block text-sm font-semibold text-gray-700 mb-2">Event Title / Semester</label>
                      <input
                        type="text"
                        value={editFormData.semester}
                        onChange={(e) => setEditFormData({ ...editFormData, semester: e.target.value })}
                        className="w-full px-4 py-3 rounded-lg border-2 border-gray-200 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-semibold text-gray-700 mb-2">Event Date</label>
                      <input
                        type="date"
                        value={editFormData.date}
                        onChange={(e) => setEditFormData({ ...editFormData, date: e.target.value })}
                        className="w-full px-4 py-3 rounded-lg border-2 border-gray-200 focus:ring-2 focus:ring-indigo-500 outline-none transition"
                      />
                    </div>
                    <div className="flex gap-3 pt-2">
                      <button
                        onClick={() => handleEditSave(id)}
                        disabled={loading}
                        className="flex-1 flex items-center justify-center gap-2 px-4 py-3 rounded-lg text-sm font-semibold bg-green-600 text-white hover:bg-green-700 disabled:opacity-60 transition"
                      >
                        <Save size={18} /> Save Changes
                      </button>
                      <button
                        onClick={() => setEditingId(null)}
                        className="flex-1 flex items-center justify-center gap-2 px-4 py-3 rounded-lg text-sm font-semibold bg-gray-200 text-gray-700 hover:bg-gray-300 transition"
                      >
                        <X size={18} /> Cancel
                      </button>
                    </div>
                  </div>
                ) : (
                  <>
                    <div className="flex items-start justify-between mb-4">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <h3 className="text-xl font-bold text-gray-900">{jf.Semester || jf.semester || 'Untitled Event'}</h3>
                          {isActive && (
                            <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-bold bg-gradient-to-r from-green-500 to-emerald-500 text-white shadow-sm">
                              <Zap size={12} /> Active
                            </span>
                          )}
                          {isPast && !isActive && (
                            <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-gray-200 text-gray-600">
                              Past Event
                            </span>
                          )}
                        </div>
                        <div className="flex items-center gap-2 text-gray-600">
                          <Calendar size={16} className="text-indigo-600" />
                          <span className="text-sm font-medium">{formattedDate}</span>
                        </div>
                      </div>
                    </div>

                    <div className="flex flex-wrap gap-3">
                      <button
                        onClick={() => handleEditClick(jf)}
                        disabled={!canEdit}
                        className={`inline-flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition-all ${
                          canEdit 
                            ? 'bg-blue-100 text-blue-700 hover:bg-blue-200 hover:shadow-md' 
                            : 'bg-gray-100 text-gray-400 cursor-not-allowed'
                        }`}
                        title={!canEdit ? 'Cannot edit past or ongoing events' : 'Edit event details'}
                      >
                        <Edit2 size={16} /> Edit Details
                      </button>
                      <button
                        onClick={() => handleActivate(id)}
                        disabled={isActive}
                        className="inline-flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-semibold bg-indigo-100 text-indigo-700 hover:bg-indigo-200 hover:shadow-md disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                        title={isActive ? 'Already active' : 'Set as active event'}
                      >
                        <Zap size={16} /> {isActive ? 'Currently Active' : 'Activate'}
                      </button>
                      <button
                        onClick={() => handleDelete(id)}
                        className="inline-flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-semibold bg-red-100 text-red-700 hover:bg-red-200 hover:shadow-md transition-all"
                        title="Delete this event"
                      >
                        <Trash2 size={16} /> Delete
                      </button>
                    </div>
                  </>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

export default JobFairSetup;