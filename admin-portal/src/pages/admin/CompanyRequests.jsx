import React, { useEffect, useState } from 'react';
import axios from 'axios';
import signalrSvc from '../../services/signalr';

const STATUSES = [
  'Pending',
  'InProgress',
  'Fulfilled',
  'Rejected',
  'Cancelled'
];

const CompanyRequests = () => {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState('');
  const [searchTerm, setSearchTerm] = useState('');

  const apiBase = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5158';

  useEffect(() => {
    fetchList();

    const conn = signalrSvc.createCompanyRequestsConnection();

    async function start() {
      // Only start if not already connected/connecting
      if (conn.state !== 'Disconnected') {
        console.log('SignalR already connected or connecting, state=', conn.state);
        return;
      }
      try {
        await conn.start();
        console.log('SignalR connected successfully');
      } catch (e) {
        console.error('SignalR start failed', e, 'connection state=', conn && conn.state);
        setTimeout(start, 2000);
      }
    }
    start();

    conn.on('CompanyRequestCreated', (payload) => {
      // Normalize camelCase to PascalCase for consistency with API response
      const normalized = {
        CompanyRequestId: payload.companyRequestId || payload.CompanyRequestId,
        CompanyId: payload.companyId || payload.CompanyId,
        CompanyName: payload.companyName || payload.CompanyName,
        JobFairId: payload.jobFairId || payload.JobFairId,
        Type: payload.type || payload.Type,
        Description: payload.description || payload.Description,
        Quantity: payload.quantity || payload.Quantity,
        AdditionalInfo: payload.additionalInfo || payload.AdditionalInfo,
        Status: payload.status || payload.Status,
        AdminNote: payload.adminNote || payload.AdminNote,
        CreatedAt: payload.createdAt || payload.CreatedAt,
        UpdatedAt: payload.updatedAt || payload.UpdatedAt,
        FulfilledAt: payload.fulfilledAt || payload.FulfilledAt
      };
      setRequests(prev => [normalized, ...prev]);
    });

    conn.on('CompanyRequestUpdated', (payload) => {
      // Normalize camelCase to PascalCase for consistency with API response
      const normalized = {
        CompanyRequestId: payload.companyRequestId || payload.CompanyRequestId,
        CompanyId: payload.companyId || payload.CompanyId,
        CompanyName: payload.companyName || payload.CompanyName,
        JobFairId: payload.jobFairId || payload.JobFairId,
        Type: payload.type || payload.Type,
        Description: payload.description || payload.Description,
        Quantity: payload.quantity || payload.Quantity,
        AdditionalInfo: payload.additionalInfo || payload.AdditionalInfo,
        Status: payload.status || payload.Status,
        AdminNote: payload.adminNote || payload.AdminNote,
        CreatedAt: payload.createdAt || payload.CreatedAt,
        UpdatedAt: payload.updatedAt || payload.UpdatedAt,
        FulfilledAt: payload.fulfilledAt || payload.FulfilledAt
      };
      setRequests(prev => prev.map(r => r.CompanyRequestId === normalized.CompanyRequestId ? normalized : r));
    });

    return () => {
      if (conn) {
        try { conn.off('CompanyRequestCreated'); conn.off('CompanyRequestUpdated'); } catch {}
      }
    };
  }, []);

  async function fetchList() {
    setLoading(true);
    try {
      const token = localStorage.getItem('token');
      let url = apiBase + '/api/admin/companyrequests';
      const params = [];
      if (filterStatus) params.push(`status=${filterStatus}`);
      if (params.length > 0) url += '?' + params.join('&');
      
      console.log('Fetching from:', url);
      const res = await axios.get(url, { headers: { Authorization: `Bearer ${token}` } });
      console.log('Fetched company requests:', res.data);
      console.log('Is array?', Array.isArray(res.data), 'Length:', res.data?.length);
      
      // Normalize camelCase to PascalCase for consistency
      const data = Array.isArray(res.data) ? res.data.map(r => ({
        CompanyRequestId: r.companyRequestId || r.CompanyRequestId,
        CompanyId: r.companyId || r.CompanyId,
        CompanyName: r.companyName || r.CompanyName,
        JobFairId: r.jobFairId || r.JobFairId,
        Type: r.type || r.Type,
        Description: r.description || r.Description,
        Quantity: r.quantity || r.Quantity,
        AdditionalInfo: r.additionalInfo || r.AdditionalInfo,
        Status: r.status || r.Status,
        AdminNote: r.adminNote || r.AdminNote,
        CreatedAt: r.createdAt || r.CreatedAt,
        UpdatedAt: r.updatedAt || r.UpdatedAt,
        FulfilledAt: r.fulfilledAt || r.FulfilledAt
      })) : [];
      
      setRequests(data);
    } catch (e) {
      console.error('Error fetching company requests:', e);
      console.error('Error response:', e.response?.data);
      console.error('Error status:', e.response?.status);
      setRequests([]);
    } finally { setLoading(false); }
  }

  // Refetch when filter changes
  useEffect(() => {
    fetchList();
  }, [filterStatus]);

  async function updateStatus(id, status, adminNote) {
    try {
      const token = localStorage.getItem('token');
      console.log('Updating request', id, 'to status', status);
      await axios.put(apiBase + `/api/admin/companyrequests/${id}/status`, { status, adminNote }, { headers: { Authorization: `Bearer ${token}` } });
      console.log('Status updated successfully');
    } catch (e) {
      console.error('Update status error:', e);
      console.error('Error response:', e.response?.data);
      console.error('Error status:', e.response?.status);
      alert('Failed to update status: ' + (e.response?.data || e.message));
    }
  }

  return (
    <div className="space-y-6 animate-fade-in pb-10">
      
      {/* Header & Controls */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Company Requests</h2>
          <p className="text-gray-500 text-sm">Manage equipment and supply needs</p>
        </div>
        
        <div className="flex flex-wrap gap-2 w-full sm:w-auto items-center">
          {/* Filter by Status */}
          <select 
            value={filterStatus} 
            onChange={(e) => setFilterStatus(e.target.value)}
            className="px-3 py-2 border rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 shadow-sm"
          >
            <option value="">All Statuses</option>
            {STATUSES.map(s => <option key={s} value={s}>{s}</option>)}
          </select>

          {/* Search Company */}
          <input 
            type="text"
            placeholder="Search company..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="px-3 py-2 border rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 shadow-sm w-full sm:w-64"
          />
          
          <button 
            onClick={fetchList}
            className="px-4 py-2 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 shadow-sm transition"
          >
            Refresh
          </button>
        </div>
      </div>

      {/* Stats Summary */}
      <div className="grid grid-cols-5 gap-3">
        {STATUSES.map(status => {
          const count = requests.filter(r => r.Status === status).length;
          return (
            <div key={status} className="bg-white border border-gray-200 p-3 rounded-lg text-center shadow-sm">
              <div className="text-2xl font-bold text-indigo-600">{count}</div>
              <div className="text-xs text-gray-600">{status}</div>
            </div>
          );
        })}
      </div>

      {/* Data Table */}
      <div className="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">ID</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Date/Time</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Company</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Type</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Description</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Qty</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Status</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Fulfilled</th>
                <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {loading ? (
                [...Array(5)].map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td colSpan="9" className="px-6 py-4"><div className="h-10 bg-gray-100 rounded w-full"></div></td>
                  </tr>
                ))
              ) : requests.length > 0 ? (
                requests
                  .filter(r => !searchTerm || (r.CompanyName && r.CompanyName.toLowerCase().includes(searchTerm.toLowerCase())))
                  .map(r => {
                    const createdDateTime = r.CreatedAt ? new Date(r.CreatedAt) : null;
                    const createdDate = createdDateTime ? createdDateTime.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : 'Unknown';
                    const createdTime = createdDateTime ? createdDateTime.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }) : '';
                    
                    const fulfilledDateTime = r.FulfilledAt ? new Date(r.FulfilledAt) : null;
                    const fulfilledDate = fulfilledDateTime ? fulfilledDateTime.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }) : '';
                    const fulfilledTime = fulfilledDateTime ? fulfilledDateTime.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }) : '';
                    
                    return (
                      <tr key={r.CompanyRequestId} className="hover:bg-gray-50 transition-colors">
                        {/* ID */}
                        <td className="px-6 py-4">
                          <div className="text-sm font-mono text-gray-900 font-semibold">#{r.CompanyRequestId}</div>
                        </td>
                        
                        {/* Date/Time */}
                        <td className="px-6 py-4">
                          <div className="text-sm text-gray-700">{createdDate}</div>
                          <div className="text-xs text-gray-500">{createdTime}</div>
                        </td>
                        
                        {/* Company */}
                        <td className="px-6 py-4">
                          <div className="font-medium text-gray-900">{r.CompanyName || ('Company ' + r.CompanyId)}</div>
                        </td>

                        {/* Type */}
                        <td className="px-6 py-4">
                          <span className="bg-blue-50 text-blue-700 px-2 py-0.5 rounded text-xs font-medium">
                            {r.Type || 'Unknown'}
                          </span>
                        </td>

                        {/* Description */}
                        <td className="px-6 py-4">
                          <div className="text-sm text-gray-700 max-w-xs truncate">{r.Description || 'No description'}</div>
                          {r.AdditionalInfo && (
                            <div className="text-xs text-gray-500 mt-0.5 max-w-xs truncate">
                              {r.AdditionalInfo}
                            </div>
                          )}
                          {r.AdminNote && (
                            <div className="text-xs text-amber-600 mt-1 bg-amber-50 px-2 py-0.5 rounded inline-block">
                              Note: {r.AdminNote}
                            </div>
                          )}
                        </td>

                        {/* Quantity */}
                        <td className="px-6 py-4">
                          <span className="font-bold text-gray-900">{r.Quantity}</span>
                        </td>

                        {/* Status Badge */}
                        <td className="px-6 py-4">
                          <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${
                            r.Status === 'Fulfilled' ? 'bg-green-100 text-green-800' :
                            r.Status === 'Pending' ? 'bg-yellow-100 text-yellow-800' :
                            r.Status === 'InProgress' ? 'bg-blue-100 text-blue-800' :
                            r.Status === 'Rejected' ? 'bg-red-100 text-red-800' :
                            'bg-gray-100 text-gray-800'
                          }`}>
                            {r.Status}
                          </span>
                        </td>

                        {/* Fulfillment Time */}
                        <td className="px-6 py-4">
                          {r.FulfilledAt ? (
                            <>
                              <div className="text-sm text-green-700 font-medium">{fulfilledDate}</div>
                              <div className="text-xs text-green-600">{fulfilledTime}</div>
                            </>
                          ) : (
                            <span className="text-xs text-gray-400">—</span>
                          )}
                        </td>

                        {/* Action */}
                        <td className="px-6 py-4 text-right">
                          <select 
                            value={r.Status} 
                            onChange={(e) => updateStatus(r.CompanyRequestId, e.target.value, r.AdminNote)} 
                            className="px-3 py-1.5 border rounded-lg text-xs font-medium focus:ring-2 focus:ring-indigo-500 bg-white hover:bg-gray-50 transition"
                          >
                            {STATUSES.map(s => <option key={s} value={s}>{s}</option>)}
                          </select>
                        </td>
                      </tr>
                    );
                  })
              ) : (
                <tr>
                  <td colSpan="8" className="px-6 py-8 text-center text-gray-500">
                    No requests found
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default CompanyRequests;
