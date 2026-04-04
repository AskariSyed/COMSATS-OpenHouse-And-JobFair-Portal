import { PageHeader } from '../components/PageHeader';
import { companyCapabilities, howToUse, portalUrls } from '../data/siteContent';

const companyFaqs = [
  {
    question: 'How do we recover access if we forget the company password?',
    answer: 'Use Forgot Password on the company login page. The portal sends a validation code (OTP) to your email, then you can set a new strong password.'
  },
  {
    question: 'Why am I asked to join the active job fair after login?',
    answer: 'If your company is not enrolled in the currently active fair, the dashboard prompts you to participate and set the number of representatives before switching your workflows to that fair.'
  },
  {
    question: 'How does attendance work on job fair day?',
    answer: 'You can confirm attendance before the event (when allowed), and on job fair day you can mark presence by scanning the admin QR code from the dashboard attendance flow.'
  },
  {
    question: 'Can we still send or schedule interviews after the fair ends?',
    answer: 'No. Interview actions are time-bound in the portal and are blocked after the configured job fair cutoff window.'
  },
  {
    question: 'What is walk-in interviewing and when can it be used?',
    answer: 'Walk-in interviewing can be toggled from the dashboard when policy conditions are met (typically on job fair day and attendance requirements are satisfied).'
  },
  {
    question: 'Are company surveys mandatory?',
    answer: 'Yes. The portal includes CDC and Department survey forms. On job fair day, reminder prompts appear (including a mandatory reminder after the configured time) until required responses are submitted.'
  },
  {
    question: 'How do supply and support requests work?',
    answer: 'Use Supply Requests to submit needs (supplies, cleaning, equipment, info, etc.), track status updates, and cancel pending/in-progress requests if required.'
  }
];

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

      <section className="rounded-2xl border border-blue-100 bg-white p-6 shadow-soft">
        <h2 className="text-xl font-bold">FAQs</h2>
        <div className="mt-4 space-y-3">
          {companyFaqs.map((faq) => (
            <details key={faq.question} className="rounded-lg border border-slate-200 bg-slate-50 p-4">
              <summary className="cursor-pointer list-none text-sm font-semibold text-slate-900">{faq.question}</summary>
              <p className="mt-2 text-sm text-slate-700">{faq.answer}</p>
            </details>
          ))}
        </div>
      </section>
    </div>
  );
}
