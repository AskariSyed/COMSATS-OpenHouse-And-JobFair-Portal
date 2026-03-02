/* eslint-disable no-unused-vars */
import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Search, 
  Building2, 
  MapPin, 
  Mail, 
  Phone,
  Plus, 
  Briefcase, 
  X,
  Globe,
  Loader2,
  Bell, 
  Users // Added
} from 'lucide-react';
import api from '../../lib/api';
import { toast } from 'react-hot-toast';
import { motion, AnimatePresence } from 'framer-motion';
import SendNotificationModal from '../../lib/components/SendNotificationModal'; // Added

// 🔧 CONFIGURATION: Backend Base URL
const BACKEND_URL = "https://localhost:7050"; 

const getLogoUrl = (path) => {
  if (!path) return null;
  if (path.startsWith('http')) return path; 
  return `${BACKEND_URL}${path}`; 
};

// ----------------------------------------------------------------------
// Modal: Add On-Spot Company
// ----------------------------------------------------------------------
const AddCompanyModal = ({ onClose, onSuccess }) => {
  const [formData, setFormData] = useState({ 
    name: '', 
    industry: '',
    focalPersonName: '', 
    email: '',
    focalPersonPhone: '' // Added
  });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await api.post('/admin/companies/onspot', formData);
      toast.success(`${formData.name} added successfully!`);
      onSuccess();
      onClose();
    } catch (error) {
      console.error(error);
      toast.error("Failed to add company. Check required fields.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <motion.div 
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden"
      >
        <div className="px-6 py-4 border-b flex justify-between items-center bg-gray-50">
          <h3 className="font-bold text-gray-800">Add On-Spot Company</h3>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
            <X size={20} />
          </button>
        </div>
        
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Company Name *</label>
            <input 
              type="text" 
              required
              className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-indigo-500 focus:outline-none"
              placeholder="e.g. Tech Solutions Inc."
              value={formData.name}
              onChange={(e) => setFormData({...formData, name: e.target.value})}
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Industry *</label>
            <select 
              className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-indigo-500 focus:outline-none bg-white"
              value={formData.industry}
              onChange={(e) => setFormData({...formData, industry: e.target.value})}
              required
            >
              <option value="">Select Industry...</option>
              <option value="Software Development">Software Development</option>
              <option value="Artificial Intelligence">Artificial Intelligence</option>
              <option value="Engineering">Engineering</option>
              <option value="Telecommunications">Telecommunications</option>
              <option value="Business & Finance">Business & Finance</option>
            </select>
          </div>

          {/* NEW FIELDS */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Focal Person Name *</label>
            <input 
              type="text" 
              required
              className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-indigo-500 focus:outline-none"
              placeholder="e.g. John Doe"
              value={formData.focalPersonName}
              onChange={(e) => setFormData({...formData, focalPersonName: e.target.value})}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Email Address *</label>
              <input 
                type="email" 
                required
                className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                placeholder="contact@company.com"
                value={formData.email}
                onChange={(e) => setFormData({...formData, email: e.target.value})}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Phone Number *</label>
              <input 
                type="tel" 
                required
                className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                placeholder="0300-1234567"
                value={formData.focalPersonPhone}
                onChange={(e) => setFormData({...formData, focalPersonPhone: e.target.value})}
              />
            </div>
          </div>

          <div className="pt-2 flex justify-end gap-3">
            <button 
              type="button" 
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded-lg"
            >
              Cancel
            </button>
            <button 
              type="submit" 
              disabled={loading}
              className="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg disabled:opacity-50"
            >
              {loading ? 'Adding...' : 'Add Company'}
            </button>
          </div>
        </form>
      </motion.div>
    </div>
  );
};

// ----------------------------------------------------------------------
// Modal: Assign Room
// ----------------------------------------------------------------------
const AssignRoomModal = ({ company, onClose, onSuccess }) => {
  const [rooms, setRooms] = useState([]);
  const [selectedRoomId, setSelectedRoomId] = useState('');
  const [isTentative, setIsTentative] = useState(false); // New State
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const fetchRooms = async () => {
      try {
        const res = await api.get('/admin/rooms?status=0'); // Fetch vacant rooms
        setRooms(res.data.filter(r => r.status === 0)); 
      } catch (error) {
        toast.error("Failed to load rooms");
      }
    };
    fetchRooms();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!selectedRoomId) return;
    
    setLoading(true);
    try {
      if (isTentative) {
        await api.put(`/admin/rooms/tentatively-assign?companyId=${company.companyId}&roomId=${selectedRoomId}`);
        toast.success(`Room tentatively assigned to ${company.name}`);
      } else {
        await api.put(`/admin/rooms/assign-company?companyId=${company.companyId}&roomId=${selectedRoomId}`);
        toast.success(`Room assigned to ${company.name}`);
      }
      onSuccess();
      onClose();
    } catch (error) {
      toast.error("Failed to assign room");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <motion.div 
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden"
      >
        <div className="px-6 py-4 border-b flex justify-between items-center bg-gray-50">
          <h3 className="font-bold text-gray-800">Assign Room to {company.name}</h3>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
            <X size={20} />
          </button>
        </div>
        
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Select Room</label>
            <select 
              className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-indigo-500 focus:outline-none bg-white"
              value={selectedRoomId}
              onChange={(e) => setSelectedRoomId(e.target.value)}
              required
            >
              <option value="">Select a vacant room...</option>
              {rooms.map(room => (
                <option key={room.roomId} value={room.roomId}>
                  {room.roomName} (Capacity: {room.capacity})
                </option>
              ))}
            </select>
          </div>

          <div className="flex items-center gap-2">
            <input 
              type="checkbox" 
              id="tentative" 
              className="w-4 h-4 text-indigo-600 rounded border-gray-300 focus:ring-indigo-500"
              checked={isTentative}
              onChange={(e) => setIsTentative(e.target.checked)}
            />
            <label htmlFor="tentative" className="text-sm text-gray-700 select-none">
              Tentative Assignment (Pending Confirmation)
            </label>
          </div>

          <div className="pt-2 flex justify-end gap-3">
            <button 
              type="button" 
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded-lg"
            >
              Cancel
            </button>
            <button 
              type="submit" 
              disabled={loading || !selectedRoomId}
              className={`px-4 py-2 text-sm font-medium text-white rounded-lg disabled:opacity-50 ${isTentative ? 'bg-amber-500 hover:bg-amber-600' : 'bg-indigo-600 hover:bg-indigo-700'}`}
            >
              {loading ? 'Assigning...' : isTentative ? 'Assign Tentatively' : 'Assign Room'}
            </button>
          </div>
        </form>
      </motion.div>
    </div>
  );
};

// ----------------------------------------------------------------------
// Main Page Component
// ----------------------------------------------------------------------
const CompaniesList = () => {
  const navigate = useNavigate(); // Hook for navigation
  const [companies, setCompanies] = useState([]); 
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [assignRoomModal, setAssignRoomModal] = useState({ open: false, company: null });
  const [notifyModal, setNotifyModal] = useState({ open: false, company: null }); // New State
  const [meta, setMeta] = useState({ page: 1, totalPages: 1, totalCount: 0 });

  const fetchCompanies = async (page = 1) => {
    setLoading(true);
    try {
      // Backend returns { companies: [...], totalCount: ... }
      const res = await api.get(`/admin/companies?page=${page}&pageSize=50`); 
      
      setCompanies(res.data.companies || []); 
      setMeta({
        page: res.data.page,
        totalPages: res.data.totalPages,
        totalCount: res.data.totalCount
      });

    } catch (error) {
      console.error(error);
      toast.error("Failed to fetch companies.");
      setCompanies([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCompanies(1);
  }, []);

  // Filter Logic
  const filteredCompanies = companies.filter(c => 
    c.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    c.industry?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6 animate-fade-in pb-10">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Participating Companies</h1>
          <p className="text-gray-500 text-sm">Manage company registrations and room allocations.</p>
        </div>
        <div className="flex gap-2">
          <button 
            onClick={() => setNotifyModal({ open: true, company: null })}
            className="flex items-center gap-2 px-4 py-2 bg-amber-500 text-white rounded-lg text-sm font-medium hover:bg-amber-600 shadow-sm transition hover:-translate-y-0.5"
          >
            <Bell size={18} />
            Notify All
          </button>
          <button 
            onClick={() => setIsModalOpen(true)}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 shadow-sm transition hover:-translate-y-0.5"
          >
            <Plus size={18} />
            Add On-Spot Company
          </button>
        </div>
      </div>

      {/* Search & Stats Bar */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Search */}
        <div className="lg:col-span-2 bg-white p-1.5 rounded-xl border shadow-sm flex items-center">
          <Search className="ml-3 text-gray-400" size={20} />
          <input 
            type="text" 
            placeholder="Search by company name or industry..." 
            className="w-full px-4 py-2 outline-none text-sm text-gray-700"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        
        {/* Quick Stat */}
        <div className="bg-indigo-50 rounded-xl border border-indigo-100 p-4 flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold text-indigo-600 uppercase">Total Registered</p>
            <p className="text-2xl font-bold text-indigo-900">{meta.totalCount}</p>
          </div>
          <div className="p-2 bg-white rounded-lg text-indigo-600">
            <Building2 size={24} />
          </div>
        </div>
      </div>

      {/* Companies Table */}
      <div className="bg-white rounded-xl border shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Company</th>
                <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Industry</th>
                <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Company Contact</th>
                <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Focal Person</th>
                <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Room Status</th>
                <th className="px-6 py-4 text-right text-xs font-bold text-gray-700 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {loading ? (
                [...Array(6)].map((_, i) => (
                  <tr key={i} className="animate-pulse bg-white hover:bg-gray-50">
                    <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-40"></div></td>
                    <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-32"></div></td>
                    <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-48"></div></td>
                    <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-48"></div></td>
                    <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-24"></div></td>
                    <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-20 ml-auto"></div></td>
                  </tr>
                ))
              ) : filteredCompanies.length > 0 ? (
                <AnimatePresence>
                  {filteredCompanies.map((company) => (
                    <motion.tr
                      layout
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      exit={{ opacity: 0 }}
                      key={company.companyId}
                      onClick={() => navigate(`/admin/companies/${company.companyId}`)}
                      className="bg-white hover:bg-indigo-50 transition-colors cursor-pointer group"
                    >
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="p-2 bg-gray-50 rounded-lg border border-gray-100 group-hover:bg-indigo-100 transition-colors">
                            {company.logoUrl ? (
                              <img src={getLogoUrl(company.logoUrl)} alt="Logo" className="w-6 h-6 object-contain" />
                            ) : (
                              <Building2 className="text-gray-400 group-hover:text-indigo-600" size={20} />
                            )}
                          </div>
                          <div className="overflow-hidden">
                            <p className="font-semibold text-gray-900 group-hover:text-indigo-600 transition-colors line-clamp-1" title={company.name}>
                              {company.name}
                              {typeof company.repsCount === 'number' && (
                                <span className="ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-semibold bg-gray-100 text-gray-700">
                                  Reps: {company.repsCount}
                                </span>
                              )}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2">
                          <Briefcase size={14} className="text-gray-400" />
                          <span className="text-sm text-gray-600">{company.industry || 'General'}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex flex-col gap-1">
                          {company.userEmail && (
                            <div className="flex items-center text-sm text-gray-600 gap-2">
                              <Mail size={14} className="text-gray-400 flex-shrink-0" />
                              <span className="truncate" title={company.userEmail}>{company.userEmail}</span>
                            </div>
                          )}
                          {company.userPhone && (
                            <div className="flex items-center text-sm text-gray-600 gap-2">
                              <Phone size={14} className="text-gray-400 flex-shrink-0" />
                              <span className="truncate">{company.userPhone}</span>
                            </div>
                          )}
                          {company.website && (
                            <div className="flex items-center text-sm text-gray-600 gap-2">
                              <Globe size={14} className="text-gray-400 flex-shrink-0" />
                              <span className="truncate">{company.website.replace(/^https?:\/\//, '')}</span>
                            </div>
                          )}
                          {!company.userEmail && !company.userPhone && !company.website && (
                            <span className="text-sm text-gray-400">No contact info</span>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex flex-col gap-1.5">
                          {company.focalPersonName && (
                            <div className="flex items-start gap-2">
                              <Users size={14} className="text-gray-400 mt-0.5 flex-shrink-0" />
                              <div className="overflow-hidden">
                                <p className="text-sm font-medium text-gray-900 truncate" title={company.focalPersonName}>
                                  {company.focalPersonName}
                                </p>
                              </div>
                            </div>
                          )}
                          {company.focalPersonEmail && (
                            <div className="flex items-center text-xs text-gray-600 gap-2 ml-5">
                              <Mail size={12} className="text-gray-400 flex-shrink-0" />
                              <span className="truncate" title={company.focalPersonEmail}>{company.focalPersonEmail}</span>
                            </div>
                          )}
                          {company.focalPersonPhone && (
                            <div className="flex items-center text-xs text-gray-600 gap-2 ml-5">
                              <Phone size={12} className="text-gray-400 flex-shrink-0" />
                              <span className="truncate">{company.focalPersonPhone}</span>
                            </div>
                          )}
                          {!company.focalPersonName && !company.focalPersonEmail && !company.focalPersonPhone && (
                            <span className="text-sm text-gray-400">No focal person info</span>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        {company.roomName ? (
                          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-green-100 text-green-700">
                            <MapPin size={12} /> {company.roomName}
                          </span>
                        ) : (
                          <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-yellow-100 text-yellow-700">
                            Not Allocated
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center justify-end gap-2">
                          {!company.roomName && (
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                setAssignRoomModal({ open: true, company });
                              }}
                              className="px-3 py-1.5 text-xs font-medium text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-lg transition-colors"
                              title="Assign Room"
                            >
                              Assign
                            </button>
                          )}
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              setNotifyModal({ open: true, company });
                            }}
                            className="p-2 text-gray-400 hover:text-amber-600 hover:bg-amber-50 rounded-lg transition-colors"
                            title="Send Notification"
                          >
                            <Bell size={16} />
                          </button>
                        </div>
                      </td>
                    </motion.tr>
                  ))}
                </AnimatePresence>
              ) : (
                <tr>
                  <td colSpan="5" className="px-6 py-16 text-center">
                    <Building2 className="w-12 h-12 text-gray-300 mx-auto mb-3" />
                    <p className="text-gray-500 font-medium">No companies found.</p>
                    <p className="text-sm text-gray-400">Try adjusting your search or add a new company.</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Pagination Footer */}
      {!loading && meta.totalPages > 1 && (
        <div className="flex justify-center gap-2 mt-8">
           <button 
             disabled={meta.page <= 1}
             onClick={() => fetchCompanies(meta.page - 1)}
             className="px-4 py-2 border rounded-lg bg-white text-sm font-medium hover:bg-gray-50 disabled:opacity-50"
           >
             Previous
           </button>
           <span className="px-4 py-2 text-sm text-gray-600 flex items-center">
             Page {meta.page} of {meta.totalPages}
           </span>
           <button 
             disabled={meta.page >= meta.totalPages}
             onClick={() => fetchCompanies(meta.page + 1)}
             className="px-4 py-2 border rounded-lg bg-white text-sm font-medium hover:bg-gray-50 disabled:opacity-50"
           >
             Next
           </button>
        </div>
      )}

      {/* Add Modal */}
      {isModalOpen && (
        <AddCompanyModal 
          onClose={() => setIsModalOpen(false)} 
          onSuccess={() => fetchCompanies(1)} 
        />
      )}

      {/* Assign Room Modal */}
      {assignRoomModal.open && (
        <AssignRoomModal 
          company={assignRoomModal.company}
          onClose={() => setAssignRoomModal({ open: false, company: null })}
          onSuccess={() => fetchCompanies(meta.page)}
        />
      )}

      {/* Notify Modal */}
      <SendNotificationModal 
        isOpen={notifyModal.open}
        onClose={() => setNotifyModal({ open: false, company: null })}
        recipientId={notifyModal.company?.companyId}
        recipientName={notifyModal.company?.name}
        type="company"
      />
    </div>
  );
};

export default CompaniesList;