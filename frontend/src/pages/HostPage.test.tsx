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
const notebook = { id: 'note', name: 'pablo-note', type: 'Computer', isActive: true };
const phone = { id: 'phone', name: 'iPhone', type: 'Smartphone', isActive: false };

function lastBody(fetchMock: ReturnType<typeof mockApi>) {
  const [, init] = fetchMock.mock.lastCall as [string, RequestInit];
  return JSON.parse(init.body as string) as unknown;
}

describe('HostPage', () => {
  beforeEach(() => {
    saveHostToken('host-token');
  });

  it('greets the host by name', async () => {
    const fetchMock = mockApi({
      'GET /me': { status: 200, body: host },
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
      'GET /me/party': { status: 200, body: party },
      'DELETE /auth/token': { status: 204 },
    });
    renderAt('/host');

    await userEvent.click(await screen.findByRole('button', { name: 'Sair' }));

    expect(await screen.findByRole('link', { name: 'Entrar com Spotify' })).toBeInTheDocument();
    expect(getHostToken()).toBeNull();
    expect(fetchMock).toHaveBeenLastCalledWith(
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
        'GET /me/party': { status: 200, body: party },
      });

      renderAt('/host');

      expect(await screen.findByRole('heading', { name: 'Churrasco' })).toBeInTheDocument();
      expect(screen.getByText(/Tocando em pablo-note/)).toBeInTheDocument();
      expect(screen.getByLabelText('Link de convite')).toHaveValue(party.shareUrl);
      expect(screen.queryByRole('button', { name: 'Criar party' })).not.toBeInTheDocument();
    });

    it('shows a QR code that guests can scan', async () => {
      mockApi({
        'GET /me': { status: 200, body: host },
        'GET /me/party': { status: 200, body: party },
      });

      renderAt('/host');

      expect(await screen.findByRole('img', { name: 'QR code do convite' })).toBeInTheDocument();
    });

    it('copies the invite link', async () => {
      mockApi({
        'GET /me': { status: 200, body: host },
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
        'GET /me/party': noParty,
        'GET /me/devices': { status: 200, body: [phone, notebook] },
        'POST /parties': { status: 201, body: party },
      });
      renderAt('/host');

      expect(await screen.findByRole('radio', { name: /pablo-note/ })).toBeChecked();
      await userEvent.type(screen.getByLabelText('Nome da party'), ' Churrasco ');
      await userEvent.click(screen.getByRole('button', { name: 'Criar party' }));

      expect(await screen.findByLabelText('Link de convite')).toHaveValue(party.shareUrl);
      expect(lastBody(fetchMock)).toEqual({ name: 'Churrasco', deviceId: 'note' });
    });

    it('uses the device the host picks', async () => {
      const fetchMock = mockApi({
        'GET /me': { status: 200, body: host },
        'GET /me/party': noParty,
        'GET /me/devices': { status: 200, body: [phone, notebook] },
        'POST /parties': { status: 201, body: party },
      });
      renderAt('/host');

      await userEvent.click(await screen.findByRole('radio', { name: /iPhone/ }));
      await userEvent.type(screen.getByLabelText('Nome da party'), 'Churrasco');
      await userEvent.click(screen.getByRole('button', { name: 'Criar party' }));

      await screen.findByLabelText('Link de convite');
      expect(lastBody(fetchMock)).toEqual({ name: 'Churrasco', deviceId: 'phone' });
    });

    it('shows the party that already exists when the API answers 409', async () => {
      mockApi({
        'GET /me': { status: 200, body: host },
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
