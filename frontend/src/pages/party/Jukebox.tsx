import { useEffect, useEffectEvent, useMemo, useState } from 'react';
import {
  ApiError,
  getQueue,
  removeFromQueue,
  skipTrack,
  startPlayback,
  type Queue,
  type QueueItem,
} from '../../api/client';
import type { HostControls } from './hostControls';
import { NowPlaying } from './NowPlaying';
import { TrackSearch } from './TrackSearch';
import { UpNext } from './UpNext';
import { usePartyEvents } from './usePartyEvents';
import { Loading } from '../../components/Loading';

type Props = {
  partyId: string;
  // The guest's participant token, or the host's own token.
  token: string;
  participantId: string;
  // The host sees the same jukebox plus the buttons to skip, start and remove songs.
  isHost?: boolean;
  onUnauthorized: () => void;
  onEnded: () => void;
};

// Search and queue, the same for guests and the host. The queue follows the party live: it reloads
// whenever the API says something changed (usePartyEvents).
export function Jukebox({
  partyId,
  token,
  participantId,
  isHost = false,
  onUnauthorized,
  onEnded,
}: Props) {
  const [queue, setQueue] = useState<Queue | null>(null);
  const [error, setError] = useState<string | null>(null);
  // Kept apart from the loading error: reloading the queue after a failed action must not hide why it failed.
  const [actionError, setActionError] = useState<string | null>(null);
  // Bumping it reloads the queue (after a notice from the party, or after adding a song).
  const [reloadKey, setReloadKey] = useState(0);
  const [hostBusy, setHostBusy] = useState(false);

  // Returns true when the error ends the visit and the page takes over.
  function handleFatalError(err: unknown) {
    if (!(err instanceof ApiError)) return false;
    if (err.status === 401) onUnauthorized();
    else if (err.status === 410) onEnded();
    else return false;
    return true;
  }

  // An effect event always sees the latest props, so the effect below doesn't run again just
  // because the page passed new callbacks.
  const onLoadFailed = useEffectEvent((err: unknown) => {
    if (!handleFatalError(err))
      setError('Não conseguimos carregar a fila. Tente recarregar a página.');
  });

  useEffect(() => {
    let current = true;
    getQueue(partyId, token).then(
      (loaded) => {
        if (!current) return;
        setQueue(loaded);
        setError(null);
      },
      (err: unknown) => {
        if (current) onLoadFailed(err);
      },
    );
    // A newer load replaces this one: an older answer arriving late is ignored.
    return () => {
      current = false;
    };
  }, [partyId, token, reloadKey]);

  function reload() {
    setReloadKey((key) => key + 1);
  }

  usePartyEvents(partyId, { onChange: reload, onEnded });

  async function runHostAction(action: () => Promise<unknown>) {
    setHostBusy(true);
    setActionError(null);
    try {
      await action();
    } catch (err) {
      if (!handleFatalError(err)) {
        setActionError(err instanceof ApiError ? err.message : 'Algo deu errado. Tente de novo.');
      }
    } finally {
      setHostBusy(false);
      reload();
    }
  }

  const hostControls: HostControls | undefined = isHost
    ? {
        busy: hostBusy,
        onSkip: () => void runHostAction(() => skipTrack(partyId, token)),
        onStart: () => void runHostAction(() => startPlayback(partyId, token)),
        onRemove: (item: QueueItem) =>
          void runHostAction(() => removeFromQueue(partyId, item.id, token)),
      }
    : undefined;

  const queuedTrackIds = useMemo(
    () =>
      new Set(
        [queue?.nowPlaying, ...(queue?.upNext ?? [])].flatMap((item) =>
          item ? [item.trackId] : [],
        ),
      ),
    [queue],
  );
  const myPending = queue?.upNext.filter((item) => item.addedBy.id === participantId).length ?? 0;
  const limitReached = queue !== null && myPending >= queue.maxPendingPerParticipant;

  // Order on screen: what plays now, then the search (the main action), then what comes next.
  return (
    <>
      {error && <p role="alert">{error}</p>}
      {actionError && <p role="alert">{actionError}</p>}
      {queue ? (
        <NowPlaying queue={queue} participantId={participantId} hostControls={hostControls} />
      ) : (
        !error && <Loading text="Carregando a fila..." />
      )}

      <TrackSearch
        partyId={partyId}
        token={token}
        queuedTrackIds={queuedTrackIds}
        limitReached={limitReached}
        summary={
          queue
            ? `Suas músicas esperando: ${String(myPending)} de ${String(queue.maxPendingPerParticipant)}`
            : undefined
        }
        onAdded={reload}
        onFatalError={handleFatalError}
      />

      {queue && (
        <UpNext upNext={queue.upNext} participantId={participantId} hostControls={hostControls} />
      )}
    </>
  );
}
