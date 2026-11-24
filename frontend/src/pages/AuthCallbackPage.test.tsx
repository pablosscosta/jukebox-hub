import { screen } from '@testing-library/react';
import { getHostToken } from '../auth/hostToken';
import { mockFetch, renderAt } from '../test/utils';

describe('AuthCallbackPage', () => {
  it('trades the login code for a token and opens the host page', async () => {
    const fetchMock = mockFetch(
      { status: 201, body: { token: 'host-token', host: { id: '1', displayName: 'Pablo' } } },
      { status: 200, body: { id: '1', displayName: 'Pablo' } },
    );

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
    mockFetch({ status: 401, body: { error: { code: 'invalid_login_code', message: 'x' } } });

    renderAt('/auth/callback?code=expired');

    expect(await screen.findByRole('alert')).toHaveTextContent('Algo deu errado no login');
    expect(getHostToken()).toBeNull();
  });

  it('shows an error when there is no code at all', () => {
    renderAt('/auth/callback');

    expect(screen.getByRole('alert')).toBeInTheDocument();
  });
});
