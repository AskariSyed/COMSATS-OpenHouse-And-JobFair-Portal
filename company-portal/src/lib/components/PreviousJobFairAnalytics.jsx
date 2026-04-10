import React, { useEffect, useMemo, useState } from 'react';
import { Loader2, Briefcase, Users, CheckCircle, XCircle, Award, Upload, ArrowUpDown } from 'lucide-react';
import { copyJobToCurrentJobFair, getCompanyHistoricalAnalytics } from '../api';

export default function PreviousJobFairAnalytics({ onError, onSuccess, onSelectStudent }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [selectedJobFairId, setSelectedJobFairId] = useState('');
  const [exportingJobId, setExportingJobId] = useState(null);
  const [tableSort, setTableSort] = useState({
    hired: { key: 'studentName', direction: 'asc' },
    shortlisted: { key: 'studentName', direction: 'asc' },
    rejected: { key: 'studentName', direction: 'asc' }
  });

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

  const handleExportJob = async (jobId) => {
    setExportingJobId(jobId);
    try {
      await copyJobToCurrentJobFair(jobId);
      if (onSuccess) onSuccess('Job exported to current job fair successfully.');
    } catch (err) {
      onError(err.message || 'Failed to export job');
    } finally {
      setExportingJobId(null);
    }
  };

  const getSortedOutcomeList = (outcomeKey, list) => {
    const config = tableSort[outcomeKey] || { key: 'studentName', direction: 'asc' };
    return [...list].sort((a, b) => {
      const directionFactor = config.direction === 'asc' ? 1 : -1;
      if (config.key === 'registrationNo') {
        return ((String(a.registrationNo || '').localeCompare(String(b.registrationNo || ''))) * directionFactor);
      }
      if (config.key === 'department') {
        return ((String(a.department || '').localeCompare(String(b.department || ''))) * directionFactor);
      }
      return ((String(a.studentName || '').localeCompare(String(b.studentName || ''))) * directionFactor);
    });
  };

  const toggleOutcomeSort = (outcomeKey, key) => {
    setTableSort((prev) => {
      const current = prev[outcomeKey] || { key: 'studentName', direction: 'asc' };
      const direction = current.key === key && current.direction === 'asc' ? 'desc' : 'asc';
      return { ...prev, [outcomeKey]: { key, direction } };
    });
  };

  const renderStudentsTable = (title, list, colorClass, outcomeKey) => {
    const sortedList = getSortedOutcomeList(outcomeKey, list);
    return (
    <div className="rounded-xl border border-gray-200 bg-white shadow-sm">
      <div className={`border-b px-4 py-3 text-sm font-semibold ${colorClass}`}>{title} ({list.length})</div>
      <div className="max-h-72 overflow-auto">
        {sortedList.length === 0 ? (
          <p className="p-4 text-sm text-gray-500">No students in this category.</p>
        ) : (
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-50 text-gray-500">
              <tr>
                <th className="px-4 py-2">
                  <button type="button" onClick={() => toggleOutcomeSort(outcomeKey, 'studentName')} className="inline-flex items-center gap-1 hover:text-gray-800">
                    Name <ArrowUpDown className="w-3 h-3" />
                  </button>
                </th>
                <th className="px-4 py-2">
                  <button type="button" onClick={() => toggleOutcomeSort(outcomeKey, 'registrationNo')} className="inline-flex items-center gap-1 hover:text-gray-800">
                    Reg No <ArrowUpDown className="w-3 h-3" />
                  </button>
                </th>
                <th className="px-4 py-2">
                  <button type="button" onClick={() => toggleOutcomeSort(outcomeKey, 'department')} className="inline-flex items-center gap-1 hover:text-gray-800">
                    Dept <ArrowUpDown className="w-3 h-3" />
                  </button>
                </th>
                <th className="px-4 py-2 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {sortedList.map((student) => (
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
  };

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

      <div className="rounded-xl border border-gray-200 bg-white shadow-sm p-4">
        <div className="flex items-center justify-between border-b pb-3 mb-4">
          <h3 className="text-sm font-semibold text-gray-700">Jobs Posted In Selected Fair</h3>
          {data.canExportToCurrentJobFair && (
            <span className="text-[11px] font-semibold text-emerald-700 bg-emerald-50 border border-emerald-200 px-2 py-1 rounded-full">
              Export enabled for active fair
            </span>
          )}
        </div>

        {jobs.length === 0 ? (
          <p className="p-4 text-sm text-gray-500">No jobs posted in this job fair.</p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {jobs.map((job) => (
              <div key={job.jobId} className="border border-gray-200 rounded-xl p-4 bg-white hover:shadow-sm transition-shadow">
                <div className="flex items-start justify-between gap-2">
                  <h4 className="font-bold text-gray-900 text-sm">{job.jobTitle}</h4>
                  <span className="text-[10px] font-semibold bg-blue-50 text-blue-700 border border-blue-100 px-2 py-0.5 rounded-full">
                    {job.numberOfJobs} openings
                  </span>
                </div>
                <p className="text-xs text-gray-500 mt-1">Type: {job.jobType}</p>
                <p className="text-sm text-gray-600 mt-2 line-clamp-3">{job.jobDescription || 'No description provided.'}</p>

                <div className="flex flex-wrap gap-1.5 mt-3">
                  {(job.requiredSkills || []).length > 0 ? (job.requiredSkills || []).slice(0, 6).map((skill, idx) => (
                    <span key={`${job.jobId}-${idx}`} className="text-[10px] bg-gray-50 text-gray-700 border border-gray-200 px-2 py-0.5 rounded-full">
                      {skill}
                    </span>
                  )) : (
                    <span className="text-xs text-gray-400">No skills listed.</span>
                  )}
                </div>

                {data.canExportToCurrentJobFair && (
                  <div className="mt-3">
                    <button
                      onClick={() => handleExportJob(job.jobId)}
                      disabled={exportingJobId === job.jobId}
                      className="inline-flex items-center gap-1.5 text-xs font-semibold bg-emerald-600 text-white px-3 py-1.5 rounded-lg hover:bg-emerald-700 disabled:opacity-60"
                    >
                      {exportingJobId === job.jobId ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Upload className="w-3.5 h-3.5" />}
                      Export To Current Fair
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        {renderStudentsTable('Hired', outcomes.hired || [], 'text-green-700', 'hired')}
        {renderStudentsTable('Shortlisted', outcomes.shortlisted || [], 'text-yellow-700', 'shortlisted')}
        {renderStudentsTable('Rejected', outcomes.rejected || [], 'text-red-700', 'rejected')}
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
