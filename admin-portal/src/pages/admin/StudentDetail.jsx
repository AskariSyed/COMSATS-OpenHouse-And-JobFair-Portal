/* eslint-disable no-unused-vars */
import React, { useEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import { 
  ArrowLeft, Mail, Phone, Globe, Github, Linkedin, 
  Briefcase, Award, GraduationCap, PlayCircle, ExternalLink,
  Layers, Bell, Edit2, Save, X
} from 'lucide-react';
import { toast } from 'react-hot-toast';
import SendNotificationModal from '../../lib/components/SendNotificationModal';
import api, { getFileUrl, updateStudentCredentials } from '../../lib/api';


const getYouTubeId = (url) => {
  if (!url) return null;
  const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*/;
  const match = url.match(regExp);
  return (match && match[2].length === 11) ? match[2] : null;
};

const formatGradeValue = (value, digits = 2) => {
  const num = Number(value);
  if (!Number.isFinite(num)) return null;
  return Number.isInteger(num) ? String(num) : num.toFixed(digits);
};

const getEducationGradeLabel = (edu) => {
  if (!edu) return null;

  const type = String(edu.gradeType || '').trim().toLowerCase();
  const gradeValue = Number(edu.gradeValue);
  const cgpa = Number(edu.cgpa);
  const marksObtained = Number(edu.marksObtained);
  const totalMarks = Number(edu.totalMarks);

  if (type === 'percentage') {
    const raw = Number.isFinite(gradeValue)
      ? gradeValue
      : (Number.isFinite(cgpa) ? cgpa * 25 : NaN);
    const value = formatGradeValue(raw);
    return value ? `Percentage: ${value}%` : null;
  }

  if (type === 'marks') {
    if (Number.isFinite(marksObtained) && Number.isFinite(totalMarks) && totalMarks > 0) {
      return `Marks: ${formatGradeValue(marksObtained)}/${formatGradeValue(totalMarks)}`;
    }
    return null;
  }

  const cgpaValue = Number.isFinite(cgpa) ? cgpa : gradeValue;
  const value = formatGradeValue(cgpaValue);
  return value ? `CGPA: ${value}` : null;
};

// Helper: YouTube Thumbnail Component
const YouTubeThumbnail = ({ url, alt }) => {
  const videoId = getYouTubeId(url);
  const thumbnailUrl = videoId ? `https://img.youtube.com/vi/${videoId}/mqdefault.jpg` : null;

  if (thumbnailUrl) {
    return (
      <div className="relative h-48 w-full bg-black group overflow-hidden">
        <img src={thumbnailUrl} alt={alt} className="w-full h-full object-cover opacity-80 group-hover:opacity-60 transition-opacity" />
        <a href={url} target="_blank" rel="noreferrer" className="absolute inset-0 flex items-center justify-center">
          <PlayCircle size={48} className="text-white drop-shadow-lg transform group-hover:scale-110 transition-transform cursor-pointer" />
        </a>
      </div>
    );
  }
  // Fallback if not a YouTube link
  return <div className="h-4 w-full bg-gradient-to-r from-indigo-500 to-purple-600"></div>;
};

const StudentDetail = () => {
  const strongPasswordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$/;
  const { studentId } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [isNotifyModalOpen, setIsNotifyModalOpen] = useState(false);
  const [isEmailModalOpen, setIsEmailModalOpen] = useState(false);
  const [isEditingProfile, setIsEditingProfile] = useState(false);
  const [isEditingCredentials, setIsEditingCredentials] = useState(false);
  const [credentialsFormData, setCredentialsFormData] = useState({ email: '', password: '' });
  const [credentialsLoading, setCredentialsLoading] = useState(false);
  const [profileLoading, setProfileLoading] = useState(false);
  const [profileBanner, setProfileBanner] = useState(null);
  const [emailSending, setEmailSending] = useState(false);
  const [emailFormData, setEmailFormData] = useState({
    subject: '',
    body: ''
  });
  const profileFormRef = useRef(null);
  const credentialsFormRef = useRef(null);
  const credentialsPasswordInputRef = useRef(null);
  const [profileFormData, setProfileFormData] = useState({
    fullName: '',
    registrationNo: '',
    department: '',
    cgpa: '',
    phone: '',
    skills: ''
  });

  const handleBack = () => {
    const fromAnalytics = location?.state?.fromAnalytics;
    if (fromAnalytics?.jobFairId) {
      navigate('/admin/analytics', { state: fromAnalytics });
      return;
    }
    navigate(-1);
  };

  useEffect(() => {
    const fetchDetails = async () => {
      try {
        const res = await api.get(`/admin/students/${studentId}/details`);
        setData(res.data);
        setCredentialsFormData({ email: res.data.contactDetails?.email || '', password: '' });
        setProfileFormData({
          fullName: res.data.name || '',
          registrationNo: res.data.registrationNo || '',
          department: res.data.department || '',
          cgpa: res.data.cgpa ?? '',
          phone: res.data.contactDetails?.phone || '',
          skills: (res.data.skills || []).join(', ')
        });

        const editMode = new URLSearchParams(location.search).get('edit');
        if (editMode === 'profile') {
          setIsEditingProfile(true);
        }
      } catch (err) {
        toast.error("Failed to load profile");
        navigate('/admin/students');
      } finally {
        setLoading(false);
      }
    };
    fetchDetails();
  }, [studentId, navigate, location.search]);

  // Auto-scroll to profile form when opened
  useEffect(() => {
    if (isEditingProfile && profileFormRef.current) {
      profileFormRef.current.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }, [isEditingProfile]);

  // Auto-scroll and focus the password field when credentials editor opens
  useEffect(() => {
    if (!isEditingCredentials) return;
    if (credentialsFormRef.current) {
      credentialsFormRef.current.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
    if (credentialsPasswordInputRef.current) {
      credentialsPasswordInputRef.current.focus({ preventScroll: true });
      credentialsPasswordInputRef.current.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  }, [isEditingCredentials]);

  // Lock background scroll while email modal is open
  useEffect(() => {
    if (!isEmailModalOpen || typeof document === 'undefined') return;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, [isEmailModalOpen]);

  const handleSaveCredentials = async () => {
    try {
      setCredentialsLoading(true);
      const updateData = {};
      if (credentialsFormData.email.trim()) updateData.email = credentialsFormData.email.trim();
      if (credentialsFormData.password.trim()) {
        if (!strongPasswordRegex.test(credentialsFormData.password.trim())) {
          toast.error('Password must include uppercase, lowercase, number, special character and be at least 8 characters.');
          setCredentialsLoading(false);
          return;
        }
        updateData.password = credentialsFormData.password.trim();
      }

      if (Object.keys(updateData).length === 0) {
        toast.error('Please update at least one field');
        return;
      }

      await updateStudentCredentials(studentId, updateData);
      toast.success('Credentials updated successfully');
      setIsEditingCredentials(false);
      // Refresh the profile
      const res = await api.get(`/admin/students/${studentId}/details`);
      setData(res.data);
      setCredentialsFormData({ email: res.data.contactDetails?.email || '', password: '' });
    } catch (error) {
      console.error(error);
      const errorMsg = error.response?.data?.Message || 'Failed to update credentials';
      toast.error(errorMsg);
    } finally {
      setCredentialsLoading(false);
    }
  };

  const handleSaveProfile = async () => {
    try {
      setProfileLoading(true);
      const parsedCgpa = Number(profileFormData.cgpa);
      const skills = String(profileFormData.skills || '')
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);

      await api.put(`/admin/students/${studentId}/profile`, {
        fullName: profileFormData.fullName,
        registrationNo: profileFormData.registrationNo,
        department: profileFormData.department,
        cgpa: Number.isFinite(parsedCgpa) ? parsedCgpa : undefined,
        phone: profileFormData.phone,
        skills,
      });

      toast.success('Student profile updated successfully');
      setProfileBanner({ type: 'success', message: 'Student profile updated successfully.' });
      setIsEditingProfile(false);

      const res = await api.get(`/admin/students/${studentId}/details`);
      setData(res.data);
      setProfileFormData({
        fullName: res.data.name || '',
        registrationNo: res.data.registrationNo || '',
        department: res.data.department || '',
        cgpa: res.data.cgpa ?? '',
        phone: res.data.contactDetails?.phone || '',
        skills: (res.data.skills || []).join(', ')
      });
    } catch (error) {
      const errorMsg = error.response?.data?.Message || error.response?.data?.message || 'Failed to update student profile';
      toast.error(errorMsg);
      setProfileBanner({ type: 'error', message: String(errorMsg) });
    } finally {
      setProfileLoading(false);
    }
  };

  const openEmailModal = () => {
    setEmailFormData({
      subject: `Regarding Your Profile - ${data?.name || 'Student'}`,
      body: `\n\nRegards,\nCOMSATS University Islamabad Wah Campus Job Fair Team`
    });
    setIsEmailModalOpen(true);
  };

  const handleSendEmail = async () => {
    const subject = String(emailFormData.subject || '').trim();
    const body = String(emailFormData.body || '').trim();

    if (!subject || !body) {
      toast.error('Subject and email body are required.');
      return;
    }

    try {
      setEmailSending(true);
      await api.post(`/admin/students/${studentId}/send-email`, {
        subject,
        body,
      });
      toast.success('Email sent successfully');
      setIsEmailModalOpen(false);
    } catch (error) {
      const errorMsg = error.response?.data?.Message || error.response?.data?.message || 'Failed to send email';
      toast.error(errorMsg);
    } finally {
      setEmailSending(false);
    }
  };

  if (loading) return (
    <div className="flex flex-col items-center justify-center h-[80vh]">
      <div className="w-12 h-12 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin mb-4"></div>
      <p className="text-gray-500 font-medium">Loading Profile...</p>
    </div>
  );

  if (!data) return null;

  // Filter out FYP and any non-accepted/pending/rejected memberships from "Other Projects"
  const otherProjects = (data.allProjects || []).filter((p) => {
    const type = String(p.type || '').toLowerCase();
    const status = String(p.status || '').toLowerCase();
    const isAccepted = !status || status === 'accepted';
    return type !== 'finalyear' && isAccepted;
  });

  return (
    <div className="space-y-6 animate-fade-in max-w-7xl mx-auto pb-10 px-4 sm:px-6 lg:px-8">
      {profileBanner && (
        <div className={`rounded-lg border px-4 py-3 text-sm font-medium ${profileBanner.type === 'success' ? 'bg-emerald-50 border-emerald-200 text-emerald-800' : 'bg-red-50 border-red-200 text-red-800'}`}>
          {profileBanner.message}
        </div>
      )}
      
      {/* Back Button */}
      <button 
        onClick={handleBack}
        className="flex items-center gap-2 text-gray-600 hover:text-indigo-600 transition font-medium mt-6 mb-4"
      >
        <ArrowLeft size={20} /> Back to Directory
      </button>

      <div className="flex flex-col lg:flex-row gap-8 items-start">
        
        {/* -------------------------------------------------- */}
        {/* LEFT COLUMN: Sticky Sidebar                        */}
        {/* -------------------------------------------------- */}
        <div className="w-full lg:w-1/3 space-y-6 lg:sticky lg:top-8">
          
          {/* Profile Card */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-8 flex flex-col items-center text-center">
            <div className="w-32 h-32 rounded-full border-4 border-white shadow-lg overflow-hidden mb-6 bg-indigo-50 flex items-center justify-center">
              {data.profilePicUrl ? (
                <img src={getFileUrl(data.profilePicUrl)} alt={data.name} className="w-full h-full object-cover" />
              ) : (
                <span className="text-4xl font-bold text-indigo-300">{data.name?.charAt(0)}</span>
              )}
            </div>

            <h1 className="text-2xl font-bold text-gray-900">{data.name}</h1>
            <p className="text-indigo-600 font-medium mb-2">{data.registrationNo}</p>
            <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-600">
              {data.department}
            </span>

            {/* CGPA */}
            <div className="mt-8 w-full p-4 bg-gray-50 rounded-xl border border-gray-100 flex justify-between items-center">
              <span className="text-xs font-bold text-gray-400 uppercase tracking-wider">CGPA</span>
              <span className={`text-2xl font-bold ${data.cgpa >= 3.0 ? 'text-emerald-600' : 'text-gray-600'}`}>
                {data.cgpa?.toFixed(2)}
              </span>
            </div>

            {/* Action Buttons */}
            <div className="w-full mt-6 space-y-3">
              
              {/* EDIT CREDENTIALS BUTTON */}
              <button 
                onClick={() => setIsEditingProfile(true)}
                className="flex items-center justify-center gap-2 w-full py-2.5 bg-indigo-600 text-white rounded-lg text-sm font-semibold hover:bg-indigo-700 transition shadow-md shadow-indigo-200"
              >
                <Edit2 size={16} /> Edit Profile
              </button>

              {/* EDIT CREDENTIALS BUTTON */}
              <button 
                onClick={() => setIsEditingCredentials(true)}
                className="flex items-center justify-center gap-2 w-full py-2.5 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition shadow-md shadow-blue-200"
              >
                <Edit2 size={16} /> Edit Credentials
              </button>

              {/* NOTIFY BUTTON */}
              <button 
                onClick={() => setIsNotifyModalOpen(true)}
                className="flex items-center justify-center gap-2 w-full py-2.5 bg-amber-500 text-white rounded-lg text-sm font-semibold hover:bg-amber-600 transition shadow-md shadow-amber-200"
              >
                <Bell size={16} /> Send Notification
              </button>

              <button
                onClick={openEmailModal}
                className="flex items-center justify-center gap-2 w-full py-2.5 bg-indigo-600 text-white rounded-lg text-sm font-semibold hover:bg-indigo-700 transition shadow-md shadow-indigo-200"
              >
                <Mail size={16} /> Send Email
              </button>

              {(data.cvUrl || data.CvUrl) && (
                <a
                  href={getFileUrl(data.cvUrl || data.CvUrl)}
                  target="_blank"
                  rel="noreferrer"
                  className="flex items-center justify-center gap-2 w-full py-2.5 bg-white border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 transition"
                >
                  <Award size={16} /> Download CV
                </a>
              )}
              
              {data.contactDetails?.phone && (
                <div className="flex items-center justify-center gap-2 w-full py-2.5 bg-white border border-gray-300 rounded-lg text-sm font-medium text-gray-700">
                  <Phone size={16} /> {data.contactDetails.phone}
                </div>
              )}
            </div>

            {/* Social Icons */}
            <div className="flex gap-4 mt-6 justify-center">
              {data.links && Object.entries(data.links).map(([platform, url]) => (
                <a key={platform} href={url} target="_blank" rel="noreferrer" className="text-gray-400 hover:text-indigo-600 hover:scale-110 transition">
                  {platform.toLowerCase().includes('linkedin') && <Linkedin size={20} />}
                  {platform.toLowerCase().includes('github') && <Github size={20} />}
                  {platform.toLowerCase().includes('portfolio') && <Globe size={20} />}
                  {platform.toLowerCase().includes('facebook') && <Globe size={20} />}
                </a>
              ))}
            </div>
          </div>

          {/* Edit Credentials Modal */}
          {isEditingProfile && (
            <div ref={profileFormRef} className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-bold text-gray-900">Edit Student Profile</h3>
                <button
                  onClick={() => setIsEditingProfile(false)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  <X size={20} />
                </button>
              </div>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
                  <input
                    type="text"
                    value={profileFormData.fullName}
                    onChange={(e) => setProfileFormData({ ...profileFormData, fullName: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
                  />
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Registration No</label>
                    <input
                      type="text"
                      value={profileFormData.registrationNo}
                      onChange={(e) => setProfileFormData({ ...profileFormData, registrationNo: e.target.value })}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Department</label>
                    <input
                      type="text"
                      value={profileFormData.department}
                      onChange={(e) => setProfileFormData({ ...profileFormData, department: e.target.value })}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">CGPA</label>
                    <input
                      type="number"
                      step="0.01"
                      min="0"
                      max="4"
                      value={profileFormData.cgpa}
                      onChange={(e) => setProfileFormData({ ...profileFormData, cgpa: e.target.value })}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
                    <input
                      type="text"
                      value={profileFormData.phone}
                      onChange={(e) => setProfileFormData({ ...profileFormData, phone: e.target.value })}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Skills (comma separated)</label>
                  <textarea
                    rows="3"
                    value={profileFormData.skills}
                    onChange={(e) => setProfileFormData({ ...profileFormData, skills: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
                  />
                </div>

                <div className="flex gap-3 pt-2">
                  <button
                    onClick={handleSaveProfile}
                    disabled={profileLoading}
                    className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-60 font-medium transition"
                  >
                    <Save size={16} /> Save Profile
                  </button>
                  <button
                    onClick={() => setIsEditingProfile(false)}
                    className="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 font-medium transition"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* Edit Credentials Modal */}
          {isEditingCredentials && (
            <div ref={credentialsFormRef} className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-bold text-gray-900">Edit Credentials</h3>
                <button
                  onClick={() => setIsEditingCredentials(false)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  <X size={20} />
                </button>
              </div>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                  <input
                    type="email"
                    value={credentialsFormData.email}
                    onChange={(e) => setCredentialsFormData({ ...credentialsFormData, email: e.target.value })}
                    placeholder="Leave empty to keep current"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">New Password</label>
                  <input
                    ref={credentialsPasswordInputRef}
                    type="password"
                    value={credentialsFormData.password}
                    onChange={(e) => setCredentialsFormData({ ...credentialsFormData, password: e.target.value })}
                    placeholder="Leave empty to keep current"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition"
                  />
                </div>

                <div className="flex gap-3 pt-2">
                  <button
                    onClick={handleSaveCredentials}
                    disabled={credentialsLoading}
                    className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-60 font-medium transition"
                  >
                    <Save size={16} /> Save Changes
                  </button>
                  <button
                    onClick={() => {
                      setIsEditingCredentials(false);
                      setCredentialsFormData({ email: data.contactDetails?.email || '', password: '' });
                    }}
                    className="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 font-medium transition"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* Skills Card */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
            <h3 className="text-sm font-bold text-gray-900 uppercase mb-4 tracking-wider">Skills & Expertise</h3>
            <div className="flex flex-wrap gap-2">
              {data.skills?.map(skill => (
                <span key={skill} className="px-3 py-1.5 bg-gray-50 border border-gray-100 text-gray-700 text-sm font-medium rounded-lg">
                  {skill}
                </span>
              ))}
            </div>
          </div>
        </div>

        {/* -------------------------------------------------- */}
        {/* RIGHT COLUMN: Content Feed                         */}
        {/* -------------------------------------------------- */}
        <div className="w-full lg:w-2/3 space-y-8">

          {/* 1. Final Year Project */}
          {data.finalYearProject && (
            <section className="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden">
              <div className="p-6 border-b border-gray-100 bg-gray-50 flex items-center gap-2">
                <Award className="text-amber-500" size={20} />
                <h2 className="text-lg font-bold text-gray-900">Final Year Project</h2>
              </div>

              {/* Video Thumbnail */}
              <YouTubeThumbnail url={data.finalYearProject.demoUrl} alt="FYP Demo" />

              <div className="p-8">
                <div className="flex justify-between items-start mb-4">
                  <h3 className="text-2xl font-bold text-gray-900">{data.finalYearProject.title}</h3>
                  {data.finalYearProject.gitHubUrl && (
                    <a href={data.finalYearProject.gitHubUrl} target="_blank" rel="noreferrer" className="flex items-center gap-1 text-sm font-medium text-gray-600 hover:text-indigo-600">
                      <Github size={16} /> Repository
                    </a>
                  )}
                </div>

                <p className="text-gray-600 leading-relaxed mb-6">
                  {data.finalYearProject.description}
                </p>

                {/* Team Members */}
                {data.finalYearProject.partners?.length > 0 && (
                  <div>
                    <h4 className="text-xs font-bold text-gray-400 uppercase mb-3">Project Team</h4>
                    <div className="flex flex-wrap gap-3">
                      {data.finalYearProject.partners.map(p => (
                        <div key={p.studentId} className="flex items-center gap-2 pr-4 py-1.5 pl-1.5 bg-gray-50 border rounded-full text-sm text-gray-700">
                          <div className="w-6 h-6 rounded-full bg-gray-200 flex items-center justify-center text-xs font-bold text-gray-500">
                            {p.name.charAt(0)}
                          </div>
                          {p.name} <span className="text-xs text-gray-400">({p.role})</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </section>
          )}

          {/* 2. Other Projects */}
          {otherProjects.length > 0 && (
             <section>
              <div className="flex items-center gap-2 mb-4">
                <div className="p-2 bg-pink-50 text-pink-600 rounded-lg"><Layers size={20} /></div>
                <h2 className="text-xl font-bold text-gray-900">Other Projects</h2>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {otherProjects.map((project) => (
                  <div key={project.projectId} className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden hover:shadow-md transition">
                    <YouTubeThumbnail url={project.demoUrl} alt={project.title} />
                    <div className="p-5">
                      <div className="flex justify-between items-start mb-2">
                         <h4 className="font-bold text-gray-900 line-clamp-1" title={project.title}>{project.title}</h4>
                         <span className="px-2 py-0.5 bg-gray-100 text-gray-600 text-[10px] font-bold uppercase rounded">{project.type}</span>
                      </div>
                      <p className="text-sm text-gray-600 line-clamp-3 mb-4 h-16">
                        {project.description}
                      </p>
                      <div className="flex gap-3 text-sm font-medium">
                         {project.demoUrl && (
                           <a href={project.demoUrl} target="_blank" rel="noreferrer" className="text-indigo-600 hover:underline flex items-center gap-1">
                             <PlayCircle size={14} /> Demo
                           </a>
                         )}
                         {project.gitHubUrl && (
                           <a href={project.gitHubUrl} target="_blank" rel="noreferrer" className="text-gray-600 hover:text-black flex items-center gap-1">
                             <Github size={14} /> Code
                           </a>
                         )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
             </section>
          )}

          {/* 3. Experience & Education Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            
            {/* Experience */}
            <section className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
              <div className="flex items-center gap-2 mb-6">
                <div className="p-2 bg-blue-50 text-blue-600 rounded-lg"><Briefcase size={20} /></div>
                <h2 className="text-lg font-bold text-gray-900">Experience</h2>
              </div>
              <div className="space-y-6 pl-2">
                {data.experiences?.length > 0 ? data.experiences.map((exp, idx) => (
                  <div key={idx} className="relative pl-6 border-l-2 border-gray-200 last:border-0 pb-2">
                    <div className="absolute -left-[9px] top-1.5 w-4 h-4 rounded-full border-4 border-white bg-blue-500 shadow-sm"></div>
                    <h5 className="font-bold text-gray-900 text-sm">{exp.role}</h5>
                    <p className="text-xs font-semibold text-indigo-600 mb-1">{exp.companyName}</p>
                    <p className="text-xs text-gray-400 mb-2">
                       {new Date(exp.startDate).getFullYear()} - {exp.isCurrent ? 'Present' : new Date(exp.endDate).getFullYear()}
                    </p>
                    <p className="text-xs text-gray-600 line-clamp-3">{exp.description}</p>
                  </div>
                )) : (
                  <p className="text-gray-400 italic text-sm text-center">No experience added.</p>
                )}
              </div>
            </section>

            {/* Education */}
            <section className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
               <div className="flex items-center gap-2 mb-6">
                <div className="p-2 bg-purple-50 text-purple-600 rounded-lg"><GraduationCap size={20} /></div>
                <h2 className="text-lg font-bold text-gray-900">Education</h2>
              </div>
              <div className="space-y-4">
                {data.educations?.length > 0 ? data.educations.map((edu, idx) => (
                  <div key={idx} className="pb-4 border-b border-gray-100 last:border-0">
                    <h5 className="font-bold text-gray-900 text-sm">{edu.degree}</h5>
                    <p className="text-xs text-gray-600 mb-1">{edu.institutionName}</p>
                    {getEducationGradeLabel(edu) && (
                      <p className="text-xs font-semibold text-indigo-600 mb-1">{getEducationGradeLabel(edu)}</p>
                    )}
                    <div className="flex justify-between items-center text-xs">
                       <span className="text-gray-400">{new Date(edu.startDate).getFullYear()} - {edu.isCurrent ? 'Present' : new Date(edu.endDate).getFullYear()}</span>
                    </div>
                  </div>
                )) : <p className="text-gray-400 italic text-sm text-center">No education listed.</p>}
              </div>
            </section>
          </div>

          {/* 4. Achievements */}
          <section className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
             <div className="flex items-center gap-2 mb-6">
              <div className="p-2 bg-emerald-50 text-emerald-600 rounded-lg"><Award size={20} /></div>
              <h2 className="text-lg font-bold text-gray-900">Achievements & Certifications</h2>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Certifications */}
              {data.certifications?.map((cert, idx) => (
                 <div key={`cert-${idx}`} className="p-3 bg-gray-50 rounded-lg border border-gray-100">
                    <h5 className="font-bold text-gray-900 text-sm">{cert.title}</h5>
                    <p className="text-xs text-gray-500 mt-1">Issued by {cert.issuer}</p>
                    {cert.credentialUrl && (
                      <a href={cert.credentialUrl} target="_blank" rel="noreferrer" className="text-xs text-indigo-600 hover:underline mt-2 inline-block">View Credential</a>
                    )}
                 </div>
              ))}
              
              {/* Other Achievements */}
              {data.achievements?.map((ach, idx) => (
                 <div key={`ach-${idx}`} className="p-3 bg-gray-50 rounded-lg border border-gray-100">
                    <h5 className="font-bold text-gray-900 text-sm">{ach.title}</h5>
                    <p className="text-xs text-gray-500 mt-1 line-clamp-2">{ach.description}</p>
                 </div>
              ))}

              {(!data.certifications?.length && !data.achievements?.length) && (
                 <p className="text-gray-400 italic text-sm col-span-2 text-center">No achievements listed.</p>
              )}
            </div>
          </section>

        </div>
      </div>

      {/* Notification Modal */}
      <SendNotificationModal 
        isOpen={isNotifyModalOpen} 
        onClose={() => setIsNotifyModalOpen(false)}
        recipientId={data.studentId}
        recipientName={data.name}
        type="student"
      />

      {isEmailModalOpen && typeof document !== 'undefined' && createPortal((
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-2xl overflow-hidden animate-fade-in">
            <div className="px-6 py-4 border-b flex justify-between items-center bg-gray-50">
              <h3 className="font-bold text-gray-900">Send Email to Student</h3>
              <button onClick={() => setIsEmailModalOpen(false)} className="text-gray-400 hover:text-gray-600">
                <X size={20} />
              </button>
            </div>

            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">To</label>
                <div className="w-full px-4 py-2 border border-gray-200 bg-gray-50 rounded-lg text-sm text-gray-700">
                  {data?.contactDetails?.email || 'No email'}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Subject</label>
                <input
                  type="text"
                  value={emailFormData.subject}
                  onChange={(e) => setEmailFormData({ ...emailFormData, subject: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email Body</label>
                <textarea
                  rows="10"
                  value={emailFormData.body}
                  onChange={(e) => setEmailFormData({ ...emailFormData, body: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none resize-y"
                />
              </div>
            </div>

            <div className="px-6 py-4 border-t bg-gray-50 flex justify-end gap-3">
              <button
                onClick={() => setIsEmailModalOpen(false)}
                className="px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded-lg"
                disabled={emailSending}
              >
                Cancel
              </button>
              <button
                onClick={handleSendEmail}
                className="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg disabled:opacity-60"
                disabled={emailSending}
              >
                {emailSending ? 'Sending...' : 'Send Email'}
              </button>
            </div>
          </div>
        </div>
      ), document.body)}
    </div>
  );
};

export default StudentDetail;