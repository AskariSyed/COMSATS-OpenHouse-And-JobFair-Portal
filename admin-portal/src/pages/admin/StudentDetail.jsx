/* eslint-disable no-unused-vars */
import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { 
  ArrowLeft, Mail, Phone, Globe, Github, Linkedin, 
  Briefcase, Award, GraduationCap, PlayCircle, ExternalLink,
  Layers, Bell, Edit2, Save, X
} from 'lucide-react';
import { toast } from 'react-hot-toast';
import SendNotificationModal from '../../lib/components/SendNotificationModal';
import api, { BACKEND_URL, updateStudentCredentials } from '../../lib/api';


const getImageUrl = (path) => {
  if (!path) return null;
  if (path.startsWith('http')) return path; 
  // Now it uses the central configuration
  return `${BACKEND_URL}${path}`; 
};

// Helper: Extract YouTube ID
const getYouTubeId = (url) => {
  if (!url) return null;
  const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*/;
  const match = url.match(regExp);
  return (match && match[2].length === 11) ? match[2] : null;
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
  const { studentId } = useParams();
  const navigate = useNavigate();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [isNotifyModalOpen, setIsNotifyModalOpen] = useState(false);
  const [isEditingCredentials, setIsEditingCredentials] = useState(false);
  const [credentialsFormData, setCredentialsFormData] = useState({ email: '', password: '' });
  const [credentialsLoading, setCredentialsLoading] = useState(false);

  useEffect(() => {
    const fetchDetails = async () => {
      try {
        const res = await api.get(`/admin/students/${studentId}/details`);
        setData(res.data);
        setCredentialsFormData({ email: res.data.contactDetails?.email || '', password: '' });
      } catch (err) {
        toast.error("Failed to load profile");
        navigate('/admin/students');
      } finally {
        setLoading(false);
      }
    };
    fetchDetails();
  }, [studentId, navigate]);

  const handleSaveCredentials = async () => {
    try {
      setCredentialsLoading(true);
      const updateData = {};
      if (credentialsFormData.email.trim()) updateData.email = credentialsFormData.email.trim();
      if (credentialsFormData.password.trim()) updateData.password = credentialsFormData.password.trim();

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

  if (loading) return (
    <div className="flex flex-col items-center justify-center h-[80vh]">
      <div className="w-12 h-12 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin mb-4"></div>
      <p className="text-gray-500 font-medium">Loading Profile...</p>
    </div>
  );

  if (!data) return null;

  // Filter out FYP from "Other Projects"
  const otherProjects = data.allProjects?.filter(p => p.type !== 'FinalYear') || [];

  return (
    <div className="space-y-6 animate-fade-in max-w-7xl mx-auto pb-10 px-4 sm:px-6 lg:px-8">
      
      {/* Back Button */}
      <button 
        onClick={() => navigate(-1)}
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
                <img src={getImageUrl(data.profilePicUrl)} alt={data.name} className="w-full h-full object-cover" />
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

              <a href={`mailto:${data.contactDetails?.email}`} className="flex items-center justify-center gap-2 w-full py-2.5 bg-indigo-600 text-white rounded-lg text-sm font-semibold hover:bg-indigo-700 transition shadow-md shadow-indigo-200">
                <Mail size={16} /> Send Email
              </a>

              {(data.cvUrl || data.CvUrl) && (
                <a
                  href={getImageUrl(data.cvUrl || data.CvUrl)}
                  target="_blank"
                  rel="noreferrer"
                  className="flex items-center justify-center gap-2 w-full py-2.5 bg-white border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 transition"
                >
                  <Award size={16} /> Download CV
                </a>
              )}
              
              {data.contactDetails?.phone && (
                <a href={`tel:${data.contactDetails?.phone}`} className="flex items-center justify-center gap-2 w-full py-2.5 bg-white border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 transition">
                  <Phone size={16} /> Call Student
                </a>
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
          {isEditingCredentials && (
            <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
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
                    <div className="flex justify-between items-center text-xs">
                       <span className="text-gray-400">{new Date(edu.startDate).getFullYear()} - {new Date(edu.endDate).getFullYear()}</span>
                       {edu.cgpa > 0 && <span className="font-bold text-indigo-600">CGPA: {edu.cgpa}</span>}
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
        studentId={data.studentId}
        studentName={data.name}
      />
    </div>
  );
};

export default StudentDetail;