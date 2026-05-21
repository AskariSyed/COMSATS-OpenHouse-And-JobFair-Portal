export const portalUrls = {
  student: 'https://comsats.student.jfair.tech',
  company: 'https://comsats.company.jfair.tech',
  admin: 'https://comsats.admin.jfair.tech',
  studentApk: 'https://comsats.student.jfair.tech/downloads/student-portal.apk'
};

export const featureGrid = [
  { title: 'Student Profile Readiness', detail: 'Students manage skills, education, projects, certifications, and profile completeness for recruiter visibility.' },
  { title: 'CV Workflows', detail: 'Students can upload their own PDF CV and also use generated CV flows for quick readiness.' },
  { title: 'Job and Company Discovery', detail: 'Students browse active fair jobs and participating companies with search and filtering support.' },
  { title: 'Interview Requests and Queue', detail: 'Students send interview requests and track interview status, schedule timing, and assigned rooms.' },
  { title: 'Recruiter Operations', detail: 'Companies manage profiles, post openings, review student profiles, and handle recruitment interactions.' },
  { title: 'Interview Management', detail: 'Company workflows include pending requests, scheduled interviews, incoming reminders, and activity badges.' },
  { title: 'Admin Fair Operations', detail: 'Admins configure job fairs, manage rooms, attendance, notices, company requests, and participant records.' },
  { title: 'Analytics and Surveys', detail: 'Admin and company sides include survey and analytics views for reporting and fair performance insights.' }
];

export const studentCapabilities = [
  'Secure sign-in, onboarding, and account recovery flows.',
  'Profile management across education, projects, achievements, skills, and contact links.',
  'CV readiness with generated CV upload and own-PDF upload support.',
  'Jobs and companies exploration with search, filters, and recommendations.',
  'Interview request lifecycle and scheduled interview queue with room/time details.',
  'Notifications experience including reminders and updates for interview activity.'
];

export const companyCapabilities = [
  'Company login, registration, and profile/branding management.',
  'Participation prompts for active job fair enrollment workflows.',
  'Student directory and FYP exploration for candidate review.',
  'Job posting and recruitment tracking with interview handling.',
  'Request and interview notification badges with incoming scheduling context.',
  'Dashboard analytics, surveys, notices, and session safety handling.'
];

export const adminCapabilities = [
  'Admin-authenticated workspace with protected operation routes.',
  'Job fair setup controls, including active-fair configuration constraints.',
  'Student and company management with detailed profile-level pages.',
  'Company requests, room management, and attendance workflows.',
  'Notice board management and survey response oversight.',
  'Analytics dashboards with detailed lists and export-oriented reporting flows.'
];

export const howToUse = {
  student: [
    'Sign in and complete profile fields until your readiness score is complete.',
    'Upload CV (generated or own PDF), then browse jobs and companies.',
    'Send interview requests and monitor scheduled interviews and reminders.'
  ],
  company: [
    'Login or register, then complete company profile and participation setup.',
    'Publish jobs, explore students/FYPs, and manage interview requests.',
    'Track interviews, notices, surveys, and analytics from the dashboard.'
  ],
  admin: [
    'Login to admin operations and configure job fair setup details.',
    'Manage students, companies, rooms, attendance, and notices.',
    'Monitor analytics, feedback, surveys, and overall fair coordination.'
  ]
};
