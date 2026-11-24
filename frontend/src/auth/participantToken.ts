// Keeps each guest's token in localStorage, one per party, so reloading the party page keeps
// them in. Storage can be unavailable (e.g. private mode): then the guest just joins again.
function storageKey(partyId: string) {
  return `jukebox.participant.${partyId}`;
}

export function getParticipantToken(partyId: string): string | null {
  try {
    return localStorage.getItem(storageKey(partyId));
  } catch {
    return null;
  }
}

export function saveParticipantToken(partyId: string, token: string) {
  try {
    localStorage.setItem(storageKey(partyId), token);
  } catch {
    // Not persisted; the guest stays in until the page is reloaded.
  }
}

export function clearParticipantToken(partyId: string) {
  try {
    localStorage.removeItem(storageKey(partyId));
  } catch {
    // Nothing to clear.
  }
}
