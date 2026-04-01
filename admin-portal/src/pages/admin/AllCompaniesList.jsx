import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import api, { getAllJobFairs, blockCompany, unblockCompany, getFileUrl } from '../../lib/api';
import { toast } from 'react-hot-toast';
import { Eye, Ban, CheckCircle, Building2, Mail, Phone, Globe, Users, MapPin } from 'lucide-react';

const normalizeCompany = (company) => {
  const companyId = company.companyId || company.CompanyId || company.id || company.Id;
  return {
    ...company,
    companyId,
    name:
      company.name ||
      company.Name ||
      company.companyName ||
      company.CompanyName ||
      'Unknown Company',
    industry: company.industry || company.Industry || company.sector || company.Sector || company.category || company.Category || '',
    logoUrl: company.logoUrl || company.LogoUrl || company.logo || company.Logo || '',
    userEmail:
      company.userEmail ||
      company.UserEmail ||
      company.email ||
      company.Email ||
      company.contactEmail ||
      company.ContactEmail ||
      '',
    userPhone:
      company.userPhone ||
      company.UserPhone ||
      company.phone ||
      company.Phone ||
      company.contactNumber ||
      company.ContactNumber ||
      company.contactNo ||
      company.ContactNo ||
      '',
    website: company.website || company.Website || '',
    focalPersonName: company.focalPersonName || company.FocalPersonName || '',
    focalPersonEmail: company.focalPersonEmail || company.FocalPersonEmail || '',
    focalPersonPhone: company.focalPersonPhone || company.FocalPersonPhone || '',
    roomName: company.roomName || company.RoomName || company.roomNo || company.RoomNo || '',
    isBlocked: company.isBlocked ?? company.IsBlocked ?? false,
  };
};

const AllCompaniesList = () => {
  const navigate = useNavigate();
  const [jobFairs, setJobFairs] = useState([]);
  const [selectedJobFair, setSelectedJobFair] = useState('all');
  const [companies, setCompanies] = useState([]);
  const [loading, setLoading] = useState(false);
  const [tab, setTab] = useState('participated'); // 'participated' | 'all'


  // Move function declarations above useEffect to avoid hoisting errors
  const fetchJobFairs = async () => {
    try {
      const res = await getAllJobFairs();
      setJobFairs(res.data.jobFairs || res.data.JobFairs || res.data || []);
    } catch {
      toast.error('Failed to load job fairs');
    }
  };

  const fetchCompanies = async () => {
    setLoading(true);
    try {
      let response;
      if (tab === 'participated' && selectedJobFair !== 'all') {
        response = await api.get(`/admin/jobfairs/${selectedJobFair}/companies`);
        setCompanies((response.data.companies || response.data.Companies || response.data || []).map(normalizeCompany));
      } else if (tab === 'all') {
        response = await api.get('/admin/companies/all');
        setCompanies((response.data.companies || response.data.Companies || []).map(normalizeCompany));
      } else {
        response = await api.get('/admin/companies');
        setCompanies((response.data.companies || response.data.Companies || []).map(normalizeCompany));
      }
    } catch {
      toast.error('Failed to load companies');
    }
    setLoading(false);
  };

  useEffect(() => {
    fetchJobFairs();
  }, []);

  useEffect(() => {
    fetchCompanies();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedJobFair, tab]);

  const handleBlockToggle = async (company) => {
    try {
      if (company.isBlocked) {
        await unblockCompany(company.companyId);
        toast.success('Company unblocked');
      } else {
        await blockCompany(company.companyId);
        toast.success('Company blocked');
      }
      fetchCompanies();
    } catch {
      toast.error('Failed to update block status');
    }
  };

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">All Companies Directory</h1>
      <div className="flex gap-4 mb-4">
        <select
          className="border rounded px-3 py-2 bg-white text-gray-900 font-medium"
          style={{ color: '#111827', backgroundColor: '#ffffff' }}
          value={selectedJobFair}
          onChange={e => setSelectedJobFair(e.target.value)}
        >
          <option value="all" style={{ color: '#111827', backgroundColor: '#ffffff' }}>All Job Fairs</option>
          {jobFairs.map(jf => (
            <option
              key={jf.jobFairId || jf.JobFairId}
              value={jf.jobFairId || jf.JobFairId}
              style={{ color: '#111827', backgroundColor: '#ffffff' }}
            >
              {jf.semester || jf.Semester || jf.title || jf.Title || jf.name || jf.Name || `Job Fair ${jf.jobFairId || jf.JobFairId}`}
            </option>
          ))}
        </select>
        <button
          className={`px-4 py-2 rounded ${tab === 'participated' ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-gray-700'}`}
          onClick={() => setTab('participated')}
        >
          Participated Companies
        </button>
        <button
          className={`px-4 py-2 rounded ${tab === 'all' ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-gray-700'}`}
          onClick={() => setTab('all')}
        >
          All Companies
        </button>
      </div>
      <div className="bg-white rounded-xl border shadow-sm overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-4 text-left">Company</th>
              <th className="px-6 py-4 text-left">Industry</th>
              <th className="px-6 py-4 text-left">Company Contact</th>
              <th className="px-6 py-4 text-left">Focal Person</th>
              <th className="px-6 py-4 text-left">Room Status</th>
              <th className="px-6 py-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan="6" className="text-center py-8">Loading...</td></tr>
            ) : companies.length === 0 ? (
              <tr><td colSpan="6" className="text-center py-8">No companies found.</td></tr>
            ) : (
              companies.map(company => (
                <tr
                  key={company.companyId}
                  className="border-b hover:bg-indigo-50 cursor-pointer"
                  onClick={() => navigate(`/admin/companies/${company.companyId}`, { state: { from: '/admin/companies/all' } })}
                >
                  <td className="px-6 py-4 max-w-[420px]">
                    <div className="flex items-center gap-3">
                      <div className="p-2 bg-gray-50 rounded-lg border border-gray-100">
                        {company.logoUrl ? (
                          <img src={getFileUrl(company.logoUrl)} alt="Logo" className="w-6 h-6 object-contain" />
                        ) : (
                          <Building2 className="text-gray-400" size={20} />
                        )}
                      </div>
                      <div className="min-w-0">
                        <p className="font-semibold text-gray-900 break-words whitespace-normal leading-snug" title={company.name}>
                          {company.name}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">{company.industry || 'General'}</td>
                  <td className="px-6 py-4">
                    <div className="flex flex-col gap-1">
                      {company.userEmail && (
                        <div className="flex items-center text-sm text-gray-600 gap-2">
                          <Mail size={14} className="text-gray-400 flex-shrink-0" />
                          <span className="truncate" title={company.userEmail}>{company.userEmail}</span>
                        </div>
                      )}
                      {company.userPhone && (
                        <div className="flex items-center text-sm text-gray-600 gap-2">
                          <Phone size={14} className="text-gray-400 flex-shrink-0" />
                          <span className="truncate">{company.userPhone}</span>
                        </div>
                      )}
                      {company.website && (
                        <div className="flex items-center text-sm text-gray-600 gap-2">
                          <Globe size={14} className="text-gray-400 flex-shrink-0" />
                          <span className="truncate">{company.website.replace(/^https?:\/\//, '')}</span>
                        </div>
                      )}
                      {!company.userEmail && !company.userPhone && !company.website && (
                        <span className="text-sm text-gray-400">No contact info</span>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex flex-col gap-1.5">
                      {company.focalPersonName && (
                        <div className="flex items-start gap-2">
                          <Users size={14} className="text-gray-400 mt-0.5 flex-shrink-0" />
                          <div className="overflow-hidden">
                            <p className="text-sm font-medium text-gray-900 truncate" title={company.focalPersonName}>
                              {company.focalPersonName}
                            </p>
                          </div>
                        </div>
                      )}
                      {company.focalPersonEmail && (
                        <div className="flex items-center text-xs text-gray-600 gap-2 ml-5">
                          <Mail size={12} className="text-gray-400 flex-shrink-0" />
                          <span className="truncate" title={company.focalPersonEmail}>{company.focalPersonEmail}</span>
                        </div>
                      )}
                      {company.focalPersonPhone && (
                        <div className="flex items-center text-xs text-gray-600 gap-2 ml-5">
                          <Phone size={12} className="text-gray-400 flex-shrink-0" />
                          <span className="truncate">{company.focalPersonPhone}</span>
                        </div>
                      )}
                      {!company.focalPersonName && !company.focalPersonEmail && !company.focalPersonPhone && (
                        <span className="text-sm text-gray-400">No focal person info</span>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    {company.roomName ? (
                      <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-green-100 text-green-700">
                        <MapPin size={12} /> {company.roomName}
                      </span>
                    ) : (
                      <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-yellow-100 text-yellow-700">
                        Not Allocated
                      </span>
                    )}
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex justify-end gap-2" onClick={(e) => e.stopPropagation()}>
                    <button
                      onClick={() => handleBlockToggle(company)}
                      className={`p-2 rounded ${company.isBlocked ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}
                      title={company.isBlocked ? 'Unblock Company' : 'Block Company'}
                    >
                      {company.isBlocked ? <CheckCircle size={16} /> : <Ban size={16} />}
                    </button>
                    <button
                      className="p-2 rounded bg-blue-100 text-blue-700"
                      onClick={() => navigate(`/admin/companies/${company.companyId}`, { state: { from: '/admin/companies/all' } })}
                      title="View Company"
                    >
                      <Eye size={16} />
                    </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default AllCompaniesList;
