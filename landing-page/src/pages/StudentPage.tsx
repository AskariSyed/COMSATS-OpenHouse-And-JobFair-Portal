import { motion } from 'framer-motion';
import { PageHeader } from '../components/PageHeader';
import { StudentMockupSlider } from '../components/StudentMockupSlider';
import { howToUse, portalUrls, studentCapabilities } from '../data/siteContent';

const studentFaqs = [
  {
    question: 'How do I make my profile ready for recruiters?',
    answer: 'Complete education, skills, projects, achievements, and contact links, then upload a CV to improve your profile readiness.'
  },
  {
    question: 'Can I upload my own CV PDF?',
    answer: 'Yes. You can upload your own PDF CV, and you may also use generated CV workflows if available in your account.'
  },
  {
    question: 'How do interview requests work?',
    answer: 'You can send interview requests to companies and track status updates for pending, scheduled, or completed interviews with room/time details.'
  },
  {
    question: 'How do I use the portal on iPhone?',
    answer: 'Open student.jfair.tech in Safari, tap Share, and choose Add to Home Screen for app-like access.'
  },
  {
    question: 'How do I get Android app access?',
    answer: 'Use the Download student-portal.apk button on this page and install the APK for a native-like mobile experience.'
  },
  {
    question: 'Which email will I receive my password on?',
    answer: 'You will receive it on your university-provided Microsoft account email, using the template format FA22-BCS-000@cuiwah.edu.pk. During sign-up, enter your registration number and an auto-generated password will be sent to this email.'
  },
  {
    question: 'Can I change my password?',
    answer: 'For password changes, please contact the IT Center or the portal admin for assistance.'
  }
];

export function StudentPage() {
  return (
    <div className="space-y-8 overflow-x-hidden">
      <PageHeader
        title="Student Portal (Mobile-first)"
        subtitle="Built for on-the-go student usage: profile readiness, CV workflows, jobs and companies discovery, interview requests, queue tracking, and notification reminders."
      />

      <motion.section
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.45, delay: 0.05 }}
      >
        <StudentMockupSlider />
      </motion.section>

      <motion.section
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.45, delay: 0.1 }}
        className="rounded-2xl border border-blue-100 bg-white p-6 shadow-soft"
      >
        <h2 className="text-xl font-bold">Student Functionalities</h2>
        <ul className="mt-4 space-y-3 text-sm text-slate-700">
          {studentCapabilities.map((item) => (
            <li key={item} className="flex gap-2"><span className="mt-1 h-2 w-2 rounded-full bg-blue-600" />{item}</li>
          ))}
        </ul>
      </motion.section>

      <motion.section
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.45, delay: 0.15 }}
        className="grid gap-4 md:grid-cols-2"
      >
        <article className="rounded-2xl border border-teal-200 bg-teal-50 p-6 transition-transform duration-300 hover:-translate-y-1">
          <h3 className="text-lg font-bold text-teal-900">Android</h3>
          <p className="mt-2 text-sm text-teal-800">Install APK for app-like experience and quick access.</p>
          <a href={portalUrls.studentApk} className="mt-4 inline-block rounded-lg bg-teal-600 px-4 py-2 text-sm font-semibold text-white">Download student-portal.apk</a>
        </article>

        <article className="rounded-2xl border border-blue-200 bg-blue-50 p-6 transition-transform duration-300 hover:-translate-y-1">
          <h3 className="text-lg font-bold text-blue-900">iPhone</h3>
          <p className="mt-2 text-sm text-blue-800">Open student.jfair.tech in Safari, then tap Share and choose Add to Home Screen.</p>
          <a href={portalUrls.student} className="mt-4 inline-block rounded-lg bg-blue-600 px-4 py-2 text-sm font-semibold text-white">Open Student Portal</a>
        </article>
      </motion.section>

      <motion.section
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.45, delay: 0.2 }}
        className="rounded-2xl border border-blue-100 bg-white p-6 shadow-soft"
      >
        <h2 className="text-xl font-bold">How Students Use It</h2>
        <ol className="mt-4 space-y-2 text-sm text-slate-700">
          {howToUse.student.map((step) => (
            <li key={step} className="rounded-lg bg-slate-50 p-3">{step}</li>
          ))}
        </ol>
      </motion.section>

      <motion.section
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.45, delay: 0.25 }}
        className="rounded-2xl border border-blue-100 bg-white p-6 shadow-soft"
      >
        <h2 className="text-xl font-bold">FAQs</h2>
        <div className="mt-4 space-y-3">
          {studentFaqs.map((faq) => (
            <details key={faq.question} className="rounded-lg border border-slate-200 bg-slate-50 p-4">
              <summary className="cursor-pointer list-none text-sm font-semibold text-slate-900">{faq.question}</summary>
              <p className="mt-2 text-sm text-slate-700">{faq.answer}</p>
            </details>
          ))}
        </div>
      </motion.section>
    </div>
  );
}
