/* eslint-disable no-unused-vars */
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Mail, Lock, ArrowRight, Loader2, ShieldCheck } from 'lucide-react';
import toast, { Toaster } from 'react-hot-toast';
import api from '../lib/api';
import { motion } from 'framer-motion';
import LogoWithoutBg from '../assets/LogoWithoutBg.png';

const Login = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    email: '',
    password: ''
  });

  // Handle Input Change
  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  // Handle Form Submit
  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      // 1. Target the Admin Login Endpoint specifically
      // Matches AuthController.cs: [HttpPost("admin/login")]
      const response = await api.post('/auth/admin/login', {
        emailOrRegNo: formData.email, // Mapping email input to the DTO field
        password: formData.password
      });

      const data = response.data;

      // 2. Save Token & User Details
      localStorage.setItem('token', data.token || data.Token);
      localStorage.setItem('role', 'Admin'); 
      localStorage.setItem('userId', data.userId || data.UserId);
      
      const toastId = toast.success('Welcome back, Administrator', {
        duration: 1200
      });

      // 3. Redirect directly to Admin Dashboard
      setTimeout(() => {
        toast.dismiss(toastId);
        navigate('/admin/dashboard');
      }, 1200);

    } catch (error) {
      console.error(error);
      const errorMsg = error.response?.data || "Access Denied. Invalid credentials.";
      // If the error is an object (sometimes .NET returns JSON), default to string
      toast.error(typeof errorMsg === 'string' ? errorMsg : "Login failed. Check your connection.");
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
          <div className="mb-8">
            <div className="inline-block bg-white rounded-2xl p-4 shadow-lg">
              <img 
                src={LogoWithoutBg} 
                alt="CUI Wah Job Fair Logo" 
                className="h-32 w-auto"
              />
            </div>
          </div>
          <h1 className="text-5xl font-bold mb-6 leading-tight">
            Admin <br/>
            <span className="text-indigo-400">Portal</span>
          </h1>
          <p className="text-lg text-slate-300 mb-8 leading-relaxed">
            Secure access to the Job Fair management system. Monitor student registrations, manage companies, and oversee room allocations.
          </p>
        </div>
      </div>

      {/* Right Side - Login Form */}
      <div className="w-full lg:w-1/2 flex items-center justify-center p-8">
        
        {/* Using motion.div here fixes the ESLint error */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="w-full max-w-md bg-white rounded-2xl shadow-xl p-8 border border-gray-100"
        >
          <div className="text-center mb-10">
            <div className="flex justify-center mb-6">
              <div className="inline-block bg-white rounded-xl p-3 shadow-md">
                <img 
                  src={LogoWithoutBg} 
                  alt="CUI Wah Job Fair Logo" 
                  className="h-20 w-auto"
                />
              </div>
            </div>
            <h2 className="text-2xl font-bold text-gray-900">Administrator Login</h2>
            <p className="text-gray-500 mt-2 text-sm">Please enter your credentials to continue</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            
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

            {/* Password Input */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">
                Password
              </label>
              <div className="relative group">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Lock className="h-5 w-5 text-gray-400 group-focus-within:text-indigo-600 transition-colors" />
                </div>
                <input
                  type="password"
                  name="password"
                  required
                  value={formData.password}
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
              className="w-full flex items-center justify-center py-3.5 px-4 rounded-xl shadow-lg shadow-indigo-500/30 text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all disabled:opacity-70 disabled:cursor-not-allowed transform active:scale-[0.98]"
            >
              {loading ? (
                <>
                  <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                  Verifying...
                </>
              ) : (
                <>
                  Access Dashboard
                  <ArrowRight className="ml-2 h-4 w-4" />
                </>
              )}
            </button>

          </form>
        </motion.div>
      </div>
      </div>
    </div>
  );
};

export default Login;