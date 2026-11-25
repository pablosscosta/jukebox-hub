import { useState } from 'react';
import { ApiError, endParty } from '../../api/client';

type Props = {
  partyId: string;
  token: string;
  onEnded: () => void;
  onUnauthorized: () => void;
};

// Ends the party for everyone: the music stops and the guests' screens say it's over. Asks first,
// on the page itself: native confirm() dialogs are blocked by some embedded and in-app browsers.
export function EndPartyButton({ partyId, token, onEnded, onUnauthorized }: Props) {
  const [confirming, setConfirming] = useState(false);
  const [ending, setEnding] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleEnd() {
    setEnding(true);
    setError(null);
    try {
      await endParty(partyId, token);
      onEnded();
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) onUnauthorized();
      else setError('Não conseguimos encerrar a party. Tente de novo.');
      setEnding(false);
    }
  }

  if (!confirming) {
    return (
      <button
        type="button"
        onClick={() => {
          setConfirming(true);
        }}
      >
        Encerrar party
      </button>
    );
  }

  return (
    <div role="group" aria-label="Confirmar encerramento">
      {error && <p role="alert">{error}</p>}
      <p>Encerrar a party? A música para e os convidados não podem mais adicionar.</p>
      <button type="button" onClick={() => void handleEnd()} disabled={ending}>
        {ending ? 'Encerrando...' : 'Sim, encerrar'}
      </button>{' '}
      <button
        type="button"
        onClick={() => {
          setConfirming(false);
        }}
        disabled={ending}
      >
        Cancelar
      </button>
    </div>
  );
}
