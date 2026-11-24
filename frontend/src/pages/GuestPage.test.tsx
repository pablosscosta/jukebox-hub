import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { getParticipantToken, saveParticipantToken } from '../auth/participantToken';
import { mockApi, renderAt } from '../test/utils';

const partyId = '3f9c0000-0000-0000-0000-000000000001';
const partyPath = `/parties/${partyId}`;
const party = {
  id: partyId,
  name: 'Churrasco',
  status: 'active',
  hostName: 'Pablo',
  expiresAt: '2026-11-24T23:00:00Z',
};
const ana = { id: '1', displayName: 'Ana', joinedAt: '2026-11-24T18:00:00Z' };
const error = (status: number, code: string) => ({
  status,
  body: { error: { code, message: 'x' } },
});

function lastBody(fetchMock: ReturnType<typeof mockApi>) {
  const [, init] = fetchMock.mock.lastCall as [string, RequestInit];
  return JSON.parse(init.body as string) as unknown;
}

describe('GuestPage', () => {
  it('shows the party and lets the guest join with a name', async () => {
    const fetchMock = mockApi({
      [`GET ${partyPath}`]: { status: 200, body: party },
      [`POST ${partyPath}/participants`]: {
        status: 201,
        body: { participantToken: 'guest-token', participant: ana },
      },
    });
    renderAt(`/p/${partyId}`);

    expect(await screen.findByRole('heading', { name: 'Churrasco' })).toBeInTheDocument();
    expect(screen.getByText('Party de Pablo')).toBeInTheDocument();
    await userEvent.type(screen.getByLabelText('Seu nome (opcional)'), ' Ana ');
    await userEvent.click(screen.getByRole('button', { name: 'Entrar na party' }));

    expect(await screen.findByText('Você entrou como Ana.')).toBeInTheDocument();
    expect(lastBody(fetchMock)).toEqual({ displayName: 'Ana' });
    expect(getParticipantToken(partyId)).toBe('guest-token');
  });

  it('lets the guest join without a name', async () => {
    const fetchMock = mockApi({
      [`GET ${partyPath}`]: { status: 200, body: party },
      [`POST ${partyPath}/participants`]: {
        status: 201,
        body: {
          participantToken: 'guest-token',
          participant: { ...ana, displayName: 'Convidado 3' },
        },
      },
    });
    renderAt(`/p/${partyId}`);

    await userEvent.click(await screen.findByRole('button', { name: 'Entrar na party' }));

    expect(await screen.findByText('Você entrou como Convidado 3.')).toBeInTheDocument();
    expect(lastBody(fetchMock)).toEqual({ displayName: '' });
  });

  it('keeps a guest who already joined on this phone', async () => {
    saveParticipantToken(partyId, 'guest-token');
    const fetchMock = mockApi({
      [`GET ${partyPath}`]: { status: 200, body: party },
      [`GET ${partyPath}/participants/me`]: { status: 200, body: ana },
    });

    renderAt(`/p/${partyId}`);

    expect(await screen.findByText('Você entrou como Ana.')).toBeInTheDocument();
    const [, init] = fetchMock.mock.lastCall as [string, RequestInit];
    expect(new Headers(init.headers).get('Authorization')).toBe('Bearer guest-token');
  });

  it('forgets a token that no longer works and asks the guest to join again', async () => {
    saveParticipantToken(partyId, 'old-token');
    mockApi({
      [`GET ${partyPath}`]: { status: 200, body: party },
      [`GET ${partyPath}/participants/me`]: error(401, 'unauthorized'),
    });

    renderAt(`/p/${partyId}`);

    expect(await screen.findByRole('button', { name: 'Entrar na party' })).toBeInTheDocument();
    expect(getParticipantToken(partyId)).toBeNull();
  });

  it('says when the party is over', async () => {
    mockApi({ [`GET ${partyPath}`]: { status: 200, body: { ...party, status: 'ended' } } });

    renderAt(`/p/${partyId}`);

    expect(await screen.findByRole('alert')).toHaveTextContent('Essa party já terminou.');
    expect(screen.queryByRole('button', { name: 'Entrar na party' })).not.toBeInTheDocument();
  });

  it('says when the party ends while the guest is joining', async () => {
    mockApi({
      [`GET ${partyPath}`]: { status: 200, body: party },
      [`POST ${partyPath}/participants`]: error(410, 'party_ended'),
    });
    renderAt(`/p/${partyId}`);

    await userEvent.click(await screen.findByRole('button', { name: 'Entrar na party' }));

    expect(await screen.findByRole('alert')).toHaveTextContent('Essa party já terminou.');
  });

  it('explains a broken link', async () => {
    mockApi({ [`GET ${partyPath}`]: error(404, 'party_not_found') });

    renderAt(`/p/${partyId}`);

    expect(await screen.findByRole('alert')).toHaveTextContent('Não encontramos essa party');
  });

  it('shows a message when the API is down', async () => {
    mockApi({ [`GET ${partyPath}`]: { status: 500 } });

    renderAt(`/p/${partyId}`);

    expect(await screen.findByRole('alert')).toHaveTextContent('Não conseguimos carregar a party');
  });
});
