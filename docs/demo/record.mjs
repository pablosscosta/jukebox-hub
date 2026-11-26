// Records the demo video: the real frontend, driven by Playwright, with every API call answered by
// fictional data (fixtures.mjs). Two screens are recorded at once and share the same mocked state:
// the host on a desktop and a guest on a phone. See README.md in this folder.
import { execFileSync, spawn } from 'node:child_process';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { setTimeout as sleep } from 'node:timers/promises';
import { chromium } from 'playwright';
import {
  GUEST_TOKEN,
  HOST_TOKEN,
  PARTY_ID,
  host,
  participants,
  party,
  publicParty,
  searchResults,
  tracks,
} from './fixtures.mjs';

const ROOT = resolve(import.meta.dirname, '../..');
const ASSETS = join(ROOT, 'docs/assets');
// A port of our own, so a dev server you already have running is left alone.
const APP_URL = 'http://127.0.0.1:5174';
const API_URL = 'http://127.0.0.1:3000';

const HOST_VIEWPORT = { width: 1000, height: 844 };
const GUEST_VIEWPORT = { width: 390, height: 844 };
// When the song on screen ends, counted from the start of the recording.
const SONG_ENDS_AFTER_MS = 14_500;
// The first moments only show the pages loading.
const TRIM_START_S = 1;
const BACKGROUND = '#121212';

await main();

async function main() {
  const devServer = await startDevServer();
  const workDir = mkdtempSync(join(tmpdir(), 'jukebox-demo-'));
  try {
    const raw = await record(workDir);
    encode(raw);
  } finally {
    devServer.kill();
    rmSync(workDir, { recursive: true, force: true });
  }
}

// Runs Vite pointing at the address the mocks intercept, whatever frontend/.env says.
async function startDevServer() {
  const server = spawn('npx', ['vite', '--port', '5174', '--strictPort'], {
    cwd: join(ROOT, 'frontend'),
    env: { ...process.env, VITE_API_URL: API_URL },
    stdio: 'ignore',
  });
  for (let attempt = 0; attempt < 60; attempt++) {
    try {
      if ((await fetch(APP_URL)).ok) return server;
    } catch {
      // Not up yet.
    }
    await sleep(500);
  }
  server.kill();
  throw new Error(`The dev server did not start at ${APP_URL}.`);
}

// The fake API: the same contract as docs/api.md, with the state kept here in memory.
function createMockApi(startedAt) {
  const item = (track, id, addedBy, status = 'pending') => ({
    ...track,
    id,
    status,
    addedBy: { id: addedBy.id, displayName: addedBy.displayName },
    addedAt: new Date(startedAt).toISOString(),
    startedAt: null,
  });

  const nowPlaying = item(tracks.masQueNada, 'q1', participants.ana, 'playing');
  // Started long ago, so it ends on cue during the recording.
  nowPlaying.startedAt = new Date(
    startedAt + SONG_ENDS_AFTER_MS - tracks.masQueNada.durationMs,
  ).toISOString();

  const state = {
    nowPlaying,
    // Already in play order: the real API applies the fairness rule, here it is set by hand.
    upNext: [
      item(tracks.garota, 'q2', participants.ana),
      item(tracks.aquarela, 'q3', participants.host),
      item(tracks.sozinho, 'q4', participants.ana),
    ],
  };

  // Each open live stream (SSE) waits here until the next change is announced.
  let waitingStreams = [];
  function notifyChange() {
    const streams = waitingStreams;
    waitingStreams = [];
    for (const resolveStream of streams) resolveStream();
  }

  function queue() {
    return {
      nowPlaying: state.nowPlaying,
      upNext: state.upNext,
      maxPendingPerParticipant: 5,
      playbackState: 'playing',
      externalTrack: null,
    };
  }

  // A guest's first song goes ahead of a second song from someone else (the fairness rule).
  function addToQueue(trackId) {
    const track = searchResults.find((result) => result.trackId === trackId);
    const added = item(track, `q${String(state.upNext.length + 2)}`, participants.bruno);
    state.upNext.splice(2, 0, added);
    notifyChange();
    return added;
  }

  function playNext() {
    const [next, ...rest] = state.upNext;
    state.nowPlaying = { ...next, status: 'playing', startedAt: new Date().toISOString() };
    state.upNext = rest;
    notifyChange();
  }

  async function handle(route) {
    const request = route.request();
    const url = new URL(request.url());
    const path = url.pathname;
    const method = request.method();
    const token = request.headers().authorization?.replace('Bearer ', '');
    const asGuest = token === GUEST_TOKEN;

    if (method === 'OPTIONS') return route.fulfill({ status: 204, headers: corsHeaders() });

    const partyPath = `/parties/${PARTY_ID}`;
    if (method === 'GET' && path === '/me') return json(route, host);
    if (method === 'GET' && path === '/me/party') return json(route, party);
    if (method === 'GET' && path === partyPath) return json(route, publicParty);
    if (method === 'POST' && path === `${partyPath}/participants`) {
      await sleep(400);
      return json(route, { participantToken: GUEST_TOKEN, participant: participants.bruno }, 201);
    }
    if (method === 'GET' && path === `${partyPath}/participants/me`) {
      return json(route, asGuest ? participants.bruno : participants.host);
    }
    if (method === 'GET' && path === `${partyPath}/queue`) return json(route, queue());
    if (method === 'POST' && path === `${partyPath}/queue`) {
      await sleep(300);
      return json(route, addToQueue(request.postDataJSON().trackId), 201);
    }
    if (method === 'GET' && path === `${partyPath}/search`) {
      await sleep(500);
      return json(route, searchResults);
    }
    if (method === 'GET' && path === `${partyPath}/events`) return liveStream(route);

    console.warn(`Not mocked: ${method} ${path}`);
    return json(route, { error: { code: 'not_mocked', message: 'Fora da demo.' } }, 404);
  }

  // The real EventSource stays in charge: the response holds until something changes, then sends
  // the notice and ends, and the browser reconnects (after "retry" ms) to wait for the next one.
  async function liveStream(route) {
    await new Promise((resolveStream) => waitingStreams.push(resolveStream));
    await route
      .fulfill({
        status: 200,
        headers: { ...corsHeaders(), 'content-type': 'text/event-stream' },
        body: 'retry: 100\nevent: queue_changed\ndata: {}\n\n',
      })
      .catch(() => undefined); // The page may be gone when the recording ends.
  }

  return { handle, playNext };
}

function corsHeaders() {
  return {
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET, POST, DELETE, OPTIONS',
    'access-control-allow-headers': 'authorization, content-type, accept',
  };
}

function json(route, body, status = 200) {
  return route.fulfill({
    status,
    headers: { ...corsHeaders(), 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

async function record(workDir) {
  const browser = await chromium.launch();
  const startedAt = Date.now();
  const api = createMockApi(startedAt);

  const newPage = async (name, viewport, extra = {}) => {
    const context = await browser.newContext({
      viewport,
      colorScheme: 'dark',
      locale: 'pt-BR',
      recordVideo: { dir: join(workDir, name), size: viewport },
      ...extra,
    });
    await context.route(`${API_URL}/**`, api.handle);
    return context.newPage();
  };

  const hostPage = await newPage('host', HOST_VIEWPORT);
  await hostPage.addInitScript((token) => {
    localStorage.setItem('jukebox.hostToken', token);
  }, HOST_TOKEN);
  const guestPage = await newPage('guest', GUEST_VIEWPORT, { isMobile: true, hasTouch: true });

  await Promise.all([hostPage.goto(`${APP_URL}/host`), guestPage.goto(`${APP_URL}/p/${PARTY_ID}`)]);
  await playGuestScene(guestPage);

  // The song on screen reaches its end and the next one starts on both screens.
  await sleep(Math.max(startedAt + SONG_ENDS_AFTER_MS - Date.now(), 0));
  api.playNext();
  await sleep(3500);
  const durationS = (Date.now() - startedAt) / 1000 - TRIM_START_S;

  const videos = { host: hostPage.video(), guest: guestPage.video() };
  // Closing each context first lets Playwright finish writing its video.
  await Promise.all([hostPage.context().close(), guestPage.context().close()]);
  await browser.close();
  return {
    durationS,
    host: await videos.host.path(),
    guest: await videos.guest.path(),
  };
}

async function playGuestScene(page) {
  await page.getByLabel('Seu nome (opcional)').waitFor();
  await sleep(2000);
  await page.getByLabel('Seu nome (opcional)').pressSequentially('Bruno', { delay: 120 });
  await sleep(300);
  await page.getByRole('button', { name: 'Entrar na party' }).click();

  const search = page.getByLabel('Buscar música ou artista');
  await search.waitFor();
  await sleep(900);
  await smoothScroll(page, '#search-title');
  await search.pressSequentially('Tim Maia', { delay: 90 });
  await page.getByRole('button', { name: 'Buscar' }).click();

  const add = page.getByRole('button', { name: `Adicionar ${tracks.doLeme.title}` });
  await add.waitFor();
  await sleep(1300);
  await add.click();
  await page.getByRole('status').waitFor();
  await sleep(1800);
  await smoothScroll(page, 'body');
}

async function smoothScroll(page, selector) {
  await page.evaluate((target) => {
    document.querySelector(target)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }, selector);
  await sleep(700);
}

// WebM from Playwright -> one MP4 per screen, one with both side by side, a poster for each and the
// GIF for the README.
function encode(raw) {
  const timing = ['-ss', String(TRIM_START_S), '-t', raw.durationS.toFixed(2)];
  const asset = (name) => join(ASSETS, name);

  toMp4([...timing, '-i', raw.host], 'fps=30', asset('demo-host.mp4'));
  toMp4([...timing, '-i', raw.guest], 'fps=30', asset('demo-convidado.mp4'));
  // Both screens with a gap between them: the guest's action and the host's screen reacting live.
  toMp4(
    ['-i', asset('demo-host.mp4'), '-i', asset('demo-convidado.mp4')],
    `[0:v]pad=iw+24:ih:0:0:color=${BACKGROUND}[host];[host][1:v]hstack=inputs=2`,
    asset('demo.mp4'),
  );
  for (const view of ['demo-host', 'demo-convidado', 'demo']) {
    poster(asset(`${view}.mp4`), asset(`${view}.jpg`));
  }

  // Smaller and with fewer colors than the MP4, so it stays light in the README.
  ffmpeg([
    '-i',
    asset('demo.mp4'),
    '-filter_complex',
    'fps=10,scale=900:-1:flags=lanczos,split[a][b];' +
      '[a]palettegen=max_colors=128:stats_mode=diff[palette];' +
      '[b][palette]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle',
    '-loop',
    '0',
    asset('demo.gif'),
  ]);
  console.log(`Done: ${ASSETS}/demo.mp4, demo-host.mp4, demo-convidado.mp4, demo*.jpg, demo.gif`);
}

// H.264 without audio, with the index at the start so the browser plays it before it fully loads.
function toMp4(inputs, filter, output) {
  ffmpeg([
    ...inputs,
    '-an',
    '-filter_complex',
    `${filter},format=yuv420p`,
    '-c:v',
    'libx264',
    '-preset',
    'slow',
    '-crf',
    '24',
    '-movflags',
    '+faststart',
    output,
  ]);
}

// The last moments: the new song playing and the queue with the guest's song.
function poster(mp4, output) {
  ffmpeg(['-sseof', '-0.5', '-i', mp4, '-frames:v', '1', '-q:v', '3', output]);
}

function ffmpeg(args) {
  execFileSync('ffmpeg', ['-y', '-loglevel', 'error', ...args], { stdio: 'inherit' });
}
