/* eslint-disable no-unused-vars */
import React, { useEffect, useState } from 'react';
import { Calendar, CheckCircle, AlertCircle, Plus, Zap, Trash2, Edit2, X, Save, BarChart3 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import api, { getAllJobFairs, deleteJobFair, activateJobFair, updateJobFair } from '../../lib/api';
import toast from 'react-hot-toast';

const JobFairSetup = () => {
  const navigate = useNavigate();
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
      await api.post('/admin/jobfairs', {
        semester: formData.semester,
        date: new Date(formData.date).toISOString(),
        isActive: formData.isActive
      });

      toast.success("Job Fair created!");
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
      toast.error(error.response?.data?.Message || 'Failed to activate');
    }
  };

  const handleDelete = async (jobFairId) => {
    if (!window.confirm('Delete this Job Fair?')) return;

    try {
      await deleteJobFair(jobFairId);
      toast.success('Deleted');
      fetchJobFairs();
    } catch (error) {
      toast.error('Failed to delete');
    }
  };

  const handleEditClick = (jf) => {
    const dateValue = jf.date || jf.Date;
    const jobFairDate = new Date(dateValue);
    
    if (jobFairDate <= new Date()) {
      toast.error('Cannot edit past events');
      return;
    }

    setEditingId(jf.JobFairId || jf.jobFairId);
    setEditFormData({
      semester: jf.Semester || jf.semester || '',
      date: dateValue ? new Date(dateValue).toISOString().split('T')[0] : ''
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
      toast.success('Updated');
      setEditingId(null);
      fetchJobFairs();
    } catch (error) {
      toast.error('Failed to update');
    } finally {
      setLoading(false);
    }
  };

  const activeCount = jobFairs.filter(jf => jf.IsActive || jf.isActive).length;

  const handleViewAnalytics = (jobFairId) => {
    navigate('/admin/analytics', { state: { jobFairId } });
  };

  return (
    <div className="h-full flex flex-col overflow-hidden bg-gray-50">
      {/* Header Section */}
      <div className="bg-white border-b border-gray-200 px-6 py-5">
        <div className="flex items-center justify-between">
          <div>
            <div className="flex items-center gap-3 mb-2">
              <div className="p-2 bg-indigo-100 rounded-lg">
                <Calendar className="text-indigo-600" size={24} />
              </div>
              <h1 className="text-2xl font-bold text-gray-900">Job Fair Management</h1>
            </div>
            <p className="text-sm text-gray-500">Create and manage job fair events</p>
          </div>
          <div className="flex gap-4">
            <div className="text-center p-3 bg-gray-50 rounded-lg">
              <p className="text-2xl font-bold text-gray-900">{jobFairs.length}</p>
              <p className="text-xs text-gray-500 mt-1">Total Events</p>
            </div>
            <div className="text-center p-3 bg-green-50 rounded-lg">
              <p className="text-2xl font-bold text-green-600">{activeCount}</p>
              <p className="text-xs text-gray-500 mt-1">Active</p>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 overflow-hidden flex gap-6 p-6">
        {/* Create New Event Section */}
        <div className="w-96 bg-white rounded-xl shadow-sm border border-gray-200 flex flex-col overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-100 bg-gray-50 flex items-center gap-3">
            <Plus className="text-indigo-600" size={20} />
            <div>
              <h2 className="font-semibold text-gray-900">Create New Event</h2>
              <p className="text-xs text-gray-500 mt-0.5">Add a new job fair event</p>
            </div>
          </div>

          <form onSubmit={handleSubmit} className="p-6 flex flex-col gap-4 flex-1">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Event Title</label>
              <input 
                type="text" 
                required
                placeholder="e.g., Spring 2026 Career Fair"
                className="w-full px-3 py-2.5 text-sm rounded-lg border border-gray-300 focus:ring-2 focus:ring-indigo-500 focus:border-transparent outline-none"
                value={formData.semester}
                onChange={(e) => setFormData({...formData, semester: e.target.value})}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Event Date</label>
              <input 
                type="date" 
                required
                className="w-full px-3 py-2.5 text-sm rounded-lg border border-gray-300 focus:ring-2 focus:ring-indigo-500 focus:border-transparent outline-none"
                value={formData.date}
                onChange={(e) => setFormData({...formData, date: e.target.value})}
              />
            </div>

            <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
              <div className="flex gap-2">
                <AlertCircle className="text-blue-600 shrink-0" size={16} />
                <p className="text-xs text-blue-800">
                  Creating an active event will automatically deactivate the previous active event.
                </p>
              </div>
            </div>

            <button 
              type="submit" 
              disabled={loading}
              className="mt-auto w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-lg text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 transition disabled:opacity-70 disabled:cursor-not-allowed"
            >
              <CheckCircle size={18} />
              {loading ? 'Creating...' : 'Create Event'}
            </button>
          </form>
        </div>

        {/* Events List Section */}
        <div className="flex-1 bg-white rounded-xl shadow-sm border border-gray-200 flex flex-col overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-100 bg-gray-50 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <CheckCircle className="text-indigo-600" size={20} />
              <div>
                <h2 className="font-semibold text-gray-900">Existing Events</h2>
                <p className="text-xs text-gray-500 mt-0.5">Click an event to view analytics</p>
              </div>
            </div>
            {listLoading && (
              <div className="w-4 h-4 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
            )}
          </div>

          <div className="flex-1 overflow-y-auto">
            {jobFairs.length === 0 ? (
              <div className="h-full flex flex-col items-center justify-center">
                <Calendar className="text-gray-300 mb-3" size={40} />
                <p className="text-gray-500 font-medium">No events yet</p>
                <p className="text-sm text-gray-400 mt-1">Create your first job fair event</p>
              </div>
            ) : (
              <div className="divide-y divide-gray-100">
                {jobFairs.map((jf) => {
                  const id = jf.JobFairId || jf.jobFairId;
                  const isActive = jf.IsActive ?? jf.isActive;
                  const dateValue = jf.date || jf.Date;
                  const formattedDate = dateValue ? new Date(dateValue).toLocaleDateString('en-US', { 
                    weekday: 'short', 
                    year: 'numeric', 
                    month: 'short', 
                    day: 'numeric' 
                  }) : '—';
                  const isEditing = editingId === id;
                  const canEdit = new Date(dateValue) > new Date();
                  const isPast = new Date(dateValue) < new Date();

                  return (
                    <div key={id} className={`p-4 hover:bg-gray-50 transition ${isActive ? 'bg-green-50' : ''}`}>
                      {isEditing ? (
                        <div className="space-y-3">
                          <input
                            type="text"
                            value={editFormData.semester}
                            onChange={(e) => setEditFormData({...editFormData, semester: e.target.value})}
                            className="w-full px-3 py-2 text-sm rounded-lg border border-gray-300 focus:ring-2 focus:ring-indigo-500 outline-none"
                            placeholder="Event Title"
                          />
                          <input
                            type="date"
                            value={editFormData.date}
                            onChange={(e) => setEditFormData({...editFormData, date: e.target.value})}
                            className="w-full px-3 py-2 text-sm rounded-lg border border-gray-300 focus:ring-2 focus:ring-indigo-500 outline-none"
                          />
                          <div className="flex gap-2">
                            <button
                              onClick={() => handleEditSave(id)}
                              disabled={loading}
                              className="flex-1 flex items-center justify-center gap-2 px-3 py-2 rounded-lg text-sm font-medium bg-green-600 text-white hover:bg-green-700"
                            >
                              <Save size={16} /> Save
                            </button>
                            <button
                              onClick={() => setEditingId(null)}
                              className="flex-1 flex items-center justify-center gap-2 px-3 py-2 rounded-lg text-sm font-medium bg-gray-200 text-gray-700 hover:bg-gray-300"
                            >
                              <X size={16} /> Cancel
                            </button>
                          </div>
                        </div>
                      ) : (
                        <>
                          <div className="flex items-start justify-between mb-3">
                            <div className="flex-1">
                              <div className="flex items-center gap-2 mb-1">
                                <h3 className="text-base font-semibold text-gray-900">{jf.Semester || jf.semester || 'Untitled'}</h3>
                                {isActive && (
                                  <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-green-600 text-white">
                                    <Zap size={12} /> Active
                                  </span>
                                )}
                                {isPast && !isActive && (
                                  <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-gray-200 text-gray-600">Past Event</span>
                                )}
                              </div>
                              <div className="flex items-center gap-2 text-sm text-gray-500">
                                <Calendar size={14} />
                                <span>{formattedDate}</span>
                              </div>
                            </div>
                          </div>

                          <div className="flex gap-2">
                            <button
                              onClick={() => handleViewAnalytics(id)}
                              className="flex-1 flex items-center justify-center gap-2 px-3 py-2 rounded-lg text-sm font-medium bg-indigo-100 text-indigo-700 hover:bg-indigo-200 transition"
                            >
                              <BarChart3 size={16} /> Analytics
                            </button>
                            <button
                              onClick={() => handleEditClick(jf)}
                              disabled={!canEdit}
                              className={`flex items-center justify-center gap-1 px-3 py-2 rounded-lg text-sm font-medium transition ${
                                canEdit ? 'bg-blue-100 text-blue-700 hover:bg-blue-200' : 'bg-gray-100 text-gray-400 cursor-not-allowed'
                              }`}
                            >
                              <Edit2 size={16} />
                            </button>
                            <button
                              onClick={() => handleActivate(id)}
                              disabled={isActive}
                              className="flex items-center justify-center gap-1 px-3 py-2 rounded-lg text-sm font-medium bg-yellow-100 text-yellow-700 hover:bg-yellow-200 disabled:opacity-50 disabled:cursor-not-allowed transition"
                            >
                              <Zap size={16} />
                            </button>
                            <button
                              onClick={() => handleDelete(id)}
                              className="flex items-center justify-center gap-1 px-3 py-2 rounded-lg text-sm font-medium bg-red-100 text-red-700 hover:bg-red-200 transition"
                            >
                              <Trash2 size={16} />
                            </button>
                          </div>
                        </>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default JobFairSetup;
