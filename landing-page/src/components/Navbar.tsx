import { ChevronDown, Menu, X } from 'lucide-react';
import { useState } from 'react';
import { Link, NavLink } from 'react-router-dom';
import { portalUrls } from '../data/siteContent';

const navLinks = [
  { label: 'Portals', to: '/' },
  { label: 'How to Use', to: '/how-to-use' },
  { label: 'Team', to: '/team' }
];

const detailLinks = [
  { label: 'Student', to: '/student' },
  { label: 'Company', to: '/company' },
  { label: 'Admin', to: '/admin' },
  { label: 'Team', to: '/team' }
];

const portalQuickLinks = [
  { label: 'Student Portal', href: portalUrls.student },
  { label: 'Company Portal', href: portalUrls.company },
  { label: 'Admin Portal', href: portalUrls.admin }
];

export function Navbar() {
  const [open, setOpen] = useState(false);
  const [detailsOpen, setDetailsOpen] = useState(false);

  return (
    <header className="fixed inset-x-0 top-0 z-50 border-b border-blue-100 bg-white/90 backdrop-blur">
      <div className="mx-auto flex max-w-7xl items-center justify-between px-4 py-3 sm:px-6 lg:px-8">
        <Link to="/" className="flex items-center gap-3">
          <img src="/assets/LogoWithoutBg.png" alt="COMSATS Job Fair" className="h-11 w-11 rounded-xl border border-blue-100 object-contain" />
          <div>
            <p className="text-sm font-bold text-slate-900">jfair.tech</p>
            <p className="text-xs text-slate-500">Open House and Job Fair Portal</p>
          </div>
        </Link>

        <nav className="hidden items-center gap-6 md:flex">
          {navLinks.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              className={({ isActive }) =>
                `text-sm font-semibold transition ${isActive ? 'text-blue-600' : 'text-slate-600 hover:text-blue-600'}`
              }
            >
              {link.label}
            </NavLink>
          ))}
          <div className="relative">
            <button
              type="button"
              onClick={() => setDetailsOpen((v) => !v)}
              className="flex items-center gap-1 text-sm font-semibold text-slate-600 transition hover:text-blue-600"
            >
              Details <ChevronDown className={`h-4 w-4 transition ${detailsOpen ? 'rotate-180' : ''}`} />
            </button>
            {detailsOpen && (
              <div className="absolute right-0 top-9 w-44 rounded-xl border border-blue-100 bg-white p-2 shadow-lg">
                {detailLinks.map((link) => (
                  <NavLink
                    key={link.to}
                    to={link.to}
                    onClick={() => setDetailsOpen(false)}
                    className={({ isActive }) =>
                      `block rounded-lg px-3 py-2 text-sm font-semibold ${isActive ? 'bg-blue-50 text-blue-700' : 'text-slate-700 hover:bg-slate-50'}`
                    }
                  >
                    {link.label}
                  </NavLink>
                ))}
              </div>
            )}
          </div>
          <div className="flex items-center gap-2">
            {portalQuickLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="rounded-lg bg-blue-600 px-3 py-2 text-xs font-semibold text-white hover:bg-blue-700"
              >
                {link.label}
              </a>
            ))}
          </div>
        </nav>

        <button onClick={() => setOpen((v) => !v)} className="md:hidden" type="button">
          {open ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
        </button>
      </div>

      {open && (
        <div className="border-t border-blue-100 bg-white px-4 py-3 md:hidden">
          <div className="flex flex-col gap-3">
            {navLinks.map((link) => (
              <NavLink key={link.to} to={link.to} onClick={() => setOpen(false)} className="text-sm font-semibold text-slate-700">
                {link.label}
              </NavLink>
            ))}
            <button
              type="button"
              onClick={() => setDetailsOpen((v) => !v)}
              className="flex items-center justify-between rounded-lg border border-slate-200 px-3 py-2 text-sm font-semibold text-slate-700"
            >
              Details
              <ChevronDown className={`h-4 w-4 transition ${detailsOpen ? 'rotate-180' : ''}`} />
            </button>
            {detailsOpen && (
              <div className="ml-2 flex flex-col gap-2 border-l border-slate-200 pl-3">
                {detailLinks.map((link) => (
                  <NavLink
                    key={link.to}
                    to={link.to}
                    onClick={() => {
                      setOpen(false);
                      setDetailsOpen(false);
                    }}
                    className="text-sm font-semibold text-slate-700"
                  >
                    {link.label}
                  </NavLink>
                ))}
              </div>
            )}
            <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
              {portalQuickLinks.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  className="rounded-lg bg-blue-600 px-4 py-2 text-center text-sm font-semibold text-white"
                >
                  {link.label}
                </a>
              ))}
            </div>
          </div>
        </div>
      )}
    </header>
  );
}
