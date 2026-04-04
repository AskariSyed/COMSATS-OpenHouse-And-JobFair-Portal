import { motion } from 'framer-motion';
import { useState } from 'react';
import { Github, Globe, Linkedin } from 'lucide-react';
import { PageHeader } from '../components/PageHeader';

const teamMembers = [
  {
    name: 'Muhammad Hassan Askari',
    role: 'Developer',
    description: 'Final-year Computer Science student focused on backend engineering, scalable systems, and high-impact software solutions.',
    badge: 'Developer',
    image: '/assets/team/hassan.png',
    details: [
      'Email: askari.syed04@gmail.com',
      'Location: Islamabad, Pakistan',
      'Education: BS Computer Science, COMSATS University Islamabad, Wah Campus',
      'CGPA: 3.64/4',
      'Core Focus: C#, ASP.NET Web API, .NET, SQL, Flutter, AI/Computer Vision',
      'Experience: PTA (ICT Intern), HBL Microfinance Bank (SQA Intern)'
    ],
    links: [
      {
        label: 'GitHub',
        href: 'https://github.com/AskariSyed'
      },
      {
        label: 'Portfolio',
        href: 'https://portfolioaskarisyed.vercel.app/'
      },
      {
        label: 'LinkedIn',
        href: 'https://www.linkedin.com/in/syed-hassan-askari'
      }
    ]
  },
  {
    name: 'Shumaim Zafar',
    role: 'Developer',
    description: 'Contributed to student-side workflows, product quality, and delivery for the COMSATS Job Fair Portal.',
    badge: 'Developer',
    details: [
      'Email: FA22-BCS-082@cuiwah.edu.pk',
      'Department: Computer Science',
      'CGPA: 3.84'
    ],
    links: [
      {
        label: 'LinkedIn',
        href: 'https://www.linkedin.com/in/shumaim-zafar-14b90933a/'
      }
    ]
  },
  {
    name: 'Sulimana Huma',
    role: 'Developer',
    description: 'Frontend-focused contributor for UI refinement and portal experience improvements.',
    badge: 'Developer',
    details: [
      'Department: Computer Science',
      'Focus: Frontend and UI workflows',
      'Role: Team support and interface enhancements'
    ]
  }
];

type TeamMember = {
  name: string;
  role: string;
  description: string;
  badge: string;
  image?: string;
  details?: string[];
  links?: Array<{ label: string; href: string }>;
};

const linkIcons: Record<string, typeof Github> = {
  GitHub: Github,
  Portfolio: Globe,
  LinkedIn: Linkedin
};

const members: TeamMember[] = teamMembers;

export function TeamPage() {
  const [selectedMember, setSelectedMember] = useState<TeamMember>(members[0]);

  return (
    <div className="space-y-8">
      <PageHeader
        title="Meet the Team"
        subtitle="The builders behind jfair.tech for the COMSATS Open House and Job Fair Portal."
      />

      <section className="grid gap-5 lg:grid-cols-[1.4fr_1fr]">
        <motion.article
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4 }}
          className="relative overflow-hidden rounded-3xl border border-blue-100 bg-gradient-to-br from-white via-blue-50/30 to-teal-50/40 p-7 shadow-soft"
        >
          <div className="flex flex-col gap-5 sm:flex-row sm:items-start sm:justify-between">
            <div className="flex items-start gap-4">
              {selectedMember.image && (
                <img
                  src={selectedMember.image}
                  alt={selectedMember.name}
                  className="h-20 w-20 rounded-2xl object-cover ring-1 ring-white shadow-md"
                />
              )}
              <div>
                <p className="text-xs font-bold uppercase tracking-[0.2em] text-blue-700">Developer Profile</p>
                <h3 className="mt-2 text-2xl font-extrabold text-slate-900">{selectedMember.name}</h3>
                <p className="mt-1 text-sm font-semibold text-blue-700">{selectedMember.role}</p>
              </div>
            </div>
            <span className="self-start rounded-full bg-white px-3 py-1 text-xs font-bold text-blue-700 ring-1 ring-blue-100">{selectedMember.badge}</span>
          </div>

          <p className="mt-4 max-w-2xl text-sm leading-6 text-slate-700">{selectedMember.description}</p>

          {selectedMember.details && (
            <div className="mt-5 grid gap-2 sm:grid-cols-2">
              {selectedMember.details.map((item) => (
                <div key={item} className="rounded-xl bg-white/90 px-3 py-2 text-sm text-slate-700 ring-1 ring-slate-100">
                  {item}
                </div>
              ))}
            </div>
          )}

          {selectedMember.links && (
            <div className="mt-5 flex flex-wrap gap-2">
              {selectedMember.links.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-lg bg-slate-900 px-3 py-2 text-xs font-semibold text-white hover:bg-slate-800"
                >
                  <span className="inline-flex items-center gap-2">
                    {(() => {
                      const Icon = linkIcons[link.label];
                      return Icon ? <Icon className="h-3.5 w-3.5" /> : null;
                    })()}
                    {link.label}
                  </span>
                </a>
              ))}
            </div>
          )}
        </motion.article>

        <motion.article
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4, delay: 0.05 }}
          className="rounded-3xl border border-blue-100 bg-white p-6 shadow-soft"
        >
          <h3 className="text-lg font-bold text-slate-900">Team Members</h3>
          <p className="mt-1 text-xs text-slate-500">Click any profile to view full details.</p>
          <div className="mt-4 space-y-4">
            {members.map((member) => (
              <button
                key={member.name}
                type="button"
                onClick={() => setSelectedMember(member)}
                className={`w-full rounded-xl p-4 text-left ring-1 transition ${selectedMember.name === member.name ? 'bg-blue-50 ring-blue-200' : 'bg-slate-50 ring-slate-100 hover:bg-slate-100'}`}
              >
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="font-bold text-slate-900">{member.name}</p>
                    <p className="text-sm font-semibold text-blue-700">{member.role}</p>
                  </div>
                  <span className="rounded-full bg-white px-2.5 py-1 text-[11px] font-bold text-blue-700 ring-1 ring-blue-100">{member.badge}</span>
                </div>
                <p className="mt-2 text-sm text-slate-600">{member.description}</p>
                {member.details && (
                  <ul className="mt-2 space-y-1.5 text-xs text-slate-600">
                    {member.details.slice(0, 2).map((item) => (
                      <li key={item}>{item}</li>
                    ))}
                  </ul>
                )}
              </button>
            ))}
          </div>
        </motion.article>
      </section>
    </div>
  );
}
