import React, { useState } from 'react';
import { Building2, Loader2, Lock, Mail, ArrowRight, Sparkles, KeyRound, CheckCircle2, ChevronLeft } from 'lucide-react';
import { login, verifyOtp } from '../api';
import { requestFcmToken } from '../firebase';
import logo from '../../assets/CuiWahJobFairLogo.png';

export default function LoginPage({ onLogin, onNavigate, onError }) {
  const [role] = useState('Company');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [otp, setOtp] = useState('');
  const [loading, setLoading] = useState(false);
  
  // New State to toggle OTP View
  const [showOtpInput, setShowOtpInput] = useState(false);

  // --- VALIDATION ---
  const validateEmail = (email) => {
    const emailRegex = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    return emailRegex.test(email);
  };

  // --- LOGIN HANDLER ---
  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // Validate email
    if (!validateEmail(email)) {
      onError("Please enter a valid email address.");
      return;
    }
    setLoading(true);
    
    try {
      // 1. Try getting FCM Token (optional)
      let fcmToken = null;
      try { fcmToken = await requestFcmToken(); } catch (e) { console.warn(e); }

      // 2. Attempt Login
      const data = await login(role, email, password, fcmToken);
      onLogin(data);

    } catch (err) {
      const errorMsg = err.message || "Login failed";
      
      // 🛑 DETECT UNVERIFIED ACCOUNT
      if (errorMsg.includes("Account not verified") || errorMsg.includes("OTP")) {
        setShowOtpInput(true);
        onError("Please verify your email to continue."); // Show toast
      } else {
        onError(errorMsg);
      }
    } finally {
      setLoading(false);
    }
  };

  // --- OTP VERIFICATION HANDLER ---
  const handleVerify = async (e) => {
    e.preventDefault();
    
    // Validate OTP (digits only, 6 characters)
    if (!/^\d{6}$/.test(otp)) {
      onError("OTP must be 6 digits.");
      return;
    }
    
    setLoading(true);
    try {
      // Assuming UserEmail and RepEmail are the same for the focal person
      await verifyOtp(email, email, otp);
      
      // If successful, auto-login the user
      // We assume the backend activates the user, so login should work now
      const data = await login(role, email, password);
      onLogin(data);
      
    } catch (err) {
      onError(err.message || "Invalid OTP");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex bg-white">
      
      {/* LEFT SIDE - Hero & Quote (Hidden on mobile) */}
      <div className="hidden lg:flex lg:w-1/2 bg-slate-900 relative flex-col justify-between p-12 overflow-hidden">
        <div className="absolute top-0 left-0 w-full h-full z-0">
          <div className="absolute top-10 left-10 w-72 h-72 bg-blue-600 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-blob"></div>
          <div className="absolute top-10 right-10 w-72 h-72 bg-purple-600 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-blob animation-delay-2000"></div>
          <div className="absolute bottom-10 left-20 w-72 h-72 bg-pink-600 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-blob animation-delay-4000"></div>
        </div>

        <div className="relative z-10 flex items-center gap-3 text-white">
          <img src={logo} alt="CUI Wah Job Fair" className="w-10 h-10 rounded-lg object-contain" />
          <span className="text-2xl font-bold tracking-tight">CUI Wah JobFair Company Portal</span>
        </div>

        <div className="relative z-10 mb-12">
          <div className="mb-6 text-blue-400">
            <Sparkles className="w-8 h-8" />
          </div>
          <blockquote className="text-4xl font-bold text-white leading-tight mb-6">
            "Great vision without great people is irrelevant."
          </blockquote>
          <div className="flex items-center gap-4">
            <div className="h-1 w-12 bg-blue-500 rounded-full"></div>
            <p className="text-slate-400 font-medium">Jim Collins</p>
          </div>
        </div>

        <div className="relative z-10 text-slate-500 text-sm">
          © 2025 CUI Wah Campus. All rights reserved.
        </div>
      </div>

      {/* RIGHT SIDE - Dynamic Form */}
      <div className="w-full lg:w-1/2 flex items-center justify-center p-8 bg-gray-50 lg:bg-white">
        <div className="w-full max-w-md space-y-8 animate-fade-in">
          
          {/* HEADER TEXT */}
          <div className="text-center lg:text-left">
             <img src={logo} alt="CUI Wah Job Fair" className="lg:hidden w-12 h-12 rounded-xl mx-auto mb-4 object-contain" />
             <h2 className="text-3xl font-bold text-gray-900">
               {showOtpInput ? "Verify Account" : "Welcome Back"}
             </h2>
             <p className="text-gray-500 mt-2">
               {showOtpInput 
                 ? `Enter the OTP sent to ${email}` 
                 : "Enter your credentials to access your hiring dashboard."}
             </p>
          </div>

          {/* CONDITIONAL FORM RENDERING */}
          {!showOtpInput ? (
            // --- LOGIN FORM ---
            <form onSubmit={handleSubmit} className="space-y-6 mt-8">
              <div className="space-y-2">
                <label className="text-sm font-medium text-gray-700">Email Address</label>
                <div className="relative">
                  <Mail className="absolute left-3 top-3.5 w-5 h-5 text-gray-400" />
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-blue-500 outline-none transition-all"
                    placeholder="hr@company.com"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <label className="text-sm font-medium text-gray-700">Password</label>
                  <button 
                    type="button"
                    onClick={() => onNavigate('forgot-password')}
                    className="text-sm font-medium text-blue-600 hover:text-blue-700 transition-colors"
                  >
                    Forgot Password?
                  </button>
                </div>
                <div className="relative">
                  <Lock className="absolute left-3 top-3.5 w-5 h-5 text-gray-400" />
                  <input
                    type="password"
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-blue-500 outline-none transition-all"
                    placeholder="••••••••"
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3.5 rounded-xl font-bold shadow-lg shadow-blue-600/30 transform transition hover:-translate-y-0.5 disabled:opacity-70 flex justify-center items-center gap-2"
              >
                {loading ? <Loader2 className="animate-spin h-5 w-5" /> : <>Sign In <ArrowRight className="w-4 h-4" /></>}
              </button>
            </form>
          ) : (
            // --- OTP FORM ---
            <form onSubmit={handleVerify} className="space-y-6 mt-8 animate-fade-in">
              <div className="space-y-2">
                <label className="text-sm font-medium text-gray-700">Validation Code</label>
                <div className="relative">
                  <KeyRound className="absolute left-3 top-3.5 w-5 h-5 text-gray-400" />
                  <input
                    type="text"
                    required
                    maxLength={6}
                    value={otp}
                    onChange={(e) => setOtp(e.target.value)}
                    className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-blue-500 outline-none transition-all text-center tracking-widest font-mono text-lg"
                    placeholder="000000"
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-green-600 hover:bg-green-700 text-white py-3.5 rounded-xl font-bold shadow-lg shadow-green-600/30 transform transition hover:-translate-y-0.5 disabled:opacity-70 flex justify-center items-center gap-2"
              >
                {loading ? <Loader2 className="animate-spin h-5 w-5" /> : <>Verify & Login <CheckCircle2 className="w-4 h-4" /></>}
              </button>
              
              <button 
                type="button" 
                onClick={() => setShowOtpInput(false)}
                className="w-full text-gray-500 text-sm hover:text-gray-700 flex justify-center items-center gap-1"
              >
                <ChevronLeft className="w-4 h-4" /> Use a different account
              </button>
            </form>
          )}

          {/* FOOTER - Only show in login mode */}
          {!showOtpInput && (
            <div className="pt-6 text-center border-t border-gray-100">
              <p className="text-gray-500 text-sm">
                Don't have an account yet?{' '}
                <button 
                  onClick={() => onNavigate('register')} 
                  className="font-semibold text-blue-600 hover:text-blue-700 transition-colors"
                >
                  Register Company
                </button>
              </p>

              <div className="mt-4 rounded-xl border border-blue-200 bg-blue-50 p-3 text-center">
                <p className="text-xs font-medium text-blue-800">
                  📚 <strong>Disclaimer:</strong> This is a Final Year Project by COMSATS Students (Class of 2026) Currently in Beta Testing.
                </p>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}