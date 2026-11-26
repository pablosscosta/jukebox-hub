// Fictional data for the demo. Names, party and device are made up; the song titles are public.
// Covers are generated SVGs (no album art), so the recording needs no network and is always the same.

export const PARTY_ID = 'demo';
export const HOST_TOKEN = 'demo-host-token';
export const GUEST_TOKEN = 'demo-guest-token';

export const host = { id: 'host-lucas', displayName: 'Lucas', premium: true };

export const participants = {
  host: { id: 'p-lucas', displayName: 'Lucas', role: 'host', joinedAt: '2026-11-28T18:00:00Z' },
  ana: { id: 'p-ana', displayName: 'Ana', role: 'guest', joinedAt: '2026-11-28T18:05:00Z' },
  bruno: { id: 'p-bruno', displayName: 'Bruno', role: 'guest', joinedAt: '2026-11-28T18:40:00Z' },
};

const expiresAt = '2026-11-29T06:00:00Z';

export const party = {
  id: PARTY_ID,
  name: 'Churrasco de sábado',
  status: 'active',
  deviceName: 'Caixa da sala',
  shareUrl: `https://jukebox-hub-web.onrender.com/p/${PARTY_ID}`,
  expiresAt,
  createdAt: '2026-11-28T18:00:00Z',
};

export const publicParty = {
  id: PARTY_ID,
  name: party.name,
  status: 'active',
  hostName: host.displayName,
  expiresAt,
};

// A square cover: a diagonal gradient with the song's initial.
function cover(initial, from, to) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" viewBox="0 0 300 300">
<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="${from}"/><stop offset="1" stop-color="${to}"/></linearGradient></defs>
<rect width="300" height="300" fill="url(#g)"/>
<circle cx="230" cy="70" r="90" fill="#ffffff" fill-opacity="0.08"/>
<text x="40" y="250" font-family="Georgia, serif" font-size="150" font-weight="700" fill="#ffffff" fill-opacity="0.9">${initial}</text>
</svg>`;
  return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
}

function track(trackId, title, artist, durationMs, colors) {
  return { trackId, title, artist, durationMs, imageUrl: cover(title[0], ...colors) };
}

export const tracks = {
  masQueNada: track('t-mas-que-nada', 'Mas, Que Nada!', 'Jorge Ben Jor', 179_000, [
    '#e4572e',
    '#f3a712',
  ]),
  garota: track('t-garota', 'Garota de Ipanema', 'Antônio Carlos Jobim', 196_000, [
    '#1b998b',
    '#2e86ab',
  ]),
  aquarela: track('t-aquarela', 'Aquarela', 'Toquinho', 252_000, ['#c33c54', '#8e44ad']),
  sozinho: track('t-sozinho', 'Sozinho - Ao Vivo', 'Caetano Veloso', 231_000, [
    '#254e70',
    '#37718e',
  ]),
  doLeme: track('t-do-leme', 'Do Leme ao Pontal', 'Tim Maia', 221_000, ['#f28f3b', '#c8553d']),
  primavera: track('t-primavera', 'Primavera', 'Tim Maia', 178_000, ['#4c956c', '#2c6e49']),
  azul: track('t-azul', 'Azul da Cor do Mar', 'Tim Maia', 254_000, ['#3a86ff', '#023e8a']),
  gostava: track('t-gostava', 'Gostava Tanto de Você', 'Tim Maia', 199_000, ['#9d4edd', '#5a189a']),
};

// What the search returns, whatever the query (the guest searches "Tim Maia").
export const searchResults = [tracks.doLeme, tracks.azul, tracks.primavera, tracks.gostava];
