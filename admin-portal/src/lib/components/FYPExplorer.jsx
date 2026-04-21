import React, { useEffect, useRef, useState } from 'react';
import { Loader2, Github, Code2, PlayCircle, Search } from 'lucide-react';
import { getFinalYearProjects } from '../api';
import { getThumbnailUrl } from '../utils/videoUtils';

export default function FYPExplorer({ onSelectProject, onError, jobFairId }) {
  const [projects, setProjects] = useState([]);
  const [loading, setLoading] = useState(true);
  const [studentQuery, setStudentQuery] = useState('');
  const [departmentFilter, setDepartmentFilter] = useState('');
  const [fypQuery, setFypQuery] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(9);
  const [totalCount, setTotalCount] = useState(0);
  const debounceRef = useRef(null);

  const departmentOptions = [
    'Computer Science',
    'Civil Engineering',
    'Mechanical Engineering',
    'Electrical Engineering',
    'Management Sciences'
  ];

  const fetchProjects = async () => {
    setLoading(true);
    try {
      const data = await getFinalYearProjects({
        studentQuery,
        department: departmentFilter,
        fypQuery,
        page: currentPage,
        pageSize,
        jobFairId
      });
      setProjects(data.items || data.projects || []);
      setTotalCount(data.totalCount || data.totalProjects || 0);
    } catch (err) {
      onError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => {
      fetchProjects();
    }, 350);

    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, [studentQuery, departmentFilter, fypQuery, currentPage, pageSize, jobFairId]);

  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));

  if (loading && projects.length === 0) return <div className="p-12 text-center"><Loader2 className="animate-spin mx-auto text-blue-600" /></div>;

  return (
    <div className="animate-fade-in">
      <div className="flex justify-end mb-3">
        <span className="bg-blue-100 text-blue-700 px-3 py-1 rounded-full text-xs font-bold">
          {projects.length} / {totalCount} Projects
        </span>
      </div>

      <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-200 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase block mb-1">Student Reg No / Name</label>
            <div className="relative">
              <Search className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                value={studentQuery}
                onChange={(e) => {
                  setStudentQuery(e.target.value);
                  setCurrentPage(1);
                }}
                placeholder="e.g. SP22-BCS-011 or Ali"
                className="w-full border rounded-lg p-2 pl-9"
              />
            </div>
          </div>

          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase block mb-1">Department</label>
            <select
              value={departmentFilter}
              onChange={(e) => {
                setDepartmentFilter(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full border rounded-lg p-2"
            >
              <option value="">All Departments</option>
              {departmentOptions.map((dept) => (
                <option key={dept} value={dept}>{dept}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase block mb-1">FYP Name</label>
            <div className="relative">
              <Search className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                value={fypQuery}
                onChange={(e) => {
                  setFypQuery(e.target.value);
                  setCurrentPage(1);
                }}
                placeholder="Search by project title"
                className="w-full border rounded-lg p-2 pl-9"
              />
            </div>
          </div>
        </div>
      </div>

      {loading && projects.length > 0 && (
        <div className="mb-4 text-sm text-blue-600 flex items-center gap-2">
          <Loader2 className="w-4 h-4 animate-spin" /> Updating results...
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        {projects.map(project => (
          (() => {
            const projectGithubUrl = String(project.gitHubUrl || project.githubUrl || project.GitHubUrl || '').trim();
            const firstStudentGithub = (project.students || [])
              .map((student) => student.studentGitHubUrl || student.studentGithubUrl || student.githubUrl)
              .find(Boolean);
            const projectGithubLink = projectGithubUrl || firstStudentGithub;
            return (
          <div 
            key={project.projectId} 
            onClick={() => onSelectProject(project.projectId)}
            className="group bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden flex flex-col h-full hover:shadow-xl hover:border-blue-300 transition-all cursor-pointer"
          >
            {/* Thumbnail Section */}
            <div className="h-36 bg-slate-100 relative overflow-hidden">
              {project.demoUrl && getThumbnailUrl(project.demoUrl) ? (
                <>
                  <img 
                    src={getThumbnailUrl(project.demoUrl)} 
                    alt={project.title} 
                    className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
                  />
                  <div className="absolute inset-0 bg-black/30 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                    <PlayCircle className="w-12 h-12 text-white drop-shadow-lg" />
                  </div>
                </>
              ) : (
                <div className="w-full h-full flex items-center justify-center text-gray-400 bg-slate-50">
                  <Code2 className="w-12 h-12 opacity-20" />
                </div>
              )}
              <div className="absolute top-2 right-2 bg-white/90 backdrop-blur text-xs font-bold px-2 py-1 rounded shadow-sm">
                {project.type || 'FYP'}
              </div>
            </div>

            <div className="p-4 flex-1 flex flex-col">
              <h3 className="font-bold text-base text-gray-900 mb-1.5 line-clamp-1 group-hover:text-blue-600 transition-colors">
                {project.title}
              </h3>
              
              <p className="text-gray-600 text-xs mb-3 line-clamp-2 flex-1">{project.description}</p>

              <div className="flex flex-wrap gap-1 mb-3">
                {project.skills?.slice(0, 2).map((skill, i) => (
                  <span key={i} className="bg-blue-50 text-blue-700 px-2 py-1 rounded text-[10px] font-medium border border-blue-100">
                    {skill}
                  </span>
                ))}
                {project.skills?.length > 2 && <span className="text-xs text-gray-400 flex items-center">+{project.skills.length - 2}</span>}
              </div>

              <div className="pt-3 border-t border-gray-100 flex items-center justify-end text-xs text-gray-500">
                {projectGithubLink && (
                  <a
                    href={projectGithubLink}
                    target="_blank"
                    rel="noreferrer"
                    onClick={(e) => e.stopPropagation()}
                    className="inline-flex items-center justify-center p-1 rounded hover:bg-gray-100 text-gray-600 hover:text-gray-900"
                    title="Open GitHub"
                    aria-label="Open GitHub"
                  >
                    <Github className="w-3.5 h-3.5" />
                  </a>
                )}
              </div>
            </div>
          </div>
            );
          })()
        ))}
      </div>

      {projects.length === 0 && (
        <div className="text-center py-12 bg-white rounded-xl border border-dashed border-gray-200 mt-6">
          <p className="text-gray-500">No projects match the selected filters.</p>
        </div>
      )}

      {totalCount > pageSize && (
        <div className="mt-6 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 bg-white border border-gray-200 rounded-xl p-3">
          <div className="text-sm text-gray-600">
            Showing page {currentPage} of {totalPages} ({totalCount} projects)
          </div>

          <div className="flex items-center gap-2">
            <select
              value={pageSize}
              onChange={(e) => {
                setPageSize(Number(e.target.value));
                setCurrentPage(1);
              }}
              className="border rounded-md px-2 py-1 text-sm"
            >
              <option value={6}>6 / page</option>
              <option value={9}>9 / page</option>
              <option value={12}>12 / page</option>
              <option value={18}>18 / page</option>
            </select>

            <button
              type="button"
              onClick={() => setCurrentPage((prev) => Math.max(1, prev - 1))}
              disabled={currentPage === 1}
              className="px-3 py-1.5 rounded-md border text-sm disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
            >
              Previous
            </button>

            <button
              type="button"
              onClick={() => setCurrentPage((prev) => Math.min(totalPages, prev + 1))}
              disabled={currentPage === totalPages}
              className="px-3 py-1.5 rounded-md border text-sm disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
            >
              Next
            </button>
          </div>
        </div>
      )}
    </div>
  );
}