import { useEffect, useEffectEvent, useState } from 'react';
import { ApiError, getMyParticipant, type Party } from '../../api/client';
import { Jukebox } from '../party/Jukebox';
import { PartyCard } from './PartyCard';

type Props = {
  party: Party;
  token: string;
  onEnded: () => void;
  onUnauthorized: () => void;
};

// The running party seen by the host: the invite, plus search and queue like any guest. The host
// is a participant of their own party; the API finds it from the host token.
export function HostParty({ party, token, onEnded, onUnauthorized }: Props) {
  const [participantId, setParticipantId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const onLoadFailed = useEffectEvent((err: unknown) => {
    if (err instanceof ApiError && err.status === 401) onUnauthorized();
    else if (err instanceof ApiError && err.status === 410) onEnded();
    else setError('Não conseguimos carregar a fila. Tente recarregar a página.');
  });

  useEffect(() => {
    getMyParticipant(party.id, token).then((participant) => {
      setParticipantId(participant.id);
    }, onLoadFailed);
  }, [party.id, token]);

  return (
    <>
      <PartyCard party={party} />
      {error && <p role="alert">{error}</p>}
      {participantId && (
        <Jukebox
          partyId={party.id}
          token={token}
          participantId={participantId}
          isHost
          onUnauthorized={onUnauthorized}
          onEnded={onEnded}
        />
      )}
    </>
  );
}
