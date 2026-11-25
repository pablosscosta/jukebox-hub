import type { ReactNode } from 'react';
import type { Queue, Track } from '../../api/client';
import type { HostControls } from './hostControls';
import { ProgressBar } from './ProgressBar';

type Props = { queue: Queue; participantId: string; hostControls?: HostControls };

// The song on now: a song from the queue, the host's own song from Spotify, or nothing.
export function NowPlaying({ queue, participantId, hostControls }: Props) {
  const { nowPlaying, externalTrack } = queue;

  return (
    <section className="section" aria-labelledby="now-playing-title">
      <h3 id="now-playing-title">Tocando agora</h3>
      <div className="card">
        {nowPlaying ? (
          <Song
            track={nowPlaying}
            startedAt={nowPlaying.startedAt}
            detail={`por ${nowPlaying.addedBy.id === participantId ? 'você' : nowPlaying.addedBy.displayName}`}
            action={
              hostControls && (
                <button
                  type="button"
                  className="button-small"
                  onClick={hostControls.onSkip}
                  disabled={hostControls.busy}
                >
                  Pular
                </button>
              )
            }
          />
        ) : externalTrack ? (
          <Song
            track={externalTrack}
            startedAt={externalTrack.startedAt ?? null}
            detail="colocada pelo host"
            tag="Spotify do host"
            action={
              hostControls && (
                <button
                  type="button"
                  className="button-small"
                  onClick={hostControls.onStart}
                  disabled={hostControls.busy}
                >
                  Voltar para a fila
                </button>
              )
            }
          />
        ) : (
          <Stopped queue={queue} hostControls={hostControls} />
        )}
      </div>
    </section>
  );
}

type SongProps = {
  track: Track;
  startedAt: string | null;
  detail: string;
  tag?: string;
  action?: ReactNode;
};

function Song({ track, startedAt, detail, tag, action }: SongProps) {
  return (
    <div className="now-playing">
      {track.imageUrl ? (
        <img src={track.imageUrl} alt="" width={96} height={96} />
      ) : (
        <span className="cover-placeholder" aria-hidden="true" />
      )}
      <div className="now-playing-info">
        <p className="now-playing-title">
          {track.title}
          {tag && <span className="tag">{tag}</span>}
        </p>
        <p>
          {track.artist} · {detail}
        </p>
        {startedAt && <ProgressBar startedAt={startedAt} durationMs={track.durationMs} />}
        {action && <div className="now-playing-actions">{action}</div>}
      </div>
    </div>
  );
}

// Nothing is playing: the jukebox waits for songs, or Spotify stopped and waits for the host.
function Stopped({ queue, hostControls }: { queue: Queue; hostControls?: HostControls }) {
  const waiting = queue.upNext.length > 0;
  const pausedWithSongs = queue.playbackState === 'paused' && waiting;

  return (
    <div className="section-header">
      <p className="hint" style={{ margin: 0 }}>
        {pausedWithSongs
          ? hostControls
            ? 'O Spotify parou no meio da música. Toque em Tocar para continuar a fila.'
            : 'A fila está pausada pelo host.'
          : 'Nada tocando agora.'}
      </p>
      {hostControls && waiting && (
        <button
          type="button"
          className="button-primary button-small"
          onClick={hostControls.onStart}
          disabled={hostControls.busy}
        >
          Tocar
        </button>
      )}
    </div>
  );
}
