import React from 'react';

const Footer = () => {
  return (
    <footer className="bg-slate-800 text-gray-300 mt-auto">
      {/* Top Section with Links */}
      <div className="border-b border-slate-700">
        <div className="max-w-7xl mx-auto px-4 py-6">
          <div className="flex flex-col items-center">
            <h3 className="text-white text-lg font-semibold mb-4">
              COMSATS University Islamabad, Wah Campus
            </h3>
            <div className="flex flex-wrap justify-center gap-6 text-sm">
              <a 
                href="https://wah.comsats.edu.pk" 
                target="_blank" 
                rel="noopener noreferrer"
                className="hover:text-white transition-colors"
              >
                Official Website
              </a>
              <a 
                href="https://comsats.edu.pk" 
                target="_blank" 
                rel="noopener noreferrer"
                className="hover:text-white transition-colors"
              >
                COMSATS Main
              </a>
              <a 
                href="https://wah.comsats.edu.pk/local-portal" 
                target="_blank" 
                rel="noopener noreferrer"
                className="hover:text-white transition-colors"
              >
                Local Portal
              </a>
              <a 
                href="https://wah.comsats.edu.pk/student-portal" 
                target="_blank" 
                rel="noopener noreferrer"
                className="hover:text-white transition-colors"
              >
                Student Portal
              </a>
              <a 
                href="https://wah.comsats.edu.pk/rms" 
                target="_blank" 
                rel="noopener noreferrer"
                className="hover:text-white transition-colors"
              >
                RMS Console
              </a>
            </div>
          </div>
        </div>
      </div>

      {/* Developers Section */}
      <div className="border-b border-slate-700">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <div className="text-center">
            <p className="text-sm font-semibold text-gray-400 mb-2">DEVELOPED BY FYP TEAM</p>
            <div className="flex flex-wrap justify-center gap-4 text-sm">
              <span className="text-gray-300">Shumaim Zafar (FA22-BCS-082)</span>
              <span className="text-gray-400">•</span>
              <span className="text-gray-300">Hassan Askari (FA22-BCS-155)</span>
              <span className="text-gray-400">•</span>
              <span className="text-gray-300">Sulimana Huma (FA22-BCS-073)</span>
            </div>
          </div>
        </div>
      </div>

      {/* Copyright Section */}
      <div className="max-w-7xl mx-auto px-4 py-4">
        <div className="text-center text-sm text-gray-400">
          <p>© 2025 Student Job Fair Portal. All rights reserved.</p>
          <p className="text-xs mt-1">Version 1.0.0</p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
