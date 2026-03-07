import React, { useEffect, useMemo, useState } from 'react';
import { Loader2, Github, Users, Code2, PlayCircle, Search } from 'lucide-react';
import { getFinalYearProjects } from '../api';
import { getThumbnailUrl } from '../utils/videoUtils';

export default function FYPExplorer({ onSelectProject, onError }) {
  const [projects, setProjects] = useState([]);
  const [loading, setLoading] = useState(true);
  const [studentQuery, setStudentQuery] = useState('');
  const [departmentFilter, setDepartmentFilter] = useState('');
  const [fypQuery, setFypQuery] = useState('');

  useEffect(() => {
    getFinalYearProjects()
      .then(data => setProjects(data.projects || []))
      .catch(err => onError(err.message))
      .finally(() => setLoading(false));
  }, [onError]);

  const normalize = (value) => String(value || '').trim().toLowerCase();
  const cleanReg = (value) => normalize(value).replace(/[^a-z0-9]/g, '');

  const getProjectStudents = (project) => project.students || project.teamMembers || project.members || [];

  const departmentOptions = useMemo(() => {
    const buckets = new Set();
    projects.forEach((project) => {
      const projectDepartment = project.department || project.Department;
      if (projectDepartment) buckets.add(projectDepartment);

      getProjectStudents(project).forEach((student) => {
        const dept = student.department || student.Department;
        if (dept) buckets.add(dept);
      });
    });

    return [...buckets].sort((a, b) => a.localeCompare(b));
  }, [projects]);

  const filteredProjects = useMemo(() => {
    const studentNeedle = normalize(studentQuery);
    const studentRegNeedle = cleanReg(studentQuery);
    const fypNeedle = normalize(fypQuery);
    const departmentNeedle = normalize(departmentFilter);

    return projects.filter((project) => {
      const title = normalize(project.title || project.name);
      const students = getProjectStudents(project);
      const projectDepartment = normalize(project.department || project.Department);

      const projectLevelStudentNames = Array.isArray(project.studentNames)
        ? project.studentNames.map((n) => normalize(n)).join(' ')
        : normalize(project.studentNames || project.studentNameList);
      const projectLevelRegistrations = Array.isArray(project.studentRegistrations)
        ? project.studentRegistrations.map((r) => cleanReg(r)).join(' ')
        : cleanReg(project.studentRegistrations || project.studentRegistrationNos || '');

      const matchesFyp = !fypNeedle || title.includes(fypNeedle);

      const matchesStudent = !studentNeedle || (
        students.some((student) => {
          const studentName = normalize(student.fullName || student.name || student.studentName);
          const studentReg = cleanReg(student.registrationNo || student.registration || student.regNo);
          return studentName.includes(studentNeedle) || (studentRegNeedle && studentReg.includes(studentRegNeedle));
        })
        || projectLevelStudentNames.includes(studentNeedle)
        || (studentRegNeedle && projectLevelRegistrations.includes(studentRegNeedle))
      );

      const matchesDepartment = !departmentNeedle || (
        projectDepartment === departmentNeedle
        || students.some((student) => normalize(student.department || student.Department) === departmentNeedle)
      );

      return matchesFyp && matchesStudent && matchesDepartment;
    });
  }, [projects, studentQuery, departmentFilter, fypQuery]);

  if (loading) return <div className="p-12 text-center"><Loader2 className="animate-spin mx-auto text-blue-600" /></div>;

  return (
    <div className="animate-fade-in">
      <div className="flex justify-between items-end mb-6">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Final Year Projects</h2>
          <p className="text-gray-500 text-sm">Discover innovative projects built by graduating students</p>
        </div>
        <span className="bg-blue-100 text-blue-700 px-3 py-1 rounded-full text-xs font-bold">
          {filteredProjects.length} / {projects.length} Projects
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
                onChange={(e) => setStudentQuery(e.target.value)}
                placeholder="e.g. SP22-BCS-011 or Ali"
                className="w-full border rounded-lg p-2 pl-9"
              />
            </div>
          </div>

          <div>
            <label className="text-xs font-semibold text-gray-500 uppercase block mb-1">Department</label>
            <select
              value={departmentFilter}
              onChange={(e) => setDepartmentFilter(e.target.value)}
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
                onChange={(e) => setFypQuery(e.target.value)}
                placeholder="Search by project title"
                className="w-full border rounded-lg p-2 pl-9"
              />
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredProjects.map(project => (
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

      {filteredProjects.length === 0 && (
        <div className="text-center py-12 bg-white rounded-xl border border-dashed border-gray-200 mt-6">
          <p className="text-gray-500">No projects match the selected filters.</p>
        </div>
      )}
    </div>
  );
}