import React, { useState, useEffect } from 'react';
import { Plus, Loader2, AlertCircle, CheckCircle, Clock, XCircle, Trash2 } from 'lucide-react';
import { createCompanyRequest, getMyRequests, cancelCompanyRequest } from '../api';

const REQUEST_TYPES = ['Supplies', 'Cleaning', 'Info', 'Equipment', 'Other'];
const REQUEST_TYPE_MAP = {
  0: 'Supplies',
  1: 'Cleaning',
  2: 'Info',
  3: 'Equipment',
  4: 'Other'
};

const REQUEST_STATUSES = {
  Pending: { color: 'bg-yellow-50 text-yellow-700 border-yellow-200', icon: Clock },
  InProgress: { color: 'bg-blue-50 text-blue-700 border-blue-200', icon: Loader2 },
  Fulfilled: { color: 'bg-green-50 text-green-700 border-green-200', icon: CheckCircle },
  Rejected: { color: 'bg-red-50 text-red-700 border-red-200', icon: XCircle },
  Cancelled: { color: 'bg-gray-50 text-gray-700 border-gray-200', icon: XCircle }
};

const STATUS_VALUE_MAP = {
  0: 'Pending',
  1: 'InProgress',
  2: 'Fulfilled',
  3: 'Rejected',
  4: 'Cancelled'
};

const normalizeStatus = (status) => {
  if (typeof status === 'number') return STATUS_VALUE_MAP[status] || 'Pending';
  if (typeof status !== 'string') return 'Pending';
  const cleaned = status.replace(/\s+/g, '').toLowerCase();
  if (cleaned === 'pending') return 'Pending';
  if (cleaned === 'inprogress') return 'InProgress';
  if (cleaned === 'fulfilled') return 'Fulfilled';
  if (cleaned === 'rejected') return 'Rejected';
  if (cleaned === 'cancelled') return 'Cancelled';
  return 'Pending';
};

export default function CompanyRequests({ onError, onSuccess }) {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({
    type: 'Supplies',
    description: '',
    quantity: 1,
    additionalInfo: ''
  });

  useEffect(() => {
    fetchRequests();
  }, []);

  const fetchRequests = async () => {
    setLoading(true);
    try {
      const data = await getMyRequests();
      setRequests(data || []);
    } catch (err) {
      onError(`Failed to load requests: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleCancelRequest = async (requestId) => {
    if (!window.confirm('Are you sure you want to cancel this request?')) return;
    
    try {
      await cancelCompanyRequest(requestId);
      if (onSuccess) onSuccess('Request cancelled successfully');
      fetchRequests();
    } catch (err) {
      onError(`Failed to cancel request: ${err.message}`);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!formData.description.trim()) {
      onError('Description is required');
      return;
    }
    if (formData.quantity < 1) {
      onError('Quantity must be at least 1');
      return;
    }

    setSubmitting(true);
    try {
      await createCompanyRequest({
        type: formData.type,
        description: formData.description.trim(),
        quantity: parseInt(formData.quantity),
        additionalInfo: formData.additionalInfo.trim()
      });
      
      if (onSuccess) onSuccess('Request submitted successfully!');
      setFormData({ type: 'Supplies', description: '', quantity: 1, additionalInfo: '' });
      setShowForm(false);
      fetchRequests();
    } catch (err) {
      onError(`Failed to submit request: ${err.message}`);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header with Add Button */}
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Supply Requests</h2>
          <p className="text-gray-500 text-sm mt-1">Manage your equipment and supply needs</p>
        </div>
        <button
          onClick={() => setShowForm(!showForm)}
          className="px-6 py-2.5 bg-blue-600 text-white font-bold rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-2"
        >
          <Plus className="w-5 h-5" />
          New Request
        </button>
      </div>

      {/* Form Section */}
      {showForm && (
        <div className="bg-white border border-gray-200 rounded-xl p-6 shadow-sm">
          <h3 className="font-bold text-gray-900 mb-4">Create New Request</h3>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-semibold text-gray-700 block mb-2">Request Type</label>
                <select
                  value={formData.type}
                  onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                  className="w-full border border-gray-300 rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  {REQUEST_TYPES.map(type => (
                    <option key={type} value={type}>{type}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-sm font-semibold text-gray-700 block mb-2">Quantity</label>
                <input
                  type="number"
                  min="1"
                  value={formData.quantity}
                  onChange={(e) => setFormData({ ...formData, quantity: e.target.value })}
                  className="w-full border border-gray-300 rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            </div>

            <div>
              <label className="text-sm font-semibold text-gray-700 block mb-2">Description *</label>
              <input
                type="text"
                placeholder="e.g., 100 ballpoint pens, blue ink"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                className="w-full border border-gray-300 rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <div>
              <label className="text-sm font-semibold text-gray-700 block mb-2">Additional Notes (Optional)</label>
              <textarea
                placeholder="Any additional details..."
                rows="3"
                value={formData.additionalInfo}
                onChange={(e) => setFormData({ ...formData, additionalInfo: e.target.value })}
                className="w-full border border-gray-300 rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
              />
            </div>

            <div className="flex gap-3 pt-2">
              <button
                type="submit"
                disabled={submitting}
                className="flex-1 px-6 py-2.5 bg-blue-600 text-white font-bold rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                {submitting ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Submitting...
                  </>
                ) : (
                  'Submit Request'
                )}
              </button>
              <button
                type="button"
                onClick={() => setShowForm(false)}
                className="px-6 py-2.5 border border-gray-300 text-gray-700 font-bold rounded-lg hover:bg-gray-50 transition-colors"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Requests List */}
      {loading ? (
        <div className="text-center py-12">
          <Loader2 className="animate-spin mx-auto text-blue-600 w-10 h-10" />
          <p className="text-gray-500 mt-2">Loading requests...</p>
        </div>
      ) : requests && requests.length > 0 ? (
        <div className="space-y-3">
          {requests.map((req) => {
            const normalizedStatus = normalizeStatus(req.status);
            const statusConfig = REQUEST_STATUSES[normalizedStatus] || REQUEST_STATUSES.Pending;
            const StatusIcon = statusConfig.icon;
            const fulfilledAt = req.fulfilledAt || req.FulfilledAt;
            
            return (
              <div key={req.companyRequestId} className="bg-white border border-gray-200 rounded-xl p-4 hover:shadow-md transition-shadow">
                <div className="flex items-start justify-between gap-4">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-3 mb-2">
                      <h3 className="font-bold text-gray-900">{req.description}</h3>
                      <span className={`px-3 py-1 rounded-full text-xs font-bold border flex items-center gap-1 whitespace-nowrap ${statusConfig.color}`}>
                        <StatusIcon className="w-3 h-3" />
                        {normalizedStatus}
                      </span>
                    </div>
                    
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm mb-3">
                      <div>
                        <p className="text-gray-500 text-xs font-semibold uppercase">Current Status</p>
                        <p className="text-gray-900 font-medium">{normalizedStatus}</p>
                      </div>
                      <div>
                        <p className="text-gray-500 text-xs font-semibold uppercase">Type</p>
                        <p className="text-gray-900 font-medium">{REQUEST_TYPE_MAP[req.type] || req.type}</p>
                      </div>
                      <div>
                        <p className="text-gray-500 text-xs font-semibold uppercase">Quantity</p>
                        <p className="text-gray-900 font-medium">{req.quantity}</p>
                      </div>
                      <div>
                        <p className="text-gray-500 text-xs font-semibold uppercase">Submitted</p>
                        <p className="text-gray-900 font-medium">{new Date(req.createdAt).toLocaleString()}</p>
                      </div>
                      {normalizedStatus === 'Fulfilled' && fulfilledAt && (
                        <div>
                          <p className="text-gray-500 text-xs font-semibold uppercase">Fulfilled</p>
                          <p className="text-gray-900 font-medium">{new Date(fulfilledAt).toLocaleString()}</p>
                        </div>
                      )}
                    </div>

                    {req.additionalInfo && (
                      <p className="text-sm text-gray-600 italic">📝 {req.additionalInfo}</p>
                    )}

                    {req.adminNote && (
                      <p className="text-sm text-blue-700 bg-blue-50 p-2 rounded mt-2">
                        <span className="font-semibold">Admin Note:</span> {req.adminNote}
                      </p>
                    )}
                  </div>

                  {/* Cancel Button - Only show if request is Pending or InProgress */}
                  {(normalizedStatus === 'Pending' || normalizedStatus === 'InProgress') && (
                    <button
                      onClick={() => handleCancelRequest(req.companyRequestId)}
                      className="text-red-600 hover:text-red-900 bg-red-50 p-2 rounded-lg hover:bg-red-100 transition flex items-center gap-2"
                      title="Cancel Request"
                    >
                      <XCircle className="w-5 h-5" />
                      <span className="text-sm font-medium">Cancel</span>
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="text-center py-12 bg-white rounded-xl border border-dashed border-gray-200">
          <AlertCircle className="w-12 h-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500 font-medium">No requests yet.</p>
          <p className="text-gray-400 text-sm mt-1">Create your first request to get started.</p>
        </div>
      )}
    </div>
  );
}
