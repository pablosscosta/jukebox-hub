import { useEffect, useState } from 'react';
import { Navigate, useNavigate } from 'react-router';
import { ApiError, getMe, logout, type Host } from '../api/client';
import { clearHostToken, getHostToken } from '../auth/hostToken';

// The host's area. For now it only says hello; creating a party comes next.
export function HostPage() {
  const navigate = useNavigate();
  const [token] = useState(getHostToken);
  const [host, setHost] = useState<Host | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!token) return;

    getMe(token)
      .then(setHost)
      .catch((err: unknown) => {
        if (err instanceof ApiError && err.status === 401) {
          clearHostToken();
          void navigate('/', { replace: true });
        } else {
          setError('Não conseguimos carregar seus dados. Tente recarregar a página.');
        }
      });
  }, [token, navigate]);

  async function handleLogout() {
    if (token) {
      // Even if the request fails, the token is forgotten here and expires on its own.
      await logout(token).catch(() => undefined);
    }
    clearHostToken();
    await navigate('/', { replace: true });
  }

  if (!token) return <Navigate to="/" replace />;

  return (
    <main>
      {error && <p role="alert">{error}</p>}
      {host ? <h1>Olá, {host.displayName}!</h1> : !error && <p>Carregando...</p>}
      <button type="button" onClick={() => void handleLogout()}>
        Sair
      </button>
    </main>
  );
}
