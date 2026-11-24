import { useState } from 'react';
import { ApiError, joinParty, type Participant } from '../../api/client';
import { saveParticipantToken } from '../../auth/participantToken';

const NAME_MAX_LENGTH = 40;

type Props = {
  partyId: string;
  onJoined: (participant: Participant) => void;
  onEnded: () => void;
};

// The guest's name is optional: without one the API calls them "Convidado N".
export function JoinPartyForm({ partyId, onJoined, onEnded }: Props) {
  const [name, setName] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit() {
    setSubmitting(true);
    setError(null);
    try {
      const { participantToken, participant } = await joinParty(partyId, name.trim());
      saveParticipantToken(partyId, participantToken);
      onJoined(participant);
    } catch (err) {
      if (err instanceof ApiError && err.status === 410) {
        onEnded();
        return;
      }
      setError(err instanceof ApiError ? err.message : 'Algo deu errado. Tente de novo.');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form
      onSubmit={(event) => {
        event.preventDefault();
        void handleSubmit();
      }}
    >
      {error && <p role="alert">{error}</p>}
      <label>
        Seu nome (opcional)
        <input
          value={name}
          onChange={(event) => {
            setName(event.target.value);
          }}
          maxLength={NAME_MAX_LENGTH}
          autoComplete="nickname"
        />
      </label>
      <button type="submit" className="button" disabled={submitting}>
        {submitting ? 'Entrando...' : 'Entrar na party'}
      </button>
    </form>
  );
}
