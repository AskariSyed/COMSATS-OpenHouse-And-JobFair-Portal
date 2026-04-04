import { PageHeader } from '../components/PageHeader';
import { adminCapabilities, howToUse, portalUrls } from '../data/siteContent';

export function AdminPage() {
  return (
    <div className="space-y-8">
      <PageHeader
        title="Admin Portal (Web-first Operations)"
        subtitle="Central administrative workspace for event setup, participant management, rooms, attendance, notices, surveys, and analytics monitoring."
      />

      <section className="rounded-2xl border border-blue-100 bg-white p-6 shadow-soft">
        <h2 className="text-xl font-bold">Admin Functionalities</h2>
        <ul className="mt-4 space-y-3 text-sm text-slate-700">
          {adminCapabilities.map((item) => (
            <li key={item} className="flex gap-2"><span className="mt-1 h-2 w-2 rounded-full bg-blue-600" />{item}</li>
          ))}
        </ul>
        <a href={portalUrls.admin} className="mt-5 inline-block rounded-lg bg-blue-600 px-4 py-2 text-sm font-semibold text-white">Open Admin Portal</a>
      </section>

      <section className="rounded-2xl border border-blue-100 bg-white p-6 shadow-soft">
        <h2 className="text-xl font-bold">How Admins Use It</h2>
        <ol className="mt-4 space-y-2 text-sm text-slate-700">
          {howToUse.admin.map((step) => (
            <li key={step} className="rounded-lg bg-slate-50 p-3">{step}</li>
          ))}
        </ol>
      </section>
    </div>
  );
}
