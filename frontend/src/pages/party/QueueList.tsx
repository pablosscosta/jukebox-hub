import type { Queue, QueueItem } from '../../api/client';
import { TrackInfo } from './TrackInfo';

// Only the host gets these; guests see the same queue without buttons.
export type HostControls = {
  busy: boolean;
  onSkip: () => void;
  onStart: () => void;
  onRemove: (item: QueueItem) => void;
};

type Props = { queue: Queue; participantId: string; hostControls?: HostControls };

// What is playing and what comes next. The API sends upNext already in play order.
export function QueueList({ queue, participantId, hostControls }: Props) {
  const addedBy = (item: QueueItem) =>
    item.addedBy.id === participantId ? 'você' : item.addedBy.displayName;

  return (
    <>
      <h3>Tocando agora</h3>
      {queue.nowPlaying ? (
        <div className="track-row">
          <TrackInfo track={queue.nowPlaying} detail={`por ${addedBy(queue.nowPlaying)}`} />
          {hostControls && (
            <button type="button" onClick={hostControls.onSkip} disabled={hostControls.busy}>
              Pular
            </button>
          )}
        </div>
      ) : queue.externalTrack ? (
        <div className="track-row">
          <TrackInfo
            track={queue.externalTrack}
            detail="colocada pelo host"
            tag="Spotify do host"
          />
          {hostControls && (
            <button type="button" onClick={hostControls.onStart} disabled={hostControls.busy}>
              Voltar para a fila
            </button>
          )}
        </div>
      ) : (
        <Stopped queue={queue} hostControls={hostControls} />
      )}

      <h3>Próximas</h3>
      {queue.upNext.length === 0 ? (
        <p className="hint">A fila está vazia. Busque uma música para começar.</p>
      ) : (
        <ol className="tracks" aria-label="Próximas músicas">
          {queue.upNext.map((item) => (
            <li key={item.id}>
              <TrackInfo track={item} detail={`por ${addedBy(item)}`} />
              {hostControls && (
                <button
                  type="button"
                  aria-label={`Remover ${item.title}`}
                  onClick={() => {
                    hostControls.onRemove(item);
                  }}
                  disabled={hostControls.busy}
                >
                  Remover
                </button>
              )}
            </li>
          ))}
        </ol>
      )}
    </>
  );
}

// Nothing is playing: the jukebox waits for songs, or Spotify stopped and waits for the host.
function Stopped({ queue, hostControls }: { queue: Queue; hostControls?: HostControls }) {
  const waiting = queue.upNext.length > 0;
  const pausedWithSongs = queue.playbackState === 'paused' && waiting;

  return (
    <div className="track-row">
      <p className="hint">
        {pausedWithSongs
          ? hostControls
            ? 'O Spotify parou no meio da música. Toque em Tocar para continuar a fila.'
            : 'A fila está pausada pelo host.'
          : 'Nada tocando agora.'}
      </p>
      {hostControls && waiting && (
        <button type="button" onClick={hostControls.onStart} disabled={hostControls.busy}>
          Tocar
        </button>
      )}
    </div>
  );
}
