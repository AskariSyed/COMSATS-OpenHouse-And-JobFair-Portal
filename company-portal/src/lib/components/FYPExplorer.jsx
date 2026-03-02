import React, { useEffect, useState } from 'react';
import { Loader2, Github, ExternalLink, Users, Code2, PlayCircle } from 'lucide-react';
import { getFinalYearProjects } from '../api';
import { getThumbnailUrl } from '../utils/videoUtils';

export default function FYPExplorer({ onSelectProject, onError }) {
  const [projects, setProjects] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getFinalYearProjects()
      .then(data => setProjects(data.projects || []))
      .catch(err => onError(err.message))
      .finally(() => setLoading(false));
  }, [onError]);

  if (loading) return <div className="p-12 text-center"><Loader2 className="animate-spin mx-auto text-blue-600" /></div>;

  return (
    <div className="animate-fade-in">
      <div className="flex justify-between items-end mb-6">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Final Year Projects</h2>
          <p className="text-gray-500 text-sm">Discover innovative projects built by graduating students</p>
        </div>
        <span className="bg-blue-100 text-blue-700 px-3 py-1 rounded-full text-xs font-bold">
          {projects.length} Projects
        </span>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {projects.map(project => (
          <div 
            key={project.projectId} 
            onClick={() => onSelectProject(project.projectId)}
            className="group bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden flex flex-col h-full hover:shadow-xl hover:border-blue-300 transition-all cursor-pointer"
          >
            {/* Thumbnail Section */}
            <div className="h-48 bg-slate-100 relative overflow-hidden">
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

            <div className="p-5 flex-1 flex flex-col">
              <h3 className="font-bold text-lg text-gray-900 mb-2 line-clamp-1 group-hover:text-blue-600 transition-colors">
                {project.title}
              </h3>
              
              <p className="text-gray-600 text-sm mb-4 line-clamp-2 flex-1">{project.description}</p>

              <div className="flex flex-wrap gap-1.5 mb-4">
                {project.skills?.slice(0, 3).map((skill, i) => (
                  <span key={i} className="bg-blue-50 text-blue-700 px-2 py-1 rounded text-[10px] font-medium border border-blue-100">
                    {skill}
                  </span>
                ))}
                {project.skills?.length > 3 && <span className="text-xs text-gray-400 flex items-center">+{project.skills.length - 3}</span>}
              </div>

              <div className="pt-4 border-t border-gray-100 flex items-center justify-between text-xs text-gray-500">
                <div className="flex items-center gap-1">
                  <Users className="w-3 h-3" /> {project.totalStudents} Students
                </div>
                {project.gitHubUrl && <Github className="w-3 h-3" />}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}