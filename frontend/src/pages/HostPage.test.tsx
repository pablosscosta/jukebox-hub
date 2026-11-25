import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { getHostToken, saveHostToken } from '../auth/hostToken';
import { mockApi, renderAt } from '../test/utils';

const host = { id: '1', displayName: 'Pablo', premium: true };
const noParty = { status: 404, body: { error: { code: 'no_active_party', message: 'x' } } };
const party = {
  id: 'party-1',
  name: 'Churrasco',
  status: 'active',
  deviceName: 'pablo-note',
  shareUrl: 'http://127.0.0.1:5173/p/party-1',
  expiresAt: '2026-11-24T23:00:00Z',
  createdAt: '2026-11-24T17:00:00Z',
};
const hostParticipant = {
  id: '9',
  displayName: 'Pablo',
  role: 'host',
  joinedAt: '2026-11-24T17:00:00Z',
};
const emptyQueue = { nowPlaying: null, upNext: [], maxPendingPerParticipant: 5 };
// Once a party shows up, the page loads the host's own participant and the queue.
const partyRoutes = {
  'GET /parties/party-1/participants/me': { status: 200, body: hostParticipant },
  'GET /parties/party-1/queue': { status: 200, body: emptyQueue },
};
const notebook = { id: 'note', name: 'pablo-note', type: 'Computer', isActive: true };
const phone = { id: 'phone', name: 'iPhone', type: 'Smartphone', isActive: false };

// Body of the last POST: other requests (like loading the queue) may come after it.
function lastPostBody(fetchMock: ReturnType<typeof mockApi>) {
  const post = fetchMock.mock.calls.findLast(([, init]) => init?.method === 'POST');
  return JSON.parse(post?.[1]?.body as string) as unknown;
}

describe('HostPage', () => {
  beforeEach(() => {
    saveHostToken('host-token');
  });

  it('greets the host by name', async () => {
    const fetchMock = mockApi({
      'GET /me': { status: 200, body: host },
      ...partyRoutes,
      'GET /me/party': noParty,
      'GET /me/devices': { status: 200, body: [] },
    });

    renderAt('/host');

    expect(await screen.findByRole('heading', { name: 'Olá, Pablo!' })).toBeInTheDocument();
    const [, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(new Headers(init.headers).get('Authorization')).toBe('Bearer host-token');
  });

  it('sends a visitor without login back to the home page', () => {
    localStorage.clear();

    renderAt('/host');

    expect(screen.getByRole('link', { name: 'Entrar com Spotify' })).toBeInTheDocument();
  });

  it('forgets an expired token and goes back to the home page', async () => {
    mockApi({
      'GET /me': { status: 401, body: { error: { code: 'unauthorized', message: 'x' } } },
      'GET /me/party': { status: 401, body: { error: { code: 'unauthorized', message: 'x' } } },
    });

    renderAt('/host');

    expect(await screen.findByRole('link', { name: 'Entrar com Spotify' })).toBeInTheDocument();
    expect(getHostToken()).toBeNull();
  });

  it('logs out', async () => {
    const fetchMock = mockApi({
      'GET /me': { status: 200, body: host },
      ...partyRoutes,
      'GET /me/party': { status: 200, body: party },
      'DELETE /auth/token': { status: 204 },
    });
    renderAt('/host');

    await userEvent.click(await screen.findByRole('button', { name: 'Sair' }));

    expect(await screen.findByRole('link', { name: 'Entrar com Spotify' })).toBeInTheDocument();
    expect(getHostToken()).toBeNull();
    expect(fetchMock).toHaveBeenCalledWith(
      'http://127.0.0.1:3000/auth/token',
      expect.objectContaining({ method: 'DELETE' }),
    );
  });

  it('shows a message when the API is down', async () => {
    mockApi({ 'GET /me': { status: 500 }, 'GET /me/party': { status: 500 } });

    renderAt('/host');

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'Não conseguimos carregar seus dados',
    );
  });

  describe('when a party is running', () => {
    it('shows the party with its invite link', async () => {
      mockApi({
        'GET /me': { status: 200, body: host },
        ...partyRoutes,
        ...partyRoutes,
        'GET /me/party': { status: 200, body: party },
      });

      renderAt('/host');

      expect(await screen.findByRole('heading', { name: 'Churrasco' })).toBeInTheDocument();
      expect(screen.getByText(/Tocando em pablo-note/)).toBeInTheDocument();
      expect(screen.getByLabelText('Link de convite')).toHaveValue(party.shareUrl);
      expect(screen.queryByRole('button', { name: 'Criar party' })).not.toBeInTheDocument();
    });

    it('lets the host search and queue songs like a guest', async () => {
      const fetchMock = mockApi({
        'GET /me': { status: 200, body: host },
        'GET /me/party': { status: 200, body: party },
        ...partyRoutes,
      });

      renderAt('/host');

      expect(await screen.findByText('Suas músicas esperando: 0 de 5')).toBeInTheDocument();
      expect(screen.getByLabelText('Buscar música ou artista')).toBeInTheDocument();
      const [, init] = fetchMock.mock.lastCall as [string, RequestInit];
      expect(new Headers(init.headers).get('Authorization')).toBe('Bearer host-token');
    });

    describe('playback controls', () => {
      const song = {
        trackId: 'wave',
        title: 'Wave',
        artist: 'Tom Jobim',
        durationMs: 200000,
        imageUrl: null,
        addedBy: { id: '2', displayName: 'Ana' },
        addedAt: '2026-11-24T18:00:00Z',
      };
      const playing = {
        ...song,
        id: '10',
        trackId: 'ipanema',
        title: 'Garota de Ipanema',
        status: 'playing',
      };
      const waiting = { ...song, id: '11', status: 'pending' };
      const queueWith = (extra: Record<string, unknown>) => ({
        status: 200,
        body: { ...emptyQueue, upNext: [waiting], playbackState: 'playing', ...extra },
      });

      function openHostParty(routes: Parameters<typeof mockApi>[0]) {
        const fetchMock = mockApi({
          'GET /me': { status: 200, body: host },
          'GET /me/party': { status: 200, body: party },
          ...partyRoutes,
          ...routes,
        });
        renderAt('/host');
        return fetchMock;
      }

      it('skips the song that is playing', async () => {
        const fetchMock = openHostParty({
          'GET /parties/party-1/queue': [
            queueWith({ nowPlaying: playing }),
            queueWith({ nowPlaying: { ...waiting, status: 'playing' }, upNext: [] }),
          ],
          'POST /parties/party-1/playback/next': { status: 204 },
        });

        await userEvent.click(await screen.findByRole('button', { name: 'Pular' }));

        expect(await screen.findByText(/A fila está vazia/)).toBeInTheDocument();
        expect(fetchMock).toHaveBeenCalledWith(
          'http://127.0.0.1:3000/parties/party-1/playback/next',
          expect.objectContaining({ method: 'POST' }),
        );
      });

      it('removes a song from the queue', async () => {
        const fetchMock = openHostParty({
          'GET /parties/party-1/queue': [
            queueWith({ nowPlaying: playing }),
            queueWith({ nowPlaying: playing, upNext: [] }),
          ],
          'DELETE /parties/party-1/queue/11': { status: 204 },
        });

        await userEvent.click(await screen.findByRole('button', { name: 'Remover Wave' }));

        expect(await screen.findByText(/A fila está vazia/)).toBeInTheDocument();
        expect(fetchMock).toHaveBeenCalledWith(
          'http://127.0.0.1:3000/parties/party-1/queue/11',
          expect.objectContaining({ method: 'DELETE' }),
        );
      });

      it('starts the queue again after Spotify stopped', async () => {
        openHostParty({
          'GET /parties/party-1/queue': [
            queueWith({ playbackState: 'paused' }),
            queueWith({ nowPlaying: { ...waiting, status: 'playing' }, upNext: [] }),
          ],
          'POST /parties/party-1/playback/start': { status: 204 },
        });

        expect(await screen.findByText(/O Spotify parou no meio da música/)).toBeInTheDocument();
        await userEvent.click(screen.getByRole('button', { name: 'Tocar' }));

        expect(await screen.findByRole('button', { name: 'Pular' })).toBeInTheDocument();
      });

      it('goes back to the queue while their own Spotify song plays', async () => {
        const fetchMock = openHostParty({
          'GET /parties/party-1/queue': [
            queueWith({
              playbackState: 'external',
              externalTrack: { ...song, title: 'Have a Nice Day' },
            }),
            queueWith({ nowPlaying: { ...waiting, status: 'playing' }, upNext: [] }),
          ],
          'POST /parties/party-1/playback/start': { status: 204 },
        });

        await userEvent.click(await screen.findByRole('button', { name: 'Voltar para a fila' }));

        expect(await screen.findByRole('button', { name: 'Pular' })).toBeInTheDocument();
        expect(fetchMock).toHaveBeenCalledWith(
          'http://127.0.0.1:3000/parties/party-1/playback/start',
          expect.objectContaining({ method: 'POST' }),
        );
      });

      it('explains when Spotify is not open on the device', async () => {
        const message =
          'O Spotify não está aberto em pablo-note. Abra o Spotify nele e toque de novo.';
        openHostParty({
          'GET /parties/party-1/queue': queueWith({ playbackState: 'idle' }),
          'POST /parties/party-1/playback/start': {
            status: 422,
            body: { error: { code: 'device_unavailable', message } },
          },
        });

        await userEvent.click(await screen.findByRole('button', { name: 'Tocar' }));

        expect(await screen.findByRole('alert')).toHaveTextContent(message);
      });
    });

    it('shows a QR code that guests can scan', async () => {
      mockApi({
        'GET /me': { status: 200, body: host },
        ...partyRoutes,
        ...partyRoutes,
        'GET /me/party': { status: 200, body: party },
      });

      renderAt('/host');

      expect(await screen.findByRole('img', { name: 'QR code do convite' })).toBeInTheDocument();
    });

    it('copies the invite link', async () => {
      mockApi({
        'GET /me': { status: 200, body: host },
        ...partyRoutes,
        ...partyRoutes,
        'GET /me/party': { status: 200, body: party },
      });
      const user = userEvent.setup();
      renderAt('/host');

      await user.click(await screen.findByRole('button', { name: 'Copiar' }));

      expect(await navigator.clipboard.readText()).toBe(party.shareUrl);
      expect(screen.getByRole('button', { name: 'Copiado' })).toBeInTheDocument();
    });
  });

  describe('creating a party', () => {
    it('asks the host to open Spotify when no device is available', async () => {
      mockApi({
        'GET /me': { status: 200, body: host },
        ...partyRoutes,
        ...partyRoutes,
        'GET /me/party': noParty,
        'GET /me/devices': [
          { status: 200, body: [] },
          { status: 200, body: [notebook] },
        ],
      });
      renderAt('/host');

      expect(await screen.findByText(/Abra o Spotify/)).toBeInTheDocument();
      await userEvent.click(screen.getByRole('button', { name: 'Recarregar devices' }));

      expect(await screen.findByRole('radio', { name: /pablo-note/ })).toBeInTheDocument();
    });

    it('starts with the device that is playing and creates the party', async () => {
      const fetchMock = mockApi({
        'GET /me': { status: 200, body: host },
        ...partyRoutes,
        ...partyRoutes,
        'GET /me/party': noParty,
        'GET /me/devices': { status: 200, body: [phone, notebook] },
        'POST /parties': { status: 201, body: party },
      });
      renderAt('/host');

      expect(await screen.findByRole('radio', { name: /pablo-note/ })).toBeChecked();
      await userEvent.type(screen.getByLabelText('Nome da party'), ' Churrasco ');
      await userEvent.click(screen.getByRole('button', { name: 'Criar party' }));

      expect(await screen.findByLabelText('Link de convite')).toHaveValue(party.shareUrl);
      expect(lastPostBody(fetchMock)).toEqual({ name: 'Churrasco', deviceId: 'note' });
    });

    it('uses the device the host picks', async () => {
      const fetchMock = mockApi({
        'GET /me': { status: 200, body: host },
        ...partyRoutes,
        ...partyRoutes,
        'GET /me/party': noParty,
        'GET /me/devices': { status: 200, body: [phone, notebook] },
        'POST /parties': { status: 201, body: party },
      });
      renderAt('/host');

      await userEvent.click(await screen.findByRole('radio', { name: /iPhone/ }));
      await userEvent.type(screen.getByLabelText('Nome da party'), 'Churrasco');
      await userEvent.click(screen.getByRole('button', { name: 'Criar party' }));

      await screen.findByLabelText('Link de convite');
      expect(lastPostBody(fetchMock)).toEqual({ name: 'Churrasco', deviceId: 'phone' });
    });

    it('shows the party that already exists when the API answers 409', async () => {
      mockApi({
        'GET /me': { status: 200, body: host },
        ...partyRoutes,
        ...partyRoutes,
        'GET /me/party': noParty,
        'GET /me/devices': { status: 200, body: [notebook] },
        'POST /parties': {
          status: 409,
          body: { error: { code: 'active_party_exists', message: 'x' }, party },
        },
      });
      renderAt('/host');

      await userEvent.type(await screen.findByLabelText('Nome da party'), 'Outra');
      await userEvent.click(screen.getByRole('button', { name: 'Criar party' }));

      expect(await screen.findByRole('heading', { name: 'Churrasco' })).toBeInTheDocument();
    });

    it('explains when the device was closed and reloads the list', async () => {
      const message = 'Esse device não está mais disponível. Abra o Spotify nele e tente de novo.';
      const fetchMock = mockApi({
        'GET /me': { status: 200, body: host },
        ...partyRoutes,
        ...partyRoutes,
        'GET /me/party': noParty,
        'GET /me/devices': { status: 200, body: [notebook] },
        'POST /parties': { status: 422, body: { error: { code: 'device_unavailable', message } } },
      });
      renderAt('/host');

      await userEvent.type(await screen.findByLabelText('Nome da party'), 'Churrasco');
      await userEvent.click(screen.getByRole('button', { name: 'Criar party' }));

      expect(await screen.findByRole('alert')).toHaveTextContent(message);
      const deviceCalls = fetchMock.mock.calls.filter(([url]) => url.endsWith('/me/devices'));
      expect(deviceCalls).toHaveLength(2);
    });

    it('tells a host without Premium why they cannot create a party', async () => {
      mockApi({
        'GET /me': { status: 200, body: { ...host, premium: false } },
        'GET /me/party': noParty,
      });

      renderAt('/host');

      expect(await screen.findByRole('alert')).toHaveTextContent('Spotify Premium');
      expect(screen.queryByRole('button', { name: 'Criar party' })).not.toBeInTheDocument();
    });
  });
});
