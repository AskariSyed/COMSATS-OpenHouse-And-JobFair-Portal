import { useEffect, useMemo, useState } from 'react';
import { Outlet } from 'react-router-dom';
import { Footer } from './Footer';
import { Navbar } from './Navbar';

type PublicNotice = {
  noticeId: number;
  title: string;
  content: string;
  isBanner?: boolean;
};

export function Layout() {
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

  const bannerMessages = useMemo(
    () => publicNotices
      .filter((notice) => Boolean(notice.isBanner))
      .map((notice) => {
        const title = (notice.title || '').trim();
        const content = (notice.content || '').trim();
        if (title && content) return `${title}: ${content}`;
        return title || content;
      })
      .filter(Boolean),
    [publicNotices]
  );

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900">
      <Navbar />
      <main className="mx-auto w-full max-w-7xl px-4 pb-16 pt-24 sm:px-6 lg:px-8">
        {bannerMessages.length > 0 && (
          <section className="mb-6 overflow-hidden rounded-2xl border border-red-200 bg-gradient-to-r from-red-600 via-rose-600 to-red-700 px-4 py-3 text-white shadow-soft">
            <div className="landing-notice-marquee whitespace-nowrap text-sm font-bold tracking-wide">
              {bannerMessages.map((message, index) => (
                <span key={`${message}-${index}`} className="inline-flex items-center">
                  <span>{message}</span>
                  {index < bannerMessages.length - 1 && <span className="mx-4 text-white/70">•</span>}
                </span>
              ))}
            </div>
          </section>
        )}
        <Outlet />
      </main>
      <Footer />
    </div>
  );
}
