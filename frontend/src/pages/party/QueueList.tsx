import type { Queue, QueueItem } from '../../api/client';
import { TrackInfo } from './TrackInfo';

type Props = { queue: Queue; participantId: string };

// What is playing and what comes next. The API sends upNext already in play order.
export function QueueList({ queue, participantId }: Props) {
  const addedBy = (item: QueueItem) =>
    item.addedBy.id === participantId ? 'você' : item.addedBy.displayName;

  return (
    <>
      {queue.nowPlaying && (
        <>
          <h3>Tocando agora</h3>
          <TrackInfo track={queue.nowPlaying} detail={`por ${addedBy(queue.nowPlaying)}`} />
        </>
      )}
      <h3>Próximas</h3>
      {queue.upNext.length === 0 ? (
        <p className="hint">A fila está vazia. Busque uma música para começar.</p>
      ) : (
        <ol className="tracks" aria-label="Próximas músicas">
          {queue.upNext.map((item) => (
            <li key={item.id}>
              <TrackInfo track={item} detail={`por ${addedBy(item)}`} />
            </li>
          ))}
        </ol>
      )}
    </>
  );
}
