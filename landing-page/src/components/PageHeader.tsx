import { motion } from 'framer-motion';

interface PageHeaderProps {
  title: string;
  subtitle: string;
}

export function PageHeader({ title, subtitle }: PageHeaderProps) {
  return (
    <motion.section
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.45 }}
      className="rounded-2xl border border-blue-100 bg-white p-8 shadow-soft"
    >
      <h1 className="text-3xl font-extrabold text-slate-900 sm:text-4xl">{title}</h1>
      <p className="mt-3 max-w-3xl text-slate-600">{subtitle}</p>
    </motion.section>
  );
}
