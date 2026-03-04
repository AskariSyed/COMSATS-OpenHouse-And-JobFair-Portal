import React, { useEffect, useState } from 'react';
import { Loader2, Briefcase, Users, CheckCircle, XCircle, Award } from 'lucide-react';
import { getCompanyHistoricalAnalytics } from '../api';

export default function PreviousJobFairAnalytics({ onError, onSelectStudent }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [selectedJobFairId, setSelectedJobFairId] = useState('');

  const fetchHistory = async (jobFairId = null) => {
    setLoading(true);
    try {
      const res = await getCompanyHistoricalAnalytics(jobFairId);
      setData(res);
      if (res?.selectedJobFairId) {
        setSelectedJobFairId(String(res.selectedJobFairId));
      }
    } catch (err) {
      onError(err.message || 'Failed to load historical analytics');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHistory();
  }, []);

  if (loading) {
    return <div className="p-20 text-center"><Loader2 className="mx-auto h-10 w-10 animate-spin text-blue-600" /></div>;
  }

  if (!data) {
    return <div className="p-10 text-center text-gray-500">No historical analytics available.</div>;
  }

  const fairs = data.availableJobFairs || [];
  const summary = data.summary || {};
  const outcomes = data.outcomes || { hired: [], shortlisted: [], rejected: [] };
  const jobs = data.jobs || [];

  const renderStudentsTable = (title, list, colorClass) => (
    <div className="rounded-xl border border-gray-200 bg-white shadow-sm">
      <div className={`border-b px-4 py-3 text-sm font-semibold ${colorClass}`}>{title} ({list.length})</div>
      <div className="max-h-72 overflow-auto">
        {list.length === 0 ? (
          <p className="p-4 text-sm text-gray-500">No students in this category.</p>
        ) : (
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-50 text-gray-500">
              <tr>
                <th className="px-4 py-2">Name</th>
                <th className="px-4 py-2">Reg No</th>
                <th className="px-4 py-2">Dept</th>
                <th className="px-4 py-2 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {list.map((student) => (
                <tr key={`${title}-${student.studentId}-${student.interviewId}`}>
                  <td className="px-4 py-2 font-medium text-gray-900">{student.studentName}</td>
                  <td className="px-4 py-2 text-gray-600">{student.registrationNo}</td>
                  <td className="px-4 py-2 text-gray-600">{student.department}</td>
                  <td className="px-4 py-2 text-right">
                    <button
                      onClick={() => onSelectStudent && onSelectStudent({ studentId: student.studentId, fromPastAnalytics: true })}
                      className="rounded-md bg-indigo-50 px-3 py-1 text-xs font-medium text-indigo-700 hover:bg-indigo-100"
                    >
                      View Profile
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );

  return (
    <div className="space-y-6 pb-10">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Previous Job Fair Analytics</h2>
          <p className="text-sm text-gray-500">Review hiring outcomes, students, and jobs from earlier job fairs.</p>
        </div>
        <select
          value={selectedJobFairId}
          onChange={(e) => {
            const id = e.target.value;
            setSelectedJobFairId(id);
            fetchHistory(id || null);
          }}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          {fairs.map((fair) => (
            <option key={fair.jobFairId} value={String(fair.jobFairId)}>
              {fair.semester} ({new Date(fair.date).toLocaleDateString()})
            </option>
          ))}
        </select>
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-3 lg:grid-cols-6">
        <Stat icon={Briefcase} label="Jobs Posted" value={summary.totalJobsPosted || 0} color="text-blue-600" />
        <Stat icon={Users} label="Interviews" value={summary.totalInterviews || 0} color="text-purple-600" />
        <Stat icon={Award} label="Students" value={summary.totalStudentsConsidered || 0} color="text-gray-700" />
        <Stat icon={CheckCircle} label="Hired" value={summary.hiredCount || 0} color="text-green-600" />
        <Stat icon={CheckCircle} label="Shortlisted" value={summary.shortlistedCount || 0} color="text-yellow-600" />
        <Stat icon={XCircle} label="Rejected" value={summary.rejectedCount || 0} color="text-red-600" />
      </div>

      <div className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
        <h3 className="text-sm font-semibold text-gray-700">Hiring Rate</h3>
        <p className="mt-1 text-2xl font-bold text-gray-900">{summary.hiringRate || 0}%</p>
      </div>

      <div className="rounded-xl border border-gray-200 bg-white shadow-sm">
        <div className="border-b px-4 py-3 text-sm font-semibold text-gray-700">Jobs Posted In Selected Fair</div>
        <div className="max-h-80 overflow-auto">
          {jobs.length === 0 ? (
            <p className="p-4 text-sm text-gray-500">No jobs posted in this job fair.</p>
          ) : (
            <table className="w-full text-left text-sm">
              <thead className="bg-gray-50 text-gray-500">
                <tr>
                  <th className="px-4 py-2">Title</th>
                  <th className="px-4 py-2">Type</th>
                  <th className="px-4 py-2">Openings</th>
                  <th className="px-4 py-2">Skills</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {jobs.map((job) => (
                  <tr key={job.jobId}>
                    <td className="px-4 py-2 font-medium text-gray-900">{job.jobTitle}</td>
                    <td className="px-4 py-2 text-gray-600">{job.jobType}</td>
                    <td className="px-4 py-2 text-gray-600">{job.numberOfJobs}</td>
                    <td className="px-4 py-2 text-gray-600">{(job.requiredSkills || []).join(', ') || '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        {renderStudentsTable('Hired', outcomes.hired || [], 'text-green-700')}
        {renderStudentsTable('Shortlisted', outcomes.shortlisted || [], 'text-yellow-700')}
        {renderStudentsTable('Rejected', outcomes.rejected || [], 'text-red-700')}
      </div>
    </div>
  );
}

function Stat({ icon: Icon, label, value, color }) {
  return (
    <div className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
      <div className="flex items-center justify-between">
        <p className="text-xs font-semibold uppercase tracking-wide text-gray-500">{label}</p>
        <Icon className={`h-4 w-4 ${color}`} />
      </div>
      <p className="mt-2 text-2xl font-bold text-gray-900">{value}</p>
    </div>
  );
}
