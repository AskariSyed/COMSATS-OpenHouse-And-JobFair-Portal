import { PageHeader } from '../components/PageHeader';
import { companyCapabilities, howToUse, portalUrls } from '../data/siteContent';

export function CompanyPage() {
  return (
    <div className="space-y-8">
      <PageHeader
        title="Company Portal (Web-first)"
        subtitle="A recruiter-focused desktop workflow for profile setup, job postings, student/FYP exploration, interview handling, surveys, notices, and analytics."
      />

      <section className="rounded-2xl border border-blue-100 bg-white p-6 shadow-soft">
        <h2 className="text-xl font-bold">Company Functionalities</h2>
        <ul className="mt-4 space-y-3 text-sm text-slate-700">
          {companyCapabilities.map((item) => (
            <li key={item} className="flex gap-2"><span className="mt-1 h-2 w-2 rounded-full bg-teal-600" />{item}</li>
          ))}
        </ul>
        <a href={portalUrls.company} className="mt-5 inline-block rounded-lg bg-teal-600 px-4 py-2 text-sm font-semibold text-white">Open Company Portal</a>
      </section>

      <section className="rounded-2xl border border-blue-100 bg-white p-6 shadow-soft">
        <h2 className="text-xl font-bold">How Companies Use It</h2>
        <ol className="mt-4 space-y-2 text-sm text-slate-700">
          {howToUse.company.map((step) => (
            <li key={step} className="rounded-lg bg-slate-50 p-3">{step}</li>
          ))}
        </ol>
      </section>
    </div>
  );
}
