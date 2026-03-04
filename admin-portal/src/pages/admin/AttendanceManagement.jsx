import React, { useState, useRef, useEffect } from 'react';
import { Download, RefreshCw, Play, X, Eye, Copy, Check } from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';
import html2canvas from 'html2canvas';
import toast from 'react-hot-toast';
import * as api from '../../lib/api';

const AttendanceManagement = () => {
  const [jobFairs, setJobFairs] = useState([]);
  const [selectedJobFair, setSelectedJobFair] = useState(null);
  const [jobFairStats, setJobFairStats] = useState({});
  const [companies, setCompanies] = useState([]);
  const [loading, setLoading] = useState(false);
  const [sessionToken, setSessionToken] = useState(null);
  const [sessionActive, setSessionActive] = useState(false);
  const [attendedCompanies, setAttendedCompanies] = useState([]);
  const [copiedToken, setCopiedToken] = useState(false);
  const qrRef = useRef(null);

  const getJobFairId = (jobFair) => jobFair?.JobFairId || jobFair?.jobFairId;
  const getCompanyId = (company) => company?.id || company?.companyId || company?.CompanyId;

  // Fetch Job Fairs
  useEffect(() => {
    fetchJobFairs();
  }, []);

  const fetchJobFairs = async () => {
    try {
      const response = await api.getAllJobFairs();
      // Handle paginated response - data.jobFairs is the array
      const jobFairsList = response.data?.jobFairs || response.data || [];
      const fairs = Array.isArray(jobFairsList) ? jobFairsList : [];
      setJobFairs(fairs);
      await fetchJobFairCardStats(fairs);
    } catch (error) {
      toast.error('Failed to fetch job fairs');
      console.error(error);
      setJobFairs([]); // Set empty array on error
      setJobFairStats({});
    }
  };

  const fetchJobFairCardStats = async (fairs) => {
    try {
      const statsEntries = await Promise.all(
        fairs.map(async (fair) => {
          const jobFairId = getJobFairId(fair);
          if (!jobFairId) {
            return [String(Math.random()), { totalCompanies: 0, presentCompanies: 0 }];
          }

          try {
            const [companiesRes, attendanceRes] = await Promise.all([
              api.getCompaniesForJobFair(jobFairId),
              api.getAttendanceStats(jobFairId),
            ]);

            const fairCompanies = Array.isArray(companiesRes.data) ? companiesRes.data : [];
            const fairAttendance = Array.isArray(attendanceRes.data) ? attendanceRes.data : [];

            return [
              String(jobFairId),
              {
                totalCompanies: fairCompanies.length,
                presentCompanies: fairAttendance.filter((c) => c.isPresent).length,
              },
            ];
          } catch {
            return [String(jobFairId), { totalCompanies: 0, presentCompanies: 0 }];
          }
        })
      );

      setJobFairStats(Object.fromEntries(statsEntries));
    } catch (error) {
      console.error('Failed to fetch job fair card stats', error);
      setJobFairStats({});
    }
  };

  // Fetch Companies for selected Job Fair
  useEffect(() => {
    if (selectedJobFair) {
      fetchCompanies();
    }
  }, [selectedJobFair]);

  const fetchCompanies = async () => {
    try {
      setLoading(true);
      const jobFairId = getJobFairId(selectedJobFair);
      const response = await api.getCompaniesForJobFair(jobFairId);
      // Ensure we always set an array
      setCompanies(Array.isArray(response.data) ? response.data : []);
      setSessionToken(null);
      setSessionActive(false);
      await fetchAttendanceStats(jobFairId);

      if (isJobFairToday(selectedJobFair)) {
        await loadDailyQr(jobFairId);
      }
    } catch (error) {
      toast.error('Failed to fetch companies');
      console.error(error);
      setCompanies([]); // Set empty array on error
      setAttendedCompanies([]);
    } finally {
      setLoading(false);
    }
  };

  const handleStartAttendanceSession = async () => {
    if (!isJobFairToday(selectedJobFair)) {
      toast.error('Attendance can only be started on the job fair date');
      return;
    }

    try {
      setLoading(true);
      const jobFairId = getJobFairId(selectedJobFair);
      await loadDailyQr(jobFairId);
      await fetchAttendanceStats(jobFairId);
      await fetchJobFairs();
      toast.success('Daily attendance QR is ready');
    } catch (error) {
      const errorMsg = error.response?.data?.error || error.message || 'Failed to start attendance session';
      toast.error(errorMsg);
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const loadDailyQr = async (jobFairId) => {
    const response = await api.generateDailyAttendanceQr(jobFairId);
    const token = response?.data?.sessionToken;

    if (!token) {
      throw new Error('No QR token returned by server');
    }

    setSessionToken(token);
    setSessionActive(true);
    return token;
  };

  const handleEndAttendanceSession = async () => {
    try {
      setLoading(true);
      await api.endAttendanceSession(sessionToken);
      setSessionActive(false);
      toast.success('Attendance session ended');
      // Refresh attendance data
      await fetchAttendanceStats();
      await fetchJobFairs();
    } catch (error) {
      toast.error('Failed to end attendance session');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const fetchAttendanceStats = async (jobFairIdParam = null) => {
    try {
      const jobFairId = jobFairIdParam || getJobFairId(selectedJobFair);
      if (!jobFairId) return;

      const response = await api.getAttendanceStats(jobFairId);
      const stats = Array.isArray(response.data) ? response.data : [];
      const attended = stats
        .filter((c) => c.isPresent)
        .map((c) => String(c.id || c.companyId || c.CompanyId));
      setAttendedCompanies(attended);
    } catch (error) {
      console.error('Failed to fetch attendance stats', error);
    }
  };

  useEffect(() => {
    if (!selectedJobFair || !sessionActive) return;

    const jobFairId = getJobFairId(selectedJobFair);
    if (!jobFairId) return;

    const intervalId = setInterval(() => {
      fetchAttendanceStats(jobFairId);
    }, 10000);

    return () => clearInterval(intervalId);
  }, [selectedJobFair, sessionActive]);

  const handleDownloadQR = async () => {
    try {
      const canvas = await html2canvas(qrRef.current, {
        backgroundColor: '#ffffff',
        scale: 2
      });
      const link = document.createElement('a');
      link.href = canvas.toDataURL('image/png');
      link.download = `attendance-qr-${selectedJobFair.eventName}.png`;
      link.click();
      toast.success('QR code downloaded');
    } catch (error) {
      toast.error('Failed to download QR code');
      console.error(error);
    }
  };

  const handlePrintQR = () => {
    const printWindow = window.open('', '', 'width=800,height=600');
    const content = qrRef.current.innerHTML;
    printWindow.document.write(`
      <html>
        <head>
          <title>Attendance QR Code - ${selectedJobFair.eventName}</title>
          <style>
            body { 
              font-family: Arial, sans-serif; 
              margin: 0;
              padding: 40px;
              display: flex;
              justify-content: center;
              align-items: center;
              min-height: 100vh;
            }
            .qr-container { 
              text-align: center; 
              padding: 40px;
              border: 2px solid #000;
            }
            h2 { margin: 0 0 20px 0; }
            p { margin: 10px 0; font-size: 14px; }
          </style>
        </head>
        <body>
          <div class="qr-container">
            ${content}
            <h2>${selectedJobFair.eventName}</h2>
            <p>Scan this QR code to mark your company's attendance</p>
            <p>Session Active: ${sessionActive}</p>
          </div>
          <script>window.print();</script>
        </body>
      </html>
    `);
    printWindow.document.close();
  };

  const handleCopyToken = () => {
    navigator.clipboard.writeText(sessionToken);
    setCopiedToken(true);
    toast.success('Token copied to clipboard');
    setTimeout(() => setCopiedToken(false), 2000);
  };

  const handleMarkAbsent = async (company) => {
    try {
      const jobFairId = getJobFairId(selectedJobFair);
      const companyId = getCompanyId(company);

      if (!jobFairId || !companyId) {
        toast.error('Unable to mark absent: missing company or job fair ID');
        return;
      }

      await api.markCompanyAbsent(jobFairId, Number(companyId));
      toast.success(`${company.companyName || company.name || 'Company'} marked absent`);

      await fetchAttendanceStats(jobFairId);
      await fetchJobFairs();
    } catch (error) {
      const errorMsg = error.response?.data?.error || 'Failed to mark company absent';
      toast.error(errorMsg);
      console.error(error);
    }
  };

  const handleMarkPresent = async (company) => {
    try {
      const jobFairId = getJobFairId(selectedJobFair);
      const companyId = getCompanyId(company);

      if (!jobFairId || !companyId) {
        toast.error('Unable to mark present: missing company or job fair ID');
        return;
      }

      await api.markCompanyPresent(jobFairId, Number(companyId));
      toast.success(`${company.companyName || company.name || 'Company'} marked present`);

      await fetchAttendanceStats(jobFairId);
      await fetchJobFairs();
    } catch (error) {
      const errorMsg = error.response?.data?.error || 'Failed to mark company present';
      toast.error(errorMsg);
      console.error(error);
    }
  };

  const isJobFairToday = (jobFair) => {
    const jobFairDate = new Date(jobFair.Date || jobFair.date);
    const today = new Date();
    return jobFairDate.toDateString() === today.toDateString();
  };

  if (!selectedJobFair) {
    return (
      <div className="p-6 max-w-6xl mx-auto">
        <h1 className="text-3xl font-bold mb-6">Attendance Management</h1>
        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold mb-4">Select Job Fair</h2>
          {jobFairs.length === 0 ? (
            <p className="text-gray-500">No job fairs available</p>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {jobFairs.map(jf => {
                const today = isJobFairToday(jf);
                const fairId = String(getJobFairId(jf));
                const fairStats = jobFairStats[fairId] || { totalCompanies: 0, presentCompanies: 0 };
                return (
                  <button
                    key={getJobFairId(jf)}
                    onClick={() => setSelectedJobFair(jf)}
                    disabled={!today}
                    className={`p-4 border-2 rounded-lg transition text-left ${
                      today
                        ? 'border-blue-500 hover:bg-blue-50 cursor-pointer'
                        : 'border-gray-300 bg-gray-50 opacity-60 cursor-not-allowed'
                    }`}
                  >
                    <div className="flex items-start justify-between">
                      <h3 className="font-semibold text-lg">{jf.Semester || jf.semester}</h3>
                      {today && (
                        <span className="text-xs bg-green-100 text-green-800 px-2 py-1 rounded-full font-semibold">Today</span>
                      )}
                    </div>
                    <p className="text-sm text-gray-600">
                      {new Date(jf.Date || jf.date).toLocaleDateString()}
                    </p>
                    <p className="text-xs text-gray-500 mt-2">
                      {fairStats.totalCompanies} Companies
                    </p>
                    <p className="text-xs text-gray-500 mt-1">{fairStats.presentCompanies} Present</p>
                    {!today && (
                      <p className="text-xs text-red-600 mt-2 font-medium">Attendance unavailable on this date</p>
                    )}
                  </button>
                );
              })}
            </div>
          )}
        </div>
      </div>
    );
  }

  const attendanceRate = companies.length > 0 
    ? Math.round((attendedCompanies.length / companies.length) * 100)
    : 0;

  return (
    <div className="p-6 max-w-6xl mx-auto">
      {/* Header with Back Button */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <button
            onClick={() => {
              setSelectedJobFair(null);
              setSessionToken(null);
              setSessionActive(false);
              setAttendedCompanies([]);
            }}
            className="text-blue-600 hover:text-blue-800 mb-2 flex items-center gap-2"
          >
            ← Back to Job Fairs
          </button>
          <h1 className="text-3xl font-bold">
            Attendance Session - {selectedJobFair.Semester || selectedJobFair.semester}
          </h1>
          <p className="text-gray-600 mt-1">
            {new Date(selectedJobFair.Date || selectedJobFair.date).toLocaleDateString()}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* QR Code Panel */}
        <div className="lg:col-span-2">
          <div className="bg-white rounded-lg shadow-md p-6">
            {!sessionActive ? (
              <div className="text-center py-12">
                <h2 className="text-2xl font-bold mb-4">Generate Daily Attendance QR</h2>
                <p className="text-gray-600 mb-6">
                  Generate one static QR for today. Companies scan this QR to mark attendance.
                </p>
                <button
                  onClick={handleStartAttendanceSession}
                  disabled={loading}
                  className="bg-green-600 hover:bg-green-700 disabled:bg-gray-400 text-white px-6 py-3 rounded-lg font-medium transition flex items-center justify-center gap-2 mx-auto"
                >
                  <Play size={20} />
                  Generate Daily QR
                </button>
              </div>
            ) : (
              <div>
                <div className="flex items-center justify-between mb-4">
                  <h2 className="text-2xl font-bold">Daily Attendance QR</h2>
                  <div className="flex items-center gap-2">
                    <span className="inline-block w-3 h-3 bg-green-500 rounded-full animate-pulse"></span>
                    <span className="text-green-600 font-semibold">Valid Today</span>
                  </div>
                </div>

                <div
                  ref={qrRef}
                  className="flex justify-center mb-6 bg-gradient-to-br from-blue-50 to-indigo-50 p-8 rounded-lg"
                >
                  <div className="bg-white p-6 rounded-lg shadow-lg">
                    <QRCodeSVG
                      value={sessionToken}
                      size={250}
                      level="H"
                      includeMargin={true}
                    />
                  </div>
                </div>

                <p className="text-center text-gray-600 mb-4">
                  Companies can scan this QR code to mark attendance for today
                </p>

                <div className="bg-gray-50 p-4 rounded-lg mb-6">
                  <p className="text-sm text-gray-600 mb-2">Session Token:</p>
                  <div className="flex items-center gap-2">
                    <code className="flex-1 bg-white p-2 rounded border border-gray-300 text-xs break-all">
                      {sessionToken}
                    </code>
                    <button
                      onClick={handleCopyToken}
                      className="bg-blue-100 hover:bg-blue-200 text-blue-800 px-3 py-2 rounded transition flex items-center gap-2"
                    >
                      {copiedToken ? (
                        <>
                          <Check size={16} />
                        </>
                      ) : (
                        <>
                          <Copy size={16} />
                        </>
                      )}
                    </button>
                  </div>
                </div>

                <div className="flex gap-3">
                  <button
                    onClick={handleDownloadQR}
                    className="flex-1 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium transition flex items-center justify-center gap-2"
                  >
                    <Download size={18} />
                    Download QR
                  </button>

                  <button
                    onClick={handlePrintQR}
                    className="flex-1 bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-lg font-medium transition"
                  >
                    Print QR
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Stats Panel */}
        <div className="bg-white rounded-lg shadow-md p-6 h-fit">
          <h2 className="text-lg font-semibold mb-6">Session Statistics</h2>
          
          <div className="space-y-4">
            <div className="p-4 bg-blue-50 rounded-lg">
              <p className="text-sm text-gray-600">Total Companies</p>
              <p className="text-3xl font-bold text-blue-600">{companies.length}</p>
            </div>

            <div className="p-4 bg-green-50 rounded-lg">
              <p className="text-sm text-gray-600">Companies Present</p>
              <p className="text-3xl font-bold text-green-600">{attendedCompanies.length}</p>
            </div>

            <div className="p-4 bg-purple-50 rounded-lg">
              <p className="text-sm text-gray-600">Attendance Rate</p>
              <div className="flex items-end gap-2">
                <p className="text-3xl font-bold text-purple-600">{attendanceRate}%</p>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2 mt-2">
                <div 
                  className="bg-purple-600 h-2 rounded-full transition-all duration-300"
                  style={{ width: `${attendanceRate}%` }}
                ></div>
              </div>
            </div>

            {sessionActive && (
              <button
                onClick={fetchAttendanceStats}
                className="w-full bg-indigo-100 hover:bg-indigo-200 text-indigo-800 px-4 py-2 rounded-lg font-medium transition"
              >
                <RefreshCw size={18} className="inline mr-2" />
                Refresh Stats
              </button>
            )}
          </div>

          {sessionActive && (
            <div className="mt-6 p-3 bg-green-50 rounded-lg border border-green-200">
              <p className="text-xs font-semibold text-green-900">✓ Session Active</p>
              <p className="text-xs text-green-700 mt-1">
                QR code is live and companies can scan to mark attendance
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Attended Companies List */}
      {sessionActive && attendedCompanies.length > 0 && (
        <div className="mt-6 bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold mb-4">Companies Attended ({attendedCompanies.length})</h2>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
            {companies
              .filter(c => attendedCompanies.includes(String(getCompanyId(c))))
              .map(company => (
                <div key={getCompanyId(company)} className="bg-green-50 border border-green-200 p-3 rounded-lg">
                  <p className="text-sm font-semibold text-gray-800 break-words">{company.companyName || company.name || 'Company'}</p>
                  <span className="inline-block mt-2 px-2 py-1 bg-green-200 text-green-800 text-xs rounded-full">
                    ✓ Present
                  </span>
                  <button
                    onClick={() => handleMarkAbsent(company)}
                    className="mt-2 w-full px-2 py-1.5 text-xs font-medium bg-red-100 text-red-700 hover:bg-red-200 rounded-md transition"
                  >
                    Mark Absent
                  </button>
                </div>
              ))}
          </div>
        </div>
      )}

      {sessionActive && companies.some(c => !attendedCompanies.includes(String(getCompanyId(c)))) && (
        <div className="mt-6 bg-white rounded-lg shadow-md p-6">
          <h2 className="text-xl font-semibold mb-4">
            Companies Not Present ({companies.filter(c => !attendedCompanies.includes(String(getCompanyId(c)))).length})
          </h2>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
            {companies
              .filter(c => !attendedCompanies.includes(String(getCompanyId(c))))
              .map(company => (
                <div key={getCompanyId(company)} className="bg-amber-50 border border-amber-200 p-3 rounded-lg">
                  <p className="text-sm font-semibold text-gray-800 break-words">{company.companyName || company.name || 'Company'}</p>
                  <span className="inline-block mt-2 px-2 py-1 bg-amber-100 text-amber-800 text-xs rounded-full">
                    Not Present
                  </span>
                  <button
                    onClick={() => handleMarkPresent(company)}
                    className="mt-2 w-full px-2 py-1.5 text-xs font-medium bg-green-100 text-green-700 hover:bg-green-200 rounded-md transition"
                  >
                    Mark Present
                  </button>
                </div>
              ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default AttendanceManagement;

