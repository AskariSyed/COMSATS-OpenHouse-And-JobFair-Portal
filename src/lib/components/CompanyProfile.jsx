/* eslint-disable react-hooks/set-state-in-effect */
/* eslint-disable no-unused-vars */
import React, { useEffect, useState } from 'react';
import { Building2, MapPin, Globe, Phone, Mail, User, Edit2, Plus, Trash2, Briefcase, Users, CheckCircle, Link as LinkIcon, X, Loader2, Save, Clock } from 'lucide-react';
import { getCompanyProfile, updateCompanyProfile, createJob, updateJob, deleteJob, addContactLink, deleteContactLink, getFileUrl } from '../api';

export default function CompanyProfile({ onError }) {
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refreshKey, setRefreshKey] = useState(0);

  // Modals
  const [showProfileModal, setShowProfileModal] = useState(false);
  const [showJobModal, setShowJobModal] = useState(false);
  const [editingJob, setEditingJob] = useState(null);

  useEffect(() => {
    setLoading(true);
    getCompanyProfile()
      .then(data => setProfile(data))
      .catch(err => onError(err.message))
      .finally(() => setLoading(false));
  }, [refreshKey, onError]);

  if (loading) return <div className="h-96 flex items-center justify-center"><Loader2 className="animate-spin w-8 h-8 text-blue-600" /></div>;
  if (!profile) return <div className="text-center p-12 text-red-500">Profile not found.</div>;

  // --- HANDLERS ---
  const handleLinkDelete = async (id) => {
    if(confirm('Remove this link?')) {
      try { await deleteContactLink(id); setRefreshKey(k => k+1); } catch(e) { onError(e.message); }
    }
  };

  const handleJobDelete = async (id) => {
    if(confirm('Delete this job posting?')) {
      try { await deleteJob(id); setRefreshKey(k => k+1); } catch(e) { onError(e.message); }
    }
  };

  const { contactInfo, focalPerson, interviewStats, jobs } = profile;

  return (
    <div className="max-w-6xl mx-auto animate-fade-in pb-10">
      
      {/* --- HEADER SECTION --- */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden mb-8">
        {/* Gradient Cover */}
        <div className="h-40 bg-gradient-to-r from-slate-900 via-slate-800 to-blue-900 relative">
           <button 
             onClick={() => setShowProfileModal(true)} 
             className="absolute top-6 right-6 bg-white/10 hover:bg-white/20 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2 transition-colors backdrop-blur-sm"
           >
              <Edit2 className="w-4 h-4" /> Edit Profile
           </button>
        </div>

        <div className="px-8 pb-8 relative">
          {/* Logo (Overlapping) */}
          <div className="absolute -top-16 left-8 w-32 h-32 rounded-2xl p-1.5 bg-white shadow-lg">
            <div className="w-full h-full rounded-xl overflow-hidden bg-gray-50 border border-gray-100 flex items-center justify-center">
                {profile.logoUrl ? (
                    <img src={getFileUrl(profile.logoUrl)} className="w-full h-full object-contain" alt="Logo" />
                ) : (
                    <span className="text-4xl font-bold text-slate-300">{profile.name?.charAt(0)}</span>
                )}
            </div>
          </div>

          {/* Info Row */}
          <div className="ml-36 pt-3 min-h-[60px] flex flex-col justify-center">
             <h1 className="text-3xl font-bold text-gray-900">{profile.name}</h1>
             <div className="flex flex-wrap gap-4 text-sm text-gray-500 mt-1">
               <span className="flex items-center gap-1.5"><Building2 className="w-4 h-4 text-blue-500"/> {profile.industry}</span>
               <span className="flex items-center gap-1.5"><MapPin className="w-4 h-4 text-blue-500"/> {profile.address}</span>
               {profile.website && (
                 <a href={profile.website} target="_blank" rel="noreferrer" className="flex items-center gap-1.5 text-blue-600 hover:underline">
                   <Globe className="w-4 h-4"/> Website
                 </a>
               )}
             </div>
          </div>
        </div>
      </div>

      {/* --- STATS GRID --- */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
         <StatCard label="Active Jobs" value={jobs.jobs.length} icon={Briefcase} color="blue" />
         <StatCard label="Candidates" value={interviewStats.totalInterviews} icon={Users} color="purple" />
         <StatCard label="Hired" value={interviewStats.hiredCandidates} icon={CheckCircle} color="green" />
         <StatCard label="Pending Requests" value={interviewStats.pendingRequests} icon={Clock} color="orange" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* --- LEFT COLUMN: DETAILS --- */}
        <div className="space-y-6">
            {/* Contact Info */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
                <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2 border-b border-gray-100 pb-3">
                    <User className="w-5 h-5 text-blue-600" /> Focal Person
                </h3>
                <div className="space-y-3 text-sm">
                    <div>
                        <p className="text-gray-500 text-xs uppercase font-bold">Name</p>
                        <p className="font-medium text-gray-900">{focalPerson.name}</p>
                    </div>
                    <div>
                        <p className="text-gray-500 text-xs uppercase font-bold">Email</p>
                        <a href={`mailto:${focalPerson.email}`} className="text-blue-600 hover:underline">{focalPerson.email}</a>
                    </div>
                    <div>
                        <p className="text-gray-500 text-xs uppercase font-bold">Direct Phone</p>
                        <p className="text-gray-700">{focalPerson.phone}</p>
                    </div>
                </div>
            </div>

            {/* Official Contact */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
                <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2 border-b border-gray-100 pb-3">
                    <Phone className="w-5 h-5 text-blue-600" /> Official Contact
                </h3>
                <div className="space-y-3 text-sm">
                    <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-blue-50 flex items-center justify-center text-blue-600"><Mail className="w-4 h-4"/></div>
                        <div className="overflow-hidden">
                            <p className="text-xs text-gray-500">Email</p>
                            <p className="font-medium text-gray-900 truncate">{contactInfo.email}</p>
                        </div>
                    </div>
                    <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-blue-50 flex items-center justify-center text-blue-600"><Phone className="w-4 h-4"/></div>
                        <div>
                            <p className="text-xs text-gray-500">Phone</p>
                            <p className="font-medium text-gray-900">{contactInfo.phone}</p>
                        </div>
                    </div>
                </div>
            </div>

            {/* Social Links */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-200">
                <div className="flex justify-between items-center mb-4 border-b border-gray-100 pb-3">
                    <h3 className="font-bold text-gray-900 flex items-center gap-2"><LinkIcon className="w-5 h-5 text-blue-600"/> Social Links</h3>
                    <AddLinkButton onAdd={async (link) => { try { await addContactLink(link); setRefreshKey(k=>k+1); } catch(e){ onError(e.message); } }} />
                </div>
                <div className="flex flex-wrap gap-2">
                    {profile.socialLinks.map(link => (
                        <div key={link.linkId} className="flex items-center gap-2 px-3 py-1.5 bg-gray-50 border border-gray-200 rounded-lg text-xs transition-colors hover:bg-gray-100">
                            <Globe className="w-3 h-3 text-gray-400"/>
                            <a href={link.url} target="_blank" rel="noreferrer" className="hover:text-blue-600 font-medium text-gray-700">{link.platform}</a>
                            <button onClick={() => handleLinkDelete(link.linkId)} className="text-gray-400 hover:text-red-500 ml-1"><X className="w-3 h-3"/></button>
                        </div>
                    ))}
                    {profile.socialLinks.length === 0 && <p className="text-sm text-gray-400 italic">No links added.</p>}
                </div>
            </div>
        </div>

        {/* --- RIGHT COLUMN: JOBS --- */}
        <div className="lg:col-span-2">
            <div className="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden">
                <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                    <div>
                        <h2 className="text-xl font-bold text-gray-900">Job Postings</h2>
                        <p className="text-sm text-gray-500">Manage your open positions</p>
                    </div>
                    <button onClick={() => { setEditingJob(null); setShowJobModal(true); }} className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-bold hover:bg-blue-700 shadow-md transition-all transform hover:-translate-y-0.5">
                        <Plus className="w-4 h-4" /> Post Job
                    </button>
                </div>
                
                <div className="p-6 space-y-4">
                    {jobs.jobs.length === 0 ? (
                        <div className="text-center py-12 border-2 border-dashed border-gray-200 rounded-xl">
                            <Briefcase className="w-12 h-12 mx-auto mb-3 text-gray-300" />
                            <p className="text-gray-500 font-medium">No active job postings.</p>
                            <p className="text-sm text-gray-400">Create a job to start recruiting.</p>
                        </div>
                    ) : (
                        jobs.jobs.map(job => (
                            <div key={job.jobId} className="group bg-white border border-gray-200 rounded-xl p-5 hover:shadow-md hover:border-blue-300 transition-all relative">
                                <div className="flex justify-between items-start mb-2">
                                    <div>
                                        <h3 className="font-bold text-lg text-gray-900 group-hover:text-blue-600 transition-colors">{job.jobTitle}</h3>
                                        <div className="flex gap-2 mt-1">
                                            <span className="text-[10px] font-bold bg-blue-50 text-blue-700 px-2 py-0.5 rounded border border-blue-100 uppercase tracking-wide">
                                                {['Full Time','Internship','Part Time'][job.jobType]}
                                            </span>
                                            <span className="text-[10px] font-bold bg-gray-100 text-gray-600 px-2 py-0.5 rounded border border-gray-200">
                                                {job.numberOfJobs} Openings
                                            </span>
                                        </div>
                                    </div>
                                    <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                        <button onClick={() => { setEditingJob(job); setShowJobModal(true); }} className="p-2 hover:bg-gray-100 rounded-lg text-gray-500 hover:text-blue-600 transition-colors"><Edit2 className="w-4 h-4"/></button>
                                        <button onClick={() => handleJobDelete(job.jobId)} className="p-2 hover:bg-red-50 rounded-lg text-gray-500 hover:text-red-600 transition-colors"><Trash2 className="w-4 h-4"/></button>
                                    </div>
                                </div>
                                
                                <p className="text-sm text-gray-600 line-clamp-2 mb-3 leading-relaxed">{job.jobDescription}</p>
                                
                                <div className="flex flex-wrap gap-1.5">
                                    {job.requiredSkills?.slice(0, 4).map((s, i) => (
                                        <span key={i} className="text-xs bg-gray-50 text-gray-700 border border-gray-200 px-2 py-1 rounded-md font-medium">{s}</span>
                                    ))}
                                    {job.requiredSkills?.length > 4 && <span className="text-xs text-gray-400 flex items-center px-1">+{job.requiredSkills.length-4}</span>}
                                </div>
                            </div>
                        ))
                    )}
                </div>
            </div>
        </div>

      </div>

      {/* --- MODALS --- */}
      {showProfileModal && <ProfileModal profile={profile} onClose={() => setShowProfileModal(false)} onSave={async () => { setRefreshKey(k => k+1); setShowProfileModal(false); }} onError={onError} />}
      
      {showJobModal && <JobModal job={editingJob} onClose={() => setShowJobModal(false)} onSave={async () => { setRefreshKey(k => k+1); setShowJobModal(false); }} onError={onError} />}

    </div>
  );
}

// --- SUB-COMPONENTS ---

function StatCard({ label, value, icon: Icon, color }) {
  const colors = { blue: 'bg-blue-50 text-blue-600', purple: 'bg-purple-50 text-purple-600', green: 'bg-green-50 text-green-600', orange: 'bg-orange-50 text-orange-600' };
  return (
    <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-sm flex items-center gap-4 hover:shadow-md transition-shadow">
      <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${colors[color]}`}><Icon className="w-6 h-6"/></div>
      <div><div className="text-2xl font-bold text-gray-900 leading-none mb-1">{value}</div><div className="text-xs text-gray-500 uppercase font-bold tracking-wide">{label}</div></div>
    </div>
  );
}

function AddLinkButton({ onAdd }) {
  const [isOpen, setIsOpen] = useState(false);
  const [data, setData] = useState({ platform: 0, url: '' });
  
  const handleSubmit = () => {
    if(data.url) { onAdd(data); setIsOpen(false); setData({ platform: 0, url: '' }); }
  };

  if(!isOpen) return <button onClick={() => setIsOpen(true)} className="text-xs bg-blue-50 text-blue-600 px-2 py-1 rounded-lg font-bold hover:bg-blue-100 transition-colors flex items-center gap-1"><Plus className="w-3 h-3"/> Add Link</button>;

  return (
    <div className="flex items-center gap-2 animate-fade-in bg-white border border-gray-200 rounded-lg p-1.5 absolute right-6 z-10 shadow-xl">
       <select className="text-xs border border-gray-300 rounded p-1.5 outline-none focus:border-blue-500 bg-white" value={data.platform} onChange={e => setData({...data, platform: parseInt(e.target.value)})}>
         <option value={0}>LinkedIn</option><option value={1}>Website</option><option value={2}>Facebook</option><option value={3}>Twitter</option>
       </select>
       <input className="text-xs border border-gray-300 rounded p-1.5 w-32 outline-none focus:border-blue-500" placeholder="https://..." value={data.url} onChange={e => setData({...data, url: e.target.value})} />
       <button onClick={handleSubmit} className="bg-green-500 text-white p-1.5 rounded hover:bg-green-600"><CheckCircle className="w-3 h-3"/></button>
       <button onClick={() => setIsOpen(false)} className="text-red-400 hover:text-red-600 p-1"><X className="w-3 h-3"/></button>
    </div>
  );
}

function ProfileModal({ profile, onClose, onSave, onError }) {
  const [formData, setFormData] = useState({ ...profile, Logo: null });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const data = new FormData();
      data.append('CompanyEmail', formData.contactInfo.email);
      data.append('CompanyPhone', formData.contactInfo.phone);
      data.append('Website', formData.website || '');
      data.append('Address', formData.address);
      if(formData.Logo) data.append('Logo', formData.Logo);
      
      await updateCompanyProfile(data);
      onSave();
    } catch (err) { onError(err.message); } finally { setLoading(false); }
  };

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden animate-fade-in-down">
        <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
           <h3 className="text-lg font-bold text-gray-900">Edit Company Profile</h3>
           <button onClick={onClose}><X className="w-5 h-5 text-gray-400 hover:text-gray-600"/></button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-5">
           <Input label="Official Email" value={formData.contactInfo.email} onChange={e => setFormData({...formData, contactInfo: {...formData.contactInfo, email: e.target.value}})} />
           <Input label="Official Phone" value={formData.contactInfo.phone} onChange={e => setFormData({...formData, contactInfo: {...formData.contactInfo, phone: e.target.value}})} />
           <Input label="Website URL" value={formData.website} onChange={e => setFormData({...formData, website: e.target.value})} />
           <Input label="Headquarters Address" value={formData.address} onChange={e => setFormData({...formData, address: e.target.value})} />
           
           <div className="pt-2">
              <label className="block text-xs font-bold text-gray-500 uppercase mb-2">Update Logo</label>
              <div className="flex items-center justify-center w-full">
                  <label className="flex flex-col items-center justify-center w-full h-32 border-2 border-gray-300 border-dashed rounded-lg cursor-pointer bg-gray-50 hover:bg-gray-100 transition-colors">
                      <div className="flex flex-col items-center justify-center pt-5 pb-6">
                          <p className="mb-2 text-sm text-gray-500"><span className="font-semibold">Click to upload</span> or drag and drop</p>
                          <p className="text-xs text-gray-500">PNG, JPG (MAX. 2MB)</p>
                          {formData.Logo && <p className="mt-2 text-sm text-blue-600 font-bold">{formData.Logo.name}</p>}
                      </div>
                      <input type="file" className="hidden" onChange={e => setFormData({...formData, Logo: e.target.files[0]})} />
                  </label>
              </div> 
           </div>

           <div className="pt-4 flex gap-3">
              <button type="button" onClick={onClose} className="flex-1 py-3 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-xl font-bold transition-colors">Cancel</button>
              <button disabled={loading} className="flex-1 py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 flex justify-center gap-2 transition-colors shadow-lg shadow-blue-200">
                 {loading ? <Loader2 className="animate-spin w-5 h-5"/> : 'Save Changes'}
              </button>
           </div>
        </form>
      </div>
    </div>
  );
}

function JobModal({ job, onClose, onSave, onError }) {
  const [formData, setFormData] = useState(job || { JobTitle: '', JobDescription: '', JobCount: 1, JobType: 0, RequiredSkills: [] });
  const [skillInput, setSkillInput] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const payload = {
         JobTitle: formData.JobTitle || formData.jobTitle,
         JobDescription: formData.JobDescription || formData.jobDescription,
         NumberOfJobs: formData.NumberOfJobs || formData.numberOfJobs || 1,
         JobType: formData.JobType || formData.jobType || 0,
         RequiredSkills: formData.RequiredSkills || formData.requiredSkills || []
      };
      
      if (job) await updateJob(job.jobId, payload);
      else await createJob(payload);
      
      onSave();
    } catch (err) { onError(err.message); } finally { setLoading(false); }
  };

  const addSkill = (e) => {
    e.preventDefault();
    if(skillInput) {
       const skills = formData.RequiredSkills || formData.requiredSkills || [];
       setFormData({...formData, RequiredSkills: [...skills, skillInput]});
       setSkillInput('');
    }
  };

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden animate-fade-in-down">
        <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
           <h3 className="text-lg font-bold text-gray-900">{job ? 'Edit Job Posting' : 'Create New Job'}</h3>
           <button onClick={onClose}><X className="w-5 h-5 text-gray-400 hover:text-gray-600"/></button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-5">
           <Input label="Job Title" placeholder="e.g. Software Engineer" value={formData.JobTitle || formData.jobTitle || ''} onChange={e => setFormData({...formData, JobTitle: e.target.value})} />
           
           <div className="flex gap-4">
              <div className="flex-1">
                 <label className="block text-xs font-bold text-gray-500 uppercase mb-1.5">Positions</label>
                 <input type="number" min="1" className="w-full border border-gray-300 rounded-lg p-2.5 outline-none focus:ring-2 focus:ring-blue-500" value={formData.NumberOfJobs || formData.numberOfJobs || 1} onChange={e => setFormData({...formData, NumberOfJobs: parseInt(e.target.value)})} />
              </div>
              <div className="flex-1">
                 <label className="block text-xs font-bold text-gray-500 uppercase mb-1.5">Type</label>
                 <select className="w-full border border-gray-300 rounded-lg p-2.5 outline-none focus:ring-2 focus:ring-blue-500 bg-white" value={formData.JobType || formData.jobType || 0} onChange={e => setFormData({...formData, JobType: parseInt(e.target.value)})}>
                    <option value={0}>Full Time</option><option value={1}>Internship</option><option value={2}>Part Time</option>
                 </select>
              </div>
           </div>
           
           <div>
              <label className="block text-xs font-bold text-gray-500 uppercase mb-1.5">Description</label>
              <textarea className="w-full border border-gray-300 rounded-lg p-3 h-32 resize-none outline-none focus:ring-2 focus:ring-blue-500" placeholder="Describe the role and responsibilities..." value={formData.JobDescription || formData.jobDescription || ''} onChange={e => setFormData({...formData, JobDescription: e.target.value})}></textarea>
           </div>
           
           <div>
              <label className="block text-xs font-bold text-gray-500 uppercase mb-1.5">Required Skills</label>
              <div className="flex gap-2 mb-3">
                 <input className="flex-1 border border-gray-300 rounded-lg p-2.5 text-sm outline-none focus:border-blue-500" value={skillInput} onChange={e => setSkillInput(e.target.value)} placeholder="Type a skill..." />
                 <button onClick={addSkill} className="bg-blue-50 text-blue-600 px-4 rounded-lg text-sm font-bold hover:bg-blue-100 border border-blue-100">Add</button>
              </div>
              <div className="flex flex-wrap gap-2 min-h-[40px] p-2 bg-gray-50 rounded-lg border border-gray-100">
                 {(formData.RequiredSkills || formData.requiredSkills || []).map((s, i) => (
                    <span key={i} className="text-xs bg-white border border-gray-200 text-gray-700 px-2 py-1 rounded-md flex items-center gap-1 shadow-sm">
                        {s} 
                        <button type="button" onClick={() => {
                            const skills = formData.RequiredSkills || formData.requiredSkills;
                            setFormData({...formData, RequiredSkills: skills.filter(x => x !== s)});
                        }} className="hover:text-red-500"><X className="w-3 h-3"/></button>
                    </span>
                 ))}
                 {(formData.RequiredSkills || formData.requiredSkills || []).length === 0 && <span className="text-xs text-gray-400 italic p-1">No skills added yet.</span>}
              </div>
           </div>

           <div className="pt-4 flex gap-3">
              <button type="button" onClick={onClose} className="flex-1 py-3 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-xl font-bold transition-colors">Cancel</button>
              <button disabled={loading} className="flex-1 py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 flex justify-center gap-2 transition-colors shadow-lg shadow-blue-200">
                 {loading ? <Loader2 className="animate-spin w-5 h-5"/> : 'Save Job Posting'}
              </button>
           </div>
        </form>
      </div>
    </div>
  );
}

function Input({ label, value, onChange, type="text", placeholder }) {
  return (
    <div>
      <label className="block text-xs font-bold text-gray-500 uppercase mb-1.5">{label}</label>
      <input type={type} placeholder={placeholder} value={value || ''} onChange={onChange} className="w-full border border-gray-300 rounded-lg p-3 outline-none focus:ring-2 focus:ring-blue-500 transition-all" />
    </div>
  );
}