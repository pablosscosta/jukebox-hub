/// <reference types="vitest/config" />
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [react()],
  // 127.0.0.1 instead of localhost: Spotify no longer accepts "localhost" in redirect URIs,
  // so the whole dev setup uses the loopback IP to keep cookies and URLs consistent.
  server: { host: '127.0.0.1', port: 5173, strictPort: true },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
  },
});
