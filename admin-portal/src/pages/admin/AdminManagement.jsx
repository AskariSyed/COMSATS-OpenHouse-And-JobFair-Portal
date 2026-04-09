import React, { useEffect, useRef, useState } from 'react';
import {
  Loader2, ShieldCheck, Mail, KeyRound, UserPlus,
  CheckCircle2, XCircle, Ban, Trash2, ShieldAlert,
  RefreshCw, ArrowRight, X
} from 'lucide-react';
import { toast } from 'react-hot-toast';
import api from '../../lib/api';

const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// ─────────────────────────────────────────────────────────
// PasswordStrength (used for Change Password only)
// ─────────────────────────────────────────────────────────
const PasswordStrength = ({ password }) => {
  if (!password) return null;
  const rules = [
    { label: 'At least 9 characters', test: /.{9,}/ },
    { label: 'At least 1 uppercase letter', test: /[A-Z]/ },
    { label: 'At least 1 lowercase letter', test: /[a-z]/ },
    { label: 'At least 1 digit', test: /\d/ },
    { label: 'At least 1 special character', test: /[^A-Za-z0-9]/ },
  ];
  const score = rules.filter(r => r.test.test(password)).length;
  const colors = ['bg-red-500', 'bg-red-500', 'bg-orange-500', 'bg-amber-400', 'bg-lime-500', 'bg-green-600'];
  const textColors = ['text-red-500', 'text-red-500', 'text-orange-500', 'text-amber-500', 'text-lime-600', 'text-green-600'];
  return (
    <div className="space-y-1 mt-1 text-xs px-1">
      <div className="flex gap-1 h-1.5 w-full bg-gray-200 rounded-full overflow-hidden">
        <div className={`h-full transition-all duration-300 ${colors[score]}`} style={{ width: `${(score / 5) * 100}%` }}></div>
      </div>
      <div className={`font-medium ${textColors[score]}`}>
        {score === 5 ? 'Strong password' : score > 2 ? 'Medium password' : 'Weak password'}
      </div>
      <ul className="grid grid-cols-1 gap-1 text-[10px] text-gray-500 mt-1">
        {rules.map((r, i) => (
          <li key={i} className="flex items-center gap-1.5 break-words">
            {r.test.test(password) ? <CheckCircle2 className="w-3 h-3 text-green-500 flex-shrink-0" /> : <XCircle className="w-3 h-3 text-gray-300 flex-shrink-0" />}
            <span className={r.test.test(password) ? 'text-gray-900 line-through opacity-50' : ''}>{r.label}</span>
          </li>
        ))}
      </ul>
    </div>
  );
};

// ─────────────────────────────────────────────────────────
// OTP Input — 6 individual digit boxes
// ─────────────────────────────────────────────────────────
const OtpInput = ({ value, onChange, disabled }) => {
  const digits = (value + '      ').slice(0, 6).split('');
  const refs = Array.from({ length: 6 }, () => useRef(null));

  const handleKey = (e, idx) => {
    if (e.key === 'Backspace') {
      const next = [...digits];
      next[idx] = ' ';
      onChange(next.join('').trimEnd());
      if (idx > 0) refs[idx - 1].current?.focus();
      return;
    }
    if (!/^\d$/.test(e.key)) return;
    const next = [...digits];
    next[idx] = e.key;
    onChange(next.join('').trimEnd());
    if (idx < 5) refs[idx + 1].current?.focus();
  };

  const handlePaste = (e) => {
    const pasted = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, 6);
    if (pasted) { onChange(pasted); refs[Math.min(pasted.length, 5)].current?.focus(); }
    e.preventDefault();
  };

  return (
    <div className="flex gap-2 justify-center">
      {digits.map((d, i) => (
        <input
          key={i}
          ref={refs[i]}
          id={`otp-digit-${i}`}
          type="text"
          inputMode="numeric"
          maxLength={1}
          value={d === ' ' ? '' : d}
          onChange={() => {}}
          onKeyDown={(e) => handleKey(e, i)}
          onPaste={handlePaste}
          disabled={disabled}
          className={`w-11 h-12 text-center text-lg font-bold rounded-lg border-2 outline-none transition-all
            ${disabled ? 'bg-gray-50 text-gray-400 border-gray-200' : 'bg-white text-indigo-900'}
            ${d !== ' ' && d ? 'border-indigo-500 bg-indigo-50 shadow-sm' : 'border-gray-300'}
            focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100`}
        />
      ))}
    </div>
  );
};

// ─────────────────────────────────────────────────────────
// OTP Verification Modal
// ─────────────────────────────────────────────────────────
const OtpModal = ({ onClose, onVerified, adminEmail }) => {
  const [otp, setOtp] = useState('');
  const [sending, setSending] = useState(false);
  const [verifying, setVerifying] = useState(false);
  const [sent, setSent] = useState(false);
  const [countdown, setCountdown] = useState(0);
  const timerRef = useRef(null);

  useEffect(() => () => clearInterval(timerRef.current), []);

  const startCountdown = () => {
    setCountdown(60);
    clearInterval(timerRef.current);
    timerRef.current = setInterval(() => {
      setCountdown(prev => {
        if (prev <= 1) { clearInterval(timerRef.current); return 0; }
        return prev - 1;
      });
    }, 1000);
  };

  const sendOtp = async () => {
    setSending(true);
    try {
      await api.post('/admin/admins/send-otp');
      setSent(true);
      startCountdown();
      toast.success('OTP sent to your email.');
    } catch (err) {
      const msg = err?.response?.data?.message || err?.response?.data?.Message || 'Failed to send OTP.';
      toast.error(typeof msg === 'string' ? msg : 'Failed to send OTP.');
    } finally {
      setSending(false);
    }
  };

  const verifyOtp = async () => {
    if (otp.replace(/\s/g, '').length < 6) {
      toast.error('Please enter the 6-digit OTP.');
      return;
    }
    setVerifying(true);
    try {
      await api.post('/admin/admins/verify-otp', { otp: otp.trim() });
      toast.success('OTP verified!');
      onVerified(otp.trim());
    } catch (err) {
      const msg = err?.response?.data?.message || err?.response?.data?.Message || 'Invalid OTP.';
      toast.error(typeof msg === 'string' ? msg : 'Invalid OTP.');
    } finally {
      setVerifying(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden">
        {/* Modal header */}
        <div className="bg-gradient-to-r from-indigo-600 to-indigo-500 px-6 py-5 flex items-start justify-between">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <ShieldAlert className="w-5 h-5 text-indigo-200" />
              <h3 className="text-white font-semibold text-base">Identity Verification</h3>
            </div>
            <p className="text-indigo-200 text-xs">
              Confirm your identity before creating a co-admin account.
            </p>
          </div>
          <button onClick={onClose} className="text-indigo-200 hover:text-white ml-4 mt-0.5">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal body */}
        <div className="px-6 py-6 space-y-5">
          {!sent ? (
            <div className="text-center space-y-3">
              <div className="inline-flex items-center justify-center w-14 h-14 rounded-full bg-indigo-50 border-2 border-indigo-100">
                <Mail className="w-6 h-6 text-indigo-600" />
              </div>
              <div>
                <p className="text-sm text-gray-700 font-medium">Send OTP to your email</p>
                {adminEmail && (
                  <p className="text-xs text-gray-400 mt-1">An OTP will be sent to <strong>{adminEmail}</strong></p>
                )}
              </div>
              <button
                id="btn-send-otp"
                onClick={sendOtp}
                disabled={sending}
                className="w-full px-4 py-2.5 text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg disabled:opacity-60 flex items-center justify-center gap-2 transition-colors"
              >
                {sending ? <Loader2 size={15} className="animate-spin" /> : <Mail size={15} />}
                {sending ? 'Sending OTP…' : 'Send Verification OTP'}
              </button>
            </div>
          ) : (
            <div className="space-y-4">
              <div className="text-center">
                <p className="text-sm text-gray-700 font-medium">Enter the 6-digit code</p>
                <p className="text-xs text-gray-400 mt-1">
                  Check your inbox{adminEmail ? ` (${adminEmail})` : ''}
                </p>
              </div>

              <OtpInput value={otp} onChange={setOtp} disabled={verifying} />

              <button
                id="btn-verify-otp"
                onClick={verifyOtp}
                disabled={verifying || otp.trim().length < 6}
                className="w-full px-4 py-2.5 text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg disabled:opacity-50 flex items-center justify-center gap-2 transition-colors"
              >
                {verifying ? <Loader2 size={15} className="animate-spin" /> : <ArrowRight size={15} />}
                {verifying ? 'Verifying…' : 'Verify & Continue'}
              </button>

              <div className="flex items-center justify-center gap-1 text-xs text-gray-500">
                {countdown > 0 ? (
                  <span>Resend available in <strong>{countdown}s</strong></span>
                ) : (
                  <button
                    onClick={sendOtp}
                    disabled={sending}
                    className="flex items-center gap-1 text-indigo-600 hover:underline font-medium disabled:opacity-60"
                  >
                    <RefreshCw size={11} />
                    {sending ? 'Resending…' : 'Resend OTP'}
                  </button>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────
// Main AdminManagement Component
// ─────────────────────────────────────────────────────────
const AdminManagement = () => {
  const currentRole = localStorage.getItem('role') || '';
  const adminEmail = localStorage.getItem('email') || '';
  const isSuperAdmin = currentRole === 'Admin';

  const [admins, setAdmins] = useState([]);
  const [loadingAdmins, setLoadingAdmins] = useState(true);
  const [actionLoadingId, setActionLoadingId] = useState(null);
  const [banner, setBanner] = useState(null);

  // Create co-admin form
  const [createAdminForm, setCreateAdminForm] = useState({ name: '', email: '' });
  const [isCreatingAdmin, setIsCreatingAdmin] = useState(false);

  // OTP modal state
  const [showOtpModal, setShowOtpModal] = useState(false);
  const [pendingOtp, setPendingOtp] = useState(null); // set after OTP verified

  // Change email / password forms
  const [emailForm, setEmailForm] = useState({ newEmail: '', password: '' });
  const [passwordForm, setPasswordForm] = useState({ currentPassword: '', newPassword: '', confirmPassword: '' });
  const [isChangingEmail, setIsChangingEmail] = useState(false);
  const [isChangingPassword, setIsChangingPassword] = useState(false);

  const showBanner = (type, message) => setBanner({ type, message });

  const fetchAdmins = async () => {
    setLoadingAdmins(true);
    try {
      const res = await api.get('/admin/admins');
      const list = res?.data?.admins || res?.data?.Admins || [];
      setAdmins(Array.isArray(list) ? list : []);
    } catch (error) {
      const message = error?.response?.data?.message || error?.response?.data?.Message || error?.response?.data || 'Failed to fetch admin users.';
      toast.error(typeof message === 'string' ? message : JSON.stringify(message));
    } finally {
      setLoadingAdmins(false);
    }
  };

  useEffect(() => {
    if (isSuperAdmin) fetchAdmins();
    else setLoadingAdmins(false);
  }, [isSuperAdmin]);

  // Step 1 — validate form and open OTP modal
  const handleOpenOtpModal = (e) => {
    e.preventDefault();
    if (!isSuperAdmin) { toast.error('Only super admin can create co-admin accounts.'); return; }
    if (!createAdminForm.name.trim() || !createAdminForm.email.trim()) {
      toast.error('Please fill in both name and email.'); return;
    }
    if (!emailRegex.test(createAdminForm.email.trim())) {
      toast.error('Please enter a valid email address.'); return;
    }
    setPendingOtp(null);
    setShowOtpModal(true);
  };

  // Step 2 — OTP verified callback
  const handleOtpVerified = (verifiedOtp) => {
    setPendingOtp(verifiedOtp);
    setShowOtpModal(false);
    // Automatically submit creation
    submitCreateAdmin(verifiedOtp);
  };

  // Step 3 — Create co-admin
  const submitCreateAdmin = async (otp) => {
    setIsCreatingAdmin(true);
    try {
      await api.post('/admin/admins/create', {
        name: createAdminForm.name.trim(),
        email: createAdminForm.email.trim(),
        otp,
      });
      toast.success('Co-admin created! Credentials emailed to them.');
      showBanner('success', `Co-admin account created for ${createAdminForm.email.trim()}. Login credentials have been sent to their email.`);
      setCreateAdminForm({ name: '', email: '' });
      setPendingOtp(null);
      fetchAdmins();
    } catch (error) {
      const message = error?.response?.data?.message || error?.response?.data?.Message || error?.response?.data || 'Failed to create co-admin.';
      toast.error(typeof message === 'string' ? message : JSON.stringify(message));
      showBanner('error', typeof message === 'string' ? message : 'Failed to create co-admin.');
    } finally {
      setIsCreatingAdmin(false);
    }
  };

  const handleToggleBlock = async (admin) => {
    if (!isSuperAdmin) return;
    const adminId = admin.userId || admin.UserId;
    const isActive = Boolean(admin.isActive ?? admin.IsActive);
    setActionLoadingId(adminId);
    try {
      if (isActive) {
        await api.put(`/admin/admins/${adminId}/block`);
        toast.success('Co-admin blocked successfully.');
        showBanner('success', 'Co-admin blocked successfully.');
      } else {
        await api.put(`/admin/admins/${adminId}/unblock`);
        toast.success('Co-admin unblocked successfully.');
        showBanner('success', 'Co-admin unblocked successfully.');
      }
      fetchAdmins();
    } catch (error) {
      const message = error?.response?.data?.message || error?.response?.data?.Message || error?.response?.data || 'Failed to update co-admin status.';
      toast.error(typeof message === 'string' ? message : JSON.stringify(message));
      showBanner('error', typeof message === 'string' ? message : 'Failed to update co-admin status.');
    } finally {
      setActionLoadingId(null);
    }
  };

  const handleDeleteCoAdmin = async (admin) => {
    if (!isSuperAdmin) return;
    const adminId = admin.userId || admin.UserId;
    const adminName = admin.fullName || admin.FullName || admin.email || admin.Email || 'this co-admin';
    if (!window.confirm(`Delete ${adminName}? This action cannot be undone.`)) return;
    setActionLoadingId(adminId);
    try {
      await api.delete(`/admin/admins/${adminId}`);
      toast.success('Co-admin deleted successfully.');
      showBanner('success', 'Co-admin deleted successfully.');
      fetchAdmins();
    } catch (error) {
      const message = error?.response?.data?.message || error?.response?.data?.Message || error?.response?.data || 'Failed to delete co-admin profile.';
      toast.error(typeof message === 'string' ? message : JSON.stringify(message));
      showBanner('error', typeof message === 'string' ? message : 'Failed to delete co-admin profile.');
    } finally {
      setActionLoadingId(null);
    }
  };

  const handleChangeEmail = async (e) => {
    e.preventDefault();
    if (!emailForm.newEmail || !emailForm.password) { toast.error('Please fill both email and password.'); return; }
    if (!emailRegex.test(emailForm.newEmail.trim())) { toast.error('Please enter a valid new email.'); return; }
    setIsChangingEmail(true);
    try {
      await api.put('/admin/admins/change-email', { newEmail: emailForm.newEmail.trim(), password: emailForm.password });
      toast.success('Email changed successfully. Please login again.');
      localStorage.clear();
      window.location.href = '/';
    } catch (error) {
      const message = error?.response?.data?.message || error?.response?.data?.Message || error?.response?.data || 'Failed to change email.';
      toast.error(typeof message === 'string' ? message : JSON.stringify(message));
    } finally {
      setIsChangingEmail(false);
    }
  };

  const handleChangePassword = async (e) => {
    e.preventDefault();
    if (!passwordForm.currentPassword || !passwordForm.newPassword || !passwordForm.confirmPassword) {
      toast.error('Please fill all password fields.'); return;
    }
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{9,}$/;
    if (!passwordRegex.test(passwordForm.newPassword)) {
      toast.error('Password does not meet minimum requirement: at least one upper case, one lower case, 9 characters in total, one special character, and one digit.'); return;
    }
    if (passwordForm.newPassword !== passwordForm.confirmPassword) {
      toast.error('New password and confirm password do not match.'); return;
    }
    setIsChangingPassword(true);
    try {
      await api.put('/admin/admins/change-password', { currentPassword: passwordForm.currentPassword, newPassword: passwordForm.newPassword });
      toast.success('Password changed successfully.');
      setPasswordForm({ currentPassword: '', newPassword: '', confirmPassword: '' });
    } catch (error) {
      const message = error?.response?.data?.message || error?.response?.data?.Message || error?.response?.data || 'Failed to change password.';
      toast.error(typeof message === 'string' ? message : JSON.stringify(message));
    } finally {
      setIsChangingPassword(false);
    }
  };

  if (!isSuperAdmin) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Admin Management</h1>
          <p className="text-sm text-gray-500 mt-1">This section is available for super admin only.</p>
        </div>
        <div className="bg-amber-50 border border-amber-200 text-amber-800 rounded-lg p-4 text-sm font-medium">
          Access denied. Co-admin accounts cannot access admin management.
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* OTP Modal */}
      {showOtpModal && (
        <OtpModal
          adminEmail={adminEmail}
          onClose={() => setShowOtpModal(false)}
          onVerified={handleOtpVerified}
        />
      )}

      <div>
        <h1 className="text-2xl font-bold text-gray-900">Admin Management</h1>
        <p className="text-sm text-gray-500 mt-1">Create co-admin accounts and manage super admin credentials.</p>
      </div>

      {banner && (
        <div className={`rounded-lg border px-4 py-3 text-sm font-medium flex items-start justify-between gap-3 ${banner.type === 'success' ? 'bg-emerald-50 border-emerald-200 text-emerald-800' : 'bg-red-50 border-red-200 text-red-800'}`}>
          <span>{banner.message}</span>
          <button onClick={() => setBanner(null)} className="flex-shrink-0 opacity-60 hover:opacity-100"><X size={14} /></button>
        </div>
      )}

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {/* ── Create Co-Admin ── */}
        <div className="bg-white border border-gray-100 rounded-xl shadow-sm p-5">
          <div className="flex items-center gap-2 mb-1">
            <UserPlus className="w-5 h-5 text-indigo-600" />
            <h2 className="font-semibold text-gray-900">Create Co-Admin</h2>
          </div>
          <p className="text-xs text-gray-400 mb-4">
            Enter their name and email. A secure password will be auto-generated and emailed to them.
          </p>

          <form onSubmit={handleOpenOtpModal} className="space-y-3">
            <input
              id="coadmin-name"
              type="text"
              placeholder="Full Name"
              value={createAdminForm.name}
              onChange={(e) => setCreateAdminForm({ ...createAdminForm, name: e.target.value })}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
              required
            />
            <input
              id="coadmin-email"
              type="email"
              placeholder="Email address"
              value={createAdminForm.email}
              onChange={(e) => setCreateAdminForm({ ...createAdminForm, email: e.target.value })}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
              required
            />

            {/* Info callout */}
            <div className="bg-indigo-50 border border-indigo-100 rounded-lg p-3 text-xs text-indigo-700 flex gap-2 items-start">
              <ShieldAlert className="w-3.5 h-3.5 mt-0.5 flex-shrink-0" />
              <span>You'll receive an OTP on your email to verify this action before the account is created.</span>
            </div>

            <button
              id="btn-create-coadmin"
              type="submit"
              disabled={isCreatingAdmin}
              className="w-full px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg disabled:opacity-60 flex items-center justify-center gap-2 transition-colors"
            >
              {isCreatingAdmin ? <Loader2 size={16} className="animate-spin" /> : <UserPlus size={16} />}
              {isCreatingAdmin ? 'Creating…' : 'Create Co-Admin'}
            </button>
          </form>
        </div>

        {/* ── Change Email ── */}
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
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
              required
            />
            <input
              type="password"
              placeholder="Current Password"
              value={emailForm.password}
              onChange={(e) => setEmailForm({ ...emailForm, password: e.target.value })}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
              required
            />
            <button
              type="submit"
              disabled={isChangingEmail}
              className="w-full px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg disabled:opacity-60 flex items-center justify-center gap-2 transition-colors"
            >
              {isChangingEmail ? <Loader2 size={16} className="animate-spin" /> : null}
              {isChangingEmail ? 'Updating...' : 'Update Email'}
            </button>
          </form>
        </div>

        {/* ── Change Password ── */}
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
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
              required
            />
            <input
              type="password"
              placeholder="New Password"
              value={passwordForm.newPassword}
              onChange={(e) => setPasswordForm({ ...passwordForm, newPassword: e.target.value })}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
              required
            />
            <PasswordStrength password={passwordForm.newPassword} />
            <input
              type="password"
              placeholder="Confirm New Password"
              value={passwordForm.confirmPassword}
              onChange={(e) => setPasswordForm({ ...passwordForm, confirmPassword: e.target.value })}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
              required
            />
            <button
              type="submit"
              disabled={isChangingPassword}
              className="w-full px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg disabled:opacity-60 flex items-center justify-center gap-2 transition-colors"
            >
              {isChangingPassword ? <Loader2 size={16} className="animate-spin" /> : null}
              {isChangingPassword ? 'Updating...' : 'Update Password'}
            </button>
          </form>
        </div>
      </div>

      {/* ── Existing Co-Admins Table ── */}
      <div className="bg-white border border-gray-100 rounded-xl shadow-sm p-5">
        <div className="flex items-center gap-2 mb-4">
          <ShieldCheck className="w-5 h-5 text-indigo-600" />
          <h2 className="font-semibold text-gray-900">Existing Co-Admins</h2>
        </div>

        {loadingAdmins ? (
          <div className="flex items-center gap-2 text-sm text-gray-500">
            <Loader2 size={16} className="animate-spin" /> Loading admins...
          </div>
        ) : admins.length === 0 ? (
          <p className="text-sm text-gray-500">No co-admin accounts found.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead>
                <tr className="text-left text-gray-500 border-b border-gray-100">
                  <th className="py-2 pr-4">Name</th>
                  <th className="py-2 pr-4">Email</th>
                  <th className="py-2 pr-4">Role</th>
                  <th className="py-2 pr-4">Status</th>
                  <th className="py-2 pr-4">Created</th>
                  <th className="py-2 pr-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {admins.map((admin, idx) => (
                  <tr key={admin.userId || admin.UserId || idx} className="border-b border-gray-50">
                    <td className="py-2 pr-4 text-gray-900">{admin.fullName || admin.FullName || 'N/A'}</td>
                    <td className="py-2 pr-4 text-gray-700">{admin.email || admin.Email}</td>
                    <td className="py-2 pr-4 text-gray-600">CoAdmin</td>
                    <td className="py-2 pr-4">
                      {(admin.isActive ?? admin.IsActive) ? (
                        <span className="px-2 py-1 rounded-full text-xs bg-emerald-100 text-emerald-700">Active</span>
                      ) : (
                        <span className="px-2 py-1 rounded-full text-xs bg-red-100 text-red-700">Inactive</span>
                      )}
                    </td>
                    <td className="py-2 pr-4 text-gray-500">
                      {new Date(admin.createdAt || admin.CreatedAt || Date.now()).toLocaleDateString()}
                    </td>
                    <td className="py-2 pr-4">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => handleToggleBlock(admin)}
                          disabled={actionLoadingId === (admin.userId || admin.UserId)}
                          className={`px-2.5 py-1.5 rounded text-xs font-medium border ${
                            (admin.isActive ?? admin.IsActive)
                              ? 'bg-amber-50 text-amber-700 border-amber-200 hover:bg-amber-100'
                              : 'bg-emerald-50 text-emerald-700 border-emerald-200 hover:bg-emerald-100'
                          } disabled:opacity-60 inline-flex items-center gap-1`}
                        >
                          {actionLoadingId === (admin.userId || admin.UserId) ? <Loader2 className="w-3 h-3 animate-spin" /> : <Ban className="w-3 h-3" />}
                          {(admin.isActive ?? admin.IsActive) ? 'Block' : 'Unblock'}
                        </button>
                        <button
                          onClick={() => handleDeleteCoAdmin(admin)}
                          disabled={actionLoadingId === (admin.userId || admin.UserId)}
                          className="px-2.5 py-1.5 rounded text-xs font-medium border bg-red-50 text-red-700 border-red-200 hover:bg-red-100 disabled:opacity-60 inline-flex items-center gap-1"
                        >
                          <Trash2 className="w-3 h-3" /> Delete
                        </button>
                      </div>
                    </td>
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
