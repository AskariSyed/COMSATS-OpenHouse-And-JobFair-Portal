import axios from 'axios';

// 1. Define the Base URL (Root of your .NET Backend)
// In HTTPS dev mode prefer same-origin + Vite proxy to avoid mixed-content.
const configuredBackendUrl = import.meta.env.VITE_BACKEND_URL || '';
export const BACKEND_URL = import.meta.env.DEV ? configuredBackendUrl : '';

const isInsecureBackendOnSecurePage =
  typeof window !== 'undefined' &&
  window.location.protocol === 'https:' &&
  BACKEND_URL.startsWith('http://');

// 2. Define the API URL
const API_URL = (BACKEND_URL && !isInsecureBackendOnSecurePage) ? `${BACKEND_URL}/api` : '/api';

/**
 * Safe URL builder for uploaded files (images, CVs, logos).
 * Falls back to a relative URL (goes through Vite proxy) when running an HTTPS
 * dev server against an HTTP backend to avoid mixed-content blocking.
 */
export const getFileUrl = (path) => {
  if (!path) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  const cleanPath = path.startsWith('/') ? path : `/${path}`;
  if (isInsecureBackendOnSecurePage || !BACKEND_URL) return cleanPath;
  return `${BACKEND_URL}${cleanPath}`;
};

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// 401 handling for idle/expired sessions across admin portal.
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error?.response?.status;
    if (status === 401) {
      localStorage.removeItem('token');
      localStorage.removeItem('role');
      localStorage.removeItem('userId');
      localStorage.removeItem('email');
      if (typeof window !== 'undefined') {
        sessionStorage.setItem('admin_session_expired', '1');
        if (window.location.pathname !== '/') {
          window.location.replace('/');
        }
      }
    }
    return Promise.reject(error);
  }
);

// 3. Interceptor for Token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const registerCompanyForFair = (companyId, jobFairId) => {
  const query = jobFairId ? `?jobFairId=${jobFairId}` : '';
  return api.post(`/admin/companies/${companyId}/register-for-fair${query}`);
};

export const registerStudentForFair = (studentId, jobFairId) => {
  const query = jobFairId ? `?jobFairId=${jobFairId}` : '';
  return api.post(`/admin/students/${studentId}/register-for-fair${query}`);
};

export const tentativelyAssignRoom = (companyId, roomId, force = false) => {
  return api.put(`/admin/rooms/tentatively-assign?companyId=${companyId}&roomId=${roomId}&force=${force}`);
};

export const assignCompanyToRoom = (companyId, roomId, force = false) => {
  return api.put(`/admin/rooms/assign-company?companyId=${companyId}&roomId=${roomId}&force=${force}`);
};

export const confirmRoomAllotment = (roomId, force = false) => {
  return api.put(`/admin/rooms/${roomId}/confirm-allotment?force=${force}`);
};

export const updateRoomCapacity = (roomId, capacity, force = false) => {
  return api.put(`/admin/rooms/${roomId}/capacity?capacity=${capacity}&force=${force}`);
};

// --- Notifications ---
export const notifyCompany = (companyId, data) => api.post(`/admin/companies/${companyId}/notify`, data);
export const notifyAllCompanies = (data) => api.post(`/admin/companies/notify-all`, data);

// --- Global Student List (Regardless of Participation) ---
export const getAllStudentsGlobal = (page = 1, search = '', department = '') => {
  const query = `?page=${page}&pageSize=20&search=${encodeURIComponent(search)}&department=${encodeURIComponent(department)}`;
  return api.get(`/admin/students/all${query}`);
};

// --- Attendance Management ---
export const getAllJobFairs = () => {
  // Get all job fairs without pagination limit
  return api.get('/admin/jobfairs?page=1&pageSize=1000');
};

export const getCompaniesForJobFair = (jobFairId) => {
  return api.get(`/admin/jobfairs/${jobFairId}/companies`);
};

export const startAttendanceSession = (jobFairId) => {
  return api.post(`/Attendance/start-session`, {
    jobFairId
  });
};

export const generateDailyAttendanceQr = (jobFairId) => {
  return api.post(`/Attendance/generate-daily-qr`, {
    jobFairId
  });
};

export const endAttendanceSession = (sessionToken) => {
  return api.post(`/Attendance/end-session`, {
    sessionToken
  });
};

export const getAttendanceStats = (jobFairId) => {
  return api.get(`/Attendance/stats/${jobFairId}`);
};

export const markCompanyAbsent = (jobFairId, companyId) => {
  return api.put('/Attendance/mark-absent', {
    jobFairId,
    companyId,
  });
};

export const markCompanyPresent = (jobFairId, companyId) => {
  return api.put('/Attendance/mark-present', {
    jobFairId,
    companyId,
  });
};

// --- Job Fair management ---
export const deleteJobFair = (jobFairId) => api.delete(`/admin/jobfairs/${jobFairId}`);
export const activateJobFair = (jobFairId) => api.post(`/admin/jobfairs/${jobFairId}/activate`);
export const updateJobFair = (jobFairId, data) => api.put(`/admin/jobfairs/${jobFairId}`, data);

// --- Student credentials ---
export const updateStudentCredentials = (studentId, data) => api.put(`/admin/students/${studentId}/edit-credentials`, data);

export const unregisterStudentFromFair = (studentId, jobFairId) => {
  const query = jobFairId ? `?jobFairId=${jobFairId}` : '';
  return api.delete(`/admin/students/${studentId}/unregister-from-fair${query}`);
};

export const blockCompany = (companyId) => api.put(`/admin/companies/${companyId}/block`);
export const unblockCompany = (companyId) => api.put(`/admin/companies/${companyId}/unblock`);

api.blockCompany = blockCompany;
api.unblockCompany = unblockCompany;
export default api;