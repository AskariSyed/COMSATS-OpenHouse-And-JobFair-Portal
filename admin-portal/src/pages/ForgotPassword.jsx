import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { Mail, ShieldCheck, ArrowRight, ArrowLeft, Lock, Loader2 } from 'lucide-react';
import toast, { Toaster } from 'react-hot-toast';
import api from '../lib/api';
import { motion } from 'framer-motion';
import LogoWithoutBg from '../assets/LogoWithoutBg.png';

const ForgotPassword = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [step, setStep] = useState(1); // 1: Email, 2: OTP & New Password
  
  // Data from Step 1
  const [userId, setUserId] = useState(null);
  const [emailSentTo, setEmailSentTo] = useState('');

  // Form Data
  const [formData, setFormData] = useState({
    email: '',
    otp: '',
    newPassword: '',
    confirmPassword: ''
  });

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  // Step 1: Send OTP
  const handleSendOtp = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      const response = await api.post('/auth/forgot-password/send-otp', {
        emailOrRegNo: formData.email
      });
      
      const data = response.data;
      setUserId(data.UserId || data.userId);
      setEmailSentTo(data.Email || data.email || formData.email);
      setStep(2);
      
      toast.success(data.message || data.Message || 'OTP sent to your email.');
    } catch (error) {
      console.error(error);
      const errorMsg = error?.response?.data?.message || error?.response?.data?.Message || 'Failed to send OTP. Please check your email and try again.';
      toast.error(typeof errorMsg === 'string' ? errorMsg : 'Check your connection and try again.');
    } finally {
      setLoading(false);
    }
  };

  // Step 2: Verify OTP and Reset Password
  const handleResetPassword = async (e) => {
    e.preventDefault();
    if (formData.newPassword !== formData.confirmPassword) {
      return toast.error("Passwords do not match.");
    }
    if (formData.newPassword.length < 8) {
      return toast.error("Password must be at least 8 characters long.");
    }
    
    setLoading(true);

    try {
      const response = await api.post('/auth/forgot-password/verify-otp', {
        userId: userId,
        otp: formData.otp,
        newPassword: formData.newPassword,
        confirmPassword: formData.confirmPassword
      });
      
      const data = response.data;
      toast.success(data.message || data.Message || 'Password reset successfully.');
      
      setTimeout(() => {
        navigate('/');
      }, 1500);
      
    } catch (error) {
      console.error(error);
      const errorMsg = error?.response?.data?.message || error?.response?.data?.Message || error?.response?.data || 'Failed to reset password. Please check your OTP.';
      toast.error(typeof errorMsg === 'string' ? errorMsg : 'Invalid request. Check your details.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      <Toaster position="top-right" />
      <div className="flex-1 flex">

      {/* Left Side - Visual & Branding */}
      <div className="hidden lg:flex lg:w-1/2 bg-slate-900 relative overflow-hidden items-center justify-center text-white">
        {/* Background effects */}
        <div className="absolute inset-0 opacity-20">
          <div className="absolute top-0 left-0 w-96 h-96 bg-indigo-600 rounded-full mix-blend-multiply filter blur-3xl animate-blob"></div>
          <div className="absolute bottom-0 right-0 w-96 h-96 bg-blue-600 rounded-full mix-blend-multiply filter blur-3xl animate-blob animation-delay-2000"></div>
        </div>

        <div className="relative z-10 p-12 max-w-xl">
          <div className="mb-8 cursor-pointer" onClick={() => navigate('/')}>
            <img 
              src={LogoWithoutBg} 
              alt="CUI Wah Job Fair Logo" 
              className="h-32 w-auto hover:opacity-90 transition-opacity"
            />
          </div>
          <h1 className="text-5xl font-bold mb-6 leading-tight">
            Account <br/>
            <span className="text-indigo-400">Recovery</span>
          </h1>
          <p className="text-lg text-slate-300 mb-8 leading-relaxed">
            Regain access to the admin portal securely. We'll send an OTP to your registered email address to verify your identity.
          </p>
        </div>
      </div>

      {/* Right Side - Form */}
      <div className="w-full lg:w-1/2 flex items-center justify-center p-8">
        
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="w-full max-w-md bg-white rounded-2xl shadow-xl p-8 border border-gray-100"
        >
          <div className="text-center mb-10">
            <div className="flex justify-center mb-6 lg:hidden">
              <img 
                src={LogoWithoutBg} 
                alt="CUI Wah Job Fair Logo" 
                className="h-20 w-auto"
              />
            </div>
            <h2 className="text-2xl font-bold text-gray-900">
              {step === 1 ? 'Forgot Password' : 'Reset Password'}
            </h2>
            <p className="text-gray-500 mt-2 text-sm">
              {step === 1 
                ? 'Enter your email address to receive a one-time password.' 
                : `Enter the OTP sent to ${emailSentTo} and pick a new password.`}
            </p>
          </div>

          {step === 1 ? (
            <form onSubmit={handleSendOtp} className="space-y-6">
              {/* Email Input */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  Email Address
                </label>
                <div className="relative group">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Mail className="h-5 w-5 text-gray-400 group-focus-within:text-indigo-600 transition-colors" />
                  </div>
                  <input
                    type="email"
                    name="email"
                    required
                    value={formData.email}
                    onChange={handleChange}
                    className="block w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition-all outline-none bg-gray-50 focus:bg-white"
                    placeholder="admin@cuiwah.edu.pk"
                  />
                </div>
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                disabled={loading}
                className="w-full flex items-center justify-center py-3.5 px-4 rounded-xl shadow-lg shadow-indigo-500/30 text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all disabled:opacity-70 disabled:cursor-not-allowed transform active:scale-[0.98]"
              >
                {loading ? (
                  <>
                    <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                    Sending OTP...
                  </>
                ) : (
                  <>
                    Send OTP
                    <ArrowRight className="ml-2 h-4 w-4" />
                  </>
                )}
              </button>
            </form>
          ) : (
            <form onSubmit={handleResetPassword} className="space-y-5">
              {/* OTP Input */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  OTP Code
                </label>
                <div className="relative group">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <ShieldCheck className="h-5 w-5 text-gray-400 group-focus-within:text-indigo-600 transition-colors" />
                  </div>
                  <input
                    type="text"
                    name="otp"
                    required
                    value={formData.otp}
                    onChange={handleChange}
                    className="block w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition-all outline-none bg-gray-50 focus:bg-white tracking-widest uppercase font-mono"
                    placeholder="XXXXXX"
                  />
                </div>
              </div>

              {/* New Password Input */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  New Password
                </label>
                <div className="relative group">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Lock className="h-5 w-5 text-gray-400 group-focus-within:text-indigo-600 transition-colors" />
                  </div>
                  <input
                    type="password"
                    name="newPassword"
                    required
                    minLength={8}
                    value={formData.newPassword}
                    onChange={handleChange}
                    className="block w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition-all outline-none bg-gray-50 focus:bg-white"
                    placeholder="••••••••"
                  />
                </div>
              </div>

              {/* Confirm Password Input */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  Confirm Password
                </label>
                <div className="relative group">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Lock className="h-5 w-5 text-gray-400 group-focus-within:text-indigo-600 transition-colors" />
                  </div>
                  <input
                    type="password"
                    name="confirmPassword"
                    required
                    minLength={8}
                    value={formData.confirmPassword}
                    onChange={handleChange}
                    className="block w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition-all outline-none bg-gray-50 focus:bg-white"
                    placeholder="••••••••"
                  />
                </div>
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                disabled={loading}
                className="w-full flex items-center justify-center py-3.5 px-4 rounded-xl shadow-lg shadow-indigo-500/30 text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all disabled:opacity-70 disabled:cursor-not-allowed transform active:scale-[0.98] mt-2"
              >
                {loading ? (
                  <>
                    <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                    Resetting Password...
                  </>
                ) : (
                  <>
                    Confirm Reset
                    <ArrowRight className="ml-2 h-4 w-4" />
                  </>
                )}
              </button>
              
              <div className="text-center mt-4">
                <button 
                  type="button" 
                  onClick={() => setStep(1)}
                  disabled={loading}
                  className="text-sm font-medium text-indigo-600 hover:text-indigo-500 transition-colors"
                >
                  Didn't receive the email? Try again.
                </button>
              </div>
            </form>
          )}

          <div className="mt-8 text-center border-t border-gray-100 pt-6">
            <Link 
              to="/" 
              className="inline-flex items-center text-sm font-semibold text-gray-600 hover:text-gray-900 transition-colors"
            >
              <ArrowLeft className="mr-2 h-4 w-4" />
              Back to Login
            </Link>
          </div>
          
        </motion.div>
      </div>
      </div>
    </div>
  );
};

export default ForgotPassword;
