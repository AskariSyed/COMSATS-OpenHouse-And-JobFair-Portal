import React, { useEffect, useState } from 'react';
import { ChevronLeft, Github, ExternalLink, Users, Code2, Loader2, User, Building2, Calendar, Award, Briefcase } from 'lucide-react';
import { getProjectDetails, getFileUrl } from '../api';
import { getEmbedUrl, getYoutubeId } from '../utils/videoUtils';

export default function FYPDetails({ projectId, onBack, onSelectStudent, onError }) {
  const [project, setProject] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Hits the 'full-details' endpoint
    getProjectDetails(projectId)
      .then(data => setProject(data.project))
      .catch(err => onError(err.message))
      .finally(() => setLoading(false));
  }, [projectId, onError]);

  if (loading) return <div className="h-96 flex items-center justify-center"><Loader2 className="animate-spin w-8 h-8 text-blue-600" /></div>;
  if (!project) return <div className="text-center text-red-500 p-12">Project not found.</div>;

  const embedUrl = getEmbedUrl(project.demoUrl);
  const projectGithubUrl = String(project.gitHubUrl || project.githubUrl || project.GitHubUrl || '').trim();
  const getStudentGithubUrl = (student) => {
    const links = student?.contactLinks?.links || [];
    const githubLink = links.find((link) => String(link.platform || '').toLowerCase() === 'github');
    return githubLink?.url || null;
  };

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden animate-fade-in flex flex-col h-full">
      {/* Header */}
      <div className="p-6 border-b flex items-start gap-4 bg-white sticky top-0 z-20">
        <button onClick={onBack} className="p-2 hover:bg-gray-100 rounded-full transition-colors mt-1">
          <ChevronLeft className="w-6 h-6 text-gray-600" />
        </button>
        <div className="flex-1">
          <div className="flex flex-col md:flex-row md:items-center gap-2 md:gap-4 mb-2">
            <h1 className="text-2xl font-bold text-gray-900 leading-tight">{project.title}</h1>
            <span className="bg-purple-100 text-purple-700 px-2.5 py-0.5 rounded text-xs font-bold uppercase tracking-wide w-fit">
              {project.type}
            </span>
            {projectGithubUrl && (
              <a
                href={projectGithubUrl}
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center justify-center p-1.5 rounded-md border border-gray-200 text-gray-600 hover:text-gray-900 hover:bg-gray-50 w-fit"
                title="Open GitHub"
                aria-label="Open GitHub"
              >
                <Github className="w-4 h-4" />
              </a>
            )}
          </div>
          
          <div className="flex flex-wrap gap-4 text-sm text-gray-500">
            {project.supervisor && <span className="flex items-center gap-1.5"><User className="w-4 h-4 text-gray-400" /> Supervisor: <span className="font-medium text-gray-700">{project.supervisor}</span></span>}
            {project.clientName && <span className="flex items-center gap-1.5 border-l pl-4 border-gray-200"><Building2 className="w-4 h-4 text-gray-400" /> Client: <span className="font-medium text-gray-700">{project.clientName}</span></span>}
            {project.summary?.averageStudentCGPA > 0 && (
                 <span className="flex items-center gap-1.5 border-l pl-4 border-gray-200"><Award className="w-4 h-4 text-gray-400" /> Avg CGPA: <span className="font-medium text-green-600">{project.summary.averageStudentCGPA}</span></span>
            )}
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-6">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          
          {/* Left Column */}
          <div className="lg:col-span-2 space-y-8">
            {embedUrl ? (
              <div className="aspect-video bg-black rounded-xl overflow-hidden shadow-lg">
                <iframe src={embedUrl} title="Project Demo" className="w-full h-full" allowFullScreen frameBorder="0" />
              </div>
            ) : (
              <div className="aspect-video bg-slate-50 rounded-xl border-2 border-dashed border-gray-200 flex flex-col items-center justify-center text-gray-400">
                <Code2 className="w-12 h-12 opacity-20 mb-2" />
                <span>No video demo</span>
              </div>
            )}

            <div className="prose max-w-none">
              <h3 className="text-lg font-bold text-gray-900 mb-3">About the Project</h3>
              <p className="text-gray-600 leading-relaxed whitespace-pre-line">{project.description || "No description provided."}</p>
            </div>

            <div className="flex flex-wrap gap-4 pt-4 border-t border-gray-100">
              {project.demoUrl && !getYoutubeId(project.demoUrl) && (
                 <a href={project.demoUrl} target="_blank" rel="noreferrer" className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 shadow-sm"><ExternalLink className="w-4 h-4" /> Live Demo</a>
              )}
              {projectGithubUrl && (
                <a href={projectGithubUrl} target="_blank" rel="noreferrer" className="inline-flex items-center gap-2 px-4 py-2 bg-gray-900 text-white rounded-lg font-medium hover:bg-gray-800 shadow-sm"><Github className="w-4 h-4" /> Source Code</a>
              )}
            </div>
          </div>

          {/* Right Column: Team */}
          <div className="lg:col-span-1">
            <div className="bg-slate-50 rounded-xl p-5 border border-gray-200 sticky top-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-bold text-gray-900 flex items-center gap-2"><Users className="w-5 h-5 text-blue-600" /> Project Team</h3>
                <span className="bg-blue-100 text-blue-700 text-xs font-bold px-2 py-1 rounded-full">{project.students?.length || 0}</span>
              </div>
              
              <div className="space-y-3">
                {project.students?.map(student => {
                  const studentGithubUrl = getStudentGithubUrl(student);
                  return (
                  <div key={student.studentId} onClick={() => onSelectStudent(student)} className="bg-white p-3 rounded-xl border border-gray-200 hover:border-blue-400 hover:shadow-md transition-all cursor-pointer group flex items-start gap-3">
                    <div className="w-10 h-10 min-w-[2.5rem] bg-gray-100 rounded-full flex items-center justify-center overflow-hidden border border-gray-200">
                       {student.profilePicUrl ? <img src={getFileUrl(student.profilePicUrl)} alt="" className="w-full h-full object-cover" /> : <span>{student.fullName?.charAt(0)}</span>}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex justify-between items-start gap-2">
                        {/* Note: Controller uses 'fullName' now */}
                        <h4 className="font-bold text-gray-800 text-sm group-hover:text-blue-600 truncate pr-2">{student.fullName}</h4>
                        <div className="flex items-center gap-1">
                          {studentGithubUrl && (
                            <a
                              href={studentGithubUrl}
                              target="_blank"
                              rel="noreferrer"
                              onClick={(e) => e.stopPropagation()}
                              className="inline-flex items-center justify-center p-1 rounded hover:bg-gray-100 text-gray-600 hover:text-gray-900"
                              title="Open student GitHub"
                              aria-label="Open student GitHub"
                            >
                              <Github className="w-3.5 h-3.5" />
                            </a>
                          )}
                          {/* Accessing nested ProjectRole object */}
                          {student.projectRole?.isCreator && <span className="text-[10px] bg-yellow-100 text-yellow-800 px-1.5 py-0.5 rounded font-bold whitespace-nowrap">Lead</span>}
                        </div>
                      </div>
                      <p className="text-xs text-gray-500 truncate">{student.registrationNo}</p>
                      <p className="text-xs text-green-700 font-semibold mt-1">CGPA: {student.cgpa ?? student.CGPA ?? 'N/A'}</p>
                      {/* Accessing nested ProjectRole object */}
                      <p className="text-[10px] text-gray-400 mt-1 uppercase tracking-wide font-medium">{student.projectRole?.role || 'Member'}</p>
                    </div>
                  </div>
                );
                })}
              </div>

               {/* New Stats Section from full-details */}
              <div className="mt-6 pt-6 border-t border-gray-200 space-y-3">
                 <h4 className="text-xs font-bold text-gray-400 uppercase">Team Stats</h4>
                 <div className="flex justify-between text-sm">
                    <span className="text-gray-600 flex items-center gap-2"><Briefcase className="w-4 h-4" /> Exp. Years</span>
                    <span className="font-bold">{project.students?.reduce((acc, s) => acc + (s.workExperience?.totalExperiences || 0), 0)}</span>
                 </div>
                 <div className="flex justify-between text-sm">
                    <span className="text-gray-600 flex items-center gap-2"><Award className="w-4 h-4" /> Certifications</span>
                    <span className="font-bold">{project.students?.reduce((acc, s) => acc + (s.certifications?.totalCertifications || 0), 0)}</span>
                 </div>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}