import React, { useEffect, useState } from 'react';
import { getNotices } from '../api';

export default function NoticesBoard({ onError }) {
  const [notices, setNotices] = useState([]);
  
  useEffect(() => { 
    getNotices()
      .then(setNotices)
      .catch(err => onError && onError(err.message)); 
  }, [onError]);

  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">Notices</h2>
      <div className="space-y-4">
        {notices.length === 0 && <p className="text-gray-500">No active notices.</p>}
        {notices.map(n => (
          <div key={n.noticeId} className="bg-white p-6 rounded-xl border-l-4 border-blue-600 shadow-sm animate-fade-in">
            <h3 className="font-bold text-gray-900">{n.title}</h3>
            <p className="text-gray-600 mt-1">{n.content}</p>
            <div className="mt-2 text-xs text-gray-400">
              Target: {n.audience} • {new Date(n.createdAt).toLocaleDateString()}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}