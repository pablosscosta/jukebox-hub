import { useEffect, useRef, useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router';
import { exchangeLoginCode } from '../api/client';
import { saveHostToken } from '../auth/hostToken';
import { Loading } from '../components/Loading';

// Error codes sent by the backend in ?error=... after the Spotify login.
const ERROR_MESSAGES: Record<string, string> = {
  access_denied: 'Você cancelou o login no Spotify.',
  invalid_state: 'O login expirou ou foi iniciado em outra aba. Tente de novo.',
  login_failed: 'Não conseguimos falar com o Spotify. Tente de novo.',
  spotify_not_configured: 'O login com Spotify ainda não está configurado no servidor.',
  not_allowed:
    'Sua conta Spotify ainda não foi liberada para criar parties nesta versão de demonstração.',
};

// Who to ask for access (set at build time). Optional: without it the page just says to ask
// whoever sent the link.
const CONTACT_EMAIL: string | undefined = import.meta.env.VITE_CONTACT_EMAIL;
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
          {errorCode === 'not_allowed' && <AskForAccess />}
          <Link to="/">Voltar para o início</Link>
        </>
      ) : (
        <Loading text="Entrando..." />
      )}
    </main>
  );
}

function AskForAccess() {
  return CONTACT_EMAIL ? (
    <p className="hint">
      Para pedir acesso, escreva para <a href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a>{' '}
      informando o e-mail da sua conta Spotify.
    </p>
  ) : (
    <p className="hint">Para pedir acesso, fale com quem te enviou o link.</p>
  );
}
