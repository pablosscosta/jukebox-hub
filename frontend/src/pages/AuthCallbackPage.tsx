import { useEffect, useRef, useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router';
import { exchangeLoginCode } from '../api/client';
import { saveHostToken } from '../auth/hostToken';

// Error codes sent by the backend in ?error=... after the Spotify login.
const ERROR_MESSAGES: Record<string, string> = {
  access_denied: 'Você cancelou o login no Spotify.',
  invalid_state: 'O login expirou ou foi iniciado em outra aba. Tente de novo.',
  login_failed: 'Não conseguimos falar com o Spotify. Tente de novo.',
  spotify_not_configured: 'O login com Spotify ainda não está configurado no servidor.',
};
const GENERIC_ERROR = 'Algo deu errado no login. Tente de novo.';

// The backend sends the host here with a one-time ?code=... that we trade for the access token.
export function AuthCallbackPage() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const code = params.get('code');
  const errorCode = params.get('error');
  const [error, setError] = useState<string | null>(
    errorCode ? (ERROR_MESSAGES[errorCode] ?? GENERIC_ERROR) : code ? null : GENERIC_ERROR,
  );
  // The code works only once, and StrictMode runs effects twice in dev.
  const exchanged = useRef(false);

  useEffect(() => {
    if (!code || errorCode || exchanged.current) return;
    exchanged.current = true;

    exchangeLoginCode(code)
      .then(({ token }) => {
        saveHostToken(token);
        return navigate('/host', { replace: true });
      })
      .catch(() => {
        setError(GENERIC_ERROR);
      });
  }, [code, errorCode, navigate]);

  return (
    <main className="hero">
      {error ? (
        <>
          <h1>Não foi possível entrar</h1>
          <p role="alert">{error}</p>
          <Link to="/">Voltar para o início</Link>
        </>
      ) : (
        <p className="hint">Entrando...</p>
      )}
    </main>
  );
}
