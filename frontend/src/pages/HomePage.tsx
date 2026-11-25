import { Navigate } from 'react-router';
import { spotifyLoginUrl } from '../api/client';
import { getHostToken } from '../auth/hostToken';

export function HomePage() {
  if (getHostToken()) return <Navigate to="/host" replace />;

  return (
    <main className="hero">
      <h1>Jukebox Hub</h1>
      <p>Crie uma festa e deixe seus convidados escolherem a próxima música.</p>
      <a className="button button-primary" href={spotifyLoginUrl}>
        Entrar com Spotify
      </a>
      <p className="hint" style={{ marginTop: 'var(--space-6)' }}>
        Quem cria a party precisa de Spotify Premium. Os convidados entram pelo link, sem conta.
      </p>
    </main>
  );
}
