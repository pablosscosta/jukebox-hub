import { useCallback, useEffect, useState } from 'react';
import { Navigate, useNavigate } from 'react-router';
import { ApiError, getCurrentParty, getMe, logout, type Host, type Party } from '../api/client';
import { clearHostToken, getHostToken } from '../auth/hostToken';
import { CreatePartyForm } from './host/CreatePartyForm';
import { HostParty } from './host/HostParty';

// The host's area: shows the running party or lets the host start one.
export function HostPage() {
  const navigate = useNavigate();
  const [token] = useState(getHostToken);
  const [host, setHost] = useState<Host | null>(null);
  const [party, setParty] = useState<Party | null>(null);
  const [error, setError] = useState<string | null>(null);

  const goHome = useCallback(() => {
    clearHostToken();
    void navigate('/', { replace: true });
  }, [navigate]);

  useEffect(() => {
    if (!token) return;

    Promise.all([getMe(token), getCurrentParty(token)])
      .then(([me, current]) => {
        setParty(current);
        setHost(me);
      })
      .catch((err: unknown) => {
        if (err instanceof ApiError && err.status === 401) goHome();
        else setError('Não conseguimos carregar seus dados. Tente recarregar a página.');
      });
  }, [token, goHome]);

  async function handleLogout() {
    if (token) {
      // Even if the request fails, the token is forgotten here and expires on its own.
      await logout(token).catch(() => undefined);
    }
    goHome();
  }

  if (!token) return <Navigate to="/" replace />;

  return (
    <main>
      {error && <p role="alert">{error}</p>}
      {host ? (
        <>
          <h1>Olá, {host.displayName}!</h1>
          <HostContent
            host={host}
            party={party}
            token={token}
            onCreated={setParty}
            onEnded={() => {
              setParty(null);
            }}
            onUnauthorized={goHome}
          />
        </>
      ) : (
        !error && <p>Carregando...</p>
      )}
      <button type="button" className="link" onClick={() => void handleLogout()}>
        Sair
      </button>
    </main>
  );
}

type HostContentProps = {
  host: Host;
  party: Party | null;
  token: string;
  onCreated: (party: Party) => void;
  onEnded: () => void;
  onUnauthorized: () => void;
};

function HostContent({ host, party, token, onCreated, onEnded, onUnauthorized }: HostContentProps) {
  if (party) {
    return (
      <HostParty party={party} token={token} onEnded={onEnded} onUnauthorized={onUnauthorized} />
    );
  }

  if (!host.premium) {
    return <p role="alert">Para tocar músicas pela Jukebox Hub você precisa do Spotify Premium.</p>;
  }

  return <CreatePartyForm token={token} onCreated={onCreated} onUnauthorized={onUnauthorized} />;
}
