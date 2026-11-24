import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { getHostToken, saveHostToken } from '../auth/hostToken';
import { mockFetch, renderAt } from '../test/utils';

describe('HostPage', () => {
  it('greets the host by name', async () => {
    saveHostToken('host-token');
    const fetchMock = mockFetch({ status: 200, body: { id: '1', displayName: 'Pablo' } });

    renderAt('/host');

    expect(await screen.findByRole('heading', { name: 'Olá, Pablo!' })).toBeInTheDocument();
    const [, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(new Headers(init.headers).get('Authorization')).toBe('Bearer host-token');
  });

  it('sends a visitor without login back to the home page', () => {
    renderAt('/host');

    expect(screen.getByRole('link', { name: 'Entrar com Spotify' })).toBeInTheDocument();
  });

  it('forgets an expired token and goes back to the home page', async () => {
    saveHostToken('expired-token');
    mockFetch({ status: 401, body: { error: { code: 'unauthorized', message: 'x' } } });

    renderAt('/host');

    expect(await screen.findByRole('link', { name: 'Entrar com Spotify' })).toBeInTheDocument();
    expect(getHostToken()).toBeNull();
  });

  it('logs out', async () => {
    saveHostToken('host-token');
    const fetchMock = mockFetch(
      { status: 200, body: { id: '1', displayName: 'Pablo' } },
      { status: 204 },
    );
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
    saveHostToken('host-token');
    mockFetch({ status: 500 });

    renderAt('/host');

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'Não conseguimos carregar seus dados',
    );
  });
});
