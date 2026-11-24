import { screen } from '@testing-library/react';
import { saveHostToken } from '../auth/hostToken';
import { mockFetch, renderAt } from '../test/utils';

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
    mockFetch({ status: 200, body: { id: '1', displayName: 'Pablo' } });

    renderAt('/');

    expect(await screen.findByRole('heading', { name: 'Olá, Pablo!' })).toBeInTheDocument();
  });
});
