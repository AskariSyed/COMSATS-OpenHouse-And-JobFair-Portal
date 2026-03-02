import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import basicSsl from '@vitejs/plugin-basic-ssl'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), basicSsl()],
  server: {
    host: true,
    https: true,
    proxy: {
      '/api': {
        target: 'http://192.168.137.1:5158',
        changeOrigin: true,
        secure: false,
      },
      '/uploads': {
        target: 'http://192.168.137.1:5158',
        changeOrigin: true,
        secure: false,
      },
    },
  },
})
