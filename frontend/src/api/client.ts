// Talks to the Rails API. In dev it runs on 127.0.0.1:3000; in production set VITE_API_URL.
export const API_URL = import.meta.env.VITE_API_URL ?? 'http://127.0.0.1:3000';

export type Host = {
  id: string;
  displayName: string;
};

type ErrorBody = { error?: { code?: string; message?: string } };

export class ApiError extends Error {
  readonly status: number;
  readonly code: string;

  constructor(status: number, code: string, message: string) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
  }
}

async function request<T>(path: string, init: RequestInit = {}, token?: string): Promise<T> {
  const headers = new Headers(init.headers);
  headers.set('Accept', 'application/json');
  if (init.body) headers.set('Content-Type', 'application/json');
  if (token) headers.set('Authorization', `Bearer ${token}`);

  const response = await fetch(`${API_URL}${path}`, { ...init, headers });

  if (!response.ok) {
    const body = (await response.json().catch(() => ({}))) as ErrorBody;
    throw new ApiError(
      response.status,
      body.error?.code ?? 'unknown_error',
      body.error?.message ?? 'Algo deu errado. Tente de novo.',
    );
  }

  return (response.status === 204 ? undefined : await response.json()) as T;
}

// The login starts with a full page navigation (not fetch): the browser goes to Spotify.
export const spotifyLoginUrl = `${API_URL}/auth/spotify`;

export function exchangeLoginCode(code: string) {
  return request<{ token: string; host: Host }>('/auth/token', {
    method: 'POST',
    body: JSON.stringify({ code }),
  });
}

export function getMe(token: string) {
  return request<Host>('/me', {}, token);
}

export function logout(token: string) {
  return request<undefined>('/auth/token', { method: 'DELETE' }, token);
}
