/* eslint-disable no-unused-vars */
import React, { useEffect, useState } from 'react';
import { 
  Bell, Plus, Trash2, Users, Building2, Globe, X, Loader2, Eye, EyeOff, Edit2
} from 'lucide-react';
import api from '../../lib/api';
import { toast } from 'react-hot-toast';

// --- Helper: Audience Badge ---
const AudienceBadge = ({ audience }) => {
  // API returns strings: "All", "Student", "Company"
  const config = {
    Student: { color: 'bg-blue-100 text-blue-700', icon: Users },
    Company: { color: 'bg-purple-100 text-purple-700', icon: Building2 },
    All:     { color: 'bg-emerald-100 text-emerald-700', icon: Globe },
  };
  
  // Fallback to 'All' if something goes wrong
  const { color, icon: Icon } = config[audience] || config.All;

  return (
    <span className={`flex items-center gap-1 px-2 py-1 rounded text-xs font-bold ${color}`}>
      <Icon size={12} /> {audience}
    </span>
  );
};

const NoticeBoard = () => {
  const [notices, setNotices] = useState([]);
  const [loading, setLoading] = useState(true);
  
  // Modal & Form State
  const [showModal, setShowModal] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [editingId, setEditingId] = useState(null);
  
  // ✅ FIX 1: Default to 0 (All) based on your Enum
  const [formData, setFormData] = useState({
    title: '',
    content: '',
    audience: 0 
  });

  // --- Fetch Notices ---
  const fetchNotices = async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/notices');
      setNotices(res.data);
    } catch (error) {
      toast.error("Failed to load notices");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNotices();
  }, []);

  // --- Open Modal (Create vs Edit) ---
  const openCreateModal = () => {
    setEditingId(null);
    setFormData({ title: '', content: '', audience: 0 }); // Reset to 'All'
    setShowModal(true);
  };

  const openEditModal = (notice) => {
    setEditingId(notice.noticeId);
    
    // ✅ FIX 2: Map String response back to Int for the form
    let audienceInt = 0; // Default 'All'
    if (notice.audience === 'Student') audienceInt = 1;
    if (notice.audience === 'Company') audienceInt = 2;

    setFormData({
      title: notice.title,
      content: notice.content,
      audience: audienceInt
    });
    setShowModal(true);
  };

  // --- Submit (Create or Update) ---
  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const payload = { ...formData, audience: parseInt(formData.audience) };

      if (editingId) {
        await api.put(`/admin/notices/${editingId}`, payload);
        toast.success("Notice updated successfully!");
      } else {
        await api.post('/admin/notices', payload);
        toast.success("Notice posted successfully!");
      }

      setShowModal(false);
      fetchNotices();
    } catch (error) {
      console.error(error);
      toast.error(editingId ? "Failed to update notice" : "Failed to post notice");
    } finally {
      setSubmitting(false);
    }
  };

  // --- Other Actions ---
  const handleToggleVisibility = async (id) => {
    try {
      // Note: Using Uppercase 'Notice' to match your Controller route
      await api.put(`/admin/Notice/${id}/toggle-visibility`);
      setNotices(prev => prev.map(n => 
        n.noticeId === id ? { ...n, isHidden: !n.isHidden } : n
      ));
      toast.success("Visibility updated");
    } catch (error) {
      toast.error("Failed to update visibility");
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Are you sure you want to delete this notice?")) return;
    try {
      await api.delete(`/admin/notice/${id}`);
      setNotices(prev => prev.filter(n => n.noticeId !== id));
      toast.success("Notice deleted");
    } catch (error) {
      toast.error("Failed to delete notice");
    }
  };

  return (
    <div className="max-w-5xl mx-auto pb-10 animate-fade-in space-y-6">
      
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Notice Board</h1>
          <p className="text-gray-500 text-sm">Manage announcements for the Job Fair.</p>
        </div>
        <button 
          onClick={openCreateModal}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition shadow-sm font-medium"
        >
          <Plus size={18} /> Post Notice
        </button>
      </div>

      {/* List */}
      {loading ? (
        <div className="flex justify-center py-20">
          <Loader2 size={40} className="animate-spin text-indigo-600" />
        </div>
      ) : (
        <div className="grid gap-4">
          {notices.length > 0 ? notices.map((notice) => (
            <div 
              key={notice.noticeId} 
              className={`p-6 rounded-xl border transition group relative ${
                notice.isHidden 
                  ? 'bg-gray-50 border-gray-200 opacity-75' 
                  : 'bg-white border-gray-200 shadow-sm hover:shadow-md'
              }`}
            >
              <div className="flex justify-between items-start mb-2">
                <div className="flex items-center gap-3">
                  <h3 className="text-lg font-bold text-gray-900 flex items-center gap-2">
                    {notice.title}
                    {notice.isHidden && (
                      <span className="px-2 py-0.5 bg-gray-200 text-gray-600 text-[10px] rounded uppercase font-bold border border-gray-300">
                        Hidden
                      </span>
                    )}
                  </h3>
                  <AudienceBadge audience={notice.audience} />
                </div>
                <span className="text-xs text-gray-400">
                  {new Date(notice.createdAt).toLocaleDateString()}
                </span>
              </div>
              
              <p className="text-gray-600 text-sm leading-relaxed whitespace-pre-wrap mb-2">
                {notice.content}
              </p>

              {/* Action Buttons */}
              <div className="flex gap-2 justify-end opacity-0 group-hover:opacity-100 transition-opacity">
                <button 
                  onClick={() => openEditModal(notice)}
                  className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-full transition"
                  title="Edit Notice"
                >
                  <Edit2 size={18} />
                </button>

                <button 
                  onClick={() => handleToggleVisibility(notice.noticeId)}
                  className="p-2 text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-full transition"
                  title={notice.isHidden ? "Make Visible" : "Hide Notice"}
                >
                  {notice.isHidden ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
                
                <button 
                  onClick={() => handleDelete(notice.noticeId)}
                  className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-full transition"
                  title="Delete"
                >
                  <Trash2 size={18} />
                </button>
              </div>
            </div>
          )) : (
            <div className="text-center py-16 bg-gray-50 rounded-xl border border-dashed border-gray-300">
              <Bell className="w-12 h-12 text-gray-300 mx-auto mb-3" />
              <p className="text-gray-500 font-medium">No notices posted yet.</p>
            </div>
          )}
        </div>
      )}

      {/* Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-100 bg-gray-50 flex justify-between items-center">
              <h3 className="font-bold text-gray-800">
                {editingId ? 'Edit Notice' : 'Create New Notice'}
              </h3>
              <button onClick={() => setShowModal(false)} className="text-gray-400 hover:text-gray-600">
                <X size={20} />
              </button>
            </div>
            
            <form onSubmit={handleSubmit} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Target Audience</label>
                <div className="grid grid-cols-3 gap-2">
                  {/* ✅ FIX 3: Updated Values to match 0=All, 1=Student, 2=Company */}
                  {[
                    { val: 0, label: 'Everyone', icon: Globe },
                    { val: 1, label: 'Students', icon: Users },
                    { val: 2, label: 'Companies', icon: Building2 },
                  ].map((opt) => (
                    <button
                      key={opt.val}
                      type="button"
                      onClick={() => setFormData({...formData, audience: opt.val})}
                      className={`flex flex-col items-center justify-center p-3 rounded-lg border transition ${
                        formData.audience === opt.val 
                          ? 'border-indigo-600 bg-indigo-50 text-indigo-700' 
                          : 'border-gray-200 hover:bg-gray-50 text-gray-600'
                      }`}
                    >
                      <opt.icon size={20} className="mb-1" />
                      <span className="text-xs font-bold">{opt.label}</span>
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Subject / Title</label>
                <input 
                  type="text" required
                  className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-indigo-500 outline-none"
                  placeholder="e.g. Lunch Break Announcement"
                  value={formData.title}
                  onChange={e => setFormData({...formData, title: e.target.value})}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Message Content</label>
                <textarea 
                  required rows="4"
                  className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-indigo-500 outline-none resize-none"
                  placeholder="Write your announcement here..."
                  value={formData.content}
                  onChange={e => setFormData({...formData, content: e.target.value})}
                />
              </div>

              <div className="flex justify-end gap-2 pt-2">
                <button 
                  type="button" 
                  onClick={() => setShowModal(false)}
                  className="px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded-lg"
                >
                  Cancel
                </button>
                <button 
                  type="submit" 
                  disabled={submitting}
                  className="flex items-center gap-2 px-6 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg disabled:opacity-50"
                >
                  {submitting && <Loader2 size={16} className="animate-spin" />}
                  {editingId ? 'Update Notice' : 'Post Notice'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
};

export default NoticeBoard;