/// <reference types="vitest/config" />
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [react()],
  // Listens on every network interface: the host uses http://127.0.0.1:5173 (Spotify rejects
  // "localhost" in redirect URIs) and guests' phones on the same Wi-Fi use the notebook's IP.
  server: { host: true, port: 5173, strictPort: true },
  test: {
    environment: 'jsdom',
    // Pages talk to the API on the same hostname they were opened from (see api/client.ts).
    environmentOptions: { jsdom: { url: 'http://127.0.0.1:5173/' } },
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
  },
});
