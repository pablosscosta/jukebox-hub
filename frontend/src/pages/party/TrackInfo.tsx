import type { Track } from '../../api/client';

type Props = { track: Track; detail?: string; tag?: string };

// Cover, title and artist: how a song looks in the search results and in the queue.
export function TrackInfo({ track, detail, tag }: Props) {
  return (
    <span className="track-info">
      {track.imageUrl ? (
        <img src={track.imageUrl} alt="" width={48} height={48} loading="lazy" />
      ) : (
        <span className="track-cover-placeholder" aria-hidden="true" />
      )}
      <span>
        <strong>{track.title}</strong>
        {tag && <span className="tag">{tag}</span>}
        <br />
        <small>
          {track.artist}
          {detail && ` · ${detail}`}
        </small>
      </span>
    </span>
  );
}
