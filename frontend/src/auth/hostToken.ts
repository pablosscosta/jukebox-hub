// Keeps the host's access token in localStorage so a page reload doesn't log them out.
// Storage can be unavailable (private mode, blocked site data), so every access is guarded:
// in that case the host just has to log in again after a reload.
const STORAGE_KEY = 'jukebox.hostToken';

export function getHostToken(): string | null {
  try {
    return localStorage.getItem(STORAGE_KEY);
  } catch {
    return null;
  }
}

export function saveHostToken(token: string) {
  try {
    localStorage.setItem(STORAGE_KEY, token);
  } catch {
    // Not persisted; the token still works until the page is reloaded.
  }
}

export function clearHostToken() {
  try {
    localStorage.removeItem(STORAGE_KEY);
  } catch {
    // Nothing to clear.
  }
}
