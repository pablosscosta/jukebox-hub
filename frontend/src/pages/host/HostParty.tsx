import { useEffect, useEffectEvent, useState } from 'react';
import { ApiError, getMyParticipant, type Party } from '../../api/client';
import { Jukebox } from '../party/Jukebox';
import { EndPartyButton } from './EndPartyButton';
import { InviteCard } from './InviteCard';

type Props = {
  party: Party;
  token: string;
  onEnded: () => void;
  onUnauthorized: () => void;
};

// The running party seen by the host: what plays, search and queue like any guest (plus the host's
// buttons), then the invite and, last and apart, ending the party. The host is a participant of
// their own party; the API finds it from the host token.
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
      <div className="party-header">
        <div>
          <h2>{party.name}</h2>
          <p>Tocando em {party.deviceName}</p>
        </div>
        <a className="button button-small" href="#convite">
          Convidar
        </a>
      </div>
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
      <InviteCard party={party} />
      <footer className="page-footer">
        <p className="hint">A party encerra sozinha depois de 6 h sem música.</p>
        <EndPartyButton
          partyId={party.id}
          token={token}
          onEnded={onEnded}
          onUnauthorized={onUnauthorized}
        />
      </footer>
    </>
  );
}
