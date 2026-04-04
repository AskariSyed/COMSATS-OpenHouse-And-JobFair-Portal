import { PageHeader } from '../components/PageHeader';
import { howToUse } from '../data/siteContent';

export function HowToUsePage() {
  return (
    <div className="space-y-8">
      <PageHeader
        title="How to Use the Platform"
        subtitle="Practical onboarding steps for each role in the COMSATS Open House and Job Fair workflow."
      />

      <section className="grid gap-4 lg:grid-cols-3">
        <article className="rounded-2xl border border-blue-100 bg-white p-6 shadow-soft">
          <h2 className="text-xl font-bold">Students</h2>
          <p className="mt-1 text-xs text-slate-500">Estimated setup: 10-15 minutes</p>
          <ol className="mt-4 space-y-3 text-sm text-slate-700">
            {howToUse.student.map((step, idx) => (
              <li key={step} className="rounded-lg bg-slate-50 p-3"><strong>{idx + 1}.</strong> {step}</li>
            ))}
          </ol>
        </article>

        <article className="rounded-2xl border border-teal-100 bg-white p-6 shadow-soft">
          <h2 className="text-xl font-bold">Companies</h2>
          <p className="mt-1 text-xs text-slate-500">Estimated setup: 15-20 minutes</p>
          <ol className="mt-4 space-y-3 text-sm text-slate-700">
            {howToUse.company.map((step, idx) => (
              <li key={step} className="rounded-lg bg-slate-50 p-3"><strong>{idx + 1}.</strong> {step}</li>
            ))}
          </ol>
        </article>

        <article className="rounded-2xl border border-slate-200 bg-white p-6 shadow-soft">
          <h2 className="text-xl font-bold">Admins</h2>
          <p className="mt-1 text-xs text-slate-500">Estimated setup: 20-30 minutes</p>
          <ol className="mt-4 space-y-3 text-sm text-slate-700">
            {howToUse.admin.map((step, idx) => (
              <li key={step} className="rounded-lg bg-slate-50 p-3"><strong>{idx + 1}.</strong> {step}</li>
            ))}
          </ol>
        </article>
      </section>
    </div>
  );
}
