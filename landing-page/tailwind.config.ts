import type { Config } from 'tailwindcss';

export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        brandBlue: '#2563EB',
        brandTeal: '#0D9488',
        ink: '#0f172a'
      },
      boxShadow: {
        soft: '0 18px 45px rgba(15, 23, 42, 0.10)'
      }
    }
  },
  plugins: []
} satisfies Config;