import React, { useState } from 'react';
import { KeyRound, Mail, ArrowRight, CheckCircle2, Loader2, ChevronLeft, ShieldCheck } from 'lucide-react';
import { sendPasswordResetOtp, verifyResetOtpAndSetPassword } from '../api';

export default function ForgotPasswordPage({ onNavigate }) {
  const [step, setStep] = useState(1); // 1: Email, 2: OTP & New Pass
  const [loading, setLoading] = useState(false);
  const [email, setEmail] = useState('');
  const [userId, setUserId] = useState(null);
  const [otp, setOtp] = useState('');
  const [passwords, setPasswords] = useState({ new: '', confirm: '' });
  const [message, setMessage] = useState({ text: '', type: '' });

  const handleSendOtp = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage({ text: '', type: '' });
    try {
      const res = await sendPasswordResetOtp(email);
      if (res.userId) {
        setUserId(res.userId);
        setStep(2);
        setMessage({ text: 'Validation code sent to your email.', type: 'success' });
      } else {
        setMessage({ text: res.message, type: 'info' });
      }
    } catch (err) { setMessage({ text: err.message, type: 'error' }); } 
    finally { setLoading(false); }
  };

  const handleReset = async (e) => {
    e.preventDefault();
    if (passwords.new !== passwords.confirm) return setMessage({ text: "Passwords don't match", type: "error" });
    setLoading(true);
    try {
      await verifyResetOtpAndSetPassword(userId, otp, passwords.new, passwords.confirm);
      setMessage({ text: 'Password updated successfully!', type: 'success' });
      setTimeout(() => onNavigate('login'), 2000);
    } catch (err) { setMessage({ text: err.message, type: 'error' }); }
    finally { setLoading(false); }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 p-6 relative overflow-hidden">
      {/* Background Decor */}
      <div className="absolute top-0 left-0 w-full h-full overflow-hidden z-0 pointer-events-none">
        <div className="absolute top-[-10%] right-[-10%] w-[500px] h-[500px] bg-blue-100 rounded-full mix-blend-multiply filter blur-3xl opacity-50 animate-blob"></div>
        <div className="absolute bottom-[-10%] left-[-10%] w-[500px] h-[500px] bg-purple-100 rounded-full mix-blend-multiply filter blur-3xl opacity-50 animate-blob animation-delay-2000"></div>
      </div>

      <div className="w-full max-w-md bg-white rounded-2xl shadow-xl p-8 relative z-10 animate-fade-in border border-white/50 backdrop-blur-sm">
        <button onClick={() => onNavigate('login')} className="flex items-center text-sm text-gray-500 hover:text-gray-900 transition-colors mb-6 group">
            <ChevronLeft className="w-4 h-4 group-hover:-translate-x-1 transition-transform" /> Back to Login
        </button>
        
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-blue-50 rounded-2xl flex items-center justify-center mx-auto mb-6 text-blue-600 shadow-sm border border-blue-100">
             {step === 1 ? <KeyRound className="w-8 h-8" /> : <ShieldCheck className="w-8 h-8" />}
          </div>
          <h2 className="text-2xl font-bold text-gray-900">{step === 1 ? "Forgot Password?" : "Reset Credentials"}</h2>
          <p className="text-gray-500 mt-2 text-sm">{step === 1 ? "No worries, we'll send you reset instructions." : "Enter the code sent to your email."}</p>
        </div>

        {message.text && (
            <div className={`p-4 rounded-xl mb-6 text-sm font-medium flex items-center gap-3 ${message.type === 'error' ? 'bg-red-50 text-red-700 border border-red-100' : 'bg-green-50 text-green-700 border border-green-100'}`}>
                {message.type === 'success' ? <CheckCircle2 className="w-5 h-5"/> : <div className="w-2 h-2 rounded-full bg-current"></div>}
                {message.text}
            </div>
        )}

        {step === 1 ? (
          <form onSubmit={handleSendOtp} className="space-y-5">
            <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">Email or Registration ID</label>
                <div className="relative">
                    <Mail className="absolute left-3.5 top-3.5 w-5 h-5 text-gray-400" />
                    <input 
                        required 
                        value={email} 
                        onChange={e => setEmail(e.target.value)} 
                        className="w-full pl-11 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-blue-500 outline-none transition-all placeholder-gray-400" 
                        placeholder="fa21-bcs-001 or email@ex.com"
                    />
                </div>
            </div>
            <button disabled={loading} className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3.5 rounded-xl font-bold shadow-lg shadow-blue-200 transform transition active:scale-95 flex justify-center items-center gap-2">
                {loading ? <Loader2 className="animate-spin" /> : <>Send Reset Code <ArrowRight className="w-4 h-4" /></>}
            </button>
          </form>
        ) : (
          <form onSubmit={handleReset} className="space-y-5 animate-fade-in">
            <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">OTP Code</label>
                <input 
                    required 
                    maxLength={6}
                    value={otp} 
                    onChange={e => setOtp(e.target.value)} 
                    className="w-full py-3 px-4 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-blue-500 outline-none text-center text-2xl tracking-widest font-mono" 
                    placeholder="000000"
                />
            </div>
            <div className="space-y-3">
                <input required type="password" placeholder="New Password" value={passwords.new} onChange={e => setPasswords({...passwords, new: e.target.value})} className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-blue-500 outline-none" />
                <input required type="password" placeholder="Confirm Password" value={passwords.confirm} onChange={e => setPasswords({...passwords, confirm: e.target.value})} className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-blue-500 outline-none" />
            </div>
            <button disabled={loading} className="w-full bg-green-600 hover:bg-green-700 text-white py-3.5 rounded-xl font-bold shadow-lg shadow-green-200 transform transition active:scale-95 flex justify-center items-center gap-2">
                {loading ? <Loader2 className="animate-spin" /> : <>Set New Password <CheckCircle2 className="w-4 h-4" /></>}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}