import { useEffect, useState } from 'react';
import { useParams } from 'react-router';
import {
  ApiError,
  getMyParticipant,
  getParty,
  type Participant,
  type PublicParty,
} from '../api/client';
import { clearParticipantToken, getParticipantToken } from '../auth/participantToken';
import { JoinPartyForm } from './guest/JoinPartyForm';

type View =
  | { kind: 'loading' }
  | { kind: 'notFound' }
  | { kind: 'failed' }
  | { kind: 'ended'; party?: PublicParty }
  | { kind: 'join'; party: PublicParty }
  | { kind: 'joined'; party: PublicParty; participant: Participant };

// The page guests open from the invite link or QR code. No login: joining gives them a token.
export function GuestPage() {
  const { partyId = '' } = useParams();
  const [view, setView] = useState<View>({ kind: 'loading' });

  useEffect(() => {
    loadView(partyId).then(setView, () => {
      setView({ kind: 'failed' });
    });
  }, [partyId]);

  return <main>{renderView(view, partyId, setView)}</main>;
}

function renderView(view: View, partyId: string, setView: (view: View) => void) {
  switch (view.kind) {
    case 'loading':
      return <p>Carregando a party...</p>;
    case 'notFound':
      return <p role="alert">Não encontramos essa party. Confira o link com quem te convidou.</p>;
    case 'failed':
      return <p role="alert">Não conseguimos carregar a party. Tente recarregar a página.</p>;
    case 'ended':
      return (
        <>
          {view.party && <h1>{view.party.name}</h1>}
          <p role="alert">Essa party já terminou.</p>
        </>
      );
    case 'join':
      return (
        <>
          <PartyHeader party={view.party} />
          <JoinPartyForm
            partyId={partyId}
            onJoined={(participant) => {
              setView({ kind: 'joined', party: view.party, participant });
            }}
            onEnded={() => {
              setView({ kind: 'ended', party: view.party });
            }}
          />
        </>
      );
    case 'joined':
      return (
        <>
          <PartyHeader party={view.party} />
          <p>Você entrou como {view.participant.displayName}.</p>
          <p className="hint">A fila e a busca de músicas chegam na próxima etapa.</p>
        </>
      );
  }
}

function PartyHeader({ party }: { party: PublicParty }) {
  return (
    <>
      <h1>{party.name}</h1>
      <p>Party de {party.hostName}</p>
    </>
  );
}

// Decides what to show: a guest who already joined on this phone goes straight in.
async function loadView(partyId: string): Promise<View> {
  let party: PublicParty;
  try {
    party = await getParty(partyId);
  } catch (err) {
    if (err instanceof ApiError && err.status === 404) return { kind: 'notFound' };
    throw err;
  }
  if (party.status === 'ended') return { kind: 'ended', party };

  const token = getParticipantToken(partyId);
  if (!token) return { kind: 'join', party };

  try {
    return { kind: 'joined', party, participant: await getMyParticipant(partyId, token) };
  } catch (err) {
    if (err instanceof ApiError && err.status === 410) return { kind: 'ended', party };
    if (err instanceof ApiError && err.status === 401) {
      // The saved token is no good anymore: forget it and let the guest join again.
      clearParticipantToken(partyId);
      return { kind: 'join', party };
    }
    throw err;
  }
}
