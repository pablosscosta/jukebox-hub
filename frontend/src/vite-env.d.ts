interface ImportMetaEnv {
  // URL of the Rails API. Defaults to http://127.0.0.1:3000 in dev.
  readonly VITE_API_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
