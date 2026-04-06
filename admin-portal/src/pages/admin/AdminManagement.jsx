import React, { useEffect, useState } from 'react';
import { Loader2, ShieldCheck, Mail, KeyRound, UserPlus } from 'lucide-react';
import { toast } from 'react-hot-toast';
import api from '../../lib/api';

const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const AdminManagement = () => {
  const [admins, setAdmins] = useState([]);
  const [loadingAdmins, setLoadingAdmins] = useState(true);

  const [createAdminForm, setCreateAdminForm] = useState({
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
  });
  const [emailForm, setEmailForm] = useState({
    newEmail: '',
    password: '',
  });
  const [passwordForm, setPasswordForm] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
  });

  const [isCreatingAdmin, setIsCreatingAdmin] = useState(false);
  const [isChangingEmail, setIsChangingEmail] = useState(false);
  const [isChangingPassword, setIsChangingPassword] = useState(false);

  const fetchAdmins = async () => {
    setLoadingAdmins(true);
    try {
      const res = await api.get('/admin/admins');
      const list = res?.data?.admins || res?.data?.Admins || [];
      setAdmins(Array.isArray(list) ? list : []);
    } catch (error) {
      const message =
        error?.response?.data?.message ||
        error?.response?.data ||
        'Failed to fetch admin users.';
      toast.error(String(message));
    } finally {
      setLoadingAdmins(false);
    }
  };

  useEffect(() => {
    fetchAdmins();
  }, []);

  const handleCreateAdmin = async (e) => {
    e.preventDefault();

    if (!createAdminForm.name || !createAdminForm.email || !createAdminForm.password || !createAdminForm.confirmPassword) {
      toast.error('Please fill all fields for new admin.');
      return;
    }

    if (!emailRegex.test(createAdminForm.email.trim())) {
      toast.error('Please enter a valid admin email.');
      return;
    }

    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{9,}$/;
    if (!passwordRegex.test(createAdminForm.password)) {
      toast.error('Password does not meet minimum requirement: at least one upper case, one lower case, 9 characters in total, one special character, and one digit.');
      return;
    }

    if (createAdminForm.password !== createAdminForm.confirmPassword) {
      toast.error('Password and confirm password do not match.');
      return;
    }

    setIsCreatingAdmin(true);
    try {
      await api.post('/admin/admins/create', {
        name: createAdminForm.name.trim(),
        email: createAdminForm.email.trim(),
        password: createAdminForm.password,
      });
      toast.success('Admin created successfully.');
      setCreateAdminForm({ name: '', email: '', password: '', confirmPassword: '' });
      fetchAdmins();
    } catch (error) {
      const message =
        error?.response?.data?.message ||
        error?.response?.data ||
        'Failed to create admin.';
      toast.error(String(message));
    } finally {
      setIsCreatingAdmin(false);
    }
  };

  const handleChangeEmail = async (e) => {
    e.preventDefault();

    if (!emailForm.newEmail || !emailForm.password) {
      toast.error('Please fill both email and password.');
      return;
    }

    if (!emailRegex.test(emailForm.newEmail.trim())) {
      toast.error('Please enter a valid new email.');
      return;
    }

    setIsChangingEmail(true);
    try {
      await api.put('/admin/admins/change-email', {
        newEmail: emailForm.newEmail.trim(),
        password: emailForm.password,
      });
      toast.success('Email changed successfully. Please login again.');
      localStorage.clear();
      window.location.href = '/';
    } catch (error) {
      const message =
        error?.response?.data?.message ||
        error?.response?.data ||
        'Failed to change email.';
      toast.error(String(message));
    } finally {
      setIsChangingEmail(false);
    }
  };

  const handleChangePassword = async (e) => {
    e.preventDefault();

    if (!passwordForm.currentPassword || !passwordForm.newPassword || !passwordForm.confirmPassword) {
      toast.error('Please fill all password fields.');
      return;
    }

    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{9,}$/;
    if (!passwordRegex.test(passwordForm.newPassword)) {
      toast.error('Password does not meet minimum requirement: at least one upper case, one lower case, 9 characters in total, one special character, and one digit.');
      return;
    }

    if (passwordForm.newPassword !== passwordForm.confirmPassword) {
      toast.error('New password and confirm password do not match.');
      return;
    }

    setIsChangingPassword(true);
    try {
      await api.put('/admin/admins/change-password', {
        currentPassword: passwordForm.currentPassword,
        newPassword: passwordForm.newPassword,
      });
      toast.success('Password changed successfully.');
      setPasswordForm({ currentPassword: '', newPassword: '', confirmPassword: '' });
    } catch (error) {
      const message =
        error?.response?.data?.message ||
        error?.response?.data ||
        'Failed to change password.';
      toast.error(String(message));
    } finally {
      setIsChangingPassword(false);
    }
  };

  return (
    <div className="space-y-6 animate-fade-in">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Admin Management</h1>
        <p className="text-sm text-gray-500 mt-1">Create admins and manage your own admin credentials.</p>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <div className="bg-white border border-gray-100 rounded-xl shadow-sm p-5">
          <div className="flex items-center gap-2 mb-4">
            <UserPlus className="w-5 h-5 text-indigo-600" />
            <h2 className="font-semibold text-gray-900">Create Admin</h2>
          </div>
          <form onSubmit={handleCreateAdmin} className="space-y-3">
            <input
              type="text"
              placeholder="Full Name"
              value={createAdminForm.name}
              onChange={(e) => setCreateAdminForm({ ...createAdminForm, name: e.target.value })}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              required
            />
            <input
              type="email"
              placeholder="Email"
              value={createAdminForm.email}
              onChange={(e) => setCreateAdminForm({ ...createAdminForm, email: e.target.value })}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              required
            />
            <input
              type="password"
              placeholder="Password"
              value={createAdminForm.password}
              onChange={(e) => setCreateAdminForm({ ...createAdminForm, password: e.target.value })}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              required
            />
            <input
              type="password"
              placeholder="Confirm Password"
              value={createAdminForm.confirmPassword}
              onChange={(e) => setCreateAdminForm({ ...createAdminForm, confirmPassword: e.target.value })}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              required
            />
            <button
              type="submit"
              disabled={isCreatingAdmin}
              className="w-full px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg disabled:opacity-60 flex items-center justify-center gap-2"
            >
              {isCreatingAdmin ? <Loader2 size={16} className="animate-spin" /> : null}
              {isCreatingAdmin ? 'Creating...' : 'Create Admin'}
            </button>
          </form>
        </div>

        <div className="bg-white border border-gray-100 rounded-xl shadow-sm p-5">
          <div className="flex items-center gap-2 mb-4">
            <Mail className="w-5 h-5 text-indigo-600" />
            <h2 className="font-semibold text-gray-900">Change My Email</h2>
          </div>
          <form onSubmit={handleChangeEmail} className="space-y-3">
            <input
              type="email"
              placeholder="New Email"
              value={emailForm.newEmail}
              onChange={(e) => setEmailForm({ ...emailForm, newEmail: e.target.value })}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              required
            />
            <input
              type="password"
              placeholder="Current Password"
              value={emailForm.password}
              onChange={(e) => setEmailForm({ ...emailForm, password: e.target.value })}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              required
            />
            <button
              type="submit"
              disabled={isChangingEmail}
              className="w-full px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg disabled:opacity-60 flex items-center justify-center gap-2"
            >
              {isChangingEmail ? <Loader2 size={16} className="animate-spin" /> : null}
              {isChangingEmail ? 'Updating...' : 'Update Email'}
            </button>
          </form>
        </div>

        <div className="bg-white border border-gray-100 rounded-xl shadow-sm p-5">
          <div className="flex items-center gap-2 mb-4">
            <KeyRound className="w-5 h-5 text-indigo-600" />
            <h2 className="font-semibold text-gray-900">Change My Password</h2>
          </div>
          <form onSubmit={handleChangePassword} className="space-y-3">
            <input
              type="password"
              placeholder="Current Password"
              value={passwordForm.currentPassword}
              onChange={(e) => setPasswordForm({ ...passwordForm, currentPassword: e.target.value })}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              required
            />
            <input
              type="password"
              placeholder="New Password"
              value={passwordForm.newPassword}
              onChange={(e) => setPasswordForm({ ...passwordForm, newPassword: e.target.value })}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              required
            />
            <input
              type="password"
              placeholder="Confirm New Password"
              value={passwordForm.confirmPassword}
              onChange={(e) => setPasswordForm({ ...passwordForm, confirmPassword: e.target.value })}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              required
            />
            <button
              type="submit"
              disabled={isChangingPassword}
              className="w-full px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg disabled:opacity-60 flex items-center justify-center gap-2"
            >
              {isChangingPassword ? <Loader2 size={16} className="animate-spin" /> : null}
              {isChangingPassword ? 'Updating...' : 'Update Password'}
            </button>
          </form>
        </div>
      </div>

      <div className="bg-white border border-gray-100 rounded-xl shadow-sm p-5">
        <div className="flex items-center gap-2 mb-4">
          <ShieldCheck className="w-5 h-5 text-indigo-600" />
          <h2 className="font-semibold text-gray-900">Existing Admins</h2>
        </div>

        {loadingAdmins ? (
          <div className="flex items-center gap-2 text-sm text-gray-500">
            <Loader2 size={16} className="animate-spin" />
            Loading admins...
          </div>
        ) : admins.length === 0 ? (
          <p className="text-sm text-gray-500">No admin accounts found.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead>
                <tr className="text-left text-gray-500 border-b border-gray-100">
                  <th className="py-2 pr-4">Name</th>
                  <th className="py-2 pr-4">Email</th>
                  <th className="py-2 pr-4">Status</th>
                  <th className="py-2 pr-4">Created</th>
                </tr>
              </thead>
              <tbody>
                {admins.map((admin, idx) => (
                  <tr key={admin.userId || admin.UserId || idx} className="border-b border-gray-50">
                    <td className="py-2 pr-4 text-gray-900">{admin.fullName || admin.FullName || 'N/A'}</td>
                    <td className="py-2 pr-4 text-gray-700">{admin.email || admin.Email}</td>
                    <td className="py-2 pr-4">
                      {(admin.isActive ?? admin.IsActive) ? (
                        <span className="px-2 py-1 rounded-full text-xs bg-emerald-100 text-emerald-700">Active</span>
                      ) : (
                        <span className="px-2 py-1 rounded-full text-xs bg-red-100 text-red-700">Inactive</span>
                      )}
                    </td>
                    <td className="py-2 pr-4 text-gray-500">{new Date(admin.createdAt || admin.CreatedAt || Date.now()).toLocaleDateString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default AdminManagement;
