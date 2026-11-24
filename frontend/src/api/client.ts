// Talks to the Rails API. In production set VITE_API_URL. In dev the API is on port 3000 of the
// same machine the page came from: the host opens 127.0.0.1 and a guest's phone opens the
// notebook's Wi-Fi IP, and each one reaches the API at that same address.
export const API_URL =
  import.meta.env.VITE_API_URL ?? `${window.location.protocol}//${window.location.hostname}:3000`;

export type Host = {
  id: string;
  displayName: string;
  premium: boolean;
};

export type Device = {
  id: string;
  name: string;
  type: string;
  isActive: boolean;
};

export type Party = {
  id: string;
  name: string;
  status: 'active' | 'ended';
  deviceName: string;
  shareUrl: string;
  expiresAt: string;
  createdAt: string;
};

// What a guest sees about a party before joining.
export type PublicParty = {
  id: string;
  name: string;
  status: 'active' | 'ended';
  hostName: string;
  expiresAt: string;
};

export type Participant = {
  id: string;
  displayName: string;
  joinedAt: string;
};

type ErrorBody = { error?: { code?: string; message?: string } };

export class ApiError extends Error {
  readonly status: number;
  readonly code: string;
  // The whole response body, for errors that carry extra data (e.g. 409 with the current party).
  readonly body: unknown;

  constructor(status: number, code: string, message: string, body: unknown = {}) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
    this.body = body;
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
      body,
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

export function getDevices(token: string) {
  return request<Device[]>('/me/devices', {}, token);
}

// The host's active party, or null when there is none.
export async function getCurrentParty(token: string) {
  try {
    return await request<Party>('/me/party', {}, token);
  } catch (err) {
    if (err instanceof ApiError && err.code === 'no_active_party') return null;
    throw err;
  }
}

export function createParty(token: string, params: { name: string; deviceId: string }) {
  return request<Party>('/parties', { method: 'POST', body: JSON.stringify(params) }, token);
}

export function getParty(partyId: string) {
  return request<PublicParty>(`/parties/${encodeURIComponent(partyId)}`);
}

export function joinParty(partyId: string, displayName: string) {
  return request<{ participantToken: string; participant: Participant }>(
    `/parties/${encodeURIComponent(partyId)}/participants`,
    { method: 'POST', body: JSON.stringify({ displayName }) },
  );
}

export function getMyParticipant(partyId: string, token: string) {
  return request<Participant>(`/parties/${encodeURIComponent(partyId)}/participants/me`, {}, token);
}
