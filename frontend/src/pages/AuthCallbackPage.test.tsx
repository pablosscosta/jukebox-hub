import { screen } from '@testing-library/react';
import { getHostToken } from '../auth/hostToken';
import { mockApi, renderAt } from '../test/utils';

describe('AuthCallbackPage', () => {
  it('trades the login code for a token and opens the host page', async () => {
    const host = { id: '1', displayName: 'Pablo', premium: true };
    const fetchMock = mockApi({
      'POST /auth/token': { status: 201, body: { token: 'host-token', host } },
      'GET /me': { status: 200, body: host },
      'GET /me/party': {
        status: 200,
        body: {
          id: 'p1',
          name: 'Churrasco',
          status: 'active',
          deviceName: 'note',
          shareUrl: 'x',
          expiresAt: '2026-11-24T23:00:00Z',
          createdAt: '2026-11-24T17:00:00Z',
        },
      },
    });

    renderAt('/auth/callback?code=one-time-code');

    expect(await screen.findByRole('heading', { name: 'Olá, Pablo!' })).toBeInTheDocument();
    expect(getHostToken()).toBe('host-token');
    expect(fetchMock).toHaveBeenCalledWith(
      'http://127.0.0.1:3000/auth/token',
      expect.objectContaining({ method: 'POST', body: JSON.stringify({ code: 'one-time-code' }) }),
    );
  });

  it('explains when the host cancelled the login on Spotify', () => {
    renderAt('/auth/callback?error=access_denied');

    expect(screen.getByRole('alert')).toHaveTextContent('Você cancelou o login no Spotify.');
    expect(screen.getByRole('link', { name: 'Voltar para o início' })).toHaveAttribute('href', '/');
  });

  it('shows a generic message for an unknown error', () => {
    renderAt('/auth/callback?error=something_new');

    expect(screen.getByRole('alert')).toHaveTextContent('Algo deu errado no login');
  });

  it('shows an error when the code is rejected', async () => {
    mockApi({
      'POST /auth/token': {
        status: 401,
        body: { error: { code: 'invalid_login_code', message: 'x' } },
      },
    });

    renderAt('/auth/callback?code=expired');

    expect(await screen.findByRole('alert')).toHaveTextContent('Algo deu errado no login');
    expect(getHostToken()).toBeNull();
  });

  it('shows an error when there is no code at all', () => {
    renderAt('/auth/callback');

    expect(screen.getByRole('alert')).toBeInTheDocument();
  });
});
