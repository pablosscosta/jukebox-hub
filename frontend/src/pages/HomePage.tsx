import { Navigate } from 'react-router';
import { spotifyLoginUrl } from '../api/client';
import { getHostToken } from '../auth/hostToken';

export function HomePage() {
  if (getHostToken()) return <Navigate to="/host" replace />;

  return (
    <main>
      <h1>Jukebox Hub</h1>
      <p>Crie uma festa e deixe seus convidados escolherem a próxima música.</p>
      <a className="button" href={spotifyLoginUrl}>
        Entrar com Spotify
      </a>
    </main>
  );
}
