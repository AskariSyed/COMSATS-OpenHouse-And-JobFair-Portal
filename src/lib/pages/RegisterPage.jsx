/* eslint-disable react-hooks/set-state-in-effect */
import React, { useState, useRef, useEffect } from 'react';
import { ChevronRight, Mail, Loader2, Plus, Trash2, X, ArrowRight, ArrowLeft, CheckCircle2, User, Building2, Phone, Briefcase, Globe, MapPin } from 'lucide-react';
import { registerCompany, verifyOtp } from '../api';
import { allSkillsList } from '../../data/skills';

const INDUSTRIES = [
  "Information Technology", "Fintech", "Textile", "Manufacturing", 
  "Education", "Healthcare", "Telecommunications", "Banking", 
  "Construction", "Retail", "Energy", "Other"
];

export default function RegisterPage({ onNavigate, onSuccess, onError }) {
  const [currentStep, setCurrentStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [otp, setOtp] = useState('');
  
  const [formData, setFormData] = useState({
    Name: '', Description: '', RepsCount: 1, 
    FocalPersonPhone: '', CompanyEmail: '', CompanyPhone: '', Address: '', Website: '',
    InterviewDurationMinutes: 15, Industry: 'Information Technology',
    UserEmail: '', UserFullName: '', UserPassword: ''
  });
  const [logoFile, setLogoFile] = useState(null);

  const [jobs, setJobs] = useState([
    { JobTitle: '', JobDescription: '', JobCount: 1, Type: 0, SelectedSkills: [] }
  ]);

  const handleChange = (e) => setFormData({...formData, [e.target.name]: e.target.value});

  // --- VALIDATION ---
  const validateEmail = (email) => {
    const emailRegex = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    return emailRegex.test(email);
  };  

  const validatePhone = (phone) => {
    const phoneRegex = /^\d{11}$/;
    return phoneRegex.test(phone);
  };

  const validatePassword = (password) => {
    // At least 8 characters, one uppercase, one lowercase, one digit, one special character
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
    return passwordRegex.test(password);
  };

  const validateWebsite = (url) => {
    if (!url) return true; // Optional field
    const urlRegex = /^(https?:\/\/)?(www\.)?[a-zA-Z0-9-]+(\.[a-zA-Z]{2,})+(\/[^\s]*)?$/;
    return urlRegex.test(url);
  };

  // --- JOB LOGIC ---
  const addJob = () => setJobs([...jobs, { JobTitle: '', JobDescription: '', JobCount: 1, Type: 0, SelectedSkills: [] }]);
  const removeJob = (index) => { if (jobs.length > 1) setJobs(jobs.filter((_, i) => i !== index)); };
  
  const updateJob = (index, field, value) => {
    const newJobs = [...jobs];
    newJobs[index][field] = value;
    setJobs(newJobs);
  };

  const addSkillToJob = (jobIndex, skill) => {
    const newJobs = [...jobs];
    if (!newJobs[jobIndex].SelectedSkills.includes(skill)) {
      newJobs[jobIndex].SelectedSkills.push(skill);
      setJobs(newJobs);
    }
  };

  const removeSkillFromJob = (jobIndex, skillToRemove) => {
    const newJobs = [...jobs];
    newJobs[jobIndex].SelectedSkills = newJobs[jobIndex].SelectedSkills.filter(s => s !== skillToRemove);
    setJobs(newJobs);
  };

  // --- NAVIGATION & SUBMISSION ---
  const nextStep = () => {
    if (currentStep === 1) {
      if (!formData.UserFullName || !formData.UserEmail || !formData.UserPassword || !formData.FocalPersonPhone) {
        return onError("Please fill all representative details.");
      }
      if (!validateEmail(formData.UserEmail)) {
        return onError("Please enter a valid email address.");
      }
      if (!validatePhone(formData.FocalPersonPhone)) {
        return onError("Phone number must be exactly 11 digits.");
      }
      if (!validatePassword(formData.UserPassword)) {
        return onError("Password must be at least 8 characters with one uppercase, one lowercase, one digit, and one special character.");
      }
    }
    if (currentStep === 2) {
      if (!formData.Name || !formData.Address) {
        return onError("Company Name and Address are required.");
      }
      if (formData.RepsCount < 1) {
        return onError("Number of representatives must be at least 1.");
      }
      if (formData.InterviewDurationMinutes < 1 || formData.InterviewDurationMinutes > 60) {
        return onError("Interview duration must be between 1 and 60 minutes.");
      }
      if (formData.CompanyEmail && !validateEmail(formData.CompanyEmail)) {
        return onError("Please enter a valid company email address.");
      }
      if (formData.CompanyPhone && !validatePhone(formData.CompanyPhone)) {
        return onError("Company phone must be exactly 11 digits.");
      }
      if (formData.Website && !validateWebsite(formData.Website)) {
        return onError("Please enter a valid website URL.");
      }
    }
    setCurrentStep(prev => prev + 1);
  };

  const handleSignup = async () => {
    setLoading(true);
    try {
      const data = new FormData();
      Object.keys(formData).forEach(key => data.append(key, formData[key]));
      data.append('FocalPersonName', formData.UserFullName);
      data.append('FocalPersonEmail', formData.UserEmail);
      if (logoFile) data.append('Logo', logoFile);

      jobs.forEach((job, index) => {
        data.append(`JobOfferings[${index}].JobTitle`, job.JobTitle);
        data.append(`JobOfferings[${index}].JobDescription`, job.JobDescription);
        data.append(`JobOfferings[${index}].JobCount`, job.JobCount);
        data.append(`JobOfferings[${index}].Type`, job.Type);
        data.append(`JobOfferings[${index}].RequiredSkills`, job.SelectedSkills.join(', '));
      });

      data.append('ContactLinks[0].Platform', 1);
      data.append('ContactLinks[0].Url', formData.Website || 'http://example.com');

      await registerCompany(data);
      onSuccess("Registration successful! OTP sent.");
      setCurrentStep(4); 
    } catch (err) { onError(err.message || "Registration failed"); } 
    finally { setLoading(false); }
  };

  const handleVerify = async () => {
    // Validate OTP (digits only, 6 characters)
    if (!/^\d{6}$/.test(otp)) {
      onError("OTP must be 6 digits.");
      return;
    }
    
    setLoading(true);
    try {
      await verifyOtp(formData.UserEmail, formData.UserEmail, otp);
      onSuccess("Account verified! Please login.");
      onNavigate('login');
    } catch (err) { onError(err.message || "Invalid OTP"); } 
    finally { setLoading(false); }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex">
      {/* LEFT SIDEBAR - Stepper */}
      <div className="hidden lg:flex w-1/3 bg-slate-900 text-white p-12 flex-col justify-between relative overflow-hidden">
        {/* Background blobs */}
        <div className="absolute top-0 left-0 w-full h-full z-0 pointer-events-none">
           <div className="absolute -top-10 -left-10 w-64 h-64 bg-blue-600 rounded-full mix-blend-multiply filter blur-3xl opacity-20"></div>
           <div className="absolute bottom-10 right-10 w-64 h-64 bg-purple-600 rounded-full mix-blend-multiply filter blur-3xl opacity-20"></div>
        </div>

        <div className="relative z-10">
          <div className="flex items-center gap-2 mb-8 text-blue-400 font-bold tracking-widest text-sm uppercase">
             <Building2 className="w-4 h-4" /> Partner Portal
          </div>
          <h1 className="text-4xl font-bold mb-4">Join the Next <br/>Big Hiring Event</h1>
          <p className="text-slate-400 mb-12 leading-relaxed">Connect with top talent from CUI Wah Campus. Register your company to manage job postings, schedule interviews, and more.</p>
          
          <div className="space-y-8">
            <StepItem step={1} current={currentStep} title="Account Details" desc="Focal person information" />
            <StepItem step={2} current={currentStep} title="Company Profile" desc="Branding and industry" />
            <StepItem step={3} current={currentStep} title="Job Offerings" desc="Roles you are hiring for" />
            <StepItem step={4} current={currentStep} title="Verification" desc="Email confirmation" />
          </div>
        </div>

        <div className="relative z-10 text-xs text-slate-600">
           <button onClick={() => onNavigate('login')} className="flex items-center gap-2 text-white hover:text-blue-300 transition-colors">
             <ArrowLeft className="w-4 h-4" /> Back to Login
           </button>
        </div>
      </div>

      {/* RIGHT SIDE - Form Area */}
      <div className="flex-1 flex flex-col h-screen overflow-hidden bg-white">
        <div className="flex-1 overflow-y-auto p-6 md:p-12">
           <div className="max-w-2xl mx-auto py-8">
             
             {/* Mobile Header */}
             <div className="lg:hidden mb-8">
               <h2 className="text-2xl font-bold text-gray-900">Create Account</h2>
               <p className="text-sm text-gray-500">Step {currentStep} of 4</p>
               <div className="w-full bg-gray-100 h-2 mt-2 rounded-full overflow-hidden">
                 <div className="bg-blue-600 h-full transition-all duration-300" style={{width: `${currentStep * 25}%`}}></div>
               </div>
             </div>

             {/* STEP 1: ACCOUNT */}
             {currentStep === 1 && (
               <div className="animate-fade-in space-y-6">
                 <h2 className="text-2xl font-bold text-gray-900 mb-6">Representative Details</h2>
                 <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                   <InputGroup label="Full Name" icon={User} name="UserFullName" value={formData.UserFullName} onChange={handleChange} placeholder="e.g. Ali Khan" />
                   <InputGroup label="Direct Phone" icon={Phone} name="FocalPersonPhone" value={formData.FocalPersonPhone} onChange={handleChange} placeholder="03001234567" pattern="\d{11}" title="Phone number must be exactly 11 digits" />
                 </div>
                 <InputGroup label="Work Email (Login ID)" icon={Mail} type="email" name="UserEmail" value={formData.UserEmail} onChange={handleChange} placeholder="ali@company.com" />
                 <InputGroup label="Password" icon={CheckCircle2} type="password" name="UserPassword" value={formData.UserPassword} onChange={handleChange} placeholder="Create a strong password" pattern="(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}" title="Password must be at least 8 characters with one uppercase, one lowercase, one digit, and one special character (@$!%*?&)" />
               </div>
             )}

             {/* STEP 2: COMPANY */}
             {currentStep === 2 && (
                <div className="animate-fade-in space-y-6">
                   <h2 className="text-2xl font-bold text-gray-900 mb-6">Company Profile</h2>
                   <InputGroup label="Company Name" icon={Building2} name="Name" value={formData.Name} onChange={handleChange} placeholder="Tech Solutions Inc." />
                   
                   <div>
                     <label className="block text-sm font-medium text-gray-700 mb-1.5">Company Description</label>
                     <textarea name="Description" value={formData.Description} onChange={handleChange} rows={3} className="w-full p-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-blue-500 outline-none transition-all" placeholder="Tell us about your company..." />
                   </div>
                   
                   <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1.5">Industry</label>
                        <select name="Industry" value={formData.Industry} onChange={handleChange} className="w-full p-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-blue-500 outline-none transition-all">
                          {INDUSTRIES.map(ind => <option key={ind} value={ind}>{ind}</option>)}
                        </select>
                      </div>
                      <InputGroup label="Official Phone" icon={Phone} name="CompanyPhone" value={formData.CompanyPhone} onChange={handleChange} pattern="\d{11}" title="Phone number must be exactly 11 digits" />
                   </div>

                   <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                      <InputGroup label="Number of Representatives" icon={User} type="number" name="RepsCount" value={formData.RepsCount} onChange={handleChange} min="1" />
                      <InputGroup label="Interview Duration (Minutes)" icon={Briefcase} type="number" name="InterviewDurationMinutes" value={formData.InterviewDurationMinutes} onChange={handleChange} min="1" max="60" />
                   </div>

                   <InputGroup label="Official Email" icon={Mail} type="email" name="CompanyEmail" value={formData.CompanyEmail} onChange={handleChange} />
                   <InputGroup label="Website URL" icon={Globe} name="Website" value={formData.Website} onChange={handleChange} placeholder="https://example.com" pattern="(https?:\/\/)?(www\.)?[a-zA-Z0-9-]+(\.[a-zA-Z]{2,})+(\/.*)? " title="Please enter a valid website URL" />
                   <InputGroup label="Headquarters Address" icon={MapPin} name="Address" value={formData.Address} onChange={handleChange} />
                   
                   <div>
                     <label className="block text-sm font-medium text-gray-700 mb-1.5">Company Logo</label>
                     <div className="border-2 border-dashed border-gray-300 rounded-xl p-6 text-center hover:bg-gray-50 transition-colors">
                        <input type="file" onChange={(e) => setLogoFile(e.target.files[0])} className="hidden" id="logo-upload" />
                        <label htmlFor="logo-upload" className="cursor-pointer flex flex-col items-center">
                          <div className="w-12 h-12 bg-blue-50 text-blue-600 rounded-full flex items-center justify-center mb-2"><Plus className="w-6 h-6"/></div>
                          <span className="text-sm text-gray-600 font-medium">{logoFile ? logoFile.name : "Click to upload logo"}</span>
                          <span className="text-xs text-gray-400 mt-1">PNG, JPG up to 2MB</span>
                        </label>
                     </div>
                   </div>
                </div>
             )}

             {/* STEP 3: JOBS */}
             {currentStep === 3 && (
               <div className="animate-fade-in space-y-6">
                 <div className="flex justify-between items-center mb-4">
                   <h2 className="text-2xl font-bold text-gray-900">Job Openings</h2>
                   <button onClick={addJob} className="text-sm bg-blue-50 text-blue-600 px-4 py-2 rounded-lg font-bold hover:bg-blue-100 flex items-center gap-1 transition-colors">
                     <Plus className="w-4 h-4" /> Add Position
                   </button>
                 </div>

                 <div className="space-y-4">
                   {jobs.map((job, index) => (
                     <div key={index} className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm relative group hover:border-blue-300 transition-all">
                       {jobs.length > 1 && (
                         <button onClick={() => removeJob(index)} className="absolute top-4 right-4 text-gray-400 hover:text-red-500 opacity-0 group-hover:opacity-100 transition-opacity"><Trash2 className="w-5 h-5" /></button>
                       )}
                       
                       <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                         <div className="col-span-2 md:col-span-1">
                            <label className="text-xs font-bold text-gray-500 uppercase">Job Title</label>
                            <input value={job.JobTitle} onChange={(e) => updateJob(index, 'JobTitle', e.target.value)} className="w-full p-2 border-b border-gray-200 focus:border-blue-500 outline-none font-medium text-lg placeholder-gray-300" placeholder="e.g. Software Engineer" />
                         </div>
                         <div className="flex gap-4">
                            <div className="flex-1">
                               <label className="text-xs font-bold text-gray-500 uppercase">Count</label>
                               <input type="number" min="1" value={job.JobCount} onChange={(e) => updateJob(index, 'JobCount', e.target.value)} className="w-full p-2 border-b border-gray-200 focus:border-blue-500 outline-none" />
                            </div>
                            <div className="flex-1">
                               <label className="text-xs font-bold text-gray-500 uppercase">Type</label>
                               <select value={job.Type} onChange={(e) => updateJob(index, 'Type', e.target.value)} className="w-full p-2 border-b border-gray-200 focus:border-blue-500 outline-none bg-transparent">
                                 <option value={0}>Full Time</option>
                                 <option value={1}>Internship</option>
                                 <option value={2}>Part Time</option>
                               </select>
                            </div>
                         </div>
                       </div>
                       
                       <div className="mb-4">
                         <label className="text-xs font-bold text-gray-500 uppercase">Description</label>
                         <textarea rows={2} value={job.JobDescription} onChange={(e) => updateJob(index, 'JobDescription', e.target.value)} className="w-full p-2 border border-gray-100 rounded bg-gray-50 text-sm focus:bg-white focus:ring-1 focus:ring-blue-500 outline-none mt-1" placeholder="Brief role description..." />
                       </div>

                       <SkillSelector selectedSkills={job.SelectedSkills} onAdd={(s) => addSkillToJob(index, s)} onRemove={(s) => removeSkillFromJob(index, s)} />
                     </div>
                   ))}
                 </div>
               </div>
             )}

             {/* STEP 4: VERIFY */}
             {currentStep === 4 && (
               <div className="animate-fade-in text-center py-12">
                 <div className="w-20 h-20 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center mx-auto mb-6 animate-pulse">
                   <Mail className="w-10 h-10" />
                 </div>
                 <h2 className="text-3xl font-bold text-gray-900 mb-3">Verify Your Email</h2>
                 <p className="text-gray-500 mb-8 max-w-md mx-auto">We've sent a 6-digit code to <strong>{formData.UserEmail}</strong>. Enter it below to activate your account.</p>
                 
                 <input 
                   type="text" 
                   maxLength={6}
                   value={otp}
                   onChange={(e) => setOtp(e.target.value.replace(/\D/g, ''))}
                   pattern="\d{6}"
                   title="OTP must be 6 digits"
                   className="text-center text-4xl tracking-[0.5em] font-bold w-full max-w-xs mx-auto block p-4 border-b-2 border-gray-300 focus:border-blue-600 outline-none mb-8 font-mono bg-transparent transition-colors"
                   placeholder="000000"
                 />
                 
                 <button onClick={handleVerify} disabled={loading} className="w-full bg-blue-600 hover:bg-blue-700 text-white py-4 rounded-xl font-bold shadow-lg shadow-blue-200 transition-all flex justify-center items-center gap-2">
                   {loading ? <Loader2 className="animate-spin" /> : 'Activate Account'}
                 </button>
               </div>
             )}
           </div>
        </div>

        {/* FOOTER CONTROLS */}
        {currentStep < 4 && (
           <div className="p-6 border-t border-gray-100 bg-white flex justify-between items-center z-20">
              <button 
                onClick={() => setCurrentStep(prev => prev - 1)} 
                disabled={currentStep === 1}
                className={`flex items-center gap-2 px-6 py-3 rounded-xl font-medium transition ${currentStep === 1 ? 'opacity-0 pointer-events-none' : 'text-gray-600 hover:bg-gray-100'}`}
              >
                Back
              </button>

              {currentStep < 3 ? (
                <button onClick={nextStep} className="bg-slate-900 text-white px-8 py-3 rounded-xl font-bold hover:bg-slate-800 shadow-lg shadow-slate-200 flex items-center gap-2 transition-all hover:gap-3">
                  Next Step <ArrowRight className="w-4 h-4" />
                </button>
              ) : (
                <button onClick={handleSignup} disabled={loading} className="bg-blue-600 text-white px-8 py-3 rounded-xl font-bold hover:bg-blue-700 shadow-lg shadow-blue-200 flex items-center gap-2 transition-all">
                   {loading ? <Loader2 className="animate-spin" /> : 'Complete Registration'} <CheckCircle2 className="w-4 h-4" />
                </button>
              )}
           </div>
        )}
      </div>
    </div>
  );
}

// --- HELPER COMPONENTS ---

function StepItem({ step, current, title, desc }) {
  const active = step === current;
  const done = step < current;
  return (
    <div className={`flex items-start gap-4 transition-opacity duration-300 ${active ? 'opacity-100' : 'opacity-50'}`}>
      <div className={`w-10 h-10 rounded-full flex items-center justify-center font-bold border-2 transition-colors ${active ? 'bg-blue-600 border-blue-600 text-white' : done ? 'bg-green-500 border-green-500 text-white' : 'border-slate-700 text-slate-500'}`}>
        {done ? <CheckCircle2 className="w-5 h-5" /> : step}
      </div>
      <div>
        <h4 className={`font-bold ${active ? 'text-white' : 'text-slate-300'}`}>{title}</h4>
        <p className="text-xs text-slate-500">{desc}</p>
      </div>
    </div>
  );
}

function InputGroup({ label, name, value, onChange, type = "text", placeholder, icon: Icon, pattern, title, ...props }) {
  return (
    <div>
      <label className="block text-sm font-medium text-gray-700 mb-1.5">{label}</label>
      <div className="relative">
        {Icon && <Icon className="absolute left-3.5 top-3.5 w-5 h-5 text-gray-400" />}
        <input 
          type={type} name={name} value={value} onChange={onChange} placeholder={placeholder}
          pattern={pattern} title={title} {...props}
          className={`w-full ${Icon ? 'pl-11' : 'pl-4'} pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all placeholder-gray-400`} 
        />
      </div>
    </div>
  );
}

function SkillSelector({ selectedSkills, onAdd, onRemove }) {
  const [query, setQuery] = useState('');
  const [suggestions, setSuggestions] = useState([]);
  const [showDropdown, setShowDropdown] = useState(false);
  const wrapperRef = useRef(null);

  useEffect(() => {
    if (query.trim()) {
      const filtered = allSkillsList.filter(s => s.toLowerCase().includes(query.toLowerCase()) && !selectedSkills.includes(s));
      setSuggestions(filtered.slice(0, 5));
      setShowDropdown(true);
    } else {
      setShowDropdown(false);
    }
  }, [query, selectedSkills]);

  return (
    <div className="relative" ref={wrapperRef}>
      <label className="text-xs font-bold text-gray-500 uppercase block mb-2">Required Skills</label>
      <div className="flex flex-wrap gap-2 mb-2 p-2 bg-gray-50 border border-gray-100 rounded-lg min-h-[40px]">
        {selectedSkills.map((s, i) => (
          <span key={i} className="bg-blue-100 text-blue-700 text-xs font-bold px-2 py-1 rounded flex items-center gap-1">
            {s} <button onClick={() => onRemove(s)} className="hover:text-blue-900"><X className="w-3 h-3" /></button>
          </span>
        ))}
        <input 
          className="flex-1 bg-transparent text-sm outline-none min-w-[100px]"
          placeholder="Type to add skills..."
          value={query}
          onChange={e => setQuery(e.target.value)}
          onFocus={() => query && setShowDropdown(true)}
          onBlur={() => setTimeout(() => setShowDropdown(false), 200)}
        />
      </div>
      {showDropdown && suggestions.length > 0 && (
        <div className="absolute z-10 w-full bg-white border border-gray-200 shadow-xl mt-1 rounded-xl overflow-hidden">
          {suggestions.map((s, i) => (
            <div key={i} className="px-4 py-2 hover:bg-blue-50 cursor-pointer text-sm font-medium text-gray-700" onMouseDown={() => { onAdd(s); setQuery(''); }}>{s}</div>
          ))}
        </div>
      )}
    </div>
  );
}