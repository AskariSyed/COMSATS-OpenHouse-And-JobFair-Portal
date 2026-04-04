import { PageHeader } from '../components/PageHeader';
import { companyCapabilities, howToUse, portalUrls } from '../data/siteContent';

const companyFaqs = [
  {
    question: 'How do we recover access if we forget the company password?',
    answer: 'Use Forgot Password on the company login page. The portal sends a validation code (OTP) to your email, then you can set a new strong password.'
  },
  {
    question: 'Why am I asked to join the active job fair after login?',
    answer: 'If your company account is not enrolled in the currently active fair, the portal shows a participation prompt. This ensures jobs, interviews, attendance, and analytics are mapped to the correct active fair. If you select Yes, your company is enrolled with your selected representative count and your workflows switch to that fair context.'
  },
  {
    question: 'How does attendance work on job fair day?',
    answer: 'You can confirm attendance before the event (when allowed), and on job fair day you can mark presence by scanning the admin QR code from the dashboard attendance flow.'
  },
  {
    question: 'What is the difference between Confirm Attendance and Mark Present?',
    answer: 'Confirm Attendance is a pre-event confirmation that your company plans to attend. Mark Present is the on-day check-in action (via admin QR scan) that records your arrival for the active job fair.'
  },
  {
    question: 'I confirmed attendance earlier. Do I still need to mark present on job fair day?',
    answer: 'Yes. Confirmation and on-day presence are separate steps. You should still mark present on job fair day so arrival is recorded and on-day workflows can proceed correctly.'
  },
  {
    question: 'What if we cannot mark present or miss the QR check-in step?',
    answer: 'If QR-based presence is missed or blocked, contact the admin desk immediately for manual assistance. Attendance status affects room allocation and other event-day workflows.'
  },
  {
    question: 'When is attendance confirmation allowed?',
    answer: 'Attendance confirmation is only available during the allowed pre-event window configured by the portal. If the button is disabled, it means confirmation is not currently open for your account.'
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
  },
  {
    question: 'Can we edit the number of representatives after joining the active fair?',
    answer: 'If representative-count editing is available in your current company profile settings, you can update it there. If that option is locked for the active fair, request an admin update.'
  },
  {
    question: 'Do we need to re-join every new job fair semester?',
    answer: 'Yes. Participation is tied to each active fair cycle, so you may be prompted again when a new semester fair becomes active.'
  },
  {
    question: 'Why is the Schedule button disabled for some students?',
    answer: 'Scheduling may be disabled when the request is not in Accepted state, no valid slot is available, the interview window is closed, or the student already has a scheduled interview in that flow.'
  },
  {
    question: 'Can we auto-schedule all accepted interviews at once?',
    answer: 'Yes. Use the Schedule All option (when available) to auto-assign slots for accepted requests during the allowed scheduling window.'
  },
  {
    question: 'Can we reschedule an already scheduled interview?',
    answer: 'Rescheduling depends on portal rules and interview state. If direct reschedule controls are unavailable for a specific case, use interview management actions or contact admin support.'
  },
  {
    question: 'What interview statuses are available in the company workflow?',
    answer: 'Common statuses include Pending, Accepted, Queued/Scheduled, In Progress, and Completed outcomes (such as Hired, Shortlisted, or Rejected).' 
  },
  {
    question: 'Who can start and complete an interview in the portal?',
    answer: 'Authorized company-side users operating your company dashboard can start interviews and submit completion outcomes according to role permissions.'
  },
  {
    question: 'What happens if a student does not show up at the scheduled time?',
    answer: 'Use interview management actions to handle the case according to portal policy (for example, update status, proceed with another candidate, or mark outcome appropriately).' 
  },
  {
    question: 'When can we start Walk-In Interviewing, and who controls it?',
    answer: 'Walk-in mode can be toggled from the company dashboard when policy conditions are met (typically on job fair day with required attendance state).'
  },
  {
    question: 'Why are surveys locked before or after job fair day?',
    answer: 'Survey access is time-bound to the active fair day and configured policy window, so forms may remain unavailable outside that period.'
  },
  {
    question: 'Do we need to submit both CDC and Department surveys?',
    answer: 'Yes. Both survey sections are expected for complete submission, and reminders continue until required responses are provided.'
  },
  {
    question: 'How do notice-board updates affect company workflow?',
    answer: 'Notices communicate operational updates, deadlines, and instructions. You should review them regularly because they may impact attendance, interviews, or survey actions.'
  },
  {
    question: 'Can we import previous jobs into the current fair?',
    answer: 'Yes. If historical job import is available in your profile/job tools, you can copy selected previous-fair jobs into the current active fair context.'
  },
  {
    question: 'How are room assignment and attendance connected?',
    answer: 'On-day presence and attendance state are used in room-allocation workflows. Missing attendance steps can delay or block automatic room assignment.'
  },
  {
    question: 'What should we do if room is not auto-assigned after marking present?',
    answer: 'Contact the admin desk immediately for manual room allotment. The portal may show this requirement when no suitable room is auto-available.'
  },
  {
    question: 'Can we download student CVs in bulk?',
    answer: 'Bulk CV download availability depends on the current interview/directory tools. If shown in your workflow, you can export multiple CVs; otherwise use per-student download options.'
  },
  {
    question: 'Can we view candidates from previous fairs separately?',
    answer: 'Yes. Use history or previous-analytics views (when available) to separate current-fair candidates from earlier fair records.'
  },
  {
    question: 'Why do analytics numbers differ across tabs?',
    answer: 'Different widgets can reflect different filters, statuses, or refresh times. Compare timeframe and status scope before concluding there is a mismatch.'
  },
  {
    question: 'Can we cancel a supply request after submitting it?',
    answer: 'Yes. Pending or in-progress supply requests can usually be cancelled from the Supply Requests section using the cancel action.'
  },
  {
    question: 'What should we do if the portal shows Session Expired repeatedly?',
    answer: 'Sign in again, clear browser cache/storage if needed, and confirm stable connectivity. If it persists, contact admin/IT support to verify account/session policy settings.'
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
