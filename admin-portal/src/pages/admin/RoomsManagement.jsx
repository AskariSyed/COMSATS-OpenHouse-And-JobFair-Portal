/* eslint-disable no-unused-vars */
import React, { useEffect, useState, useMemo } from 'react';
import { 
  Users, Upload, Download, Plus, Trash2, 
  Search, ArrowUpDown, RotateCcw, FileText,
  CheckCircle, AlertCircle, LayoutGrid
} from 'lucide-react';
import api from '../../lib/api';
import { toast } from 'react-hot-toast';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { useNavigate } from 'react-router-dom';


// ----------------------------------------------------------------------
// Helper: Stats Card
// ----------------------------------------------------------------------
const StatsCard = ({ title, value, icon: Icon, color, onClick }) => (
  <div 
    onClick={onClick}
    className={`bg-white p-6 rounded-xl border border-gray-100 shadow-sm flex items-center gap-4 transition-transform hover:scale-[1.02] ${onClick ? 'cursor-pointer hover:shadow-md' : ''}`}
  >
    <div className={`p-3 rounded-full ${color} bg-opacity-10 text-${color.split('-')[1]}-600`}>
      <Icon size={24} />
    </div>
    <div>
      <p className="text-sm text-gray-500 font-medium">{title}</p>
      <h3 className="text-2xl font-bold text-gray-800">{value}</h3>
    </div>
  </div>
);

// ----------------------------------------------------------------------
// Helper: Status Badge (Updated for C# Enum)
// ----------------------------------------------------------------------
const RoomStatusBadge = ({ status }) => {
  // C# Enum: 0=Vacant, 1=TentativelyAlloted, 2=Alloted
  const styles = {
    0: 'bg-emerald-100 text-emerald-700 border-emerald-200', // Vacant
    1: 'bg-amber-100 text-amber-700 border-amber-200',      // Tentative
    2: 'bg-indigo-100 text-indigo-700 border-indigo-200',   // Alloted
  };
  
  const labels = { 
    0: 'Vacant', 
    1: 'Tentative', 
    2: 'Allocated' 
  };

  return (
    <span className={`px-2.5 py-0.5 rounded-full text-xs font-bold border ${styles[status] || styles[0]}`}>
      {labels[status] || 'Unknown'}
    </span>
  );
};

// ----------------------------------------------------------------------
// Helper: Add Room Modal
// ----------------------------------------------------------------------
const AddRoomModal = ({ onClose, onSuccess }) => {
  const [formData, setFormData] = useState({ roomName: '', capacity: 30 });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      await api.post('/admin/rooms', formData);
      toast.success('Room added successfully');
      onSuccess();
      onClose();
    } catch (error) {
      toast.error("Failed to add room");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 animate-fade-in">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-sm overflow-hidden">
        <div className="p-5 border-b bg-gray-50">
          <h3 className="font-bold text-gray-800">Add New Room</h3>
        </div>
        <form onSubmit={handleSubmit} className="p-5 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Room Name</label>
            <input type="text" required className="w-full border rounded-lg px-3 py-2 focus:ring-2 focus:ring-indigo-500 outline-none" placeholder="e.g. C-14" value={formData.roomName} onChange={e => setFormData({...formData, roomName: e.target.value})} />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Capacity</label>
            <input type="number" required min="1" className="w-full border rounded-lg px-3 py-2 focus:ring-2 focus:ring-indigo-500 outline-none" value={formData.capacity} onChange={e => setFormData({...formData, capacity: parseInt(e.target.value)})} />
          </div>
          <div className="flex justify-end gap-2 pt-2">
            <button type="button" onClick={onClose} className="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg">Cancel</button>
            <button type="submit" disabled={loading} className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700">{loading ? 'Saving...' : 'Save Room'}</button>
          </div>
        </form>
      </div>
    </div>
  );
};

// ----------------------------------------------------------------------
// Main Page Component
// ----------------------------------------------------------------------
const RoomsManagement = () => {
  const navigate = useNavigate();
  const [rooms, setRooms] = useState([]);
  const [companies, setCompanies] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [allocatingRoomId, setAllocatingRoomId] = useState(null);

  const [filters, setFilters] = useState({
    minCapacity: '',
    maxCapacity: '',
    status: 'all', 
    search: ''
  });
  const [sortConfig, setSortConfig] = useState({ key: 'name', direction: 'asc' });

  const fetchData = async () => {
    setLoading(true);
    try {
      const [roomsRes, companiesRes] = await Promise.all([
        api.get('/admin/rooms'),
        api.get('/admin/companies?pageSize=1000') // Fetch all companies for dropdown
      ]);
      setRooms(roomsRes.data);
      
      // Handle paginated response for companies
      const companiesData = Array.isArray(companiesRes.data) 
        ? companiesRes.data 
        : (companiesRes.data.companies || companiesRes.data.participations || []);
        
      setCompanies(companiesData);
    } catch (error) {
      console.error(error);
      toast.error("Failed to load data");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  // 2. Process Rooms (Filter + Sort)
  const processedRooms = useMemo(() => {
    let result = [...rooms];

    if (filters.search) {
      const term = filters.search.toLowerCase();
      result = result.filter(r => r.roomName.toLowerCase().includes(term));
    }
    if (filters.minCapacity) result = result.filter(r => r.capacity >= parseInt(filters.minCapacity));
    if (filters.maxCapacity) result = result.filter(r => r.capacity <= parseInt(filters.maxCapacity));
    
    // ✅ UPDATED FILTER LOGIC
    if (filters.status !== 'all') {
      const statusMap = { 
        'vacant': 0, 
        'tentative': 1, 
        'allocated': 2 
      };
      result = result.filter(r => r.status === statusMap[filters.status]);
    }

    result.sort((a, b) => {
      let comparison = 0;
      if (sortConfig.key === 'name') {
        comparison = a.roomName.localeCompare(b.roomName, undefined, { numeric: true, sensitivity: 'base' });
      } else if (sortConfig.key === 'capacity') {
        comparison = a.capacity - b.capacity;
      } else if (sortConfig.key === 'status') {
        comparison = a.status - b.status;
      }
      return sortConfig.direction === 'asc' ? comparison : -comparison;
    });

    return result;
  }, [rooms, filters, sortConfig]);

  // Calculate Stats
  const stats = useMemo(() => {
    return {
      total: rooms.length,
      vacant: rooms.filter(r => r.status === 0).length,
      tentative: rooms.filter(r => r.status === 1).length,
      allocated: rooms.filter(r => r.status === 2).length,
    };
  }, [rooms]);

  // --- PDF Generation Logic ---
  const downloadPdfReport = () => {
    const doc = new jsPDF();
    
    doc.setFontSize(18);
    doc.setTextColor(79, 70, 229);
    doc.text("Room Allocation Status Report", 14, 20);
    
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(`Generated on: ${new Date().toLocaleString()}`, 14, 28);

    // ✅ UPDATED STATS CALCULATION
    const total = processedRooms.length;
    const vacant = processedRooms.filter(r => r.status === 0).length;
    const tentative = processedRooms.filter(r => r.status === 1).length;
    const allocated = processedRooms.filter(r => r.status === 2).length;

    doc.setFontSize(12);
    doc.setTextColor(0);
    doc.text(`Total: ${total}  |  Vacant: ${vacant}  |  Tentative: ${tentative}  |  Allocated: ${allocated}`, 14, 40);

    // Table Data
    const tableData = processedRooms.map(r => {
      let statusText = "Vacant";
      if (r.status === 1) statusText = "Tentative";
      if (r.status === 2) statusText = "Allocated";

      return [
        r.roomName,
        r.capacity,
        statusText,
        r.companyName || '-'
      ];
    });

    autoTable(doc, {
      startY: 45,
      head: [['Room Name', 'Capacity', 'Status', 'Allocated To']],
      body: tableData,
      theme: 'striped',
      headStyles: { fillColor: [79, 70, 229] },
      styles: { fontSize: 10 },
      didParseCell: function (data) {
        if (data.section === 'body' && data.column.index === 2) {
          const status = data.cell.raw;
          if (status === 'Vacant') data.cell.styles.textColor = [16, 185, 129]; // Green
          if (status === 'Tentative') data.cell.styles.textColor = [245, 158, 11]; // Amber
          if (status === 'Allocated') data.cell.styles.textColor = [79, 70, 229]; // Indigo
        }
      }
    });

    doc.save('Rooms_Allocation_Report.pdf');
    toast.success("Report downloaded successfully!");
  };

  // --- Actions ---
  const handleAllocate = async (roomId, companyId) => {
    if (!companyId) return;
    try {
      await api.put(`/admin/rooms/assign-company?companyId=${companyId}&roomId=${roomId}`);
      toast.success("Room allocated!");
      fetchData();
      setAllocatingRoomId(null);
    } catch (error) {
      toast.error(error.response?.data || "Allocation failed");
    }
  };

  const handleDeallocate = async (roomId) => {
    if (!window.confirm("Remove company from this room?")) return;
    try {
      await api.put(`/admin/rooms/${roomId}/remove-company`);
      toast.success("Room vacated.");
      fetchData();
    } catch (error) {
      toast.error("Failed to remove company");
    }
  };

  const confirmRoomAllotment = async (roomId) => {
    try {
      await api.put(`/admin/rooms/${roomId}/confirm-allotment`);
      toast.success("Room allotment confirmed.");
      fetchData();
    } catch (error) {
      toast.error(error.response?.data || "Failed to confirm allotment");
    }
  };

  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const formData = new FormData();
    formData.append('file', file);
    const toastId = toast.loading("Uploading...");
    try {
      await api.post('/admin/rooms/bulk-upload', formData, { headers: { 'Content-Type': 'multipart/form-data' }});
      toast.success("Upload complete!", { id: toastId });
      fetchData();
    } catch (error) {
      toast.error("Upload failed.", { id: toastId });
    }
  };

  const downloadTemplate = async () => {
    try {
      const response = await api.get('/admin/rooms/download', { responseType: 'blob' });
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', 'Rooms_Template.xlsx');
      document.body.appendChild(link);
      link.click();
    } catch (error) {
      toast.error("Download failed");
    }
  };

  const clearFilters = () => {
    setFilters({ minCapacity: '', maxCapacity: '', status: 'all', search: '' });
    setSortConfig({ key: 'name', direction: 'asc' });
  };

  return (
    <div className="space-y-8 animate-fade-in pb-20">
      
      {/* Header & Stats */}
      <div className="flex flex-col gap-6">
        <div className="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Room Allocation</h1>
            <p className="text-gray-500 mt-1">Manage venue capacity and company assignments efficiently.</p>
          </div>
          <div className="flex gap-2 flex-wrap">
            <button onClick={downloadPdfReport} className="px-4 py-2 bg-white border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 text-sm font-medium flex items-center transition shadow-sm">
              <FileText size={16} className="mr-2 text-indigo-600" /> PDF Report
            </button>
            <button onClick={downloadTemplate} className="px-4 py-2 bg-white border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 text-sm font-medium flex items-center transition shadow-sm">
              <Download size={16} className="mr-2 text-gray-500" /> Template
            </button>
            <label className="px-4 py-2 bg-white border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 text-sm font-medium flex items-center cursor-pointer transition shadow-sm">
              <Upload size={16} className="mr-2 text-gray-500" /> Bulk Upload 
              <input type="file" accept=".csv, .xlsx" className="hidden" onChange={handleFileUpload} />
            </label>
            <button onClick={() => setShowAddModal(true)} className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 text-sm font-medium flex items-center shadow-md transition">
              <Plus size={18} className="mr-1" /> Add Room
            </button>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <StatsCard 
            title="Total Rooms" 
            value={stats.total} 
            icon={LayoutGrid} 
            color="bg-gray-100 text-gray-600" 
            onClick={() => setFilters({...filters, status: 'all'})}
          />
          <StatsCard 
            title="Vacant" 
            value={stats.vacant} 
            icon={CheckCircle} 
            color="bg-emerald-100 text-emerald-600" 
            onClick={() => setFilters({...filters, status: 'vacant'})}
          />
          <StatsCard 
            title="Tentative" 
            value={stats.tentative} 
            icon={AlertCircle} 
            color="bg-amber-100 text-amber-600" 
            onClick={() => setFilters({...filters, status: 'tentative'})}
          />
          <StatsCard 
            title="Allocated" 
            value={stats.allocated} 
            icon={Users} 
            color="bg-indigo-100 text-indigo-600" 
            onClick={() => setFilters({...filters, status: 'allocated'})}
          />
        </div>
      </div>

      {/* Toolbar */}
      <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex flex-col lg:flex-row gap-4 items-end lg:items-center justify-between sticky top-0 z-10">
        <div className="flex flex-wrap gap-3 w-full lg:w-auto">
          <div className="relative group">
            <Search className="w-4 h-4 absolute left-3 top-2.5 text-gray-400 group-focus-within:text-indigo-500 transition-colors" />
            <input 
              type="text" 
              placeholder="Search Room..." 
              className="pl-9 pr-3 py-2 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 focus:border-transparent outline-none w-48 transition-all" 
              value={filters.search} 
              onChange={e => setFilters({...filters, search: e.target.value})} 
            />
          </div>
          
          <div className="flex items-center gap-2 border border-gray-200 rounded-lg px-3 py-2 bg-gray-50 focus-within:bg-white focus-within:ring-2 focus-within:ring-indigo-500 transition-all">
            <span className="text-xs font-medium text-gray-500 uppercase">Seats</span>
            <input type="number" placeholder="Min" className="w-10 bg-transparent outline-none text-sm font-bold text-gray-700" value={filters.minCapacity} onChange={e => setFilters({...filters, minCapacity: e.target.value})} />
            <span className="text-gray-300">|</span>
            <input type="number" placeholder="Max" className="w-10 bg-transparent outline-none text-sm font-bold text-gray-700" value={filters.maxCapacity} onChange={e => setFilters({...filters, maxCapacity: e.target.value})} />
          </div>
          
          <select 
            className="border border-gray-200 rounded-lg px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500 bg-white cursor-pointer hover:border-gray-300 transition-colors" 
            value={filters.status} 
            onChange={e => setFilters({...filters, status: e.target.value})}
          >
            <option value="all">All Statuses</option>
            <option value="vacant">Vacant Only</option>
            <option value="tentative">Tentative Only</option>
            <option value="allocated">Allocated Only</option>
          </select>
        </div>
        
        <div className="flex gap-3 items-center w-full lg:w-auto justify-end">
          <div className="flex items-center gap-2">
            <ArrowUpDown size={16} className="text-gray-400" />
            <select className="text-sm font-medium text-gray-700 bg-transparent outline-none cursor-pointer hover:text-indigo-600" value={`${sortConfig.key}-${sortConfig.direction}`} onChange={(e) => { const [key, direction] = e.target.value.split('-'); setSortConfig({ key, direction }); }}>
              <option value="name-asc">Name (A-Z)</option>
              <option value="name-desc">Name (Z-A)</option>
              <option value="capacity-desc">Capacity (High-Low)</option>
              <option value="capacity-asc">Capacity (Low-High)</option>
              <option value="status-asc">Status</option>
            </select>
          </div>
          <button onClick={clearFilters} className="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-full transition" title="Reset Filters"><RotateCcw size={18} /></button>
        </div>
      </div>

      {/* Grid */}
      <div className="bg-white rounded-xl border shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Room</th>
                <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Capacity</th>
                <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Status</th>
                <th className="px-6 py-4 text-left text-xs font-bold text-gray-700 uppercase tracking-wider">Company</th>
                <th className="px-6 py-4 text-right text-xs font-bold text-gray-700 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {loading ? (
                [...Array(6)].map((_, i) => (
                  <tr key={i} className="animate-pulse bg-white hover:bg-gray-50">
                    <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-24"></div></td>
                    <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-16"></div></td>
                    <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-20"></div></td>
                    <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-40"></div></td>
                    <td className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-20 ml-auto"></div></td>
                  </tr>
                ))
              ) : processedRooms.length > 0 ? (
                processedRooms.map((room) => (
                  <tr key={room.roomId} className="bg-white hover:bg-gray-50 transition-colors group">
                    <td className="px-6 py-4">
                      <p className="font-bold text-gray-900 group-hover:text-indigo-600 transition-colors">{room.roomName}</p>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <Users size={14} className="text-gray-400" />
                        <span className="text-sm text-gray-600 font-medium">{room.capacity} Seats</span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <RoomStatusBadge status={room.status} />
                    </td>
                    <td className="px-6 py-4">
                      {room.status === 2 || room.status === 1 ? (
                        <div className="flex items-center gap-2">
                          <button 
                            className="text-sm font-semibold text-indigo-700 hover:underline"
                            onClick={() => room.companyId && navigate(`/admin/companies/${room.companyId}`)}
                            title={room.companyName}
                          >
                            {room.companyName || 'Unknown Company'}
                          </button>
                          {typeof room.companyRepsCount === 'number' && (
                            <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-semibold bg-gray-100 text-gray-700">
                              Reps: {room.companyRepsCount}
                            </span>
                          )}
                        </div>
                      ) : (
                        <span className="text-sm text-gray-500">-</span>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-end gap-2">
                        {room.status === 0 ? (
                          allocatingRoomId === room.roomId ? (
                            <div className="flex gap-2 items-center">
                              <select 
                                className="text-sm px-2 py-1 border border-gray-300 rounded-lg outline-none focus:ring-2 focus:ring-indigo-500 bg-white" 
                                onChange={(e) => handleAllocate(room.roomId, e.target.value)} 
                                defaultValue=""
                                autoFocus
                              >
                                <option value="" disabled>Select...</option>
                                {(companies || []).filter(c => !c.roomName).map(c => (
                                  <option key={c.companyId} value={c.companyId}>
                                    {(c.name || c.companyName)}{typeof c.repsCount === 'number' ? ` (Reps: ${c.repsCount})` : ''}
                                  </option>
                                ))}
                              </select>
                              <button onClick={() => setAllocatingRoomId(null)} className="text-gray-400 hover:text-gray-600 px-1">✕</button>
                            </div>
                          ) : (
                            <button 
                              onClick={() => setAllocatingRoomId(room.roomId)} 
                              className="px-3 py-1.5 text-xs font-medium text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-lg transition-colors"
                            >
                              Assign
                            </button>
                          )
                        ) : (
                          <div className="flex items-center gap-2">
                            {room.status === 1 && (
                              <button 
                                onClick={() => confirmRoomAllotment(room.roomId)} 
                                className="px-3 py-1.5 text-xs font-medium text-amber-700 bg-amber-50 hover:bg-amber-100 rounded-lg transition-colors" 
                                title="Confirm Allotment"
                              >
                                Confirm Allotment
                              </button>
                            )}
                            <button 
                              onClick={() => handleDeallocate(room.roomId)} 
                              className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors" 
                              title="Remove Company"
                            >
                              <Trash2 size={16} />
                            </button>
                          </div>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="5" className="px-6 py-16 text-center">
                    <Search size={48} className="text-gray-300 mb-4 mx-auto" />
                    <p className="text-lg font-medium text-gray-600">No rooms found</p>
                    <p className="text-sm text-gray-400">Try adjusting your filters or search query.</p>
                    <button onClick={clearFilters} className="mt-4 text-indigo-600 hover:text-indigo-800 font-medium text-sm">Clear Filters</button>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {showAddModal && <AddRoomModal onClose={() => setShowAddModal(false)} onSuccess={fetchData} />}
    </div>
  );
};

export default RoomsManagement;