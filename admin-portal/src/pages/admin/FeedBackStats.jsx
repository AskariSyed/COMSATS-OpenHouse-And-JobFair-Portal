/* eslint-disable no-unused-vars */
import React, { useEffect, useState } from 'react';
import { PieChart, Pie, Cell, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { MessageSquare, Coffee, Layout, Award, Download } from 'lucide-react';
import api from '../../lib/api';
import toast from 'react-hot-toast';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';

const FeedbackStats = () => {
  const [surveys, setSurveys] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchSurveys = async () => {
      try {
        // Matches AdminController.cs Endpoint #7
        const res = await api.get('/admin/surveys');
        setSurveys(res.data);
      } catch (error) {
        toast.error("Failed to load feedback");
      } finally {
        setLoading(false);
      }
    };
    fetchSurveys();
  }, []);

  // --- Helper: Process Data for Charts ---
  const getStats = (field) => {
    const counts = { Good: 0, Average: 0, Bad: 0 };
    surveys.forEach(s => {
      const val = s.responses?.[field] || 'Average'; // Default fallback
      if (counts[val] !== undefined) counts[val]++;
    });
    return [
      { name: 'Good', value: counts.Good },
      { name: 'Average', value: counts.Average },
      { name: 'Bad', value: counts.Bad },
    ];
  };

  const COLORS = ['#10B981', '#F59E0B', '#EF4444']; // Green, Amber, Red

  // --- PDF Generator ---
  const downloadPdf = () => {
    const doc = new jsPDF();
    doc.text("Employer Feedback Report", 14, 20);
    
    // Comments Table
    const rows = surveys.map(s => [
      s.companyName || 'Anonymous',
      s.responses?.fypQuality,
      s.responses?.fypComments || '-',
      s.responses?.arrangementsQuality,
      s.responses?.arrangementComments || '-'
    ]);

    autoTable(doc, {
      startY: 30,
      head: [['Company', 'FYP Rating', 'FYP Comments', 'Arrangements', 'Notes']],
      body: rows,
    });

    doc.save('Feedback_Report.pdf');
  };

  if (loading) return <div className="p-10 text-center">Loading Feedback...</div>;

  return (
    <div className="space-y-8 animate-fade-in pb-10">
      
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Employer Feedback</h1>
          <p className="text-gray-500 text-sm">Observations on FYP Quality, Logistics, and Food.</p>
        </div>
        <button onClick={downloadPdf} className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700">
           <Download size={16} /> Export PDF
        </button>
      </div>

      {/* 1. Visual Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        
        {/* FYP Quality Chart */}
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm flex flex-col items-center">
          <div className="flex items-center gap-2 mb-4 text-gray-800 font-bold">
            <Award className="text-indigo-600" /> FYP Quality
          </div>
          <div className="h-48 w-full">
            <ResponsiveContainer>
              <PieChart>
                <Pie data={getStats('fypQuality')} innerRadius={40} outerRadius={60} paddingAngle={5} dataKey="value">
                  {getStats('fypQuality').map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Arrangements Chart */}
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm flex flex-col items-center">
          <div className="flex items-center gap-2 mb-4 text-gray-800 font-bold">
            <Layout className="text-blue-600" /> Arrangements
          </div>
          <div className="h-48 w-full">
            <ResponsiveContainer>
              <PieChart>
                <Pie data={getStats('arrangementsQuality')} innerRadius={40} outerRadius={60} paddingAngle={5} dataKey="value">
                  {getStats('arrangementsQuality').map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Food Quality Chart */}
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm flex flex-col items-center">
          <div className="flex items-center gap-2 mb-4 text-gray-800 font-bold">
            <Coffee className="text-amber-600" /> Refreshments
          </div>
          <div className="h-48 w-full">
            <ResponsiveContainer>
              <PieChart>
                <Pie data={getStats('foodQuality')} innerRadius={40} outerRadius={60} paddingAngle={5} dataKey="value">
                  {getStats('foodQuality').map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* 2. Detailed Comments Feed */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
        <div className="p-5 border-b border-gray-100 bg-gray-50">
          <h3 className="font-bold text-gray-800 flex items-center gap-2">
            <MessageSquare size={18} /> Detailed Comments
          </h3>
        </div>
        <div className="divide-y divide-gray-100">
          {surveys.map((s) => (
            <div key={s.surveyId} className="p-6 hover:bg-gray-50 transition">
              <div className="flex justify-between items-start mb-2">
                <span className="font-bold text-gray-900">{s.companyName || "Anonymous Company"}</span>
                <span className="text-xs text-gray-400">{new Date(s.submittedAt).toLocaleDateString()}</span>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm mt-3">
                {/* FYP Comment */}
                <div className="bg-indigo-50 p-3 rounded-lg">
                  <span className="block text-xs font-bold text-indigo-400 uppercase mb-1">FYP Suggestions</span>
                  <p className="text-gray-700 italic">"{s.responses?.fypComments || 'No comments'}"</p>
                </div>
                {/* Arrangement Comment */}
                <div className="bg-blue-50 p-3 rounded-lg">
                  <span className="block text-xs font-bold text-blue-400 uppercase mb-1">Arrangements</span>
                  <p className="text-gray-700 italic">"{s.responses?.arrangementComments || 'No comments'}"</p>
                </div>
                {/* Food Comment */}
                <div className="bg-amber-50 p-3 rounded-lg">
                  <span className="block text-xs font-bold text-amber-500 uppercase mb-1">Food & Lunch</span>
                  <p className="text-gray-700 italic">"{s.responses?.foodComments || 'No comments'}"</p>
                </div>
              </div>
            </div>
          ))}
          {surveys.length === 0 && (
            <div className="p-10 text-center text-gray-400 italic">No feedback surveys submitted yet.</div>
          )}
        </div>
      </div>
    </div>
  );
};

export default FeedbackStats;