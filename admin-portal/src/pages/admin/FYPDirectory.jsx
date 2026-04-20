import React, { useState, useEffect } from 'react';
import toast from 'react-hot-toast';
import FYPExplorer from '../../lib/components/FYPExplorer';
import FYPDetails from '../../lib/components/FYPDetails';
import { getAllJobFairs } from '../../lib/api';

export default function FYPDirectory() {
  const [selectedProjectId, setSelectedProjectId] = useState(null);
  const [jobFairs, setJobFairs] = useState([]);
  const [selectedJobFairId, setSelectedJobFairId] = useState('');
  const [isLoadingFairs, setIsLoadingFairs] = useState(true);

  useEffect(() => {
    fetchJobFairs();
  }, []);

  const fetchJobFairs = async () => {
    setIsLoadingFairs(true);
    try {
      const response = await getAllJobFairs();
      const items = response.data.items || response.data.jobFairs || [];
      setJobFairs(items);
      
      const activeFair = items.find(jf => jf.isActive);
      if (activeFair) {
        setSelectedJobFairId(activeFair.jobFairId.toString());
      } else if (items.length > 0) {
        setSelectedJobFairId(items[0].jobFairId.toString());
      }
    } catch (err) {
      toast.error('Failed to load job fairs.');
    } finally {
      setIsLoadingFairs(false);
    }
  };

  const handleError = (msg) => {
    toast.error(msg);
  };

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Final Year Projects Directory</h1>
          <p className="text-gray-500 text-sm mt-1">Browse projects of students registered for the selected job fair</p>
        </div>
        {!selectedProjectId && !isLoadingFairs && jobFairs.length > 0 && (
          <div className="flex items-center gap-3">
            <label className="text-sm font-medium text-gray-700 whitespace-nowrap">
              Job Fair:
            </label>
            <select
              value={selectedJobFairId}
              onChange={(e) => setSelectedJobFairId(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm min-w-[200px]"
            >
              {jobFairs.map((fair) => (
                <option key={fair.jobFairId} value={fair.jobFairId}>
                  {fair.semester} {fair.isActive ? '(Active)' : ''}
                </option>
              ))}
            </select>
          </div>
        )}
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden min-h-[500px] p-6">
        {selectedProjectId ? (
          <FYPDetails 
            projectId={selectedProjectId} 
            onBack={() => setSelectedProjectId(null)} 
            onError={handleError} 
          />
        ) : (
          <FYPExplorer 
            jobFairId={selectedJobFairId ? parseInt(selectedJobFairId) : null}
            onSelectProject={(id) => setSelectedProjectId(id)} 
            onError={handleError} 
          />
        )}
      </div>
    </div>
  );
}
