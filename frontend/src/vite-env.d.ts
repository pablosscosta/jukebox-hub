interface ImportMetaEnv {
  // URL of the Rails API. In dev it defaults to port 3000 on the page's own hostname.
  readonly VITE_API_URL?: string;
  // Who to ask for host access while the Spotify app is in development mode (optional).
  readonly VITE_CONTACT_EMAIL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
