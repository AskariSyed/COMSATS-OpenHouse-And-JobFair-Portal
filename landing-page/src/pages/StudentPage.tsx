import { motion } from 'framer-motion';
import { Apple, Smartphone, Info } from 'lucide-react';
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
    answer: [
      'Open Safari and go to student.jfair.tech.',
      'Wait for the page to load.',
      'Tap the Share button at the bottom of Safari.',
      'Scroll if needed and choose Add to Home Screen.',
      'Save the shortcut to open the student portal like an app.'
    ]
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
    question: 'Can I change my email?',
    answer: 'For email changes, please contact the IT Center or the portal admin for assistance.'
  }
];

export function StudentPage() {
  return (
    <div className="space-y-8 overflow-x-hidden">
      <PageHeader
        title="Student Portal (Mobile-first)"
        subtitle="Built for on-the-go student usage: profile readiness, CV workflows, jobs and companies discovery, interview requests, queue tracking, and notification reminders."
      />

      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
        className="rounded-xl border border-amber-200 bg-amber-50 p-4 shadow-sm"
      >
        <div className="flex gap-3 items-start">
          <Info className="mt-0.5 h-6 w-6 shrink-0 text-amber-600" />
          <div className="text-sm text-amber-900">
            <p className="font-bold text-amber-800 text-base mb-1">Mobile Device Recommended</p>
            <p className="leading-relaxed">
              Students are highly encouraged to use a mobile device instead of the website for better notification availability.{' '}
              If you are on <strong>Android</strong>, please <a href={portalUrls.studentApk} className="font-semibold underline hover:text-amber-700 transition-colors">download and install the app</a>.{' '}
              If you are on <strong>iOS (iPhone)</strong>, please open the website in Safari and add it to your home screen.
            </p>
          </div>
        </div>
      </motion.div>

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
          <h3 className="flex items-center gap-2 text-lg font-bold text-teal-900"><Smartphone className="h-5 w-5" />Android</h3>
          <p className="mt-2 text-sm text-teal-800">Install APK for app-like experience and quick access.</p>
          <a href={portalUrls.studentApk} className="mt-4 inline-block rounded-lg bg-teal-600 px-4 py-2 text-sm font-semibold text-white">Download student-portal.apk</a>
        </article>

        <article className="rounded-2xl border border-blue-200 bg-blue-50 p-6 transition-transform duration-300 hover:-translate-y-1">
          <h3 className="flex items-center gap-2 text-lg font-bold text-blue-900"><Apple className="h-5 w-5" />iPhone</h3>
          <div className="mt-2 text-sm text-blue-800">
            <p>Open Safari and go to student.jfair.tech.</p>
            <ul className="mt-2 list-disc space-y-1 pl-5 text-blue-900">
              <li>Wait for the page to load.</li>
              <li>Tap Share at the bottom of Safari.</li>
              <li>Scroll if needed and choose Add to Home Screen.</li>
            </ul>
          </div>
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
              {Array.isArray(faq.answer) ? (
                <ul className="mt-2 list-disc space-y-1 pl-5 text-sm text-slate-700">
                  {faq.answer.map((step) => (
                    <li key={step}>{step}</li>
                  ))}
                </ul>
              ) : (
                <p className="mt-2 text-sm text-slate-700">{faq.answer}</p>
              )}
            </details>
          ))}
        </div>
      </motion.section>
    </div>
  );
}
