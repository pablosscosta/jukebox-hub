import { screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { getParticipantToken, saveParticipantToken } from '../../auth/participantToken';
import { emitPartyEvent, mockApi, openStreams, renderAt } from '../../test/utils';

// The jukebox is tested through the guest page, the way a guest uses it.
const partyId = '3f9c0000-0000-0000-0000-000000000001';
const partyPath = `/parties/${partyId}`;
const party = {
  id: partyId,
  name: 'Churrasco',
  status: 'active',
  hostName: 'Pablo',
  expiresAt: '2026-11-24T23:00:00Z',
};
const ana = { id: '1', displayName: 'Ana', role: 'guest', joinedAt: '2026-11-24T18:00:00Z' };

const ipanema = {
  trackId: 'ipanema',
  title: 'Garota de Ipanema',
  artist: 'Tom Jobim',
  durationMs: 323000,
  imageUrl: 'https://i.scdn.co/image/300',
};
const wave = { ...ipanema, trackId: 'wave', title: 'Wave' };

function queueItem(track: typeof ipanema, id: string, addedBy = { id: '1', displayName: 'Ana' }) {
  return { ...track, id, status: 'pending', addedBy, addedAt: '2026-11-24T18:00:00Z' };
}
function queue(upNext: ReturnType<typeof queueItem>[] = [], extra: Record<string, unknown> = {}) {
  return {
    status: 200,
    body: {
      nowPlaying: null,
      upNext,
      maxPendingPerParticipant: 5,
      playbackState: 'idle',
      ...extra,
    },
  };
}
const error = (status: number, code: string, message = 'x') => ({
  status,
  body: { error: { code, message } },
});

function openJoinedParty(routes: Parameters<typeof mockApi>[0]) {
  saveParticipantToken(partyId, 'guest-token');
  const fetchMock = mockApi({
    [`GET ${partyPath}`]: { status: 200, body: party },
    [`GET ${partyPath}/participants/me`]: { status: 200, body: ana },
    ...routes,
  });
  renderAt(`/p/${partyId}`);
  return fetchMock;
}

async function search(query: string) {
  await userEvent.type(await screen.findByLabelText('Buscar música ou artista'), query);
  await userEvent.click(screen.getByRole('button', { name: 'Buscar' }));
}

describe('Jukebox', () => {
  it('shows the queue in the order the API sends, with who added each song', async () => {
    const bruno = { id: '2', displayName: 'Bruno' };
    openJoinedParty({
      [`GET ${partyPath}/queue`]: queue([queueItem(ipanema, '10'), queueItem(wave, '11', bruno)]),
    });

    const list = await screen.findByRole('list', { name: 'Próximas músicas' });

    const items = within(list).getAllByRole('listitem');
    expect(items[0]).toHaveTextContent('Garota de Ipanema');
    expect(items[0]).toHaveTextContent('por você');
    expect(items[1]).toHaveTextContent('Wave');
    expect(items[1]).toHaveTextContent('por Bruno');
    expect(screen.getByText('Suas músicas esperando: 1 de 5')).toBeInTheDocument();
  });

  it('says when the queue is empty', async () => {
    openJoinedParty({ [`GET ${partyPath}/queue`]: queue() });

    expect(await screen.findByText(/A fila está vazia/)).toBeInTheDocument();
  });

  it('searches a song and adds it to the queue', async () => {
    const fetchMock = openJoinedParty({
      [`GET ${partyPath}/queue`]: [queue(), queue([queueItem(ipanema, '10')])],
      [`GET ${partyPath}/search`]: { status: 200, body: [ipanema, wave] },
      [`POST ${partyPath}/queue`]: { status: 201, body: queueItem(ipanema, '10') },
    });

    await search('ipanema');
    await userEvent.click(
      await screen.findByRole('button', { name: 'Adicionar Garota de Ipanema' }),
    );

    expect(await screen.findByRole('status')).toHaveTextContent(
      '"Garota de Ipanema" entrou na fila.',
    );
    const list = await screen.findByRole('list', { name: 'Próximas músicas' });
    expect(list).toHaveTextContent('Garota de Ipanema');
    const searchCall = fetchMock.mock.calls.find(([url]) => url.includes('/search'));
    expect(new URL(searchCall?.[0] ?? '').searchParams.get('q')).toBe('ipanema');
  });

  it('clears the search after adding a song', async () => {
    openJoinedParty({
      [`GET ${partyPath}/queue`]: [queue(), queue([queueItem(ipanema, '10')])],
      [`GET ${partyPath}/search`]: { status: 200, body: [ipanema, wave] },
      [`POST ${partyPath}/queue`]: { status: 201, body: queueItem(ipanema, '10') },
    });

    await search('ipanema');
    await userEvent.click(
      await screen.findByRole('button', { name: 'Adicionar Garota de Ipanema' }),
    );

    await screen.findByRole('status');
    expect(screen.queryByRole('list', { name: 'Resultados da busca' })).not.toBeInTheDocument();
    expect(screen.getByLabelText('Buscar música ou artista')).toHaveValue('');
  });

  it('clears the search with the button', async () => {
    openJoinedParty({
      [`GET ${partyPath}/queue`]: queue(),
      [`GET ${partyPath}/search`]: { status: 200, body: [wave] },
    });

    await search('wave');
    await userEvent.click(await screen.findByRole('button', { name: 'Limpar' }));

    expect(screen.queryByRole('list', { name: 'Resultados da busca' })).not.toBeInTheDocument();
    expect(screen.getByLabelText('Buscar música ou artista')).toHaveValue('');
  });

  it("doesn't offer songs that are already in the queue", async () => {
    openJoinedParty({
      [`GET ${partyPath}/queue`]: queue([
        queueItem(ipanema, '10', { id: '2', displayName: 'Bruno' }),
      ]),
      [`GET ${partyPath}/search`]: { status: 200, body: [ipanema, wave] },
    });

    await search('jobim');

    expect(
      await screen.findByRole('button', { name: 'Adicionar Garota de Ipanema' }),
    ).toBeDisabled();
    expect(screen.getByRole('button', { name: 'Adicionar Wave' })).toBeEnabled();
  });

  it('stops adding when the guest has 5 songs waiting', async () => {
    const mine = ['a', 'b', 'c', 'd', 'e'].map((id) => queueItem({ ...ipanema, trackId: id }, id));
    openJoinedParty({
      [`GET ${partyPath}/queue`]: queue(mine),
      [`GET ${partyPath}/search`]: { status: 200, body: [wave] },
    });

    await search('wave');

    expect(await screen.findByRole('button', { name: 'Adicionar Wave' })).toBeDisabled();
    expect(screen.getByText(/Você chegou ao limite da fila/)).toBeInTheDocument();
  });

  it('shows why a song could not be added and refreshes the queue', async () => {
    const fetchMock = openJoinedParty({
      [`GET ${partyPath}/queue`]: queue(),
      [`GET ${partyPath}/search`]: { status: 200, body: [wave] },
      [`POST ${partyPath}/queue`]: error(409, 'already_queued', 'Essa música já está na fila.'),
    });

    await search('wave');
    await userEvent.click(await screen.findByRole('button', { name: 'Adicionar Wave' }));

    expect(await screen.findByRole('alert')).toHaveTextContent('Essa música já está na fila.');
    const queueLoads = fetchMock.mock.calls.filter(
      ([url, init]) => url.endsWith('/queue') && !init?.method,
    );
    expect(queueLoads).toHaveLength(2);
  });

  it('says when nothing was found', async () => {
    openJoinedParty({
      [`GET ${partyPath}/queue`]: queue(),
      [`GET ${partyPath}/search`]: { status: 200, body: [] },
    });

    await search('zzzz');

    expect(await screen.findByText('Nenhuma música encontrada.')).toBeInTheDocument();
  });

  it('updates the queue by itself when the party says it changed', async () => {
    openJoinedParty({
      [`GET ${partyPath}/queue`]: [queue(), queue([queueItem(wave, '11')])],
    });
    await screen.findByText(/A fila está vazia/);

    emitPartyEvent('queue_changed');

    expect(await screen.findByRole('list', { name: 'Próximas músicas' })).toHaveTextContent('Wave');
  });

  it('follows the live stream of this party, without sending the token', async () => {
    openJoinedParty({ [`GET ${partyPath}/queue`]: queue() });
    await screen.findByText(/A fila está vazia/);

    expect(openStreams().map((source) => source.url)).toEqual([
      `http://127.0.0.1:3000${partyPath}/events`,
    ]);
  });

  it('tells the guest right away when the host ends the party', async () => {
    openJoinedParty({ [`GET ${partyPath}/queue`]: queue() });
    await screen.findByText(/A fila está vazia/);

    emitPartyEvent('party_ended');

    expect(await screen.findByRole('alert')).toHaveTextContent('Essa party já terminou.');
    expect(openStreams()).toEqual([]);
  });

  it('asks the guest to join again when their token stops working', async () => {
    openJoinedParty({ [`GET ${partyPath}/queue`]: error(401, 'unauthorized') });

    expect(await screen.findByRole('button', { name: 'Entrar na party' })).toBeInTheDocument();
    expect(getParticipantToken(partyId)).toBeNull();
  });

  it('says when the party ends', async () => {
    openJoinedParty({
      [`GET ${partyPath}/queue`]: queue(),
      [`GET ${partyPath}/search`]: error(410, 'party_ended'),
    });

    await search('wave');

    expect(await screen.findByRole('alert')).toHaveTextContent('Essa party já terminou.');
  });

  it('shows the song that is playing, without host buttons for a guest', async () => {
    openJoinedParty({
      [`GET ${partyPath}/queue`]: queue([queueItem(wave, '11')], {
        nowPlaying: { ...queueItem(ipanema, '10'), status: 'playing' },
        playbackState: 'playing',
      }),
    });

    expect(await screen.findByText('Garota de Ipanema')).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Pular' })).not.toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /Remover/ })).not.toBeInTheDocument();
  });

  it('tells guests when the host paused the jukebox', async () => {
    openJoinedParty({
      [`GET ${partyPath}/queue`]: queue([queueItem(wave, '11')], { playbackState: 'paused' }),
    });

    expect(await screen.findByText('A fila está pausada pelo host.')).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Tocar' })).not.toBeInTheDocument();
  });

  it("shows the host's own song from Spotify as playing", async () => {
    openJoinedParty({
      [`GET ${partyPath}/queue`]: queue([queueItem(wave, '11')], {
        playbackState: 'external',
        externalTrack: { ...ipanema, title: 'Have a Nice Day', artist: 'Stereophonics' },
      }),
    });

    expect(await screen.findByText('Have a Nice Day')).toBeInTheDocument();
    expect(screen.getByText('Spotify do host')).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Voltar para a fila' })).not.toBeInTheDocument();
  });

  it('just says nothing is playing when Spotify stopped and the queue is empty', async () => {
    openJoinedParty({ [`GET ${partyPath}/queue`]: queue([], { playbackState: 'paused' }) });

    expect(await screen.findByText('Nada tocando agora.')).toBeInTheDocument();
  });
});
