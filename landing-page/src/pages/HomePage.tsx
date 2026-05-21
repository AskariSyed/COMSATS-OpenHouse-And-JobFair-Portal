import { useEffect, useMemo, useState } from 'react';
import { motion } from 'framer-motion';
import { Apple, ArrowRight, Briefcase, Building2, Download, ShieldCheck, Smartphone, Users } from 'lucide-react';
import { Link } from 'react-router-dom';
import { featureGrid, portalUrls } from '../data/siteContent';

type PublicNotice = {
  noticeId: number;
  title: string;
  content: string;
  audience: string;
  isBanner?: boolean;
  createdAt: string;
};

const jumpAnimation = {
  y: [0, -10, 0],
  transition: {
    duration: 1.6,
    repeat: Infinity,
    ease: 'easeInOut'
  }
};

const cards = [
  {
    title: 'Student Portal',
    tag: 'Mobile-first',
    icon: Smartphone,
    points: ['Profile and CV readiness', 'Job and company browsing', 'Interview requests and reminders'],
    href: portalUrls.student,
    button: 'Open Student Portal'
  },
  {
    title: 'Company Portal',
    tag: 'Desktop-first',
    icon: Briefcase,
    points: ['Recruiter dashboard workflows', 'Student/FYP exploration', 'Interview and analytics management'],
    href: portalUrls.company,
    button: 'Open Company Portal'
  },
  {
    title: 'Admin Portal',
    tag: 'Desktop-first',
    icon: ShieldCheck,
    points: ['Fair setup and operations', 'Rooms, attendance, notices', 'Surveys and analytics'],
    href: portalUrls.admin,
    button: 'Open Admin Portal'
  }
];

export function HomePage() {
  const [publicNotices, setPublicNotices] = useState<PublicNotice[]>([]);

  useEffect(() => {
    let disposed = false;
    const apiBase = (import.meta.env.VITE_API_BASE_URL || '').replace(/\/$/, '');

    const fetchPublicNotices = async () => {
      try {
        const response = await fetch(`${apiBase}/api/public/notices`);
        if (!response.ok) throw new Error('Failed to fetch public notices');
        const data = await response.json();
        if (!disposed) {
          setPublicNotices(Array.isArray(data) ? data : []);
        }
      } catch {
        if (!disposed) {
          setPublicNotices([]);
        }
      }
    };

    fetchPublicNotices();
    const intervalId = window.setInterval(fetchPublicNotices, 5 * 60 * 1000);

    return () => {
      disposed = true;
      window.clearInterval(intervalId);
    };
  }, []);

  const regularNotices = useMemo(
    () => publicNotices.filter((notice) => !notice.isBanner),
    [publicNotices]
  );

  return (
    <div className="space-y-12">
      <motion.section
        initial={{ opacity: 0, y: 24 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="rounded-3xl border border-blue-100 bg-white p-8 shadow-soft"
      >
        <div className="grid gap-8 lg:grid-cols-2">
          <div>
            <span className="rounded-full bg-blue-50 px-3 py-1 text-xs font-bold uppercase tracking-wide text-blue-700">Central platform</span>
            <h1 className="mt-4 text-4xl font-extrabold leading-tight text-slate-900 sm:text-5xl">
              One Platform for Students, Companies and Admins
            </h1>
            <p className="mt-4 text-lg text-slate-600">
              COMSATS Job Fair And Open House Solution brings your role-based portal suite into one entry point for the COMSATS Open House and Job Fair system.
            </p>
            <p className="mt-3 text-sm font-semibold text-slate-700">
              Student portal is mobile-first. Company and Admin portals are desktop-focused for operations.
            </p>
            <div className="mt-6 flex flex-wrap gap-3">
              <a className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700" href={portalUrls.student}>Student Portal</a>
              <a className="rounded-lg bg-teal-600 px-4 py-2 text-sm font-semibold text-white hover:bg-teal-700" href={portalUrls.company}>Company Portal</a>
              <a className="rounded-lg bg-slate-900 px-4 py-2 text-sm font-semibold text-white hover:bg-slate-800" href={portalUrls.admin}>Admin Portal</a>
            </div>
            <div className="mt-4">
              <a className="inline-flex items-center gap-2 text-sm font-semibold text-blue-700 hover:text-blue-800" href={portalUrls.studentApk}>
                <Download className="h-4 w-4" /> Download Android APK
              </a>
            </div>
          </div>

          <div className="rounded-2xl border border-blue-100 bg-gradient-to-br from-blue-50 to-teal-50 p-6">
            <div className="grid gap-3">
              <div className="rounded-xl bg-white p-4 shadow-sm">
                <p className="text-xs font-bold uppercase tracking-wide text-blue-700">Student flow</p>
                <p className="mt-1 text-sm text-slate-700">Sign in, complete profile, upload CV, browse jobs, send requests, track interviews.</p>
              </div>
              <div className="rounded-xl bg-white p-4 shadow-sm">
                <p className="text-xs font-bold uppercase tracking-wide text-teal-700">Company flow</p>
                <p className="mt-1 text-sm text-slate-700">Manage company profile, review students/FYPs, post jobs, handle interviews, monitor analytics.</p>
              </div>
              <div className="rounded-xl bg-white p-4 shadow-sm">
                <p className="text-xs font-bold uppercase tracking-wide text-slate-700">Admin flow</p>
                <p className="mt-1 text-sm text-slate-700">Coordinate setup, rooms, attendance, notices, surveys, and fair-level reporting.</p>
              </div>
            </div>
          </div>
        </div>
      </motion.section>

      <section className="grid gap-4 md:grid-cols-3">
        {cards.map((card) => (
          <article key={card.title} className="rounded-2xl border border-blue-100 bg-white p-6 shadow-soft">
            <div className="flex items-start justify-between">
              <card.icon className="h-8 w-8 text-blue-600" />
              <span className="rounded-full bg-blue-50 px-3 py-1 text-xs font-bold text-blue-700">{card.tag}</span>
            </div>
            <h2 className="mt-4 text-xl font-bold">{card.title}</h2>
            {card.title === 'Student Portal' ? (
              <div className="mt-4 flex items-start gap-3">
                <motion.div
                  animate={jumpAnimation}
                  whileHover={{ scale: 2.8, y: -6 }}
                  transition={{ type: 'spring', stiffness: 260, damping: 16 }}
                  className="shrink-0 p-1.5 origin-top-left cursor-pointer z-20"
                >
                  <img
                    src="/assets/student-mockups/01-sign-in.png"
                    alt="Sign In Screen"
                    className="w-10 h-auto drop-shadow-xl"
                    loading="lazy"
                  />
                </motion.div>
                <ul className="space-y-2 text-sm text-slate-600">
                  {card.points.map((point) => (
                    <li key={point} className="flex items-start gap-2"><span className="mt-1 h-2 w-2 rounded-full bg-teal-500" />{point}</li>
                  ))}
                </ul>
              </div>
            ) : (
              <ul className="mt-4 space-y-2 text-sm text-slate-600">
                {card.points.map((point) => (
                  <li key={point} className="flex items-start gap-2"><span className="mt-1 h-2 w-2 rounded-full bg-teal-500" />{point}</li>
                ))}
              </ul>
            )}
            <a href={card.href} className="mt-5 inline-flex items-center gap-2 text-sm font-semibold text-blue-700 hover:text-blue-800">
              {card.button} <ArrowRight className="h-4 w-4" />
            </a>
          </article>
        ))}
      </section>

      <section className="rounded-2xl border border-blue-100 bg-white p-8 shadow-soft">
        <h2 className="text-2xl font-extrabold">Core Platform Features</h2>
        <div className="mt-6 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          {featureGrid.map((feature) => (
            <div key={feature.title} className="rounded-xl border border-slate-200 bg-slate-50 p-4">
              <p className="font-semibold text-slate-900">{feature.title}</p>
              <p className="mt-2 text-sm text-slate-600">{feature.detail}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="grid gap-4 lg:grid-cols-2">
        <div className="rounded-2xl border border-blue-100 bg-white p-6 shadow-soft">
          <h3 className="text-xl font-bold">Student App Experience</h3>
          <p className="mt-2 text-sm text-slate-600">
            The student portal is optimized for phones. Android users can install the APK, while iPhone users can add the web app to the home screen for app-like access.
          </p>
          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            <a href={portalUrls.studentApk} className="rounded-lg border border-teal-200 bg-teal-50 p-4 text-sm font-semibold text-teal-800">
              <span className="flex items-center gap-2"><Smartphone className="h-4 w-4" />Android: Download APK</span>
            </a>
            <div className="rounded-lg border border-blue-200 bg-blue-50 p-4 text-sm font-semibold text-blue-800">
              <div className="mb-2 flex items-center gap-2"><Apple className="h-4 w-4" />iPhone</div>
              <ul className="list-disc space-y-1 pl-5 font-normal text-blue-900">
                <li>Open Safari and go to comsats.student.jfair.tech</li>
                <li>Wait for the page to load</li>
                <li>Tap Share at the bottom</li>
                <li>Choose Add to Home Screen</li>
              </ul>
            </div>
          </div>
        </div>

        <div className="rounded-2xl border border-blue-100 bg-white p-6 shadow-soft">
          <h3 className="text-xl font-bold">Explore Detailed Pages</h3>
          <p className="mt-2 text-sm text-slate-600">Use dedicated pages for each role and full feature documentation.</p>
          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            <Link to="/student" className="rounded-lg border border-slate-200 bg-slate-50 p-4 text-sm font-semibold">Student Details</Link>
            <Link to="/company" className="rounded-lg border border-slate-200 bg-slate-50 p-4 text-sm font-semibold">Company Details</Link>
            <Link to="/admin" className="rounded-lg border border-slate-200 bg-slate-50 p-4 text-sm font-semibold">Admin Details</Link>
            <Link to="/how-to-use" className="rounded-lg border border-slate-200 bg-slate-50 p-4 text-sm font-semibold">How to Use</Link>
          </div>
        </div>
      </section>

      <section className="rounded-2xl border border-blue-100 bg-white p-8 shadow-soft">
        <h2 className="text-2xl font-extrabold">Public Notices</h2>
        <p className="mt-2 text-sm text-slate-600">Latest announcements for visitors and participants.</p>
        <div className="mt-5 space-y-3">
          {regularNotices.length === 0 && (
            <p className="text-sm text-slate-500">No public notices right now.</p>
          )}
          {regularNotices.map((notice) => (
            <article key={notice.noticeId} className="rounded-xl border border-slate-200 bg-slate-50 p-4">
              <div className="flex items-start justify-between gap-3">
                <h3 className="text-base font-bold text-slate-900">{notice.title}</h3>
                <span className="shrink-0 text-xs text-slate-500">{new Date(notice.createdAt).toLocaleDateString()}</span>
              </div>
              <p className="mt-2 text-sm text-slate-700 whitespace-pre-wrap">{notice.content}</p>
            </article>
          ))}
        </div>
      </section>
    </div>
  );
}
