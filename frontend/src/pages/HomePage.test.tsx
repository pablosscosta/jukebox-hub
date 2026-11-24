import { screen } from '@testing-library/react';
import { saveHostToken } from '../auth/hostToken';
import { mockApi, renderAt } from '../test/utils';

describe('HomePage', () => {
  it('invites the visitor to log in with Spotify', () => {
    renderAt('/');

    expect(screen.getByRole('heading', { name: 'Jukebox Hub' })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'Entrar com Spotify' })).toHaveAttribute(
      'href',
      'http://127.0.0.1:3000/auth/spotify',
    );
  });

  it('sends a logged-in host straight to their page', async () => {
    saveHostToken('host-token');
    mockApi({
      'GET /me': { status: 200, body: { id: '1', displayName: 'Pablo', premium: true } },
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

    renderAt('/');

    expect(await screen.findByRole('heading', { name: 'Olá, Pablo!' })).toBeInTheDocument();
  });
});
