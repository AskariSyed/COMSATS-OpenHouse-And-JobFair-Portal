// --- CONFIGURATION ---
const CONFIGURED_SERVER_URL = import.meta.env.VITE_SERVER_URL || "";
export const SERVER_URL = CONFIGURED_SERVER_URL;
const API_BASE_URL = SERVER_URL ? `${SERVER_URL}/api` : '/api';
const DEFAULT_TIMEOUT_MS = 60000;

/**
 * Helper to get full file URL
 * Handles relative paths from server and absolute URLs
 */
export const getFileUrl = (path) => {
  if (!path) return null;
  if (path.startsWith('http') || path.startsWith('https')) return path;
  // Remove leading slash if present to avoid double slashes if SERVER_URL ends with one
  const cleanPath = path.startsWith('/') ? path.substring(1) : path;
  if (!SERVER_URL) return `/${cleanPath}`;
  return `${SERVER_URL}/${cleanPath}`;
};

/**
 * Generic Fetch Wrapper
 */
async function request(endpoint, method = 'GET', body = null, isFileUpload = false, options = {}) {
  const token = localStorage.getItem('token');
  const { timeoutMs = DEFAULT_TIMEOUT_MS, debugLabel = `${method} ${endpoint}` } = options;
  const headers = {};
  
  // If it's NOT a file upload, set Content-Type to JSON
  // If it IS a file upload (FormData), let the browser set the Content-Type boundary automatically
  if (!isFileUpload) {
    headers['Content-Type'] = 'application/json';
  }
  
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);
  const requestUrl = `${API_BASE_URL}${endpoint}`;
  const startedAt = Date.now();

  const config = {
    method,
    headers,
    body: body ? (isFileUpload ? body : JSON.stringify(body)) : null,
    signal: controller.signal
  };

  try {
    console.debug('[API] Request started', {
      label: debugLabel,
      method,
      url: requestUrl,
      timeoutMs,
      hasBody: !!body,
      body: isFileUpload ? '[FormData]' : body
    });

    const response = await fetch(requestUrl, config);
    const elapsedMs = Date.now() - startedAt;
    console.debug('[API] Response received', {
      label: debugLabel,
      status: response.status,
      ok: response.ok,
      elapsedMs
    });
    
    if (response.status === 401) {
      console.warn("Unauthorized access");
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      if (typeof window !== 'undefined') {
        window.dispatchEvent(new CustomEvent('auth:unauthorized'));
      }
      throw new Error('Unauthorized');
    }

    if (!response.ok) {
      const errData = await response.text();
      throw new Error(errData || `API Error: ${response.status}`);
    }
    
    const text = await response.text();
    return text ? JSON.parse(text) : {};
    
  } catch (error) {
    const elapsedMs = Date.now() - startedAt;
    if (error?.name === 'AbortError') {
      console.error('[API] Request timeout', {
        label: debugLabel,
        method,
        url: requestUrl,
        timeoutMs,
        elapsedMs
      });
      throw new Error(`Request timed out after ${timeoutMs}ms (${debugLabel})`);
    }

    console.error("API Request Failed:", error);
    throw error;
  } finally {
    clearTimeout(timeoutId);
  }
}

// ==========================================
//  EXPORTS
// ==========================================

// --- AUTHENTICATION ---
export const login = (role, email, password, fcmToken = null) => {
  // Matches JobFairPortal.DTOs.LoginDto structure
  return request(`/Auth/${role.toLowerCase()}/login`, 'POST', { 
    emailOrRegNo: email, 
    password: password,
    fcmToken: fcmToken 
  });
};

export const registerFcmToken = (fcmToken) => {
  return request('/Company/register-fcm-token', 'POST', { token: fcmToken });
};
// Missing function restored:
export const registerCompany = (formData) => {
  return request('/Auth/company-signup', 'POST', formData, true); // isFileUpload = true
};

// Missing function restored:
export const verifyOtp = (userEmail, repEmail, otp) => {
  return request('/Auth/company-verify-otp', 'POST', { userEmail, repEmail, otp });
};

// --- PASSWORD RESET ---
export const sendPasswordResetOtp = (emailOrRegNo) => {
  return request('/Auth/forgot-password/send-otp', 'POST', { emailOrRegNo });
};

export const verifyResetOtpAndSetPassword = (userId, otp, newPassword, confirmPassword) => {
  return request('/Auth/forgot-password/verify-otp', 'POST', { userId, otp, newPassword, confirmPassword });
};

export const changePassword = (currentPassword, newPassword, confirmPassword) => {
  return request('/Auth/change-password', 'POST', { currentPassword, newPassword, confirmPassword });
};

// --- COMPANY: ANALYTICS ---
export const getAnalytics = () => {
  return request('/Company/analytics');
};

export const getCompanyParticipationPrompt = () => {
  return request('/Company/participation-prompt');
};

export const participateInActiveJobFair = (repsCount = null) => {
  const payload = repsCount && Number(repsCount) > 0 ? { repsCount: Number(repsCount) } : {};
  return request('/Company/participate-active-jobfair', 'POST', payload);
};

export const getCompanyHistoricalAnalytics = (jobFairId = null) => {
  const query = jobFairId ? `?jobFairId=${encodeURIComponent(jobFairId)}` : '';
  return request(`/Company/analytics/history${query}`);
};

// --- COMPANY: STUDENTS ---
export const getStudents = (filterType, filterValue) => {
  let endpoint = '/Company/students';
  if (filterType === 'skill' && filterValue) {
    endpoint = `/Company/students/search-by-skill?skill=${encodeURIComponent(filterValue)}`;
  } else if (filterType === 'registration' && filterValue) {
    endpoint = `/Company/students/search-by-registration?registrationNo=${encodeURIComponent(filterValue)}`;
  } else if (filterType === 'department' && filterValue) {
    endpoint = `/Company/students/search-by-department?department=${encodeURIComponent(filterValue)}`;
  }
  return request(endpoint);
};

export const getStudentsByInterviewStatus = (status) => {
  return request(`/Company/students/by-interview-status?status=${encodeURIComponent(status)}`);
};

export const getStudentProfile = (studentId) => {
  return request(`/Company/students/${studentId}/profile`);
};

// --- COMPANY: PROJECTS (FYP) ---
export const getFinalYearProjects = () => {
  return request('/Company/finalyear-projects');
};

// Updated to use the new "Full Details" endpoint
export const getProjectDetails = (projectId) => {
  return request(`/Company/finalyear-projects/${projectId}/full-details`);
};

// --- COMPANY: INTERVIEWS ---
export const getPendingInterviewRequests = () => {
  return request('/Company/interview-requests/pending');
};

export const getAllInterviewRequests = (status = null, page = 1, pageSize = 20) => {
  let endpoint = `/Company/interview-requests/all?page=${page}&pageSize=${pageSize}`;
  if (status) endpoint += `&status=${status}`;
  return request(endpoint);
};

export const getScheduledInterviews = () => {
  return request('/Company/interview-requests/all?status=Accepted');
};

export const sendInterviewRequest = (studentId) => {
  return request('/Company/interview-requests/send', 'POST', { studentId });
};

export const acceptInterviewRequest = (requestId) => {
  return request(`/Company/interview-requests/${requestId}/accept`, 'POST', {});
};

export const rejectInterviewRequest = (requestId, reason) => {
  return request(`/Company/interview-requests/${requestId}/reject`, 'POST', { reason });
};

export const scheduleAllInterviews = (date = null) => {
  let endpoint = '/Company/interviews/schedule';
  if (date) endpoint += `?date=${encodeURIComponent(date)}`;
  return request(endpoint, 'POST', {}, false, {
    timeoutMs: 120000,
    debugLabel: 'scheduleAllInterviews'
  });
};

export const getStudentAvailability = (studentId, date = null, stepMinutes = 5) => {
  let endpoint = `/Company/students/${studentId}/availability?stepMinutes=${stepMinutes}`;
  if (date) endpoint += `&date=${encodeURIComponent(date)}`;
  return request(endpoint);
};

export const scheduleStudentInterview = (studentId, scheduledTime, requestId = null) => {
  return request(`/Company/students/${studentId}/schedule`, 'POST', {
    scheduledTime,
    requestId
  });
};

export const startInterview = (interviewId) => {
  return request(`/Company/interviews/${interviewId}/start`, 'POST', {});
};

export const startWalkInInterview = (studentId, overrideScheduledInterview = false) => {
  return request(`/Company/students/${studentId}/walkin/start`, 'POST', {
    overrideScheduledInterview
  });
};

export const completeInterview = (interviewId, resultStatus) => {
  return request(`/Company/interviews/${interviewId}/complete`, 'POST', { resultStatus });
};

// --- COMPANY: REQUESTS ---
const REQUEST_TYPE_MAP = {
  'Supplies': 0,
  'Cleaning': 1,
  'Info': 2,
  'Equipment': 3,
  'Other': 4
};

export const createCompanyRequest = (requestData) => {
  const payload = {
    type: REQUEST_TYPE_MAP[requestData.type],
    Description: requestData.description,
    Quantity: requestData.quantity,
    AdditionalInfo: requestData.additionalInfo || ''
  };
  return request('/Company/requests', 'POST', payload);
};

export const getMyRequests = () => {
  return request('/Company/requests');
};

export const cancelCompanyRequest = (requestId) => {
  return request(`/Company/requests/${requestId}/cancel`, 'PUT');
};

// --- COMPANY: SURVEYS ---
export const getSurveyTemplate = (surveyType) => {
  return request(`/Survey/template/${surveyType}`);
};

export const getMySurveyStatus = () => {
  return request('/Survey/my-status');
};

export const submitSurvey = (surveyData) => {
  return request('/Survey/submit', 'POST', surveyData);
};

export const submitBothSurveys = (surveyData) => {
  return request('/Survey/submit-both', 'POST', surveyData);
};

// --- COMPANY: NOTICES ---
export const getNotices = () => {return request('/Company/notices');};
export const getCompanyProfile = () => request('/Company/profile');
export const updateCompanyProfile = (formData) => request('/Company/profile', 'PUT', formData, true); // FormData

// Jobs
export const getCompanyJobs = (page = 1) => request(`/Company/jobs?page=${page}`);
export const createJob = (jobData) => request('/Company/jobs', 'POST', jobData);
export const updateJob = (jobId, jobData) => request(`/Company/jobs/${jobId}`, 'PUT', jobData);
export const deleteJob = (jobId) => request(`/Company/jobs/${jobId}`, 'DELETE');

// Contact Links
export const addContactLink = (data) => request('/Company/contact-links', 'POST', data);
export const updateContactLink = (linkId, data) => request(`/Company/contact-links/${linkId}`, 'PUT', data);
export const deleteContactLink = (linkId) => request(`/Company/contact-links/${linkId}`, 'DELETE');

// Attendance
export const confirmAttendance = () => request('/Company/confirm-attendance', 'POST');
export const getConfirmationStatus = () => request('/Company/confirmation-status');
export const markAttendanceByQr = (sessionToken) =>
  request('/Attendance/mark', 'POST', { sessionToken });