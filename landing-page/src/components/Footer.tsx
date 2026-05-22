export function Footer() {
  return (
    <footer className="border-t border-blue-100 bg-white">
      <div className="mx-auto grid max-w-7xl gap-8 px-4 py-10 sm:px-6 lg:grid-cols-3 lg:px-8">
        <div className="flex items-center gap-3">
          <img src="/assets/LogoWithoutBg.png" alt="COMSATS Job Fair" className="h-12 w-12 rounded-xl border border-blue-100 object-contain" />
          <div>
            <p className="font-bold">COMSATS Job Fair and Open House Solution</p>
            <p className="text-sm text-slate-600">Central portal for students, companies, and admins.</p>
          </div>
          
        </div>

        <div> 
          <p className="text-sm font-bold text-slate-900">Portal Links</p>
          <div className="mt-3 space-y-2 text-sm text-slate-600">
            <a className="block hover:text-blue-600" href="https://comsats.student.jfair.tech">comsats.student.jfair.tech</a>
            <a className="block hover:text-blue-600" href="https://comsats.company.jfair.tech">comsats.company.jfair.tech</a>
            <a className="block hover:text-blue-600" href="https://comsats.admin.jfair.tech">comsats.admin.jfair.tech</a>
          </div>
        </div>

        <div className="rounded-xl border border-blue-100 bg-blue-50 p-4 text-xs text-blue-900">
          <strong>Disclaimer:</strong> This is a Final Year Project by COMSATS Students (Class of 2026) and does not refer to any official COMSATS platform, policy, or communication.
        </div>
      </div>
    </footer>
  );
}
