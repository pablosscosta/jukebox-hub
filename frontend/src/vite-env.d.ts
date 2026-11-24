interface ImportMetaEnv {
  // URL of the Rails API. In dev it defaults to port 3000 on the page's own hostname.
  readonly VITE_API_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
