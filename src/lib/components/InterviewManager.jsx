/* eslint-disable no-unused-vars */
import React, { useEffect, useState } from 'react';
import { Clock, CheckCircle2, XCircle, Calendar, Loader2, Inbox, Send, History, User, ArrowDownLeft, ArrowUpRight } from 'lucide-react';
import { getPendingInterviewRequests, getAnalytics, acceptInterviewRequest, rejectInterviewRequest, getFileUrl } from '../api';

export default function InterviewManager({ onError }) {
  const [activeTab, setActiveTab] = useState('pending'); // pending | scheduled
  const [loading, setLoading] = useState(true);
  const [refreshKey, setRefreshKey] = useState(0); 
  
  const [pendingRequests, setPendingRequests] = useState([]);
  const [scheduledInterviews, setScheduledInterviews] = useState([]);
  const [stats, setStats] = useState(null);

  // Modal States
  const [actionModal, setActionModal] = useState(null); // { type: 'accept' | 'reject', request: ... }
  const [scheduleTime, setScheduleTime] = useState('');
  const [rejectReason, setRejectReason] = useState('');
  const [processing, setProcessing] = useState(false);

  useEffect(() => {
    setLoading(true);
    Promise.all([
      getPendingInterviewRequests(),
      getAnalytics()
    ]).then(([requestsData, analyticsData]) => {
      setPendingRequests(requestsData.pendingRequests || []);
      setScheduledInterviews(analyticsData.interviews?.scheduledInterviews || []);
      setStats(analyticsData.summary);
    })
    .catch(err => onError(err.message))
    .finally(() => setLoading(false));
  }, [refreshKey, onError]);

  const handleAccept = async (e) => {
    e.preventDefault();
    if (!scheduleTime) return onError("Please select a date and time");
    setProcessing(true);
    try {
      await acceptInterviewRequest(actionModal.request.requestId, scheduleTime);
      setActionModal(null);
      setRefreshKey(k => k + 1);
    } catch (err) {
      onError(err.message);
    } finally {
      setProcessing(false);
    }
  };

  const handleReject = async (e) => {
    e.preventDefault();
    if (!rejectReason) return onError("Please provide a reason");
    setProcessing(true);
    try {
      await rejectInterviewRequest(actionModal.request.requestId, rejectReason);
      setActionModal(null);
      setRefreshKey(k => k + 1);
    } catch (err) {
      onError(err.message);
    } finally {
      setProcessing(false);
    }
  };

  if (loading && !stats) return <div className="p-12 text-center"><Loader2 className="animate-spin mx-auto text-blue-600" /></div>;

  return (
    <div className="space-y-6 animate-fade-in relative">
      
      {/* --- KPI Stats Row --- */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatBox label="Pending Requests" value={pendingRequests.length} icon={Inbox} color="text-orange-600" bg="bg-orange-50" />
        <StatBox label="Scheduled" value={scheduledInterviews.length} icon={Calendar} color="text-blue-600" bg="bg-blue-50" />
        <StatBox label="Total Hired" value={stats?.totalHired || 0} icon={CheckCircle2} color="text-green-600" bg="bg-green-50" />
        <StatBox label="Total Called" value={stats?.totalStudentsCalled || 0} icon={History} color="text-purple-600" bg="bg-purple-50" />
      </div>

      {/* --- Tabs --- */}
      <div className="border-b border-gray-200 flex gap-6">
        <TabBtn id="pending" label="Inbox & Sent" count={pendingRequests.length} active={activeTab} onClick={setActiveTab} />
        <TabBtn id="scheduled" label="Scheduled Interviews" active={activeTab} onClick={setActiveTab} />
      </div>

      {/* --- PENDING REQUESTS VIEW --- */}
      {activeTab === 'pending' && (
        <div className="space-y-4">
          {pendingRequests.length === 0 ? (
            <EmptyState message="No pending requests." />
          ) : (
            <div className="grid grid-cols-1 gap-4">
              {pendingRequests.map(req => {
                // Logic: Check who requested (0 = Company, 1 = Student)
                const isIncoming = req.requestedBy === 1 || req.requestedBy === 'Student';

                return (
                  <div key={req.requestId} className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex flex-col md:flex-row items-start md:items-center gap-4 transition-all hover:border-blue-300">
                    
                    {/* Student Info */}
                    <div className="flex items-center gap-3 flex-1">
                      <div className="w-12 h-12 bg-gray-100 rounded-full overflow-hidden flex-shrink-0 border border-gray-200">
                        {req.studentProfilePic ? (
                          <img src={getFileUrl(req.studentProfilePic)} className="w-full h-full object-cover" alt="" />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center font-bold text-gray-400"><User className="w-6 h-6"/></div>
                        )}
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                            <h4 className="font-bold text-gray-900">{req.studentName}</h4>
                            {/* BADGE: Who requested? */}
                            {isIncoming ? (
                                <span className="text-[10px] bg-purple-100 text-purple-700 px-2 py-0.5 rounded-full flex items-center gap-1 font-bold border border-purple-200">
                                    <ArrowDownLeft className="w-3 h-3" /> Incoming
                                </span>
                            ) : (
                                <span className="text-[10px] bg-yellow-50 text-yellow-700 px-2 py-0.5 rounded-full flex items-center gap-1 font-bold border border-yellow-200">
                                    <ArrowUpRight className="w-3 h-3" /> Sent by You
                                </span>
                            )}
                        </div>
                        <p className="text-xs text-gray-500">{req.studentDepartment} • {req.studentRegistration}</p>
                        <div className="flex gap-2 mt-1">
                          {req.studentSkills?.slice(0, 3).map((s, i) => <span key={i} className="text-[10px] bg-gray-50 px-1.5 py-0.5 rounded text-gray-600 border border-gray-100">{s}</span>)}
                        </div>
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-2 w-full md:w-auto mt-2 md:mt-0">
                      {isIncoming ? (
                        <>
                            <button 
                              onClick={() => { setScheduleTime(''); setActionModal({ type: 'accept', request: req }); }}
                              className="flex-1 md:flex-none bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-700 flex items-center justify-center gap-2 shadow-sm"
                            >
                              <CheckCircle2 className="w-4 h-4" /> Accept
                            </button>
                            <button 
                              onClick={() => { setRejectReason(''); setActionModal({ type: 'reject', request: req }); }}
                              className="flex-1 md:flex-none bg-white border border-gray-200 text-red-600 px-4 py-2 rounded-lg text-sm font-medium hover:bg-red-50 flex items-center justify-center gap-2 shadow-sm"
                            >
                              <XCircle className="w-4 h-4" /> Reject
                            </button>
                        </>
                      ) : (
                        <div className="flex items-center gap-2 text-gray-400 bg-gray-50 px-4 py-2 rounded-lg border border-gray-100 text-sm font-medium cursor-default">
                            <Clock className="w-4 h-4" /> Awaiting Student Response...
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* --- SCHEDULED INTERVIEWS VIEW --- */}
      {activeTab === 'scheduled' && (
        <div>
          {scheduledInterviews.length === 0 ? (
             <EmptyState message="No upcoming interviews scheduled." />
          ) : (
            <div className="bg-white rounded-xl border overflow-hidden shadow-sm">
              <table className="w-full text-sm text-left">
                <thead className="bg-gray-50 text-gray-500 font-medium border-b">
                  <tr>
                    <th className="p-4">Candidate</th>
                    <th className="p-4">Date & Time</th>
                    <th className="p-4">Status</th>
                    <th className="p-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {scheduledInterviews.map(int => (
                    <tr key={int.interviewId} className="border-b last:border-0 hover:bg-gray-50">
                      <td className="p-4 font-medium">
                          {int.studentName} 
                          <span className="text-gray-400 font-normal text-xs block">{int.registrationNo}</span>
                      </td>
                      <td className="p-4">
                        <div className="flex items-center gap-2 text-blue-600 font-medium bg-blue-50 w-fit px-3 py-1 rounded-full">
                           <Clock className="w-3.5 h-3.5" />
                           {new Date(int.scheduledTime).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' })}
                        </div>
                      </td>
                      <td className="p-4">
                        <span className="bg-green-100 text-green-800 px-2 py-1 rounded-full text-xs font-bold flex items-center gap-1 w-fit">
                            <CheckCircle2 className="w-3 h-3" /> Scheduled
                        </span>
                      </td>
                      <td className="p-4 text-right">
                         {/* Placeholder for future actions like "Mark Hired" */}
                         <button className="text-gray-400 hover:text-blue-600 text-xs font-medium">View Profile</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* --- MODALS --- */}
      {actionModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 animate-fade-in">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden">
            <div className="p-6 border-b">
              <h3 className="text-lg font-bold text-gray-900">
                {actionModal.type === 'accept' ? 'Schedule Interview' : 'Reject Request'}
              </h3>
              <p className="text-sm text-gray-500 mt-1">
                Candidate: <span className="font-medium text-gray-900">{actionModal.request.studentName}</span>
              </p>
            </div>
            
            <div className="p-6">
              {actionModal.type === 'accept' ? (
                <form onSubmit={handleAccept} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Select Date & Time</label>
                    <input 
                      type="datetime-local" 
                      required
                      value={scheduleTime}
                      onChange={(e) => setScheduleTime(e.target.value)}
                      className="w-full p-3 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                    />
                  </div>
                  <div className="flex gap-3 pt-2">
                    <button type="button" onClick={() => setActionModal(null)} className="flex-1 py-2.5 text-gray-600 font-medium hover:bg-gray-100 rounded-lg">Cancel</button>
                    <button disabled={processing} className="flex-1 py-2.5 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 flex justify-center items-center gap-2">
                       {processing ? <Loader2 className="animate-spin w-4 h-4" /> : 'Confirm Schedule'}
                    </button>
                  </div>
                </form>
              ) : (
                <form onSubmit={handleReject} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Reason for Rejection</label>
                    <textarea 
                      required
                      rows={3}
                      value={rejectReason}
                      onChange={(e) => setRejectReason(e.target.value)}
                      placeholder="e.g. Position filled, Skills mismatch..."
                      className="w-full p-3 border rounded-lg focus:ring-2 focus:ring-red-500 outline-none resize-none"
                    />
                  </div>
                  <div className="flex gap-3 pt-2">
                    <button type="button" onClick={() => setActionModal(null)} className="flex-1 py-2.5 text-gray-600 font-medium hover:bg-gray-100 rounded-lg">Cancel</button>
                    <button disabled={processing} className="flex-1 py-2.5 bg-red-600 text-white font-medium rounded-lg hover:bg-red-700 flex justify-center items-center gap-2">
                       {processing ? <Loader2 className="animate-spin w-4 h-4" /> : 'Reject Request'}
                    </button>
                  </div>
                </form>
              )}
            </div>
          </div>
        </div>
      )}

    </div>
  );
}

// --- Sub Components ---

function StatBox({ label, value, icon: Icon, color, bg }) {
  return (
    <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex items-center gap-3">
      <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${bg} ${color}`}>
        <Icon className="w-5 h-5" />
      </div>
      <div>
        <div className="text-2xl font-bold text-gray-900">{value}</div>
        <div className="text-xs text-gray-500 font-medium">{label}</div>
      </div>
    </div>
  );
}

function TabBtn({ id, label, count, active, onClick }) {
  const isActive = active === id;
  return (
    <button 
      onClick={() => onClick(id)}
      className={`pb-3 px-1 text-sm font-medium border-b-2 transition-colors relative ${isActive ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700'}`}
    >
      {label}
      {count !== undefined && count > 0 && (
        <span className="ml-2 bg-red-500 text-white text-[10px] px-1.5 py-0.5 rounded-full">{count}</span>
      )}
    </button>
  );
}

function EmptyState({ message }) {
  return (
    <div className="bg-gray-50 border-2 border-dashed border-gray-200 rounded-xl p-12 text-center flex flex-col items-center justify-center text-gray-400">
      <Inbox className="w-12 h-12 mb-3 opacity-20" />
      <p>{message}</p>
    </div>
  );
}