// --- CONFIGURATION ---
export const SERVER_URL = "http://192.168.137.1:5158"; // Update if your IP changes
const API_BASE_URL = `${SERVER_URL}/api`;

/**
 * Helper to get full file URL
 * Handles relative paths from server and absolute URLs
 */
export const getFileUrl = (path) => {
  if (!path) return null;
  if (path.startsWith('http') || path.startsWith('https')) return path;
  // Remove leading slash if present to avoid double slashes if SERVER_URL ends with one
  const cleanPath = path.startsWith('/') ? path.substring(1) : path;
  return `${SERVER_URL}/${cleanPath}`;
};

/**
 * Generic Fetch Wrapper
 */
async function request(endpoint, method = 'GET', body = null, isFileUpload = false) {
  const token = localStorage.getItem('token');
  const headers = {};
  
  // If it's NOT a file upload, set Content-Type to JSON
  // If it IS a file upload (FormData), let the browser set the Content-Type boundary automatically
  if (!isFileUpload) {
    headers['Content-Type'] = 'application/json';
  }
  
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const config = {
    method,
    headers,
    body: body ? (isFileUpload ? body : JSON.stringify(body)) : null
  };

  try {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, config);
    
    if (response.status === 401) {
      console.warn("Unauthorized access");
      // Optional: window.location.href = '/login';
    }

    if (!response.ok) {
      const errData = await response.text();
      throw new Error(errData || `API Error: ${response.status}`);
    }
    
    const text = await response.text();
    return text ? JSON.parse(text) : {};
    
  } catch (error) {
    console.error("API Request Failed:", error);
    throw error;
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

// --- COMPANY: ANALYTICS ---
export const getAnalytics = () => {
  return request('/Company/analytics');
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